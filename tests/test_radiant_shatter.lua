-- Real result receipts replayed through the public player-event observer.
-- The timing/bag schedules are fixtures, not a retrospective coverage waiver.
local checks=0
local function check(v,m)checks=checks+1;assert(v,m or 'check failed')end
local function eq(a,b,m)check(a==b,(m or '')..' expected '..tostring(b)..', got '..tostring(a))end
local function copy(x)if type(x)~='table'then return x end local t={}for k,v in pairs(x)do t[k]=copy(v)end return t end
local now,frames,timers,hooks=0,{},{},{}
local learned,linked,disabled,isSalvage=true,false,false,true
local inputIDs={243602,243603}
local counts={[243602]=50}
local facts={}
for _,row in ipairs({{243602,1,3},{243603,2,3},{243599,1,1},{243600,2,1},{777777,1,1}})do
 facts[row[1]]={id=row[1],link='item:'..row[1],quality=row[3],reagentQuality=row[2],classID=7,subClassID=12,expansionID=11}
end
GetTime=function()return now end;time=function()return 2000000+now end
GetBuildInfo=function()return '12.1.5','70783','',120105 end
UnitName=function()return 'Voodoobrew'end;GetRealmName=function()return 'Grizzly Hills'end
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
 GetRecipeInfo=function(id)return {learned=learned,disabled=disabled,isSalvageRecipe=id==1280394 and isSalvage,name='recipe fixture'}end,
 GetRecipeSchematic=function(id)return {recipeID=id,reagentSlotSchematics=id==1000 and
  {{dataSlotIndex=1,required=true,quantityRequired=2,reagents={{itemID=243602}}}}or{}}end,
 GetSalvagableItemIDs=function(id)eq(id,1280394);return inputIDs end}
hooksecurefunc=function(_,name,callback)hooks[name]=callback end
local LL={db={recordConversions=true,recordDisenchants=true,characters={}},buildInfo={commit='fixture-build'}}
for _,name in ipairs({'Professions.lua','ImportedResults.lua','CraftRecording.lua'})do
 assert(loadfile('LootLiquidator/'..name))('LL',LL)end
LL.GetItemFacts=function(_,link)return copy(facts[tonumber(link:match('item:(%d+)'))])end
LL.SnapshotCraftBags=function()local variants={}
 for id in pairs(counts)do variants[id]={['item:'..id]=true}end
 return {counts=copy(counts),facts=copy(facts),variants=variants}end
LL.Invalidate=function()end
local source=assert(io.open('research/integration/measured-captures/2026-11-07-pr49-radiant-shatter-diagnostics-update/export-page-1.json','r'))
local original=assert(LL.DecodeImportJSON(source:read('*a')));source:close()
local receipts={}
for _,d in ipairs(original.diagnostics)do
 eq(d.recipeID,1280394);eq(d.method,'Craft');eq(d.context.operationInputItemID,243602)
 eq(d.context.operationInputQualityRank,1);eq(#d.resultMetadata,1)
 receipts[#receipts+1]=copy(d.resultMetadata[1])
end
eq(#receipts,50)
LL.CaptureCraftContext=function(self,recipe,f,method,allocation,concentration,guid)
 local c=copy(original.diagnostics[1].context)
 c.character=self:CharacterKey();c.recipeID=recipe;c.method=method;c.observed=time()
 c.allocationKnown=type(allocation)=='table';c.operationInputItemID=f and f.id
 c.operationInputQualityRank=f and f.reagentQuality
 return c
end
local function ledger()return LL.db.craftResearch end
local function request(n,id)id=id or 243602;hooks.CraftSalvage(1280394,n,{id=id,guid='Item-target-'..id},{},false)end
local function start(guid,recipe)recipe=recipe or 1280394
 emit('UNIT_SPELLCAST_SENT','player','',guid,recipe);emit('UNIT_SPELLCAST_START','player',guid,recipe)end
local function finish(guid,result,recipe)recipe=recipe or 1280394
 emit('UNIT_SPELLCAST_SUCCEEDED','player',guid,recipe)
 if result then emit('TRADE_SKILL_ITEM_CRAFTED_RESULT',copy(result))end end
local function result(id,output,qty)
 local r=copy(receipts[1]);r.operationID=id;r.itemID=output or 243599;r.quantity=qty or 3
 r.hyperlink='item:'..r.itemID;return r
end
eq(LL:SalvageRecipeDefinition(1280394).inputCount,1)
eq(LL:SalvageRecipeDefinition(1280394).method,'Craft')
eq(LL:SalvageRecipeDefinition(1280394).profession,'Enchanting')
eq(LL:SalvageRecipeDefinition(1229930).inputCount,5,'Engineering batch stays five')
eq(LL:SalvageRecipeDefinition(1280395),nil,'Dawn Shatter is not assumed supported')
LL.db.characters[LL:CharacterKey()]={salvageRecipes={[1280394]={inputs={[243602]=true}}}}
local options=LL:SalvageConversionOptions(facts[243602])
eq(#options,1);eq(options[1].source,'In-game salvage input list');eq(options[1].profession,'Enchanting')
LL.Conversions={[243602]={{method='Craft',recipeID=1280394,inputCount=1}}}
eq(#LL:SalvageConversionOptions(facts[243602]),0,'do not duplicate a curated recipe option')
LL.Conversions=nil

-- Reproduce the real failing shape: target is outside ordinary reagent slots.
-- Fifty authoritative three-dust receipts, one aggregate fifty-shard bag delta.
LL:StartCraftStudy('fifty real Shatter receipts');request(50)
local total=0
for i,r in ipairs(receipts)do
 start('radiant-'..i);finish('radiant-'..i,r);total=total+r.quantity
 if i==50 then counts={[243599]=total};emit('BAG_UPDATE_DELAYED')end
 advance(2)
end
eq(total,150);eq(#ledger().records,50);eq(ledger().studies[ledger().activeStudy].censored,nil)
for i,r in ipairs(ledger().records)do
 eq(r.method,'Craft');eq(r.recipeID,1280394);eq(r.nominalInputs[1].quantity,1);eq(r.inputs[1].quantity,1)
 eq(r.outputs[1].itemID,243599);eq(r.outputs[1].quantity,3);eq(r.captureVersion,3);eq(r.recorderRevision,6)
 eq(r.resultMetadata[1].operationID,receipts[i].operationID)
 eq(r.bagReconciliation.operations,50);eq(r.bagReconciliation.inputs[1].quantity,50)
 eq(r.bagReconciliation.outputs[1].quantity,150)
 eq(ledger().contexts[r.contextID].operationInputQualityRank,1)
 eq(r.salvageTarget.itemGUID,'Item-target-243602')
end
local exported=assert(io.open('/tmp/loot-radiant-shatter-capture-v3.json','w'))
exported:write(LL:ExportCraftResearch('all'));exported:close()

-- An extra unobserved operation cannot be manufactured by dividing totals.
-- Fifty typed operations do not explain a bag delta of fifty-one/153 dust.
LL:StartCraftStudy('unmatched fifty-first outcome');counts={[243602]=51};request(50)
local before=#ledger().records
for i,r in ipairs(receipts)do
 local unique=copy(r);unique.operationID=960000+i
 start('unmatched-'..i);finish('unmatched-'..i,unique);advance(.2)
end
counts={[243599]=153};emit('BAG_UPDATE_DELAYED');advance(13.1)
eq(#ledger().records,before);check(ledger().studies[ledger().activeStudy].coverageGaps['Craft:1280394'])
eq(ledger().diagnostics[#ledger().diagnostics].reason,'Unrelated Salvage output change')

-- Rank identity is retained from the selected native target and typed result.
LL:StartCraftStudy('rank two target');counts={[243603]=1};request(1,243603);start('rank-two')
counts={[243600]=3};finish('rank-two',result(940001,243600));advance(1.3)
local r=ledger().records[#ledger().records]
eq(r.operationID,'rank-two');eq(r.nominalInputs[1].itemID,243603);eq(r.nominalInputs[1].qualityRank,2)
eq(r.outputs[1].itemID,243600);eq(r.outputs[1].qualityRank,2)
eq(ledger().contexts[r.contextID].operationInputQualityRank,2)

-- Explicit Resourcefulness returns permit zero net consumption, while still
-- requiring one physical shard as the nominal target at the moment of casting.
LL:StartCraftStudy('full refund');counts={[243602]=1};request(1);start('full-refund')
local refund=result(940002);refund.resourcesReturned={{reagent={itemID=243602},quantity=1}}
counts={[243602]=1,[243599]=3};finish('full-refund',refund);advance(1.3)
r=ledger().records[#ledger().records];eq(r.operationID,'full-refund');eq(r.inputs[1].quantity,0);eq(r.nominalInputs[1].quantity,1)
LL:StartCraftStudy('reuse fully refunded target');counts={[243602]=1};request(2)
for i=1,2 do
 start('reuse-'..i);local packet=result(940002+i);packet.resourcesReturned={{reagent={itemID=243602},quantity=1}}
 finish('reuse-'..i,packet)
 if i==2 then counts={[243602]=1,[243599]=6};emit('BAG_UPDATE_DELAYED')end
 advance(.2)
end
advance(1.3);eq(ledger().records[#ledger().records].operationID,'reuse-2')
eq(ledger().studies[ledger().activeStudy].censored,nil)

-- Duplicate packets are not more dust or another cast, including late packets
-- from a completed cast that arrive while the following one is being recorded.
LL:StartCraftStudy('duplicate receipts');counts={[243602]=2};request(2);start('duplicate-a')
local packet=result(940010);emit('UNIT_SPELLCAST_SUCCEEDED','player','duplicate-a',1280394)
emit('TRADE_SKILL_ITEM_CRAFTED_RESULT',packet);emit('TRADE_SKILL_ITEM_CRAFTED_RESULT',packet)
counts={[243602]=1,[243599]=3};emit('BAG_UPDATE_DELAYED');advance(1.3)
start('duplicate-b');emit('TRADE_SKILL_ITEM_CRAFTED_RESULT',packet)
counts={[243599]=6};finish('duplicate-b',result(940011));advance(1.3)
eq(ledger().records[#ledger().records].operationID,'duplicate-b');eq(ledger().records[#ledger().records].outputs[1].quantity,3)

-- Bad targets, missing evidence and interference remain scoped failures.
for i,scenario in ipairs({'not-listed','no-target','no-result','unreported-refund','no-nominal-input','conflicting-receipt','unrelated-bags'})do
 LL:StartCraftStudy(scenario);counts={[243602]=scenario=='no-nominal-input'and 0 or 1};before=#ledger().records
 if scenario~='no-target'then request(1,scenario=='not-listed'and 777777 or 243602)end
 start(scenario);counts={[243599]=3}
 if scenario=='unreported-refund'then counts[243602]=1 end
 if scenario=='unrelated-bags'then counts[777777]=1 end
 local packet=result(940100+i)
 if scenario=='no-nominal-input'then packet.resourcesReturned={{reagent={itemID=243602},quantity=1}}end
 finish(scenario,scenario~='no-result'and packet or nil)
 if scenario=='conflicting-receipt'then packet.quantity=4;emit('TRADE_SKILL_ITEM_CRAFTED_RESULT',packet)end
 advance(13.1);eq(#ledger().records,before,scenario);check(ledger().studies[ledger().activeStudy].coverageGaps['Craft:1280394'],scenario)
end
LL:StartCraftStudy('ordinary craft stays strict');counts={[243602]=2}
hooks.CraftRecipe(1000,1,{},nil,nil,false);start('ordinary',1000);counts={[243602]=1,[243599]=3}
before=#ledger().records;finish('ordinary',result(940200),1000);advance(13.1)
eq(#ledger().records,before);check(ledger().studies[ledger().activeStudy].coverageGaps['Craft:1000'])
-- Upgrade rolls over the old failing study without modifying its flags.
local old=ledger().activeStudy;ledger().studies[old].recorderRevision=5
counts={[243602]=1};request(1);start('after-upgrade')
check(ledger().activeStudy~=old);check(ledger().studies[old].coverageGaps['Craft:1000'])
counts={[243599]=3};finish('after-upgrade',result(940201));advance(1.3)
eq(ledger().studies[ledger().activeStudy].censored,nil)
local priorRecords=#ledger().records
linked=true;check(not LL:BeginCraftCapture('linked',1280394));linked=false
learned=false;check(not LL:BeginCraftCapture('unlearned',1280394));learned=true
disabled=true;check(not LL:BeginCraftCapture('disabled',1280394));disabled=false
isSalvage=false;check(not LL:BeginCraftCapture('not-salvage',1280394));isSalvage=true
eq(#ledger().records,priorRecords,'unsupported native states never create observations')
eq(craftCalls,0,'observer never executes a crafting API')
print('PASS: '..checks..' Radiant Shatter target, 50-receipt replay, batching, refunds, duplicate and rejection checks')
