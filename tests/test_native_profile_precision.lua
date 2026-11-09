-- Numeric identity and genuine PR51 SavedVariables upgrade, using existing exports.
-- Source exports remain unchanged; mutated copies exercise rejection contracts.
local checks=0
local function check(v,m)assert(v,m);checks=checks+1 end
local function eq(a,b,m)check(a==b,(m or 'mismatch')..': '..tostring(a)..' ~= '..tostring(b))end
local function near(a,b,m)check(type(a)=='number' and math.abs(a-b)<1e-9,m)end
local function copy(v)if type(v)~='table' then return v end local n={} for k,x in pairs(v)do n[k]=copy(x)end return setmetatable(n,getmetatable(v))end
GetTime=function()return 0 end;time=function()return 2000000 end
GetBuildInfo=function()return '12.1.5','70783','',120105 end
CreateFrame=function()return {RegisterEvent=function()end,SetScript=function()end}end
hooksecurefunc=function()end;C_Timer={After=function()end}
local LL={db={characters={}}}
for _,name in ipairs({'ItemDBRuntime.lua','ProfessionModels.lua','Database.lua','Professions.lua','CraftRecording.lua','ImportedResults.lua','ConversionEngine.lua'})do
 assert(loadfile('LootLiquidator/'..name))('LL',LL)
end
LL.CharacterKey=function()return 'Recipient - Realm'end
LL.ItemDB={schemaVersion=1,version='import-fixture',inputs={},processing={},mechanicRules={}}
assert(LL:InitializeItemDB());LL:MigrateEvidenceSettings()
LL:SetEvidenceSource('legacy',false);LL:SetEvidenceSource('reference',false)
local root='research/integration/measured-captures/'
local function read(path)local f=assert(io.open(root..path,'rb'));local s=f:read('*a');f:close();return s end
local recycling=assert(LL.DecodeImportJSON(read('2026-11-07-recycling-80-skill-200-casts/export-page-1.json')))
local shatter=assert(LL.DecodeImportJSON(read('2026-11-07-radiant-shatter-v6-live-check/export-page-1.json')))
local arrayMeta=getmetatable(shatter.records)
local function json(v)
 if type(v)=='string'then return '"'..v:gsub('[%z\1-\31\\"]',function(c)return ({['"']='\\"',['\\']='\\\\',['\n']='\\n',['\r']='\\r',['\t']='\\t'})[c] or ('\\u%04x'):format(c:byte())end)..'"'end
 if type(v)=='number'then return string.format('%.17g',v)end
 if type(v)~='table'then return tostring(v)end
 local out={}
 if getmetatable(v)==arrayMeta then for i,x in ipairs(v)do out[i]=json(x)end return '['..table.concat(out,',')..']'end
 for k,x in pairs(v)do out[#out+1]=json(tostring(k))..':'..json(x)end return '{'..table.concat(out,',')..'}'
end
local function import(page)
 local raw=json(page)
 -- Same native codec contract as test_compact_transfer.lua. Genuine portable
 -- zlib/base64 bytes are independently checked there by Python and Lua.
 C_EncodingUtil={DecodeBase64=function(s)eq(s,'fixture');return 'compressed'end,
  DecompressString=function(s,m)eq(s,'compressed');eq(m,1);return raw end}
 return LL:ImportRecordedResults('{"schemaVersion":"loot-liquidator.cast-transfer/1","encoding":"zlib-base64","uncompressedBytes":'..#raw..',"payload":"fixture"}')
end
local liveContext
LL.FindSkillQualityTarget=function()return 'Item-current-target'end
LL.CaptureCraftContext=function(_,recipe,f,method,allocation,concentration,guid)
 eq(recipe,liveContext.recipeID);eq(method,liveContext.method);eq(concentration,liveContext.applyConcentration)
 eq(guid,'Item-current-target');local c=copy(liveContext);c.character=LL:CharacterKey();c.observed=99999999;return c
end
local function setup(page)
 local r=page.records[1];liveContext=copy(page.contexts[r.contextID])
 local input=r.nominalInputs[1]
 local f={id=input.itemID,reagentQuality=input.qualityRank,expansionID=input.expansionID,quality=input.rarity,classID=input.classID,count=input.quantity}
 local option={name=r.method,recipeID=r.recipeID,inputCount=input.quantity}
 local ctx={character=LL:CharacterKey(),inputQuality=f.reagentQuality}
 LL.ProcessingPlayerConditions=function()return ctx end
 return f,option,ctx
end
local oldModule=assert(arg[1],'pass immutable PR51 ImportedResults.lua as argument')
local function loadImporter(path)assert(loadfile(path))('LL',LL);LL._importedIndex=nil end
local currentModule='LootLiquidator/ImportedResults.lua'
local function freshOld()
 LL:ClearImportedResults();loadImporter(oldModule)
 local ok,msg,count=import(recycling);check(ok,msg);eq(count.accepted,200)
 return next(LL.db.importedResults.sets)
end
local function continuation(suffix,offset)
 local ids={}
 for _,r in ipairs(recycling.records)do ids[r.operationID]=r.operationID..suffix end
 local function rename(v)
  if type(v)=='string'then return ids[v] or v end
  if type(v)~='table'then return v end
  local n=setmetatable({},getmetatable(v));for k,x in pairs(v)do n[ids[k] or k]=rename(x)end;return n
 end
 local p=rename(recycling)
 for _,r in ipairs(p.records)do for _,receipt in ipairs(r.resultMetadata)do receipt.operationID=receipt.operationID+offset end end
 return p
end
local extension=continuation('-precision-extension',10000000)
local third=continuation('-precision-third',20000000)
local tiny=continuation('-precision-tiny',30000000)
local contextID=recycling.records[1].contextID
local original=tiny.contexts[contextID].operationStats[1].ratingPct
tiny.contexts[contextID].operationStats[1].ratingPct=original+1e-13
check(original~=tiny.contexts[contextID].operationStats[1].ratingPct,'unequal doubles')
eq(tostring(original),tostring(tiny.contexts[contextID].operationStats[1].ratingPct),'actual Lua5.1 old alias')
local f,option,ctx=setup(recycling)
local function all()return LL:ImportedEvidenceRecords('Recycle:245807')end
local function eligible()return LL:ImportedEvidenceRecords('Recycle:245807',f,option,ctx)end
local function add(p,n)local ok,msg,c=import(p);check(ok,msg);eq(c.accepted,n)end
local function replay(p)local ok,_,c=import(p);eq(ok,false);eq(c.duplicate,200)end
-- Real old implementation, real persisted state, then new implementation.
local legacyKey,persisted=freshOld()
local oldReference=persisted.referenceContextID
loadImporter(currentModule)
eq(#all(),1);eq(all()[1].samples,200,'old aggregate remains queryable')
eq(#eligible(),1);replay(recycling)
add(extension,200)
eq(#all(),1,'same-study unique continuation does not split');eq(all()[1].samples,400)
eq(#all()[1].sourceRecordIDs,400);near(all()[1].expectedInputCount,933/200,'refund denominator preserved')
eq(LL.db.importedResults.sets[legacyKey],nil,'old key moved')
local exactKey,same=next(LL.db.importedResults.sets);check(exactKey~=legacyKey)
eq(same,persisted,'migration preserves actual aggregate object');eq(same.referenceContextID,oldReference)
replay(recycling);replay(extension)
-- Live mismatch invalidates both successful and missing model cache.
check(LL:ResolveEvidenceModel(f,option,nil,1),'exact profile initially eligible')
liveContext.operationStats[1].ratingPct=original+1e-13
eq(#eligible(),0,'tiny numeric mismatch fails exact identity')
eq(LL:ResolveEvidenceModel(f,option,nil,1),nil,'cached success invalidated')
liveContext.operationStats[1].ratingPct=original
check(LL:ResolveEvidenceModel(f,option,nil,1),'cached absence invalidated')
add(tiny,200);eq(#all(),2,'new tiny profile separate');eq(#eligible(),1)
eq(eligible()[1].samples,400,'tiny profile does not contaminate original')
liveContext.operationStats[1].ratingPct=original+1e-13
eq(#eligible(),1);eq(eligible()[1].samples,200,'tiny profile retains own denominator')
liveContext.operationStats[1].ratingPct=original;replay(tiny)
-- Old-key collision: do not steal an unequal retained native profile.
legacyKey,persisted=freshOld();loadImporter(currentModule)
add(tiny,200);eq(#all(),2);eq(LL.db.importedResults.sets[legacyKey],persisted);eq(persisted.casts,200)
add(extension,200);eq(#all(),2);eq(eligible()[1].samples,400);replay(tiny)
-- Partial upgrade coexistence: reconcile complete disjoint sets without lost samples.
legacyKey,persisted=freshOld();local oldState=copy(LL.db.importedResults)
loadImporter(currentModule);LL:ClearImportedResults();add(extension,200)
local newKey,newSet=next(LL.db.importedResults.sets)
LL.db.importedResults.sets[legacyKey]=persisted
for k,v in pairs(oldState.seen)do LL.db.importedResults.seen[k]=v end
for k,v in pairs(oldState.nativeSeen)do LL.db.importedResults.nativeSeen[k]=v end
LL.db.importedResults.seenCount=LL.db.importedResults.seenCount+oldState.seenCount
LL._importedIndex=nil
eq(#eligible(),1,'post-load coexistence resolves before unseen import')
eq(eligible()[1].samples,400,'post-load unique samples retained')
local loaded=assert(LL:ResolveEvidenceModel(f,option,nil,1))
eq(loaded.materials[1].chanceCasts,100,'post-load evidence includes both groups')
add(third,200);eq(LL.db.importedResults.sets[legacyKey],nil);eq(persisted.casts,200)
eq(LL.db.importedResults.sets[newKey],newSet);eq(newSet.casts,600)
eq(#eligible(),1);eq(eligible()[1].samples,600)
local combined=assert(LL:ComputeEvidenceModel(f,option,nil,1,ctx))
eq(combined.materials[1].chanceCasts,150,'all 600 samples at existing 25 percent import weight')
near(combined.materials[1].expectedQuantity,1.98,'coexistence mean preserved')
LL.GetOutputPrice=function(_,id)return id==f.id and 20 or 100 end
near(LL:ValueProcessingModel(combined,0,true,f),(198+.335*20)/5,'coexistence valuation and refund preserved')
eq(LL:ImportedResultsCount(),600,'coexistence never overwrites valid state')
replay(recycling);replay(extension);replay(third)
-- Unsafe coexistence remains intact; aggregate outputs cannot be unblended by ID.
for _,damage in ipairs({'overlap','missing','duplicate','invalid-total'}) do
 legacyKey,persisted=freshOld();oldState=copy(LL.db.importedResults)
 loadImporter(currentModule);LL:ClearImportedResults();add(extension,200)
 newKey,newSet=next(LL.db.importedResults.sets)
 if damage=='overlap' then persisted.sourceRecordIDs[1]=newSet.sourceRecordIDs[1]
 elseif damage=='missing' then persisted.sourceRecordIDs[200]=nil
 elseif damage=='duplicate' then persisted.sourceRecordIDs[2]=persisted.sourceRecordIDs[1]
 else persisted.materials[243581].total=0 end
 LL.db.importedResults.sets[legacyKey]=persisted
 for k,v in pairs(oldState.seen)do LL.db.importedResults.seen[k]=v end
 for k,v in pairs(oldState.nativeSeen)do LL.db.importedResults.nativeSeen[k]=v end
 LL.db.importedResults.seenCount=LL.db.importedResults.seenCount+oldState.seenCount
 LL._importedIndex=nil
 add(third,200)
 eq(LL.db.importedResults.sets[legacyKey],persisted,'unsafe legacy retained: '..damage)
 eq(persisted.casts,200);eq(LL.db.importedResults.sets[newKey],newSet);eq(newSet.casts,400)
 eq(LL:ImportedResultsCount(),600);eq(#all(),2,'unsafe provenance is not invented: '..damage)
 eq(#eligible(),0,'ambiguous pair explicitly held: '..damage)
 eq(LL:ResolveEvidenceModel(f,option,nil,1),nil,'no arbitrary study winner: '..damage)
 for _,row in ipairs(all())do check(row.legacyProfileConflict);check(row.baselineStatus:find('Held:',1,true))end
 replay(recycling);replay(extension);replay(third)
end
-- Actual old importer demonstrably loses per-cast profile attribution already.
legacyKey,persisted=freshOld();add(tiny,200)
eq(#all(),1,'old implementation aliases unequal native profiles');eq(persisted.casts,400)
loadImporter(currentModule);eq(#all(),1);eq(all()[1].samples,400,'historical aggregate not silently dropped')
add(extension,200);eq(#all(),1);eq(all()[1].samples,600,'history preserved, not certified or reconstructed')
eq(persisted.observationContext.operationStats[1].ratingPct,original,'only first historical profile survives')
replay(tiny);replay(recycling);replay(extension)
-- Independent studies need the same derived context identity across versions.
legacyKey,persisted=freshOld();local savedReference=persisted.referenceContextID
local savedLineage=copy(persisted.sourceRecordIDs)
loadImporter(currentModule);f,option,ctx=setup(recycling)
local independent=continuation('-independent-precision',50000000)
local sid=independent.records[1].studyID
independent.studies[sid..'-independent']=independent.studies[sid];independent.studies[sid]=nil
for _,r in ipairs(independent.records)do r.studyID=sid..'-independent' end
add(independent,200)
local function independentModel(samples)
 local rows=eligible();eq(#rows,2,'both independent studies exact-live eligible')
 eq(rows[1].referenceContextID,rows[2].referenceContextID,'derived identity consistent across versions')
 check(rows[1].studyID~=rows[2].studyID,'source studies remain independent')
 local model=assert(LL:ResolveEvidenceModel(f,option,nil,1))
 eq(model.materials[1].chanceCasts,samples/4,'all independent samples contribute at existing source weight')
 near(model.materials[1].expectedQuantity,1.98,'independent mean retained')
 near(LL:ValueProcessingModel(model,0,true,f),(198+.335*20)/5,'independent value/refunds retained')
 check(model.sources.imported>0);eq(#model.excludedSources,0,'no false reference normalization exclusion')
 eq(persisted.referenceContextID,savedReference,'saved legacy identifier preserved')
 for i,id in ipairs(savedLineage)do eq(persisted.sourceRecordIDs[i],id,'old lineage retained')end
 local found=false
 for _,row in ipairs(rows)do if row.studyID==sid then
  found=true;eq(row.savedReferenceContextID,savedReference)
 end end
 check(found,'original source study retained')
end
independentModel(400)
add(extension,200);independentModel(600)
replay(recycling);replay(independent);replay(extension)
-- A different native double cannot enter either independent matching study.
add(tiny,200);eq(#all(),3);independentModel(600)
liveContext.operationStats[1].ratingPct=original+1e-13
eq(#eligible(),1);eq(eligible()[1].samples,200)
liveContext.operationStats[1].ratingPct=original
-- Reviewer public ConversionOptions warm-cache transitions with fixed outer ctx.
LL:ClearImportedResults();loadImporter(currentModule);add(recycling,200);f,option,ctx=setup(recycling)
LL.GetOutputPrice=function(_,id)return id==f.id and 20 or 100 end
LL.SalvageConversionOptions=function()return {{method='Recycle',recipeID=1229930,inputCount=5,salvage=true,profession='Engineering'}}end
LL.CanUseConversion=function()return true,nil,LL:CharacterKey()end
LL.GetLearnedProcessingEstimate=function()return nil end
LL.Conversions={};LL.db.recipeCandidates={};LL.EligibleDisenchant=function()return false end
local public=LL:ConversionOptions(f);eq(#public,1);check(public[1].value~=nil,'public matching value')
local stats=liveContext.operationStats
local positive=public[1].value
liveContext.operationStats[1].ratingPct=original+1e-13
public=LL:ConversionOptions(f);eq(#public,1);eq(public[1].value,nil,'public tiny mismatch invalidates warm model')
liveContext.operationStats[1].ratingPct=original
public=LL:ConversionOptions(f);near(public[1].value,positive,'public missing-to-matching')
liveContext.operationStats=nil
public=LL:ConversionOptions(f);eq(public[1].value,nil,'public matching-to-missing')
liveContext.operationStats=stats
public=LL:ConversionOptions(f);near(public[1].value,positive,'public absent-to-matching')
print('REVIEW PUBLIC CONVERSION CACHE PASSED')
-- Opposite signed zeros across importer versions must not split one study.
for _,negativeOld in ipairs({true,false})do
 LL:ClearImportedResults();loadImporter(oldModule)
 local z=copy(recycling);z.contexts[contextID].operationStats[1].ratingPct=negativeOld and -1/math.huge or 0
 add(z,200);loadImporter(currentModule);f,option,ctx=setup(z)
 local zext=copy(extension);zext.contexts[contextID].operationStats[1].ratingPct=negativeOld and 0 or -1/math.huge
 add(zext,200)
 eq(#all(),1,'opposite zero continuation remains one study')
 eq(LL:ImportedResultsCount(),400);eq(eligible()[1].samples,400)
 eq(LL:ResolveEvidenceModel(f,option,nil,1).materials[1].chanceCasts,100,'opposite zeros retain all samples')
 replay(z);replay(zext)
end
-- Two genuine old signed-zero groups also reconcile immediately on upgrade.
for _,negativeOld in ipairs({true,false})do for _,overlap in ipairs({false,true})do
 LL:ClearImportedResults();loadImporter(oldModule)
 local z=copy(recycling);z.contexts[contextID].operationStats[1].ratingPct=negativeOld and -1/math.huge or 0
 local zext=copy(extension);zext.contexts[contextID].operationStats[1].ratingPct=negativeOld and 0 or -1/math.huge
 add(z,200);add(zext,200);eq(#all(),2,'actual old signed-zero split')
 if overlap then
  local _,first=next(LL.db.importedResults.sets)
  for _,other in pairs(LL.db.importedResults.sets)do if other~=first then other.sourceRecordIDs[1]=first.sourceRecordIDs[1]end end
 end
 loadImporter(currentModule);f,option,ctx=setup(z)
 eq(LL:ImportedResultsCount(),400)
 if overlap then
  eq(#eligible(),0,'old-old overlap explicitly held');eq(#all(),2)
  eq(LL:ResolveEvidenceModel(f,option,nil,1),nil)
 else
  eq(#eligible(),1);eq(#all(),1);eq(eligible()[1].samples,400)
  eq(LL:ResolveEvidenceModel(f,option,nil,1).materials[1].chanceCasts,100,'old-old unique samples retained')
  local zthird=copy(third);zthird.contexts[contextID].operationStats[1].ratingPct=0
  add(zthird,200);eq(#eligible(),1);eq(eligible()[1].samples,600)
  eq(LL:ResolveEvidenceModel(f,option,nil,1).materials[1].chanceCasts,150)
 end
 replay(z);replay(zext)
 loadImporter(currentModule);eq(#eligible(),overlap and 0 or 1,'reload is idempotent')
end end
-- Numerically equal signed zeros retain equality; infinities/NaN do not match.
LL:ClearImportedResults();local zero=continuation('-zero',40000000)
zero.contexts[contextID].operationStats[1].ratingPct=0
add(zero,200);setup(zero);eq(#eligible(),1)
liveContext.operationStats[1].ratingPct=-1/math.huge;eq(#eligible(),1,'signed zeros are equal')
liveContext.operationStats[1].ratingPct=math.huge;eq(#eligible(),0)
liveContext.operationStats[1].ratingPct=0/0;eq(#eligible(),0)
-- Absent native data remains held, no anonymous tuple fallback.
liveContext.operationStats=nil;eq(#eligible(),0)
print('PASS: '..checks..' native profile precision and legacy upgrade assertions')
