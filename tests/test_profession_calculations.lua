-- Distinct profession metrics: units, input savings, time, concentration and
-- eligibility. A catalog entry need not increase per-operation output units.
local checks=0
local function check(value,label) assert(value,label);checks=checks+1 end
local function near(actual,expected,label)
    check(type(actual)=='number' and math.abs(actual-expected)<1e-8,
        label..': '..tostring(actual)..' ~= '..tostring(expected))
end
local function copy(value)
    if type(value)~='table' then return value end
    local result={} for key,item in pairs(value) do result[key]=copy(item) end return result
end
local function same(a,b)
    if type(a)~=type(b) then return false end
    if type(a)~='table' then return a==b end
    for key,value in pairs(a) do if not same(value,b[key]) then return false end end
    for key in pairs(b) do if a[key]==nil then return false end end
    return true
end
GetBuildInfo=function() return '12.1.5','70961' end
GetTime=function() return 100 end
time=function() return 100 end
CreateFrame=function() return {RegisterEvent=function()end,SetScript=function()end} end
local LL={db={}}
for _,file in ipairs({'ItemDBRuntime.lua','ProfessionCatalog.lua','Professions.lua',
    'ProfessionModels.lua','ProfessionCalculations.lua'}) do
    assert(loadfile('LootLiquidator/'..file))('LL',LL)
end
local metadata=assert(LL.ItemDB.professionProfiles,'compiled profession profiles required')
local matrix={
    {'Alchemy','Craft',1230854},{'Blacksmithing','Craft',1229598},
    {'Enchanting','Craft',1236098},{'Engineering','Craft',1229755},
    {'Herbalism','Gather'},{'Inscription','Craft',1230016},
    {'Jewelcrafting','Craft',1230437},{'Leatherworking','Craft',1237486},
    {'Mining','Gather'},{'Skinning','Skin'},{'Tailoring','Craft',1227926},
    {'Cooking','Craft',1226166},{'Fishing','Fish'},
}
local function context(profession,points)
    return {profession=profession,expansionID=11,skill=100,effectiveSkill=100,
        preSpecializationSkill=100,simulated=true,profileKind='manual-simulation',
        specialization='none',specializationPoints=points or {},learnedSpecializations={},
        stats={},duration=10,craftTime=10,concentrationCost=100}
end
local function facts(profession) return {id=999999,classID=7,quality=2,expansionID=11,profession=profession} end
local function option(method,recipe) return {name=method,recipeID=recipe,inputCount=5} end
local function parameters(profession,method,recipe,ctx)
    return assert(LL:ProfessionProfileParameters(profession,11,ctx or context(profession),
        option(method,recipe),facts(profession)))
end
local function units(model,id)
    for _,material in ipairs(model.materials or {}) do if material.id==id then return material.expectedQuantity end end
end
local nodeCount,milestoneCount,profileCount=0,0,0
for _,row in ipairs(matrix) do
    local profession,method,recipe=row[1],row[2],row[3]
    check(metadata.professionParameters[profession],profession..' has native profession parameters')
    for _,expansion in ipairs({9,10,11}) do
        local profile=assert(metadata.profiles[profession..':'..expansion],profession..' era profile absent')
        profileCount=profileCount+1
        for id,node in pairs(profile.nodes or {}) do
            nodeCount=nodeCount+1
            check(type(id)=='number' and type(node.maxRank or node.maxInvestedRank)=='number',
                'catalog identity and invested cap retained')
            local last=-1
            for _,milestone in ipairs(node.milestones or {}) do
                milestoneCount=milestoneCount+1
                check(milestone.rank>=0 and milestone.rank>last,'actual milestone boundaries are ordered')
                last=milestone.rank
                if milestone.rank==0 then check(#(milestone.effects or {})==0,'learning effect is not applied twice at rank zero') end
            end
        end
    end
    local ctx=context(profession)
    local params=parameters(profession,method,recipe,ctx)
    check(type(params.skill)=='number' and params.skill>=0,profession..' has a numerical skill metric')
    check(type(params.outputFactor)=='number' and params.outputFactor>=0,profession..' has a finite output factor')
    check(type(params.inputFactor)=='number' and params.inputFactor>0,profession..' has an invertible input factor')
    local source={inputCount=5,expectedInputCount=5,materials={{id=999998,expectedQuantity=2,confidence=80}},
        duration=10,concentrationCost=100,confidence=80}
    local before=copy(source)
    local normalized=assert(LL:NormalizeProfessionBaseline(source,params,option(method,recipe)))
    local projected=assert(LL:ProjectProfessionBaseline(normalized,params,option(method,recipe)))
    near(units(projected,999998),2,profession..' source normalization and projection round trip')
    check(same(source,before),profession..' retains its source observations')
    local twice=LL:ProjectProfessionBaseline(projected,params,option(method,recipe))
    near(units(twice,999998),units(projected,999998),profession..' projection is idempotent')
    for _,material in ipairs(projected.materials) do
        check(material.samples==nil and material.chance==nil,profession..' model creates no observations or hit probability')
    end
end
check(profileCount==39,'all thirteen professions across three modern eras are exercised')
check(nodeCount==727,'every compiled specialization node is accounted for')
check(milestoneCount>nodeCount,'actual milestone inventory is tested, not a fabricated fixed node schedule')

for _,row in ipairs({{'Enchanting','Disenchant'},{'Inscription','Mill'},
    {'Jewelcrafting','Prospect'},{'Jewelcrafting','Crush'}}) do
    local ctx=context(row[1]);ctx.stats.multicraft={percent=100}
    local plain=parameters(row[1],row[2],nil)
    local changed=parameters(row[1],row[2],nil,ctx)
    near(changed.outputFactor,plain.outputFactor,row[2]..' does not inherit crafting Multicraft')
end
local rf=context('Enchanting');rf.stats.resourcefulness={percent=100}
near(parameters('Enchanting','Disenchant',nil,rf).inputFactor,1,'Disenchant has no Resourcefulness savings')
local mill=context('Inscription');mill.stats.resourcefulness={percent=25}
local millParams=parameters('Inscription','Mill',nil,mill)
check(millParams.inputFactor<1,'milling Resourcefulness changes input consumption')
near(millParams.outputFactor,parameters('Inscription','Mill',nil).outputFactor,
    'milling Resourcefulness does not multiply material output per completed cast')

-- Real recipe labels prevent Light talent bonuses from reaching Void potions.
local void=parameters('Alchemy','Craft',1230867,context('Alchemy',{['107103']=10}))
local light=parameters('Alchemy','Craft',1230867,context('Alchemy',{['107106']=10}))
local neutral=parameters('Alchemy','Craft',1230867)
check(void.skill>neutral.skill,'Void skill points affect the matching real recipe')
near(light.skill,neutral.skill,'Light skill points do not leak to a Void recipe')
-- The native quality join, rather than numerical item order, identifies ranks.
local potion=assert(metadata.recipes[1230867])
check(potion.qualityOrderVerified,'actual potion quality identities are source-verified')
check(potion.outputQualityItems[1].id==241303 and potion.outputQualityItems[2].id==241302,
    'the lower numerical potion ID is the higher quality')
local savedConditions=LL.ProcessingPlayerConditions
local potionContext=context('Alchemy');potionContext.preSpecializationSkill=0
LL.ProcessingPlayerConditions=function() return potionContext end
local potionOption={method='Craft',profession='Alchemy',recipeID=1230867,inputCount=1,outputID=241303,outputCount=5}
local lowPotion=assert(LL:ProfessionCraftModel(facts('Alchemy'),potionOption))
check(lowPotion.qualityRank==1 and lowPotion.materials[1].id==241303,'low skill selects the verified rank-one potion')
potionContext.preSpecializationSkill=600
local highPotion=assert(LL:ProfessionCraftModel(facts('Alchemy'),potionOption))
check(highPotion.qualityRank==2 and highPotion.materials[1].id==241302,'high skill selects the verified rank-two potion')
near(highPotion.materials[1].expectedQuantity,lowPotion.materials[1].expectedQuantity,
    'quality changes potion identity while conserving the native five-unit output')
potionContext.stats.resourcefulness={percent=25}
local fixedBeforeBenchmark=assert(LL:ProfessionCraftModel(facts('Alchemy'),potionOption))
local unscaledFixed=copy(fixedBeforeBenchmark)
potionContext.benchmark={outputLevel=160,specializationBonus=25,resourcefulnessChance=50,resourcefulnessSaved=40}
local benchmarkContextBefore=copy(potionContext);local potionOptionBefore=copy(potionOption)
local fixedBenchmark=assert(LL:ProfessionCraftModel(facts('Alchemy'),potionOption))
check(fixedBenchmark.syntheticBenchmark,'fixed native crafting applies the selected benchmark')
near(fixedBenchmark.materials[1].expectedQuantity,fixedBeforeBenchmark.materials[1].expectedQuantity*2,
    'fixed craft output level and specialization bonus multiply final native units exactly once')
near(fixedBenchmark.expectedInputCount,.8,'benchmark Resourcefulness replaces the native input saving')
near(fixedBenchmark.supplyCostFactor,.8,'fixed craft supply costing uses the replacement Resourcefulness factor')
check(fixedBeforeBenchmark.expectedInputCount~=.8,'the replacement is distinct from the existing native input factor')
check(fixedBenchmark.confidence==0 and fixedBenchmark.materials[1].confidence==0,'fixed craft benchmark retains confidence zero')
check(LL:ApplySyntheticBenchmark(facts('Alchemy'),option('Craft',1230867),fixedBenchmark,potionContext)==fixedBenchmark,
    'fixed craft benchmark replay does not scale its output twice')
check(same(fixedBeforeBenchmark,unscaledFixed),'benchmark evaluation preserves the preceding native model')
check(same(potionContext,benchmarkContextBefore) and same(potionOption,potionOptionBefore),
    'fixed native crafting preserves the selected profile and recipe inputs')
near(fixedBenchmark.rawProfessionBaseline.materials[1].expectedQuantity,5,'fixed craft source baseline remains five native units')
LL.ProcessingPlayerConditions=savedConditions
local rfBase=context('Alchemy');rfBase.expansionID=9;rfBase.stats.resourcefulness={percent=100}
local rfTalent=copy(rfBase);rfTalent.specializationPoints={['19535']=10}
local craft=option('Craft',405832)
local dfFacts=facts('Alchemy');dfFacts.expansionID=9
local plainRefund=assert(LL:ProfessionProfileParameters('Alchemy',9,rfBase,craft,dfFacts))
local strongerRefund=assert(LL:ProfessionProfileParameters('Alchemy',9,rfTalent,craft,dfFacts))
check(strongerRefund.inputFactor<plainRefund.inputFactor,'Resourcefulness-saving talent improves the input metric')
near(strongerRefund.outputFactor,plainRefund.outputFactor,
    'additional reagents saved by Resourcefulness are not additional output materials')

local fast=context('Alchemy');fast.stats.craftingSpeed={percent=25}
local timed=parameters('Alchemy','Craft',1230867,fast)
check(timed.duration<neutral.duration,'crafting speed improves duration')
near(timed.outputFactor,neutral.outputFactor,'crafting speed does not multiply per-cast output units')
local efficient=context('Alchemy');efficient.stats.ingenuity={percent=25}
local concentration=parameters('Alchemy','Craft',1230867,efficient)
check(concentration.expectedConcentrationCost<concentration.concentrationCost,
    'Ingenuity changes expected concentration use')
near(concentration.outputFactor,neutral.outputFactor,'Ingenuity does not multiply output units')
for _,row in ipairs({{'Herbalism','Gather'},{'Mining','Gather'},{'Skinning','Skin'}}) do
    local plain=parameters(row[1],row[2])
    local deft=context(row[1]);deft.stats.deftness={percent=25}
    local quicker=parameters(row[1],row[2],nil,deft)
    check(quicker.duration<plain.duration,row[1]..' Deftness changes gathering duration')
    near(quicker.outputFactor,plain.outputFactor,row[1]..' Deftness does not change units per target')
    local finesse=context(row[1]);finesse.stats.finesse={percent=25}
    check(parameters(row[1],row[2],nil,finesse).outputFactor>plain.outputFactor,
        row[1]..' Finesse changes the declared gathering quantity metric')
    local perception=context(row[1]);perception.stats.perception={percent=25}
    local rare=parameters(row[1],row[2],nil,perception)
    check(rare.rareDiscoveryFactor>plain.rareDiscoveryFactor,row[1]..' Perception changes rare discovery')
    near(rare.outputFactor,plain.outputFactor,row[1]..' Perception is separate from common quantity')
end

local baseCalibration=context('Alchemy')
baseCalibration.stats.multicraft={rating=100,percent=20}
baseCalibration.statAnchors={multicraft={rating=100,percent=20}}
baseCalibration.statCalibration={multicraft={rating=100,percent=20,source='native-operation'}}
local changedCalibration=copy(baseCalibration);changedCalibration.stats.multicraft.rating=200
local originalCalibration=copy(baseCalibration)
local anchored=parameters('Alchemy','Craft',1230867,baseCalibration)
local ratingChange=parameters('Alchemy','Craft',1230867,changedCalibration)
near(anchored.stats.multicraft,.2,'native percentage anchor is preserved')
near(ratingChange.stats.multicraft,.4,'rating delta uses the declared calibration')
check(same(baseCalibration,originalCalibration),'parameter evaluation does not mutate stat anchors')
local manualTalent=context('Alchemy',{['107101']=20})
manualTalent.stats.multicraft={rating=240,percent=12}
manualTalent.statAnchors={multicraft={rating=240,percent=12}}
manualTalent.statCalibration={multicraft={rating=300,percent=15,source='native-operation'}}
local manualParams=parameters('Alchemy','Craft',1230867,manualTalent)
local nativeTalent=copy(manualTalent)
nativeTalent.simulated=false;nativeTalent.profileKind='live';nativeTalent.stats=nil;nativeTalent.statAnchors=nil
-- This path grants 120 rating at full investment, including its milestones.
nativeTalent.operationStats={{bonusStatName='Multicraft',bonusStatValue=360,ratingPct=18}}
nativeTalent.operationStatsIncludeSpecialization=true
local nativeParams=parameters('Alchemy','Craft',1230867,nativeTalent)
near(nativeParams.stats.multicraft,manualParams.stats.multicraft,'native talent stats are not added twice')

local additive=copy(neutral);additive.outputFactor=2;additive.extraOutputs={[999998]=.5}
local mathematicalBaseline={inputCount=1,materials={{id=999998,expectedQuantity=2,confidence=80}},confidence=80}
local projected=assert(LL:ProjectProfessionBaseline(mathematicalBaseline,additive,option('Craft',1230867)))
near(units(projected,999998),4.5,'additive outputs follow the multiplicative operation')
local freshObservation=copy(projected);freshObservation.rawProfessionBaseline=nil
near(units(assert(LL:NormalizeProfessionBaseline(freshObservation,additive,option('Craft',1230867))),999998),2,
    'inverse subtracts additive quantity before dividing by the output factor')
near(units(assert(LL:NormalizeProfessionBaseline(projected,additive,option('Craft',1230867))),999998),2,
    'normalization recognizes its already retained canonical baseline')
local relative=copy(additive);relative.relativeExtraOutputs={[999998]=.5}
local relativeProjection=assert(LL:ProjectProfessionBaseline(mathematicalBaseline,relative,option('Craft',1230867)))
near(units(relativeProjection,999998),6.5,'a relative increase multiplies its existing outcome before additive units')
local relativeObservation=copy(relativeProjection);relativeObservation.rawProfessionBaseline=nil
near(units(assert(LL:NormalizeProfessionBaseline(relativeObservation,relative,option('Craft',1230867))),999998),2,
    'relative and additive outcome adjustments invert in their forward order')
local boundParams=copy(neutral);boundParams.nontradableExtraOutputs={[219150]=.5}
local personalProjected=LL:ProjectProfessionBaseline(mathematicalBaseline,boundParams,option('Craft',1230867))
personalProjected.generalProfessionParameters=boundParams;personalProjected.generalProjectedSources={personal=true}
personalProjected.sources={personal=1};personalProjected.generalProjectionInputCount=1
local withAdditions=LL:ApplyGeneralProfessionAdditions(facts('Alchemy'),option('Craft',1230867),personalProjected)
local boundUnits,boundRows=0,0
for _,m in ipairs(withAdditions.materials) do if m.id==219150 and m.economicPolicy=='nontradable' then boundUnits=boundUnits+m.expectedQuantity;boundRows=boundRows+1 end end
near(boundUnits,.5,'a projected personal bound byproduct is not added a second time after fusion')
check(boundRows==1,'a bound byproduct keeps one physical output row')

local conditionalTested=false
for key,profile in pairs(metadata.profiles) do
    if conditionalTested then break end
    for nodeID,node in pairs(profile.nodes) do
        local candidates={}
        for _,effect in ipairs(node.pointEffects or {}) do candidates[#candidates+1]={effect=effect,rank=1} end
        for _,effect in ipairs(node.learningEffects or {}) do candidates[#candidates+1]={effect=effect,rank=1} end
        for _,milestone in ipairs(node.milestones) do
            if milestone.rank>0 then for _,effect in ipairs(milestone.effects) do
                candidates[#candidates+1]={effect=effect,rank=milestone.rank}
            end end
        end
        for _,candidate in ipairs(candidates) do
            local effect=candidate.effect;local c=effect.condition
            if not conditionalTested and c and c.contextFlags and next(c.contextFlags)
                and not c.requiresActiveBuff and not c.event and not (effect.scope or {}).scopeUnknown then
                local ctx=context(profile.profession,{[tostring(nodeID)]=candidate.rank})
                ctx.expansionID=profile.expansionID
                local op=option((effect.scope or {}).method or 'Craft')
                op.labels=(effect.scope or {}).labelIDs
                local input=facts(profile.profession);input.expansionID=profile.expansionID
                input.quality=(effect.scope or {}).inputRarity or input.quality
                local function countEffect(params)
                    local count=0
                    for _,applied in ipairs(params.appliedEffects) do
                        if applied.entryID==effect.entryID and applied.metric==effect.metric then count=count+1 end
                    end
                    return count
                end
                local absent=LL:ProfessionProfileParameters(profile.profession,profile.expansionID,ctx,op,input)
                ctx.contextFlags={}
                for flag,value in pairs(c.contextFlags) do ctx.contextFlags[type(flag)=='number' and value or flag]=true end
                local present=LL:ProfessionProfileParameters(profile.profession,profile.expansionID,ctx,op,input)
                check(countEffect(absent)==0,'context-specific effects are inactive without their actual flag')
                check(countEffect(present)>0,'actual context flag activates the matching typed effect')
                conditionalTested=true
            end
        end
    end
end
check(conditionalTested,'an actual compiled context-conditional effect is exercised')

-- Evaluate every source-backed point/learning/milestone handler at a matching
-- scope. This proves dispatch and conditions, not a fictional output gain for
-- convenience, unlock, time or unresolved-identity effects.
local recipeIndex,defaultRecipe={},{}
for id,recipe in pairs(metadata.recipes) do
    local key=recipe.profession..':'..tostring(recipe.expansionID)
    recipeIndex[key]=recipeIndex[key] or {};defaultRecipe[key]=defaultRecipe[key] or id
    for _,label in ipairs(recipe.labels or {}) do recipeIndex[key][label]=recipeIndex[key][label] or id end
end
local exercised,unknownScope,gatherScopes,unresolvedBuff,dedicated,targetFiltered=0,0,0,0,0,0
local function exerciseEffect(profile,nodeID,node,effect,rank,learned,perPoint)
    local scope=effect.scope or {}
    if scope.scopeUnknown then unknownScope=unknownScope+1;return end
    local key=profile.profession..':'..profile.expansionID
    local method=scope.method or 'Craft'
    local recipe
    for _,label in ipairs(scope.labelIDs or {}) do
        recipe=recipe or (recipeIndex[key] and recipeIndex[key][label])
    end
    recipe=recipe or defaultRecipe[key]
    local op=option(method,recipe)
    -- Gathering/loot spell labels describe a target rather than a craft recipe.
    op.labels=scope.labelIDs
    local ctx=context(profile.profession,{[tostring(nodeID)]=rank})
    ctx.expansionID=profile.expansionID
    if learned then ctx.learnedSpecializations[tostring(nodeID)]=true end
    local c=effect.condition or {}
    if c.event then ctx.events={[c.event]=true} end
    if c.requiresActiveBuff then
        ctx.activeBuffs={};for _,id in ipairs(c.spellIDs or {}) do ctx.activeBuffs[id]=true end
    end
    ctx.contextFlags={}
    for flag,value in pairs(c.contextFlags or {}) do ctx.contextFlags[type(flag)=='number' and value or flag]=true end
    for flag,value in pairs(effect.requiredContextFlags or {}) do ctx.contextFlags[type(flag)=='number' and value or flag]=true end
    local input=facts(profile.profession);input.expansionID=profile.expansionID
    if scope.inputItemIDs then input.id=scope.inputItemIDs[1] end
    input.quality=scope.inputRarity or 2;input.classID=scope.inputClassID or 4
    local params=assert(LL:ProfessionProfileParameters(profile.profession,profile.expansionID,ctx,op,input))
    local found=false
    for _,applied in ipairs(params.appliedEffects) do
        if applied.entryID==effect.entryID and applied.metric==effect.metric and applied.mechanism==effect.mechanism then
            found=true
            check(type(applied.amount)=='number','matching handler preserves a numeric metric')
        end
    end
    if effect.dedicatedHandler then
        check(not found,'a dedicated specialization formula is not applied again by the generic handler')
        for _,ruleID in ipairs(effect.dedicatedRuleIDs or {}) do
            local present=false
            for _,rule in ipairs(LL.ItemDB.specializationRules or {}) do
                if rule.ruleID==ruleID then present=true end
            end
            for _,baseline in ipairs(LL.ItemDB.modeledDisenchantBaselines or {}) do
                if baseline.rule.ruleID==ruleID then present=true end
            end
            check(present,'dedicated dispatch retains its executable rule identity')
        end
        dedicated=dedicated+1;return
    end
    if c.requiresActiveBuff and #(c.spellIDs or {})==0 then
        check(not found,'a buff with unresolved identity does not activate from an assumed flag')
        local function matchingAmount(value)
            for _,applied in ipairs(value.appliedEffects) do
                if applied.entryID==effect.entryID and applied.metric==effect.metric
                    and applied.mechanism==effect.mechanism then return applied.amount end
            end
        end
        ctx.effectStates={[effect.entryID]={active=true,stacks=1}}
        params=assert(LL:ProfessionProfileParameters(profile.profession,profile.expansionID,ctx,op,input))
        local one=matchingAmount(params)
        check(type(one)=='number','an explicit entry selection activates a buff without inventing a spell ID')
        if c.maxStacks then
            ctx.effectStates[effect.entryID].stacks=c.maxStacks
            local maximum=LL:ProfessionProfileParameters(profile.profession,profile.expansionID,ctx,op,input)
            near(matchingAmount(maximum),one*c.maxStacks,'buff stacks scale the matching entry only')
            ctx.effectStates[effect.entryID].stacks=c.maxStacks+99
            near(matchingAmount(LL:ProfessionProfileParameters(profile.profession,profile.expansionID,ctx,op,input)),
                one*c.maxStacks,'buff stacks respect the native cap')
        end
        ctx.effectStates[effect.entryID].active=false
        check(not matchingAmount(LL:ProfessionProfileParameters(profile.profession,profile.expansionID,ctx,op,input)),
            'an explicitly inactive entry cannot leak its buff effect')
        found=true
        unresolvedBuff=unresolvedBuff+1
    end
    check(found,'matching dispatch missing '..key..' '..nodeID..' '..effect.entryID..' '..effect.metric)
    if c.event or next(c.contextFlags or {}) or next(effect.requiredContextFlags or {}) then
        local function applied(value)
            for _,row in ipairs(value.appliedEffects) do
                if row.entryID==effect.entryID and row.metric==effect.metric and row.mechanism==effect.mechanism then return true end
            end
        end
        local missing=copy(ctx);missing.contextFlags={};missing.events={};missing.effectStates={}
        check(not applied(LL:ProfessionProfileParameters(profile.profession,profile.expansionID,missing,op,input)),
            'required target and event flags do not activate from a missing condition table')
        missing.effectStates={[effect.entryID]={active=true,stacks=1}}
        check(applied(LL:ProfessionProfileParameters(profile.profession,profile.expansionID,missing,op,input)),
            'an explicit conditional entry selection asserts its required context')
    end
    local binding=effect.outputBinding or {}
    if binding.requiresTargetOutputFilter then
        local function concrete(value,id)
            return (value.extraOutputs[id] or 0)+(value.nontradableExtraOutputs[id] or 0)
                +(value.relativeExtraOutputs[id] or 0)+(value.minimumOutputs[id] or 0)
        end
        for _,id in ipairs(binding.itemIDs) do near(concrete(params,id),0,'an unspecified creature target does not claim every species material') end
        local named=false
        for _,out in ipairs(params.namedOutputs) do if out.entryID==effect.entryID then named=true end end
        check(named,'missing creature identity retains a numeric named family opportunity')
        local filteredOption=copy(op);filteredOption.legalExtraOutputIDs={binding.itemIDs[1]}
        if binding.requiresRenownedTarget then filteredOption.renownedTarget=true end
        local filtered=LL:ProfessionProfileParameters(profile.profession,profile.expansionID,ctx,filteredOption,input)
        check(concrete(filtered,binding.itemIDs[1])>0,'a legal creature-specific material receives the selected effect')
        for index=2,#binding.itemIDs do near(concrete(filtered,binding.itemIDs[index]),0,'a feathered target does not acquire unrelated fur or canine outputs') end
        local mixedOption=copy(op);mixedOption.mixedTargetPrior=true;mixedOption.renownedTarget=true
        local mixed=LL:ProfessionProfileParameters(profile.profession,profile.expansionID,ctx,mixedOption,input)
        local total=0 for _,id in ipairs(binding.itemIDs) do total=total+concrete(mixed,id) end
        check(total>0 and mixed.confidence==0,'an explicit mixed-target pool retains confidence zero')
        if binding.requiresRenownedTarget then
            filteredOption.renownedTarget=nil
            local ordinary=LL:ProfessionProfileParameters(profile.profession,profile.expansionID,ctx,filteredOption,input)
            for _,id in ipairs(binding.itemIDs) do near(concrete(ordinary,id),0,'a non-Renowned creature cannot yield Majestic materials') end
        end
        targetFiltered=targetFiltered+1
    end
    for id,quantity in pairs(params.extraOutputs) do
        check(type(id)=='number' and type(quantity)=='number' and quantity>=0,'additional outcomes retain valid identities and units')
    end
    check(params.outputFactor>=0 and params.inputFactor>0,'matching handler retains nonnegative units and invertible input cost')
    if method=='Gather' or method=='Skin' or method=='Fish' then gatherScopes=gatherScopes+1 end
    exercised=exercised+1
end
for _,profile in pairs(metadata.profiles) do for nodeID,node in pairs(profile.nodes) do
    for _,effect in ipairs(node.pointEffects) do exerciseEffect(profile,nodeID,node,effect,1,true,true) end
    for _,effect in ipairs(node.learningEffects) do exerciseEffect(profile,nodeID,node,effect,0,true,false) end
    for _,milestone in ipairs(node.milestones) do if milestone.rank>0 then
        for _,effect in ipairs(milestone.effects) do exerciseEffect(profile,nodeID,node,effect,milestone.rank,true,false) end
    end end
end end
check(exercised>5000,'all scope-resolved handlers are evaluated rather than sampling only a profession')
check(gatherScopes>0,'actual gathering effect scopes are exercised')
check(targetFiltered>=8,'every species-specific and Majestic output binding is target-filtered at runtime')

for _,row in ipairs({{'Herbalism','Gather',236761},{'Mining','Gather',237359},
    {'Skinning','Skin',238511},{'Fishing','Fish',999998}}) do
    local target={targetID='reference-target:'..row[1],profession=row[1],expansionID=11,method=row[2],
        baseline={inputCount=1,materials={{id=row[3],expectedQuantity=3,confidence=0}},duration=4,confidence=0}}
    local original=copy(target)
    local ctx=context(row[1]);ctx.stats.perception={percent=25}
    if row[1]~='Fishing' then ctx.stats.finesse={percent=25};ctx.stats.deftness={percent=25} end
    local result=assert(LL:GatheringSimulationModel(target,ctx))
    check(result.actionable==false,'a target preview never becomes a bag conversion')
    check(result.targetID==target.targetID,'target simulation retains its non-item identity')
    check(result.rareDiscoveryFactor>1,'target Perception reports its separate discovery metric')
    near(units(result,row[3]),3*result.yieldFactor,'target quantities use their own baseline')
    check(same(target,original),'target projection retains its source baseline')
    if row[1]~='Fishing' then check(result.duration<4,'target Deftness changes time per gather') end
    local unscaledTarget=copy(result)
    ctx.benchmark={outputLevel=160,specializationBonus=25,resourcefulnessChance=50,resourcefulnessSaved=40}
    local contextBefore=copy(ctx)
    local benchmarked=assert(LL:GatheringSimulationModel(target,ctx))
    check(benchmarked.syntheticBenchmark and benchmarked.actionable==false,
        'a gathering benchmark remains a non-actionable target preview')
    near(units(benchmarked,row[3]),units(result,row[3])*2,'target benchmark doubles final gathered units exactly once')
    near(benchmarked.yieldFactor,result.yieldFactor*2,'target benchmark also doubles the displayed gathering yield factor')
    near(benchmarked.expectedInputCount,result.expectedInputCount,'gathering does not acquire crafting Resourcefulness consumption')
    check(benchmarked.confidence==0 and benchmarked.materials[1].confidence==0,'gathering benchmark retains confidence zero')
    check(LL:ApplySyntheticBenchmark(target,{name=row[2]},benchmarked,ctx)==benchmarked,
        'target benchmark replay cannot double the output again')
    check(same(target,original) and same(ctx,contextBefore) and same(result,unscaledTarget),
        'target benchmark preserves source target, context and previous model')
end
local namedSource={inputCount=1,materials={},namedOutputs={
    {name='Unresolved byproduct identity',expectedQuantity=.25,confidence=0},
    {name='Separate discovery effect',discoveryFactor=1.1,confidence=0}},confidence=0}
local namedBefore=copy(namedSource)
local namedContext=context('Alchemy');namedContext.benchmark={outputLevel=160,specializationBonus=25}
local namedBenchmark=LL:ApplySyntheticBenchmark(facts('Alchemy'),option('Craft',1230867),namedSource,namedContext)
near(namedBenchmark.namedOutputs[1].expectedQuantity,.5,'named expected units use the same once-only output factor')
near(namedBenchmark.namedOutputs[2].discoveryFactor,1.1,'output benchmark does not rewrite a separate discovery factor')
for _,out in ipairs(namedBenchmark.namedOutputs) do
    check(out.chance==nil and out.samples==nil and out.histogram==nil,'scaling a named expectation creates no probability or observations')
end
check(same(namedSource,namedBefore),'named benchmark preserves its source information')
check(LL:ApplySyntheticBenchmark(facts('Alchemy'),option('Craft',1230867),namedBenchmark,namedContext)==namedBenchmark,
    'named expected units are not scaled again on replay')
print('PROFESSION CALCULATIONS: '..checks..' checks passed; '..exercised..' scoped handlers, '
    ..unknownScope..' unresolved scopes, '..unresolvedBuff..' unresolved buff identities, '..dedicated..' dedicated routes')
