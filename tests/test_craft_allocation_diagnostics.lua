-- Isolated event/timer fixture. Values are deterministic tests, not WoW yields.
local checks=0
local function check(v,msg) assert(v,msg);checks=checks+1 end
local function eq(a,b,msg) check(a==b,(msg or '')..' '..tostring(a)..' ~= '..tostring(b)) end
local function clone(t) if type(t)~='table' then return t end local n={} for k,v in pairs(t) do n[k]=clone(v) end return n end
local now,frames,timers=0,{},{ }
local hooks,craftCalls={},0
C_TradeSkillUI={CraftRecipe=function() craftCalls=craftCalls+1 end}
hooksecurefunc=function(_,method,callback) hooks[method]=callback end
GetTime=function() return now end;time=function() return 1000+math.floor(now) end
GetBuildInfo=function() return 'test','123456','',120105 end
UnitName=function() return 'Tester' end;GetRealmName=function() return 'Realm' end
CreateFrame=function()
 local f={events={}};function f:RegisterEvent(e) self.events[e]=true end
 function f:SetScript(_,fn) self.fn=fn end;frames[#frames+1]=f;return f
end
C_Timer={After=function(delay,fn) timers[#timers+1]={at=now+delay,fn=fn} end}
local function emit(event,...) for _,frame in ipairs(frames) do if frame.events[event] then frame.fn(frame,event,...) end end end
local function advance(seconds)
 local finish=now+seconds
 while true do
  local index,best
  for i,t in ipairs(timers) do if t.at<=finish and (not best or t.at<best.at) then index,best=i,t end end
  if not best then break end
  table.remove(timers,index);now=best.at;best.fn()
 end;now=finish
end
local LL={db={characters={},recordConversions=true,recordDisenchants=true,minPersonalSamples=1}}
for _,name in ipairs({'ItemDBRuntime.lua','Database.lua','Professions.lua','Observations.lua','CraftRecording.lua','ConversionEngine.lua'}) do assert(loadfile('LootLiquidator/'..name))('LootLiquidator',LL) end
local captureMeasured=LL.CaptureCraftContext
check(hooks.CraftRecipe~=nil,'read-only crafting hook registered')
LL.Invalidate=function(self) self._processingModelCache=nil;self._processingContextCache=nil end
LL.CaptureCraftContext=function(self,recipe,f,method)
 return {character=self:CharacterKey(),recipeID=recipe,method=method,profileKind='measured',simulated=false,
  profession='Jewelcrafting',skillLineID=1234,baseSkill=70,bonusSkill=5,effectiveSkill=75,specialization='none',
  observed=time(),equipment={},inputExpansionID=f and f.expansionID,
  fieldStatus={equipment='measured',specialization='measured',effectiveSkill='measured'}}
end
local facts={[10]={id=10,link='item:10',quality=1,reagentQuality=2,classID=7,subClassID=7,expansionID=11},
 [11]={id=11,link='item:11',quality=1},[20]={id=20,link='item:20',quality=2,reagentQuality=1}}
local function bag(counts) local variants={} for id in pairs(counts) do variants[id]={['item:'..id]=true} end return {counts=counts,facts=clone(facts),variants=variants} end
local bags=bag({[10]=10})
LL.SnapshotCraftBags=function() return clone(bags) end
LL.ItemDB={schemaVersion=1,version='recording-fixture',inputs={[10]={method='Prospect',batch=5}},processing={
 {recordID='ref',method='Prospect',inputItemID=10,inputCount=5,sourceKey='itemdb',studyID='fixture',source='fixture',materials={
  {id=20,expectedQuantity={value=2,status='measured',confidence=90},dropChance={status='unknown',confidence=0},minQuantity={status='unknown',confidence=0},maxQuantity={status='unknown',confidence=0}}
 }}},mechanicRules={}}
check(LL:InitializeItemDB());LL:MigrateEvidenceSettings()
local function sent(guid,recipe) emit('UNIT_SPELLCAST_SENT','player','',guid,recipe or 1231127);emit('UNIT_SPELLCAST_START','player',guid,recipe or 1231127) end
local function success(guid,recipe) emit('UNIT_SPELLCAST_SUCCEEDED','player',guid,recipe or 1231127) end

-- All recipe, item, quantity and profile values here are synthetic contracts,
-- not a reconstruction of the missing historical request/schematic.
local schematic
C_TradeSkillUI.GetRecipeInfo=function() return {learned=true} end
C_TradeSkillUI.GetRecipeSchematic=function() return schematic end
local function schema()
 return {recipeID=1000,isRecraft=false,reagentSlotSchematics={
  {dataSlotIndex=1,required=true,quantityRequired=2,reagents={{itemID=10},{itemID=11}}}}}
end
local function allocated(n,id,slot)
 return {{dataSlotIndex=slot or 1,reagent={itemID=id or 11},quantity=n}}
end
local serial=0
local function begin(allocation,missing)
 serial=serial+1
 LL:StartCraftStudy('allocation diagnostic '..serial);bags=bag({[11]=2})
 if not missing then hooks.CraftRecipe(1000,1,allocation,nil,0,false) end
 local guid='allocation-'..serial;sent(guid,1000)
 return guid
end
local function finish(guid)
 bags=bag({[20]=1});success(guid,1000)
 emit('TRADE_SKILL_ITEM_CRAFTED_RESULT',{itemID=20,quantity=1,itemGUID=guid..'-output',operationID=serial})
 LL:FinishCraftCapture(true)
 return LL.db.craftResearch.diagnostics and LL.db.craftResearch.diagnostics[#LL.db.craftResearch.diagnostics]
end
local cases={
 {allocated(1),'required-quantity-mismatch'},
 {allocated(2,99),'item-not-in-slot'},
 {allocated(2,11,2),'unallocated-required-slot'},
 {allocated(0),'invalid-allocation-entry'},
 {allocated(-1),'invalid-allocation-entry'},
 {allocated(0/0),'invalid-allocation-entry'},
 {allocated(math.huge),'invalid-allocation-entry'},
 {allocated('private-value'),'invalid-allocation-entry'},
 {{},'unallocated-required-slot'},
}
for _,case in ipairs(cases) do
 schematic=schema();local guid=begin(case[1]);local d=finish(guid)
 eq(d.operationID,guid);eq(d.reason,'Unknown reagent allocation');check(d.successful)
 check(d.craftAllocation,'rejected ordinary cast must retain bounded allocation evidence')
 eq(d.craftAllocation.version,1);eq(d.craftAllocation.failure,case[2])
 eq(d.craftAllocation.requestState,'observed');eq(d.craftAllocation.schematic.state,'table')
 eq(#LL.db.craftResearch.records,0,'rejections stay rejections')
end
-- Distinguish the parser branch which rejects a selected slot absent from the schematic.
schematic=schema();schematic.reagentSlotSchematics[1].required=false
local d=finish(begin(allocated(2,11,2)));eq(d.craftAllocation.failure,'unmatched-allocation-slot')
-- Missing allocation is not an empty observed table. Missing request is distinct.
schematic=schema();d=finish(begin(nil));eq(d.craftAllocation.allocation.state,'missing')
d=finish(begin(nil,true));eq(d.craftAllocation.requestState,'missing-or-expired');eq(d.craftAllocation.allocation.state,'missing')
-- Snapshot source before copy() drops invalid negatives/nonfinite numbers.
schematic=schema();d=finish(begin(allocated(-1)))
eq(d.craftAllocation.allocation.allocationEntries[1].quantityStatus,'negative-or-nonfinite')
schematic=schema();d=finish(begin(allocated(math.huge)))
eq(d.craftAllocation.allocation.allocationEntries[1].quantityStatus,'negative-or-nonfinite')
schematic=schema();d=finish(begin(allocated('do-not-store-me')))
eq(d.craftAllocation.allocation.allocationEntries[1].quantityStatus,'string')
-- Source mutation after observation/start must change neither parser nor diagnostic.
schematic=schema();local a=allocated(1);a[1].privateField='PRIVATE';schematic.privateField='PRIVATE'
local guid=begin(a);a[1].quantity=2;schematic.reagentSlotSchematics[1].quantityRequired=1
schematic.reagentSlotSchematics[1].reagents[1].itemID=99
local immutable=finish(guid);eq(immutable.craftAllocation.failure,'required-quantity-mismatch')
eq(immutable.craftAllocation.allocation.allocationEntries[1].quantity,1)
eq(immutable.craftAllocation.schematic.slots.schematicSlots[1].quantityRequired,2)
eq(immutable.craftAllocation.schematic.slots.schematicSlots[1].reagents.allowedReagents[1].itemID,10)
eq(immutable.craftAllocation.schematic.privateField,nil)
-- Native required boolean and absent required field remain distinguishable.
schematic=schema();schematic.reagentSlotSchematics[1].required=nil
local extra=allocated(1);extra[#extra+1]={dataSlotIndex=2,reagent={itemID=11},quantity=1}
d=finish(begin(extra));eq(d.craftAllocation.failure,'unmatched-allocation-slot')
eq(d.craftAllocation.schematic.slots.schematicSlots[1].requiredStatus,'missing')
-- Successful explicit and single-option default allocations preserve old semantics.
for _,mode in ipairs({'explicit','default'}) do
 schematic=schema();local alloc=allocated(2)
 if mode=='default' then schematic.reagentSlotSchematics[1].reagents={{itemID=11}};alloc=nil end
 local old=#LL.db.craftResearch.records;local id=begin(alloc);finish(id)
 eq(#LL.db.craftResearch.records,old+1);local r=LL.db.craftResearch.records[#LL.db.craftResearch.records]
 eq(r.operationID,id);eq(r.inputs[1].quantity,2);eq(r.craftAllocation,nil)
end
-- Bounded additions do not broaden or narrow the validator, including >16 entries.
schematic=schema();schematic.reagentSlotSchematics[1].quantityRequired=17
local many={};for i=1,17 do many[i]=allocated(1)[1] end
bags=bag({[11]=17});hooks.CraftRecipe(1000,1,many,nil,0,false)
LL:StartCraftStudy('large valid');sent('large-valid',1000);bags=bag({[20]=1});success('large-valid',1000)
emit('TRADE_SKILL_ITEM_CRAFTED_RESULT',{itemID=20,quantity=1,itemGUID='large-output',operationID=10000})
check(LL:FinishCraftCapture(true),'diagnostic limit must not limit valid allocations')
local r=LL.db.craftResearch.records[#LL.db.craftResearch.records];eq(r.inputs[1].quantity,17)
-- Bounds, unknown fields and arbitrary nesting are diagnostic-only. The native
-- validation inputs are intentionally NOT changed to this allowlisted projection.
schematic=schema();local huge={};local slots={}
for i=1,40 do
 huge[i]={dataSlotIndex=i,quantity=2147483648,reagent={itemID=11,private='PRIVATE'},unknown={nested=string.rep('PRIVATE',100)}}
 local allowed={};for j=1,40 do allowed[j]={itemID=11,unknown='PRIVATE'} end
 slots[i]={dataSlotIndex=i,required=true,quantityRequired=2,reagents=allowed,unknown='PRIVATE'}
end
schematic.reagentSlotSchematics=slots;guid=begin(huge)
LL:AbandonCraftCapture('Diagnosis-only controlled abandonment')
d=LL.db.craftResearch.diagnostics[#LL.db.craftResearch.diagnostics]
local bounded=d.craftAllocation;eq(#bounded.allocation.allocationEntries,16);check(bounded.allocation.truncated)
eq(#bounded.schematic.slots.schematicSlots,16);check(bounded.schematic.slots.truncated)
eq(#bounded.schematic.slots.schematicSlots[1].reagents.allowedReagents,8)
check(bounded.schematic.slots.schematicSlots[1].reagents.truncated)
eq(bounded.allocation.allocationEntries[1].quantityStatus,'out-of-range');eq(bounded.failure,nil)
-- Unstructured malformed inputs can be observed without storing their contents.
-- Do not route these through the legacy parser, whose behavior is outside scope.
for _,malformed in ipairs({'PRIVATE',true,12,{{reagent='PRIVATE'}}}) do
 schematic=schema();guid=begin(malformed);LL:AbandonCraftCapture('Controlled malformed-input snapshot')
 d=LL.db.craftResearch.diagnostics[#LL.db.craftResearch.diagnostics]
 eq(d.craftAllocation.allocation.state,type(malformed));eq(d.craftAllocation.failure,nil)
end
-- Malformed schematic collections are type-marked without traversing values.
for _,value in ipairs({'PRIVATE',true,123}) do
 schematic=schema();schematic.reagentSlotSchematics=value;guid=begin(allocated(1))
 LL:AbandonCraftCapture('Controlled malformed-schematic snapshot')
 d=LL.db.craftResearch.diagnostics[#LL.db.craftResearch.diagnostics]
 eq(d.craftAllocation.schematic.slots.state,type(value))
end
-- Secret values are never copied, compared as values, or serialized.
local secretValue={};issecretvalue=function(v) return v==secretValue end
schematic=schema();local secured=allocated(1);secured[1].quantity=secretValue
guid=begin(secured);LL:AbandonCraftCapture('Controlled secret-field snapshot')
d=LL.db.craftResearch.diagnostics[#LL.db.craftResearch.diagnostics]
eq(d.craftAllocation.allocation.allocationEntries[1].quantityStatus,'secret')
issecretvalue=nil
-- Stale transient parser failure must not label a later, different final rejection.
schematic=schema();guid=begin(allocated(1));bags=bag({[20]=1});success(guid,1000)
emit('TRADE_SKILL_ITEM_CRAFTED_RESULT',{itemID=20,quantity=1,itemGUID='stale-output',operationID=20000})
eq(LL:FinishCraftCapture(false),false);LL:AbandonCraftCapture('Inventory interaction during capture')
d=LL.db.craftResearch.diagnostics[#LL.db.craftResearch.diagnostics];eq(d.craftAllocation.failure,nil)
-- No schematic: native description still refuses to begin capture, no new gate.
schematic=nil;hooks.CraftRecipe(1000,1,allocated(2),nil,0,false)
check(not LL:BeginCraftCapture('missing-schematic',1000))
schematic={recipeID=1000,isRecraft=true};check(not LL:BeginCraftCapture('recraft',1000))
schematic=schema();hooks.CraftRecipe(1000,1,allocated(2),nil,123,false)
check(not LL:BeginCraftCapture('customer-order',1000),'customer/order IDs are not persisted')
-- Full/latest snapshot copy depth must preserve the deepest allowed item ID.
local full=LL:SnapshotRecordedResearch(false)
local boundedCopy
for _,row in ipairs(full.diagnostics) do
 if row.craftAllocation and row.craftAllocation.allocation.truncated then boundedCopy=row end
end
check(boundedCopy);eq(boundedCopy.craftAllocation.schematic.slots.schematicSlots[1].reagents.allowedReagents[1].itemID,11)
local export=LL:ExportCraftResearch('all');check(not export:find('PRIVATE',1,true));check(not export:find('do-not-store-me',1,true))
local f=assert(io.open('/tmp/loot-craft-allocation-diagnostics.json','w'));f:write(export);f:close()
-- The 50-diagnostic cap stays unchanged. Use current latest batch to test both
-- snapshots and detached exports without relying on old row retention.
for i=1,55 do schematic=schema();d=finish(begin(allocated(1))) end
eq(#LL.db.craftResearch.diagnostics,50)
local latest=LL:SnapshotRecordedResearch(true);eq(#latest.diagnostics,1)
eq(latest.diagnostics[1].craftAllocation.schematic.slots.schematicSlots[1].reagents.allowedReagents[1].itemID,10)
latest.diagnostics[1].craftAllocation.allocation.allocationEntries[1].quantity=999
eq(d.craftAllocation.allocation.allocationEntries[1].quantity,1,'latest snapshot is detached')
print('PASS: '..checks..' ordinary Craft diagnostic assertions')
