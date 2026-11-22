-- Deterministic frame/timer fixtures, not live FPS or valuation benchmarks.
local checks=0
local function check(v,why)assert(v,why);checks=checks+1 end
local function fixture(costs,clock)
    local now,queue,delays,frames,evals,paints,batches=0,{},{},{},{},{},{}
    local frameMs=1000/60
    GetTime=function()return now/1000 end
    debugprofilestop=clock and function()return now end or nil
    CreateFrame=function()
        local frame={RegisterEvent=function()end,SetScript=function(self,_,fn)self.event=fn end}
        frames[#frames+1]=frame;return frame
    end
    C_Timer={After=function(delay,fn)
        delays[#delays+1]=delay
        local earliest=now+delay*1000
        local nextFrame=(math.floor(now/frameMs)+1)*frameMs
        local at=math.max(nextFrame,math.ceil((earliest-1e-7)/frameMs)*frameMs)
        queue[#queue+1]={at=at,fn=fn}
    end}
    local proto={SetItemFromData=function()end,SetFreeSlots=function()end,ClearItem=function()end}
    LibStub=function()return{GetAddon=function()return{GetModule=function()return{itemProto=proto}end}end}end
    hooksecurefunc=function(target,name,fn)
        local original=target[name];target[name]=function(...)original(...);fn(...)end
    end
    C_Item={GetItemLocation=function(guid)return{guid=guid}end,DoesItemExist=function()return true end,
        IsBound=function(location)return location.guid:find('bound',1,true)~=nil end,
        IsBoundToAccountUntilEquip=function()return false end}
    local LL={db={showBetterBags=true,showBadges=false}}
    assert(loadfile(BADGES_UNDER_TEST or'LootLiquidator/Badges.lua'))('LL',LL)
    frames[#frames].event(nil,'PLAYER_LOGIN')
    local version=0
    LL.Evaluate=function(_,link,context)
        local id=tonumber(link:match('item:(%d+)'));now=now+(costs[id]or 0)
        local value=id*10+(context.count or 1)+(context.isBound and 10000 or 0)
            +(context.verifiedUnbound and 1000 or 0)+version
        local decision={action=context.isBound and'D'or'A',value=value,
            facts={id=id,link=link,context=context}}
        evals[#evals+1]={id=id,action=decision.action,value=value,context=context}
        return decision
    end
    local paint=LL.Paint
    LL.Paint=function(self,button,link,result)
        paints[#paints+1]={id=result.facts.id,action=result.action,value=result.value}
        return paint(self,button,link,result)
    end
    local function display(id,guid,count)
        local item={button={IsVisible=function(self)return not self.hidden end}}
        local data={guid=guid or'instance-'..id,bagID=0,slotID=id,
            itemInfo={itemLink='item:'..id,stackCount=count or id%3+1}}
        proto.SetItemFromData(item,nil,data);return item,data
    end
    local function drain()
        local n=0
        while #queue>0 do
            local job=table.remove(queue,1);now=math.max(now,job.at)
            local before,started=#evals,now;job.fn()
            local batch={jobs=#evals-before,workMs=now-started,startedMs=started,finishedMs=now}
            batches[#batches+1]=batch
            check(batch.jobs<=8,'existing maximum of8 evaluations per callback retained')
            if clock and batch.jobs>1 then
                local costBeforeLast=0
                for i=before+1,#evals-1 do costBeforeLast=costBeforeLast+(costs[evals[i].id]or 0)end
                check(costBeforeLast<3,'measured3ms budget stops further jobs once consumed')
            end
            n=n+1;assert(n<1000,'finite queued work')
        end
    end
    return{LL=LL,proto=proto,display=display,drain=drain,delays=delays,evals=evals,paints=paints,batches=batches,
        finished=function()return now end,setVersion=function(v)version=v end}
end
local mixedCosts={.25,.25,.25,6,.25,16,.25,.25,.25,195,6,16,.25,.25,.25,.25}
local mixed=fixture(mixedCosts,true)
for id=1,#mixedCosts do mixed.display(id,id%2==0 and'bound-'..id or'free-'..id)end
check(#mixed.evals==0,'queuing remains asynchronous')
mixed.drain();check(#mixed.evals==#mixedCosts,'all cheap and slow items eventually evaluate exactly once')
for id,result in ipairs(mixed.evals)do
    local bound=id%2==0
    check(result.id==id and result.action==(bound and'D'or'A'),'queue order and binding-derived decision preserved')
    check(result.value==id*10+(id%3+1)+(bound and 10000 or 1000),
        'exact count, binding and fixture valuation preserved')
    check(result.context._LLFastBadge and result.context.bagID==0 and result.context.slotID==id,
        'same instance location/count context reaches evaluation')
end
local worst=0;for _,batch in ipairs(mixed.batches)do worst=math.max(worst,batch.workMs)end
check(worst>=195,'an individual195ms decision remains uninterruptible and visible in batch cost')
local noClock=fixture({},false)
for id=1,20 do noClock.display(id)end
noClock.drain();check(#noClock.evals==20 and #noClock.batches==3,
    'missing profiler still uses the unchanged8-job cap')
check(noClock.batches[1].jobs==8 and noClock.batches[2].jobs==8 and noClock.batches[3].jobs==4,
    'no-clock callback grouping remains8/8/4')
local pooled=fixture({},true)
local stale,data=pooled.display(1,'free-original',2)
data.guid='bound-replacement-before-tick';pooled.drain()
check(#pooled.evals==0 and stale.button.laDecision==nil,'mutated queued GUID never paints a stale result')
pooled.proto.SetItemFromData(stale,nil,data);pooled.drain()
check(#pooled.evals==1 and stale.button.laDecision.action=='D','current physical replacement receives its own native binding answer')
data.itemInfo.stackCount=7;pooled.proto.SetItemFromData(stale,nil,data);pooled.drain()
check(#pooled.evals==2 and stale.button.laDecision.value==10017,'changed same-instance count receives a fresh exact answer')
local hidden=pooled.display(2);hidden.button.hidden=true;pooled.drain()
check(#pooled.evals==2,'hidden queued item remains skipped')
hidden.button.hidden=false
local replacement={guid='free-latest',bagID=0,slotID=2,itemInfo={itemLink='item:3',stackCount=9}}
pooled.proto.SetItemFromData(hidden,nil,replacement)
for i=1,20 do pooled.proto.SetItemFromData(hidden,nil,replacement)end
pooled.drain()
check(#pooled.evals==3 and hidden.button.laDecision.value==1039,'pooled latest item and duplicate host updates coalesce into one current decision')
pooled.setVersion(5);pooled.LL:RequestBadgeRefresh(3);pooled.drain()
check(#pooled.evals==4 and hidden.button.laDecision.value==1044,'forced refresh still applies current valuation')
local function receipt(s)
    local fixed=0;for _,delay in ipairs(s.delays)do fixed=fixed+delay*1000 end
    return{scheduledDelays=s.delays,fixedCooldownMs=fixed,simulatedFinishedMs=s.finished(),
        evaluations=#s.evals,batches=s.batches,decisions=s.paints}
end
if not BADGE_SCHEDULING_OBSERVE_ONLY then
    for _,s in ipairs({mixed,noClock,pooled})do for _,delay in ipairs(s.delays)do
        check(delay==0,'all pending work resumes next frame without additional60/200/30ms waits')
    end end
end
print('PASS: '..checks..' next-frame scheduling,3ms/8-job budgets, mixed slow calls and instance/valuation guards')
return{mixed=receipt(mixed),noClock=receipt(noClock),pooled=receipt(pooled)}
