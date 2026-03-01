local _, NS = ...

local UI = {}
NS.UI = UI

local L -- will be set on ADDON_LOADED

----------------------------------------------------------------------
-- FormatTime: convert seconds to human-readable string
----------------------------------------------------------------------
function UI.FormatTime(seconds)
    if not L then L = NS.L end

    if seconds <= 0 then
        return L["READY"]
    elseif seconds < 60 then
        return L["LESS_THAN_ONE_MIN"]
    end

    local days = math.floor(seconds / 86400)
    local hours = math.floor((seconds % 86400) / 3600)
    local minutes = math.floor((seconds % 3600) / 60)

    if days > 0 then
        return days .. L["DAYS_SHORT"] .. " " .. hours .. L["HOURS_SHORT"]
    else
        return hours .. L["HOURS_SHORT"] .. " " .. minutes .. L["MINUTES_SHORT"]
    end
end

----------------------------------------------------------------------
-- Tooltip rendering
----------------------------------------------------------------------
local function ShowTooltip(anchor)
    if not L then L = NS.L end

    GameTooltip:SetOwner(anchor, "ANCHOR_LEFT")
    GameTooltip:AddLine(L["TOOLTIP_HEADER"], 1, 0.82, 0) -- Gold

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

    local displayOrder = NS.Cooldowns and NS.Cooldowns.DISPLAY_ORDER
    local trackedSpells = NS.Cooldowns and NS.Cooldowns.TRACKED_SPELLS

    -- Ensure current character is in the list (even with no stored CD)
    if NS.playerKey then
        local alreadyIn = false
        for _, k in ipairs(chars) do
            if k == NS.playerKey then alreadyIn = true; break end
        end
        if not alreadyIn then
            table.insert(chars, NS.playerKey)
            table.sort(chars)
        end
    end

    for _, charKey in ipairs(chars) do
        local cooldowns = NS.db[charKey] and NS.db[charKey].cooldowns or {}
        local isCurrentChar = (charKey == NS.playerKey)
        local charHasLines = false

        if displayOrder then
            for _, entry in ipairs(displayOrder) do
                local expiresAt = cooldowns[entry.key]
                -- For current char: also show known spells with no stored CD
                local knownAndReady = false
                if not expiresAt and isCurrentChar and trackedSpells then
                    for spellID, info in pairs(trackedSpells) do
                        if info.key == entry.key and IsPlayerSpell(spellID) then
                            knownAndReady = true
                            break
                        end
                    end
                end

                if expiresAt or knownAndReady then
                    if not charHasLines then
                        found = true
                        charHasLines = true
                        GameTooltip:AddLine(" ")
                        GameTooltip:AddLine(charKey, 0.2, 0.6, 1)
                    end

                    local remaining = expiresAt and (expiresAt - now) or 0
                    if remaining <= 0 then
                        GameTooltip:AddDoubleLine(
                            L[entry.key] or entry.key,
                            L["READY"],
                            1, 1, 1,
                            0, 1, 0
                        )
                    else
                        GameTooltip:AddDoubleLine(
                            L[entry.key] or entry.key,
                            UI.FormatTime(remaining),
                            1, 1, 1,
                            1, 0.6, 0
                        )
                    end
                end
            end
        end
    end

    if not found then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(L["NO_COOLDOWNS"], 0.6, 0.6, 0.6)
    end

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(L["TOOLTIP_HINT"], 0.6, 0.6, 0.6)
    GameTooltip:Show()
end

----------------------------------------------------------------------
-- Minimap button
----------------------------------------------------------------------
local function UpdateMinimapButtonPosition(button, angle)
    local radian = math.rad(angle)
    local x = math.cos(radian) * 80
    local y = math.sin(radian) * 80
    button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local function CreateMinimapButton()
    local button = CreateFrame("Button", "ChronoCraftMinimapButton", Minimap)
    button:SetSize(32, 32)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:EnableMouse(true)
    button:SetMovable(true)

    -- Icon
    local icon = button:CreateTexture(nil, "BACKGROUND")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER")
    icon:SetTexture("Interface\\Icons\\INV_Misc_PocketWatch_01")

    -- Border
    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetSize(54, 54)
    border:SetPoint("TOPLEFT")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    -- Highlight
    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetSize(24, 24)
    highlight:SetPoint("CENTER")
    highlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    -- Position
    local angle = NS.db and NS.db.settings and NS.db.settings.minimapPos or 220
    UpdateMinimapButtonPosition(button, angle)

    -- Drag handling
    button:RegisterForDrag("LeftButton")
    button:SetScript("OnDragStart", function(self)
        self.isDragging = true
    end)

    button:SetScript("OnDragStop", function(self)
        self.isDragging = false
    end)

    button:SetScript("OnUpdate", function(self)
        if not self.isDragging then return end

        local mx, my = Minimap:GetCenter()
        local cx, cy = GetCursorPosition()
        local scale = Minimap:GetEffectiveScale()
        cx, cy = cx / scale, cy / scale

        local angle = math.deg(math.atan2(cy - my, cx - mx))
        UpdateMinimapButtonPosition(self, angle)

        if NS.db and NS.db.settings then
            NS.db.settings.minimapPos = angle
        end
    end)

    -- Tooltip
    button:SetScript("OnEnter", function(self)
        ShowTooltip(self)
    end)

    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    return button
end

----------------------------------------------------------------------
-- Init
----------------------------------------------------------------------
local minimapButton

NS:RegisterCallback("ADDON_LOADED", function()
    L = NS.L
    minimapButton = CreateMinimapButton()
end)

-- Refresh tooltip on cooldown updates (if tooltip is showing)
NS:RegisterCallback("COOLDOWN_UPDATED", function()
    if minimapButton and GameTooltip:IsOwned(minimapButton) then
        ShowTooltip(minimapButton)
    end
end)
