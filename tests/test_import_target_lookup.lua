-- Query-local inventory target reuse through actual imported salvage queries.
-- Preserved exports and synthetic study copies test behavior, not empirical yields.
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
if arg[1] then assert(loadfile(arg[1]))('LL',LL) end
local realFind=LL.FindSkillQualityTarget
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

-- Scaling-only synthetic copies of the preserved 200-cast export; not empirical evidence.
local function study(n)
 local ids={}
 for _,r in ipairs(recycling.records)do ids[r.operationID]=r.operationID..'-scale-'..n end
 local sid=recycling.records[1].studyID;ids[sid]=sid..'-scale-'..n
 local function rename(v)
  if type(v)=='string'then return ids[v] or v end
  if type(v)~='table'then return v end
  local x=setmetatable({},getmetatable(v))
  for k,a in pairs(v)do x[ids[k] or k]=rename(a)end;return x
 end
 local p=rename(recycling)
 for _,r in ipairs(p.records)do for _,receipt in ipairs(r.resultMetadata)do receipt.operationID=receipt.operationID+n*10000000 end end
 return p
end

local f,option,ctx=setup(recycling)
local key='Recycle:'..f.id
local bag,slot,targetGUID,present=5,20,'Item-current-target',true
local reads,finds,captures=0,0,0
ItemLocation={CreateFromBagAndSlot=function(_,b,s)return {bag=b,slot=s}end}
C_Container={GetContainerNumSlots=function()return 20 end}
C_Item={GetItemID=function(loc)
 reads=reads+1;return present and loc.bag==bag and loc.slot==slot and f.id or 1
 end,GetItemGUID=function()return targetGUID end}
C_TradeSkillUI={GetItemReagentQualityByItemInfo=function()return f.reagentQuality end}
LL.FindSkillQualityTarget=function(self,...)finds=finds+1;return realFind(self,...)end
LL.CaptureCraftContext=function(_,recipe,_,method,allocation,concentration,guid)
 captures=captures+1;eq(recipe,liveContext.recipeID);eq(method,liveContext.method)
 eq(guid,targetGUID);eq(concentration,false)
 local c=copy(liveContext);c.character=LL:CharacterKey();return c
end
local function reset()reads,finds,captures=0,0,0 end
local function rows()
 return LL:ImportedEvidenceRecords(key,f,option,ctx) or {}
end
local function expect(n,scans,inspections,cap)
 reset();local result=rows();eq(#result,n);eq(finds,scans,'target searches per query')
 eq(reads,inspections,'native inventory reads');eq(captures,cap,'context captures');return result
end
-- Laziness: no evidence, no matching coarse eligibility, and unrelated plain data.
eq(#rows(),0);eq(finds,0)
for n=1,8 do local ok,msg,c=import(n==1 and recycling or study(n));check(ok,msg);eq(c.accepted,200)end
local all=LL:ImportedEvidenceRecords(key);eq(#all,8)
local good=expect(8,1,120,1)
for i,r in ipairs(good)do
 eq(r,all[i],'exact original evidence object/order')
 eq(r.samples,200);eq(#r.sourceRecordIDs,200)
 near(r.materials[1].expectedQuantity.value,396/200,'unchanged quantity')
 near(r.expectedInputCount,933/200,'unchanged net consumption')
end
for _,name in ipairs({'simulated','stale'})do ctx[name]=true;expect(0,0,0,0);ctx[name]=nil end
local owner=ctx.character;ctx.character='Offline';expect(0,0,0,0);ctx.character=owner
local recipe=option.recipeID;option.recipeID=1;expect(0,0,0,0);option.recipeID=recipe
local batch=option.inputCount;option.inputCount=1;expect(0,0,0,0);option.inputCount=batch
local rank=f.reagentQuality;f.reagentQuality=rank+1;expect(0,0,0,0);f.reagentQuality=rank
-- First row is ineligible, later rows still trigger exactly one lazy lookup.
local saved=all[1].recipeID;all[1].recipeID=1
local subset=expect(7,1,120,1);for i,r in ipairs(subset)do eq(r,all[i+1])end
all[1].recipeID=saved
-- Ordinary evidence must not trigger any target lookup.
LL._importedIndex['Mill:1']={{method='Mill'}}
reset();eq(#LL:ImportedEvidenceRecords('Mill:1',{id=1},{name='Mill'},ctx),1);eq(finds,0)
-- Missing results are memoized only inside this call, never into the next one.
present=false;expect(0,1,120,0);expect(0,1,120,0)
present=true;expect(8,1,120,1)
-- Real location/GUID changes on successive calls remain freshly verified.
bag,slot,targetGUID=0,1,'Item-moved-target';expect(8,1,1,1)
f.context={bagID=bag,slotID=slot};expect(8,1,1,1)
f.context={itemLocation={bag=bag,slot=slot}};expect(8,1,1,1)
f.context=nil;bag,slot=5,20;expect(8,1,120,1)
local skill=liveContext.effectiveSkill
liveContext.effectiveSkill=skill+1;expect(0,1,120,1)
liveContext.effectiveSkill=skill;expect(8,1,120,1)
local equipment=liveContext.fieldStatus.equipment
liveContext.fieldStatus.equipment='unknown';expect(0,1,120,1)
liveContext.fieldStatus.equipment=equipment
-- Different allocation queries must still capture independently.
local allocation=all[1].allocation;all[1].allocation={{syntheticAllocationVariant=true}}
expect(8,1,120,2);all[1].allocation=allocation
LL.GetOutputPrice=function(_,id)return id==f.id and 20 or 100 end
LL.SalvageConversionOptions=function()return {{method='Recycle',recipeID=1229930,inputCount=5,salvage=true,profession='Engineering'}}end
LL.CanUseConversion=function()return true,nil,LL:CharacterKey()end
LL.GetLearnedProcessingEstimate=function()return nil end
LL.Conversions={};LL.db.recipeCandidates={};LL.EligibleDisenchant=function()return false end
local value=(198+.335*20)/5
local function public(expected)
 reset();local out=LL:ConversionOptions(f);eq(#out,1);eq(finds,1)
 if expected then near(out[1].value,value,'public unchanged net-input value')
 else eq(out[1].value,nil,'public unavailable estimate')end
 return out[1]
end
LL._processingModelCache=nil
local first=public(true);local model=first.yieldModel
near(model.materials[1].expectedQuantity,1.98,'public exact expected quantity')
near(model.materials[1].chanceCasts,400,'independent studies retain established weight')
for i=1,10 do eq(public(true).yieldModel,model,'warm model reused')end
present=false;public(false);present=true;public(true)
liveContext.effectiveSkill=skill+1;public(false)
liveContext.effectiveSkill=skill;public(true)
LL:SetEvidenceSource('imported',false);public(false)
LL:SetEvidenceSource('imported',true);public(true)
ctx.simulated=true;reset();eq(LL:ConversionOptions(f)[1].value,nil);eq(finds,0);ctx.simulated=nil
public(true)
local index=LL._importedIndex;local before=LL:ImportedResultsCount()
local ok,_,c=import(recycling);eq(ok,false);eq(c.duplicate,200)
eq(LL:ImportedResultsCount(),before);eq(LL._importedIndex,index,'replay keeps index')
LL:ClearImportedResults();eq(LL._importedIndex,nil);eq(LL.db.importedResults,nil)
reset();eq(LL:ConversionOptions(f)[1].value,nil);eq(finds,0)
print('PASS: '..checks..' import target lookup assertions (query-local reuse; fresh later queries)')
