-- Replay real captures: rejected coverage must not trigger live profession
-- scans, while a usable cohort must still recheck the character's live profile.
local LL={}
CreateFrame=function()return {RegisterEvent=function()end,SetScript=function()end}end
GetTime=function()return 1 end;time=function()return 2000 end
GetBuildInfo=function()return 'test','70783' end
LL.CharacterKey=function()return 'Voodoobrew - Grizzly Hills' end
for _,name in ipairs({'CraftRecording.lua','ImportedResults.lua'})do
    assert(loadfile('LootLiquidator/'..name))('LL',LL)
end
local function clone(t)
    if type(t)~='table' then return t end
    local out={} for k,v in pairs(t)do out[k]=clone(v)end;return out
end
local function loadCapture(folder)
    local file=assert(io.open('research/integration/measured-captures/'..folder..'/export-page-1.json'))
    local data=assert(LL.DecodeImportJSON(file:read('*a')));file:close()
    data.sequence=0
    LL.db={craftResearch=data,recordDisenchants=true,recordConversions=true}
    return data
end
local d=loadCapture('2026-11-07-pr48-reported-1250ms')
local f={id=244752,expansionID=11,quality=3,classID=4,itemLevel=165,link=d.records[#d.records].inputs[1].hyperlink}
local reads=0
LL.CaptureCraftContext=function()reads=reads+1;error('Coverage-blocked batch queried profession APIs')end
LL.ProjectPersonalEstimate=function()error('Coverage-blocked batch reached projection')end
for i=1,20 do assert(not LL:GetLearnedDisenchantEstimate(f))end
assert(reads==0,'bag valuations of blocked batches do no live profession scans')

d=loadCapture('2026-11-07-pr48-reported-3000ms')
local original=d.records[#d.records]
local measured=clone(d.contexts[original.contextID]);measured.inputIdentity=nil
LL.CaptureCraftContext=function()reads=reads+1;return clone(measured)end
LL.ProjectPersonalEstimate=nil
local baseline=assert(LL:GetLearnedDisenchantEstimate(f))
assert(baseline.operations==31,'all 31 casts in the clean batch remain usable')
local quantities={}
for _,m in ipairs(baseline.materials)do quantities[m.id]=m.expectedQuantity end
assert(math.abs(quantities[243602]-30/31)<1e-12 and math.abs(quantities[243603]-1/31)<1e-12,
    'R1/R2 means remain identical to the actual receipts')
local oldReads=reads
measured.baseSkill=65;measured.effectiveSkill=65
assert(not LL:GetLearnedDisenchantEstimate(f),'changed live skill cannot borrow the old cohort')
assert(reads>oldReads,'a usable cohort always checks the live profile')

d=loadCapture('2026-11-07-pr48-reported-3000ms-after-reload')
original=d.records[#d.records]
measured=clone(d.contexts[original.contextID]);measured.inputIdentity=nil
baseline=assert(LL:GetLearnedDisenchantEstimate(f))
assert(baseline.operations==92,'both clean batches combine without counting re-exported casts twice')
quantities={}
for _,m in ipairs(baseline.materials)do quantities[m.id]=m.expectedQuantity end
assert(math.abs(quantities[243602]-88/92)<1e-12 and math.abs(quantities[243603]-4/92)<1e-12,
    'all 61 post-reload receipts remain in the combined exact-context estimate')

local function contextCount()local n=0 for _ in pairs(d.contexts)do n=n+1 end;return n end
local initialCount=contextCount()
local function append(id,skill)
    local r=clone(original);r.context=clone(d.contexts[original.contextID]);r.operationID=id
    r.context.observed=3000
    if skill then r.context.baseSkill=skill;r.context.effectiveSkill=skill end
    local ok,stored=LL:RecordCraftObservation(r);assert(ok,stored);return stored,r
end
local stored,r=append('lookup-test:1')
assert(stored.contextID==original.contextID and contextCount()==initialCount,'existing profiles keep their original IDs')
r.context.baseSkill=999
assert(d.contexts[stored.contextID].baseSkill==64,'indexed contexts remain isolated snapshots')
assert(append('lookup-test:2').contextID==original.contextID,'repeated casts reuse the same measured context')
local changed=append('lookup-test:3',65)
assert(changed.contextID~=original.contextID and contextCount()==initialCount+1,'changed skills receive a distinct context')
assert(append('lookup-test:4',65).contextID==changed.contextID,'a newly measured profile can be reused')
local beforeExport=LL:ExportCraftResearch()
assert(not LL:RecordCraftObservation(r),'duplicate operations remain rejected')
assert(LL:ExportCraftResearch()==beforeExport,'rejected duplicates leave exported evidence unchanged')

assert(LL:ResetRecordedResults())
stored=append('lookup-test:after-reset')
assert(stored.contextID=='context:1','a reset creates a fresh context index')
assert(#LL.db.craftResearch.records==1 and #LL.db.recordedResultsBackup.craftResearch.records==579,
    'reset preserves the full prior ledger and does not reuse its index')
print('PASS: actual 483/514/575-cast lookup replay, no blocked live scans, fresh skills and stable context identities')
