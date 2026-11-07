local LL={}
CreateFrame=function()return {RegisterEvent=function()end,SetScript=function()end}end
for _,name in ipairs({'ItemDBRuntime.lua','ProfessionModels.lua','Database.lua','Professions.lua','CraftRecording.lua','ImportedResults.lua','ConversionEngine.lua','BuildInfo.lua'})do
    assert(loadfile('LootLiquidator/'..name))('LL',LL)
end
LL.db={};assert(LL:InitializeItemDB())
local records,contexts,studies={},{},{}
for i=1,13 do
    local f=assert(io.open(('research/integration/measured-captures/2026-11-07-recycling-200-casts/export-page-%02d.json'):format(i),'r'))
    local p=assert(LL.DecodeImportJSON(f:read('*a')));f:close()
    for _,r in ipairs(p.records)do records[#records+1]=r end
    for k,v in pairs(p.contexts)do contexts[k]=v end
    for k,v in pairs(p.studies)do studies[k]=v end
end
LL.db.craftResearch={records=records,contexts=contexts,studies=studies}
local total,outputs,seen=0,0,{}
local first
for _,r in ipairs(records)do if r.method=='Recycle' and not seen[r.contextID] then
    first=first or r;seen[r.contextID]=true
    local b=assert(LL:CraftBaseline(r.studyID,r.contextID,r.recipeID))
    total=total+b.operations;outputs=outputs+b.operations*b.materials[1].expectedQuantity
end end
assert(total==200 and math.abs(outputs-421)<1e-9,'native baselines restore the actual 200 casts')
GetBuildInfo=function()return '12.1.5','70783' end
LL:MigrateEvidenceSettings()
local ctx={} for k,v in pairs(contexts[first.contextID])do ctx[k]=v end
ctx.inputQuality=1
ctx.zeroOperationStats=true;ctx.operationStatCount=#ctx.operationStats
local f={id=245807,expansionID=11,reagentQuality=1,quality=1,classID=7,count=5}
local option={name='Recycle',recipeID=1229930,inputCount=5}
local model,why=LL:ComputeEvidenceModel(f,option,nil,3,ctx)
assert(model,why)
assert(math.abs(model.materials[1].expectedQuantity-2)<1e-9,'shared ItemDB supplies the measured skill-21 mean')
LL.GetOutputPrice=function()return 100 end
assert(math.abs(LL:ValueProcessingModel(model,0,true,f)-40)<1e-9,'measured two per five inputs reaches the gold pipeline')
ctx.effectiveSkill=99;ctx.baseSkill=99
assert(not LL:ComputeEvidenceModel(f,option,nil,3,ctx),'no extrapolation to unmeasured skill')
ctx.effectiveSkill=21;ctx.baseSkill=21;ctx.bonusSkill=40
assert(not LL:ComputeEvidenceModel(f,option,nil,3,ctx),'a changed bonus cannot borrow zero-bonus measurements')
LL.CharacterKey=function()return 'Test' end
LL.db.characters={Test={professions={Engineering=true}}}
LL.GetResearchProfessionSnapshot=function()return 21,'none',2910 end
local stats={
    {bonusStatName='Statistique locale A',ratingDescription='Texte traduit',bonusStatValue=0,ratingPct=0,bonusRatingPct=0},
    {bonusStatName='Statistique locale B',ratingDescription='Autre texte',bonusStatValue=0,ratingPct=0,bonusRatingPct=0}}
LL.GetCachedOperationInfo=function()return {baseSkill=21,bonusSkill=0,bonusStats=stats} end
local native=LL:ProcessingPlayerConditions(f,'Recycle',1229930)
assert(native.zeroOperationStats and native.operationStatCount==2)
assert(LL:ComputeEvidenceModel(f,option,nil,3,native),'localization cannot conceal the measured zero-stat cohort')
stats[1].bonusStatValue=20;LL._processingContextCache={}
native=LL:ProcessingPlayerConditions(f,'Recycle',1229930)
assert(not LL:ComputeEvidenceModel(f,option,nil,3,native),'nonzero stats cannot reuse the zero-stat cohort')
local study=studies[first.studyID]
study.coverageVersion=2;study.coverageGaps={['Craft:1229866']={reason='missing'}}
assert(LL:CraftBaseline(first.studyID,first.contextID,first.recipeID),'unrelated recipe cannot censor Recycling')
study.coverageGaps['Recycle:1229930']={reason='missing'}
assert(not LL:CraftBaseline(first.studyID,first.contextID,first.recipeID),'same recipe gap must block its denominator')
study.coverageGaps['Recycle:1229930']=nil;study.globalCoverageGap='Unclosed recording session'
assert(not LL:CraftBaseline(first.studyID,first.contextID,first.recipeID),'session-wide uncertainty stays blocked')
LL.buildInfo={kind='main',branch='main',commit='abc',prs={}}
local a,b=LL:BuildSummary();assert(a=='Main branch build' and b=='PRs beyond main: none')
LL.buildInfo={kind='pr',branch='fix/recycling',commit='abc',prs={{number=49,title='Recycling',url='url'}}}
a,b=LL:BuildSummary();assert(a=='Pull request build' and b=='PRs: #49')
assert(LL:BuildDetails():find('Branch: fix/recycling',1,true))
print('PASS: native 200-cast coverage restoration, recipe isolation, global gaps and build provenance labels')
