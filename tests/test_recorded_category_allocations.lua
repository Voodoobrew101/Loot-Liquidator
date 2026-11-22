-- Many real-shaped cohorts must not repeatedly serialize each saved cast's
-- identical context. Public exports and independently owned baselines stay intact.
local checks=0
local function check(v,why)assert(v,why);checks=checks+1 end
local function eq(a,b,why)check(a==b,(why or '')..': '..tostring(a)..' ~= '..tostring(b))end
GetBuildInfo=function()return'test','70961','',120105 end
GetTime=function()return 100 end;time=function()return 1000 end
CreateFrame=function()return{RegisterEvent=function()end,SetScript=function()end}end
local LL={db={recordDisenchants=true},CharacterKey=function()return'Tester-Realm'end}
assert(loadfile('LootLiquidator/CraftRecording.lua'))('LootLiquidator',LL)
local function context()
 local c={character='Tester-Realm',recipeID=13262,method='Disenchant',profession='Enchanting',
  profileKind='measured',simulated=false,baseSkill=75,bonusSkill=5,effectiveSkill=80,
  specialization='delegate=10',skillLineID=2909,observed=1000,
  equipment={},buffs={},buffStacks={},specializationPoints={},fieldStatus={equipment='measured'}}
 for i=19,28 do c.equipment[tostring(i)]='|Hitem:'..(240000+i)..'::::::::90:104::13:3:12253:12251:12502:3:28:3615:38:8:40:2791::::Player-1175-00000000:|h[Profession equipment]|h' end
 for i=1,64 do c.specializationPoints[tostring(107000+i)]=i==1 and 10 or 0 end
 for i=1,20 do c.buffs[tostring(400000+i)]=true;c.buffStacks[tostring(400000+i)]=i end
 return c
end
LL.CaptureCraftContext=function()return context()end
local cohorts,casts=36,24
for cohort=1,cohorts do
 LL:StartCraftStudy('Measured cohort '..cohort)
 local item={itemID=260000+cohort,quantity=1,rarity=3,classID=4,expansionID=11,
  itemLevel=200,hyperlink='item:'..(260000+cohort)..':exact-variant'}
 for cast=1,casts do
  local ok,why=LL:RecordCraftObservation({operationID='capture-'..cohort..'-'..cast,recipeID=13262,
   method='Disenchant',successful=true,character='Tester-Realm',build='70961',context=context(),
   inputs={item},outputs={{itemID=cast%2==1 and 500 or 501,quantity=cast%2==1 and 2 or 1}},outputCoverage='complete'})
  check(ok,why)
 end
end
local d=LL.db.craftResearch
local first=d.records[1]
local public=assert(LL:CraftBaseline(first.studyID,first.contextID,13262))
check(public.observationContext~=d.contexts[first.contextID],'public baseline context is an independent copy')
public.observationContext.equipment['19']='changed only in returned baseline'
check(d.contexts[first.contextID].equipment['19']~='changed only in returned baseline','public baseline cannot mutate stored equipment')
local export=LL:ExportCraftResearch('all')
local facts={id=999999,quality=3,classID=4,expansionID=11,itemLevel=200,link='item:999999'}
local function result()
 local m=assert(LL:GetRecordedDisenchantCategoryEstimate(facts,13262,context()))
 eq(m.operations,cohorts*casts,'every complete cast contributes exactly once')
 eq(#m.sourceRecordIDs,cohorts*casts,'raw operation identities remain complete')
 eq(#m.memberInputItemIDs,cohorts,'all input identities remain represented')
 eq(m.materials[1].id,500);eq(m.materials[1].expectedQuantity,1);eq(m.materials[1].chance,.5)
 eq(m.materials[1].minQuantity,2);eq(m.materials[1].maxQuantity,2)
 eq(m.materials[1].quantityCounts['0'],cohorts*casts/2)
 eq(m.materials[2].id,501);eq(m.materials[2].expectedQuantity,.5);eq(m.materials[2].chance,.5)
 return m
end
result();result()
collectgarbage('collect');local start=collectgarbage('count');collectgarbage('stop')
for _=1,20 do result()end
local allocation=collectgarbage('count')-start
collectgarbage('restart');collectgarbage('collect')
local retained=collectgarbage('count')-start
check(allocation<26*1024,'20 repeated category lookups should allocate under26MiB; actualKiB='..allocation)
check(retained<32,'request-local work is collectable; retainedKiB='..retained)
eq(LL:ExportCraftResearch('all'),export,'queries leave the full captured export byte-for-byte unchanged')
eq(#d.records,cohorts*casts,'queries never add or discard capture records')
print(('RECORDED CATEGORY ALLOCATION: %d checks;20 lookups %.1fKiB temporary,%.1fKiB retained'):format(checks,allocation,retained))
