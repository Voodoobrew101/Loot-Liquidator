-- Synthetic two-cast cohort in the native helper's exact output shape. Optional
-- argv[1] replays an actual helper-generated fixture instead of this specimen.
local checks=0
local function check(v,why)assert(v,why);checks=checks+1 end
local function eq(a,b,why)check(a==b,(why or '')..': '..tostring(a)..' ~= '..tostring(b))end
local function near(a,b,why)check(type(a)=='number'and math.abs(a-b)<1e-8,(why or '')..': '..tostring(a)..' ~= '..tostring(b))end
local function copy(v)if type(v)~='table'then return v end;local t={}for k,x in pairs(v)do t[k]=copy(x)end;return t end
local build='70961';GetBuildInfo=function()return'12.1.5',build end
GetTime=function()return 100 end
CreateFrame=function()return{RegisterEvent=function()end,SetScript=function()end}end
local profile={profession='Enchanting',skill=60,baseSkill=60,bonusSkill=30,effectiveSkill=90,skillLineID=2909,
 inputExpansionID=11,expansionID=11,specialization='none',specializationKnown=true,specializationPoints={},
 buffsKnown=true,buffs={},buffStacks={},operationStats={},profileKind='measured',simulated=false,
 fieldStatus={baseSkill='measured',bonusSkill='measured',effectiveSkill='measured',specialization='measured'}}
local function metric(value)return{value=value,status='measured',confidence=25,samples=1}end
local row={recordID='evidence:community:runtime-fixture',studyID='community:runtime-fixture',method='Disenchant',
 sourceKey='itemdb',source='https://github.com/Voodoobrew101/Loot-Liquidator/issues/123',
 sourceKind='reviewed-community-player-capture',inputItemID=250001,inputCount=1,inputClassID=4,inputRarity=4,expansionID=11,
 recipeID=13262,samples=1,observedOperations=2,sourceRecordIDs={'Cast-unique-1','Cast-unique-2'},
 sourceSHA256=string.rep('a',64),sourceReviewSHA256=string.rep('b',64),patchBuild='70961',targetBuild='70961',clientVersion='12.1.5',
 baselineProfile=copy(profile),communityMeasuredProfile=copy(profile),fixedReference=true,
 categoryItemLevelMin=300,categoryItemLevelMax=300,referenceContextID='community:runtime-fixture',referenceConditions={},
 materials={{id=240001,expectedQuantity=metric(1),dropChance=metric(.5),minQuantity=metric(2),maxQuantity=metric(2)}}}
if arg and arg[1]then row=assert(assert(loadfile(arg[1]))().processing[1]);profile=copy(row.communityMeasuredProfile)end
local function context()
 local c=copy(profile);c.character='Another - Realm';c.profileKind='live';c.simulated=false;return c
end
local ctx=context()
local option={name=row.method,profession=profile.profession,recipeID=row.recipeID,inputCount=row.inputCount}
local facts={id=row.inputItemID,classID=row.inputClassID,quality=row.inputRarity,expansionID=row.expansionID,
 itemLevel=row.categoryItemLevelMin,count=row.inputCount}
local LL={db={source_itemdb_enabled=true,source_personal_enabled=true,source_legacy_enabled=false,
 source_reference_enabled=false,source_imported_enabled=false,minPersonalSamples=1},
 ItemDB={schemaVersion=1,processing={row},mechanicRules={},version='community-runtime-fixture'}}
for _,name in ipairs({'ProfessionModels.lua','Database.lua','ConversionEngine.lua'})do
 assert(loadfile('LootLiquidator/'..name))('LL',LL)
end
LL.CharacterKey=function()return'Another - Realm'end
LL.ProcessingPlayerConditions=function()return ctx end
LL.GetOutputPrice=function()return 100 end
LL.ApplyGeneralProfessionModel=function()error('matched community evidence must never be scaled a second time')end
LL.ApplyProfessionModel=LL.ApplyGeneralProfessionModel;LL.ApplyVerifiedMechanics=LL.ApplyGeneralProfessionModel
check(LL:InitializeItemDB(),'valid helper-shaped community record initializes')
local function result(personal)return LL:ComputeEvidenceModel(facts,option,personal,1,ctx,true)end
local function uses(model,id)
 for _,material in ipairs(model and model.materials or {})do
  for _,estimate in pairs(material.sourceEstimates or {})do
   for _,r in ipairs(estimate.records or {})do if r.recordID==id then return true end end
  end
 end
 return false
end
local function assertMeasured(model)
 check(model,'matched measured profile supplies a numerical model')
 check(uses(model,row.recordID),'community source contributes')
 near(model.materials[1].expectedQuantity,row.materials[1].expectedQuantity.value,'source mean unchanged')
 near(model.materials[1].chance,row.materials[1].dropChance.value,'occurrence chance unchanged')
 near(LL:ValueProcessingModel(model,0,true,facts),row.materials[1].expectedQuantity.value*100/row.inputCount,
  'valuation uses expected units once')
 check(LL.db.craftResearch==nil,'another player needs no private source ledger')
end
assertMeasured(result())
for _,name in ipairs({'ApplyDisenchantBaseline','ApplyGeneralProfessionAdditions','ApplyGeneralProfessionQuality',
 'ApplySkillQualityModel','ApplySpecializationEffects'})do LL[name]=LL.ApplyGeneralProfessionModel end
local gated=0
LL.ApplyProfessionOutputGates=function(_,_,_,model)gated=gated+1;return model end
assertMeasured(LL:ResolveEvidenceModel(facts,option,nil,1))
eq(gated,1,'public model preserves captured quantities but still applies output access gates')
for _,change in ipairs({
 function(c)c.effectiveSkill=c.effectiveSkill+1 end,
 function(c)c.effectiveSkill=nil;c.skill=0;c.baseSkill=0 end,
 function(c)c.fieldStatus.effectiveSkill='unknown' end,
 function(c)c.specializationKnown=false;c.disenchantSpecializationKnown=false end,
 function(c)c.specializationPoints={['999']=1}end,
 function(c)c.learnedSpecializations={['999']=true}end,
 function(c)c.buffsKnown=false end,
 function(c)c.buffs={['555']=true};c.buffStacks={['555']=1}end,
 function(c)c.operationStats={{bonusStatName='Resourcefulness',rating=50}}end,
 function(c)c.stats={resourcefulness={rating=50,percent=5}}end,
 function(c)c.skillLineID=999 end})do
 ctx=context();change(ctx);eq(result(),nil,'different or unknown profile is not an assumed zero profile')
end
ctx=context();build='70962';eq(result(),nil,'another patch build cannot borrow a captured cohort');build='70961'
for _,change in ipairs({
 function(f)f.itemLevel=f.itemLevel+1 end,function(f)f.quality=3 end,
 function(f)f.classID=2 end,function(f)f.id=f.id+1 end,function(f)f.expansionID=10 end})do
 local old=copy(facts);change(facts);eq(result(),nil,'exact input variant scope is preserved');facts=old
end
ctx=context();ctx.effectiveSkill=0
local originalSkill=profile.effectiveSkill
row.communityMeasuredProfile.effectiveSkill=0;row.baselineProfile.effectiveSkill=0
assertMeasured(result())
ctx.effectiveSkill=nil;eq(result(),nil,'unknown target skill does not match a real measured zero')
row.communityMeasuredProfile.effectiveSkill=originalSkill;row.baselineProfile.effectiveSkill=originalSkill;ctx=context()
local function personal(ids)
 return {effectiveSamples=#ids,samples=#ids,operations=#ids,sourceRecordIDs=copy(ids),inputCount=row.inputCount,
  patchBuild=row.patchBuild,studyID='personal-cohort',observationContext=copy(ctx),referenceContextID=row.referenceContextID,
  materials={{id=row.materials[1].id,expectedQuantity=row.materials[1].expectedQuantity.value,
   chance=row.materials[1].dropChance.value,minQuantity=2,maxQuantity=2,samples=#ids}}}
end
local p=personal(row.sourceRecordIDs)
local sharedAndPersonal=assert(result(p))
check(not uses(sharedAndPersonal,row.recordID)and sharedAndPersonal.sources.personal,
 'same operations are counted once with personal tie preference')
check(sharedAndPersonal.communityMeasuredReference,'personal overlap winner retains the reviewed observed profile')
check(LL:ResolveEvidenceModel(facts,option,p,1),'public overlapping personal winner is not projected again')
local subset=personal({row.sourceRecordIDs[1]})
local subsetResult=assert(result(subset))
check(uses(subsetResult,row.recordID)and not subsetResult.sources.personal,'larger whole shared cohort excludes its personal subset')
local disjoint=personal({'new-independent-1','new-independent-2'})
local independent=assert(result(disjoint))
check(uses(independent,row.recordID),'independent personal observations never suppress the community cohort')
for _,reason in ipairs(independent.excludedSources or {})do
 check(not reason:find('operation overlap',1,true),'disjoint operations are not classified as duplicates')
end
-- Two overlapping approved rows are rejected from pooling even without local
-- personal data. Intake also rejects these; runtime must not double-weight them.
local duplicate=copy(row);duplicate.recordID=row.recordID..':duplicate';duplicate.studyID=row.studyID..':duplicate'
LL.ItemDB.processing={row,duplicate};check(LL:InitializeItemDB())
local deduped=assert(result())
eq((uses(deduped,row.recordID)and 1 or 0)+(uses(deduped,duplicate.recordID)and 1 or 0),1,
 'overlapping shared records contribute only one whole cohort')
-- The ordinary category is a fallback reference for a different source
-- profile. It must not be blended unscaled into the reviewed exact profile.
local category=copy(row)
category.recordID='ordinary-category';category.studyID='ordinary-category';category.inputItemID=nil
category.gearKey='gear:11:4:armor';category.isDisenchantCategory=true;category.categoryReferenceOnly=false
category.categoryItemLevelMin=1;category.categoryItemLevelMax=999
category.communityMeasuredProfile=nil;category.baselineProfile=nil;category.sourceKind='compiled-research'
category.referenceContextID='ordinary-canonical-profile'
category.materials={{id=row.materials[1].id,expectedQuantity=metric(3),dropChance=metric(1),minQuantity=metric(3),maxQuantity=metric(3)}}
LL.ApplyGeneralProfessionModel=nil;LL.ApplyProfessionModel=nil;LL.ApplyVerifiedMechanics=nil
LL.ItemDB.processing={category,row};check(LL:InitializeItemDB())
assertMeasured(result())
ctx.effectiveSkill=ctx.effectiveSkill+1
local fallback=assert(result())
check(not uses(fallback,row.recordID)and uses(fallback,category.recordID),'ordinary references survive a community profile mismatch')
near(fallback.materials[1].expectedQuantity,3,'mismatched community evidence cannot change the fallback')
ctx=context()
local rareID=row.materials[1].id+1
category.materials[#category.materials+1]={id=rareID,expectedQuantity=metric(.02),dropChance=metric(.01),
 minQuantity=metric(2),maxQuantity=metric(2)}
LL.ItemDB.processing={category,row};check(LL:InitializeItemDB())
local rareModel=assert(result())
local rareMaterial
for _,m in ipairs(rareModel.materials)do if m.id==rareID then rareMaterial=m end end
check(rareMaterial and rareMaterial.communityPossibleOutput,'an unseen ordinary cooutput remains possible')
eq(rareMaterial.expectedQuantity,nil,'a missing community observation never proves zero units')
eq(rareMaterial.chance,nil,'a missing community observation never proves zero occurrence chance')
eq(rareMaterial.minQuantity,nil);eq(rareMaterial.maxQuantity,nil)
check(rareModel.unknownOutputs and rareModel.communityOutputCoverageUnknown,'unseen cooutputs mark coverage incomplete')
near(LL:ValueProcessingModel(rareModel,0,true,facts),row.materials[1].expectedQuantity.value*100,
 'the existing partial lower bound values only known observed units')
check(rareModel.partial and rareModel.partialPrice,'existing lower-bound semantics remain explicitly partial')
check(rareModel.communityOutputCoverageReason:find('known outputs only',1,true),'coverage limitation is explained')
row.communityNonEconomicOutputItemIDs={rareID}
LL.ItemDB.processing={category,row};check(LL:InitializeItemDB())
local excludedReward=assert(result())
for _,m in ipairs(excludedReward.materials)do check(m.id~=rareID,'reviewed non-economic rewards are not economic unknowns')end
check(not excludedReward.unknownOutputs,'proven non-economic reward does not make saleable yields incomplete')
row.communityNonEconomicOutputItemIDs=nil
ctx=context();LL.ApplyGeneralProfessionModel=function()error('matched community evidence must never be scaled a second time')end
LL.ApplyProfessionModel=LL.ApplyGeneralProfessionModel;LL.ApplyVerifiedMechanics=LL.ApplyGeneralProfessionModel
for _,change in ipairs({
 function(r)r.communityMeasuredProfile.effectiveSkill=nil end,
 function(r)r.communityMeasuredProfile.fieldStatus.effectiveSkill='unknown' end,
 function(r)r.sourceRecordIDs={'repeated','repeated'}end,
 function(r)r.targetBuild='70962'end,
 function(r)r.sourceSHA256='unverified'end,
 function(r)r.categoryItemLevelMax=r.categoryItemLevelMin+1 end})do
 local broken=copy(row);change(broken)
 check(not LL:ValidateItemDB({schemaVersion=1,processing={broken}}),'malformed community admission fails validation')
end
-- Typed operation stats, including an explicitly measured empty stat list,
-- are required for non-DE cohorts; absent stats must never become zero stats.
local nonDE=copy(row)
nonDE.recordID=nonDE.recordID..':prospect';nonDE.method='Prospect';nonDE.recipeID=1231127;nonDE.inputCount=5
nonDE.categoryItemLevelMin=nil;nonDE.categoryItemLevelMax=nil;nonDE.inputClassID=nil;nonDE.inputRarity=nil
for _,c in ipairs({nonDE.communityMeasuredProfile,nonDE.baselineProfile})do
 c.profession='Jewelcrafting';c.skillLineID=2901;c.operationStats={};c.fieldStatus.operationStats='measured'
end
check(LL:ValidateItemDB({schemaVersion=1,processing={nonDE}}),'measured empty stats remain known zero, not unknown')
row=nonDE;profile=copy(row.communityMeasuredProfile);ctx=context()
facts={id=row.inputItemID,expansionID=11,count=5};option={name='Prospect',recipeID=row.recipeID,inputCount=5}
LL.ItemDB.processing={row};check(LL:InitializeItemDB())
assertMeasured(result());assertMeasured(LL:ResolveEvidenceModel(facts,option,nil,1))
ctx.operationStats=nil
eq(result(),nil,'unknown target processing stats cannot match measured empty source stats')
ctx.operationStats={{bonusStatName='Resourcefulness',ratingPct=10}}
eq(result(),nil,'different target processing stats do not borrow the source quantity')
local unknownStats=copy(row)
unknownStats.communityMeasuredProfile.operationStats=nil;unknownStats.baselineProfile.operationStats=nil
check(not LL:ValidateItemDB({schemaVersion=1,processing={unknownStats}}),'unknown source processing stats are not zero')
-- The actual tooltip must disclose the partial estimate, and its display-only
-- fallback must not turn the unobserved rare output into a guessed quantity.
assert(loadfile('LootLiquidator/Badges.lua'))('LL',LL)
LL.MarkupColor=function()return ''end
LL.Money=function(_,amount)return tostring(amount)..' copper'end
LL.db.tooltipDetail=3;LL.db.tooltipOutputSort='database'
local display=LL:TooltipMaterialDisplayFields(rareMaterial,rareModel,{name='Disenchant',inputCount=1},facts)
check(display.tooltipUnknownChance and display.tooltipUnknownRange,'community unknown remains visibly unknown')
eq(display.chance,nil);eq(display.expectedQuantity,nil)
local left,right=LL:FormatTooltipMaterialRow(rareMaterial,rareModel,{name='Disenchant',inputCount=1})
check(left:find('?%',1,true)and left:find('[?]',1,true),'unknown rare output shows question marks, not fabricated zero')
eq(right,'','unobserved rare output has no gold figure')
local tip={lines={},rows={}}
function tip:AddLine(text)self.lines[#self.lines+1]=text end
function tip:AddDoubleLine(label,price)self.rows[#self.rows+1]={label,price}end
LL:AppendRecommendationTooltip(tip,{action='D',facts={id=250001,classID=4},conversionOptions={
 {name='Disenchant',letter='D',value=rareModel.value,available=true,partial=true,yieldModel=rareModel}}})
check(tip.rows[1][1]:find('partial estimate',1,true),'tooltip option labels its partial value')
local explained=false
for _,line in ipairs(tip.lines)do if line:find('known outputs only',1,true)then explained=true end end
check(explained,'tooltip explains the missing-cooutput coverage')
print('PASS: '..checks..' community source/profile/build/variant, unchanged numeric yield and operation-overlap assertions')
