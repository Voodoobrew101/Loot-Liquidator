-- Synthetic recipe identities exercise context/scan plumbing, not game yields.
local checks=0
local function check(value,label) assert(value,label);checks=checks+1 end
local function near(a,b,label) check(type(a)=='number' and math.abs(a-b)<1e-8,(label or '')..': '..tostring(a)..' ~= '..tostring(b)) end
GetTime=function() return 100 end
time=function() return 100 end
GetBuildInfo=function() return '12.1.5','70961' end
CreateFrame=function() return {RegisterEvent=function()end,SetScript=function()end} end
local LL={db={characters={Player={professions={},recipes={},researchProfiles={}},Alt={professions={},recipes={},researchProfiles={}}}}}
for _,file in ipairs({'ProfessionModels.lua','Professions.lua','ConversionEngine.lua'}) do assert(loadfile('LootLiquidator/'..file))('LL',LL) end
LL.CharacterKey=function() return 'Player' end
local realOutputPrice=LL.GetOutputPrice
local professions={'Alchemy','Blacksmithing','Enchanting','Engineering','Inscription','Jewelcrafting',
    'Leatherworking','Mining','Herbalism','Skinning','Tailoring','Cooking'}
local native={baseSkill=100,bonusSkill=55,craftingQuality=2,baseDifficulty=200,bonusDifficulty=10,
    ingenuityRefund=17,expectedConcentrationCost=22,
    concentrationCost=37,craftingTimeMilliseconds=4500,supportsConcentration=true,
    bonusStats={{bonusStatName='Resourcefulness',bonusStatValue=250,ratingPct=17},
        {bonusStatName='Perception',bonusStatValue=80,ratingPct=8}}}
local operationReads=0
LL.GetCachedOperationInfo=function() operationReads=operationReads+1;return native end
LL.GetResearchProfessionSnapshot=function(self,f,profession)
    local profile=self.db.characters.Player.researchProfiles[profession..':'..f.expansionID]
    if profile then return profile.skill,profile.specialization,profile.lineID end
end
local facts={id=1001,classID=7,expansionID=11,count=10,context={verifiedUnbound=true}}
local function clear() LL._processingContextCache=nil end
for i,profession in ipairs(professions) do
    local node=5000+i
    for _,character in ipairs({'Player','Alt'}) do
        local record=LL.db.characters[character]
        record.professions[profession]=true
        record.recipes[8000+i]={learned=true,profession=profession}
        record.researchProfiles[profession..':11']={skill=100,bonusSkill=40,lineID=1000+i,observed=100,
            specialization=node..'=11',specializationVerified=true,specializationSignatureEncoding='trait-node-current-rank',
            specializationKnown=true,specializationEncoding='invested-points',
            specializationPoints={[tostring(node)]=10},learnedSpecializations={[tostring(node)]=true}}
    end
    LL.db.rateProfile=1;clear()
    local live=LL:ProcessingPlayerConditions(facts,'Craft',8000+i,'Current character')
    check(live.profession==profession and live.profileKind=='live',profession..' resolves exact recipe profession')
    near(live.preSpecializationSkill,140,profession..' pre-specialization snapshot uses base plus equipment skill')
    check(live.specialization==node..'=11' and live.specializationPoints[tostring(node)]==10,
        profession..' preserves raw rank and separate invested map')
    check(live.operationStatsIncludeSpecialization and #live.operationStats==2,'all native operation stats remain inclusive')
    near(live.statCalibration.resourcefulness.rating,250,'native rating calibration')
    near(live.statCalibration.resourcefulness.percent,17,'native percentage calibration')
    check(live.concentrationCost==37 and live.craftingTimeMilliseconds==4500 and live.baseDifficulty==200,
        'operation difficulty, concentration and duration retain native units')
    local accepted=LL:SetManualProfessionProfile('Player',profession,11,{enabled=true,skill=80,specialization=node..'=5',
        stats={resourcefulness={rating=250,percent=17}}})
    if LL:ProfessionTooltipMethods(profession) then
    check(accepted,'manual profile saves for '..profession)
    LL.db.rateProfile=3;LL.db.rateProfileCharacter='Player';clear()
    local manual=LL:ProcessingPlayerConditions(facts,'Craft',8000+i,'Current character',profession)
    check(manual.simulated and manual.profession==profession and manual.specializationPoints[tostring(node)]==5,
        profession..' selects its own manual profile')
    near(manual.preSpecializationSkill,80,'manual pre-specialization skill')
    check(not manual.operationStatsIncludeSpecialization,'manual stats are independent of live specialization')
    if profession~='Enchanting' then
    near(manual.statAnchors.resourcefulness.rating,250,'initial rating/percentage pair sets one immutable anchor')
    check(LL:SetManualProfessionProfile('Player',profession,11,{enabled=true,skill=80,specialization=node..'=5',
        stats={resourcefulness={rating=260,percent=17}}}),'edited rating saves')
    clear();manual=LL:ProcessingPlayerConditions(facts,'Craft',8000+i,'Current character',profession)
    near(manual.stats.resourcefulness.rating,260,'rating edit is retained')
    near(manual.statAnchors.resourcefulness.rating,250,'rating edit does not move the anchor')
    manual.statAnchors.resourcefulness.rating=999
    near(LL:GetManualProfessionProfile('Player',profession,11).statAnchors.resourcefulness.rating,250,
        'context anchors cannot rewrite saved anchors')
    else check(not next(manual.stats or {}) and not next(manual.statAnchors or {}),'DE manual context has no unrelated resourcefulness controls') end
    else check(not accepted,'unsupported gathering manual profiles are rejected while raw context remains captured') end
    LL.db.rateProfile=2;LL.db.rateProfileCharacter='Alt';clear()
    local before=operationReads
    local offline=LL:ProcessingPlayerConditions(facts,'Craft',8000+i,'Current character',profession)
    check(offline.character=='Alt' and offline.profileKind=='offline-snapshot' and not offline.simulated,
        profession..' selects scanned offline profile')
    check(operationReads==before,'offline contexts do not borrow current operation stats')
    near(offline.preSpecializationSkill,140,'offline base plus equipment skill')
end
LL.db.rateProfile=1;LL.db.rateProfileCharacter=nil
LL.ItemDB={professionProfiles={recipes={[9999]={profession='Alchemy'}}}}
clear()
check(LL:ProcessingPlayerConditions(facts,'Craft',9999).profession=='Alchemy','exact ItemDB recipe metadata supplies profession hint')
check(not LL:CanUseConversion(facts,{method='Craft',profession='Alchemy',recipeID=9999}),
    'metadata and a profession alone never grant unknown recipe access')
LL.db.manualProfessionProfiles.Player['Alchemy:11']={stats={resourcefulness={rating=120,percent=8}}}
check(LL:SetManualProfessionProfile('Player','Alchemy',11,{enabled=true,skill=50,specialization='none',
    stats={resourcefulness={rating=130,percent=8}}}),'legacy manual profile accepts its first edit')
near(LL:GetManualProfessionProfile('Player','Alchemy',11).statAnchors.resourcefulness.rating,120,
    'legacy paired stats become the anchor before the first changed rating')

-- Scan a multi-input craft, a required quality choice and an unlearned recipe.
local learned=true
C_TradeSkillUI={
    GetProfessionInfoByRecipeID=function() return {professionID=1711,parentProfessionName='Alchemy'} end,
    GetChildProfessionInfo=function() return {professionID=1711,professionName='Midnight Alchemy',
        parentProfessionName='Alchemy',skillLevel=100,maxSkillLevel=100} end,
    GetBaseProfessionInfo=function() return {professionID=171,professionName='Alchemy'} end,
    GetAllRecipeIDs=function() return {10001,10002,10003} end,
    GetRecipeInfo=function(id) return {learned=id~=10003 and (id~=10001 or learned),name='Fixture recipe'} end,
    GetRecipeSchematic=function(id)
        return {outputItemID=2000,quantityMin=2,quantityMax=2,reagentSlotSchematics={
            {quantityRequired=2,reagents={{itemID=1001}}},
            {quantityRequired=3,reagents=id==10002 and {{itemID=1003},{itemID=1004}} or {{itemID=1002}}}}}
    end,
    GetRecipeQualityItemIDs=function(id) if id==10001 then return {2001,2002} end end,
    GetQualitiesForRecipe=function(id) if id==10001 then return {22,11} end end,
    GetRecipeOutputItemData=function(id,_,_,quality)
        if id~=10001 then return nil end
        if quality==11 then return {itemID=2002,hyperlink='item:2002:q1'} end
        if quality==22 then return {itemID=2001,hyperlink='item:2001:q2'} end
        return {itemID=2000,hyperlink='item:2000:default'}
    end,
    GetItemCraftedQualityInfo=function(item)
        if item==2001 or item=='item:2001:q2' then return {quality=2} end
        if item==2002 or item=='item:2002:q1' then return {quality=1} end
    end}
LL.db.characters.Player.recipes={}
LL:ScanProfessionRecipes()
local char=LL.db.characters.Player
check(#char.recipes[10001].requiredInputs==2 and char.recipes[10001].requiredInputsResolved,
    'all fixed required reagents are staged in the learned recipe')
check(#char.recipes[10002].reagentSlots[2].alternatives==2 and not char.recipes[10002].requiredInputsResolved,
    'unselected required alternatives remain explicit structured requirements')
check(LL.db.recipeCandidates[1001][10002]==nil,'an unresolved required choice cannot become a free economic candidate')
check(not char.recipes[10003] and LL.db.recipeCandidates[1001][10003]==nil,'unlearned recipes supply no access or candidates')
local candidate=LL.db.recipeCandidates[1001][10001]
check(candidate.extraReagents[1].id==1002 and candidate.extraReagents[1].amount==3,'every extra required input is charged')
check(candidate.qualityOrderVerified and candidate.outputQualityItems[1].id==2002
    and candidate.outputQualityItems[2].id==2001,'native quality ranks override numerical ID order')
check(candidate.outputQualityItems[2].itemLink=='item:2001:q2','native output hyperlinks survive the scan')
LL:CaptureProfessionOperation(10001,native)
local captured=char.professionRecipeOperations[10001]
check(captured.operationStatsIncludeSpecialization and #captured.operationStats==2,
    'saved native operation stats retain all typed entries and inclusive-specialization flag')
near(captured.statCalibration.resourcefulness.percent,17,'saved operation preserves its native calibration')
check(captured.craftingTimeMilliseconds==4500 and captured.concentrationCost==37,
    'saved recipe operation preserves native duration and concentration metadata')
check(captured.ingenuityRefund==17 and captured.expectedConcentrationCost==22,'native concentration refund/expected cost remain captured amounts')
LL.EligibleDisenchant=function() return false end
LL.GetOutputPrice=function(_,id) return ({[2000]=100,[1001]=4,[1002]=10,[1003]=9,[1004]=7})[id] end
GetItemCount=function() return 999 end
local bridged={}
LL.ProfessionCraftModel=function(self,f,c,character)
    bridged[#bridged+1]=c
    return {inputCount=c.inputCount,materials={{id=c.outputID,expectedQuantity=c.outputCount}},confidence=80,
        context=self:ProcessingPlayerConditions(f,c.method,c.recipeID,character,c.profession)}
end
local function craftQuote()
    for _,option in ipairs(LL:ConversionOptions(facts)) do if option.recipeID==10001 then return option end end
end
local quote=assert(craftQuote())
near(quote.value,85,'fixed native recipe uses model output minus all extra-input costs')
check(quote.available and bridged[#bridged].profession=='Alchemy','fixed craft bridge carries exact profession and learned access')
local prices=LL.GetOutputPrice
LL.GetOutputPrice=function(self,id) if id~=1002 then return prices(self,id) end end
check(craftQuote().value==nil,'missing extra-reagent price never becomes zero cost')
LL.GetOutputPrice=prices;GetItemCount=function() return 0 end
check(not craftQuote().available,'absent extra reagent stock cannot grant a usable conversion')
GetItemCount=function() return 999 end
char.recipeReagentSelections={[10002]={[2]=1004}}
LL:ScanProfessionRecipes()
check(LL.db.recipeCandidates[1001][10002].extraReagents[1].id==1004,
    'an explicitly selected required alternative creates a fully costed candidate')
learned=false;LL:ScanProfessionRecipes()
check(not char.recipes[10001] and not LL.db.recipeCandidates[1001][10001],
    'unlearning removes stale economic candidates')
LL.db.characters.Alt.recipes[10001]={learned=true,profession='Alchemy'}
LL.db.recipeCandidates[1001][10001]=candidate
LL:ScanProfessionRecipes()
check(LL.db.recipeCandidates[1001][10001]==candidate,'a different character retains its verified learned candidate')
local qualityAPI=C_TradeSkillUI.GetItemCraftedQualityInfo
C_TradeSkillUI.GetItemCraftedQualityInfo=nil
local _,verified=LL:RecipeOutputQualityItems(10001)
check(not verified,'missing native quality verification never creates an ordered family from item IDs')
C_TradeSkillUI.GetItemCraftedQualityInfo=qualityAPI

LL.db.recipeCandidates={}
char.recipes={}
LL.Conversions={[1001]={}}
for i,profession in ipairs(professions) do
    char.recipes[9000+i]={learned=true,profession=profession}
    LL.Conversions[1001][#LL.Conversions[1001]+1]={method='Craft',profession=profession,recipeID=9000+i,
        inputCount=2,outputID=2000,outputCount=2,verifiedOutput=true}
end
bridged={};LL:ConversionOptions(facts)
check(#bridged==#professions,'every retained item-processing profession reaches the shared model hook')
for i,c in ipairs(bridged) do check(c.profession==professions[i],c.profession..' retains its profession hint') end
local display
LL.Conversions={[1001]={{method='Craft',profession='Blacksmithing',recipeID=9002,inputCount=2,outputID=2000}}}
LL.ResolveEvidenceModel=function(_,_,option) display=option;return nil end
LL:ConversionOptions(facts)
check(display.profession=='Blacksmithing' and display.outputID==2000,'stochastic/unknown-output resolver receives profession and exact output metadata')

-- Price native variants first, then use the existing base-item fallback.
LL.GetOutputPrice=realOutputPrice
LL.TSMString=function(_,link,id) return link or 'i:'..id end
LL.AHFeeRate=function() return 0 end
LL.Price=function(_,source,item) if source=='dbminbuyout' then return ({['item:2001:q2']=300,['i:2000']=100})[item] end end
near(LL:GetMaterialPrice({id=2001,itemLink='item:2001:q2'}),300,'native hyperlink selects its exact variant price')
near(LL:GetMaterialPrice({id=2001,itemLink='item:2001:q2',economicPolicy='nontradable'}),0,
    'bound/conjured outputs cannot inherit a marketable original item price')
near(LL:GetOutputPrice(2000,'item:2000:unknown-variant'),100,'missing variant quote retains base-item price fallback')
local suppliesModel={inputCount=2,materials={{id=2000,expectedQuantity=2}},confidence=80,supplyCostFactor=.5}
near(LL:ValueProcessingModel(suppliesModel,30,true,facts),92.5,'modeled resourcefulness affects every consumable extra input once')
near(LL:ValueProcessingModel(suppliesModel,30,true,facts),92.5,'revaluation does not compound extra-input savings')

assert(loadfile('LootLiquidator/ProfessionModels.lua'))('LL',LL)
assert(loadfile('LootLiquidator/ProfessionCalculations.lua'))('LL',LL)
LL.ItemDB.professionProfiles=assert(loadfile('database/profession-profile-rules.lua'))()
C_Spell={GetSpellName=function(id) return 'Spell '..id end}
check(LL.GatheringSimulationModel==nil and LL.GatheringSimulationPreview==nil
    and LL.GetGatheringSimulationTargets==nil and LL.RegisterGatheringSimulationTarget==nil,
    'gathering projection APIs are removed')
check(LL.IsGatheringProfession==nil,'gathering-only profession classifier is removed')
for _,stat in ipairs(LL.ProfessionSimulationStats)do
    check(stat.key~='finesse' and stat.key~='perception' and stat.key~='deftness',
        'gathering-only simulation stats are removed')
end
local miningAuras=LL:KnownProfessionAuraIDs('Mining',11)
for _,id in ipairs({185562,432265,1236763,1236767,1269152,1269170,1269171})do
    check(not miningAuras[tostring(id)],'gathering-only aura is no longer scanned: '..id)
end

local widgets={}
local function widget()
    local w={scripts={},shown=true}
    function w:SetScript(key,fn) self.scripts[key]=fn end
    function w:SetText(text) self.text=text end
    function w:SetChecked(value) self.checked=value end
    function w:GetChecked() return self.checked end
    function w:Show() self.shown=true end
    function w:Hide() self.shown=false end
    function w:CreateFontString() return widget() end
    setmetatable(w,{__index=function() return function() end end})
    widgets[#widgets+1]=w;return w
end
CreateFrame=function() return widget() end
Settings={CreateControlTextContainer=function()
    local values={};return {Add=function(_,id,label) values[#values+1]={id,label} end,GetData=function() return values end}
end}
LL.CreateSettingsButton=function() return widget() end
LL.CreateSettingsCheckbox=function() local w=widget();w.kind='CheckButton';return w end
LL.CreateSettingsCanvasSlider=function(_,_,minimum,maximum,_,_,changed)
    local w=widget();w.slider=widget();w.minimum=minimum;w.maximum=maximum;w.changed=changed;return w
end
LL.CreateSettingsDropdown=function(_,_,data,get,set)
    local w=widget();w.select=set
    function w:Refresh() self.rows=data();self.value=get() end
    return w
end
LL.GetProfessionUIOptions=function() return {nodes={},buffs={}} end
LL.UpdateAllAppearance=function() end
GetExpansionLevel=function() return 11 end
assert(loadfile('LootLiquidator/Settings.lua'))('LL',LL)
LL.db.professionTooltipProfiles={}
local originalAlchemy=LL.ItemDB.professionProfiles.profiles['Alchemy:11']
LL.ItemDB.professionProfiles.profiles['Alchemy:11']={nodes={[777]={name='Conditional Alchemy',maxRank=30,
    learningEffects={{entryID=122285,metric='resourcefulness',amount=12,unit='rating',condition={requiresActiveBuff=true,spellIDs={433230}}}},
    milestones={{rank=5,effects={{entryID=125480,metric='resourcefulness',amount=2,unit='percent',scope={method='Craft'},
        condition={requiresActiveBuff=true,spellIDs={},maxStacks=15}}}}}}}}
LL.ItemDB.professionProfiles.recipes[9001]={profession='Alchemy',expansionID=11,labels={},outputCount=2,supportsMulticraft=true}
LL.db.characters.Player.recipes[9001]={learned=true,profession='Alchemy',outputID=2000,outputCount=2,
    reagentSlots={{quantityRequired=1,alternatives={{itemID=1001}}}}}
local spellName=C_Spell.GetSpellName
C_Spell.GetSpellName=function(id) if id==433230 then return 'Native Alchemy Bonus' end return spellName(id) end
local buffOptions=LL:AddProfessionConditionBuffs({nodes={},buffs={}},'Alchemy',11)
check(#buffOptions.buffs==1 and buffOptions.buffs[1].id==433230,'verified native condition spell becomes a named toggle without an aura scan')
local effects=LL:GetProfessionConditionalEffects('Alchemy',11,{{id=777,name='Conditional Alchemy'}})
check(#effects==1 and effects[1].entryID==125480 and effects[1].maxStacks==15 and effects[1].minimumRank==5,
    'anonymous conditional entry keeps its own stable ID, unlock rank and source stack cap')
check(LL:SetManualProfessionProfile('Player','Alchemy',11,{enabled=true,skill=100,specialization='777=5',
    effectStates={['125480']={active=true,stacks=4}}}),'manual conditional state saves without inventing an aura ID')
LL.db.rateProfile=3;LL.db.rateProfileCharacter='Player';clear()
local conditional=LL:ProcessingPlayerConditions(facts,'Craft',9001,'Current character','Alchemy')
check(conditional.effectStates['125480'].active and conditional.effectStates['125480'].stacks==4,
    'conditional entry state reaches calculation context')
conditional.effectStates['125480'].stacks=15
check(LL:GetManualProfessionProfile('Player','Alchemy',11).effectStates['125480'].stacks==4,'context states cannot mutate saved conditional choices')
check(not LL:SetManualProfessionProfile('Player','Alchemy',11,{effectStates={['125480']={active=true,stacks=16}}}),
    'manual conditional stacks cannot exceed the source cap')
local oldOptions=LL.GetProfessionUIOptions
LL.GetProfessionUIOptions=function(_,_,profession)
    if profession=='Alchemy' then return {nodes={{id=777,name='Conditional Alchemy',tab='Alchemy',maxRank=30}},buffs={}} end
    return {nodes={},buffs={}}
end
LL.db.professionTooltipProfiles.Alchemy='@hypothetical'
local firstWidget=#widgets
local conditionalPanel=LL:CreateProfessionProfilePanel('Alchemy');conditionalPanel.scripts.OnShow()
for index=firstWidget+1,#widgets do
    local w=widgets[index]
    if w.text=='Advanced' and w.scripts.OnClick then w.scripts.OnClick(w);break end
end
local conditionalCheck,stackSlider,conditionalLabel
for index=firstWidget+1,#widgets do
    local w=widgets[index]
    if w.kind=='CheckButton' and w.shown then conditionalCheck=w end
    if w.minimum==1 and w.maximum==15 then stackSlider=w end
    if w.text=='Conditional Alchemy: conditional bonus' and w.shown then conditionalLabel=w end
end
check(conditionalLabel and conditionalCheck and stackSlider,'Settings exposes a separate named conditional entry and source-bounded stack control')
conditionalCheck:SetChecked(false);conditionalCheck.scripts.OnClick(conditionalCheck)
stackSlider.changed(7)
local state=LL:GetManualProfessionProfile('Player','Alchemy',11).effectStates['125480']
check(state.active==false and state.stacks==7,'conditional activation and stacks edit independently')
LL.GetProfessionUIOptions=oldOptions
LL.ItemDB.professionProfiles.profiles['Alchemy:11']=originalAlchemy
C_UnitAuras={GetAuraDataByIndex=function(_,index) if index==1 then return {spellId=433230,applications=3} end end}
local auraProfile=LL.ItemDB.professionProfiles.profiles['Alchemy:11']
LL.ItemDB.professionProfiles.profiles['Alchemy:11']={nodes={[101]={learningEffects={{metric='resourcefulness',scope={method='Craft'},condition={spellIDs={433230}}}}}}}
local buffs,stacks,known=LL:ProfessionAuraState('Alchemy',11,'Craft')
LL.ItemDB.professionProfiles.profiles['Alchemy:11']=auraProfile
check(known and buffs['433230'] and stacks['433230']==3,'native helpful aura identity and actual stack count are preserved')
C_UnitAuras=nil

-- Required quality alternatives produce a quote on each legal input even
-- before the player opens the recipe, with every other slot fully costed.
LL.Conversions={};LL.db.recipeCandidates={};LL.db.rateProfile=1
LL.db.characters.Alt.recipes={}
char.recipes={[7001]={learned=true,profession='Alchemy',skillLineName='Midnight Alchemy',
    outputID=2000,outputCount=2,outputQuantityMin=2,outputQuantityMax=2,reagentSlots={
        {slotIndex=1,quantityRequired=2,isOptional=false,alternatives={{itemID=1001}}},
        {slotIndex=2,quantityRequired=3,isOptional=false,alternatives={{itemID=1003},{itemID=1004}}}}}}
char.recipeReagentSelections=nil
local dynamicPrices={[2000]=100,[1001]=4,[1003]=9,[1004]=7}
LL.GetOutputPrice=function(_,id) return dynamicPrices[id] end
LL.GetMaterialPrice=function(self,m) return self:GetOutputPrice(m.id) end
LL.ProfessionCraftModel=function(_,_,c)
    return {inputCount=c.inputCount,materials={{id=c.outputID,expectedQuantity=c.outputCount,confidence=80}},
        confidence=c.allocationConfidence or 80}
end
LL.ResolveEvidenceModel=function() return nil end
local function dynamicQuote(id)
    local f={id=id,classID=7,expansionID=11,count=100,context={verifiedUnbound=true}}
    for _,v in ipairs(LL:ConversionOptions(f)) do if v.recipeID==7001 then return v end end
end
local dynamic=assert(dynamicQuote(1001))
near(dynamic.value,89.5,'cheapest legal alternative charges all three required supplies')
check(dynamic.modelAllocation and dynamic.confidence==0,'a model-selected quality allocation uses the confidence score')
local fromChoice=assert(dynamicQuote(1003))
near(fromChoice.value,64,'recipe appears on an unselected legal alternative and charges the other input')
check(fromChoice.inputCount==3,'required alternative is a full native slot quantity')
check(char.recipes[7001].reagentSlots[2].selectedItemID==nil and char.recipeReagentSelections==nil,
    'quote generation never overwrites native recipe requirements or user selections')
dynamicPrices[1004]=12
near(assert(dynamicQuote(1001)).value,86.5,'allocation re-evaluates current legal prices instead of freezing a stale cheapest choice')
dynamicPrices[1003]=nil;dynamicPrices[1004]=nil
local missing=assert(dynamicQuote(1001))
check(missing.value==nil and missing.partial and missing.why=='Required reagent identity or price unavailable',
    'unknown required-slot costs remain visible and unvalued')
dynamicPrices[1003]=9;dynamicPrices[1004]=7
local nativeRows={{itemID=1001,quantity=2,dataSlotIndex=1},
    {itemID=1003,quantity=1,dataSlotIndex=2},{itemID=1004,quantity=2,dataSlotIndex=2}}
local fullAllocation
ProfessionsFrame={CraftingPage={SchematicForm={transaction={
    GetRecipeID=function() return 7001 end,
    CreateCraftingReagentInfoTbl=function() return nativeRows end,
    CreateReagentInfoTbl=function() return {} end,
    IsApplyingConcentration=function() return true end}}}}
C_TradeSkillUI.GetCraftingOperationInfo=function(id,allocation,_,concentration)
    check(id==7001 and concentration==true,'native operation read preserves the selected recipe and concentration state')
    fullAllocation=allocation
    return {baseSkill=100,bonusSkill=42,craftingQuality=2,bonusStats={}}
end
local nativeCandidate=assert(LL:LearnedRecipeConversionOptions(facts)[1])
check(nativeCandidate.allocationNative and not nativeCandidate.modelAllocation and #nativeCandidate.allocation==3,
    'complete native allocation preserves mixed qualities within one slot')
check(nativeCandidate.operationCharacter=='Player' and nativeCandidate.operationBuild=='70961'
    and nativeCandidate.operationInfo.craftingQuality==2 and nativeCandidate.operationInfo.concentrationApplied,
    'native full-allocation skill and quality stay attached to exact current character and build')
check(fullAllocation~=nativeRows and nativeCandidate.allocation[1]~=nativeRows[1],
    'read-only allocation copies cannot mutate the live profession transaction')
near(assert(dynamicQuote(1001)).value,88.5,'selected mixed native qualities charge all actual supplied ranks')
nativeRows[2].itemID=9999
C_TradeSkillUI.GetCraftingOperationInfo=nil
local rejected=assert(LL:LearnedRecipeConversionOptions(facts)[1])
check(not rejected.allocationNative and rejected.modelAllocation,'an illegal native item cannot bypass the saved schematic')
ProfessionsFrame=nil
char.recipes[7001].learned=false
check(#LL:LearnedRecipeConversionOptions(facts)==0,'modeled alternatives never grant an unlearned recipe')
local duration={}
LL:CopyProfessionOperationContext(duration,{craftingTimeMilliseconds=4500})
near(duration.duration,4.5,'native milliseconds become seconds')
check(duration.durationIncludesSpeed and duration.durationSource=='native-operation','measured duration is tagged to prevent speed double application')
C_Spell={GetSpellInfo=function() return {castTime=3000} end}
duration={};LL:ProfessionRecipeDuration(duration,7001)
near(duration.duration,3,'native spell cast milliseconds provide a scoped duration fallback')
check(duration.durationIncludesSpeed and duration.durationSource=='native-spell','spell duration retains its native observed-time semantics')
LL.ResearchProcessingInput=function() return {method='Craft',batch=1,expansion=11} end
LL.ResearchProcessingOperations=function() return {} end
LL.ResearchProcessingOutputs={}
check(#LL:ConversionOptions(facts)==0,'ambiguous generic Craft metadata never invents a profession or recipe-less operation')
check(LL:GetManualProfessionProfile('Player',nil,11)==nil,'unknown profession profile lookup remains safe')
print('PASS: '..checks..' all-profession contexts, immutable stat anchors, learned inputs, native quality and craft bridge assertions')
