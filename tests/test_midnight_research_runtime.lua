-- Numerical fixtures exercise the real evidence selector and tooltip renderer.
-- Units/cast and casts-with-a-drop are independent measurements.
local checks=0
local function check(value,label) assert(value,label);checks=checks+1 end
local function near(actual,expected,label)
    check(type(actual)=='number' and math.abs(actual-expected)<1e-9,
        (label or '')..': '..tostring(actual)..' ~= '..tostring(expected))
end
local function clone(value)
    if type(value)~='table' then return value end
    local result={} for key,v in pairs(value) do result[key]=clone(v) end return result
end
GetBuildInfo=function() return '12.1.5','70783' end
GetTime=function() return 100 end
time=function() return 100 end
CreateFrame=function() return {RegisterEvent=function()end,SetScript=function()end} end
local LL={db={characters={Player={}},tooltipDetail=3,showAverageQuantity=false,
    showResearchDetails=false,source_legacy_enabled=false,source_personal_enabled=false,
    source_imported_enabled=false,source_reference_enabled=false}}
for _,name in ipairs({'Professions.lua','ConversionEngine.lua','Database.lua','Badges.lua'}) do
    assert(loadfile('LootLiquidator/'..name))('LL',LL)
end
LL.CharacterKey=function() return 'Player' end
LL.GetResearchProfessionSnapshot=function() return 100,'none' end
LL.GetCachedOperationInfo=function() end
LL.GetOutputPrice=function() return 100 end
LL.MarkupColor=function() return '' end
LL.Money=function(_,value) return tostring(value)..' copper' end
LL.ProfessionProgression=function() return {} end
LL.TooltipConversionOptions=nil -- Render the actual explicitly resolved model.
LL:MigrateEvidenceSettings()
local function field(value,samples,status)
    return {value=value,samples=samples or 500,confidence=100,status=status or 'measured'}
end
local function output(id,mean,chance,lo,hi)
    return {id=id,expectedQuantity=field(mean),dropChance=field(chance),
        minQuantity=field(lo),maxQuantity=field(hi)}
end
local function record(id,materials)
    return {recordID=id,studyID=id,source=id,sourceKey='itemdb',method='Disenchant',
        inputItemID=239671,inputCount=1,recipeID=13262,expansionID=11,samples=500,materials=materials}
end
local old=record('less-specific-strong-looter',{
    output(243602,.697921,.697921,1,1),output(243603,.263158,.263158,1,1)})
old.samples=1130.5
for _,m in ipairs(old.materials) do for _,f in pairs(m) do
    if type(f)=='table' then f.samples=1130.5 end
end end
local counted=record('rare-courtly-units-only',{
    output(243602,.629),output(243603,.660),output(243599,.004),output(243600,.007)})
counted.inputRarity=3;counted.inputClassID=4
local facts={id=239671,quality=3,classID=4,expansionID=11,count=1}
local option={name='Disenchant',letter='D',recipeID=13262,inputCount=1,available=true}
local function install(records)
    LL.ItemDB={schemaVersion=1,version='midnight-runtime-fixture',processing=records,mechanicRules={}}
    check(LL:InitializeItemDB(),LL.itemDBError)
    LL._processingContextCache=nil
end
local function resolve(input)
    LL._processingModelCache=nil
    return LL:ResolveEvidenceModel(input or facts,option,nil,1)
end
local function byID(model,id)
    for _,m in ipairs(model.materials) do if m.id==id then return m end end
end
install({old,counted})
local model=assert(resolve())
near(byID(model,243602).expectedQuantity,.629,'exact rarity cohort wins over larger unspecified study')
near(byID(model,243603).expectedQuantity,.660)
check(byID(model,243599).expectedQuantity>0 and byID(model,243600).expectedQuantity>0,
    'reported bonus material means remain nonzero')
for _,m in ipairs(model.materials) do
    check(m.chance==nil and m.chanceCasts==nil,'unit totals do not establish a hit probability')
    check(m.minQuantity==nil and m.maxQuantity==nil and m.personalHistogram==nil,
        'unit totals do not fabricate ranges or quantity histograms')
    check(m.sourceEstimates.itemdb.studyID==counted.studyID,'source mean retains its own study identity')
end
check(#model.excludedSources==1,'old cohort remains present and separately excluded, not disabled')
near(old.materials[1].dropChance.value,.697921,'original Looter probability is preserved')
local rareContext=LL:ProcessingPlayerConditions(facts,'Disenchant',13262)
local epic=clone(facts);epic.quality=4
local epicContext=LL:ProcessingPlayerConditions(epic,'Disenchant',13262)
check(rareContext~=epicContext and rareContext.inputRarity==3 and epicContext.inputRarity==4,
    'same item ID with another actual rarity has a separate profession context')
check(rareContext.inputClassID==4,'physical input class is captured in context')
-- A projection must not get a chance to normalize away an input mismatch.
local transformed={}
LL.ApplyProfessionModel=function(_,_,_,baseline)
    transformed[baseline.source]=true;return baseline
end
local epicModel=assert(resolve(epic))
check(not transformed[counted.source],'rare cohort is rejected before profession mechanics on an epic copy')
near(byID(epicModel,243602).expectedQuantity,.697921,'original unscoped study remains available separately')
local wrongClass=clone(facts);wrongClass.classID=2
transformed={};assert(resolve(wrongClass))
check(not transformed[counted.source],'input class must match exactly before mechanics')
check(LL:ProcessingPlayerConditions(wrongClass,'Disenchant',13262)~=rareContext,
    'same item ID with another class cannot reuse cached context')
install({counted})
check(resolve(epic)==nil,'rare-only records cannot yield an epic model')
check(resolve(wrongClass)==nil,'armor-only records cannot yield a weapon model')
local noRarity=clone(facts);noRarity.quality=nil
check(resolve(noRarity)==nil,'unknown actual rarity cannot satisfy an exact identity requirement')
local bad=clone(counted);bad.inputRarity='3'
check(not LL:ValidateItemDB({schemaVersion=1,processing={bad}}),'identity metadata must have numeric types')
bad=clone(counted);bad.inputClassID=4.5
check(not LL:ValidateItemDB({schemaVersion=1,processing={bad}}),'identity metadata must use integer class IDs')
-- Unknown-n published means have an explicitly labeled weak prior, rather
-- than zero evidence or a fabricated collection of casts.
local unknown=clone(counted)
unknown.recordID='rare-unknown-n-mean';unknown.studyID=unknown.recordID;unknown.source=unknown.recordID
unknown.samples=0;unknown.sampleSizeKnown=false
unknown.materials={output(243602,1.37)}
local mean=unknown.materials[1].expectedQuantity
mean.samples=0;mean.observedSamples=0;mean.sampleSizeKnown=false;mean.priorWeight=20
mean.status='provisional';mean.confidence=40
install({old,unknown})
near(assert(resolve()).materials[1].expectedQuantity,1.37,'identity-scoped unknown-n mean remains usable')
check(LL:EvidenceReliability(mean,unknown)>0,'unknown sample size receives only the existing weak prior')
local zero=clone(mean);zero.sampleSizeKnown=true
near(LL:EvidenceReliability(zero,{samples=0}),0,'a genuine zero-cast study stays zero evidence')
check(mean.samples==0 and mean.observedSamples==0,'prior weighting does not invent observed casts')
-- Unreviewed generic references retain their old fallback behavior. Compiled
-- category aggregates are tested separately from these legacy fixtures.
local greenFacts=clone(facts);greenFacts.quality=2
local generic=record('generic-uncommon-pooled-mean',{output(243599,2.9)})
generic.inputItemID=nil;generic.gearKey='gear:11:2:armor';generic.inputRarity=2;generic.inputClassID=4
generic.materials[1].expectedQuantity=clone(mean);generic.materials[1].expectedQuantity.value=2.9
generic.samples=0;generic.sampleSizeKnown=false
install({old,generic})
local exact=assert(resolve(greenFacts))
near(byID(exact,243602).expectedQuantity,.697921,'generic pooled mean cannot outrank an exact item study')
check(byID(exact,243599)==nil,'generic expectation is not added on top of exact item outcomes')
-- Research supplies the figures; the saved display preference controls whether
-- average quantities are rendered. Hiding averages does not discard the data.
local function render(resolved)
    LL:ValueProcessingModel(resolved,0,true,facts)
    local tip={lines={},rows={}}
    function tip:AddLine(text) self.lines[#self.lines+1]=text end
    function tip:AddDoubleLine(left,right)
        self.lines[#self.lines+1]=left..' | '..right;self.rows[#self.rows+1]=left
    end
    local quote=clone(option);quote.yieldModel=resolved;quote.value=resolved.value
    LL:AppendRecommendationTooltip(tip,{action='D',facts=facts,conversionOptions={quote}})
    return table.concat(tip.lines,'\n'),table.concat(tip.rows,'\n')
end
install({counted})
local text,rows=render(assert(resolve()))
check(not rows:find('0.629',1,true) and rows:find('chance unavailable',1,true),
    'DE averages stay hidden when the saved average preference is off')
LL.db.showAverageQuantity=true
text,rows=render(assert(resolve()))
check(rows:find('0.629',1,true) and rows:find('chance unavailable',1,true),
    'enabling averages displays the researched mean without inventing probability')
check(not text:find('Personal x',1,true),'units-only study is not presented as a quantity histogram')
local occurrence=record('independent-counts-and-units',{output(243602,.5,.2,1,3)})
occurrence.inputRarity=3;occurrence.inputClassID=4
install({occurrence})
local hitModel=assert(resolve())
near(hitModel.materials[1].chance,.2,'hit probability is based on casts with a drop')
near(hitModel.materials[1].expectedQuantity,.5,'unconditional average is based on material units')
text,rows=render(hitModel)
check(rows:find('20%',1,true) and rows:find('0.500',1,true),'renderer keeps occurrence and units/cast figures distinct')
LL.db.showAverageQuantity=false
text,rows=render(hitModel)
check(rows:find('20%',1,true) and rows:find('[1-3]',1,true) and not rows:find('0.500',1,true),
    'turning averages off preserves the researched chance and range')
near(hitModel.materials[1].expectedQuantity,.5,'the display toggle does not change researched data or valuation')
LL.db.showAverageQuantity=true
-- Finally exercise the real generated record, after the evidence builder and
-- native ItemDB compiler have run, rather than only these controlled fixtures.
local shipped={}
assert(loadfile('LootLiquidator/ItemDBRuntime.lua'))('LL',shipped)
local native
for _,r in ipairs(shipped.ItemDB.processing) do
    if r.inputItemID==239671 and r.inputRarity==3 and r.inputClassID==4 then
        for _,m in ipairs(r.materials) do
            if m.id==243602 and m.expectedQuantity.value==.629 then native=r end
        end
    end
end
check(native,'native ItemDB contains the new identity-scoped Courtly units study')
LL.ItemDB=shipped.ItemDB;check(LL:InitializeItemDB(),LL.itemDBError)
local rareCategory,maxSpecCategory
for _,r in ipairs(shipped.ItemDB.processing) do
    if r.isDisenchantCategory and r.gearKey=='gear:11:3:armor' then
        if r.categoryReferenceOnly then maxSpecCategory=r else rareCategory=r end
    end
end
check(rareCategory and maxSpecCategory,'native ItemDB contains the ordinary and separate max-specialization categories')
local nativeModel=assert(resolve())
check(nativeModel.gearKey=='gear:11:3:armor','ordinary Courtly gear uses the shared rare-armor category')
local referenceContext=clone(rareContext);referenceContext.referenceContextID=maxSpecCategory.referenceContextID
local maxSpec=assert(LL:ComputeEvidenceModel(facts,option,nil,1,referenceContext,true))
near(byID(maxSpec,243602).expectedQuantity,.629,'named max-specialization reference retains its own mean')
near(byID(maxSpec,243603).expectedQuantity,.660)
check(byID(maxSpec,243602).chance==nil,'units-only category does not borrow ordinary cohort probabilities')
-- Different source items and an unseen item resolve the same shared category.
local dustFacts={id=258931,quality=3,classID=4,expansionID=11,count=1}
local dust=assert(resolve(dustFacts))
near(byID(dust,243599).chance,byID(nativeModel,243599).chance,'matching source items share category occurrence estimates')
near(byID(dust,243599).expectedQuantity,byID(nativeModel,243599).expectedQuantity,
    'matching source items share category unit estimates')
local unseen=clone(dustFacts);unseen.id=999999
local unseenModel=assert(resolve(unseen))
near(byID(unseenModel,243599).expectedQuantity,byID(dust,243599).expectedQuantity,'an unseen item receives category research')
check(byID(dust,243599).minQuantity==1 and byID(dust,243599).maxQuantity==3)
text,rows=render(dust)
check(rows:find(string.format('%.3f',byID(dust,243599).expectedQuantity),1,true),
    'native tooltip displays the shared category mean under the saved preference')
local crystalFacts={id=250456,quality=4,classID=4,expansionID=11,count=1}
local crystals=assert(resolve(crystalFacts))
check(math.abs(byID(crystals,243605).chance-190/318)<.0000005,'native category crystal probability uses its counted cohort')
near(byID(crystals,243605).expectedQuantity,byID(crystals,243605).chance,'fixed-one source stack makes E equal P for that category')
print('PASS: '..checks..' Midnight DE category, cohort isolation, units/probability and native compilation assertions')
