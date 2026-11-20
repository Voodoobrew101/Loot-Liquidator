-- Fixed skill isolates the essence unlock/increase from Crystal quality changes.
local checks=0
local function check(value,label) assert(value,label);checks=checks+1 end
local function near(actual,expected,label)
    check(type(actual)=='number' and math.abs(actual-expected)<1e-8,
        label..': '..tostring(actual)..' ~= '..tostring(expected))
end
GetBuildInfo=function() return '12.1.5','70961' end
local LL={}
for _,file in ipairs({'ItemDBRuntime.lua','ProfessionModels.lua'}) do
    assert(loadfile('LootLiquidator/'..file))('LL',LL)
end
local essenceIDs={236949,236950,236951,236952}
local function amounts(materials)
    local result={}
    for _,material in ipairs(materials or {}) do result[material.id]=material end
    return result
end
local function q(rows,id) return rows[id] and rows[id].expectedQuantity or 0 end
local count=0
for _,baseline in ipairs(LL.ItemDB.modeledDisenchantBaselines or {}) do
    if baseline.rule.childNodeID==107646 then
        count=count+1
        check(#(baseline.rule.additionalOutputs or {})==4,'Crystal rule contains the reviewed essence pool')
        local prior=amounts(baseline.materials)
        local primary=q(prior,243605)+q(prior,243606)
        for _,rank in ipairs({0,19,20,29,30}) do
            local progress=rank>=30 and 1 or rank>=20 and .5 or 0
            local profile={effectiveSkill=140,childPoints=rank}
            local projected=assert(LL:DisenchantCurveQuantities(baseline,profile))
            local rows=amounts(projected)
            local extra=0
            for _,id in ipairs(essenceIDs) do
                near(q(rows,id),.07225*progress,'per-essence quantity at '..rank)
                extra=extra+q(rows,id)
                if rows[id] then
                    near(rows[id].confidence,5,'essence uncertainty cap')
                    check(rows[id].chance==nil and rows[id].samples==nil and rows[id].quantityCounts==nil,
                        'an expected bonus does not invent probability or observations')
                end
            end
            near(extra,.289*progress,'pooled essence quantity at '..rank)
            near(q(rows,243605)+q(rows,243606),primary,'bonus unlock does not consume Crystals')
            local normalized=assert(LL:NormalizeDisenchantQuantities(baseline,projected,profile))
            local original=amounts(normalized)
            for _,id in ipairs(essenceIDs) do near(q(original,id),0,'inverse removes its own additive bonus') end
            near(q(original,243605),q(prior,243605),'inverse restores rank1 primary mean')
            near(q(original,243606),q(prior,243606),'inverse restores rank2 primary mean')
            if progress>0 then
                local inconsistent={}
                for _,material in ipairs(projected) do
                    inconsistent[#inconsistent+1]={id=material.id,
                        expectedQuantity=material.id==236949 and 0 or material.expectedQuantity}
                end
                check(LL:NormalizeDisenchantQuantities(baseline,inconsistent,profile)==nil,
                    'an observed mean below the additive contribution cannot create a negative baseline')
            end
        end
    end
end
check(count==2,'compiled armor and weapon Crystal baselines are both tested')
print('CRYSTAL COLLECTOR EXTRAS: '..checks..' checks passed')
