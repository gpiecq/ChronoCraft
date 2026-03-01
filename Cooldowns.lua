local _, NS = ...

local Cooldowns = {}
NS.Cooldowns = Cooldowns

----------------------------------------------------------------------
-- Duration constants (seconds)
----------------------------------------------------------------------
local CD_TAILORING = 345600   -- 4 days
local CD_TRANSMUTE = 72000    -- 20 hours
local CD_GLASS     = 72000    -- 20 hours
local CD_SALT      = 259200   -- 3 days

----------------------------------------------------------------------
-- Tracked spells (spellID -> info)
----------------------------------------------------------------------
local TRACKED_SPELLS = {
    -- Tailoring
    [36686] = { key = "Shadowcloth",      duration = CD_TAILORING },
    [31373] = { key = "Spellcloth",       duration = CD_TAILORING },
    [26751] = { key = "Primal Mooncloth", duration = CD_TAILORING },

    -- Alchemy transmutes
    [28566] = { key = "Transmute", duration = CD_TRANSMUTE }, -- Primal Air
    [28567] = { key = "Transmute", duration = CD_TRANSMUTE }, -- Primal Mana
    [28568] = { key = "Transmute", duration = CD_TRANSMUTE }, -- Primal Fire
    [28569] = { key = "Transmute", duration = CD_TRANSMUTE }, -- Primal Shadow
    [28580] = { key = "Transmute", duration = CD_TRANSMUTE }, -- Primal Water
    [28581] = { key = "Transmute", duration = CD_TRANSMUTE }, -- Primal Might
    [28582] = { key = "Transmute", duration = CD_TRANSMUTE }, -- Primal Earth
    [28583] = { key = "Transmute", duration = CD_TRANSMUTE }, -- Primal Life
    [28584] = { key = "Transmute", duration = CD_TRANSMUTE }, -- Primal Shadow -> Earth
    [28585] = { key = "Transmute", duration = CD_TRANSMUTE }, -- Primal Earth -> Life
    [29688] = { key = "Transmute", duration = CD_TRANSMUTE }, -- Primal Might (alt)

    -- Jewelcrafting
    [47280] = { key = "Brilliant Glass", duration = CD_GLASS },

    -- Leatherworking (spell triggered by item use)
    [19566] = { key = "Salt Shaker", duration = CD_SALT },
}
Cooldowns.TRACKED_SPELLS = TRACKED_SPELLS

----------------------------------------------------------------------
-- Tracked items (itemID -> info)
----------------------------------------------------------------------
local TRACKED_ITEMS = {
    [15846] = { key = "Salt Shaker", spellID = 19566, duration = CD_SALT },
}
Cooldowns.TRACKED_ITEMS = TRACKED_ITEMS

----------------------------------------------------------------------
-- Display order
----------------------------------------------------------------------
local DISPLAY_ORDER = {
    { key = "Shadowcloth",      category = "Tailoring" },
    { key = "Spellcloth",       category = "Tailoring" },
    { key = "Primal Mooncloth", category = "Tailoring" },
    { key = "Transmute",        category = "Alchemy" },
    { key = "Brilliant Glass",  category = "Jewelcrafting" },
    { key = "Salt Shaker",      category = "Leatherworking" },
}
Cooldowns.DISPLAY_ORDER = DISPLAY_ORDER

----------------------------------------------------------------------
-- Build reverse lookup: spellID set for quick checks
----------------------------------------------------------------------
local trackedSpellIDs = {}
for spellID in pairs(TRACKED_SPELLS) do
    trackedSpellIDs[spellID] = true
end

----------------------------------------------------------------------
-- Helper: store a cooldown
----------------------------------------------------------------------
local function StoreCooldown(key, expiresAt)
    if not NS.playerKey or not NS.db then return end
    local charData = NS.db[NS.playerKey]
    if not charData then return end

    charData.cooldowns[key] = expiresAt
    NS:FireCallback("COOLDOWN_UPDATED")
end

----------------------------------------------------------------------
-- Scan spellbook for existing cooldowns
----------------------------------------------------------------------
local function ScanSpellbook()
    if not NS.playerKey then return end

    local now = GetTime()
    local nowAbs = time()

    for spellID, info in pairs(TRACKED_SPELLS) do
        local start, duration = GetSpellCooldown(spellID)
        if start and start > 0 and duration and duration > 1.5 then
            local remaining = (start + duration) - now
            if remaining > 0 then
                local expiresAt = nowAbs + remaining
                local current = NS.db[NS.playerKey].cooldowns[info.key]
                if not current or math.abs(current - expiresAt) > 60 then
                    StoreCooldown(info.key, math.floor(expiresAt))
                end
            end
        end
    end

    -- Salt Shaker is already covered via its spellID in TRACKED_SPELLS
end

----------------------------------------------------------------------
-- Event frame
----------------------------------------------------------------------
local frame = CreateFrame("Frame")
frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
frame:RegisterEvent("TRADE_SKILL_UPDATE")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unitTarget, _, spellID = ...
        if unitTarget ~= "player" then return end

        local info = TRACKED_SPELLS[spellID]
        if info then
            StoreCooldown(info.key, time() + info.duration)
        end

    elseif event == "TRADE_SKILL_UPDATE" then
        local numSkills = GetNumTradeSkills()
        if not numSkills or numSkills == 0 then return end

        local now = GetTime()
        local nowAbs = time()

        for i = 1, numSkills do
            local cooldown = GetTradeSkillCooldown(i)
            if cooldown and cooldown > 0 then
                local link = GetTradeSkillRecipeLink(i)
                if link then
                    local spellID = tonumber(link:match("enchant:(%d+)"))
                    if spellID and TRACKED_SPELLS[spellID] then
                        local info = TRACKED_SPELLS[spellID]
                        local expiresAt = nowAbs + cooldown
                        local current = NS.db and NS.db[NS.playerKey] and NS.db[NS.playerKey].cooldowns[info.key]
                        if not current or math.abs(current - expiresAt) > 60 then
                            StoreCooldown(info.key, math.floor(expiresAt))
                        end
                    end
                end
            end
        end
    end
end)


-- Check for ready cooldowns and alert in chat (uses IsPlayerSpell)
local function AlertReadyCooldowns()
    if not NS.playerKey then return end

    local L = NS.L
    local alerted = {}

    for _, entry in ipairs(DISPLAY_ORDER) do
        if not alerted[entry.key] then
            -- Find any spellID for this key that the player knows
            for spellID, info in pairs(TRACKED_SPELLS) do
                if info.key == entry.key and IsPlayerSpell(spellID) then
                    local start, duration = GetSpellCooldown(spellID)
                    if not start or start == 0 or not duration or duration <= 1.5 then
                        alerted[entry.key] = true
                        local name = L[entry.key] or entry.key
                        DEFAULT_CHAT_FRAME:AddMessage("|cff00ccff[ChronoCraft]|r " .. string.format(L["CD_READY_ALERT"], name))
                    end
                    break
                end
            end
        end
    end
end

-- Scan spellbook after login, then alert for ready cooldowns
-- 5s delay to ensure spell data is fully loaded
NS:RegisterCallback("PLAYER_LOGIN", function()
    C_Timer.After(5, function()
        ScanSpellbook()
        AlertReadyCooldowns()
    end)
end)
