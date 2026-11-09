-- Real pilot receipts, synthetic event ordering: capture, discovery and valuation.
local checks=0
local function check(v,m)assert(v,m);checks=checks+1 end
local function eq(a,b,m)check(a==b,(m or 'mismatch')..': '..tostring(a)..' ~= '..tostring(b))end
local function copy(v)if type(v)~='table'then return v end local n={}for k,x in pairs(v)do n[k]=copy(x)end return n end
local now,frames,timers,hooks=0,{},{},{}
local skill,linked,learned,disabled=1,false,true,false
local inputIDs={245807,245808,222001,222002} -- extra IDs are eligibility fixtures, not game claims
local counts={[245807]=100}
local facts={}
for _,id in ipairs(inputIDs)do facts[id]={id=id,link='item:'..id,quality=1,reagentQuality=id==245808 and 2 or 1,classID=7,subClassID=16,expansionID=11}end
for _,id in ipairs({243581,243582,777777})do facts[id]={id=id,link='item:'..id,quality=2,reagentQuality=id==243582 and 2 or 1,classID=7,expansionID=11}end
GetTime=function()return now end;time=function()return 2000000+now end
GetBuildInfo=function()return '12.1.5','70783','',120105 end
UnitName=function()return 'Tester'end;GetRealmName=function()return 'Realm'end
CreateFrame=function()local f={events={}};function f:RegisterEvent(e)self.events[e]=true end
 function f:SetScript(_,fn)self.fn=fn end;frames[#frames+1]=f;return f end
C_Timer={After=function(delay,fn)timers[#timers+1]={at=now+delay,fn=fn}end}
local function emit(event,...)for _,f in ipairs(frames)do if f.events[event]then f.fn(f,event,...)end end end
local function advance(seconds)local finish=now+seconds
 while true do local index,first
  for i,t in ipairs(timers)do if t.at<=finish and(not first or t.at<first.at)then index,first=i,t end end
  if not first then break end;table.remove(timers,index);now=first.at;first.fn()
 end;now=finish end
local craftCalls=0
C_Item={GetItemID=function(location)return location.id end,GetItemGUID=function(location)return location.guid end}
C_TradeSkillUI={CraftRecipe=function()craftCalls=craftCalls+1 end,CraftSalvage=function()craftCalls=craftCalls+1 end,
 IsTradeSkillLinked=function()return linked end,
 GetChildProfessionInfo=function()return {professionID=2021,professionName='Midnight Engineering',parentProfessionName='Engineering'}end,
 GetAllRecipeIDs=function()return {1229930}end,
 GetRecipeInfo=function()return {learned=learned,disabled=disabled,isSalvageRecipe=true,name='Recycling'}end,
 GetRecipeSchematic=function(id)return {recipeID=id,recipeType=2,reagentSlotSchematics={}}end,
 GetSalvagableItemIDs=function(id)eq(id,1229930);return inputIDs end}
hooksecurefunc=function(_,name,callback)hooks[name]=callback end
local LL={db={recordConversions=true,recordDisenchants=true,characters={},minPersonalSamples=1}}
for _,name in ipairs({'ItemDBRuntime.lua','ProfessionModels.lua','Database.lua','Professions.lua','Observations.lua','CraftRecording.lua','ImportedResults.lua','ConversionEngine.lua'})do
 assert(loadfile('LootLiquidator/'..name))('LL',LL)end
check(LL:InitializeItemDB());LL:MigrateEvidenceSettings()
LL.db.characters[LL:CharacterKey()]={professions={Engineering=true},recipes={}}
LL.HasCurrentProfession=function(_,p)return p=='Engineering'end
LL.Invalidate=function(self)self._processingModelCache=nil;self._processingContextCache=nil end
LL.GetOutputPrice=function()return 100 end
LL.EligibleDisenchant=function()return false end
LL.GetItemFacts=function(_,link)return copy(facts[tonumber(link:match('item:(%d+)'))])end
LL.CaptureCraftContext=function(self,recipe,f,method,allocation,concentration,guid)
 return {character=self:CharacterKey(),recipeID=recipe,method=method,profileKind='measured',simulated=false,
  profession='Engineering',skillLineID=2021,baseSkill=skill,bonusSkill=0,effectiveSkill=skill,specialization='none',
  equipment={},operationStats={},allocationKnown=type(allocation)=='table',operationInputItemID=f and f.id,
  observed=time(),fieldStatus={equipment='measured'}}
end
LL.SnapshotCraftBags=function()local variants={}
 for id in pairs(counts)do variants[id]={['item:'..id]=true}end
 return {counts=copy(counts),facts=copy(facts),variants=variants}end
LL:ScanProfessionRecipes()
local char=LL.db.characters[LL:CharacterKey()]
eq(LL:ProfessionForMethod('Recycle'),'Engineering')
for _,id in ipairs(inputIDs)do
 local options=LL:ConversionOptions(facts[id]);local recycle
 for _,o in ipairs(options)do if o.name=='Recycle'then recycle=o end end
 check(recycle,'all client inputs, including unowned and both pigment ranks, get an option')
 eq(recycle.inputCount,5);eq(recycle.recipeID,1229930);eq(recycle.value,nil,'eligibility does not invent a price')
 eq(recycle.letter,'R');check(recycle.eligibleInput)
end
eq(#LL:SalvageConversionOptions({id=999999}),0,'unlisted item is not eligible')
local unowned=copy(facts[245808]);unowned.count=0
local options=LL:ConversionOptions(unowned)
eq(options[1].available,false);check(options[1].eligibleInput,'insufficient bags retain the visible eligibility')
local old=copy(char.salvageRecipes)
linked=true;LL:ScanProfessionRecipes();check(char.salvageRecipes[1229930],'linked scan cannot replace own eligibility');linked=false
inputIDs={245807,245808};LL:ScanProfessionRecipes()
eq(#LL:SalvageConversionOptions({id=222001}),0,'rescan removes stale inputs')
learned=false;LL:ScanProfessionRecipes();eq(#LL:SalvageConversionOptions(facts[245807]),0,'unlearning removes eligibility')
learned=true;disabled=true;LL:ScanProfessionRecipes();eq(#LL:SalvageConversionOptions(facts[245807]),0,'disabled recipe cannot supply candidates')
disabled=false;LL:ScanProfessionRecipes()
local original=LL.db.characters[LL:CharacterKey()]
LL.db.characters.Alt={professions={Engineering=true},recipes={[1229930]={learned=true}},salvageRecipes={}}
LL.db.characters[LL:CharacterKey()]={professions={Engineering=true},recipes={}}
local c=LL:SalvageConversionOptions(facts[245807]);eq(#c,0)
LL.db.characters[LL:CharacterKey()]=original
LL.HasCurrentProfession=function()return false end
local available=LL:CanUseConversion(facts[245807],{method='Recycle',profession='Engineering',recipeID=1229930,salvage=true})
eq(available,false,'an alt with recipe but no target list cannot claim eligibility')
LL.db.characters.Alt.salvageRecipes=copy(old)
check(LL:CanUseConversion(facts[245807],{method='Recycle',profession='Engineering',recipeID=1229930,salvage=true}))
LL.db.includeVerifiedAlts=false
eq(LL:CanUseConversion(facts[245807],{method='Recycle',profession='Engineering',recipeID=1229930,salvage=true}),false)
LL.db.includeVerifiedAlts=true;LL.HasCurrentProfession=function(_,p)return p=='Engineering'end
local source=assert(io.open('research/integration/measured-captures/2026-11-06-recycling-pilot/recycling-diagnostics.json','r'))
local diagnostics=assert(LL.DecodeImportJSON(source:read('*a')));source:close()
local pilot={}
for _,d in ipairs(diagnostics)do
 eq(d.recipeID,1229930);eq(d.context.specialization,'none');eq(d.context.bonusSkill,0)
 eq(#d.resultMetadata,1)
 pilot[#pilot+1]={skill=d.context.baseSkill,result=d.resultMetadata[1]}
end
eq(#pilot,20,'use the original exported result receipts, not invented output rates')
local function start(guid,id)
 emit('UNIT_SPELLCAST_SENT','player','',guid,1229930);emit('UNIT_SPELLCAST_START','player',guid,1229930)
end
local function finish(guid,result)
 emit('UNIT_SPELLCAST_SUCCEEDED','player',guid,1229930)
 emit('TRADE_SKILL_ITEM_CRAFTED_RESULT',copy(result))
end
local function result(op,qty,id)return {operationID=op,itemID=id or 243581,itemGUID='output-stack',quantity=qty,craftingQuality=1}end
local function request(n,id)hooks.CraftSalvage(1229930,n,{id=id or 245807,guid='input-stack'},nil,false)end
local function ledger()return LL.db.craftResearch end
local function rawExport(path)local f=assert(io.open(path,'w'));f:write(LL:ExportCraftResearch());f:close()end
-- The user's exact 20 receipts replayed against delayed inventory: no bag
-- update for the first 19 casts, then a single aggregate update for all20.
LL:StartCraftStudy('20-receipt pilot replay');request(20)
local total=0
for i,row in ipairs(pilot)do
 skill=row.skill;local guid='pilot-'..i
 start(guid);finish(guid,row.result);total=total+row.result.quantity
 if i==20 then counts={[243581]=total};emit('BAG_UPDATE_DELAYED')end
 advance(2)
end
eq(total,44);eq(#ledger().records,20);eq(ledger().studies[ledger().activeStudy].censored,nil)
for i,r in ipairs(ledger().records)do
 eq(r.method,'Recycle');eq(r.nominalInputs[1].quantity,5);eq(r.inputs[1].quantity,5)
 eq(r.outputs[1].quantity,pilot[i].result.quantity);eq(r.outputCoverage,'complete')
 eq(r.resultMetadata[1].operationID,pilot[i].result.operationID)
 eq(r.bagReconciliation.operations,20);eq(r.bagReconciliation.id,'pilot-1');eq(r.bagReconciliation.inputs[1].quantity,100)
 eq(r.bagReconciliation.outputs[1].quantity,44);eq(r.captureVersion,3)
 eq(ledger().contexts[r.contextID].baseSkill,pilot[i].skill,'per-cast skill preserved')
end
rawExport('/tmp/loot-recycling-capture-v3.json')
local quoted
for _,option in ipairs(LL:ConversionOptions(facts[245807]))do if option.name=='Recycle'then quoted=option end end
check(quoted and quoted.value,'matching measured Recycling results reach valuation')
eq(quoted.value,20,'only the matching skill19 cast is valued, once per5 inputs')
-- A returned input can fund a later cast in the same queue: nominal10,
-- initial9, net8. Receipts still prove each individual five-input operation.
LL:StartCraftStudy('reused returns');counts={[245807]=9};request(2)
for i=1,2 do
 start('reuse-'..i)
 local receipt=result(900010+i,2);receipt.resourcesReturned={{reagent={itemID=245807},quantity=1}}
 finish('reuse-'..i,receipt)
 if i==2 then counts={[245807]=1,[243581]=4};emit('BAG_UPDATE_DELAYED')end
 advance(2)
end
eq(ledger().records[#ledger().records].operationID,'reuse-2')
eq(ledger().studies[ledger().activeStudy].censored,nil,'refund reuse remains a complete batch')
-- A long CreateAll request stays attributable beyond the old120-second hint
-- lifetime as each genuine cast advances the observed request.
LL:StartCraftStudy('long CreateAll');counts={[245807]=350};request(70)
local beforeLong=#ledger().records
for i=1,70 do
 start('long-'..i);counts={[245807]=350-5*i,[243581]=i};finish('long-'..i,result(920000+i,1))
 emit('BAG_UPDATE_DELAYED');advance(2)
end
eq(#ledger().records,beforeLong+70);eq(ledger().studies[ledger().activeStudy].censored,nil)
-- Cancelling the next cast does not discard the earlier completed receipt.
LL:StartCraftStudy('cancel after receipt');counts={[245807]=10};request(2)
start('before-cancel');finish('before-cancel',result(900020,2));advance(.2)
start('cancelled');emit('UNIT_SPELLCAST_INTERRUPTED','player','cancelled',1229930)
counts={[245807]=5,[243581]=2};emit('BAG_UPDATE_DELAYED');advance(1.3)
eq(ledger().records[#ledger().records].operationID,'before-cancel')
eq(ledger().studies[ledger().activeStudy].censored,nil)
-- Changing inventories during a delayed sequence invalidates its full coverage.
LL:StartCraftStudy('queue interference');counts={[245807]=10};request(2)
local beforeInterference=#ledger().records
start('interference-1');finish('interference-1',result(900021,2));advance(.2)
start('interference-2');finish('interference-2',result(900022,2));emit('TRADE_SHOW');advance(1.3)
eq(#ledger().records,beforeInterference);check(ledger().studies[ledger().activeStudy].censored)
eq(ledger().diagnostics[#ledger().diagnostics-1].operationID,'interference-1')
eq(ledger().diagnostics[#ledger().diagnostics].operationID,'interference-2')
-- Resourcefulness uses nominal5 and reported net4, never an inferred proc rate.
LL:StartCraftStudy('returned input');counts={[245808]=10};request(1,245808);start('refund')
local refund=result(900001,2,243582);refund.resourcesReturned={{reagent={itemID=245808},quantity=1}}
counts={[245808]=6,[243582]=2};finish('refund',refund);advance(1.3)
local r=ledger().records[#ledger().records];eq(r.operationID,'refund');eq(r.inputs[1].quantity,4);eq(r.nominalInputs[1].quantity,5)
local b=assert(LL:CraftBaseline(r.studyID,r.contextID,1229930));eq(b.expectedInputsConsumed[1].expectedQuantity,4)
-- No fixed output catalogue is needed when typed results and inventory agree.
LL:StartCraftStudy('new typed output');counts={[245807]=5};request(1);start('new-output')
counts={[777777]=2};finish('new-output',result(900002,2,777777));advance(1.3)
eq(ledger().records[#ledger().records].outputs[1].itemID,777777)
-- A duplicate result from a committed cast cannot attach to the next one.
LL:StartCraftStudy('duplicates');counts={[245807]=10};request(2);start('duplicate-1')
counts={[245807]=5,[243581]=2};finish('duplicate-1',result(900003,2));advance(1.3)
start('duplicate-2');emit('TRADE_SKILL_ITEM_CRAFTED_RESULT',result(900003,2))
counts={[243581]=3};finish('duplicate-2',result(900004,1));advance(1.3)
eq(ledger().records[#ledger().records].operationID,'duplicate-2')
eq(ledger().records[#ledger().records].outputs[1].quantity,1)
-- Mismatched inputs, missing target/receipt and unrelated bag changes stay raw
-- diagnostics; they must never become a complete or zero-output sample.
for _,scenario in ipairs({'wrong-batch','wrong-target','no-target','no-receipt','unrelated','conflict'})do
 LL:StartCraftStudy(scenario);counts={[245807]=10};local before=#ledger().records
 if scenario~='no-target'then request(1,scenario=='wrong-target'and 999999 or 245807)end
 start(scenario)
 counts={[245807]=scenario=='wrong-batch'and 6 or 5,[243581]=2}
 if scenario=='unrelated'then counts[777777]=1 end
 emit('UNIT_SPELLCAST_SUCCEEDED','player',scenario,1229930)
 if scenario~='no-receipt'then
  local receipt=result(910000+before,2);emit('TRADE_SKILL_ITEM_CRAFTED_RESULT',receipt)
  if scenario=='conflict'then receipt.quantity=3;emit('TRADE_SKILL_ITEM_CRAFTED_RESULT',receipt)end
 end
 advance(13.1)
 eq(#ledger().records,before,scenario..' cannot be accepted');check(ledger().studies[ledger().activeStudy].censored,scenario)
end
-- An unrelated failed craft must not remove a successful Recycling denominator.
LL:StartCraftStudy('recipe coverage isolation');counts={[245807]=5};request(1);start('coverage-good')
counts={[243581]=2};finish('coverage-good',result(999001,2));advance(1.3)
local good=ledger().records[#ledger().records]
check(LL:BeginCraftCapture('coverage-craft',1000))
emit('UNIT_SPELLCAST_SUCCEEDED','player','coverage-craft',1000);LL:AbandonCraftCapture('Unknown reagent allocation')
local study=ledger().studies[good.studyID]
eq(study.coverageVersion,2);check(study.coverageGaps['Craft:1000'])
check(LL:CraftBaseline(good.studyID,good.contextID,1229930),'an unrelated failed recipe leaves Recycling usable')
counts={[245807]=5};request(1);start('coverage-bad')
emit('UNIT_SPELLCAST_SUCCEEDED','player','coverage-bad',1229930);LL:AbandonCraftCapture('Missing receipt')
check(not LL:CraftBaseline(good.studyID,good.contextID,1229930),'a Recycling gap blocks that recipe')
for i=1,60 do
    check(LL:BeginCraftCapture('coverage-later-'..i,1000))
    emit('UNIT_SPELLCAST_SUCCEEDED','player','coverage-later-'..i,1000);LL:AbandonCraftCapture('Unknown reagent allocation')
end
check(study.coverageGaps['Recycle:1229930'],'recipe gaps survive diagnostic eviction')
check(not LL:CraftBaseline(good.studyID,good.contextID,1229930))
eq(craftCalls,0,'observer never executes crafting or recycling')
print('PASS: '..checks..' Recycling discovery, 20-receipt replay, delayed-batch reconciliation, quality, refunds and rejection checks')
