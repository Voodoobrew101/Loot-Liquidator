-- Synthetic identities test recorder storage, not game loot distributions.
local checks=0
local function check(value,message) assert(value,message);checks=checks+1 end
local function clone(value)
    if type(value)~='table' then return value end
    local out={} for key,child in pairs(value) do out[key]=clone(child) end return out
end
local function same(a,b)
    if type(a)~=type(b) then return false end
    if type(a)~='table' then return a==b end
    for key,value in pairs(a) do if not same(value,b[key]) then return false end end
    for key in pairs(b) do if a[key]==nil then return false end end
    return true
end
GetBuildInfo=function()return '12.1.5','70961','',120105 end
GetTime=function()return 100 end;time=function()return 1000 end
CreateFrame=function()return {RegisterEvent=function()end,SetScript=function()end}end
local function context(seed)
    return {character='Tester',method='Disenchant',recipeID=13262,profession='Enchanting',
        profileKind='measured',simulated=false,baseSkill=64,bonusSkill=40,effectiveSkill=104,
        maxSkill=100,skillLineID=2906,specialization='none',specializationKnown=true,
        fixtureIdentity=seed,fieldStatus={effectiveSkill='measured',specialization='measured'},
        inputIdentity={{itemID=100000+seed,rarity=3,quantity=1,itemLevel=165,hyperlink='item:'..(100000+seed)}}}
end
local function observation(seed,id)
    return {operationID=id or 'new:'..seed,character='Tester',build='70961',method='Disenchant',recipeID=13262,
        captureVersion=2,castStartSeen=true,successful=true,outputCoverage='complete',
        attribution='cast-loot-bag',startedAt=98,endedAt=100,context=context(seed),
        inputs={{itemID=100000+seed,rarity=3,quantity=1,itemLevel=165,hyperlink='item:'..(100000+seed),classID=4,expansionID=11}},
        outputs={{itemID=243602,quantity=1}},lootSlots={{itemID=243602,quantity=1}},resultMetadata={}}
end
local function fresh(d)
    local LL={db={recordDisenchants=true,recordConversions=true,craftResearch=d}}
    LL.CharacterKey=function()return 'Tester'end
    assert(loadfile('LootLiquidator/CraftRecording.lua'))('LL',LL)
    LL:ActiveRecordingBatch()
    return LL,LL.db.craftResearch
end
local function fixture(n)
    local d={records={},contexts={},studies={study={character='Tester',build='70961',paused=true,
        coverageVersion=2,coverageGaps={},truncated=false}},activeStudy='study',sequence=1,droppedRecords=0}
    for i=1,n do
        d.contexts['context:'..i]=context(i)
        local r=observation(i,'old:'..i);r.context=nil;r.contextID='context:'..i;r.studyID='study'
        d.records[#d.records+1]=r
    end
    return d
end
local function count(t)local n=0 for _ in pairs(t)do n=n+1 end return n end
local function save(LL,seed,id)
    local ok,r=LL:RecordCraftObservation(observation(seed,id));check(ok,r);return r
end

-- All referenced snapshots remain unchanged; genuinely new evidence fails cleanly.
local LL,d=fresh(fixture(256))
local before=LL:ExportCraftResearch('all')
local ok,reason=LL:RecordCraftObservation(observation(999))
check(not ok and reason:find('all 256',1,true),'referenced contexts cannot be reclaimed')
check(not reason:find('export research before continuing',1,true),'failure does not promise export frees capacity')
check(LL:ExportCraftResearch('all')==before,'full-cap rejection preserves exported evidence')
check(save(LL,1).contextID=='context:1','existing identity still records at the cap')

-- One capacity sweep releases the whole unreachable set, without changing live IDs.
LL,d=fresh(fixture(256));for _=1,55 do table.remove(d.records,1) end
local protected=clone(d.records)
check(save(LL,999).contextID=='context:257','capacity sweep starts with a fresh ID')
check(count(d.contexts)==202,'all55 unreachable entries reclaimed in the same sweep')
for i=1,55 do check(d.contexts['context:'..i]==nil,'unused context removed by initial sweep') end
for i=1,54 do save(LL,999+i,'sweep-followup:'..i) end
check(count(d.contexts)==256,'55 new profiles use the freed capacity without exceeding256')
for i,r in ipairs(protected)do check(same(d.records[i],r),'sweep preserves every retained cast') end

-- An unreferenced slot is capacity, never a reusable identity from an old export.
LL,d=fresh(fixture(256));table.remove(d.records,1)
local oldRecords,oldContexts=clone(d.records),clone(d.contexts)
local added=save(LL,999)
check(added.contextID=='context:257' and d.contextSequence==257,'fresh ID seeded above all existing IDs')
check(count(d.contexts)==256 and d.contexts['context:1']==nil,'only unreachable entry reclaimed')
for i,r in ipairs(oldRecords)do check(same(d.records[i],r),'retained cast remains identical') end
for id,c in pairs(oldContexts)do if id~='context:1' then check(same(d.contexts[id],c),'referenced context remains identical') end end
check(save(LL,999,'same-new-profile').contextID=='context:257','new identity hits the existing cache')
local snapshot=LL:ExportCraftResearch('all')
check(not LL:RecordCraftObservation(observation(999,'same-new-profile')),'duplicate operation still rejected')
check(snapshot==LL:ExportCraftResearch('all'),'duplicate does not alter stored/exported evidence')
-- Stale signature for the reclaimed identity must not point at a different context.
ok,reason=LL:RecordCraftObservation(observation(1,'return-old-profile'))
check(not ok and reason:find('all 256',1,true),'reclaimed identity cache entry is removed')

-- Every current ledger reference, including future auxiliary nested keys, protects a context.
LL,d=fresh(fixture(256));table.remove(d.records,1);table.remove(d.records,1)
d.auxiliary={nested={contextID='context:1'}};d.auxiliary.cycle=d.auxiliary
added=save(LL,999)
check(d.contexts['context:1']~=nil and d.contexts['context:2']==nil,'nested/cyclic auxiliary reference protected')
LL,d=fresh(fixture(256));table.remove(d.records,1);table.remove(d.records,1)
d.diagnostics={{metadata={['context:1']=true}}}
save(LL,999)
check(d.contexts['context:1']~=nil and d.contexts['context:2']==nil,'context reference in diagnostic key protected')
LL,d=fresh(fixture(256));table.remove(d.records,3);table.remove(d.records,2)
d.contexts['context:1'].linkedContext='context:2';d.contexts['context:2'].linkedContext='context:1'
save(LL,999)
check(d.contexts['context:1']~=nil and d.contexts['context:2']~=nil,'transitive context references and cycles remain protected')
check(d.contexts['context:3']==nil and count(d.contexts)==256,'transitive traversal does not root unrelated orphan contexts')

-- Sparse IDs and a persisted high-water mark cannot overwrite prior identities.
local sparse=fixture(2);sparse.contexts['context:9000']=sparse.contexts['context:2'];sparse.contexts['context:2']=nil
sparse.records[2].contextID='context:9000'
LL,d=fresh(sparse);check(save(LL,999).contextID=='context:9001','sparse highest ID seeds allocator')
LL,d=fresh(d);check(save(LL,998).contextID=='context:9002','reload preserves high-water progression')
d.contextSequence=12000;LL,d=fresh(d)
check(save(LL,997).contextID=='context:12001','persisted high-water wins over live table maximum')
local exhausted=fixture(1);exhausted.contextSequence=9007199254740991
LL,d=fresh(exhausted);before=LL:ExportCraftResearch('all')
ok,reason=LL:RecordCraftObservation(observation(999))
check(not ok and reason:find('IDs are exhausted',1,true),'nonincrementable high-water fails without a collision')
check(before==LL:ExportCraftResearch('all'),'ID exhaustion preserves existing evidence')

-- Duplicate signatures survive reclaim even if the cache selected the orphan copy.
local duplicate=fixture(256);duplicate.contexts['context:256']=clone(duplicate.contexts['context:1'])
table.remove(duplicate.records,256)
LL,d=fresh(duplicate);save(LL,999)
check(save(LL,1,'duplicate-survivor').contextID=='context:1','surviving duplicate identity remains reusable')
check(count(d.contexts)==256,'duplicate maintenance stays bounded')

-- Index scope follows the contexts table; a reset/replaced ledger cannot inherit stale IDs.
local replacement=fixture(1);LL.db.craftResearch=replacement;LL:ActiveRecordingBatch()
check(save(LL,1,'replacement-existing').contextID=='context:1','replacement ledger gets its own index')
check(save(LL,2,'replacement-new').contextID=='context:2','replacement IDs cannot inherit prior high-water cache')

-- An immediate follow-up from invalidation sees the already-committed context index.
LL,d=fresh(fixture(256));for _=1,2 do table.remove(d.records,1) end
local nested
LL.Invalidate=function(self)
    if not nested then nested=true;nested=save(self,998,'nested-capture') end
end
added=save(LL,999,'outer-capture')
check(added.contextID=='context:257' and nested.contextID=='context:258','reentrant follow-up cannot overwrite either identity')
check(d.contextSequence==258 and count(d.contexts)==256,'reentrant cache and high-water remain consistent')

-- A new-study callback runs before allocation: its nested cast may safely use
-- the sole free slot, while the outer distinct profile then fails at capacity.
LL,d=fresh(fixture(256));table.remove(d.records,1);d.activeStudy=nil
local nestedNewStudy
LL.Invalidate=function(self)
    if not nestedNewStudy then nestedNewStudy=true;nestedNewStudy=save(self,998,'nested-new-study') end
end
ok,reason=LL:RecordCraftObservation(observation(999,'outer-new-study'))
check(not ok and reason:find('all 256',1,true),'outer capture fails cleanly if nested study callback uses the last slot')
check(nestedNewStudy.contextID=='context:257' and d.contexts[nestedNewStudy.contextID]~=nil,'nested accepted capture has a live immutable context')
for _,r in ipairs(d.records)do check(d.contexts[r.contextID]~=nil,'every accepted context resolves after new-study reentrancy') end

-- The same operation may arrive from the study-start callback only once.
LL,d=fresh(fixture(1));d.activeStudy=nil
local nestedDuplicate
LL.Invalidate=function(self)
    if not nestedDuplicate then nestedDuplicate=true;nestedDuplicate=save(self,999,'shared-operation') end
end
ok,reason=LL:RecordCraftObservation(observation(999,'shared-operation'))
check(not ok and reason=='Duplicate operation','operation identity is rechecked after study-start callback')
check(#d.records==2 and count(d.contexts)==2,'duplicate callback cannot allocate a second context or save twice')

-- The real pending-cast guard rejects starting another study before allocating.
LL,d=fresh(fixture(1))
LL.SnapshotCraftBags=function()return {counts={},facts={},variants={}}end
LL.CaptureCraftContext=function()return context(1)end
check(LL:BeginCraftCapture('pending-study-guard',13262),'fixture starts a real pending capture')
d.activeStudy=nil
local pendingContexts=count(d.contexts)
ok,reason=LL:RecordCraftObservation(observation(999,'pending-no-study'))
check(not ok and reason:find('pending cast',1,true),'pending study-start rejection is honored')
check(count(d.contexts)==pendingContexts and #d.records==1,'failed study start saves neither context nor malformed record')

-- Genuine older/newer exports import independently after storage reclamation.
LL,d=fresh(fixture(0));local original=save(LL,1,'export-original')
local originalExport=LL:ExportCraftResearch('all')
d.records={}
for i=2,256 do
    d.contexts['context:'..i]=context(i)
    local r=observation(i,'reference:'..i);r.context=nil;r.contextID='context:'..i;r.studyID=d.activeStudy
    d.records[#d.records+1]=r
end
-- Replace the context table to reflect a reloaded fixture with all 256 slots.
d.contexts=clone(d.contexts)
local later=save(LL,999,'export-later')
local envelope={db={craftResearch={records={later},contexts={[later.contextID]=d.contexts[later.contextID]},
    studies=d.studies,droppedRecords=0}}}
local laterExport=LL.ExportCraftResearch(envelope,'all')
check(later.contextID~='context:1','new export never changes old context identity')
local receiver={db={characters={},recordDisenchants=true,recordConversions=true}}
for _,name in ipairs({'ItemDBRuntime.lua','Database.lua','Professions.lua','Observations.lua','ImportedResults.lua','ConversionEngine.lua'})do
    assert(loadfile('LootLiquidator/'..name))('LL',receiver)
end
receiver.CharacterKey=function()return 'Receiver'end
receiver.ItemDB={schemaVersion=1,version='capacity-fixture',inputs={},processing={},mechanicRules={}}
check(receiver:InitializeItemDB());receiver:MigrateEvidenceSettings()
local imported,message=receiver:ImportRecordedResults(originalExport);check(imported,message)
imported,message=receiver:ImportRecordedResults(laterExport);check(imported,message)
local archiveCount=0
for _,set in pairs(receiver.db.importedResults.sets)do
    if set.disenchantArchive then
        archiveCount=archiveCount+1
        check(not set.disenchantArchive.conflictingMetadata,'old/new export contexts do not poison import history')
    end
end
check(archiveCount==2,'both source exports remain independently retained')
print(('RECORDER CONTEXT CAPACITY: %d checks passed'):format(checks))
