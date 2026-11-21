-- Native API mocks and actual Settings callbacks; no casts/game operations.
local file=assert(io.open('tests/test_settings.lua','r'));local source=file:read('*a');file:close()
local marker='LL:MigrateEvidenceSettings()'
local start=assert(source:find(marker,1,true),'native Settings fixture boundary')
local LL,widgets=assert(loadstring(source:sub(1,start+#marker-1)..'\nreturn LL,all'))()
assert(loadfile('LootLiquidator/ProfessionModels.lua'))('LL',LL)
assert(loadfile('LootLiquidator/ProfessionCalculations.lua'))('LL',LL)
assert(loadfile('LootLiquidator/ConversionEngine.lua'))('LL',LL)
GetBuildInfo=function()return '12.1.5','70961','',120105 end
GetExpansionLevel=function()return 11 end
GetTime=function()return 100 end
time=function()return 100 end
local checks=0
local function check(ok,label)checks=checks+1;assert(ok,label)end
local function near(a,b,label)check(type(a)=='number' and math.abs(a-b)<1e-9,label..': '..tostring(a)..' ~= '..b)end
local function copy(x)if type(x)~='table'then return x end;local y={}for k,v in pairs(x)do y[k]=copy(v)end return y end
local key='Tester - Realm'
local char=LL.db.characters[key]
char.researchProfiles={};char.professionOperationProfiles={};char.professionRecipeOperations={}
local rootRank,childRank,unlockKnown,auraKnown=21,1,true,true
local activeAura,stacks=5010,2
C_ProfSpecs={GetConfigIDForSkillLine=function(line)assert(line==1000);return 700 end,
    GetSpecTabIDsForSkillLine=function()return {1}end,GetRootPathForTab=function()return 101 end,
    GetChildrenForPath=function(id)return id==101 and {102} or nil end,
    GetUnlockEntryForPath=function(id)return id+9000 end}
C_Traits={GetNodeInfo=function(_,id)return {currentRank=id==101 and rootRank or childRank,maxRanks=31}end,
    GetEntryInfo=function()return unlockKnown and {maxRanks=1} or {} end}
C_UnitAuras={GetAuraDataByIndex=function(_,index)
    if not auraKnown then error('native aura read unavailable') end
    if index==1 and activeAura then return {spellId=activeAura,applications=stacks}end
end}
local native={baseSkill=100,bonusSkill=40,bonusStats={
    {bonusStatName='Multicraft',bonusStatValue=360,ratingPct=18},
    {bonusStatName='Resourcefulness',bonusStatValue=200,ratingPct=10}}}
local nativeReads=0
C_TradeSkillUI={GetProfessionInfoByRecipeID=function()return {professionID=1000,parentProfessionName='Alchemy'}end,
    GetCraftingOperationInfo=function(id,allocation,guid,concentration)
        check(id==4001 and type(allocation)=='table' and guid==nil and concentration==false,'actual native operation signature')
        nativeReads=nativeReads+1;return native
    end}
local effectID=8000
local function effect(metric,amount,unit,scope,condition)
    effectID=effectID+1
    return {entryID=effectID,metric=metric,amount=amount,unit=unit,confidence=100,scope=scope or {method='Craft'},condition=condition}
end
local xscope={method='Craft',labelIDs={1001}}
local yscope={method='Craft',labelIDs={1002}}
local condition={requiresActiveBuff=true,spellIDs={5010},maxStacks=2}
local nodes={
    [101]={maxRank=30,pointEffects={effect('multicraft',3,'rating'),effect('resourcefulness',.15,'percent')},
        learningEffects={effect('multicraft',30,'rating',xscope,condition),effect('resourcefulness',1,'percent',xscope,condition)}},
    [102]={maxRank=30,pointEffects={},learningEffects={effect('multicraft',20,'rating',yscope)}},
}
LL.ItemDB={professionProfiles={build=70961,clientVersion='12.1.5',profiles={['Alchemy:11']={lineID=1000,
    statKeys={'multicraft','resourcefulness'},nodes=nodes}},professionParameters={Alchemy={}},recipes={
    [4001]={profession='Alchemy',expansionID=11,skillLineID=1000,labels={1001},outputCount=2,supportsMulticraft=true},
    [4002]={profession='Alchemy',expansionID=11,skillLineID=1000,labels={1002},outputCount=2,supportsMulticraft=true}}}}
LL.GetProfessionUIOptions=function()return {nodes={{id=101,name='Receipt Root',tab='Fixture',maxRank=30},
    {id=102,name='Receipt Child',tab='Fixture',maxRank=30}},buffs={{id=5010,name='Captured buff'},{id=5020,name='Later buff'}}}end
LL.GetProfessionSimulationControlSupport=function()return {skill=true,nodes={['101']=true,['102']=true},
    stats={multicraft=true,resourcefulness=true},buffs={[5010]=true,[5020]=true}}end
LL.UpdateAllAppearance=function()end
LL:GetCachedOperationInfo(4001)
local captured=assert(char.professionRecipeOperations[4001])
local receipt=assert(captured.statGrantReference,'capture must pair allocation with native total')
check(nativeReads==1 and char.professionOperationProfiles['1000']==captured,'recipe/line indices retain the same native capture')
check(receipt.policy=='SOURCE_OPERATION' and receipt.capturedWithOperation and receipt.recipeID==4001
    and tostring(receipt.build)=='70961' and receipt.skillLineID==1000 and receipt.profession=='Alchemy','receipt binds native operation identity')
check(receipt.specializationPoints['101']==20 and receipt.specializationPoints['102']==0
    and receipt.learnedSpecializations['101'] and receipt.learnedSpecializations['102'],'raw21/1 maps to invested20/0 with learned child')
check(receipt.buffs['5010'] and receipt.buffStacks['5010']==2 and receipt.buffsKnown,'paired actual native aura/stack capture')
near(captured.statCalibration.multicraft.rating,360,'native total rating retained')
near(captured.statCalibration.multicraft.percent,18,'native total percent retained')
local sourceRating,sourcePercent=LL:ProfessionStatGrants('Alchemy',11,receipt,{name='Craft',recipeID=4001},{expansionID=11})
near(sourceRating.multicraft,120,'source X grants60point rating plus60captured buff rating')
near(sourcePercent.resourcefulness,5,'source X grants3point percentage plus2captured buff percentage')
local function snapshot(points,learned,buffs)
    return {skill=100,bonusSkill=40,lineID=1000,specializationVerified=true,
        specializationSignatureEncoding='trait-node-current-rank',specializationKnown=true,specializationEncoding='invested-points',
        specializationPoints=copy(points),learnedSpecializations=copy(learned),buffs=copy(buffs or {}),buffsKnown=true}
end
local panel,first,selector
local function fork(operation,current,targetRank)
    char.professionOperationProfiles['1000']=operation;char.professionRecipeOperations[4001]=operation
    char.researchProfiles['Alchemy:11']=current
    LL.db.manualProfessionProfiles=nil;LL.db.professionTooltipProfiles={Alchemy=key}
    if not panel then
        first=#widgets;panel=LL:CreateProfessionProfilePanel('Alchemy');panel.scripts.OnShow(panel)
        local advanced
        for i=first+1,#widgets do local w=widgets[i]
            if w.kind=='Button' and w.text=='Advanced'then advanced=w end
            if w.template=='SettingsDropdownControlTemplate' and not selector then selector=w end
        end
        assert(advanced and selector,'native Advanced/character callbacks');advanced.scripts.OnClick(advanced)
    else
        -- The production UI has one panel per profession. Revisit that same
        -- panel and select the real character rather than registering another
        -- proxy control with the same native setting variable.
        selector.initializer.setting:SetValue(1);panel.scripts.OnShow(panel)
    end
    local control
    for i=first+1,#widgets do local w=widgets[i]
        if w.kind=='Slider' and (targetRank~=nil and w.maximum==30 and w.value==current.specializationPoints['101']
            or targetRank==nil and w.value==140)then control=w;break end
    end
    assert(control,'native fork control');control:SetValue(targetRank or 141)
    return assert(LL:GetManualProfessionProfile(key,'Alchemy',11),'native UI must save fork')
end
local function parameters(manual,recipe)
    return LL:ProfessionProfileParameters('Alchemy',11,{simulated=true,profileKind='manual-simulation',
        skill=manual.skill,preSpecializationSkill=manual.skill,stats=manual.stats,statAnchors=manual.statAnchors,
        statGrantReference=manual.statGrantReference,specializationPoints=LL:ProfessionSpecializationPoints(manual.specialization),
        learnedSpecializations=manual.learnedSpecializations,buffs=manual.buffs,buffStacks=manual.buffStacks},
        {name='Craft',recipeID=recipe or 4002},{expansionID=11})
end
local sameContext=snapshot({['101']=20,['102']=0},{['101']=true,['102']=true},{['5010']=true})
sameContext.buffStacks={['5010']=2}
local sameFork=fork(captured,sameContext)
check(sameFork.buffStacks and sameFork.buffStacks['5010']==2,'skill-only fork preserves two target buff stacks')
near(parameters(sameFork,4001).stats.multicraft,.18,'same captured allocation and two stacks preserve native18percent')
local function manualContext()
    LL.db.rateProfile=3;LL.db.rateProfileCharacter=key;LL._processingContextCache=nil
    return LL:ProcessingPlayerConditions({id=9001,classID=7,expansionID=11,count=1},'Craft',4001,key,'Alchemy')
end
local targetContext=manualContext()
check(targetContext.profileKind=='manual-simulation' and targetContext.buffStacks['5010']==2,
    'actual processing context carries the two target stacks')
near(LL:ProfessionProfileParameters('Alchemy',11,targetContext,{name='Craft',recipeID=4001},{expansionID=11}).stats.multicraft,
    .18,'actual processing context preserves native18percent')
local buffLabel,buffCheck
for i=first+1,#widgets do local w=widgets[i]
    if w.kind=='FontString' and w.text=='Captured buff' then buffLabel=w;break end
end
assert(buffLabel and buffLabel.point,'native captured buff label')
for i=first+1,#widgets do local w=widgets[i]
    if w.template=='SettingsCheckboxControlTemplate' and w.point and w.point[5]==buffLabel.point[5]+3 then buffCheck=w;break end
end
assert(buffCheck and buffCheck.llNativeCheckbox.scripts.OnClick and buffCheck:GetChecked(),'native captured buff toggle')
local nativeBuffCheck=buffCheck.llNativeCheckbox
nativeBuffCheck:SetChecked(false);nativeBuffCheck.scripts.OnClick(nativeBuffCheck)
local withoutBuff=assert(LL:GetManualProfessionProfile(key,'Alchemy',11))
check(not (withoutBuff.buffs or {})['5010'] and not (withoutBuff.buffStacks or {})['5010'],'native buff toggle removes target stack count')
targetContext=manualContext()
check(not (targetContext.buffs or {})['5010'] and not (targetContext.buffStacks or {})['5010'],'actual processing context removes inactive target stacks')
near(LL:ProfessionProfileParameters('Alchemy',11,targetContext,{name='Craft',recipeID=4001},{expansionID=11}).stats.multicraft,
    .15,'removing the two target stacks subtracts60rating without rebasing source')
check(sameContext.buffStacks['5010']==2 and receipt.buffStacks['5010']==2
    and withoutBuff.statGrantReference.buffStacks['5010']==2,'fork and buff toggle leave input snapshot and paired source stacks immutable')
rootRank=31;activeAura=5020;stacks=1
local later=snapshot({['101']=30,['102']=0},{['101']=true,['102']=true},{['5020']=true})
local manual=fork(captured,later,20)
check(receipt.specializationPoints['101']==20 and receipt.buffs['5010'] and not receipt.buffs['5020']
    and receipt.buffStacks['5010']==2,'later current points/auras cannot rewrite captured source')
check(manual.statGrantReference.policy=='SOURCE_OPERATION' and manual.statGrantReference.specializationPoints['101']==20
    and manual.statGrantReference.buffs['5010'] and manual.statGrantReference.buffStacks['5010']==2,'fork uses captured source rather than current30/later buff')
local y=parameters(manual)
near(y.stats.multicraft,.16,'native360-source X120+target Y80 gives320rating/16percent')
near(y.stats.resourcefulness,.08,'native10-source X5+target Y3 gives8percent')
check(y.statReferenceAssumption==nil,'identified source scope is not downgraded to transfer prior')
near(manual.statAnchors.multicraft.rating,360,'original anchor rating is immutable')
near(manual.statAnchors.multicraft.percent,18,'original anchor percent is immutable')
local x=copy(manual);x.specialization='101=19,102=0';x.buffs={['5010']=true};x.buffStacks={['5010']=2}
near(parameters(x,4001).stats.multicraft,.1785,'one3ratingpoint removal keeps357rating/17.85percent')
local currentZero=snapshot({['101']=0,['102']=0},{},{['5020']=true})
manual=fork(captured,currentZero)
check(manual.statGrantReference.policy=='SOURCE_OPERATION' and manual.statGrantReference.specializationPoints['101']==20,
    'current reset to zero cannot relabel older invested source as ZERO_SOURCE')
near(parameters(manual).stats.multicraft,.12,'current target zero subtracts captured120 from360 to240rating/12percent')
for _,change in ipairs({'legacy','unpaired','recipe','build','line','profession'})do
    local operation=copy(captured)
    if change=='legacy'then operation.statGrantReference=nil
    elseif change=='unpaired'then operation.statGrantReference.capturedWithOperation=false
    elseif change=='recipe'then operation.statGrantReference.recipeID=4002
    elseif change=='build'then operation.statGrantReference.build='70960'
    elseif change=='line'then operation.statGrantReference.skillLineID=1001
    else operation.statGrantReference.profession='Enchanting'end
    local p=fork(operation,currentZero);local result=parameters(p)
    check(p.statGrantReference.policy=='TARGET_SCOPED_TRANSFER_PRIOR',change..' cannot assert source pairing or knownzero')
    near(result.stats.multicraft,.18,change..' identity transfer preserves native total360')
    check(result.statReferenceAssumption=='TARGET_SCOPED_TRANSFER_PRIOR' and result.confidence==0,change..' used stat gets explicit confidencezero prior')
end
local direct=snapshot({['101']=20,['102']=0},{['101']=true,['102']=true},{['5020']=true})
direct.stats={multicraft={rating=320,percent=16},resourcefulness={rating=160,percent=8}}
manual=fork(captured,direct)
check(manual.statGrantReference.policy=='TARGET_SCOPED_TRANSFER_PRIOR','different current snapshot total320 cannot pair old operation360')
near(parameters(manual).stats.multicraft,.16,'direct snapshot320 stays320 instead of incorrect280')
check(parameters(manual).confidence==0,'different total snapshot uses explicit transfer prior')
unlockKnown=false;LL:CaptureProfessionOperation(4001,native)
check(char.professionRecipeOperations[4001].statGrantReference==nil,'failed unlock mapping cannot use blind rawrank-minusone receipt')
local p=fork(char.professionRecipeOperations[4001],currentZero)
check(p.statGrantReference.policy=='TARGET_SCOPED_TRANSFER_PRIOR' and parameters(p).confidence==0,'unmapped source is an explicit prior')
unlockKnown=true;rootRank=21;childRank=1;auraKnown=false;LL:CaptureProfessionOperation(4001,native)
local missingBuff=char.professionRecipeOperations[4001]
check(missingBuff.statGrantReference.buffsKnown==false and missingBuff.statGrantReference.buffs==nil,'failed aura read remains unknown in paired receipt')
p=fork(missingBuff,later,20)
check(p.statGrantReference.policy=='TARGET_SCOPED_TRANSFER_PRIOR' and parameters(p).confidence==0,'relevant unknown source aura cannot claim identified inverse')
auraKnown=true
nodes[101].pointEffects[#nodes[101].pointEffects+1]=effect('multicraft',1,'rating',{method='Craft',labelIDs={1001},inputRarity=2})
p=fork(captured,later,20)
check(p.statGrantReference.policy=='TARGET_SCOPED_TRANSFER_PRIOR' and parameters(p).confidence==0,'unknown source input scope remains a confidencezero transfer prior')
nodes[101].pointEffects[#nodes[101].pointEffects]=nil
rootRank=0;childRank=0;activeAura=nil;LL:CaptureProfessionOperation(4001,native)
local zero=char.professionRecipeOperations[4001]
check(zero.statGrantReference.specializationPoints['101']==0 and not next(zero.statGrantReference.learnedSpecializations),
    'verified native zero includes no learned unlock grants')
p=fork(zero,currentZero)
check(p.statGrantReference.policy=='ZERO_SOURCE' and parameters(p).statReferenceAssumption==nil
    and parameters(p).confidence>0,'verified source zero needs no unknown-transfer confidence cap')
check(receipt.specializationPoints['101']==20 and receipt.buffs['5010'] and receipt.buffStacks['5010']==2,
    'subsequent captures and UI forks leave the original receipt detached')
print('PASS: '..checks..' native stat receipt capture, immutable source pairing, UI fork and prior-boundary checks')
