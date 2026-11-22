-- More than400 unique GUID/location identities must evict individual old
-- decisions, not flush valid current ones. This drives the actual BB hooks.
local checks=0
local function check(v,label)assert(v,label);checks=checks+1 end
local now,timers,frames=0,{},{}
GetTime=function()return now end
debugprofilestop=function()return 0 end
CreateFrame=function()
    local frame={RegisterEvent=function()end,SetScript=function(self,_,fn)self.callback=fn end}
    frames[#frames+1]=frame;return frame
end
C_Timer={After=function(_,fn)timers[#timers+1]=fn end}
local function drain()
    while #timers>0 do local work=timers;timers={}for _,fn in ipairs(work)do fn()end end
end
local proto={SetItemFromData=function()end,SetFreeSlots=function()end,ClearItem=function()end}
LibStub=function()return{GetAddon=function()return{GetModule=function()return{itemProto=proto}end}end}end
hooksecurefunc=function(target,method,fn)
    local old=target[method];target[method]=function(...)old(...);fn(...)end
end
local LL={db={showBetterBags=true,showBadges=false}}
assert(loadfile(BADGES_UNDER_TEST or 'LootLiquidator/Badges.lua'))('LL',LL)
frames[#frames].callback(nil,'PLAYER_LOGIN')
local evaluations,version,pendingID=0,1,nil
LL.Evaluate=function(_,link,context)
    evaluations=evaluations+1
    local id=tonumber(link:match('item:(%d+)'))
    return{action='V',value=id*10+version,facts={id=id,link=link,context=context,itemInfoPending=id==pendingID}}
end
local instances={}
local function instance(index)
    return{bagid=math.floor((index-1)/36),slotid=(index-1)%36+1,
        itemInfo={itemLink='item:'..(1000+index),itemGUID='Item-instance-'..index,
            stackCount=1,isBound=false}}
end
local function display(data)
    now=now+.001
    local frame={button={IsVisible=function()return true end}}
    proto.SetItemFromData(frame,nil,data);drain()
    return frame
end
for index=1,400 do
    local data=instance(index);instances[index]={data=data,frame=display(data)}
end
check(evaluations==400,'400 unique physical identities are evaluated once')
local data401=instance(401);display(data401)
check(evaluations==401,'capacity permits exactly one new decision evaluation')
proto.ClearItem(instances[2].frame)
local reused=display(instances[2].data)
check(evaluations==401,'a valid non-oldest identity still hits after the401st insertion')
check(reused.button.laDecision.value==10020+version,'a capacity hit preserves the exact decision value')
proto.ClearItem(instances[1].frame)
display(instances[1].data)
check(evaluations==402,'the single oldest identity was evicted, proving the400-entry bound')
for index=402,430 do display(instance(index))end
local before=evaluations
proto.ClearItem(instances[300].frame)
local current=display(instances[300].data)
check(evaluations==before,'many capacity insertions retain a still-recent physical identity')
now=now+31
proto.ClearItem(current)
current=display(instances[300].data)
check(evaluations==before+1,'the original30-second expiry remains authoritative')
version=2
LL:RequestBadgeRefresh(1300)
drain()
check(evaluations==before+2 and current.button.laDecision.value==13002,
    'forced targeted refresh bypasses the cache and installs the new decision')
local moved=instances[300].data
moved.slotid=moved.slotid+1
proto.SetItemFromData(current,nil,moved);drain()
check(evaluations==before+3,'moving the same GUID to another slot cannot reuse an old instance key')
moved.itemInfo.stackCount=2
proto.SetItemFromData(current,nil,moved);drain()
check(evaluations==before+4,'stack-count changes remain part of the physical fingerprint')
moved.itemInfo.isBound=true
proto.SetItemFromData(current,nil,moved);drain()
check(evaluations==before+5 and current.button.laDecision.facts.context.isBound==true,
    'changed binding requires a new decision using actual binding facts')
local incomplete=instance(900);pendingID=1900
local waiting=display(incomplete)
before=evaluations
proto.SetItemFromData(waiting,nil,incomplete);drain()
check(evaluations==before+1,'pending item info is retried even for an unchanged button')
pendingID=nil
proto.SetItemFromData(waiting,nil,incomplete);drain()
before=evaluations
proto.ClearItem(waiting)
display(incomplete)
check(evaluations==before,'resolved item info can enter the bounded recent cache')
LL:ClearBadgeDecisionCache()
display(incomplete)
check(evaluations==before+1,'explicit invalidation still discards every recent decision')
local queued=instance(999)
local holder={button={IsVisible=function()return true end}}
proto.SetItemFromData(holder,nil,queued)
queued.itemInfo.itemGUID='Item-replaced-before-timer'
before=evaluations;drain()
check(evaluations==before and holder.button.laDecision==nil,'stale queued GUID never receives a cached or newly evaluated badge')
print('PASS: '..checks..' bounded BetterBags capacity, expiry, forced refresh and physical-identity checks')
