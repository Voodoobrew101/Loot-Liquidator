local checks=0
local function check(value,label) assert(value,label);checks=checks+1 end
local function near(value,wanted,label)
    check(type(value)=='number' and math.abs(value-wanted)<1e-8,
        label..': '..tostring(value)..' ~= '..tostring(wanted))
end
local build='70961'
GetBuildInfo=function() return '12.1.5',build end
CreateFrame=function() return {RegisterEvent=function()end,SetScript=function()end} end
local LL={}
for _,file in ipairs({'Professions.lua','ProfessionModels.lua'}) do
    assert(loadfile('LootLiquidator/'..file))('LL',LL)
end
local data=assert(loadfile('database/specialization-effects.lua'))()
LL.ItemDB={specializationRules=data.specializationRules}
local facts={id=210931,expansionID=10,reagentQuality=2,classID=7,count=5}
local option={name='Prospect',recipeID=434018,inputCount=5}
local colors={{98659,212508},{98660,212495},{98661,212511},{98662,212505}}
local function quantity(model,id)
    for _,m in ipairs(model.materials) do if m.id==id then return m.expectedQuantity end end
    return 0
end
local function evaluate(points)
    local original={inputCount=5,confidence=90,materials={{id=212498,expectedQuantity=4,confidence=90}}}
    local ctx={profession='Jewelcrafting',simulated=true,profileKind='manual-simulation',
        specializationPoints=points,specialization='none'}
    local result=LL:ApplySpecializationEffects(facts,option,original,ctx)
    near(original.materials[1].expectedQuantity,4,'source Amber expectation is immutable')
    local total=0 for _,m in ipairs(result.materials) do total=total+m.expectedQuantity end
    near(total,4,'all color replacements conserve original gem units')
    return result
end
for _,color in ipairs(colors) do
    for _,case in ipairs({{4,.04},{5,.07},{14,.16},{15,.20},{20,.25}}) do
        local result=evaluate({[tostring(color[1])]=case[1]})
        near(quantity(result,color[2]),4*case[2],'point and milestone fraction moves to the selected color')
        near(quantity(result,212498),4*(1-case[2]),'the same fraction leaves Amber')
    end
end
local all={}
for _,color in ipairs(colors) do all[tostring(color[1])]=20 end
local full=evaluate(all)
near(quantity(full,212498),0,'four complete color paths exhaust exactly one Amber reservoir')
for _,color in ipairs(colors) do near(quantity(full,color[2]),1,'each full color receives one quarter of the original units') end
build='70783'
local prior=evaluate(all)
near(quantity(prior,212498),.8,'newly reviewed milestones are not backdated to an older source build')
for _,color in ipairs(colors) do near(quantity(prior,color[2]),.8,'older build retains only the reviewed per-point fraction') end
print('GEM REPLACEMENT MILESTONES: '..checks..' checks passed')
