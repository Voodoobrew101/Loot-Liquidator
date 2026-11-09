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
local arrayFields={records=true,inputs=true,nominalInputs=true,outputs=true}
local function json(v,forceArray)
 if type(v)=='string' then return '"'..v..'"' end
 if type(v)=='number' or type(v)=='boolean' then return tostring(v) end
 if #v>0 or forceArray then local o={} for i=1,#v do o[i]=json(v[i]) end return '['..table.concat(o,',')..']' end
 local o={} for k,x in pairs(v) do o[#o+1]='"'..k..'":'..json(x,arrayFields[k]) end return '{'..table.concat(o,',')..'}'
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

-- Drop precision is not quantity precision. Preserve the old evidence weights
-- without manufacturing uncertainty for totals or observed conditional bounds.
for _,field in ipairs({'expectedQuantity','minQuantity','maxQuantity'}) do
 eq(gem[field].confidence,nil,field..' confidence is unknown, not zero')
 eq(gem[field].confidenceUnscored,true,field..' is explicitly unscored')
 eq(gem[field].evidenceScore,gem.dropChance.confidence,'legacy ordinal weight retained')
end
eq(gem.dropChance.confidenceBasis,'drop-rate-normal-approximation-5pp')
-- Compare the entire priced model's economic and selection numbers with the
-- original imported contract, including mixed sources, stale data and sliders.
local function numericSnapshot(t,prefix,out)
 out=out or {};prefix=prefix or ''
 for k,v in pairs(t) do
  local key=prefix..'/'..tostring(k)
  if type(v)=='number' then out[key]=v
  elseif type(v)=='table' then numericSnapshot(v,key,out) end
 end
 return out
end
local function numericEqual(a,b)
 local aa,bb=numericSnapshot(a),numericSnapshot(b)
 for k,v in pairs(aa) do check(bb[k] and math.abs(v-bb[k])<1e-9,'preserved '..k) end
 for k in pairs(bb) do check(aa[k]~=nil,'no missing economic number '..k) end
end
local function compute(personal)
 local m=assert(LL:ComputeEvidenceModel(f,{name='Prospect',inputCount=5,recipeID=1231127},personal,1,{}))
 LL.GetMaterialPrice=function(_,material)return material.id==20 and 100 or 10 end
 check(LL:ValueProcessingModel(m,0,true)~=nil,'imported means remain priceable')
 return m
end
local function legacyFields(enable)
 for _,m in ipairs(r.materials) do
  for _,name in ipairs({'expectedQuantity','minQuantity','maxQuantity'}) do
   local field=m[name]
   field.confidence=enable and m.dropChance.confidence or nil
   field.evidenceScore=not enable and m.dropChance.confidence or nil
   field.confidenceUnscored=not enable or nil
  end
 end
end
local personal={effectiveSamples=30,samples=30,inputCount=5,materials={
 {id=20,expectedQuantity=.4,chance=.2,minQuantity=1,maxQuantity=2},
 {id=21,expectedQuantity=2,chance=1,minQuantity=2,maxQuantity=2}}}
for _,mixed in ipairs({false,true}) do
 for _,stale in ipairs({false,true}) do
  for _,weight in ipairs({1,25,100}) do
   LL:SetEvidenceSource('imported',true,weight)
   r.obsolete=stale or nil
   local fixed=compute(mixed and personal or nil)
   eq(fixed.confidenceUnscored,true,'any contributing imported expectation is unscored')
   for _,m in ipairs(fixed.materials) do eq(m.confidenceUnscored,true) end
   legacyFields(true)
   local original=compute(mixed and personal or nil)
   numericEqual(fixed,original)
   legacyFields(false)
  end
 end
end
r.obsolete=nil;LL:SetEvidenceSource('imported',true,25)
LL:SetEvidenceSource('imported',false)
local excluded=compute(personal)
eq(excluded.confidenceUnscored,nil,'disabled imports cannot taint a scored model')
LL:SetEvidenceSource('imported',true,25)
-- Render the actual imported model through the normal recommendation tooltip.
assert(loadfile('LootLiquidator/Badges.lua'))('LootLiquidator',LL)
LL.db.tooltipDetail=3;LL.db.showMaterialConfidence=true
LL.MarkupColor=function()return ''end;LL.Money=function(_,n)return tostring(n)..' copper'end
LL.ProfessionProgression=function()return {}end
local actual=compute(personal)
local tip={lines={}}
function tip:AddLine(s)self.lines[#self.lines+1]=s end
function tip:AddDoubleLine(l,r)self.lines[#self.lines+1]=l..' | '..r end
LL:AppendRecommendationTooltip(tip,{action='P',facts=f,count=5,
 conversionOptions={{name='Prospect',letter='P',available=true,value=actual.value,yieldModel=actual}}})
local shown=table.concat(tip.lines,'\n')
check(shown:find('Confidence unscored',1,true),'actual imported option is explicitly unscored')
check(not shown:match('Confidence %d+%%'), 'no option probability claim')
check(not shown:match('%(%d+%%%)'),'no material confidence percentage')
check(shown:find('copper',1,true),'economic values remain visible')

-- Public option boundaries must not export internal heuristic scores as
-- confidence. Feed the real computed import model through both option APIs.
local savedResolve=LL.ResolveEvidenceModel
LL.ResolveEvidenceModel=function()return actual end
LL.Conversions={[10]={{method='Prospect',inputCount=5,recipeID=1231127}}}
LL.CanUseConversion=function()return true end
LL.EligibleDisenchant=function()return false end
local options=LL:ConversionOptions(f)
check(#options>0,'actual conversion API returns an option')
eq(options[1].confidence,'unknown','conversion API does not export heuristic confidence')
eq(options[1].value,actual.value,'conversion API preserves quoted value')
local savedEligible,savedExpansion=LL.EligibleDisenchant,LL.DisenchantExpansion
LL.EligibleDisenchant=function()return true end;LL.DisenchantExpansion=function()return 11 end
local deOption=assert(LL:EvaluateDisenchant(f))
eq(deOption.confidence,'unknown','disenchant API does not export heuristic confidence')
eq(deOption.value,actual.value,'disenchant API preserves quoted value')
LL.EligibleDisenchant=savedEligible;LL.DisenchantExpansion=savedExpansion
LL.ResolveEvidenceModel=savedResolve;LL.Conversions=nil

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

-- B7b: malformed JSON must never partially import a plausible-looking page.
local before=LL:ImportedResultsCount()
local valid=page({cast('strict-json',{{itemID=21,quantity=3}})})
for _,number in ipairs({'03','3.','3.e0','3e','3e+','+3','0x3','3e999'}) do
 local text,n=valid:gsub('"quantity":3','"quantity":'..number,1)
 eq(n,1,'fixture has an output quantity')
 eq((LL:ImportRecordedResults(text)),false,'invalid number: '..number)
 eq(LL:ImportedResultsCount(),before,'invalid JSON never changes counts')
end
for _,text in ipairs({
 valid:gsub('"strict%-json"','"line\nbreak"'),
 valid:gsub('"strict%-json"','"nul'..string.char(0)..'byte"'),
 valid:gsub('"strict%-json"','"\\uD800"'),
 valid:gsub('"strict%-json"','"\\uDC00"'),
 valid:gsub('"strict%-json"','"\\uD800\\u0041"'),
 valid:gsub('"strict%-json"','"\\u00xz"'),
 valid:gsub('"quantity":3','"quantity":900,"quantity":3',1),
 valid:gsub('"quantity":3','"quantity":null,"quantity":3',1),
 (valid:gsub('"quantity":3','"quantity":900,"\\u0071uantity":3',1)),
}) do
 eq((LL:ImportRecordedResults(text)),false,'damaged text or repeated field rejected')
 eq(LL:ImportedResultsCount(),before,'no partial import of malformed JSON')
end
-- Valid decimal/exponent notation still works; escaped names keep their identity.
for i,number in ipairs({'3.0','3e0','3E+0'}) do
 local text=page({cast('valid-number-'..i,{{itemID=21,quantity=3}})}):gsub('"quantity":3','"quantity":'..number,1)
 check((LL:ImportRecordedResults(text)),'valid JSON number: '..number)
end
local unicode=page({cast('unicode-name',{{itemID=21,quantity=3}})}):gsub('"unicode%-name"','"caf\\u00e9-\\uD83D\\uDE00"')
check((LL:ImportRecordedResults(unicode)),'escaped Unicode operation ID imports')
local decodedID='caf'..string.char(195,169)..'-'..string.char(240,159,152,128)
eq((LL:ImportRecordedResults(page({cast(decodedID,{{itemID=21,quantity=3}})}))),false,'same UTF-8 ID is a duplicate')
check((LL:ImportRecordedResults(page({cast('caf?-?',{{itemID=21,quantity=3}})}))),'different name must not collapse to question marks')

-- Null array entries remain visible to validation instead of becoming Lua holes.
local withNull=page({cast('after-null',{{itemID=21,quantity=3}})}):gsub('"records":%[','"records":[null,',1)
ok,msg,counts=LL:ImportRecordedResults(withNull)
check(ok,msg);eq(counts.accepted,1);eq(counts.damaged,1,'null cast counted as damaged')
local nullOutput=page({cast('null-output',{{itemID=21,quantity=3}})}):gsub('"outputs":%[','"outputs":[null,',1)
eq((LL:ImportRecordedResults(nullOutput)),false,'null material invalidates the cast')
local nullInput=page({cast('null-input',{{itemID=21,quantity=3}})}):gsub('"nominalInputs":%[','"nominalInputs":[null,',1)
eq((LL:ImportRecordedResults(nullInput)),false,'null input cannot disappear')
local falseInput=page({cast('false-input',{{itemID=21,quantity=3}},{nominalInputs=false})})
eq((LL:ImportRecordedResults(falseInput)),false,'invalid nominal inputs cannot fall back to actual inputs')
-- A confirmed empty result uses [], never {} or null, for its output list.
local empty=page({cast('confirmed-empty',{}, {zeroEvidence='operator-confirmed-empty'})})
eq((LL:ImportRecordedResults((empty:gsub('"outputs":%[%]','"outputs":{}')))),false,'object cannot stand for empty output array')
eq((LL:ImportRecordedResults((empty:gsub('"outputs":%[%]','"outputs":null')))),false,'null cannot stand for empty output array')
check((LL:ImportRecordedResults(empty)),'confirmed empty output array still imports')

-- Results from another game build still count, at a lower (stale) weight.
ok=LL:ImportRecordedResults(page({cast('oldbuild',{{itemID=30,quantity=1}},{build='100000',inputs={{itemID=11,quantity=5}},nominalInputs={{itemID=11,quantity=5}}})}))
check(ok);check(LL:ImportedEvidenceRecords('Prospect:11')[1].obsolete,'old build marked stale, not dropped')

-- Disenchant imports apply to their expansion/rarity/armor-or-weapon group,
-- including items that were never in the imported log. The same item ID can
-- occur at another rarity, so its ID cannot be the grouping key.
LL:SetEvidenceSource('legacy',false);LL:SetEvidenceSource('reference',false)
local function de(id,item,quantity,expansion,rarity,classID,extra)
 local input={itemID=item,quantity=1,expansionID=expansion,rarity=rarity,classID=classID}
 local overrides={method='Disenchant',recipeID=13262,inputs={input},nominalInputs={input}}
 for k,v in pairs(extra or {}) do overrides[k]=v end
 return cast(id,{{itemID=300,quantity=quantity}},overrides)
end
local grouped={
 de('de-rare-a',201,1,11,3,4),de('de-rare-b',202,3,11,3,4),
 de('de-epic',201,4,11,4,4),de('de-other-expansion',203,2,10,3,4),
 de('de-weapon',204,5,11,3,2),
}
ok,msg,counts=LL:ImportRecordedResults(page(grouped));check(ok,msg);eq(counts.accepted,5)
local category=assert(LL:ImportedEvidenceRecords('Disenchant:gear:11:3:armor'))
eq(#category,1,'one category record for two sampled armor IDs');eq(category[1].samples,2,'casts counted once')
eq(category[1].gearKey,'gear:11:3:armor');eq(category[1].inputItemID,nil,'category is not exact-item evidence')
eq(#category[1].memberInputItemIDs,2,'sampled item IDs retained as provenance')
eq(category[1].inputRarity,3);eq(category[1].inputClassID,4);eq(category[1].expansionID,11)
eq(category[1].materials[1].expectedQuantity.value,2,'category mean pools reported totals')
eq(category[1].materials[1].dropChance.value,1,'category chance pools reported hits')
eq(LL:ImportedEvidenceRecords('Disenchant:201'),nil,'no duplicate exact-ID index for category casts')
eq(LL:ImportedEvidenceRecords('Disenchant:gear:11:4:armor')[1].samples,1,'rarity remains separate')
eq(LL:ImportedEvidenceRecords('Disenchant:gear:10:3:armor')[1].samples,1,'expansion remains separate')
eq(LL:ImportedEvidenceRecords('Disenchant:gear:11:3:weapon')[1].samples,1,'weapons remain separate')
local gear={id=299,quality=3,classID=4,expansionID=11}
local option={name='Disenchant',inputCount=1,recipeID=13262}
model=assert(LL:ComputeEvidenceModel(gear,option,nil,1,{}))
eq(model.materials[1].expectedQuantity,2,'unseen matching item receives the category result')
eq((LL:ComputeEvidenceModel({id=299,quality=2,classID=4,expansionID=11},option,nil,1,{})),nil,'no rarity leakage')
eq((LL:ComputeEvidenceModel({id=299,quality=3,classID=2,expansionID=9},option,nil,1,{})),nil,'no expansion leakage')
eq((LL:ComputeEvidenceModel(gear,option,nil,2,{})),nil,'personal-only mode still excludes imported categories')
LL:SetEvidenceSource('imported',false)
eq((LL:ComputeEvidenceModel(gear,option,nil,1,{})),nil,'source switch still excludes imported categories')
LL:SetEvidenceSource('imported',true)
ok,msg,counts=LL:ImportRecordedResults(page(grouped));eq(ok,false,'category import duplicates refused');eq(counts.duplicate,5)
eq(LL:ImportedEvidenceRecords('Disenchant:gear:11:3:armor')[1].samples,2,'duplicate casts do not inflate category totals')

-- Old exports without classification remain available on their sampled item;
-- partial metadata stays scoped and cannot be promoted into a guessed group.
ok,msg=LL:ImportRecordedResults(page({de('de-legacy',205,1),de('de-partial',206,2,nil,3,4)}));check(ok,msg)
eq(LL:ImportedEvidenceRecords('Disenchant:205')[1].gearKey,nil,'legacy export remains exact-item fallback')
local partial=LL:ImportedEvidenceRecords('Disenchant:206')[1]
eq(partial.gearKey,nil,'partial classification does not invent an expansion')
eq(partial.inputRarity,3,'partial rarity preserved');eq(partial.inputClassID,4,'partial class preserved')
local upgraded=assert(LL:ComputeEvidenceModel({id=206,quality=4,classID=4,expansionID=11},option,nil,1,{}))
eq(upgraded.materials[1].expectedQuantity,4,'upgraded item gets epic category, excluding partial rare data')
for i,meta in ipairs({{12,3,4},{11,5,4},{11,3,7},{'11',3,4},{false,3,4},{11,false,4},{11,3,false}}) do
 eq((LL:ImportRecordedResults(page({de('de-invalid-meta-'..i,207,1,meta[1],meta[2],meta[3])}))),false,'invalid category metadata rejected')
end
ok,msg=LL:ImportRecordedResults(page({de('de-old-category',208,1,11,3,4,{build='100000'})}));check(ok,msg)
category=LL:ImportedEvidenceRecords('Disenchant:gear:11:3:armor')
eq(#category,2,'builds retain separate category cohorts')
local stale=0;for _,record in ipairs(category) do if record.obsolete then stale=stale+1;eq(record.samples,1) else eq(record.samples,2) end end
eq(stale,1,'historical category retains stale discount')
LL:SetEvidenceSource('legacy',true);LL:SetEvidenceSource('reference',true)

-- Remove imported results.
ok,msg=LL:ClearImportedResults();check(ok,msg);eq(LL:ImportedResultsCount(),0);eq(LL:ImportedEvidenceRecords('Prospect:10'),nil)
check(LL.db.craftResearch.records[1].operationID=='mine-1','own results untouched')
print('PASS: '..checks..' import assertions (B7: separate source, own confidence, damaged values rejected)')
