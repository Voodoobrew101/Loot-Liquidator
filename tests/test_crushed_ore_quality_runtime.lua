-- Existing source .104 is a mean, never a newly asserted probability/range.
local LL={}
assert(loadfile('LootLiquidator/ItemDBRuntime.lua'))('LL',LL)
assert(loadfile('LootLiquidator/ProfessionCalculations.lua'))('LL',LL)
local checks=0
local function check(value,why)checks=checks+1;assert(value,why)end
local function near(a,b,why)check(type(a)=='number'and math.abs(a-b)<1e-10,why)end
local data=LL.ItemDB.professionProfiles
local effect
for _,milestone in ipairs(data.profiles['Jewelcrafting:10'].nodes[98663].milestones)do
 for _,candidate in ipairs(milestone.effects or{})do if candidate.entryID==121951 then effect=candidate end end
end
check(effect and effect.numericUnsupported==true,'native quality identity grants no fabricated numerical bonus')
local option={name='Prospect',profession='Jewelcrafting',recipeID=434018,inputCount=5}
local facts={id=210934,expansionID=10,reagentQuality=2}
local source={inputCount=5,materials={{id=213220,expectedQuantity=.104,confidence=0},
 {id=212498,expectedQuantity=1.75,confidence=0},
 {id=242608,expectedQuantity=0,chance=0,structuralZero=true,probabilityBasis='specialization-eligibility-zero'}}}
for _,skill in ipairs({0,100,545,2000})do for _,points in ipairs({0,19,20,40})do
 local params=LL:ProfessionProfileParameters('Jewelcrafting',10,
  {skill=skill,preSpecializationSkill=skill,specializationPoints={['98663']=points},stats={}},option,facts)
 local normalized=assert(LL:NormalizeProfessionBaseline(source,params,option))
 local projected=assert(LL:ProjectProfessionBaseline(normalized,params,option))
 local final=LL:ApplyGeneralProfessionQuality(facts,option,projected,{})
 check(final==projected,'Prospect never acquires a generic crafting-quality allocation')
 check(#final.materials==3,'skill/spec projection cannot recreate invalid Crushed siblings')
 for _,m in ipairs(final.materials)do
  check(m.id~=213219 and m.id~=213221,'no wrong-grade placeholder is recreated')
  if m.id==213220 then
   near(m.expectedQuantity,.104,'reported rank2 mean remains unchanged')
   check(m.chance==nil and m.minQuantity==nil and m.maxQuantity==nil,'missing probability/range remains absent')
  elseif m.id==212498 then near(m.expectedQuantity,1.75,'another actual gem remains unchanged')
  elseif m.id==242608 then
   check(m.expectedQuantity==0 and m.chance==0 and m.structuralZero==true
    and m.probabilityBasis=='specialization-eligibility-zero','real lock-zero evidence survives')
  end
 end
end end
local unknown=LL:ProfessionProfileParameters('Jewelcrafting',10,
 {skill=2000,specializationPoints={['98663']=40},stats={}},option,{expansionID=10})
check(unknown.inputQuality==nil,'unknown input rank remains unresolved')
check(unknown.extraOutputs[213219]==nil and unknown.extraOutputs[213220]==nil and unknown.extraOutputs[213221]==nil,
 'qualitative native rule never guesses a rank or extra quantity for unknown input')
near(source.materials[1].expectedQuantity,.104,'immutable source mean')
check(#source.materials==3 and source.materials[1].chance==nil,'immutable source rows and absent distribution')
print('PASS: '..checks..' native Crushed input-quality/source-preservation checks')
