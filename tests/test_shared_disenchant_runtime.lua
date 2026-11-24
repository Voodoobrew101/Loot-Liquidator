local ll={db={source_personal_enabled=false,source_imported_enabled=false,
 source_itemdb_enabled=true,source_legacy_enabled=true,source_reference_enabled=true}}
GetTime=function()return 100 end
GetBuildInfo=function()return '12.1.5','70961' end
CreateFrame=function()return {RegisterEvent=function()end,SetScript=function()end}end
for _,file in ipairs({'ItemDBRuntime.lua','ProfessionModels.lua','ProfessionCalculations.lua',
 'Database.lua','Professions.lua','ConversionEngine.lua','Badges.lua'})do
 assert(loadfile('LootLiquidator/'..file))('LL',ll)
end
ll.CharacterKey=function()return 'Fixture - Realm'end
ll.GetOutputPrice=function(_,id)return id==243602 and 100 or 200,'fixture'end
ll.MarkupColor=function()return ''end
ll.Money=function(_,v)return tostring(v)end
local ctx={profession='Enchanting',expansionID=11,skillLineID=2909,
 skill=64,baseSkill=64,bonusSkill=40,effectiveSkill=104,preSpecializationSkill=104,
 specialization='none',specializationKnown=true,specializationPoints={},learnedSpecializations={},
 buffsKnown=true,buffs={},buffStacks={},character='Fixture - Realm',profileKind='live'}
ll.ProcessingPlayerConditions=function()return ctx end
assert(ll:InitializeItemDB(),ll.itemDBError)
local option={name='Disenchant',profession='Enchanting',recipeID=13262,inputCount=1}
local function model(id,rarity,expansion,class)
 local f={id=id,classID=class or 4,quality=rarity or 3,expansionID=expansion or 11,
 itemLevel=168,count=1,context={isBound=true}}
 return ll:ResolveEvidenceModel(f,option,nil,1),f
end
local first
for _,id in ipairs({244752,239671,999999})do
 local m,f=model(id)
 assert(m and m.sharedCategoryReference,'shared observations apply to ANY matching catalog number')
 assert(not m.disenchantBaselineApplied,'measured observations must not be reinterpreted as zero-skill means')
 local quantities={}
 for _,out in ipairs(m.materials)do quantities[out.id]=out.expectedQuantity end
 assert(math.abs(quantities[243602]-500/544)<1e-6)
 assert(math.abs(quantities[243603]-44/544)<1e-6)
 assert(m.confidence>0,'personal source OFF retains measured built-in confidence')
 local gold=ll:ValueProcessingModel(m,0,true,f)
 assert(math.abs(gold-(quantities[243602]*100+quantities[243603]*200))<1e-6)
 if first then assert(first==m.confidence)else first=m.confidence end
end
ctx.effectiveSkill=82;ctx.bonusSkill=18;ctx.preSpecializationSkill=82
for _,args in ipairs({{999998,4,11,4},{999996,3,11,2},{999993,4,11,2}})do
 local m=model(unpack(args))
 assert(m and m.sharedCategoryReference and m.confidence>0,'other uploaded rarities/types use their own measured category')
 assert(#m.materials>0,'other uploaded category has actual outputs')
end
for _,args in ipairs({{999997,3,10,4},{999992,2,11,4},{999991,3,11,19}})do
 local m=model(unpack(args))
 assert(not (m and m.sharedCategoryReference),'wrong rarity/era/type cannot use these counts')
end
ctx.simulated=true
local simulated=model(999995)
assert(not (simulated and simulated.sharedCategoryReference),'what-if profiles retain their explicit simulation curves')
ctx.simulated=nil
ll.db.source_itemdb_enabled=false
ll._evidenceModelCache=nil
local disabled=model(244752)
assert(not (disabled and disabled.sharedCategoryReference),'source switch still respected')
print('PASS: all shared captured gear categories, arbitrary item IDs, personal OFF, quantities, gold and category boundaries')
