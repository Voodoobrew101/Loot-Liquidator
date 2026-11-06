-- Synthetic formulas verify the UI-to-engine contract, not real WoW yields.
local LL={db={characters={Player={professions={Inscription=true},recipes={[100]={learned=true}}}}}}
GetTime=function()return 100 end
time=function()return 100 end
GetBuildInfo=function()return 'test','200' end
CreateFrame=function()return {RegisterEvent=function()end,SetScript=function()end}end
for _,name in ipairs({'Professions.lua','ProfessionModels.lua','Database.lua','ConversionEngine.lua','Badges.lua'}) do
    assert(loadfile('LootLiquidator/'..name))('LL',LL)
end
LL.CharacterKey=function()return 'Player'end
LL.GetResearchProfessionSnapshot=function()return 10,'none'end
LL.GetCachedOperationInfo=function()end
LL.GetOutputPrice=function()return 100 end
LL.AHFeeRate=function()return 0 end
LL.EligibleDisenchant=function()return false end
LL.ProfessionProgression=function()return {}end
LL.Money=function(_,n)return tostring(n)..' copper'end
LL.MarkupColor=function()return ''end
local function field(v)return {value=v,status='measured',confidence=90}end
local rule={ruleID='synthetic',method='Mill',recipeID=100,inputItemID=1,outputItemID=10,
    expansionID=9,build='200',referenceProfile={effectiveSkill=0,specialization='none'},
    skillFactors={{skill=0,factor=1},{skill=100,factor=2}},
    evidenceStatus='VERIFIED_NUMERIC',applyPolicy='EXECUTE',numericTransformValidated=true,
    independentReview='APPROVED',confidence0to100=94,sourceClaimIDs={'synthetic-a','synthetic-b'}}
LL.ItemDB={schemaVersion=1,version='synthetic',mechanicRules={},professionRules={rule},
    processing={{recordID='synthetic',studyID='synthetic',sourceKey='itemdb',method='Mill',recipeID=100,inputItemID=1,
        inputCount=5,expansionID=9,patchBuild='200',baselineProfile=rule.referenceProfile,
        samples=100,source='synthetic',materials={{id=10,expectedQuantity=field(2),dropChance=field(1),
            minQuantity=field(2),maxQuantity=field(2)}}}}}
assert(LL:InitializeItemDB());LL:MigrateEvidenceSettings()
LL.db.tooltipDetail=3;LL.db.professionTooltipProfiles={Inscription='@hypothetical'}
LL.Invalidate=function(self)self._processingContextCache=nil;self._processingModelCache=nil end
local f={id=1,classID=7,expansionID=9,count=5,context={}}
local option={name='Mill',recipeID=100,inputCount=5}
local original=LL:ConversionOptions(f)
local function profile(skill,stats)
    assert(LL:SetManualProfessionProfile('Player','Inscription',9,{enabled=true,skill=skill,specialization='none',stats=stats}))
end
profile(0)
local low=LL:TooltipConversionOptions(f,original)[1]
profile(100)
local high=LL:TooltipConversionOptions(f,original)[1]
assert(low.value==40 and high.value==80,'selected skill reaches actual resolver and valuation')
assert(low.available==false and high.available==false,'simulation cannot grant access')
local function render(quote)
    local tip={lines={}}
    function tip:AddLine(s)self.lines[#self.lines+1]=s end
    function tip:AddDoubleLine(a,b)self.lines[#self.lines+1]=a..' | '..b end
    LL.db.professionTooltipProfiles={}
    LL:AppendRecommendationTooltip(tip,{action='A',rawAuction=1,netAuction=1,facts=f,conversionOptions={quote}})
    LL.db.professionTooltipProfiles={Inscription='@hypothetical'}
    return table.concat(tip.lines,'\n')
end
-- Rendering a synthetic reference quote needs the same explicit display opt-in.
local tip={lines={}}
function tip:AddLine(s)self.lines[#self.lines+1]=s end
function tip:AddDoubleLine(a,b)self.lines[#self.lines+1]=a..' | '..b end
profile(0)
LL:AppendRecommendationTooltip(tip,{action='A',rawAuction=1,netAuction=1,facts=f,conversionOptions=original})
local text=table.concat(tip.lines,'\n')
assert(text:find('Simulated',1,true) and text:find('40 copper',1,true))
assert(text:find('Next researched skill breakpoint: 100 (+100 skill)',1,true))
LL.db.showProfessionThresholds=false
tip.lines={};LL:AppendRecommendationTooltip(tip,{action='A',rawAuction=1,netAuction=1,facts=f,conversionOptions=original})
assert(not table.concat(tip.lines,'\n'):find('Next researched',1,true))
local other={id=2,classID=7,expansionID=9}
assert(not table.concat(LL:ProfessionThresholdNotes(other,option,{effectiveSkill=0}),';'):find('100',1,true),'no cross-item threshold leak')
profile(100,{resourcefulness={rating=250,percent=12.5}})
local ctx=LL:TooltipConversionOptions(f,original)[1].yieldModel.context
assert(ctx.operationStats[1].bonusStatValue==250 and ctx.operationStats[1].ratingPct==12.5)
assert(ctx.simulated and LL.db.characters.Player.researchProfiles==nil)
assert(not LL:SetManualProfessionProfile('Player','Inscription',9,{stats={resourcefulness={percent=0/0}}}))
assert(not LL:SetManualProfessionProfile('Player','Inscription',9,{stats={resourcefulness={percent=101}}}))
local n={id=2,name='Child',maxRank=30,requirements={{kind='node',nodeID=1,rank=10,name='Parent'}},
    milestones={{rank=15,description='A sourced milestone'}}}
assert(LL:ProfessionNodeRequirements(n,{['1']=9},100)==false)
assert(LL:ProfessionNodeRequirements(n,{['1']=10},100)==true)
assert(table.concat(LL:ProfessionNodeTooltip(n,0,{['1']=0},100),'\n'):find('Requires 10 points in Parent',1,true))
assert(table.concat(LL:ProfessionNodeTooltip(n,0,{['1']=10},100),'\n'):find('At 15 points',1,true))
n.requirementsKnown=false;n.requirements=nil
assert(LL:ProfessionNodeRequirements(n,{},100)==nil,'unknown requirements are not certified unlocked')
LL:CaptureProfessionOperation(100,{}) -- absent Blizzard API is harmless
C_TradeSkillUI={GetProfessionInfoByRecipeID=function()return {professionID=202}end}
LL:CaptureProfessionOperation(100,{baseSkill=10,bonusSkill=5,upperSkillTreshold=75,
    bonusStats={{bonusStatName='Resourcefulness',bonusStatValue=250,ratingPct=12.5}}})
local captured=LL.db.characters.Player.professionOperationProfiles['202']
assert(captured.stats[1].percent==12.5 and captured.upperSkillThreshold==75)
LL.db.characters.Player.details={[202]={parentName='Inscription',name='Dragon Isles Inscription'}}
C_ProfSpecs={GetConfigIDForSkillLine=function()return 1 end,
    GetSpecTabIDsForSkillLine=function()return {1}end,GetRootPathForTab=function()return 12 end,
    GetTabInfo=function()return {name='A tree'}end,GetSpendEntryForPath=function(id)return id+100 end,
    GetUnlockEntryForPath=function(id)return id+200 end,
    GetDescriptionForPath=function()return 'Node description' end,
    GetSourceTextForPath=function()return 'A captured unlock requirement' end,
    GetChildrenForPath=function(id)if id==12 then return {13}end end,
    GetPerksForPath=function()return {{perkID=77}}end,
    GetUnlockRankForPerk=function()return 10 end,GetDescriptionForPerk=function()return 'A captured perk' end}
C_Traits={GetNodeInfo=function()return {maxRanks=31,currentRank=11}end,
    GetEntryInfo=function(_,id)if id>=200 then return {maxRanks=1}end return {definitionID=id}end,
    GetDefinitionInfo=function(id)return {overrideName='Node '..id}end}
local scanned=LL:GetProfessionUIOptions('Player','Inscription',9)
assert(#scanned.nodes==2 and scanned.nodes[1].maxRank==30 and scanned.nodes[1].rank==10,
    'unlock rank is not an allocatable knowledge point')
assert(scanned.nodes[2].parentID==12 and scanned.nodes[2].depth==1)
assert(scanned.nodes[1].milestones[1].rank==10 and scanned.operation.recipeID==100)
assert(scanned.nodes[1].requirementsKnown==false,'live unlock state is not a simulated prerequisite formula')
print('PASS: actual simulated skill valuation and tooltip, scoped thresholds, stat context, invalid stats and prerequisite boundaries')
