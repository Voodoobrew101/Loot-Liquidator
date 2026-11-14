-- Import actual verified salvage receipts through the normal economic path.
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
local ok,msg,count=import(recycling);check(ok,msg);eq(count.accepted,200)
local f,option,ctx=setup(recycling)
local rows=assert(LL:ImportedEvidenceRecords('Recycle:245807'));eq(#rows,1);local r=rows[1]
eq(r.recipeID,1229930);eq(r.studyID,recycling.records[1].studyID);eq(#r.sourceRecordIDs,200)
eq(r.samples,200);eq(r.materials[1].id,243581);eq(r.materials[1].quality,1)
near(r.materials[1].expectedQuantity.value,396/200,'native total retained')
near(r.expectedInputCount,933/200,'net consumption preserves reported refunds')
local model=assert(LL:ComputeEvidenceModel(f,option,nil,1,ctx))
near(model.materials[1].expectedQuantity,1.98,'imported-only Recycling reaches resolver')
near(model.sources.imported,1,'separate source')
LL.GetOutputPrice=function(_,id)return id==f.id and 20 or 100 end
near(LL:ValueProcessingModel(model,0,true,f),(198+.335*20)/5,'input savings priced once per nominal batch')
eq(LL:ComputeEvidenceModel(f,option,nil,2,ctx),nil,'personal-only excludes imports')
LL:SetEvidenceSource('imported',false);eq(LL:ComputeEvidenceModel(f,option,nil,1,ctx),nil,'source disabled')
LL:SetEvidenceSource('imported',true)
local changed=copy(option);changed.recipeID=987654
eq(LL:ComputeEvidenceModel(f,changed,nil,1,ctx),nil,'no recipe leakage')
local old=liveContext.effectiveSkill;liveContext.effectiveSkill=old+1
eq(LL:ComputeEvidenceModel(f,option,nil,1,ctx),nil,'no skill extrapolation');liveContext.effectiveSkill=old
ctx.simulated=true;eq(LL:ComputeEvidenceModel(f,option,nil,1,ctx),nil,'simulation is not measured context');ctx.simulated=nil
ctx.character='Offline - Realm';eq(LL:ComputeEvidenceModel(f,option,nil,1,ctx),nil,'offline owner cannot use current API');ctx.character=LL:CharacterKey()
ok,msg,count=import(recycling);eq(ok,false);eq(count.duplicate,200)
LL:ClearImportedResults()
ok,msg,count=import(shatter);check(ok,msg);eq(count.accepted,4)
f,option,ctx=setup(shatter)
model=assert(LL:ComputeEvidenceModel(f,option,nil,1,ctx));near(model.materials[1].expectedQuantity,3,'Shatter native dust mean')
LL.GetOutputPrice=function(_,id)return id==f.id and 20 or 100 end
LL.SalvageConversionOptions=function()return {{method='Craft',recipeID=1280394,inputCount=1,salvage=true,profession='Enchanting'}}end
LL.CanUseConversion=function()return true,nil,LL:CharacterKey()end
LL.GetLearnedProcessingEstimate=function()return nil end
LL.Conversions={};LL.db.recipeCandidates={}
LL.EligibleDisenchant=function()return false end
local options=LL:ConversionOptions(f)
eq(#options,1);near(options[1].value,300,'imported-only Shatter is priced through actual Craft conversion discovery')
eq(options[1].available,true,'ordinary availability gate retained')
LL.CanUseConversion=function()return false,'Recipe unavailable',LL:CharacterKey()end
eq(LL:ConversionOptions(f)[1].available,false,'import cannot grant recipe access')
local originalCount=LL:ImportedResultsCount()
local function reject(change,label)
 LL:ClearImportedResults();local page=copy(shatter);change(page)
 local safe,accepted,why=pcall(import,page);check(safe,label..' must return a rejection without throwing: '..tostring(accepted))
 eq(accepted,false,label..': '..tostring(why));eq(LL:ImportedResultsCount(),0,'no biased cohort remainder')
end
reject(function(p)p.records[1].resultMetadata[1].quantity=4 end,'receipt mismatch')
reject(function(p)p.records[1].salvageTarget.itemGUID='another' end,'target mismatch')
reject(function(p)p.records[1].salvageTarget.eligibilitySource='guess'end,'unverified target')
reject(function(p)p.records[1].inputs[1].quantity=0 end,'unreported full refund')
reject(function(p)p.records[1].resultMetadata[1].resourcesReturned=setmetatable({{reagent={itemID=243602},quantity=1}},arrayMeta)end,'contradictory refund')
reject(function(p)p.records[1].resultMetadata[1].operationID=p.records[2].resultMetadata[1].operationID end,'duplicate native receipt')
reject(function(p)p.records[1].operationID=p.records[2].operationID end,'conflicting cast identity')
reject(function(p)p.records[1].bagReconciliation.operations=2 end,'missing batch member')
reject(function(p)p.records[1].bagReconciliation.outputs[1].quantity=4 end,'bag output mismatch')
reject(function(p)p.contexts[p.records[1].contextID].simulated=true end,'simulated source')
reject(function(p)p.contexts[p.records[1].contextID].recipeID=987654 end,'crossed context')
reject(function(p)p.contexts[p.records[1].contextID].inputIdentity[1]=true end,'malformed input identity')
reject(function(p)for _,r2 in ipairs(p.records)do r2.character=nil end;p.contexts[p.records[1].contextID].character=nil;p.studies[p.records[1].studyID].character=nil end,'missing source character')
reject(function(p)p.contexts[p.records[1].contextID].unexpected=string.rep('x',65537)end,'oversized context')
reject(function(p)p.records[1].allocation.extra=true end,'unsupported side allocation')
reject(function(p)p.studies[p.records[1].studyID].truncated=true end,'truncated study')
reject(function(p)p.studies[p.records[1].studyID].globalCoverageGap='uncertain'end,'global gap')
reject(function(p)local s=p.studies[p.records[1].studyID];s.censored=true;s.coverageGaps['Craft:1280394']={reason='unmatched'}end,'same recipe gap')
reject(function(p)p.studies[p.records[1].studyID].coverageGaps['Craft:1280394']={reason='unmatched'}end,'same recipe gap without censored flag')
reject(function(p)local s=p.studies[p.records[1].studyID];s.censored=false;s.coverageGaps['Craft:1280394']={reason='unmatched'}end,'same recipe gap with false censored flag')
reject(function(p)for _,r in ipairs(p.records)do r.recipeID=987654 end end,'arbitrary Craft remains unsupported')
reject(function(p)for _,r in ipairs(p.records)do r.method='Recycle'end end,'crossed method/recipe')
-- An unrelated scoped failure cannot censor good Shatter receipts.
LL:ClearImportedResults();local page=copy(shatter);local s=page.studies[page.records[1].studyID]
s.censored=true;s.coverageGaps['Craft:1229866']={reason='unmatched'}
check(import(page),'unrelated recipe gap remains usable')
-- Same measured profile in an independent study can contribute without losing
-- either study lineage. A changed profile still cannot join the live estimate.
local independent=copy(shatter)
local originalStudy=independent.records[1].studyID
independent.studies[originalStudy..'-independent']=independent.studies[originalStudy]
independent.studies[originalStudy]=nil
for _,r2 in ipairs(independent.records)do
 r2.studyID=originalStudy..'-independent';r2.operationID=r2.operationID..'-independent'
 r2.bagReconciliation.id=r2.operationID;r2.bagReconciliation.outputs[1].quantity=6
 r2.outputs[1].quantity=6;r2.resultMetadata[1].quantity=6;r2.resultMetadata[1].operationID=r2.resultMetadata[1].operationID+10
end
check(import(independent),'independent matching cohort admitted separately')
f,option,ctx=setup(shatter);model=assert(LL:ComputeEvidenceModel(f,option,nil,1,ctx))
near(model.materials[1].expectedQuantity,4.5,'both independent same-profile studies contribute')
local imported=LL:ImportedEvidenceRecords('Craft:243602');eq(#imported,2);eq(imported[1].referenceContextID,imported[2].referenceContextID)
-- Later coverage changes are scoped to the original study and recipe, across
-- all its profiles. The hold survives a reload and stale complete re-exports.
local function laterRecords(source,suffix,offset)
 local result=copy(source)
 for _,cast in ipairs(result.records)do
  cast.operationID=cast.operationID..suffix;cast.bagReconciliation.id=cast.bagReconciliation.id..suffix
  for _,receipt in ipairs(cast.resultMetadata)do receipt.operationID=receipt.operationID+offset end
 end
 return result
end
local function studyOf(source)return source.studies[source.records[1].studyID]end
local alternate=laterRecords(shatter,'-alternate-profile',10000)
local sourceContext=alternate.records[1].contextID
alternate.contexts[sourceContext..'-alternate']=alternate.contexts[sourceContext]
alternate.contexts[sourceContext]=nil
local profile=alternate.contexts[sourceContext..'-alternate']
profile.effectiveSkill=profile.effectiveSkill+1
for _,cast in ipairs(alternate.records)do cast.contextID=sourceContext..'-alternate' end
check(import(alternate),'same study has a second saved profile')
local sameStudyRecycling=laterRecords(recycling,'-shared-study',20000)
local recyclingStudy=sameStudyRecycling.records[1].studyID
sameStudyRecycling.studies[originalStudy]=sameStudyRecycling.studies[recyclingStudy]
sameStudyRecycling.studies[recyclingStudy]=nil
for _,cast in ipairs(sameStudyRecycling.records)do cast.studyID=originalStudy end
check(import(sameStudyRecycling),'different salvage recipe in same study')
near(assert(LL:ResolveEvidenceModel(f,option,nil,1)).materials[1].expectedQuantity,4.5,'combined model cached before later gap')
local lateGap=copy(shatter)
studyOf(lateGap).coverageGaps['Craft:1280394']={reason='Inputs have not settled'}
local malformed=copy(lateGap);studyOf(malformed).coverageGaps['Craft:1280394']={}
eq(import(malformed),false,'malformed gap does not revoke saved results')
local wrongCohort=copy(lateGap)
wrongCohort.contexts[sourceContext].effectiveSkill=profile.effectiveSkill
eq(import(wrongCohort),false,'unverified context does not revoke saved results')
local unresolved=copy(lateGap)
for _,cast in ipairs(unresolved.records)do cast.bagReconciliation.operations=2 end
eq(import(unresolved),false,'unreconciled rows cannot revoke saved results')
near(assert(LL:ResolveEvidenceModel(f,option,nil,1)).materials[1].expectedQuantity,4.5,'failed proof leaves warmed cache intact')
local savedCasts=LL:ImportedResultsCount()
ok,msg,count=import(lateGap);check(ok,msg);eq(count.accepted,0);eq(count.updatedSalvageHolds,1);eq(count.incomplete,4)
eq(LL:ImportedResultsCount(),savedCasts,'held casts remain in saved results')
near(assert(LL:ResolveEvidenceModel(f,option,nil,1)).materials[1].expectedQuantity,6,'late gap invalidates cached combined valuation')
f,option,ctx=setup(alternate);eq(LL:ResolveEvidenceModel(f,option,nil,1),nil,'other profile of the same study and recipe held')
f,option,ctx=setup(sameStudyRecycling);check(LL:ResolveEvidenceModel(f,option,nil,1),'other salvage recipe remains eligible')
LL.db.importedResults=copy(LL.db.importedResults);LL._importedIndex=nil
f,option,ctx=setup(shatter)
imported=assert(LL:ImportedEvidenceRecords('Craft:243602'));eq(#imported,1,'saved hold re-applied after reload')
eq(imported[1].studyID,originalStudy..'-independent','independent profile study remains eligible')
local stale=laterRecords(shatter,'-stale',30000)
ok,msg,count=import(stale);eq(ok,false);eq(count.incomplete,4,'stale complete export cannot add to a held cohort')

-- A verified later export can report truncation after every original receipt
-- has been evicted. It still identifies the retained exact source cohort.
local truncated=laterRecords(shatter,'-new-after-eviction',40000)
studyOf(truncated).truncated=true
truncated.records[1].bagReconciliation.operations=2
ok,msg,count=import(truncated);check(ok,msg);eq(count.accepted,0);eq(count.updatedSalvageHolds,1)
f,option,ctx=setup(sameStudyRecycling);eq(LL:ResolveEvidenceModel(f,option,nil,1),nil,'verified truncation holds other salvage recipes in the study')
f,option,ctx=setup(shatter)
near(assert(LL:ResolveEvidenceModel(f,option,nil,1)).materials[1].expectedQuantity,6,'truncation does not cross study identity')
-- Multiple genuine output packets may sum to one item; identical duplicate
-- packets are ambiguous and must not become additional measured output.
LL:ClearImportedResults();page=copy(shatter)
for _,r2 in ipairs(page.records)do local second=copy(r2.resultMetadata[1]);r2.resultMetadata[1].quantity=1;second.quantity=2;r2.resultMetadata[2]=second end
check(import(page),'distinct same-item packets aggregate to the recorded vector')
reject(function(p)local r2=p.records[1];r2.resultMetadata[2]=copy(r2.resultMetadata[1]);r2.outputs[1].quantity=6;r2.bagReconciliation.outputs[1].quantity=6 end,'identical repeated output packet')
-- Raw pages remain supported within the native copy limit; a larger raw
-- document requires the compact envelope or complete smaller export pages.
LL:ClearImportedResults();check(LL:ImportRecordedResults(json(shatter)),'ordinary raw Shatter page')
local large=read('2026-11-07-recycling-80-skill-200-casts/export-page-1.json')
check(#large>500000);eq(LL:ImportRecordedResults(large),false,'oversized raw import is rejected intact')
-- Revalidate exact native applicability before serving a cached economic model.
f,option,ctx=setup(shatter);check(LL:ResolveEvidenceModel(f,option,nil,1),'initial cached match')
liveContext.effectiveSkill=liveContext.effectiveSkill+1
eq(LL:ResolveEvidenceModel(f,option,nil,1),nil,'changed measured state invalidates cached match')
liveContext.effectiveSkill=liveContext.effectiveSkill-1
check(LL:ResolveEvidenceModel(f,option,nil,1),'restored match also replaces cached missing-data answer')
-- Fully refunded operations retain a nominal input and all measured outputs.
LL:ClearImportedResults();page=copy(shatter)
for _,r2 in ipairs(page.records)do
 r2.inputs[1].quantity=0
 r2.resultMetadata[1].resourcesReturned=setmetatable({{reagent={itemID=243602},quantity=1}},arrayMeta)
 r2.bagReconciliation.inputs=setmetatable({},arrayMeta)
end
check(import(page),'explicit full refunds accepted')
f,option,ctx=setup(page);model=assert(LL:ComputeEvidenceModel(f,option,nil,1,ctx))
eq(model.expectedInputCount,0,'zero consumed is distinct from unknown')
near(LL:ValueProcessingModel(model,0,true,f),320,'full refund saves nominal shard without extra dust')
-- Native result identity also prevents replay with a rewritten cast GUID.
local replay=copy(page);for _,r2 in ipairs(replay.records)do r2.operationID=r2.operationID..'-alias';r2.bagReconciliation.id=r2.operationID end
ok,msg,count=import(replay);eq(ok,false);eq(count.duplicate,4,'native receipt replay refused')
LL:ClearImportedResults();LL.db.craftResearch={records=page.records}
ok,msg,count=import(page);eq(ok,false);eq(count.own,4,'own recordings remain separate')
eq(originalCount,4)
print('PASS: '..checks..' verified salvage import assertions (real receipts, context, refunds and economic discovery)')
