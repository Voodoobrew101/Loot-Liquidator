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
sent('cast-positive');bags=bag({[10]=5,[20]=2});success('cast-positive');emit('LOOT_CLOSED');advance(1.3)
local d=LL.db.craftResearch
eq(#d.records,1);eq(d.records[1].outputCoverage,'complete');eq(d.records[1].outputs[1].quantity,2)
eq(d.records[1].resultMetadata and #d.records[1].resultMetadata,0)
check(d.contexts[d.records[1].contextID].simulated==false)
success('cast-positive');eq(d.studies[d.activeStudy].censored,nil,'duplicate success is harmless')
sent('cast-zero');bags=bag({[20]=2});success('cast-zero');emit('LOOT_CLOSED')
eq(LL:ConfirmEmptyCraft(),false,'pending results cannot be confirmed prematurely');advance(13.1)
eq(#d.records,2);eq(d.records[2].outputCoverage,'unresolved','timeout is not zero')
local baseline,issue=LL:CraftBaseline(d.activeStudy,d.records[1].contextID,1231127)
eq(baseline,nil);check(issue:find('Unresolved'))
check(LL:ConfirmEmptyCraft());eq(d.records[2].zeroEvidence,'operator-confirmed-empty')
baseline=assert(LL:CraftBaseline(d.activeStudy,d.records[1].contextID,1231127))
eq(baseline.operations,2);eq(baseline.materials[1].expectedQuantity,1);eq(baseline.materials[1].chance,.5)
eq(baseline.materials[1].minQuantity,2);eq(baseline.materials[1].maxQuantity,2)
eq(baseline.materials[1].quantityCounts['0'],1);eq(baseline.materials[1].quantityCounts['2'],1)
local learned=assert(LL:GetLearnedProcessingEstimate(facts[10],'Prospect',5,1231127))
eq(learned.effectiveSamples,2);eq(learned.materials[1].expectedQuantity,1)
LL.GetOutputPrice=function() return 100 end
local final=assert(LL:ResolveEvidenceModel(facts[10],{name='Prospect',inputCount=5,recipeID=1231127},learned,2))
eq(LL:ValueProcessingModel(final,0,true),20,'engine uses unconditional quantity once / 5')
eq(final.context.effectiveSkill,75,'tooltip context comes from the measured personal model')
check(final.confidenceUnscored,'provisional captures do not claim a reviewed confidence score')
local wrongContext={character='Different - Realm',simulated=false}
eq(LL:ComputeEvidenceModel(facts[10],{name='Prospect',inputCount=5,recipeID=1231127},learned,2,wrongContext),nil,'another character cannot borrow measured samples')
wrongContext.character=LL:CharacterKey();wrongContext.simulated=true
eq(LL:ComputeEvidenceModel(facts[10],{name='Prospect',inputCount=5,recipeID=1231127},learned,2,wrongContext),nil,'manual simulation cannot borrow measured samples')
local otherStudy=clone(learned);otherStudy.studyID='different-study';otherStudy.materials[1].expectedQuantity=3
local otherModel=assert(LL:ResolveEvidenceModel(facts[10],{name='Prospect',inputCount=5,recipeID=1231127},otherStudy,2))
eq(otherModel.materials[1].expectedQuantity,3,'equal sample counts from different studies do not collide in the cache')
local file=assert(io.open('/tmp/loot-craft-export.json','w'));file:write(LL:ExportCraftResearch());file:close()
file=assert(io.open('/tmp/loot-craft-baselines.json','w'));file:write(LL:ExportCraftBaselines());file:close()
-- A fake empty direct sample without explicit evidence must not enter the log.
local invalid={operationID='bad-zero',method='Prospect',recipeID=1231127,character=LL:CharacterKey(),build='123456',successful=true,
 context=LL:CaptureCraftContext(1231127,nil,'Prospect'),inputs={{itemID=10,quantity=5}},outputs={},outputCoverage='complete'}
eq(LL:RecordCraftObservation(invalid),false)
-- Delayed loot after an unresolved zero prevents a later zero confirmation.
LL:StartCraftStudy('late loot');bags=bag({[10]=5});sent('late');bags=bag({});success('late');advance(13.1)
bags=bag({[20]=2});eq(LL:ConfirmEmptyCraft(),false)
-- Interrupted/failed operations are not denominator samples.
LL:StartCraftStudy('failure');bags=bag({[10]=5});local n=#d.records
sent('failed');emit('UNIT_SPELLCAST_FAILED','player','failed',1231127);bags=bag({});advance(14);eq(#d.records,n)
-- Another unit cannot complete this player's cast, nor can a mismatched GUID.
bags=bag({[10]=5});sent('actual');bags=bag({[20]=2})
emit('UNIT_SPELLCAST_SUCCEEDED','party1','actual',1231127);success('wrong-guid');emit('LOOT_CLOSED');advance(2);eq(#d.records,n)
success('actual');advance(2);eq(#d.records,n+1)
-- Overlap never turns two simultaneous bag deltas into one operation.
LL:StartCraftStudy('overlap');bags=bag({[10]=10});sent('first');success('first');sent('second')
bags=bag({[20]=4});success('second');advance(14);check(d.studies[d.activeStudy].censored)
-- Other inventory interactions censor the study, preserving diagnostics.
LL:StartCraftStudy('trade');bags=bag({[10]=5});sent('trade');success('trade');emit('TRADE_SHOW');bags=bag({[20]=2});advance(14)
check(d.studies[d.activeStudy].censored);check(#d.diagnostics>0)
-- Generic crafting supports multiple fixed required reagents, without reading
-- the simulated Manual profile or guessing optional/alternative allocations.
C_TradeSkillUI={GetRecipeInfo=function() return {learned=true} end,GetRecipeSchematic=function()
 return {recipeID=999,outputItemID=20,isRecraft=false,reagentSlotSchematics={
  {required=true,quantityRequired=2,reagents={{itemID=10}}},
  {required=true,quantityRequired=3,reagents={{itemID=11}}}}} end}
LL:StartCraftStudy('generic');bags=bag({[10]=2,[11]=3});sent('multi',999)
bags=bag({[20]=1});success('multi',999)
emit('TRADE_SKILL_ITEM_CRAFTED_RESULT',{itemID=20,quantity=1,itemGUID='item-guid',operationID=99,resourcesReturned={}})
emit('TRADE_SKILL_ITEM_CRAFTED_RESULT',{itemID=20,quantity=1,itemGUID='item-guid',operationID=99,resourcesReturned={}})
advance(2);local last=d.records[#d.records];eq(last.operationID,'multi');eq(last.method,'Craft');eq(#last.inputs,2);eq(#last.resultMetadata,1)
eq(LL:GetRecordedProcessingEstimate(facts[10],'Craft',2,999),nil,'multi-input baseline is not priced as one-input')
local raw=clone(invalid);raw.operationID='manual';raw.context.simulated=true;raw.outputs={{itemID=20,quantity=2}}
eq(LL:RecordCraftObservation(raw),false,'simulation cannot be recorded as measured')
-- The actual reagent allocation and typed resource-return event distinguish
-- nominal consumption from net inputs; no Resourcefulness coefficient is guessed.
C_TradeSkillUI.GetRecipeSchematic=function(recipe)
 return {recipeID=recipe,outputItemID=20,isRecraft=false,reagentSlotSchematics={
  {dataSlotIndex=1,required=true,quantityRequired=2,reagents={{itemID=10},{itemID=11}}}}}
end
LL:StartCraftStudy('allocated-refund');bags=bag({[11]=2})
hooks.CraftRecipe(1000,1,{{dataSlotIndex=1,reagent={itemID=11},quantity=2}},nil,0,false)
sent('refund',1000);bags=bag({[11]=1,[20]=3});success('refund',1000)
emit('TRADE_SKILL_ITEM_CRAFTED_RESULT',{itemID=20,quantity=3,itemGUID='refund-output',operationID=100,
 resourcesReturned={{reagent={itemID=11},quantity=1}}})
advance(2);last=d.records[#d.records];eq(last.operationID,'refund');eq(last.inputs[1].quantity,1);eq(last.nominalInputs[1].quantity,2)
local refundBase=assert(LL:CraftBaseline(last.studyID,last.contextID,1000))
eq(refundBase.expectedInputsConsumed[1].expectedQuantity,1);eq(refundBase.inputs[1].quantity,2)
eq(refundBase.materials[1].expectedQuantity,3)
local refundEstimate=assert(LL:GetRecordedProcessingEstimate(facts[11],'Craft',2,1000))
local resolved=assert(LL:ResolveEvidenceModel(facts[11],{name='Craft',inputCount=2,recipeID=1000},refundEstimate,2))
LL.GetOutputPrice=function(_,id) return id==20 and 100 or id==11 and 50 end
eq(LL:ValueProcessingModel(resolved,0,true,facts[11]),175,'value includes observed saved input / original nominal batch')
LL.AuctionEligible=function() return false end;facts[11].vendor=7
eq(LL:ValueProcessingModel(resolved,0,true,facts[11]),153.5,'bound input savings use the available vendor value')
LL.AuctionEligible=nil
local refundFile=assert(io.open('/tmp/loot-craft-refund-export.json','w'));refundFile:write(LL:ExportCraftResearch());refundFile:close()
-- Recrafts and customer orders cannot be mistaken for bag-output crafts.
LL:ObserveCraftRequest(1001,1,{},nil,99,false);bags=bag({[10]=2});check(not LL:BeginCraftCapture('order',1001))
C_TradeSkillUI.GetRecipeSchematic=function(recipe) return {recipeID=recipe,isRecraft=true} end
check(not LL:BeginCraftCapture('recraft',1002))
-- Long casts time out relative to success, not relative to their start.
LL:StartCraftStudy('long cast');bags=bag({[10]=5});sent('long');advance(20)
bags=bag({[20]=2});success('long');emit('LOOT_CLOSED');advance(2)
eq(d.records[#d.records].operationID,'long');eq(d.records[#d.records].outputCoverage,'complete')
-- Turning recording off prevents all new records and starts a new study on re-enable.
LL.db.recordConversions=false;local beforeCount=#d.records
bags=bag({[10]=5});check(not LL:BeginCraftCapture('disabled',1231127));eq(#d.records,beforeCount)
LL.db.recordConversions=true
-- Source records/context are copied; caller mutation cannot rewrite history.
local ctx=LL:CaptureCraftContext(1231127,nil,'Prospect')
local rawCopy=clone(invalid);rawCopy.operationID='immutable';rawCopy.context=ctx
rawCopy.outputs={{itemID=20,quantity=1}};rawCopy.outputCoverage='complete'
check(LL:RecordCraftObservation(rawCopy));ctx.baseSkill=999;rawCopy.outputs[1].quantity=999
local stored=d.records[#d.records]
check(d.contexts[stored.contextID].baseSkill~=999);eq(stored.outputs[1].quantity,1)
-- Measured contexts query current API values with the actual allocation;
-- no Manual settings or historical specialization is substituted.
C_TradeSkillUI.GetProfessionInfoByRecipeID=function() return {professionID=1234,parentProfessionName='Jewelcrafting',skillLevel=70,skillModifier=5} end
C_TradeSkillUI.GetProfessionInventorySlots=function() return {20} end
GetInventoryItemLink=function() return 'item:equipped-tool' end
C_ProfSpecs={GetConfigIDForSkillLine=function() return 1 end,GetSpecTabIDsForSkillLine=function() return {10} end,
 GetRootPathForTab=function() return 100 end,GetChildrenForPath=function() return {} end}
C_Traits={GetNodeInfo=function() return {currentRank=3} end}
local calls=0
C_TradeSkillUI.GetCraftingOperationInfo=function(recipe,allocation,guid,concentration)
 calls=calls+1;eq(recipe,1000);eq(allocation[1].quantity,2);eq(concentration,false)
 return {baseSkill=70,bonusSkill=15,bonusStats={{bonusStatName='Resourcefulness',bonusStatValue=42}},craftingQuality=2}
end
LL.db.manualProfessionProfiles={['Tester - Realm']={['Jewelcrafting:11']={enabled=true,skill=999,specialization='none',simulated=true}}}
local measured=captureMeasured(LL,1000,facts[11],'Craft',{{dataSlotIndex=1,reagent={itemID=11},quantity=2}},false)
eq(measured.effectiveSkill,85);eq(measured.specialization,'100=3');eq(measured.equipment['20'],'item:equipped-tool')
eq(measured.operationStats[1].bonusStatValue,42);eq(measured.simulated,false)
C_ProfSpecs=nil;C_Traits=nil
local unavailable=captureMeasured(LL,1000,facts[11],'Craft')
eq(unavailable.specialization,nil);eq(unavailable.fieldStatus.specialization,'unknown');eq(unavailable.operationStats,nil);eq(calls,1)
-- Exercise valuation using the real context reader, not the fixture stub. A
-- recorded allocation must be re-read, and changed stats must reject matching.
C_ProfSpecs={GetConfigIDForSkillLine=function() return 1 end,GetSpecTabIDsForSkillLine=function() return {10} end,
 GetRootPathForTab=function() return 100 end,GetChildrenForPath=function() return {} end}
C_Traits={GetNodeInfo=function() return {currentRank=3} end}
LL.CaptureCraftContext=captureMeasured
LL:StartCraftStudy('measured-allocation');bags=bag({[11]=2})
local operationAllocation={{dataSlotIndex=1,reagent={itemID=11},quantity=2}}
local realRecord={operationID='measured-allocation',recipeID=1000,method='Craft',successful=true,
 character=LL:CharacterKey(),build='123456',context=captureMeasured(LL,1000,facts[11],'Craft',operationAllocation,false),
 inputs={{itemID=11,quantity=2,rarity=1}},outputs={{itemID=20,quantity=3}},
 allocation=operationAllocation,applyConcentration=false,outputCoverage='complete'}
check(LL:RecordCraftObservation(realRecord))
local matched=assert(LL:GetRecordedProcessingEstimate(facts[11],'Craft',2,1000))
eq(matched.observationContext.effectiveSkill,85,'real operation allocation is rechecked')
C_TradeSkillUI.GetCraftingOperationInfo=function() return {baseSkill=70,bonusSkill=16,bonusStats={}} end
eq(LL:GetRecordedProcessingEstimate(facts[11],'Craft',2,1000),nil,'changed equipment/operation stats cannot reuse baseline')
eq(craftCalls,0,'recorder never executes a craft')
-- A study left active by an interrupted client session has unknown coverage.
-- Reloading cannot silently reuse it as a complete denominator.
local oldStudy=d.activeStudy
local resumed={db=clone(LL.db),CharacterKey=LL.CharacterKey}
assert(loadfile('LootLiquidator/CraftRecording.lua'))('LootLiquidator',resumed)
local newStudy=assert(resumed:StartCraftStudy('after interrupted session'))
check(resumed.db.craftResearch.studies[oldStudy].censored)
check(newStudy~=oldStudy)
-- Retained source snapshots and registry are never changed by observations.
eq(#LL.ItemDB.mechanicRules,0);eq(LL.ItemDB.processing[1].materials[1].expectedQuantity.value,2)
print('PASS: '..checks..' cast-recorder assertions (events, zeros, delayed loot, coverage, generic crafting, baseline and engine)')
