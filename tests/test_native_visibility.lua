-- BetterBags reparents Blizzard bags/bank below a hidden frame. IsShown()
-- remains true on these children; IsVisible() includes the hidden ancestor.
local checks=0
local function check(v,why)assert(v,why);checks=checks+1 end
local function fixture(legacy)
    local timers,events,paints,evaluations={},{},{},{}
    local mutate,version=nil,1
    CreateFrame=function()
        local f={events={}}
        function f:RegisterEvent(event)self.events[event]=true end
        function f:SetScript(_,fn)self.callback=fn end
        events[#events+1]=f;return f
    end
    C_Timer={After=function(_,fn)timers[#timers+1]=fn end}
    debugprofilestop=function()return 0 end
    local function frame(parent)
        local f={parent=parent,shown=true,children={},hooks={}}
        function f:IsShown()return self.shown end
        if not legacy then
            function f:IsVisible()return self.shown and(not self.parent or self.parent:IsVisible())end
        end
        function f:GetChildren()return unpack(self.children)end
        function f:HookScript(event,fn)self.hooks[event]=fn end
        function f:SetScript()end
        if parent then parent.children[#parent.children+1]=f end
        return f
    end
    local ancestor=frame();local bag=frame(ancestor)
    for i=1,13 do _G['ContainerFrame'..i]=nil end
    ContainerFrame1=bag;ContainerFrameCombinedBags=nil;ContainerFrameUtil=nil;ContainerFrame_Update=nil
    local bagButtons={}
    for slot=1,12 do
        local b=frame(bag);b.GetBagID=function()return 0 end
        b.GetID=function()return slot end;bagButtons[slot]=b
    end
    local bank=frame(ancestor);local panel=frame(bank);bank.BankPanel=panel
    BankFrame=bank;BankPanel=nil
    local bankButtons,pool={},{}
    for slot=1,20 do
        local b=frame(panel);b.GetBankTabID=function()return 13 end
        b.GetContainerSlotID=function()return slot end
        bankButtons[slot]=b;pool[b]=true
    end
    panel.EnumerateValidItems=function()return next,pool,nil end
    C_Container={GetContainerItemLink=function(bagID,slot)return'item:'..(1000+bagID*100+slot)end,
        GetContainerItemInfo=function(_,slot)return{stackCount=slot+1,isBound=true}end}
    C_Item=nil;ItemLocation=nil;C_AuctionHouse=nil
    GetCurrentGuildBankTab=function()return 1 end
    GetGuildBankItemLink=function(_,slot)if slot==1 then return'item:9999'end end
    GetGuildBankItemInfo=function()return nil,7 end
    local guild=frame(ancestor);guild.Columns={{Buttons={frame(guild)}}};guild.Update=function()end
    GuildBankFrame=guild
    hooksecurefunc=function(target,method,fn)
        if type(target)=='table'then local original=target[method]
            target[method]=function(...)original(...);fn(...)end
        end
    end
    local LL={db={showBlizzardBags=true,showGuildBank=true}}
    LL.ClearButton=function(_,button)if button then button.laLink=nil;button.laDecision=nil end end
    LL.Evaluate=function(_,link,context)
        evaluations[#evaluations+1]={link=link,context=context}
        local value=(context.count or 1)*100*version
        if mutate then local fn=mutate;mutate=nil;fn()end
        return{action='D',value=value}
    end
    LL.Paint=function(_,button,link,decision)
        button.laLink=link;button.laDecision=decision
        paints[#paints+1]={link=link,value=decision.value,context=evaluations[#evaluations].context}
    end
    assert(loadfile(NATIVE_BAGS_UNDER_TEST or'LootLiquidator/NativeBags.lua'))('LL',LL)
    local function drain()
        local n=0
        while #timers>0 do local fn=table.remove(timers,1);fn();n=n+1;assert(n<1000,'finite work queue')end
    end
    return{LL=LL,ancestor=ancestor,bag=bag,bagButtons=bagButtons,bank=bank,panel=panel,bankButtons=bankButtons,
        guild=guild,paints=paints,evaluations=evaluations,timers=timers,drain=drain,
        mutate=function(fn)mutate=fn end,
        setVersion=function(value)version=value end,
        guildOpen=function()for _,e in ipairs(events)do if e.events.GUILDBANKFRAME_OPENED then e.callback(e,'GUILDBANKFRAME_OPENED')end end end,
        one=function()local fn=table.remove(timers,1);if fn then fn()end end}
end
local hidden=fixture();hidden.ancestor.shown=false
check(hidden.bag:IsShown()and hidden.panel:IsShown()and not hidden.bag:IsVisible()and not hidden.panel:IsVisible(),
    'fixture reproduces true IsShown / false IsVisible under BetterBags hidden parent')
hidden.LL:UpdateBlizzardBags();hidden.drain()
check(#hidden.evaluations==0 and #hidden.paints==0,'hidden native roots perform no duplicate valuation or paint')
hidden.ancestor.shown=true;hidden.LL:UpdateBlizzardBags();hidden.drain()
check(#hidden.evaluations==32 and #hidden.paints==32,'visible native containers and bank resume all actual item decisions')
for _,row in ipairs(hidden.paints)do
    check(row.value==row.context.count*100 and row.context._LLFastBadge==true,
        'visible gold fixture and original count/fast-badge context unchanged')
end
local pending=fixture();pending.bag.shown=false
pending.LL:UpdateBlizzardBags()
check(#pending.evaluations==0 and #pending.timers==1,'native bank initially queues its normal deferred batch')
pending.ancestor.shown=false;pending.drain()
check(#pending.evaluations==0 and #pending.paints==0,'hidden ancestor after enqueue cancels pending bank work')
pending.ancestor.shown=true;pending.LL:UpdateBlizzardBags();pending.drain()
check(#pending.evaluations==20 and #pending.paints==20,'new visible refresh resumes after hidden jobs were discarded')
local children=fixture();children.bagButtons[1].shown=false;children.bankButtons[1].shown=false
children.LL:UpdateBlizzardBags();children.drain()
check(#children.evaluations==30 and #children.paints==30,'hidden individual bag/bank children are not valued or queued')
local inside=fixture();inside.bag.shown=false
inside.LL:UpdateBlizzardBags();inside.mutate(function()inside.ancestor.shown=false end);inside.drain()
check(#inside.evaluations==1 and #inside.paints==0,'hide during first bank evaluation discards its paint and remaining hidden jobs')
local fallback=fixture(true);fallback.LL:UpdateBlizzardBags();fallback.drain()
check(#fallback.evaluations==32 and #fallback.paints==32,'legacy IsShown-only API stubs retain visible behavior')
fallback.panel.shown=false;fallback.bag.shown=false
local before=#fallback.evaluations;fallback.LL:UpdateBlizzardBags();fallback.drain()
check(#fallback.evaluations==before,'legacy IsShown=false still prevents work')
local guild=fixture();guild.ancestor.shown=false;guild.guildOpen();guild.drain()
check(#guild.evaluations==0 and #guild.paints==0,'guild root also honors hidden ancestors')
guild.ancestor.shown=true;guild.LL:QueueGuildRefresh();guild.drain()
check(#guild.evaluations==1 and guild.evaluations[1].context.guild and guild.evaluations[1].context.count==7,
    'visible guild item keeps its distinct original guild/count context')
local queuedGuild=fixture();queuedGuild.guildOpen();queuedGuild.one();queuedGuild.ancestor.shown=false;queuedGuild.drain()
check(#queuedGuild.evaluations==0,'guild hidden after scan cancels queued evaluations')
local refresh=fixture();refresh.LL:QueueBlizzardBagRefresh();refresh.drain()
check(#refresh.evaluations==32,'initial explicit full refresh evaluates all visible native buttons')
refresh.setVersion(2)
for i=1,20 do refresh.LL:QueueBlizzardBagRefresh()end
refresh.drain()
check(#refresh.evaluations==64,'repeated full settings/appearance requests coalesce and still revalue unchanged painted buttons')
for index=33,64 do local row=refresh.paints[index]
    check(row.value==row.context.count*200,'full refresh replaces unchanged badges with current valuation')
end
refresh.LL:QueueBlizzardBagRefresh(0);refresh.drain()
check(#refresh.evaluations==76,'ordinary dirty-bag refresh stays limited to that bag')
refresh.ancestor.shown=false;refresh.LL:QueueBlizzardBagRefresh();refresh.drain()
check(#refresh.evaluations==76,'full requests still skip hidden native ancestors')
refresh.ancestor.shown=true;refresh.setVersion(3);refresh.LL:QueueBlizzardBagRefresh();refresh.drain()
check(#refresh.evaluations==108,'explicit reopen refresh revalues visible same-instance badges after hidden interval')
print('PASS: '..checks..' hidden-native-ancestor, queued cancellation, resume, legacy visibility and unchanged context/value checks')
