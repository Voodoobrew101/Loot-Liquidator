-- Synthetic coefficients verify the complete control pipeline, not game rates.
local checks=0
local function check(v,s)assert(v,s);checks=checks+1 end
local function near(a,b,s)check(type(a)=='number' and math.abs(a-b)<1e-8,s..': '..tostring(a)..' ~= '..tostring(b))end
GetBuildInfo=function()return '12.1.5','70961','',120105 end
GetTime=function()return 100 end;time=GetTime
local frames={}
CreateFrame=function()local f={events={}};function f:RegisterEvent(e)self.events[e]=true end;function f:SetScript(_,fn)self.onEvent=fn end;frames[#frames+1]=f;return f end
local LL={db={characters={Player={professions={Jewelcrafting=true},researchProfiles={['Jewelcrafting:10']={skill=100,preSpecializationSkill=100,lineID=1000,observed=100,specialization='1=1',specializationKnown=true,specializationEncoding='invested-points',specializationSignatureEncoding='trait-node-current-rank',specializationVerified=true,specializationPoints={['1']=1},learnedSpecializations={['1']=true}}}}},source_legacy_enabled=false,source_reference_enabled=false,source_personal_enabled=false,source_imported_enabled=false}}
for _,name in ipairs({'Professions.lua','ProfessionModels.lua','ProfessionCalculations.lua','Database.lua','ConversionEngine.lua'})do assert(loadfile('LootLiquidator/'..name))('LL',LL)end
LL.CharacterKey=function()return 'Player'end
LL.GetResearchProfessionSnapshot=function()return 100,'1=1',1000 end
LL.GetCachedOperationInfo=function()end
LL.ProcessingMethodMode=function()return 1 end
local invalidations=0
LL.Invalidate=function(self)invalidations=invalidations+1;self._processingContextCache=nil;self._processingModelCache=nil end
local active,stacks=false,1
C_UnitAuras={GetPlayerAuraBySpellID=function(id)if id==5010 and active then return {spellId=id,applications=stacks}end end}
local function field(n)return{value=n,status='measured',confidence=90,samples=100}end
local source={recordID='buff-pipeline-fixture',studyID='fixture',source='Fixture',sourceKey='itemdb',method='Prospect',recipeID=4001,inputItemID=1001,inputCount=5,expansionID=10,fixedReference=true,referenceConditions={},materials={{id=2001,expectedQuantity=field(2),dropChance=field(.8),minQuantity=field(1),maxQuantity=field(3)}}}
local effect={entryID=8001,metric='yieldMultiplier',amount=20,unit='percent',confidence=90,scope={method='Prospect',profession='Jewelcrafting',expansionID=10},condition={requiresActiveBuff=true,spellIDs={5010},maxStacks=2}}
LL.ItemDB={schemaVersion=1,version='buff-pipeline',processing={source},mechanicRules={},professionProfiles={profiles={['Jewelcrafting:10']={statKeys={},nodes={[1]={maxRank=1,learningEffects={effect}}}}},recipes={},professionParameters={}}}
check(LL:InitializeItemDB(),LL.itemDBError or 'DB initialized');LL:MigrateEvidenceSettings()
LL.GetOutputPrice=function()return 100 end
local input={id=1001,expansionID=10,classID=7,reagentQuality=1,count=5}
local operation={name='Prospect',recipeID=4001,inputCount=5}
local function quote()return assert(LL:ResolveEvidenceModel(input,operation,nil,1))end
local base=quote();near(base.materials[1].expectedQuantity,2,'supported source quantity without buff')
near(LL:ValueProcessingModel(base,0,true,input),40,'source value per input')
local eventFrame
for _,frame in ipairs(frames)do if frame.events.UNIT_AURA then eventFrame=frame end end
check(eventFrame~=nil,'profession aura changes are subscribed')
LL:RefreshProfessionAuraFingerprint()
active=true
eventFrame.onEvent(eventFrame,'UNIT_AURA','target')
check(invalidations==0,'another unit does not invalidate player profile')
eventFrame.onEvent(eventFrame,'UNIT_AURA','player')
check(invalidations==1,'modeled aura gain invalidates quote immediately')
local buffed=quote();near(buffed.materials[1].expectedQuantity,2.4,'captured buff changes the resolved drop amount')
near(LL:ValueProcessingModel(buffed,0,true,input),48,'buff changes economic value through same model')
eventFrame.onEvent(eventFrame,'UNIT_AURA','player')
check(invalidations==1,'unchanged or unrelated aura update keeps cache')
stacks=2;eventFrame.onEvent(eventFrame,'UNIT_AURA','player')
check(invalidations==2,'stack changes invalidate the cached quote')
near(quote().materials[1].expectedQuantity,2.8,'native stacks apply declared multiplier once')
active=false;eventFrame.onEvent(eventFrame,'UNIT_AURA','player')
near(quote().materials[1].expectedQuantity,2,'aura expiration restores source amount without waiting for cache TTL')
near(source.materials[1].expectedQuantity.value,2,'source data is never rewritten')
local ctx={skill=100,preSpecializationSkill=100,specializationPoints={[1]=1},buffs={['5010']=true},buffStacks={['5010']=2}}
local f={id=1001,expansionID=10,classID=7}
local wrong=LL:ProfessionProfileParameters('Jewelcrafting',10,ctx,{name='Craft'},f)
near(wrong.outputFactor,1,'prospecting buff cannot affect unrelated craft')
effect.numericUnsupported=true
near(LL:ProfessionProfileParameters('Jewelcrafting',10,ctx,operation,f).outputFactor,1,'unsupported numeric effect cannot change drops')
effect.numericUnsupported=nil;effect.requiresSemanticReview=true
near(LL:ProfessionProfileParameters('Jewelcrafting',10,ctx,operation,f).outputFactor,1,'unresolved meaning cannot change drops')
effect.requiresSemanticReview=nil;effect.condition.contextFlags={deepNode=true}
ctx.effectStates={[8001]={active=true}}
near(LL:ProfessionProfileParameters('Jewelcrafting',10,ctx,{name='Craft'},f).outputFactor,1,'manual buff selection does not bypass the operation scope')
ctx.contextFlags={deepNode=true}
near(LL:ProfessionProfileParameters('Jewelcrafting',10,ctx,operation,f).outputFactor,1.2,'manual buff selection applies after all target conditions match')
-- Ratings without a native rating-percent pair must not create a guessed %.
local uncalibrated={skill=100,stats={resourcefulness={rating=100},multicraft={rating=100},ingenuity={percent=100}},concentrationCost=100}
local params=LL:ProfessionProfileParameters('Jewelcrafting',10,uncalibrated,{name='Craft'},f)
near(params.stats.resourcefulness,0,'uncalibrated rating does not become a guessed chance')
near(params.inputFactor,1,'missing savings coefficient cannot fabricate input savings')
near(params.outputFactor,1,'missing multicraft quantity coefficient cannot fabricate output')
check(params.expectedConcentrationCost==nil and params.stats.ingenuity==nil,
    'item processing omits concentration forecasts and Ingenuity projection')
-- Exercise an actual compiled native condition, not only the fixture rule.
-- The native operation rating/percent pair is mocked; the buff's identity,
-- +150 rating and native multicraft quantity coefficients are source data.
local metadata=assert(loadfile('database/profession-profile-rules.lua'))()
LL.ItemDB.professionProfiles=metadata
local nativeEffect
for _,milestone in ipairs(metadata.profiles['Engineering:10'].nodes[100842].milestones)do
 for _,e in ipairs(milestone.effects)do if e.entryID==124558 and e.metric=='multicraft' then nativeEffect=e end end
end
check(nativeEffect and nativeEffect.amount==150 and nativeEffect.unit=='rating','Ingenious native entry124558 grants150 multicraft rating')
check(nativeEffect.condition.spellIDs[1]==447312,'native Ingenious aura identity retained')
local realRecipe=metadata.recipes[447337]
check(realRecipe.profession=='Engineering' and realRecipe.expansionID==10,'actual Engineering reagent recipe scoped to TWW')
local realOp={name='Craft',recipeID=447337,inputCount=1}
local realInput={id=210937,expansionID=10,classID=7}
local realCtx={skill=100,preSpecializationSkill=100,specializationPoints={[100842]=15},stats={multicraft={rating=0,percent=0}},statCalibration={multicraft={rating=100,percent=10}},buffs={}}
local nativeAuraActive=false
C_UnitAuras.GetPlayerAuraBySpellID=function(id)if id==447312 and nativeAuraActive then return {spellId=id,applications=1}end end
realCtx.buffs=LL:ProfessionAuraState('Engineering',10,'Craft')
local unbuffed=LL:ProfessionProfileParameters('Engineering',10,realCtx,realOp,realInput)
nativeAuraActive=true;realCtx.buffs=LL:ProfessionAuraState('Engineering',10,'Craft')
check(realCtx.buffs['447312'],'actual compiled native aura is captured for matching profession')
local activated=LL:ProfessionProfileParameters('Engineering',10,realCtx,realOp,realInput)
near(activated.stats.multicraft-unbuffed.stats.multicraft,.15,'native150 rating uses captured operation ratio once')
local nativeParameters=metadata.professionParameters.Engineering
local extra=(nativeParameters.MinCraftExtraQtyPct+nativeParameters.MaxCraftExtraQtyPct)/200
near(activated.outputFactor-unbuffed.outputFactor,.15*extra,'real native buff and quantity coefficients change crafted output')
local realBaseline={inputCount=1,materials={{id=221856,expectedQuantity=2,confidence=90}},confidence=90}
local beforeBuff=LL:ProjectProfessionBaseline(realBaseline,unbuffed,realOp)
local afterBuff=LL:ProjectProfessionBaseline(realBaseline,activated,realOp)
near(afterBuff.materials[1].expectedQuantity-beforeBuff.materials[1].expectedQuantity,2*.15*extra,'actual native buff changes output through forward model')
check(LL:ValueProcessingModel(afterBuff,0,true,realInput)>LL:ValueProcessingModel(beforeBuff,0,true,realInput),'actual native buff changes valued result')
nativeAuraActive=false;realCtx.buffs=LL:ProfessionAuraState('Engineering',10,'Craft')
near(LL:ProfessionProfileParameters('Engineering',10,realCtx,realOp,realInput).outputFactor,unbuffed.outputFactor,'actual native aura removal restores output')
print('PASS: '..checks..' live aura, scoped native buff, drop/value pipeline and unsupported coefficient checks')
