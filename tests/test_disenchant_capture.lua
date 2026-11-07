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
-- Clean logout of a censored batch is not a game-build change.
emit('PLAYER_LOGOUT')
local closedBatch=d.activeStudy
local s={db=LL.db,CharacterKey=LL.CharacterKey}
assert(loadfile('LootLiquidator/CraftRecording.lua'))('LootLiquidator',s)
s:ActiveRecordingBatch()
eq(d.studies[closedBatch].closedReason,'Study has unresolved coverage gaps')
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
print('PASS: '..checks..' disenchant recorder regression assertions')
