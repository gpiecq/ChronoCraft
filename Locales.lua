local _, NS = ...

local L = {}
NS.L = L

-- Default: English
L["ADDON_LOADED"]         = "ChronoCraft loaded. Type /cc to list cooldowns."
L["TOOLTIP_HEADER"]       = "ChronoCraft - Profession Cooldowns"
L["READY"]                = "Ready"
L["NO_COOLDOWNS"]         = "No cooldowns tracked"
L["TOOLTIP_HINT"]         = "Left-click to drag"
L["DAYS_SHORT"]           = "d"
L["HOURS_SHORT"]          = "h"
L["MINUTES_SHORT"]        = "min"
L["LESS_THAN_ONE_MIN"]    = "< 1min"
L["CD_READY_ALERT"]       = "|cff00ff00%s|r is ready!"
L["CHAT_HEADER"]          = "=== ChronoCraft - Cooldowns ==="
L["CHAT_NO_COOLDOWNS"]    = "No cooldowns tracked yet."
L["CHAT_CHAR_HEADER"]     = "  %s:"

-- Profession categories
L["Tailoring"]            = "Tailoring"
L["Alchemy"]              = "Alchemy"
L["Jewelcrafting"]        = "Jewelcrafting"
L["Leatherworking"]       = "Leatherworking"

-- Cooldown names
L["Shadowcloth"]          = "Shadowcloth"
L["Spellcloth"]           = "Spellcloth"
L["Primal Mooncloth"]     = "Primal Mooncloth"
L["Transmute"]            = "Transmute"
L["Brilliant Glass"]      = "Brilliant Glass"
L["Salt Shaker"]          = "Salt Shaker"

-- French overrides
if GetLocale() == "frFR" then
    L["ADDON_LOADED"]         = "ChronoCraft charg\195\169. Tapez /cc pour lister les cooldowns."
    L["TOOLTIP_HEADER"]       = "ChronoCraft - Cooldowns de m\195\169tiers"
    L["READY"]                = "Pr\195\170t"
    L["NO_COOLDOWNS"]         = "Aucun cooldown enregistr\195\169"
    L["TOOLTIP_HINT"]         = "Clic gauche pour d\195\169placer"
    L["DAYS_SHORT"]           = "j"
    L["HOURS_SHORT"]          = "h"
    L["MINUTES_SHORT"]        = "min"
    L["LESS_THAN_ONE_MIN"]    = "< 1min"
    L["CD_READY_ALERT"]       = "|cff00ff00%s|r est pr\195\170t !"
    L["CHAT_HEADER"]          = "=== ChronoCraft - Cooldowns ==="
    L["CHAT_NO_COOLDOWNS"]    = "Aucun cooldown enregistr\195\169."
    L["CHAT_CHAR_HEADER"]     = "  %s :"

    L["Tailoring"]            = "Couture"
    L["Alchemy"]              = "Alchimie"
    L["Jewelcrafting"]        = "Joaillerie"
    L["Leatherworking"]       = "Travail du cuir"

    L["Shadowcloth"]          = "Tisse-ombre"
    L["Spellcloth"]           = "Tisse-sort"
    L["Primal Mooncloth"]     = "Tissu lunaire primal"
    L["Transmute"]            = "Transmutation"
    L["Brilliant Glass"]      = "Verre brillant"
    L["Salt Shaker"]          = "Saloir"
end
