-- An unrelated saved cast cannot contribute to this recipe lookup and must
-- not allocate a study/context key. Matching cohorts retain their old dedupe.
local checks=0
local function check(value,label)checks=checks+1;assert(value,label)end
local function clone(v)if type(v)~='table'then return v end local r={}for k,x in pairs(v)do r[k]=clone(x)end return r end
GetBuildInfo=function()return 'test','70961','',120105 end
GetTime=function()return 100 end;time=function()return 1000 end
CreateFrame=function()return{RegisterEvent=function()end,SetScript=function()end}end
local LL={db={},CharacterKey=function()return 'Actual-Realm'end}
assert(loadfile('LootLiquidator/CraftRecording.lua'))('LL',LL)
local function context(recipe)
    return{character='Actual-Realm',recipeID=recipe,method='Craft',profession='Alchemy',profileKind='measured',
        simulated=false,baseSkill=75,bonusSkill=5,effectiveSkill=80,specialization='none',skillLineID=2900,
        observed=1000,equipment={},buffs={},buffStacks={},specializationPoints={},fieldStatus={equipment='measured'}}
end
LL:StartCraftStudy('Independent recorded operations')
local function record(id,recipe,input,output)
    local ok,reason=LL:RecordCraftObservation({operationID=id,recipeID=recipe,method='Craft',successful=true,
        character='Actual-Realm',build='70961',context=context(recipe),
        inputs={{itemID=input,quantity=1,rarity=1,classID=7}},
        outputs={{itemID=500,quantity=output}},outputCoverage='complete'})
    check(ok,reason)
end
for i=1,80 do record('unrelated-'..i,901,200,3)end
local ledger=LL.db.craftResearch
local study=ledger.records[1].studyID
local facts={id=100,quality=1,classID=7,expansionID=11,link='item:100'}
local captures=0
LL.CaptureCraftContext=function()
    captures=captures+1
    for _,r in ipairs(ledger.records)do if r.recipeID==900 then return clone(ledger.contexts[r.contextID])end end
end
local function query()
    local count,original=0,tostring
    tostring=function(value)if value==study then count=count+1 end return original(value)end
    local ok,result=pcall(LL.GetRecordedProcessingEstimate,LL,facts,'Craft',1,900)
    tostring=original
    check(ok,result)
    return result,count
end
local before=LL:ExportCraftResearch('all')
local missing,keys=query()
check(missing==nil and captures==0,'unrelated history does not fabricate observations or query a live context')
check(keys==0,'unrelated recipe history does not construct cohort keys')
check(LL:ExportCraftResearch('all')==before,'negative lookup leaves the full captured export unchanged')
record('target-1',900,100,2);record('target-2',900,100,2)
local baselineCalls=0
local realBaseline=LL.CraftBaseline
LL.CraftBaseline=function(self,...)baselineCalls=baselineCalls+1;return realBaseline(self,...)end
before=LL:ExportCraftResearch('all')
local found,count=query()
check(found and found.operations==2 and found.effectiveSamples==2,'matching complete casts remain counted exactly once')
check(found.materials[1].expectedQuantity==2 and found.materials[1].chance==1,
    'actual material units and occurrence remain unchanged')
check(found.materials[1].minQuantity==2 and found.materials[1].maxQuantity==2,
    'matching measured positive range remains intact')
check(count==1,'the first matching cohort returns without constructing unrelated history keys')
check(baselineCalls==1 and captures==1,'duplicate study/context rows retain one baseline and target-context query')
check(#found.sourceRecordIDs==2,'both original operation identities remain in the returned baseline')
check(LL:ExportCraftResearch('all')==before,'successful lookup leaves all raw records and contexts unchanged')
check(#ledger.records==82,'queries never add or discard recorded casts')
print('RECORDED PROCESSING QUERY GATES: '..checks..' checks passed')
