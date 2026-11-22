-- Retired convenience stats must not change item quantities, input savings or
-- money. Native achieved crafting quality remains an authoritative output ID.
local checks=0
local function check(v,label)assert(v,label);checks=checks+1 end
local function near(a,b,label)check(type(a)=='number' and math.abs(a-b)<1e-9,label..': '..tostring(a)..' ~= '..tostring(b))end
local function copy(v)
    if type(v)~='table' then return v end
    local out={}for k,x in pairs(v)do out[k]=copy(x)end return out
end
local function same(a,b)
    if type(a)~=type(b)then return false end
    if type(a)~='table'then return a==b end
    for k,v in pairs(a)do if not same(v,b[k])then return false end end
    for k in pairs(b)do if a[k]==nil then return false end end return true
end
local LL={}
assert(loadfile('LootLiquidator/ProfessionCalculations.lua'))('LL',LL)
assert(loadfile('LootLiquidator/ConversionEngine.lua'))('LL',LL)
local effects={}
local retired={'craftingSpeed','ingenuity','inspiration','concentrationCost','concentrationRefund',
    'nonOutput','recipeUnlock','eligibility'}
for index,metric in ipairs(retired)do
    effects[#effects+1]={entryID=index,metric=metric,amount=50,unit='percent',confidence=0,recipeIDs={1}}
end
LL.ItemDB={professionProfiles={profiles={['Alchemy:10']={statKeys={'resourcefulness','multicraft'},nodes={
    [1]={maxRank=1,learningEffects=effects}}}},professionParameters={Alchemy={
    MinCraftExtraQtyPct=50,MaxCraftExtraQtyPct=150,ResourcefulEffectLow=20,ResourcefulEffectHigh=40}},
    recipes={[1]={profession='Alchemy',expansionID=10,supportsMulticraft=true,supportsResourcefulness=true,
        supportsQuality=true,qualityOrderVerified=true,outputQualityItems={{id=2001},{id=2002}},
        qualityThresholds={{rank=2,fraction=1}},difficulty=100}}}}
LL.GetOutputPrice=function(_,id)return id==1001 and 40 or 100 end
local facts={id=1001,expansionID=10,quality=1,classID=7}
local option={name='Craft',recipeID=1,inputCount=5,supportsMulticraft=true}
local context={skill=0,stats={resourcefulness={percent=50},multicraft={percent=25}}}
local plain=LL:ProfessionProfileParameters('Alchemy',10,context,option,facts)
local noisy=copy(context)
noisy.specializationPoints={[1]=1}
noisy.stats.craftingSpeed={percent=100,rating=999}
noisy.stats.ingenuity={percent=100,rating=999}
noisy.stats.inspiration={percent=100,rating=999}
noisy.duration=10;noisy.durationIncludesSpeed=true;noisy.concentrationCost=100
noisy.concentrationRefund=.5;noisy.ingenuityRefund=50;noisy.ingenuityRefundFraction=.5
local beforeContext=copy(noisy)
local changed=LL:ProfessionProfileParameters('Alchemy',10,noisy,option,facts)
check(same(noisy,beforeContext),'parameter calculation preserves raw operation metadata')
near(changed.confidence,plain.confidence,'retired zero-confidence effects do not weaken material evidence')
check(#changed.appliedEffects==0 and next(changed.effectTotals)==nil,'retired effects have no runtime projection bookkeeping')
for _,key in ipairs({'duration','baseDuration','speedFactor','concentrationCost','concentrationRefund',
    'expectedConcentrationCost','unlocks','simulatedEligibility','eligible'})do
    check(changed[key]==nil,'no unrelated projected parameter '..key)
end
for _,key in ipairs({'craftingSpeed','ingenuity','inspiration'})do check(changed.stats[key]==nil,'no unrelated calculated stat '..key)end
near(changed.outputFactor,1.25,'native Multicraft still changes actual Craft output units')
near(changed.inputFactor,.85,'native Resourcefulness still saves inputs')
local raw={inputCount=5,expectedInputCount=5,duration=10,concentrationCost=100,confidence=80,
    materials={{id=2001,expectedQuantity=2,confidence=80,chance=1,minQuantity=2,maxQuantity=2}}}
local beforeRaw=copy(raw)
local projected=LL:ProjectProfessionBaseline(raw,changed,option)
near(projected.materials[1].expectedQuantity,2.5,'Craft output projection keeps its quantity effect')
near(projected.expectedInputCount,4.25,'input projection retains the saved-input expectation')
near(LL:ValueProcessingModel(projected,0,true,facts),56,'gold includes output units and saved input value exactly once')
local untouched=LL:ProjectProfessionBaseline(raw,plain,option)
near(LL:ValueProcessingModel(untouched,0,true,facts),projected.value,'retired fields cannot change gold')
check(same(raw,beforeRaw),'projection and pricing never rewrite source observations or time metadata')
near(projected.duration,10,'source duration metadata is copied without a forecast transform')
near(projected.concentrationCost,100,'source concentration metadata is copied without a forecast transform')
local observation=copy(projected);observation.rawProfessionBaseline=nil
local normalized=LL:NormalizeProfessionBaseline(observation,changed,option)
near(normalized.materials[1].expectedQuantity,2,'retained quantity transform still has an exact inverse')
near(normalized.expectedInputCount,5,'retained saved-input transform still has an exact inverse')
local nodes=LL.ItemDB.professionProfiles.profiles['Alchemy:10'].nodes
nodes[2]={maxRank=1,learningEffects={{entryID=20,metric='yieldMultiplier',amount=20,
    unit='percent',confidence=90,condition={contextFlags={matchedTarget=true}}}}}
local conditional=copy(context);conditional.specializationPoints={[2]=1}
local unselected=LL:ProfessionProfileParameters('Alchemy',10,conditional,option,facts)
near(unselected.outputFactor,plain.outputFactor,'output rules still require their real target context')
conditional.contextFlags={matchedTarget=true}
local selected=LL:ProfessionProfileParameters('Alchemy',10,conditional,option,facts)
near(selected.outputFactor,1.5,'matching target context preserves its output quantity effect')
near(LL:ValueProcessingModel(LL:ProjectProfessionBaseline(raw,selected,option),0,true,facts),66,
    'matching material-affecting context reaches gold through actual projected units')
for _,method in ipairs({'Prospect','Mill','Crush','Smelt','Recycle','Disenchant','Use'})do
    local op=copy(option);op.name=method
    local parameters=LL:ProfessionProfileParameters('Alchemy',10,noisy,op,facts)
    near(parameters.outputFactor,1,method..' cannot receive a Craft-only Multicraft output bonus')
    local model=LL:ProjectProfessionBaseline(raw,parameters,op)
    near(model.materials[1].expectedQuantity,2,method..' keeps per-operation units')
    if method=='Disenchant' or method=='Use'then
        near(parameters.inputFactor,1,method..' cannot receive Resourcefulness savings')
        near(LL:ValueProcessingModel(model,0,true,facts),40,method..' value uses only its unchanged output')
    else
        near(parameters.inputFactor,.85,method..' keeps supported Resourcefulness savings')
        near(LL:ValueProcessingModel(model,0,true,facts),46,method..' value includes input savings without extra outputs')
    end
end
-- The native operation already reports the quality achieved with concentration.
-- Removing concentration forecasts must not discard that actual item identity.
local native=copy(noisy)
native.operationStatsIncludeSpecialization=true;native.craftingQuality=2
native.concentrationApplied=true;native.operationStats={}
local beforeNative=copy(native)
LL.ProcessingPlayerConditions=function()return native end
local crafted=LL:ProfessionCraftModel(facts,{method='Craft',profession='Alchemy',recipeID=1,
    inputCount=5,outputID=2001,outputCount=2})
check(crafted.qualityRank==2 and crafted.materials[1].id==2002,
    'native achieved quality retains the correct crafted item despite zero simulated skill')
near(LL:ValueProcessingModel(crafted,0,true,facts),56,'native high-quality Craft remains valued through the same quantity/input math')
check(same(native,beforeNative),'actual native quality and concentration metadata remain unchanged')
print('PASS: '..checks..' item-processing metrics, quantity/input gold and native achieved-quality checks')
