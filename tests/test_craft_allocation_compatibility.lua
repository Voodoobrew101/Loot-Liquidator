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

-- Actual event-path differential fixture, also runnable unchanged on original main.
local schematic
C_TradeSkillUI.GetRecipeInfo=function() return {learned=true} end
C_TradeSkillUI.GetRecipeSchematic=function() return schematic end
local cases={
 {quantity=2,required=true,options={11,10},accepted=true},
 {quantity=1,required=true,options={11,10},reason='Unknown reagent allocation'},
 {quantity=0,required=true,options={11,10},reason='Unknown reagent allocation'},
 {quantity=-1,required=true,options={11,10},reason='Unknown reagent allocation'},
 {quantity='invalid',required=true,options={11,10},reason='Unknown reagent allocation'},
 {quantity=2,required=true,options={99},reason='Unknown reagent allocation'},
 {missing=true,required=true,options={11},accepted=true},
 {missing=true,required=true,options={11,10},reason='Unknown reagent allocation'},
 {quantity=2,required=true,options={11,10},slot=2,reason='Unknown reagent allocation'},
 {quantity=2,required=false,options={11,10},slot=2,reason='Unknown reagent allocation'},
 {quantity=2,required=true,options={11,10},consumed=1,reason='Recipe reagent consumption mismatch'},
 {quantity=2,required=true,options={11,10},refund=1,consumed=1,accepted=true},
 {quantity=1,required=false,options={11,10},consumed=1,accepted=true},
}
for i,c in ipairs(cases) do
 schematic={recipeID=1000,isRecraft=false,reagentSlotSchematics={
  {dataSlotIndex=1,required=c.required,quantityRequired=2,reagents={}}}}
 for _,id in ipairs(c.options) do table.insert(schematic.reagentSlotSchematics[1].reagents,{itemID=id}) end
 local allocation=not c.missing and {{dataSlotIndex=c.slot or 1,reagent={itemID=11},quantity=c.quantity}} or nil
 LL:StartCraftStudy('differential-'..i);bags=bag({[11]=2})
 hooks.CraftRecipe(1000,1,allocation,nil,0,false);sent('differential-'..i,1000)
 bags=bag({[11]=2-(c.consumed or 2),[20]=1});success('differential-'..i,1000)
 emit('TRADE_SKILL_ITEM_CRAFTED_RESULT',{itemID=20,quantity=1,itemGUID='output-'..i,operationID=i,
  resourcesReturned=c.refund and {{reagent={itemID=11},quantity=c.refund}} or {}})
 local old=#LL.db.craftResearch.records;local result=LL:FinishCraftCapture(true)
 if c.accepted then check(result);eq(#LL.db.craftResearch.records,old+1)
 else eq(result,false);eq(#LL.db.craftResearch.records,old)
  eq(LL.db.craftResearch.diagnostics[#LL.db.craftResearch.diagnostics].reason,c.reason) end
end
-- Compare the entire original export, including coverage/context/receipts/rates,
-- after removing ONLY the new diagnostic field. Do not omit existing fields.
for _,d in ipairs(LL.db.craftResearch.diagnostics) do d.craftAllocation=nil end
local path=os.getenv('CRAFT_COMPAT_OUTPUT') or '/tmp/loot-craft-compatibility.json'
local f=assert(io.open(path,'w'));f:write(LL:ExportCraftResearch('all'));f:close()
print('PASS: '..checks..' unchanged Craft acceptance/coverage assertions')
