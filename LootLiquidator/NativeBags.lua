-- Native Blizzard bags, banks and guild-bank adapters.
local ADDON, LL = ...
local subscriptions={}
local eventFrame=CreateFrame("Frame")
local function NewNativeObserver()
    local observer={events={}}
    function observer:RegisterEvent(event)
        self.events[event]=true
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
local ADDON, LL = ...
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
    if not frame or not frame.IsShown or not frame:IsShown() then return end
    local num=frame.GetNumChildren and frame:GetNumChildren() or 0
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
                    if LL.RememberATTItem then LL:RememberATTItem(link) end
                    LL:Paint(b,link,LL:Evaluate(link,ItemContext(bag,slot)))
                else
                    LL:ClearButton(b)
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
        if job and panel and panel.IsShown and panel:IsShown()
            and button.IsShown and button:IsShown() then
            local bag,slot=BankButtonCoordinates(button)
            local link=bag and C_Container and C_Container.GetContainerItemLink
                and C_Container.GetContainerItemLink(bag,slot)
            if bag==job.bag and slot==job.slot and link==job.link then
                if LL.RememberATTItem then LL:RememberATTItem(link) end
                local decision=LL:Evaluate(link,ItemContext(bag,slot))
                LL:Paint(button,link,decision)
                button.laBlizzardBag=true
                button.laBagID,button.laSlotID=bag,slot
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
    if not panel or not panel.IsShown or not panel:IsShown() then return end
    local function VisitButton(button)
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
        local changed = fullPending and nil or changedBags
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
    if event == "GUILDBANKFRAME_CLOSED" then guildOpen = false end
    HookGuild()
    LA:QueueGuildRefresh()
end)

end
