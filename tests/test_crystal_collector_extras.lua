-- Unverified cross-rarity essence guesses must not reach drops or prices.
local checks=0
local function check(value,label)assert(value,label);checks=checks+1 end
local function near(actual,expected,label)
    check(type(actual)=='number' and math.abs(actual-expected)<1e-8,
        label..': '..tostring(actual)..' ~= '..tostring(expected))
end
GetBuildInfo=function()return '12.1.5','70961','',120105 end
CreateFrame=function()return {RegisterEvent=function()end,SetScript=function()end}end
local LL={db={}}
for _,file in ipairs({'ItemDBRuntime.lua','Professions.lua','ProfessionModels.lua','Database.lua','ConversionEngine.lua'})do
    assert(loadfile('LootLiquidator/'..file))('LL',LL)
end
local essenceIDs={236949,236950,236951,236952}
local function amounts(materials)
    local result={}
    for _,material in ipairs(materials or {})do result[material.id]=material end
    return result
end
local function q(rows,id)return rows[id] and rows[id].expectedQuantity or 0 end
LL.GetOutputPrice=function(_,id)
    if id==243605 then return 100 elseif id==243606 then return 200 end
    return 1000000 -- A leaked speculative Mote would visibly contaminate value.
end
local count=0
for _,baseline in ipairs(LL.ItemDB.modeledDisenchantBaselines or {})do
    if baseline.rule.childNodeID==107646 then
        count=count+1
        check(baseline.rule.additionalOutputs==nil,'Unverified essence output pool must not be compiled')
        local prior=amounts(baseline.materials)
        local primary=q(prior,243605)+q(prior,243606)
        local profiles={}
        local facts={id=999000+baseline.inputClassID,classID=baseline.inputClassID,quality=4,expansionID=11,count=1}
        local option={name='Disenchant',recipeID=13262,inputCount=1}
        for _,rank in ipairs({0,19,20,29,30})do
            local context={simulated=true,profileKind='manual-simulation',profession='Enchanting',
                skill=140,preSpecializationSkill=140,
                specializationPoints={['107649']=0,['107646']=rank},buffs={}}
            local profile=assert(LL:DisenchantForwardProfile(facts,option,context,baseline.rule))
            profiles[rank]=profile
            local projected=assert(LL:DisenchantCurveQuantities(baseline,profile))
            local rows=amounts(projected)
            for _,id in ipairs(essenceIDs)do
                check(rows[id]==nil,'No guessed Mote distribution or price at Crystal rank '..rank)
                check(prior[id]==nil,'No hidden zero-profile Mote prior')
            end
            near(q(rows,243605)+q(rows,243606),primary,'Primary crystal units are conserved')
            local model={inputCount=1,confidence=baseline.confidence,materials=projected}
            near(LL:ValueProcessingModel(model,0,true,facts),q(rows,243605)*100+q(rows,243606)*200,
                'Only primary crystal outputs enter the quote')
            local original=amounts(assert(LL:NormalizeDisenchantQuantities(baseline,projected,profile)))
            near(q(original,243605),q(prior,243605),'Inverse preserves source rank1 mean')
            near(q(original,243606),q(prior,243606),'Inverse preserves source rank2 mean')
        end
        near(profiles[30].effectiveSkill-profiles[29].effectiveSkill,21,
            'Real rank30 +20 skill milestone and one invested point still apply')
        local before=amounts(assert(LL:DisenchantCurveQuantities(baseline,profiles[29])))
        local after=amounts(assert(LL:DisenchantCurveQuantities(baseline,profiles[30])))
        check(q(after,243606)>q(before,243606),'Native skill milestone still improves primary quality')
    end
end
check(count==2,'Both armor and weapon Crystal categories are tested')
print('CRYSTAL COLLECTOR ADMISSION: '..checks..' checks passed; no unverified essence prices')
