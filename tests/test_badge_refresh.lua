-- Reproduce per-cast Invalidate -> BetterBags refresh with an instance GUID
-- and binding facts resolved from the native item-location APIs.
local now,profiler,timers,frames=0,0,{},{}
local checks=0
local function check(v,message)assert(v,message);checks=checks+1 end
GetTime=function()return now end;debugprofilestop=function()return profiler end
wipe=function(t)for k in pairs(t)do t[k]=nil end;return t end
SlashCmdList={};STANDARD_TEXT_FONT='test'
CreateFrame=function()
    local f={RegisterEvent=function()end,SetScript=function(self,_,fn)self.callback=fn end}
    frames[#frames+1]=f;return f
end
C_Timer={After=function(delay,fn)timers[#timers+1]={at=now+delay,fn=fn}end}
local function advance(seconds)
    local finish=now+seconds
    while true do
        local index,best
        for i,t in ipairs(timers)do if t.at<=finish and (not best or t.at<best.at)then index,best=i,t end end
        if not index then break end
        table.remove(timers,index);now=best.at;best.fn()
    end
    now=finish
end
local proto={SetItemFromData=function()end,SetFreeSlots=function()end,ClearItem=function()end}
local bb={GetModule=function()return {itemProto=proto}end}
LibStub=function()return {GetAddon=function()return bb end}end
hooksecurefunc=function(target,method,fn)
    local original=target[method]
    target[method]=function(...)original(...);fn(...)end
end
C_Item={GetItemLocation=function()return {}end,DoesItemExist=function()return true end,
    IsBound=function()return false end,IsBoundToAccountUntilEquip=function()return true end}
local LL={}
assert(loadfile('LootLiquidator/Core.lua'))('LL',LL)
LL.db={showBadges=true,showBetterBags=true}
assert(loadfile('LootLiquidator/Badges.lua'))('LL',LL)
frames[#frames].callback(nil,'PLAYER_LOGIN')
LL.GetBadgeColor=function()return {1,0,1}end
local action,evaluations='D',0
LL.Evaluate=function(_,link,context)
    evaluations=evaluations+1;profiler=profiler+20 -- exercise deferred work
    return {action=action,facts={link=link,context=context}}
end
local function button()
    local b={otherBadgeVisible=true}
    function b:IsVisible()return true end
    function b:CreateFontString()
        local f={visible=false,hides=0,ClearAllPoints=function()end,SetPoint=function()end,
            SetFont=function()end,SetTextColor=function()end}
        function f:SetText(text)self.text=text end
        function f:Show()self.visible=true end
        function f:Hide()self.visible=false;self.hides=self.hides+1 end
        return f
    end
    return b
end
local b=button();local item={button=b}
local data={guid='Item-original',itemInfo={itemLink='item:10',stackCount=1,bagID=0,slotID=1}}
proto.SetItemFromData(item,nil,data);advance(1)
check(b.laLetter.visible and b.laLetter.text=='D','initial item receives its D')
check(b.laDecision.facts.context.verifiedWarbound,'native binding evidence was resolved')
local fingerprint=b.laBadgeFingerprint
local initialHides=b.laLetter.hides
for i=1,10 do
    LL:Invalidate()
    check(b.laLetter.visible,'unchanged item must keep D visible while refresh is queued')
    check(b.laBadgeFingerprint==fingerprint,'forced refresh preserves the actual instance identity')
    advance(1)
    proto.SetItemFromData(item,nil,data)
    check(b.laLetter.visible,'host redraw after refresh must not hide the same item')
    advance(1)
end
check(b.laLetter.hides==initialHides,'repeated recording refreshes never clear an unchanged badge')
check(evaluations==11,'each forced refresh evaluates once; identical host redraws reuse it')
action='V';LL:Invalidate()
check(b.laLetter.visible and b.laLetter.text=='D','keep prior decision only until replacement is ready')
advance(1)
check(b.laLetter.visible and b.laLetter.text=='V','a changed recommendation replaces the displayed letter')

-- The same hyperlink can identify a different physical item. It must clear.
local replacement={guid='Item-replacement',itemInfo={itemLink='item:10',stackCount=1,bagID=0,slotID=1}}
proto.SetItemFromData(item,nil,replacement)
check(not b.laLetter.visible,'a changed GUID clears the previous instance immediately')
advance(1);check(b.laLetter.visible,'the replacement receives a fresh decision')
LL:Invalidate();check(b.laLetter.visible,'replacement source data survives its initial clear')
advance(1)
replacement.itemInfo.stackCount=2
proto.SetItemFromData(item,nil,replacement)
check(not b.laLetter.visible,'changed stack count is not mistaken for an unchanged item')
advance(1)
proto.SetFreeSlots(item)
check(not b.laLetter.visible and not b.laBetterBagsData,'free slots release badge and source data')
check(b.otherBadgeVisible,'other addons\' badges are untouched')

-- A pooled data table can be mutated before its pending timer runs.
LL:ClearBadgeDecisionCache()
proto.SetItemFromData(item,nil,replacement)
replacement.guid='Item-mutated-before-timer'
advance(1)
check(not b.laLetter.visible,'mutated queued identity must not paint a stale decision')
proto.SetItemFromData(item,nil,replacement);advance(1)
check(b.laLetter.visible,'a subsequent real host update recovers normally')
proto.SetItemFromData(item,nil,data);proto.ClearItem(item);advance(1)
check(not b.laLetter.visible and not b.laBetterBagsData,'clearing cancels pending work and releases its source')
print('PASS: '..checks..' BetterBags refresh assertions: no D flicker, fresh decisions, pooled identity and binding safety')
