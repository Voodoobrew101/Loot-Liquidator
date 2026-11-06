local LL={db={tooltipDetail=3}}
CreateFrame=function()return {RegisterEvent=function()end,SetScript=function()end}end
assert(loadfile('LootLiquidator/Badges.lua'))('LootLiquidator',LL)
LL.MarkupColor=function()return ''end
LL.Money=function(_,n)return tostring(n)..' copper'end
LL.ProfessionProgression=function()return {}end
local a={id=10,chance=.2,expectedQuantity=.375,minQuantity=1,maxQuantity=2,netExpectedValue=3}
local b={id=20,chance=.8,expectedQuantity=2,minQuantity=2,maxQuantity=2,netExpectedValue=9}
local zero={id=30,chance=0,expectedQuantity=0,netExpectedValue=0}
local unknown={id=40}
local original={unknown,a,zero,b}
local function order(mode,expected)
    LL.db.tooltipOutputSort=mode
    local sorted=LL:SortedTooltipMaterials(original)
    for i,id in ipairs(expected) do assert(sorted[i].id==id,mode..' row '..i) end
    assert(original[1]==unknown and original[2]==a and original[3]==zero and original[4]==b,'cached model unchanged')
end
order('value',{20,10,30,40})
a.chance=.9
order('chance',{10,20,30,40})
a.chance=.2
a.expectedQuantity=3
order('quantity',{10,20,30,40})
a.expectedQuantity=.375
order('database',{40,10,30,20})
order('invalid-saved-value',{20,10,30,40})
C_Item={GetItemInfo=function(id)return ({[10]='Zinc',[20]='amber',[30]='Copper'})[id]end}
order('name',{20,30,10,40})
local model={inputCount=5,materials={a,b},confidence=50,value=12}
local function render(show,method)
    LL.db.showAverageQuantity=show
    local tip={lines={}}
    function tip:AddLine(s)self.lines[#self.lines+1]=s end
    function tip:AddDoubleLine(l,r)self.lines[#self.lines+1]=l..' | '..r end
    LL:AppendRecommendationTooltip(tip,{action='P',facts={id=1,classID=7,count=5},count=5,
        conversionOptions={{name=method or 'Prospect',letter='P',available=true,value=12,yieldModel=model}}})
    return table.concat(tip.lines,'\n')
end
local hidden=render(nil)
assert(hidden:find('[1-2]',1,true) and hidden:find('[2]',1,true),'yield ranges omit x')
assert(not hidden:find('[x',1,true) and not hidden:find('0.375',1,true),'average hidden by default')
assert(hidden:find('copper',1,true),'gold value stays visible')
local shown=render(true)
assert(shown:find('0.375',1,true),'average can be enabled independently')
assert(not shown:find('Per 5 input',1,true) and not shown:find('Unadjusted reference',1,true),
    'processing explanations hidden by default')
LL.db.showTooltipExplanations=true
local explained=render(true)
assert(explained:find('Per 5 input',1,true) and explained:find('average units include zeros',1,true)
    and explained:find('Unadjusted reference',1,true),'advanced option restores both explanations')
LL.db.showTooltipExplanations=false
assert(not render(true):find('Unadjusted reference',1,true),'explanations hide again')
assert(model.value==12 and a.netExpectedValue==3 and b.netExpectedValue==9,'presentation leaves economic values unchanged')
-- Technical details are independent opt-ins; core values remain visible.
model.sources={legacy=100};LL.SourceOrder={'legacy'}
model.context={profession='Enchanting',effectiveSkill=104,character='Tester',profileKind='live'}
local plain=render(false)
assert(not plain:find('effective contribution',1,true) and not plain:find('skill 104',1,true))
LL.db.showResearchDetails=true
assert(render(false):find('effective contribution',1,true))
assert(not render(false):find('skill 104',1,true))
LL.db.showProfessionDetails=true
assert(render(false):find('skill 104',1,true) and render(false):find('Tester (live)',1,true))
LL.db.showProfessionDetails=false;LL.db.showResearchDetails=false
-- Simulated and disenchanting results honor the same saved preference.
-- Empirical confidence must not be claimed for assumed material quantities.
model.syntheticBenchmark=true;model.confidence=0;a.confidence=0;b.confidence=0
LL.db.showMaterialConfidence=true
local assumed=render(false)
assert(assumed:find('Simulated assumptions',1,true) and not assumed:find('0.375',1,true))
assert(render(true):find('0.375',1,true),'simulated averages appear only when enabled')
assert(not assumed:find('Confidence 0%',1,true) and not assumed:find('(0%)',1,true),
    'synthetic quantities have assumptions, not measured numeric confidence')
model.syntheticBenchmark=nil
assert(not render(false,'Disenchant'):find('0.375',1,true),'disenchanting cannot override hidden averages')
assert(render(true,'Disenchant'):find('0.375',1,true),'disenchanting follows the enabled average preference')
-- Sort the complete list before the normal twelve-row limit is applied.
LL.db.tooltipOutputSort='value'
local many={}
for i=1,13 do many[i]={id=i,netExpectedValue=i} end
assert(LL:SortedTooltipMaterials(many)[1].id==13 and many[1].id==1)
print('PASS: optional averages, compact yields, five output sort choices and cached-model isolation')
