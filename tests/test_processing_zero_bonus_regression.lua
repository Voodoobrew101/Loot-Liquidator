-- Real ItemDB/selector/bonus/renderer regression for the three reported inputs.
-- Set REPRO_ADDON_ROOT and REPRO_DIAGNOSTIC_ONLY for read-only installed-build audit.
local root=REPRO_ADDON_ROOT or 'LootLiquidator'
local checks=0
local function check(v,why) assert(v,why);checks=checks+1 end
local function clone(x) if type(x)~='table' then return x end local y={} for k,v in pairs(x) do y[k]=clone(v) end return y end
GetBuildInfo=function() return '12.1.5','70961' end
GetTime=function() return 100 end
time=function() return 1795219200 end
CreateFrame=function() return {RegisterEvent=function()end,SetScript=function()end} end
local db=LOOT_REPRO_DB or {characters={Player={}},source_itemdb_weight=81,source_personal_weight=65,source_imported_weight=25,
    tooltipDetail=3,showAverageQuantity=false,showExpectedMaterialValues=true}
db=clone(db)
local LL={db=db}
for _,file in ipairs({'ItemDBRuntime.lua','Professions.lua','ProfessionModels.lua','ProfessionCalculations.lua',
    'Observations.lua','Database.lua','ConversionEngine.lua','Badges.lua'}) do
    local path=root..'/'..file
    local exists=io.open(path,'r')
    if exists then exists:close();assert(loadfile(path))('LL',LL) end
end
LL.CharacterKey=function() return 'Player' end
LL.CanUseConversion=function() return false,'Offline native access not asserted','Current character' end
LL.EligibleDisenchant=function() return false end
LL.MarkupColor=function() return '' end
LL.Money=function(_,value) return string.format('%.10g copper',value) end
LL.ProfessionProgression=function() return {} end
LL.TooltipConversionOptions=nil
LL.GetOutputPrice=function(self,id)
    local items=self.ItemDB.professionProfiles and self.ItemDB.professionProfiles.items or {}
    local item=items[id] or items[tostring(id)] or {}
    return (item.qualityRank or 1)*100,'Fixed synthetic price by native rank'
end
LL:MigrateEvidenceSettings()
check(LL:InitializeItemDB(),LL.itemDBError)
local hooks={'ApplyGeneralProfessionModel','ApplyGeneralProfessionAdditions','ApplyGeneralProfessionQuality','ApplySkillQualityModel','ApplySpecializationEffects','ApplySyntheticBenchmark'}
local original={} for _,key in ipairs(hooks) do original[key]=LL[key] end
local function context(f,method,_,_,profession)
    local prof=profession or (method=='Prospect' and 'Jewelcrafting' or 'Inscription')
    return {character='Player',profession=prof,expansionID=11,inputID=f.id,inputQuality=f.reagentQuality,
        inputRarity=f.quality,inputClassID=f.classID,skill=0,effectiveSkill=0,preSpecializationSkill=0,
        simulated=true,profileKind='manual-simulation',specializationKnown=true,specializationEncoding='invested-points',
        specializationPoints={},learnedSpecializations={},stats={},buffs={},buffsKnown=true,
        benchmark={outputLevel=100,specializationBonus=0,resourcefulnessChance=0,resourcefulnessSaved=0}}
end
LL.ProcessingPlayerConditions=context
local function plain(model)
    if not model then return nil end
    local x={}
    for _,key in ipairs({'confidence','valueConfidence','value','partial','partialPrice','adjustment','referenceContextID','skillQualityApplied',
        'skillQualityUnavailable','skillQualityIssue','generalProfessionApplied','generalQualityApplied','syntheticBenchmark','benchmarkOutputFactor'}) do x[key]=model[key] end
    x.materials={}
    for _,m in ipairs(model.materials or {}) do
        local z={}
        for _,key in ipairs({'id','rankIDs','expectedQuantity','chance','minQuantity','maxQuantity','confidence','netExpectedValue','netUnitPrice',
            'sourceContributions','sourceEstimates','unprojectedQualityExpectedQuantity'}) do z[key]=clone(m[key]) end
        x.materials[#x.materials+1]=z
    end
    return x
end
local function run(f,scenario)
    for _,key in ipairs(hooks) do
        if scenario=='source_only' then LL[key]=nil else LL[key]=original[key] end
    end
    LL.ProcessingPlayerConditions=function(...)
        local c=context(...)
        if scenario=='benchmark20' then c.benchmark.specializationBonus=20 end
        local skill=tonumber(scenario:match('^skill(%d+)$'))
        if skill then c.skill=skill;c.effectiveSkill=skill;c.preSpecializationSkill=skill end
        return c
    end
    LL._processingModelCache=nil;LL._processingContextCache={}
    local chosen
    for _,q in ipairs(LL:ConversionOptions(f)) do if q.name==(f.id==237365 and 'Prospect' or 'Mill') and q.inputCount==(f.id==237365 and 5 or 10) then chosen=q;break end end
    if not chosen then return {missingQuote=true} end
    local t={lines={}}
    function t:AddLine(s) self.lines[#self.lines+1]=s end
    function t:AddDoubleLine(a,b) self.lines[#self.lines+1]=a..' | '..b end
    LL:AppendRecommendationTooltip(t,{action='A',facts=f,conversionOptions={chosen}})
    return {value=chosen.value,confidence=chosen.confidence,inputCount=chosen.inputCount,recipeID=chosen.recipeID,
        source=chosen.source,partial=chosen.partial,model=plain(chosen.yieldModel),tooltip=table.concat(t.lines,'\n')}
end
PROCESSING_REPRO={inputs={}}
for _,entry in ipairs({{237365,2},{236777,2},{236770,1}}) do
    local f={id=entry[1],classID=7,quality=1,expansionID=11,reagentQuality=entry[2],count=100,
        link='item:'..entry[1],name='Input '..entry[1],context={verifiedUnbound=true}}
    local result={id=f.id}
    for _,scenario in ipairs({'source_only','zero_bonus','benchmark20','skill1','skill25','skill50','skill100','skill500'}) do result[scenario]=run(f,scenario) end
    PROCESSING_REPRO.inputs[#PROCESSING_REPRO.inputs+1]=result
    if not REPRO_DIAGNOSTIC_ONLY then
        local a,b=result.source_only,result.zero_bonus
        check(a.model and b.model,'baseline and zero-bonus quote exist')
        local means={}
        for _,m in ipairs(a.model.materials) do means[m.id]=(means[m.id] or 0)+(m.expectedQuantity or 0) end
        for _,m in ipairs(b.model.materials) do
            check(math.abs((means[m.id] or 0)-(m.expectedQuantity or 0))<1e-8,'zero bonus preserves material '..m.id..' for input '..f.id)
            means[m.id]=nil
        end
        for _,amount in pairs(means) do check(math.abs(amount)<1e-8,'zero bonus cannot silently remove a source rank') end
        check(math.abs(a.value-b.value)<1e-8,'zero bonus preserves baseline EV '..f.id)
        check(a.confidence==b.confidence,'zero bonus preserves source confidence '..f.id)
        for _,scenario in ipairs({'skill1','skill25','skill50','skill100','skill500'}) do
            check(result[scenario].value>=a.value-1e-8,'positive skill cannot downgrade an identified baseline rank '..f.id..' '..scenario)
        end
        local c=result.benchmark20
        check(math.abs(c.value-b.value*1.2)<1e-8,'benchmark applies once to EV '..f.id)
    end
end
PROCESSING_REPRO.checks=checks
if not REPRO_DIAGNOSTIC_ONLY then print('PROCESSING ZERO BONUS REGRESSION: '..checks..' checks passed') end

