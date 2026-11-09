-- Deterministic event replays for owner-reported capture failures, not yield priors.
local checks=0
local function eq(a,b,message) assert(a==b,(message or '')..': '..tostring(a)..' ~= '..tostring(b));checks=checks+1 end
local frames,timers,now={},{},0
CreateFrame=function()
    local f={events={}}
    function f:RegisterEvent(e) self.events[e]=true end
    function f:SetScript(_,fn) self.fn=fn end
    frames[#frames+1]=f;return f
end
local function emit(e,...) for _,f in ipairs(frames) do if f.events[e] then f.fn(f,e,...) end end end
time=function() return 1000+math.floor(now) end;GetTime=function() return now end
GetBuildInfo=function() return 'test','70783','',120105 end
C_Timer={After=function(delay,fn) timers[#timers+1]={at=now+delay,fn=fn} end}
local function advance(seconds)
    local finish=now+seconds
    while true do
        local index,best
        for i,t in ipairs(timers) do if t.at<=finish and (not best or t.at<best.at) then index,best=i,t end end
        if not best then break end
        table.remove(timers,index);now=best.at;best.fn()
    end
    now=finish
end
local LL={db={characters={},recordDisenchants=true},CharacterKey=function() return 'Tester - Realm' end}
assert(loadfile('LootLiquidator/Professions.lua'))('LootLiquidator',LL)
LL.CharacterKey=function() return 'Tester - Realm' end
local realContext=LL.CaptureCraftContext
LL.CaptureCraftContext=function(self,recipe,f,method)
    return {character=self:CharacterKey(),recipeID=recipe,method=method,profileKind='measured',simulated=false,
        inputExpansionID=f and f.expansionID,fieldStatus={}}
end
-- A valuation veto must never erase a successful observed disenchant.
LL.EligibleDisenchant=function() return false,'Old database says no' end
LL.DisenchantTables={[5]={quality={[2]={candidates={109693}}}}}
LL.ItemDB={processing={}}
local gearA,gearB='item:109979:0:0:0:0:0:0:1','item:109979:0:0:0:0:0:0:2'
local facts={
    [gearA]={id=109979,link=gearA,classID=4,quality=3,itemLevel=266,expansionID=5},
    [gearB]={id=109979,link=gearB,classID=4,quality=3,itemLevel=280,expansionID=5},
    ['item:109693']={id=109693,link='item:109693',classID=7,subClassID=12,expansionID=5},
    ['item:236950']={id=236950,link='item:236950',classID=7,expansionID=11},
    ['item:999999']={id=999999,link='item:999999',classID=7,expansionID=11},
}
LL.GetItemFacts=function(_,link) assert(facts[link],link);return facts[link] end
local bags,loot={},{}
C_Container={GetContainerNumSlots=function(bag) return bag==0 and #bags or 0 end,
    GetContainerItemInfo=function(_,slot)
        local v=bags[slot];return v and {itemID=facts[v[1]].id,hyperlink=v[1],stackCount=v[2] or 1}
    end}
GetNumLootItems=function() return #loot end
GetLootSlotLink=function(slot) return loot[slot][1] end
GetLootSlotInfo=function(slot) return 1,'test',loot[slot][2] end
assert(loadfile('LootLiquidator/CraftRecording.lua'))('LootLiquidator',LL)
local function start(guid,before)
    bags=before;loot={};LL:StartNewBatch()
    emit('UNIT_SPELLCAST_SENT','player','',guid,13262)
    emit('UNIT_SPELLCAST_START','player',guid,13262)
    emit('UNIT_SPELLCAST_SUCCEEDED','player',guid,13262)
end
local function finish(after,slots)
    loot=slots or {};emit('LOOT_READY');emit('LOOT_OPENED',true,true)
    bags=after;emit('BAG_UPDATE_DELAYED');emit('LOOT_CLOSED');advance(1.3)
end
local function last() local r=LL.db.craftResearch.records;return r[#r] end
-- Previously rejected Warlords rare -> dust, independent of ItemDB coverage.
start('legacy',{{gearA}});finish({{'item:109693',11}},{{'item:109693',11}})
eq(last().operationID,'legacy');eq(last().outputs[1].quantity,11)
local d=LL.db.craftResearch
eq(d.studies[d.activeStudy].censored,nil);eq(last().captureVersion,2)
-- A new co-output is observed, even if its expansion and identity were unknown
-- to the database. Repeated READY/OPENED cannot multiply the loot.
start('bonus',{{gearA}})
finish({{'item:109693',2},{'item:236950',1}},{{'item:109693',2},{'item:236950',1}})
eq(last().operationID,'bonus');eq(#last().outputs,2);eq(last().outputs[2].quantity,1)
eq(d.studies[d.activeStudy].censored,nil)
eq(LL:CraftBaseline(last().studyID,last().contextID,13262).operations,1,'usable measured cohort')
-- Two different copies of one item ID no longer make its identity unknowable.
start('variant',{{gearA},{gearB}})
finish({{gearA},{'item:109693',2}},{{'item:109693',2}})
eq(last().operationID,'variant');eq(last().inputs[1].hyperlink,gearB)
eq(last().inputs[1].itemLevel,280)
eq(d.contexts[last().contextID].inputIdentity[1].itemLevel,280)
-- Bag sorting does not change per-link identity.
start('sorted',{{gearB},{gearA},{gearB}})
finish({{gearB},{'item:109693',1},{gearA}},{{'item:109693',1}})
eq(last().operationID,'sorted');eq(last().inputs[1].itemLevel,280)
-- When autoloot beats the snapshot, known expansion candidates still work
-- across gear rarities, without inventing unknown bonus mappings.
start('fallback',{{gearA}});bags={{'item:109693',4}};emit('LOOT_CLOSED');advance(1.3)
eq(last().operationID,'fallback');eq(d.studies[d.activeStudy].censored,nil)
local n=#d.records
start('unrelated',{{gearA}})
finish({{'item:109693',2},{'item:999999',1}},{{'item:109693',2}});advance(13)
eq(#d.records,n);eq(d.studies[d.activeStudy].coverageReason,'Loot result/bag delta mismatch')
eq(d.diagnostics[#d.diagnostics].studyID,d.activeStudy)
eq(d.diagnostics[#d.diagnostics].successful,true)
eq(LL:RecordingStatus():find('Needs review',1,true)~=nil,true)
-- Missing outputs are not a complete cast, even when a loot window closed.
start('missing-loot',{{gearA}});finish({},{{'item:109693',2}});advance(13)
eq(#d.records,n);eq(d.studies[d.activeStudy].censored,true)
-- Genuine inventory interactions retain censorship and the reason.
start('trade',{{gearA}});emit('TRADE_SHOW');finish({{'item:109693',2}},{{'item:109693',2}});advance(13)
eq(d.studies[d.activeStudy].coverageReason,'Inventory interaction during capture')
-- A clean logout can resume a recipe-scoped batch without discarding its gaps.
emit('PLAYER_LOGOUT')
local closedBatch=d.activeStudy
local s={db=LL.db,CharacterKey=LL.CharacterKey}
assert(loadfile('LootLiquidator/CraftRecording.lua'))('LootLiquidator',s)
s:ActiveRecordingBatch()
eq(d.studies[closedBatch].closedReason,nil)
eq(d.activeStudy,closedBatch)
eq(d.studies[closedBatch].coverageGaps['Disenchant:13262']~=nil,true)
-- API placeholder 0/0 is unknown, not a measured zero-skill baseline. A real
-- zero out of a positive cap is retained as a legitimate measurement.
LL.ProfessionCatalog={['Enchanting:11']={lineID=2909}}
LL.db.characters[LL:CharacterKey()]={details={[2909]={parentName='Enchanting',name='Midnight Enchanting',skill=40,maxSkill=100}}}
local maximum=0
C_TradeSkillUI={GetProfessionInfoByRecipeID=function() return {professionID=333,skillLevel=300,maxSkillLevel=800} end,
    GetProfessionInfoBySkillLineID=function() return {professionID=2909,skillLevel=0,skillModifier=0,maxSkillLevel=maximum} end}
local c=realContext(LL,13262,{expansionID=11},'Disenchant')
eq(c.effectiveSkill,nil);eq(c.skillLineID,2909);eq(c.fieldStatus.effectiveSkill,'unknown')
eq(LL.db.characters[LL:CharacterKey()].details[2909].skill,40,'placeholder cannot overwrite skill cache')
maximum=100;c=realContext(LL,13262,{expansionID=11},'Disenchant')
eq(c.effectiveSkill,0);eq(c.maxSkill,100);eq(c.fieldStatus.effectiveSkill,'measured')
c=realContext(LL,13262,{expansionID=2},'Disenchant')
eq(c.effectiveSkill,nil);eq(c.skillLineID,nil,'no parent skill substituted for missing expansion')
-- Feed the actual event-captured records to the native popup integration test.
local export=assert(io.open('/tmp/loot-disenchant-capture-v2.json','w'))
export:write(LL:ExportCraftResearch(1));export:close()
-- Replay the owner's 75 output receipts interleaved with the 19 no-input,
-- no-loot signatures as targeting activations. The old export didn't store
-- cursor/start flags, so this reproduces the bug, not recovered historical events.
for _,frame in ipairs(frames)do if frame.events.UNIT_SPELLCAST_SENT then frames={frame};break end end
local input=assert(io.open('research/integration/measured-captures/2026-11-07-disenchant-75-casts/export-page-1.json','r'))
local decoder={};assert(loadfile('LootLiquidator/ImportedResults.lua'))('LL',decoder)
local original=assert(decoder.DecodeImportJSON(input:read('*a')));input:close()
local replay,inventory={},{}
local sid='Voodoobrew - Grizzly Hills:70783:1794071551:12'
for _,r in ipairs(original.records)do if r.studyID==sid then
    replay[#replay+1]={kind='cast',data=r};inventory[#inventory+1]={r.inputs[1].hyperlink}
    local i=r.inputs[1];facts[i.hyperlink]={id=i.itemID,link=i.hyperlink,classID=i.classID,quality=i.rarity,itemLevel=i.itemLevel,expansionID=i.expansionID}
    for _,m in ipairs(r.outputs)do facts[m.hyperlink]={id=m.itemID,link=m.hyperlink,classID=7,quality=m.rarity,reagentQuality=m.qualityRank,expansionID=11}end
end end
for _,g in ipairs(original.diagnostics)do if g.studyID==sid and g.method=='Disenchant'then replay[#replay+1]={kind='cursor',data=g}end end
table.sort(replay,function(a,b)return a.data.startedAt<b.data.startedAt end)
local targeting=false;SpellIsTargeting=function()return targeting end
LL.CaptureCraftContext=function(self,recipe,_,method)return {character=self:CharacterKey(),recipeID=recipe,method=method,
    profileKind='measured',simulated=false,baseSkill=64,bonusSkill=0,effectiveSkill=64,specialization='none'}end
bags=inventory;loot={};LL:StartNewBatch()
local batch=d.activeStudy;local before=#d.records;local cursorBefore=d.targetingActivations or 0
local produced={}
for _,event in ipairs(replay)do
    local r=event.data;targeting=event.kind=='cursor'
    emit('UNIT_SPELLCAST_SENT','player','',r.operationID,13262)
    if event.kind=='cursor'then
        emit('UNIT_SPELLCAST_SUCCEEDED','player',r.operationID,13262)
    else
        emit('UNIT_SPELLCAST_START','player',r.operationID,13262);advance(1.7)
        local nextBag={};local removed=false
        for _,entry in ipairs(bags)do
            if not removed and entry[1]==r.inputs[1].hyperlink then removed=true else nextBag[#nextBag+1]=entry end
        end
        assert(removed)
        loot={}
        for _,m in ipairs(r.outputs)do
            nextBag[#nextBag+1]={m.hyperlink,m.quantity};loot[#loot+1]={m.hyperlink,m.quantity}
            produced[m.itemID]=(produced[m.itemID] or 0)+m.quantity
        end
        bags=nextBag;emit('UNIT_SPELLCAST_SUCCEEDED','player',r.operationID,13262)
        emit('LOOT_READY');emit('LOOT_CLOSED');emit('BAG_UPDATE_DELAYED');advance(1.3)
    end
end
eq(#d.records-before,75);eq(d.targetingActivations-cursorBefore,19)
eq(produced[243602],70);eq(produced[243603],5);eq(d.studies[batch].censored,nil)
eq(last().castStartSeen,true);eq(last().recorderRevision,6)
-- Opening the next cursor while real loot is unsettled must not force-finalize it.
LL:StartNewBatch();bags={{gearA}};loot={};targeting=false
emit('UNIT_SPELLCAST_START','player','delayed-real',13262)
emit('UNIT_SPELLCAST_SUCCEEDED','player','delayed-real',13262)
targeting=true;emit('UNIT_SPELLCAST_SENT','player','','next-cursor',13262)
emit('UNIT_SPELLCAST_SUCCEEDED','player','next-cursor',13262)
finish({{'item:109693',2}},{{'item:109693',2}})
eq(last().operationID,'delayed-real');eq(d.studies[d.activeStudy].censored,nil)
-- The targeting flag cannot suppress a genuine START plus reconciled result.
LL:StartNewBatch();bags={{gearA}};loot={}
emit('UNIT_SPELLCAST_START','player','real-with-cursor',13262)
emit('UNIT_SPELLCAST_SUCCEEDED','player','real-with-cursor',13262)
finish({{'item:109693',1}},{{'item:109693',1}})
eq(last().operationID,'real-with-cursor')
batch=d.activeStudy
-- Unknown/missed-start successes still create gaps; no generic suppression.
targeting=false;emit('UNIT_SPELLCAST_SENT','player','','unknown-start',13262)
emit('UNIT_SPELLCAST_SUCCEEDED','player','unknown-start',13262)
eq(d.studies[batch].coverageGaps['Disenchant:13262']~=nil,true)
-- A blocked pre-fix batch is retained, and collection automatically uses a fresh one.
d.studies[batch].recorderRevision=4
bags={{gearA}};emit('UNIT_SPELLCAST_START','player','after-upgrade',13262)
eq(d.activeStudy~=batch,true);eq(d.studies[batch].censored,true)
emit('UNIT_SPELLCAST_INTERRUPTED','player','after-upgrade',13262)
-- Replay the new PR49 check after an unresolved ordinary craft. Unrecognized
-- player spells must not prematurely finalize that capture or create a global
-- gap, and they must not discard a real Disenchant START awaiting its success.
local checkFile=assert(io.open('research/integration/measured-captures/2026-11-07-pr49-20-cast-check/export-page-1.json'))
local latest=assert(decoder.DecodeImportJSON(checkFile:read('*a')));checkFile:close()
C_TradeSkillUI={GetRecipeInfo=function(id)if id==1229863 then return {learned=true}end end,
    GetRecipeSchematic=function(id)if id==1229863 then return {recipeID=id,reagentSlotSchematics={
        {dataSlotIndex=1,required=true,quantityRequired=1,reagents={{itemID=243581},{itemID=243582}}}}}end end}
LL:StartNewBatch();batch=d.activeStudy;bags={{gearA}};loot={}
emit('UNIT_SPELLCAST_START','player','scope-craft',1229863)
emit('UNIT_SPELLCAST_SUCCEEDED','player','scope-craft',1229863)
local diagnosticsBefore=#(d.diagnostics or {})
emit('UNIT_SPELLCAST_SENT','player','','unrecognized-spell',999998)
emit('UNIT_SPELLCAST_START','player','unrecognized-spell',999998)
eq(#(d.diagnostics or {}),diagnosticsBefore,'unrecognized spell cannot finalize a pending profession capture')
eq(d.studies[batch].globalCoverageGap,nil,'unrecognized spell cannot create a study-wide overlap gap')
advance(13.1)
eq(d.studies[batch].coverageGaps['Craft:1229863']~=nil,true,'actual craft failure stays scoped')
local remaining,totals={},{}
for _,r in ipairs(latest.records)do
    local i=r.inputs[1];remaining[#remaining+1]=i.hyperlink
    facts[i.hyperlink]={id=i.itemID,link=i.hyperlink,classID=i.classID,quality=i.rarity,itemLevel=i.itemLevel,expansionID=i.expansionID}
    for _,m in ipairs(r.outputs)do facts[m.hyperlink]={id=m.itemID,link=m.hyperlink,classID=m.classID,
        quality=m.rarity,reagentQuality=m.qualityRank,itemLevel=m.itemLevel,expansionID=m.expansionID}end
end
local function replayBag()
    local result={}
    for _,link in ipairs(remaining)do result[#result+1]={link}end
    for link,n in pairs(totals)do result[#result+1]={link,n}end
    return result
end
local accepted=#d.records;local materialTotals={};local contextRefs={}
for _,r in ipairs(latest.records)do
    bags=replayBag();loot={}
    emit('UNIT_SPELLCAST_START','player',r.operationID,13262)
    emit('UNIT_SPELLCAST_SENT','player','','unrecognized-during-real-start',999998)
    emit('UNIT_SPELLCAST_START','player','unrecognized-during-real-start',999998)
    for i,link in ipairs(remaining)do if link==r.inputs[1].hyperlink then table.remove(remaining,i);break end end
    for _,m in ipairs(r.outputs)do
        totals[m.hyperlink]=(totals[m.hyperlink] or 0)+m.quantity
        loot[#loot+1]={m.hyperlink,m.quantity}
        materialTotals[m.itemID]=(materialTotals[m.itemID] or 0)+m.quantity
    end
    emit('UNIT_SPELLCAST_SUCCEEDED','player',r.operationID,13262)
    finish(replayBag(),loot);contextRefs[last().contextID]=true
end
eq(#d.records-accepted,20);eq(materialTotals[243602],19);eq(materialTotals[243603],1)
eq(d.activeStudy,batch);eq(d.studies[batch].globalCoverageGap,nil)
eq(d.studies[batch].coverageGaps['Disenchant:13262'],nil,'Craft gap cannot censor subsequent complete disenchants')
local usable=0
for id in pairs(contextRefs)do usable=usable+assert(LL:CraftBaseline(batch,id,13262)).operations end
eq(usable,20,'all 20 actual receipts reach recipe-scoped baselines in replay')
-- Genuine overlaps between two known tracked casts still block their recipe.
bags={{gearA},{gearA}};loot={}
emit('UNIT_SPELLCAST_START','player','known-overlap-first',13262)
emit('UNIT_SPELLCAST_SUCCEEDED','player','known-overlap-first',13262)
emit('UNIT_SPELLCAST_START','player','known-overlap-second',13262)
eq(d.studies[batch].coverageGaps['Disenchant:13262']~=nil,true,'real known-cast overlap remains blocked')
-- Any tracked profession, not just Disenchant, leaves a blocked older revision
-- in place and opens a clean collection batch after upgrading.
d.studies[batch].recorderRevision=4
emit('UNIT_SPELLCAST_START','player','craft-after-scope-upgrade',1229863)
eq(d.activeStudy~=batch,true);eq(d.studies[batch].censored,true)
eq(d.studies[d.activeStudy].recorderRevision,6)
emit('UNIT_SPELLCAST_INTERRUPTED','player','craft-after-scope-upgrade',1229863)
print('PASS: 75 original and 20 PR49 receipts, cursor/unrecognized spell isolation, real overlaps and upgrade rollover')
print('PASS: '..checks..' disenchant recorder regression assertions')
