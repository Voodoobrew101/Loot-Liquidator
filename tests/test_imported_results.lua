-- B7: importing another player's exported results as a separate source.
-- Values are deterministic fixtures, not WoW yields.
local checks=0
local function check(v,msg) assert(v,msg);checks=checks+1 end
local function eq(a,b,msg) check(a==b,(msg or '')..' '..tostring(a)..' ~= '..tostring(b)) end
GetTime=function() return 0 end;time=function() return 1000 end
GetBuildInfo=function() return 'test','123456','',120105 end
UnitName=function() return 'Tester' end;GetRealmName=function() return 'Realm' end
CreateFrame=function() local f={};function f:RegisterEvent() end;function f:SetScript() end;return f end
hooksecurefunc=function() end;C_Timer={After=function() end}
local LL={db={characters={},recordConversions=true,recordDisenchants=true}}
for _,name in ipairs({'ItemDBRuntime.lua','Database.lua','Professions.lua','Observations.lua','CraftRecording.lua','ImportedResults.lua','ConversionEngine.lua'}) do
 assert(loadfile('LootLiquidator/'..name))('LootLiquidator',LL)
end
LL.ItemDB={schemaVersion=1,version='import-fixture',inputs={},processing={},mechanicRules={}}
check(LL:InitializeItemDB());LL:MigrateEvidenceSettings()
eq(LL.db.source_imported_enabled,true,'imported source on by default');eq(LL.db.source_imported_weight,25,'imported default weight')
check(LL.SourceOrder[3]=='imported','imported listed in Database & Accuracy')

-- Minimal JSON writer for fixtures (same layout the Export button produces).
local function json(v)
 if type(v)=='string' then return '"'..v..'"' end
 if type(v)=='number' or type(v)=='boolean' then return tostring(v) end
 if #v>0 then local o={} for i=1,#v do o[i]=json(v[i]) end return '['..table.concat(o,',')..']' end
 local o={} for k,x in pairs(v) do o[#o+1]='"'..k..'":'..json(x) end return '{'..table.concat(o,',')..'}'
end
local function cast(id,outputs,overrides)
 local r={operationID=id,recipeID=1231127,method='Prospect',successful=true,character='Other-Realm',build='123456',
  outputCoverage='complete',inputs={{itemID=10,quantity=5}},nominalInputs={{itemID=10,quantity=5}},outputs=outputs}
 for k,v in pairs(overrides or {}) do r[k]=v end
 return r
end
local function page(records,extra)
 local t={schemaVersion='loot-liquidator.cast-log/1',sampleKind='RAW_CAST_LOG',page=1,pages=1,records=records,contexts={},studies={}}
 for k,v in pairs(extra or {}) do t[k]=v end
 return json(t)
end
-- 50 casts: item 20 drops in 9 (18%), x1 or x2; item 21 every cast, x3.
local records={}
for i=1,50 do
 local out={{itemID=21,quantity=3}}
 if i<=9 then out[#out+1]={itemID=20,quantity=i%2+1} end
 records[i]=cast('op'..i,out)
end
records[51]=cast('op-unresolved',{{itemID=21,quantity=3}},{outputCoverage='unresolved'})
local ok,msg,counts=LL:ImportRecordedResults(page(records))
check(ok,msg);eq(counts.accepted,50);eq(counts.incomplete,1,'unresolved casts are skipped, not counted')
check(msg:find('Imported 50 results',1,true),msg);eq(LL:ImportedResultsCount(),50)

-- Stored as counts in a separate source with its own confidence.
local ev=LL:ImportedEvidenceRecords('Prospect:10');check(ev and #ev==1,'one imported record')
local r=ev[1];eq(r.sourceKey,'imported');eq(r.samples,50);eq(r.inputCount,5);eq(r.obsolete,nil,'same build is current')
local gem;for _,m in ipairs(r.materials) do if m.id==20 then gem=m end end
check(math.abs(gem.dropChance.value-.18)<1e-9,'chance = drops / casts')
check(math.abs(gem.expectedQuantity.value-(5*2+4*1)/50)<1e-9,'average = total / casts')
eq(gem.minQuantity.value,1);eq(gem.maxQuantity.value,2)
check(gem.dropChance.confidence>=60 and gem.dropChance.confidence<=68,'18% over 50 casts is about 64% confidence: '..gem.dropChance.confidence)
eq(LL.ImportChanceConfidence(18,100)>=78 and LL.ImportChanceConfidence(18,100)<=84,true,'about 81% at 100 casts')

-- Imported-only items get an answer, and personal-only mode excludes them.
local f={id=10,quality=1,classID=7,expansionID=11}
local model=assert(LL:ComputeEvidenceModel(f,{name='Prospect',inputCount=5,recipeID=1231127},nil,1,{}))
check(math.abs((model.sources.imported or 0)-1)<1e-9,'imported results drive the estimate when nothing else exists')
check(model.confidence>0,'imported estimate carries a confidence')
eq((LL:ComputeEvidenceModel(f,{name='Prospect',inputCount=5},nil,2,{})),nil,'personal-only mode ignores imported results')
LL:SetEvidenceSource('imported',false);eq((LL:ComputeEvidenceModel(f,{name='Prospect',inputCount=5},nil,1,{})),nil,'imported source can be switched off')
LL:SetEvidenceSource('imported',true)

-- The same paste twice is refused; nothing is double counted.
ok,msg,counts=LL:ImportRecordedResults(page(records))
eq(ok,false,'duplicate paste');eq(counts.duplicate,50);eq(LL:ImportedResultsCount(),50)
-- Your own casts are never re-imported as someone else's.
LL.db.craftResearch={records={{operationID='mine-1'}}}
ok,msg,counts=LL:ImportRecordedResults(page({cast('mine-1',{{itemID=21,quantity=3}}),cast('new-1',{{itemID=21,quantity=3}})}))
check(ok,msg);eq(counts.own,1);eq(counts.accepted,1);eq(LL:ImportedResultsCount(),51)

-- Damaged or impossible values.
local bad={}
for i=1,10 do bad[i]=cast('bad'..i,{{itemID=21,quantity=3}}) end
bad[1].outputs[1].quantity=1000;bad[2].outputs[1].quantity=-1;bad[3].inputs[1].quantity=0;bad[3].nominalInputs=nil
ok,msg=LL:ImportRecordedResults(page(bad));eq(ok,false,'many impossible values reject the whole paste')
check(msg:find('damaged or edited',1,true),msg);eq(LL:ImportedResultsCount(),51,'nothing imported from a damaged paste')
local mostlyGood={}
for i=1,20 do mostlyGood[i]=cast('good'..i,{{itemID=21,quantity=3}}) end
mostlyGood[5].outputs={{itemID=21,quantity=2.5}}
ok,msg,counts=LL:ImportRecordedResults(page(mostlyGood));check(ok,msg);eq(counts.damaged,1);eq(counts.accepted,19)
for _,text in ipairs({'','   ','not json at all','{"records":[','{"schemaVersion":"other","sampleKind":"RAW_CAST_LOG","records":[]}',
  page({},{sampleKind='SOMETHING_ELSE'}),page({cast('x',{{itemID=21,quantity=3}})})..' trailing'}) do
 eq((LL:ImportRecordedResults(text)),false,'rejected: '..text:sub(1,40))
end
eq((LL:ImportRecordedResults(page({cast('same-item',{{itemID=10,quantity=1}})}))),false,'output equal to the input is impossible')
eq((LL:ImportRecordedResults(page({cast('de5',{{itemID=21,quantity=1}},{method='Disenchant'})}))),false,'disenchanting uses one item')

-- Results from another game build still count, at a lower (stale) weight.
ok=LL:ImportRecordedResults(page({cast('oldbuild',{{itemID=30,quantity=1}},{build='100000',inputs={{itemID=11,quantity=5}},nominalInputs={{itemID=11,quantity=5}}})}))
check(ok);check(LL:ImportedEvidenceRecords('Prospect:11')[1].obsolete,'old build marked stale, not dropped')

-- Remove imported results.
ok,msg=LL:ClearImportedResults();check(ok,msg);eq(LL:ImportedResultsCount(),0);eq(LL:ImportedEvidenceRecords('Prospect:10'),nil)
check(LL.db.craftResearch.records[1].operationID=='mine-1','own results untouched')
print('PASS: '..checks..' import assertions (B7: separate source, own confidence, damaged values rejected)')
