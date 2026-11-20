-- Sourced output effects remain editable even when a quantity curve is not
-- known. Capability distinguishes descriptive context from executed arithmetic.
local count=0
local function check(value,label) assert(value,label);count=count+1 end
local function copy(value)
    if type(value)~='table' then return value end
    local result={} for k,v in pairs(value) do result[k]=copy(v) end return result
end
GetBuildInfo=function() return '12.1.5','70783' end
CreateFrame=function() return {RegisterEvent=function()end,SetScript=function()end} end
local LL={}
for _,file in ipairs({'ItemDBRuntime.lua','ProfessionCatalog.lua','Professions.lua','ProfessionModels.lua'}) do
    assert(loadfile('LootLiquidator/'..file))('LL',LL)
end
local function support(profession,expansion,nodes)
    nodes=nodes or (LL.ProfessionCatalog[profession..':'..expansion] or {}).nodes
    return LL:GetProfessionSimulationControlSupport(profession,expansion,nodes)
end
local native=LL.ItemDB
local enchant=support('Enchanting',11)
check(enchant.skill,'enchanting skill stays editable as known profession context')
check(enchant.nodes['107649'] and enchant.nodes['107647'],'both known full-reference allocations remain editable')
check(enchant.nodes['107648'] and enchant.nodes['107646'],'Dust Deliverer and Crystal Collector remain editable')
check(enchant.unquantifiedNodes['107648'] and enchant.unquantifiedNodes['107646'],
    'known dust/crystal effects explicitly lack numerical yield curves')
check(not next(enchant.stats) and not next(enchant.buffs),'captured stats/buffs alone do not expose controls')
local jc=support('Jewelcrafting',11)
check(jc.skill and jc.nodes['106982'] and jc.nodes['106983'],'Midnight prospecting skill reaches a quality calculation')
local mill=support('Inscription',11)
check(mill.skill and mill.nodes['109653'] and mill.nodes['109655'] and mill.nodes['109660'],'all sourced milling skill bonuses connect to quality')
local tww=support('Jewelcrafting',10)
check(not tww.skill,'TWW skill has no supported outcome model')
for _,id in ipairs({'98659','98660','98661','98662'}) do check(tww.nodes[id],'TWW shared-reservoir replacement '..id) end
local twwEnchant=support('Enchanting',10)
check(twwEnchant.skill and twwEnchant.nodes['99890'] and twwEnchant.unquantifiedNodes['99890'],
    'TWW sourced skill points remain editable with their unquantified output state')
local dragonflight=support('Inscription',9)
check(dragonflight.skill and dragonflight.nodes['34832'] and dragonflight.unquantifiedNodes['34832'],
    'Dragonflight sourced skill context does not require an invented output curve')
check(not support('Blacksmithing',11).skill and not next(support('Blacksmithing',11).nodes),'unsupported professions show no inert inputs')
GetBuildInfo=function() return 'future','999999' end
check(not next(support('Jewelcrafting',11).nodes) and not next(support('Enchanting',11).nodes),'wrong-build specialization research is not executable')
GetBuildInfo=function() return '12.1.5','70783' end
local function field(value) return {value=value,status='measured',confidence=90} end
local baseline={recordID='synthetic-baseline',sourceKey='itemdb',method='Mill',expansionID=11,inputItemID=1,
    inputCount=5,recipeID=100,inputQualityRank=1,patchBuild='70783',referenceContextID='synthetic-context',
    baselineProfile={effectiveSkill=0,specialization='none'},materials={{id=10,
        expectedQuantity=field(2),dropChance=field(.5),minQuantity=field(1),maxQuantity=field(3)}}}
local common={ruleID='synthetic',applyPolicy='EXECUTE',evidenceStatus='SOURCED_PROVISIONAL',
    confidence0to100=70,sourceClaimIDs={'synthetic-test-only'},profession='Inscription',method='Mill',expansionID=11,build='70783'}
local multiplier=copy(common);multiplier.kind='quantity-multiplier';multiplier.nodeID=12;multiplier.maxRank=30;multiplier.perPoint=.01
LL.ItemDB={processing={copy(baseline)},specializationRules={multiplier},professionRules={},mechanicRules={},skillQualityRules={}}
local nodes={{id=12,maxRank=30,name='Outcome',requirements={{kind='node',nodeID=11,rank=5},{kind='skill',skill=25}}},
    {id=11,maxRank=20,name='Required',requirements={{kind='node',nodeID=9,rank=1}}},
    {id=9,maxRank=10,name='Ancestor'}, {id=8,maxRank=20,name='Unrelated',parentID=9}}
local current=support('Inscription',11,nodes)
check(current.nodes['12'] and current.nodes['11'] and current.nodes['9'],'known prerequisite closure exposes necessary inputs')
check(current.dependencyNodes['11'] and current.dependencyNodes['9'] and not current.dependencyNodes['12'],'dependency controls are distinguished')
check(current.skill and current.skillDependency,'known skill prerequisite permits an executable outcome')
check(not current.nodes['8'],'catalog parent links alone do not expose inert sliders')
LL.ItemDB.specializationRules={}
check(not next(support('Inscription',11,nodes).nodes),'removing researched support hides the control again')
LL.ItemDB.specializationRules={copy(multiplier)}
check(support('Inscription',11,nodes).nodes['12'],'new executable research restores the same catalog node')
LL.ItemDB.specializationRules[1].applyPolicy='DISABLED'
check(not support('Inscription',11,nodes).nodes['12'],'disabled effect stays hidden')
LL.ItemDB.specializationRules[1]=copy(multiplier);LL.ItemDB.specializationRules[1].sourceClaimIDs={}
check(not support('Inscription',11,nodes).nodes['12'],'unsourced effect stays hidden')
LL.ItemDB.specializationRules[1]=copy(multiplier);LL.ItemDB.processing={}
check(not support('Inscription',11,nodes).nodes['12'],'a formula without a compatible baseline cannot change yields')
LL.ItemDB.processing={copy(baseline)};LL.ItemDB.specializationRules[1]=copy(multiplier)
LL.ItemDB.specializationRules[1].milestones={{rank=5,multiplier=2},{rank=10,multiplier=nil}}
check(not support('Inscription',11,nodes).nodes['12'],'a malformed milestone cannot produce a working multiplier')
LL.ItemDB.specializationRules[1]=copy(multiplier);LL.ItemDB.specializationRules[1].inputItemIDs={2}
check(not support('Inscription',11,nodes).nodes['12'],'wrong input scope has no compatible outcome')
-- A varying skill curve is usable by the skill control. Point bonuses also
-- require the numeric model to accept their changed specialization signature.
local numeric=copy(common);numeric.inputItemID=1;numeric.recipeID=100;numeric.outputItemID=10
numeric.referenceProfile={effectiveSkill=0,specialization='none'}
numeric.skillFactors={{skill=0,factor=1},{skill=100,factor=2}}
local point=copy(common);point.ruleID='synthetic-point';point.kind='skill-per-point';point.nodeID=12;point.maxRank=30;point.perPoint=1
LL.ItemDB.specializationRules={point};LL.ItemDB.professionRules={numeric}
check(support('Inscription',11,nodes).skill,'a valid skill curve supports base skill')
check(support('Inscription',11,nodes).nodes['12'] and support('Inscription',11,nodes).unquantifiedNodes['12'],
    'a curve rejecting changed specialization retains separately sourced skill context')
numeric.specializationFactors={none=1,['12=1']=1}
check(support('Inscription',11,nodes).nodes['12'],'an accepting varying skill model connects the sourced point bonus')
numeric.skillFactors={{skill=0,factor=1},{skill=100,factor=1}}
check(not support('Inscription',11,{}).skill,'a constant curve does not create a useful skill control')
-- A future existing mechanic formula can genuinely consume a typed stat or
-- buff. Merely adding similarly named fields to unrelated rules cannot.
local mechanic=copy(common);mechanic.ruleID='synthetic-mechanic';mechanic.inputItemID=1;mechanic.recipeID=100
mechanic.inputQualityRank=1;mechanic.outputItemID=10;mechanic.applies='VERIFIED_APPLIES'
mechanic.sourceBuild='70783';mechanic.targetBuild='70783';mechanic.sourceReferenceContextID='synthetic-context'
mechanic.formulaID='MULTIPLY';mechanic.effectTarget='OUTPUT_UNCONDITIONAL_EXPECTATION';mechanic.parameters={multiplier=1.2}
mechanic.targetConditions={stats={resourcefulness={percent=20}},buffs={['123']=true}}
LL.ItemDB.professionRules={};LL.ItemDB.specializationRules={};LL.ItemDB.mechanicRules={mechanic}
local future=support('Inscription',11,{})
check(future.stats.resourcefulness and future.stats.resourcefulness.percent and not future.stats.resourcefulness.rating,'a consumed percentage restores only that stat input')
check(future.buffs['123'],'an outcome formula restores its consumed buff selector')
mechanic.parameters.multiplier=1
check(not next(support('Inscription',11,{}).stats),'an identity multiplier is not an outcome change')
mechanic.parameters.multiplier=1.2
mechanic.targetConditions.equipment={}
check(not next(support('Inscription',11,{}).stats),'a manual profile cannot satisfy equipment-bound formulas')
mechanic.targetConditions.equipment=nil;mechanic.targetConditions.craftingQuality=2
check(not next(support('Inscription',11,{}).stats),'uneditable live quality metadata cannot reveal simulated stat controls')
mechanic.targetConditions={operationStats={{bonusStatName='Resourcefulness',ratingPct=20}}}
check(not next(support('Inscription',11,{}).stats),'raw API stat snapshots are not equal to simulated typed operation stats')
mechanic.targetConditions={operationStats={{bonusStatName='Resourcefulness',ratingPct=20,simulated=true,statKey='resourcefulness'}}}
check(support('Inscription',11,{}).stats.resourcefulness.percent,'an exactly reachable typed operation-stat condition reveals its input')
mechanic.inputQualityRank=nil
check(not next(support('Inscription',11,{}).stats),'non-DE mechanics require the runtime quality identity')
mechanic.inputQualityRank=1;mechanic.sourceReferenceContextID=nil
check(not next(support('Inscription',11,{}).stats),'a missing source context cannot execute a mechanic')
mechanic.sourceReferenceContextID='synthetic-context';LL.ItemDB.processing[1].sourceKey='reference'
check(not next(support('Inscription',11,{}).stats),'reference baselines never enter the existing itemdb mechanics adapter')
LL.ItemDB.processing[1].sourceKey='itemdb'
mechanic.parameters.multiplier=.8;mechanic.effectTarget='OPERATION_DURATION'
check(not next(support('Inscription',11,{}).stats),'duration-only metadata does not change current yield/value calculations')
mechanic.effectTarget='EXPECTED_INPUT_CONSUMPTION'
check(support('Inscription',11,{}).stats.resourcefulness.percent,'milling input savings affect valuation')
mechanic.method='Disenchant';mechanic.profession='Enchanting';LL.ItemDB.processing[1].method='Disenchant'
mechanic.inputRarity=3;mechanic.inputClassID=4
check(not next(support('Enchanting',11,{}).stats),'disenchanting cannot gain a resource-saving slider from input-consumption metadata')
LL.ItemDB=copy(native)
for _,record in ipairs(LL.ItemDB.processing) do
    if record.isDisenchantCategory and record.categoryReferenceOnly then
        record.inputRarity=nil;record.inputClassID=nil;record.expansionID=nil
        record.gearKey='gear:10:4:weapon'
    end
end
local function referenceSupported()
    local capability=support('Enchanting',11)
    for _,effects in pairs(capability.nodeEffects) do
        for _,id in ipairs(effects) do if id=='specialization:11:Disenchant:max-shard-reference' then return true end end
    end
    return false
end
check(not referenceSupported(),'a gear-key-only baseline from another scope cannot enable the reference')
for _,key in ipairs({'gear:11:4:armor','gear:11:3:weapon'}) do
    LL.ItemDB=copy(native)
    for _,record in ipairs(LL.ItemDB.processing) do
        if record.isDisenchantCategory and record.categoryReferenceOnly then
            record.inputRarity=nil;record.inputClassID=nil;record.expansionID=nil;record.gearKey=key
        end
    end
    check(not referenceSupported(),'a gear-key-only baseline must match exact rarity/type: '..key)
end
LL.ItemDB=copy(native)
for _,rule in ipairs(LL.ItemDB.specializationRules) do
    if rule.kind=='reference-context' then rule.requiredNodeCaps={['107649']=29,['107647']=30} end
end
check(not referenceSupported(),'an unreachable required-node cap cannot advertise reference arithmetic')
check(support('Enchanting',11).nodes['107649'],'known Delegate skill remains editable independently of the held reference')
LL.ItemDB=native
check(not next(support('Enchanting',11,{{name='bad catalog'},{id=107647,maxRank='30'}}).nodes),'malformed catalog entries cannot create a visible control')
LL.ItemDB=copy(native);LL.ItemDB.skillQualityRules={}
local contextOnly=support('Jewelcrafting',11)
check(contextOnly.nodes['106982'] and contextOnly.skill and contextOnly.unquantifiedNodes['106982'],
    'removing a quantity/quality path retains known skill context and marks it unquantified')
LL.ItemDB=copy(native);LL.ItemDB.skillQualityRules[3]=copy(LL.ItemDB.skillQualityRules[1])
local duplicate=LL.ItemDB.skillQualityRules[3]
local ambiguous=support(duplicate.method=='Mill' and 'Inscription' or 'Jewelcrafting',11)
check(ambiguous.skill and next(ambiguous.unquantifiedNodes),
    'ambiguous quality models retain sourced skill context without advertising quantified output')
-- Described output effects require their own source, patch, catalog and baseline
-- scope. A description does not create a skill bonus or multiplier rule.
local crystal
for _,effect in ipairs(native.specializationDescriptions) do if effect.nodeID==107646 then crystal=copy(effect) end end
check(crystal~=nil,'the shipped Crystal Collector description is available')
local descriptionBaseline={method='Disenchant',expansionID=11,inputRarity=4,inputClassID=4,
    materials={{id=243605,expectedQuantity=field(1)}}}
LL.ItemDB={processing={descriptionBaseline},specializationDescriptions={crystal}}
local described=support('Enchanting',11)
check(described.nodes['107646'] and described.unquantifiedNodes['107646'] and not described.skill,
    'Crystal description supplies its point control but invents no skill bonus')
check(described.nodeDescriptions['107646'][1]==crystal.description,'the source description reaches editor capability')
for key,value in pairs({clientVersion='12.1.6',expansionID=10,profession='Inscription',method='Mill',maxRank=29,inputRarity=2}) do
    LL.ItemDB.specializationDescriptions={copy(crystal)}
    LL.ItemDB.specializationDescriptions[1][key]=value
    check(not support('Enchanting',11).nodes['107646'],'description scope mismatch remains excluded: '..key)
end
LL.ItemDB.specializationDescriptions={copy(crystal)}
LL.ItemDB.specializationDescriptions[1].sourceClaimIDs={}
check(not support('Enchanting',11).nodes['107646'],'an unsourced description cannot expose an output control')
LL.ItemDB=native
print('PASS: '..count..' research-driven control capability, restoration, prerequisite, model and scope assertions')
