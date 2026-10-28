local ADDON, LA = ...
local hooked = false
local queued = false
local guildOpen = false

local function GuildButton(frame, slot)
    local column = math.ceil(slot / 14)
    local idx = ((slot - 1) % 14) + 1
    if frame.Columns and frame.Columns[column] and frame.Columns[column].Buttons then
        return frame.Columns[column].Buttons[idx]
    end
    return _G["GuildBankColumn" .. column .. "Button" .. idx]
end

local function UpdateGuild()
    local f = _G.GuildBankFrame
    if not f then return end
    if not guildOpen or not LA.db or not LA.db.showGuildBank
       or not f:IsShown() or (f.mode and f.mode ~= "bank") then
        for i=1,98 do LA:ClearButton(GuildButton(f, i)) end
        return
    end
    local tab = GetCurrentGuildBankTab and GetCurrentGuildBankTab()
    if not tab or tab < 1 or not GetGuildBankItemLink then return end
    for slot = 1, 98 do
        local b = GuildButton(f, slot)
        if b then
            b.laGuildBank = true
            local link = GetGuildBankItemLink(tab, slot)
            if link then
                local count = 1
                if GetGuildBankItemInfo then
                    local _, c = GetGuildBankItemInfo(tab, slot)
                    count = c or 1
                end
                if LA.RememberATTItem then LA:RememberATTItem(link) end
                LA:Paint(b, link, LA:Evaluate(link, {guild=true, count=count,_LLFastBadge=true}))
            else
                LA:ClearButton(b)
            end
        end
    end
end

function LA:QueueGuildRefresh()
    if queued then return end
    queued = true
    if C_Timer and C_Timer.After then
        C_Timer.After(0.1, function() queued = false; UpdateGuild() end)
    else
        queued = false; UpdateGuild()
    end
end

local function HookGuild()
    if hooked or not _G.GuildBankFrame then return end
    hooked = true
    local f = _G.GuildBankFrame
    if f:IsShown() then guildOpen = true end
    if type(f.Update) == "function" then
        hooksecurefunc(f, "Update", function() LA:QueueGuildRefresh() end)
    elseif type(_G.GuildBankFrame_Update) == "function" then
        hooksecurefunc("GuildBankFrame_Update", function() LA:QueueGuildRefresh() end)
    end
    f:HookScript("OnShow", function() guildOpen = true; LA:QueueGuildRefresh() end)
    f:HookScript("OnHide", function() guildOpen = false; LA:QueueGuildRefresh() end)
end

local e = CreateFrame("Frame")
e:RegisterEvent("ADDON_LOADED")
e:RegisterEvent("PLAYER_LOGIN")
e:RegisterEvent("GUILDBANKFRAME_OPENED")
e:RegisterEvent("GUILDBANKFRAME_CLOSED")
e:RegisterEvent("GUILDBANKBAGSLOTS_CHANGED")
e:RegisterEvent("GUILDBANK_UPDATE_TABS")
e:SetScript("OnEvent", function(_, event, name)
    if event == "ADDON_LOADED" and name ~= "Blizzard_GuildBankUI" then return end
    if event == "PLAYER_LOGIN" or event == "ADDON_LOADED" then
        HookGuild()
        return
    end
    if event == "GUILDBANKFRAME_OPENED" then guildOpen = true end
    if event == "GUILDBANKFRAME_CLOSED" then guildOpen = false end
    HookGuild()
    LA:QueueGuildRefresh()
end)
