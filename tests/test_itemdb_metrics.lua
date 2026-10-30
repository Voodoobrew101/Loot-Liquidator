-- ItemDB-only end-to-end operation identity, quantities, valuation and tooltip.
local LL={}
CreateFrame=function()return {RegisterEvent=function()end,SetScript=function()end}end
GetBuildInfo=function()return '12.1.5','123456','Oct 29 2026',120105 end
GetTime=function()return 100 end
for _,file in ipairs({'ItemDBRuntime.lua','itemTSM.lua','GameData.lua','ProfessionModels.lua',
    'Database.lua','ConversionEngine.lua','Badges.lua'}) do
    assert(loadfile('LootLiquidator/'..file))('LootLiquidator',LL)
end
LL.db={source_itemdb_enabled=true,source_itemdb_weight=100,source_itemtsm_enabled=false,
    source_personal_enabled=false,source_legacy_enabled=false,processingModes={M=1,P=1,S=1},
    tooltipDetail=3,showTooltips=true,showMaterialBreakdown=true}
LL:MigrateEvidenceSettings()
LL.CanUseConversion=function()return true,nil,'Tester - Realm'end
LL.ProfessionForMethod=function(_,method)return ({Mill='Inscription',Prospect='Jewelcrafting',Smelt='Mining'})[method]end
LL.ProcessingPlayerConditions=function()return {skill=100,effectiveSkill=100}end
LL.EligibleDisenchant=function()return false end
LL.GetOutputPrice=function()return 100 end
LL.MarkupColor=function()return '|cffffffff'end
LL.Money=function(_,value)return tostring(value)end
LL.ProfessionProgression=function()return {}end
local function near(a,b)assert(type(a)=='number' and math.abs(a-b)<1e-9,tostring(a)..' ~= '..tostring(b))end
local function render(f,option)
    local tip={lines={}}
    function tip:AddLine(s)self.lines[#self.lines+1]=s end
    function tip:AddDoubleLine(a,b)self.lines[#self.lines+1]=a..' '..b end
    LL:AppendRecommendationTooltip(tip,{action=option.letter,facts=f,conversionOptions={option},count=f.count})
    return table.concat(tip.lines,'\n')
end
-- Actual shipped BFA research uses mass-milling recipes, despite the old
-- compatibility hints saying five herbs. Match the complete operation.
for _,case in ipairs({{152506,256218,15.48},{152507,256223,16.39},{152508,256221,15.89}}) do
    local f={id=case[1],classID=7,expansionID=7,count=20}
    local options=LL:ConversionOptions(f)
    assert(#options==1 and options[1].recipeID==case[2] and options[1].inputCount==20)
    local model=assert(options[1].yieldModel)
    assert(model.inputCount==20 and #model.materials==3)
    local total=0
    for _,m in ipairs(model.materials)do
        assert(m.chance==nil and m.minQuantity==nil and m.maxQuantity==nil,'missing empirical fields must stay unknown')
        if m.id==153635 then near(m.expectedQuantity,case[3])end
        total=total+m.expectedQuantity*100
    end
    near(options[1].value,total/20)
    local text=render(f,options[1])
    assert(text:find('Per 20 input(s)',1,true) and text:find('[range ?]',1,true))
    f.count=5
    options=LL:ConversionOptions(f)
    assert(not options[1].available and options[1].inputShort and options[1].inputCount==20)
    assert(options[1].yieldModel.inputCount==20,'a short bag stack must not change operation units')
end
-- Synthetic full four-field record: P is occurrence per operation, min/max
-- are conditional positive counts, E includes zeros. Price uses E once.
local function field(value,status)return {value=value,status=status or 'measured',confidence=80}end
local material={id=900010,dropChance=field(.5),minQuantity=field(10),maxQuantity=field(20),expectedQuantity=field(8)}
local row={recordID='synthetic:mass',method='Mill',profession='Inscription',inputItemID=900001,inputCount=20,
    recipeID=900002,sourceKey='itemdb',studyID='synthetic',source='synthetic fixture',referenceContextID='fixture',
    referenceConditions={},samples=100,expansionID=7,materials={material}}
LL.ItemDB={schemaVersion=1,processing={row},mechanicRules={},inputs={[900001]={method='Mill',batch=5,expansion=7}}}
local f={id=900001,classID=7,expansionID=7,count=20}
local function option()
    assert(LL:InitializeItemDB())
    local options=LL:ConversionOptions(f)
    assert(#options==1 and options[1].recipeID==900002 and options[1].inputCount==20)
    return options[1]
end
local chosen=option()
near(chosen.yieldModel.materials[1].chance,.5)
assert(chosen.yieldModel.materials[1].minQuantity==10 and chosen.yieldModel.materials[1].maxQuantity==20)
near(chosen.yieldModel.materials[1].expectedQuantity,8)
near(chosen.value,40) -- 8 units * 100 copper / 20 inputs, without another P factor
local text=render(f,chosen)
assert(text:find('50%',1,true) and text:find('[x10-20]',1,true) and text:find('EV 8.000',1,true))
material.dropChance.status='provisional'
assert(render(f,option()):find('~50%',1,true),'provisional probabilities need an approximation marker')
material.dropChance=field(nil,'unknown');material.minQuantity=field(nil,'unknown');material.maxQuantity=field(nil,'unknown')
text=render(f,option());assert(text:find('[range ?]',1,true) and not text:find('50%',1,true))
material.dropChance=field(1e-7);material.expectedQuantity=field(1e-7)
material.minQuantity=field(1);material.maxQuantity=field(1)
text=render(f,option())
assert(text:find('<0.1%',1,true) and text:find('EV <0.001',1,true),'positive values must not display as zero')
material.dropChance.value=.999999;material.expectedQuantity.value=.999999
assert(render(f,option()):find('>99.9%',1,true),'near-certain is not 100%')
material.dropChance.value=1;material.expectedQuantity.value=1
assert(render(f,option()):find('100%',1,true))
material.dropChance.value=0;material.expectedQuantity.value=0
chosen=option();near(chosen.value,0)
text=render(f,chosen);assert(text:find('0%',1,true) and text:find('EV 0.000',1,true))
-- Operation discovery does not admit disabled evidence or bypass recipe access.
LL.db.source_itemdb_enabled=false
local disabled=option();assert(disabled.value==nil)
assert(render(f,disabled):find('Insufficient Data',1,true),'known operations need an explanation even when yields are unavailable')
LL.db.source_itemdb_enabled=true
LL.CanUseConversion=function()return false,'Recipe not learned'end
assert(not option().available)
-- Exact-item disenchant research has its own evaluator. An input hint must
-- not create a second generic destroy option or index the Mill/Prospect spells.
LL.CanUseConversion=function()return true,nil,'Tester - Realm'end
LL.EligibleDisenchant=function()return true end
LL.DisenchantExpansion=function(_,facts)return facts.expansionID end
LL.CurrentHasEnchanting=function()return true end
LL.DisenchantEstimate=LL.EvaluateDisenchant -- normal Core delegation
row.method='Disenchant';row.recipeID=13262;row.profession='Enchanting';row.inputCount=1
LL.ItemDB.inputs[900001]={method='Disenchant',batch=1,expansion=7}
material.dropChance.value=.5;material.expectedQuantity.value=8
material.minQuantity.value=10;material.maxQuantity.value=20
f.classID=4;f.quality=4
assert(LL:InitializeItemDB())
local de=LL:ConversionOptions(f)
assert(#de==1 and de[1].name=='Disenchant' and de[1].yieldModel)
near(de[1].yieldModel.materials[1].chance,.5)
assert(de[1].yieldModel.materials[1].minQuantity==10)
near(de[1].value,800)
-- Retired manual modifiers cannot alter ItemDB metrics.
LL.db.researchSkillTolerance=40;LL.db.skillAwareProcessing=false
LL.db.midnightDisenchantUpgradePct=100;LL.db.dragonflightProspectingInspirationPct=100
LL.db.warWithinMillingOutputRank=3
LL._processingModelCache=nil
local stable=LL:ConversionOptions(f)[1]
near(stable.value,800);near(stable.yieldModel.materials[1].chance,.5)
-- DE reuses one complete personal estimate. Only a source that contributes
-- to the final model can supply the displayed sample count.
local profile={skill=100,effectiveSkill=100,character='Tester - Realm'}
LL.CharacterKey=function()return 'Tester - Realm'end
LL.ProcessingPlayerConditions=function()return profile end
LL.ProcessingDataMode=function()return LL.db.disenchantDataMode end
LL.db.source_personal_enabled=true;LL.db.source_personal_weight=100
LL.db.disenchantDataMode=2
local reads=0
LL.GetLearnedDisenchantEstimate=function()
    reads=reads+1
    return {inputCount=1,samples=7,effectiveSamples=7,patchBuild='123456',
        observationContext=profile,materials={{id=900010,expectedQuantity=1,chance=.5,minQuantity=1,maxQuantity=4}}}
end
LL._processingModelCache=nil
local measured=LL:ConversionOptions(f)[1]
assert(reads==1,'DE must not re-query an old personal aggregation path')
assert(measured.yieldModel.personalStats.total==7 and measured.estimate.samples==7)
near(measured.yieldModel.materials[1].expectedQuantity,1)
LL.db.disenchantDataMode=3;LL._processingModelCache=nil
local external=LL:ConversionOptions(f)[1]
assert(external.yieldModel.personalStats==nil and external.estimate.samples==nil,
    'ItemDB-only tooltip must not show personal samples')
near(external.yieldModel.materials[1].expectedQuantity,8)
print('PASS: ItemDB-only real mass-milling recipes, all four metric units, source/access gates, conditional ranges, unknowns and probability/yield precision')
