local ADDON_NAME, NS = ...

----------------------------------------------------------------------
-- Event bus
----------------------------------------------------------------------
NS.callbacks = {}

function NS:RegisterCallback(event, fn)
    if not self.callbacks[event] then
        self.callbacks[event] = {}
    end
    table.insert(self.callbacks[event], fn)
end

function NS:FireCallback(event, ...)
    if self.callbacks[event] then
        for _, fn in ipairs(self.callbacks[event]) do
            fn(...)
        end
    end
end

----------------------------------------------------------------------
-- Defaults & merge
----------------------------------------------------------------------
local DEFAULTS = {
    settings = {
        minimapPos = 220,
    },
}

local function MergeDefaults(target, defaults)
    for k, v in pairs(defaults) do
        if type(v) == "table" then
            if type(target[k]) ~= "table" then
                target[k] = {}
            end
            MergeDefaults(target[k], v)
        elseif target[k] == nil then
            target[k] = v
        end
    end
end

----------------------------------------------------------------------
-- Main frame & events
----------------------------------------------------------------------
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_LOGOUT")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...
        if name == ADDON_NAME then
            -- Init SavedVariables
            if not ChronoCraftDB then
                ChronoCraftDB = {}
            end
            MergeDefaults(ChronoCraftDB, DEFAULTS)
            NS.db = ChronoCraftDB

            NS:FireCallback("ADDON_LOADED")
            self:UnregisterEvent("ADDON_LOADED")
        end

    elseif event == "PLAYER_LOGIN" then
        -- Build player key
        local name = UnitName("player")
        local realm = GetRealmName()
        NS.playerKey = name .. "-" .. realm

        -- Init character data
        if not NS.db[NS.playerKey] then
            NS.db[NS.playerKey] = { cooldowns = {} }
        end
        if not NS.db[NS.playerKey].cooldowns then
            NS.db[NS.playerKey].cooldowns = {}
        end

        local L = NS.L
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ccff" .. L["ADDON_LOADED"] .. "|r")

        NS:FireCallback("PLAYER_LOGIN")

    elseif event == "PLAYER_LOGOUT" then
        -- Purge expired cooldowns (older than 24h past expiry)
        local now = time()
        local PURGE_THRESHOLD = 86400 -- 24h
        for charKey, charData in pairs(NS.db) do
            if type(charData) == "table" and charData.cooldowns then
                for cdKey, expiresAt in pairs(charData.cooldowns) do
                    if type(expiresAt) == "number" and (expiresAt + PURGE_THRESHOLD) < now then
                        charData.cooldowns[cdKey] = nil
                    end
                end
                -- Remove character entry if no cooldowns remain
                local hasCD = false
                for _ in pairs(charData.cooldowns) do
                    hasCD = true
                    break
                end
                if not hasCD then
                    NS.db[charKey] = nil
                end
            end
        end
    end
end)

----------------------------------------------------------------------
-- Slash commands
----------------------------------------------------------------------
local function PrintCooldowns()
    local L = NS.L
    DEFAULT_CHAT_FRAME:AddMessage("|cffffd700" .. L["CHAT_HEADER"] .. "|r")

    local now = time()
    local found = false

    -- Sort character names
    local chars = {}
    for charKey, charData in pairs(NS.db) do
        if type(charData) == "table" and charData.cooldowns then
            local hasCD = false
            for _ in pairs(charData.cooldowns) do
                hasCD = true
                break
            end
            if hasCD then
                table.insert(chars, charKey)
            end
        end
    end
    table.sort(chars)

    for _, charKey in ipairs(chars) do
        found = true
        DEFAULT_CHAT_FRAME:AddMessage("|cff3399ff" .. string.format(L["CHAT_CHAR_HEADER"], charKey) .. "|r")

        local cooldowns = NS.db[charKey].cooldowns
        -- Use display order from Cooldowns module if available
        local displayOrder = NS.Cooldowns and NS.Cooldowns.DISPLAY_ORDER
        if displayOrder then
            for _, entry in ipairs(displayOrder) do
                local expiresAt = cooldowns[entry.key]
                if expiresAt then
                    local remaining = expiresAt - now
                    local timeStr
                    if remaining <= 0 then
                        timeStr = "|cff00ff00" .. L["READY"] .. "|r"
                    else
                        timeStr = "|cffff9900" .. NS.UI.FormatTime(remaining) .. "|r"
                    end
                    DEFAULT_CHAT_FRAME:AddMessage("    " .. (L[entry.key] or entry.key) .. ": " .. timeStr)
                end
            end
        else
            for cdKey, expiresAt in pairs(cooldowns) do
                local remaining = expiresAt - now
                local timeStr
                if remaining <= 0 then
                    timeStr = "|cff00ff00" .. L["READY"] .. "|r"
                else
                    timeStr = "|cffff9900" .. NS.UI.FormatTime(remaining) .. "|r"
                end
                DEFAULT_CHAT_FRAME:AddMessage("    " .. (L[cdKey] or cdKey) .. ": " .. timeStr)
            end
        end
    end

    if not found then
        DEFAULT_CHAT_FRAME:AddMessage("|cff999999" .. L["CHAT_NO_COOLDOWNS"] .. "|r")
    end
end

SLASH_CHRONOCRAFT1 = "/chronocraft"
SLASH_CHRONOCRAFT2 = "/cc"
SlashCmdList["CHRONOCRAFT"] = function()
    PrintCooldowns()
end
