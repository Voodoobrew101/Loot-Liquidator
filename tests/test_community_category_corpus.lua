-- Replay every compiled community category at its recorded profile, including
-- profession equipment, then reject a different build/profile/gear class.
local function copy(v)
 if type(v)~='table' then return v end
 local result={} for k,x in pairs(v) do result[k]=copy(x) end return result
end
local rows=assert(loadfile('database/community-capture-baselines.lua'))().processing
local build,version,ctx
GetBuildInfo=function() return version,build end
GetTime=function() return 100 end
CreateFrame=function() return {RegisterEvent=function()end,SetScript=function()end} end
local checked,operations=0,{}
for _,row in ipairs(rows) do
 if row.communityCategoryCapture then
  build,version=tostring(row.patchBuild),row.clientVersion
  ctx=copy(row.communityMeasuredProfile)
  ctx.character='Independent reader - Realm';ctx.profileKind='live';ctx.simulated=false
  local ll={db={source_itemdb_enabled=true,source_personal_enabled=false,
   source_legacy_enabled=false,source_reference_enabled=false,source_imported_enabled=false},
   ItemDB={schemaVersion=1,processing={row},mechanicRules={}}}
  for _,file in ipairs({'ProfessionModels.lua','Database.lua','Professions.lua','ConversionEngine.lua'}) do
   assert(loadfile('LootLiquidator/'..file))('LL',ll)
  end
  ll.CharacterKey=function() return ctx.character end
  ll.ProcessingPlayerConditions=function() return ctx end
  assert(ll:InitializeItemDB(),ll.itemDBError)
  local option={name=row.method,profession=ctx.profession,recipeID=row.recipeID,inputCount=1}
  local facts={id=999999,classID=row.inputClassID,quality=row.inputRarity,
   expansionID=row.expansionID,itemLevel=168,count=1}
  local model=assert(ll:ResolveEvidenceModel(facts,option,nil,1),row.recordID)
  assert(model.communityMeasuredReference,'recorded profile uses measured community evidence')
  for _,material in ipairs(row.materials) do
   local found
   for _,out in ipairs(model.materials) do if out.id==material.id then found=out end end
   assert(found and math.abs(found.expectedQuantity-material.expectedQuantity.value)<1e-7,
    'native selection preserves observed quantity: '..row.recordID)
  end
  for _,id in ipairs(row.sourceRecordIDs) do assert(not operations[id]);operations[id]=true end
  build='different-build';assert(not ll:ResolveEvidenceModel(facts,option,nil,1))
  build=tostring(row.patchBuild)
  ctx.effectiveSkill=ctx.effectiveSkill+1;assert(not ll:ResolveEvidenceModel(facts,option,nil,1))
  ctx.effectiveSkill=row.communityMeasuredProfile.effectiveSkill
  facts.classID=row.inputClassID==4 and 2 or 4
  assert(not ll:ResolveEvidenceModel(facts,option,nil,1))
  checked=checked+1
 end
end
assert(checked>0,'reviewed community category corpus must be present')
local count=0 for _ in pairs(operations) do count=count+1 end
print('PASS: '..checked..' actual community category/profile records, '..count..' distinct operations; mismatch rejection')
