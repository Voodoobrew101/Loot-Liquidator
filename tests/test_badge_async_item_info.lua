-- Same BetterBags instance, asynchronous static item info; no mouseover involved.
local now,timers,frames,checks=0,{},{},0
local function check(value,message)assert(value,message);checks=checks+1 end
GetTime=function()return now end;STANDARD_TEXT_FONT='test';SlashCmdList={}
wipe=function(t)for key in pairs(t)do t[key]=nil end end
CreateFrame=function()
 local f={events={}}
 function f:RegisterEvent(event)self.events[event]=true end
 function f:SetScript(_,callback)self.callback=callback end
 frames[#frames+1]=f;return f
end
C_Timer={After=function(delay,callback)timers[#timers+1]={at=now+delay,callback=callback}end}
local function advance()
 while #timers>0 do
  local job=table.remove(timers,1);now=math.max(now,job.at);job.callback()
 end
 now=now+1
end
local proto={SetItemFromData=function()end,SetFreeSlots=function()end,ClearItem=function()end}
LibStub=function()return{GetAddon=function()return{GetModule=function()return{itemProto=proto}end}end}end
hooksecurefunc=function(target,key,hook)
 local original=target[key];target[key]=function(...)original(...);hook(...)end
end
local pending,gearVendor,auction,conversion=false,100,100000,0
local calls={[10]=0,[11]=0}
C_Item={GetItemInfoInstant=function(link)
 local id=tonumber(link:match('item:(%d+)'))
 return id,'Fixture','Fixture','',123,id==10 and 4 or 7,2
end,GetItemInfo=function(link)
 if pending then return nil end
 local id=tonumber(link:match('item:(%d+)'))
 return 'Fixture '..id,link,4,305,1,'Fixture','Fixture',1,'INVTYPE_HEAD',123,
  id==10 and gearVendor or 1,id==10 and 4 or 7,2,id==10 and 1 or 0,11
end,GetItemLocation=function(guid)return{guid=guid}end,
 DoesItemExist=function()return true end,IsBound=function(loc)return loc.guid=='gear'end,
 IsBoundToAccountUntilEquip=function()return false end}
local LL={}
assert(loadfile('LootLiquidator/Core.lua'))('LL',LL)
LL.db={enabled=true,showBadges=true,showBetterBags=true,showSoulboundVendorBadge=true}
LL.DisenchantEligibility=function()return false end;LL.EligibleDisenchant=function()return false end
LL.BestConversion=function(_,facts)
 calls[facts.id]=(calls[facts.id]or 0)+1;facts.conversionOptions={}
 if facts.id==10 and conversion>0 then return{name='Disenchant',value=conversion}end
end
LL.AuctionUnit=function(_,facts)return facts.id==11 and auction>0 and auction or nil end
LL.ReportMissing=function()end;LL.GetBadgeColor=function()return{1,1,1}end
assert(loadfile('LootLiquidator/Badges.lua'))('LL',LL)
local events=frames[#frames];events.callback(nil,'PLAYER_LOGIN')
check(events.events.GET_ITEM_INFO_RECEIVED,'Existing event frame subscribes to item readiness')
local function button()
 local b={}
 function b:IsVisible()return true end
 function b:CreateFontString()
  local f={hides=0,ClearAllPoints=function()end,SetPoint=function()end,SetFont=function()end,SetTextColor=function()end}
  function f:SetText(text)self.text=text end
  function f:Show()self.visible=true end
  function f:Hide()self.visible=false;self.hides=self.hides+1 end
  return f
 end
 return b
end
local gear,reagent=button(),button()
local gearItem,reagentItem={button=gear},{button=reagent}
local gearData={guid='gear',itemInfo={itemLink='item:10',stackCount=1,bagID=0,slotID=1}}
local reagentData={guid='reagent',itemInfo={itemLink='item:11',stackCount=1,bagID=0,slotID=2}}
proto.SetItemFromData(gearItem,nil,gearData);proto.SetItemFromData(reagentItem,nil,reagentData);advance()
check(gear.laLetter.visible and gear.laLetter.text=='V','Ready bound gear receives V under the existing opt-in')
check(reagent.laLetter.visible and reagent.laLetter.text=='A','Ready profitable reagent receives A')
local originalFacts=gear.laDecision.facts
local hides=gear.laLetter.hides
pending=true;LL:Invalidate();advance()
check(gear.laLetter.visible and gear.laLetter.text=='V','Pending static metadata cannot replace the same ready V with hidden')
check(gear.laLetter.hides==hides,'Same-item metadata refresh does not clear the badge')
check(gear.laDecision.facts.itemInfoPending and gear.laDecision.facts.itemInfoFromSnapshot,
 'The reused static facts retain explicit pending provenance')
check(gear.laDecision.facts.vendor==100 and gear.laDecision.facts.quality==4,'Only verified static metadata is reused')
check(gear.laDecision.facts.context~=originalFacts.context,'Current instance context is read afresh')
local gearCalls=calls[10]
proto.SetItemFromData(gearItem,nil,gearData);advance()
check(calls[10]==gearCalls+1,'A pending decision cannot become an unchanged-host-draw cache hit')
check(gear.laLetter.visible and gear.laLetter.text=='V','Consecutive pending reads retain the verified static snapshot')
for pass=1,5 do
 local previous=gear.laDecision.facts
 LL:Invalidate();advance()
 local current=gear.laDecision.facts
 check(gear.laLetter.visible and gear.laLetter.text=='V'and gear.laLetter.hides==hides,
  'Repeated background pending pass '..pass..' must not flicker V')
 check(current.vendor==100 and current.quality==4 and current.itemInfoPending
  and current.itemInfoFromSnapshot==true,'Verified static provenance survives pending pass '..pass)
 check(current.context~=previous.context,'Each pending pass receives a fresh current context')
 for _,value in pairs(current)do check(value~=previous,'Pending facts cannot retain a chain to the previous facts')end
 for _,value in pairs(current.context)do check(value~=previous and value~=previous.context,
  'Current context cannot retain the previous facts or context')end
end

-- Live pricing and processing decisions must keep changing even while static
-- item metadata is pending. No prior A or conversion quote is passed as facts.
auction=0;conversion=500000;LL:Invalidate();advance()
check(gear.laLetter.text=='D','A genuine conversion change replaces V during a pending metadata read')
check(reagent.laLetter.text=='V','A genuine auction-price change replaces A during a pending metadata read')
conversion=0;pending=false;gearVendor=0
events.callback(nil,'GET_ITEM_INFO_RECEIVED',10,true);advance()
check(not gear.laLetter.visible and gear.laDecision.vendor==0,'Ready vendor0 overrides the old100 on the targeted item event')
check(not gear.laDecision.facts.itemInfoPending,'Ready item data leaves the pending state')
check(reagent.laDecision.facts.itemInfoPending,'The targeted ready event does not repaint another pending item')

-- A ready zero must also bypass a still-live ready100 decision in Core's cache.
gearVendor=100;LL:RequestBadgeRefresh(10);advance()
check(gear.laLetter.visible and gear.laLetter.text=='V','Ready positive vendor quote repaints V')
gearVendor=0;LL:RequestBadgeRefresh(10);advance()
check(not gear.laLetter.visible and gear.laDecision.vendor==0,'Ready zero is part of decision cache identity')

pending=true;gearVendor=100;LL:Invalidate();advance()
gearCalls=calls[10];local reagentCalls=calls[11]
events.callback(nil,'GET_ITEM_INFO_RECEIVED',999,true)
events.callback(nil,'GET_ITEM_INFO_RECEIVED',10,false);advance()
check(calls[10]==gearCalls and calls[11]==reagentCalls,'Unrelated/failed item-info events do not trigger all-bag work')
pending=false;events.callback(nil,'GET_ITEM_INFO_RECEIVED',10,true);advance()
check(calls[10]==gearCalls+1 and calls[11]==reagentCalls,'A successful event refreshes only the matching pending item')

-- Snapshot data never supplies binding/count/location, and changed identities
-- never borrow a previous instance's ready facts.
pending=true
local fresh=LL:GetItemFacts('item:10',{count=7,isBound=false,bagID=9,slotID=4},originalFacts)
check(fresh.count==7 and fresh.context.isBound==false and fresh.context.bagID==9 and fresh.context.slotID==4,
 'Current context/count/location win over the old snapshot')
local other=LL:GetItemFacts('item:12',{count=1},originalFacts)
check(other.vendor==0 and other.quality==nil and not other.itemInfoFromSnapshot,'A different hyperlink cannot use the old static facts')
gearData.guid='replacement';proto.SetItemFromData(gearItem,nil,gearData)
check(not gear.laLetter.visible,'Changed GUID clears the old recommendation immediately')
advance()
check(not gear.laDecision.facts.itemInfoFromSnapshot and gear.laDecision.vendor==0,
 'Changed physical instance does not inherit the prior snapshot')
gearData.itemInfo.stackCount=2;proto.SetItemFromData(gearItem,nil,gearData)
check(not gear.laLetter.visible,'Changed stack count clears the old recommendation')
advance()
check(gear.laDecision.count==2 and not gear.laDecision.facts.itemInfoFromSnapshot,'Changed stack is evaluated with its own current context')

-- Timer-less hosts use the same guarded static fallback, with no extra cache.
C_Timer=nil;pending=false;gearVendor=100;gearData.guid='gear';gearData.itemInfo.stackCount=1
proto.SetItemFromData(gearItem,nil,gearData)
check(gear.laLetter.visible and gear.laLetter.text=='V','Synchronous adapter can paint a ready item')
pending=true;LL:RequestBadgeRefresh(10)
check(gear.laLetter.visible and gear.laLetter.text=='V'and gear.laDecision.facts.itemInfoFromSnapshot,
 'Synchronous same-item refresh also keeps verified static facts')
pending=false;gearVendor=0;events.callback(nil,'GET_ITEM_INFO_RECEIVED',10,true)
check(not gear.laLetter.visible and gear.laDecision.vendor==0,'Synchronous ready event also honors a real zero')
print(('PASS: %d asynchronous same-item badge checks; no pending V flicker, targeted readiness, live quote changes and strict instance identity'):format(checks))
