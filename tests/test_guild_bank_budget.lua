-- Drive the native guild-bank event/timer adapter with98 actual slot-shaped
-- fixtures. Values are deterministic test figures, not game price estimates.
local checks=0
local function check(v,label)assert(v,label);checks=checks+1 end
local function setup(cost)
    local frames,timers,slots,buttons,paints,contexts={},{},{},{},{},{}
    local visible,tab,profiler=true,1,0
    local version,evaluations=1,0
    local mutate
    CreateFrame=function()
        local f={events={},RegisterEvent=function(self,e)self.events[e]=true end,
            SetScript=function(self,_,fn)self.callback=fn end}
        frames[#frames+1]=f;return f
    end
    C_Timer={After=function(delay,fn)timers[#timers+1]={delay=delay,fn=fn}end}
    debugprofilestop=function()return profiler end
    ContainerFrame_Update=nil;ContainerFrameUtil=nil;ContainerFrameCombinedBags=nil
    for i=1,13 do _G['ContainerFrame'..i]=nil end
    for bank=1,2 do
        slots[bank]={}
        for slot=1,98 do slots[bank][slot]={link='item:'..(bank*1000+slot),count=slot%5+1}end
    end
    local frame={Columns={},mode='bank',hooks={},IsShown=function()return visible end,
        HookScript=function(self,event,fn)self.hooks[event]=fn end,Update=function()end}
    for slot=1,98 do
        local b={slot=slot}
        local column=math.ceil(slot/14);frame.Columns[column]=frame.Columns[column]or{Buttons={}}
        frame.Columns[column].Buttons[(slot-1)%14+1]=b;buttons[slot]=b
    end
    GuildBankFrame=frame
    GetCurrentGuildBankTab=function()return tab end
    GetGuildBankItemLink=function(t,s)return slots[t][s]and slots[t][s].link end
    GetGuildBankItemInfo=function(t,s)return nil,slots[t][s]and slots[t][s].count end
    hooksecurefunc=function(target,method,fn)
        local old=target[method];target[method]=function(...)old(...);fn(...)end
    end
    local LL={db={showGuildBank=true,showBlizzardBags=false}}
    LL.ClearButton=function(_,button)if button then button.laLink=nil;button.laDecision=nil end end
    LL.Paint=function(_,button,link,result)
        button.laLink=link;button.laDecision=result
        paints[#paints+1]={slot=button.slot,link=link,value=result.value,tab=tab,count=result.count}
    end
    LL.Evaluate=function(_,link,context)
        evaluations=evaluations+1;profiler=profiler+cost
        contexts[#contexts+1]=context
        local result={value=tonumber(link:match('%d+'))*10+context.count+version,count=context.count}
        if mutate then local fn=mutate;mutate=nil;fn()end
        return result
    end
    assert(loadfile('LootLiquidator/NativeBags.lua'))('LL',LL)
    local function event(name)
        for _,f in ipairs(frames)do if f.events[name]then f.callback(f,name)end end
    end
    local function one()
        local t=table.remove(timers,1);if not t then return 0 end
        local before=evaluations;t.fn();return evaluations-before
    end
    local function drain()
        local iterations=0
        while #timers>0 do
            check(one()<=8,'each callback evaluates at most8 guild slots')
            iterations=iterations+1;check(iterations<1000,'event work remains coalesced and finite')
        end
    end
    return{LL=LL,frame=frame,buttons=buttons,slots=slots,paints=paints,contexts=contexts,
        event=event,one=one,drain=drain,timers=timers,
        count=function()return evaluations end,
        setTab=function(v)tab=v end,setVersion=function(v)version=v end,
        setVisible=function(v)visible=v;frame.hooks[v and 'OnShow'or'OnHide']()end,
        mutateNext=function(fn)mutate=fn end}
end
local s=setup(0)
s.event('GUILDBANKFRAME_OPENED')
for i=1,20 do s.LL:QueueGuildRefresh()end
check(#s.timers==1,'rapid open/update events coalesce into one latest-tab scan')
check(s.one()==0 and s.count()==0,'initial scan never synchronously values all98 items')
check(s.one()==8,'without a timer limit a work callback still caps at8 items')
s.drain()
check(s.count()==98 and #s.paints==98,'every occupied slot eventually receives exactly one initial answer')
for _,context in ipairs(s.contexts)do
    check(context.guild==true and context._LLFastBadge==true and type(context.count)=='number',
        'guild/count context remains identical to the original adapter')
end
s.setVersion(2);s.LL:QueueGuildRefresh();s.one()
check(s.buttons[1].laDecision.value==10013,'same-instance prior badge remains until its replacement is ready')
s.drain()
check(s.buttons[1].laDecision.value==10014,'full refresh still installs current evaluated values')
local slow=setup(2)
slow.event('GUILDBANKFRAME_OPENED');slow.one()
check(slow.one()==2,'approximately3ms budget yields after two2ms test evaluations')
slow.drain();check(slow.count()==98,'time budget does not discard slow items')
local hidden=setup(0)
hidden.event('GUILDBANKFRAME_OPENED');hidden.one();hidden.setVisible(false);hidden.drain()
check(hidden.count()==0 and #hidden.paints==0,'hiding cancels queued work before any stale paint')
hidden.setVisible(true);hidden.drain()
check(hidden.count()==98,'showing again evaluates the latest visible tab')
local changed=setup(0)
changed.event('GUILDBANKFRAME_OPENED');changed.one();changed.setTab(2)
changed.LL:QueueGuildRefresh();changed.drain()
check(#changed.paints==98,'rapid tab switch replaces the old work with one latest tab')
for _,paint in ipairs(changed.paints)do check(paint.tab==2 and paint.link:find('item:2',1,true)==1,
    'a previous tab cannot paint into recycled guild buttons')end
local during=setup(0)
during.event('GUILDBANKFRAME_OPENED');during.one()
during.mutateNext(function()during.setTab(2)end);during.drain()
check(during.count()==99 and #during.paints==98,'a tab changed during evaluation discards the first answer and all old pending work')
for _,paint in ipairs(during.paints)do check(paint.tab==2,'post-evaluation tab identity is rechecked')end
local replaced=setup(0)
replaced.event('GUILDBANKFRAME_OPENED');replaced.one()
replaced.mutateNext(function()replaced.slots[1][1]={link='item:9999',count=17}end);replaced.drain()
check(replaced.buttons[1].laLink=='item:9999'and replaced.buttons[1].laDecision.count==17,
    'changed link/count is re-read and receives a newly evaluated answer')
for _,paint in ipairs(replaced.paints)do check(paint.slot~=1 or paint.link=='item:9999',
    'old slot identity never paints after an asynchronous replacement')end
local quantity=setup(0)
quantity.event('GUILDBANKFRAME_OPENED');quantity.one()
quantity.mutateNext(function()quantity.slots[1][1].count=22 end);quantity.drain()
check(quantity.buttons[1].laDecision.count==22,'same link with a changed count must be re-evaluated')
for _,paint in ipairs(quantity.paints)do check(paint.slot~=1 or paint.count==22,
    'old stack-count-dependent answer is never published')end
local mode=setup(0)
mode.event('GUILDBANKFRAME_OPENED');mode.one();mode.frame.mode='log';mode.drain()
check(mode.count()==0,'guild logs mode cancels bank badge work')
mode.frame.mode='bank';mode.frame.Update();mode.drain()
check(mode.count()==98,'returning to bank mode refreshes all current slots')
local disabled=setup(0)
disabled.event('GUILDBANKFRAME_OPENED');disabled.one();disabled.LL.db.showGuildBank=false;disabled.drain()
check(disabled.count()==0 and #disabled.paints==0,'turning guild badges off cancels pending valuation and paint')
disabled.LL.db.showGuildBank=true;disabled.LL:QueueGuildRefresh();disabled.drain()
check(disabled.count()==98,'turning guild badges back on values the current tab normally')
disabled.LL.db.showGuildBank=false;disabled.LL:QueueGuildRefresh();disabled.drain()
check(disabled.buttons[1].laDecision==nil and disabled.buttons[98].laDecision==nil,
    'disabling after a completed batch clears prior guild badges')
local missing=setup(0)
missing.event('GUILDBANKFRAME_OPENED');missing.one()
missing.frame.Columns[1].Buttons[1]=nil;missing.drain()
for _,paint in ipairs(missing.paints)do check(paint.slot~=1,'a removed guild button never receives a stale paint')end
check(missing.buttons[1].laDecision==nil and missing.buttons[98].laDecision~=nil,
    'an unavailable button is discarded while the remaining slots complete')
local api=setup(0)
api.event('GUILDBANKFRAME_OPENED');api.one()
local linkAPI=GetGuildBankItemLink;GetGuildBankItemLink=nil;api.drain()
check(api.count()==0,'temporarily unavailable guild item API safely cancels pending work')
GetGuildBankItemLink=linkAPI;api.frame.Update();api.drain()
check(api.count()==98,'restored native API supplies a fresh complete batch')
local closeDuring=setup(0)
closeDuring.event('GUILDBANKFRAME_OPENED');closeDuring.one()
closeDuring.mutateNext(function()closeDuring.setVisible(false)end);closeDuring.drain()
check(closeDuring.count()==1 and #closeDuring.paints==0,'closing during an evaluation cannot publish its result or run remaining jobs')
print('PASS: '..checks..' guild-bank bounded work, current values, count/link/tab guards and event coalescing checks')
