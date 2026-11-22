-- Native Blizzard bags, banks and guild-bank adapters.
local _, LL = ...
local function IsVisible(frame)
    if not frame then return false end
    if type(frame.IsVisible)=="function" then return frame:IsVisible() end
    return type(frame.IsShown)=="function" and frame:IsShown()
end
local subscriptions={}
local eventFrame=CreateFrame("Frame")
local function NewNativeObserver()
    local observer={}
    function observer:RegisterEvent(event)
        if not subscriptions[event] then subscriptions[event]={};eventFrame:RegisterEvent(event) end
        subscriptions[event][#subscriptions[event]+1]=self
    end
    function observer:SetScript(_,callback) self.callback=callback end
    return observer
end
eventFrame:SetScript("OnEvent",function(_,event,...)
    for _,observer in ipairs(subscriptions[event] or {}) do
        if observer.callback then observer.callback(observer,event,...) end
    end
end)

do -- Default bags, regular bank and Warband bank
-- Default Blizzard bag integration, separate and combined modes where their
-- item buttons expose bag/slot IDs. Never touch Blizzard's addon files.
local scheduled = false
local fullPending = false
local changedBags = {}
local function ItemContext(bag, slot)
    local c = {bagID=bag,slotID=slot,_LLFastBadge=true}
    if C_Container and C_Container.GetContainerItemInfo then
        local i=C_Container.GetContainerItemInfo(bag,slot)
        if i then c.count=i.stackCount or 1; c.isBound=i.isBound end
    end
    if C_Container and C_Container.GetContainerItemQuestInfo then
        local info=C_Container.GetContainerItemQuestInfo(bag,slot)
        if info then c.isQuest=info.isQuestItem end
    end
    if ItemLocation and ItemLocation.CreateFromBagAndSlot and C_Item then
        local ok, location=pcall(ItemLocation.CreateFromBagAndSlot,ItemLocation,bag,slot)
        if ok and location and C_Item.DoesItemExist then
            local existsOK,exists=pcall(C_Item.DoesItemExist,location)
            if existsOK and exists then
                if C_Item.IsBound then
                    local boundOK,bound=pcall(C_Item.IsBound,location)
                    if boundOK then
                        c.isBound=bound
                        if bound==false then c.verifiedUnbound=true end
                    end
                end
                if C_Item.IsBoundToAccountUntilEquip then
                    local wbOK,wb=pcall(C_Item.IsBoundToAccountUntilEquip,location)
                    if wbOK and wb then
                        c.isBoundToAccount=true
                        c.verifiedWarbound=true -- item-instance check, not template bind type
                        c.verifiedUnbound=false
                    end
                end
                if C_AuctionHouse and C_AuctionHouse.IsSellItemValid then
                    local eligibleOK,eligible=pcall(C_AuctionHouse.IsSellItemValid,location,false)
                    if eligibleOK and not eligible then c.verifiedUnbound=false end
                end
            end
        end
    end
    return c
end

local function ScanFrame(frame, changed)
    if not IsVisible(frame) then return end
    -- Retail combined bags may use pooled buttons. Check visible children and
    -- their grandchildren; ignore unknown widget shapes rather than mislabel.
    local candidates={}
    local function collect(parent,depth)
        if not parent or depth>3 then return end
        if parent.GetChildren then
            for _,child in ipairs({parent:GetChildren()}) do
                if child then
                    if (child.GetBagID or child.bagID) and (child.GetID or child.slotID) then
                        candidates[#candidates+1]=child
                    end
                    collect(child,depth+1)
                end
            end
        end
    end
    collect(frame,1)
    for _,b in ipairs(candidates) do
        if IsVisible(b) then
        local bag=b.GetBagID and b:GetBagID() or b.bagID
        local slot=b.GetID and b:GetID() or b.slotID
        if type(bag)=="number" and type(slot)=="number" and slot>0 then
            local link=C_Container and C_Container.GetContainerItemLink
                and C_Container.GetContainerItemLink(bag,slot)
            local dirty = not changed or changed[bag] or b.laBagID~=bag
                or b.laSlotID~=slot or b.laLink~=link
            if dirty then
                b.laBlizzardBag = true
                b.laBagID, b.laSlotID = bag,slot
                if link then
                    LL:Paint(b,link,LL:Evaluate(link,ItemContext(bag,slot)))
                else
                    LL:ClearButton(b)
                end
            end
        end
        end
    end
end


-- Retail character bank and Warband Bank share Blizzard's BankFrame.BankPanel.
-- Its pooled buttons are not ContainerFrame item buttons: they expose
-- GetBankTabID()/GetContainerSlotID().  Iteration also differs: the active
-- button may be the KEY in EnumerateValidItems(), not the value.
-- Queue only V/D/T evaluations, keeping the UI's initial bank paint cheap.
local bankJobs=setmetatable({}, {__mode="k"})
local bankOrder={}
local bankHead=1
local bankScheduled=false
local bankHooksInstalled=false

local function BankPanel()
    local frame=_G.BankFrame
    return (frame and frame.BankPanel) or _G.BankPanel
end

local function BankButtonCoordinates(button)
    if not button or (type(button)~="table" and type(button)~="userdata")
        or type(button.GetBankTabID)~="function"
        or type(button.GetContainerSlotID)~="function" then return nil end
    local bag=button:GetBankTabID()
    local slot=button:GetContainerSlotID()
    if type(bag)=="number" and type(slot)=="number" and slot>0 then
        return bag,slot
    end
end

local function BankTick()
    bankScheduled=false
    local start=type(debugprofilestop)=="function" and debugprofilestop() or nil
    local processed=0
    while bankHead<=#bankOrder and processed<8 do
        if start and debugprofilestop()-start>=3 and processed>0 then break end
        local button=bankOrder[bankHead]
        bankOrder[bankHead]=false
        bankHead=bankHead+1
        local job=bankJobs[button]
        bankJobs[button]=nil
        local panel=BankPanel()
        if job and IsVisible(panel) and IsVisible(button) then
            local bag,slot=BankButtonCoordinates(button)
            local link=bag and C_Container and C_Container.GetContainerItemLink
                and C_Container.GetContainerItemLink(bag,slot)
            if bag==job.bag and slot==job.slot and link==job.link then
                local decision=LL:Evaluate(link,ItemContext(bag,slot))
                if IsVisible(panel) and IsVisible(button) then
                LL:Paint(button,link,decision)
                button.laBlizzardBag=true
                button.laBagID,button.laSlotID=bag,slot
                end
            end
        end
        processed=processed+1
    end
    if bankHead<=#bankOrder then
        bankScheduled=true
        if C_Timer and C_Timer.After then C_Timer.After(0,BankTick)
        else BankTick() end
    else
        bankOrder={}
        bankHead=1
    end
end

local function QueueBankButton(button,bag,slot,link)
    -- Badges on repurposed pooled buttons must never advertise the previous tab.
    if button.laLink~=link or button.laBagID~=bag or button.laSlotID~=slot then
        LL:ClearButton(button)
    end
    button.laBlizzardBag=true
    if not bankJobs[button] then bankOrder[#bankOrder+1]=button end
    bankJobs[button]={bag=bag,slot=slot,link=link}
    if not bankScheduled then
        bankScheduled=true
        if C_Timer and C_Timer.After then C_Timer.After(0,BankTick)
        else BankTick() end
    end
end

local function ScanBankPanel(changed)
    local panel=BankPanel()
    if not IsVisible(panel) then return end
    local function VisitButton(button)
        if not IsVisible(button) then return end
        local bag,slot=BankButtonCoordinates(button)
        if not bag then return end
        local link=C_Container and C_Container.GetContainerItemLink
            and C_Container.GetContainerItemLink(bag,slot)
        local dirty = not changed or changed[bag]
            or button.laBagID~=bag or button.laSlotID~=slot
            or button.laLink~=link or not button.laDecision
        -- Blizzard can remove overlay regions when recycling buttons.
        if not dirty and button.laLetter and button.laLetter.IsShown
            and button.laDecision and button.laDecision.action~="Q"
            and not button.laLetter:IsShown() then dirty=true end
        if dirty then
            if link then QueueBankButton(button,bag,slot,link)
            else
                bankJobs[button]=nil
                LL:ClearButton(button)
            end
        end
    end
    -- BankPanelMixin:EnumerateValidItems() can return keys as the buttons.
    local function Consume(iterator,state,initial)
        if type(iterator)~="function" then return end
        for key,value in iterator,state,initial do
            local button
            if BankButtonCoordinates(key) then button=key
            elseif BankButtonCoordinates(value) then button=value end
            if button then VisitButton(button) end
        end
    end
    if type(panel.EnumerateValidItems)=="function" then
        Consume(panel:EnumerateValidItems())
    elseif panel.itemButtonPool and type(panel.itemButtonPool.EnumerateActive)=="function" then
        Consume(panel.itemButtonPool:EnumerateActive())
    end
end

local function InstallBankHooks()
    if bankHooksInstalled then return end
    local panel=BankPanel()
    if not panel or not hooksecurefunc then return end
    bankHooksInstalled=true
    -- Refresh on selected-tab changes, including personal/account bank switch.
    for _,method in ipairs({"RefreshAllItemsForSelectedTab","GenerateItemSlotsForSelectedTab"}) do
        if type(panel[method])=="function" then
            hooksecurefunc(panel,method,function() LL:QueueBlizzardBagRefresh() end)
        end
    end
    if type(panel.HookScript)=="function" then
        panel:HookScript("OnShow",function() LL:QueueBlizzardBagRefresh() end)
        panel:HookScript("OnHide",function()
            -- Abandon queued bank jobs on close; recycled buttons must not be
            -- evaluated against a different bank tab in the next session.
            for button in pairs(bankJobs) do bankJobs[button]=nil end
        end)
    end
end

function LL:UpdateBlizzardBags(changed)
    if not self.db or self.db.showBlizzardBags==false then return end
    local set={}
    if ContainerFrameUtil and ContainerFrameUtil.GetAllContainerFrames then
        local ok,frames=pcall(ContainerFrameUtil.GetAllContainerFrames)
        if ok and type(frames)=="table" then
            for _,frame in pairs(frames) do set[frame]=true end
        end
    end
    for i=1,13 do
        local frame=_G["ContainerFrame"..i]
        if frame then set[frame]=true end
    end
    if _G.ContainerFrameCombinedBags then set[_G.ContainerFrameCombinedBags]=true end
    for frame in pairs(set) do ScanFrame(frame, changed) end
    ScanBankPanel(changed)
end

function LL:QueueBlizzardBagRefresh(bag)
    if type(bag)=="number" then
        changedBags[bag] = true
    else
        -- Show/hide and settings changes may alter which bag buttons exist.
        fullPending = true
    end
    if scheduled then return end
    scheduled = true
    local function Refresh()
        scheduled = false
        local changed
        if not fullPending then changed=changedBags end
        fullPending, changedBags = false, {}
        self:UpdateBlizzardBags(changed)
    end
    if C_Timer and C_Timer.After then C_Timer.After(0.08, Refresh)
    else Refresh() end
end

local e=NewNativeObserver()
e:RegisterEvent("PLAYER_LOGIN")
e:RegisterEvent("BAG_UPDATE")
e:RegisterEvent("BANKFRAME_OPENED")
e:RegisterEvent("ADDON_LOADED")
e:RegisterEvent("PLAYERBANKSLOTS_CHANGED")
e:SetScript("OnEvent",function(_, event, bag)
    if event == "ADDON_LOADED" then
        if bag=="Blizzard_UIPanels_Game" or bag=="Blizzard_BankUI" then
            InstallBankHooks()
        end
        return
    end
    if event == "PLAYER_LOGIN" or event == "BANKFRAME_OPENED" then
        InstallBankHooks()
    end
    if event == "BAG_UPDATE" then LL:QueueBlizzardBagRefresh(bag)
    else LL:QueueBlizzardBagRefresh() end
end)
if type(ContainerFrame_Update)=="function" then
    hooksecurefunc("ContainerFrame_Update",function() LL:QueueBlizzardBagRefresh() end)
end

end

do -- Guild bank
local hooked = false
local queued = false
local guildOpen = false
local guildJobs,guildJobCount,guildCursor={},0,1
local guildWorkScheduled=false
local guildWorkFrame,guildWorkTab

local function GuildButton(frame, slot)
    local column = math.ceil(slot / 14)
    local idx = ((slot - 1) % 14) + 1
    if frame.Columns and frame.Columns[column] and frame.Columns[column].Buttons then
        return frame.Columns[column].Buttons[idx]
    end
    return _G["GuildBankColumn" .. column .. "Button" .. idx]
end

local function ClearGuild(frame)
    if frame then for slot=1,98 do LL:ClearButton(GuildButton(frame,slot))end end
end
local function ResetGuildWork(clear)
    if clear then ClearGuild(guildWorkFrame or _G.GuildBankFrame)end
    guildJobs,guildJobCount,guildCursor={},0,1
    guildWorkFrame,guildWorkTab=nil,nil
end
local function GuildState()
    local frame=_G.GuildBankFrame
    if not guildOpen or not frame or not LL.db or not LL.db.showGuildBank
        or not IsVisible(frame) or frame.mode and frame.mode~='bank' then return nil end
    local tab=GetCurrentGuildBankTab and GetCurrentGuildBankTab()
    if type(tab)~='number'or tab<1 or not GetGuildBankItemLink then return nil end
    return frame,tab
end
local function GuildCount(tab,slot)
    if GetGuildBankItemInfo then local _,count=GetGuildBankItemInfo(tab,slot);return count or 1 end
    return 1
end
local function GuildJobMatches(job)
    local frame,tab=GuildState()
    return frame==job.frame and tab==job.tab and GuildButton(frame,job.slot)==job.button
        and GetGuildBankItemLink(tab,job.slot)==job.link and GuildCount(tab,job.slot)==job.count
end
local function GuildTick()
    guildWorkScheduled=false
    if guildJobCount==0 then ResetGuildWork(false);return end
    local start=type(debugprofilestop)=='function'and debugprofilestop()or nil
    local processed=0
    while guildJobCount>0 and processed<8 do
        local frame,tab=GuildState()
        if frame~=guildWorkFrame or tab~=guildWorkTab then
            ResetGuildWork(true)
            if frame then LL:QueueGuildRefresh()end
            return
        end
        if start and debugprofilestop()-start>=3 and processed>0 then break end
        local slot=guildCursor;guildCursor=slot%98+1
        local job=guildJobs[slot]
        if job then
            guildJobs[slot]=nil;guildJobCount=guildJobCount-1
            if GuildJobMatches(job)then
                local result=LL:Evaluate(job.link,{guild=true,count=job.count,_LLFastBadge=true})
                -- Native updates can replace a slot/tab while its data is read.
                -- Never paint an earlier item's answer over the latest slot.
                if GuildJobMatches(job)then
                    LL:Paint(job.button,job.link,result)
                    job.button.laGuildBank=true
                    job.button.laGuildTab,job.button.laGuildSlot,job.button.laGuildCount=job.tab,job.slot,job.count
                else LL:ClearButton(job.button);LL:QueueGuildRefresh()end
            else LL:ClearButton(job.button);LL:QueueGuildRefresh()end
            processed=processed+1
        end
    end
    if guildJobCount>0 then
        guildWorkScheduled=true
        if C_Timer and C_Timer.After then C_Timer.After(0,GuildTick)else GuildTick()end
    else ResetGuildWork(false)end
end
local function UpdateGuild()
    local f,tab=GuildState()
    if not f then ResetGuildWork(true);return end
    if guildWorkFrame and (guildWorkFrame~=f or guildWorkTab~=tab)then ResetGuildWork(true)end
    guildWorkFrame,guildWorkTab=f,tab
    for slot = 1, 98 do
        local b = GuildButton(f, slot)
        if b then
            b.laGuildBank = true
            local link = GetGuildBankItemLink(tab, slot)
            if link then
                local count=GuildCount(tab,slot)
                if b.laGuildTab~=tab or b.laLink~=link or b.laGuildCount~=count then LL:ClearButton(b)end
                if not guildJobs[slot]then guildJobCount=guildJobCount+1 end
                guildJobs[slot]={frame=f,tab=tab,slot=slot,button=b,link=link,count=count}
            else
                if guildJobs[slot]then guildJobCount=guildJobCount-1 end
                guildJobs[slot]=nil
                LL:ClearButton(b)
            end
        end
    end
    if guildJobCount>0 and not guildWorkScheduled then
        guildWorkScheduled=true
        if C_Timer and C_Timer.After then C_Timer.After(0,GuildTick)else GuildTick()end
    end
end

function LL:QueueGuildRefresh()
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
        hooksecurefunc(f, "Update", function() LL:QueueGuildRefresh() end)
    elseif type(_G.GuildBankFrame_Update) == "function" then
        hooksecurefunc("GuildBankFrame_Update", function() LL:QueueGuildRefresh() end)
    end
    f:HookScript("OnShow", function() guildOpen = true; LL:QueueGuildRefresh() end)
    f:HookScript("OnHide", function() guildOpen = false;ResetGuildWork(true);LL:QueueGuildRefresh() end)
end

local e = NewNativeObserver()
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
    if event == "GUILDBANKFRAME_CLOSED" then guildOpen = false;ResetGuildWork(true)end
    HookGuild()
    LL:QueueGuildRefresh()
end)

end
