-- Zero profile first; then exactly one stat/skill allocation changes. Native
-- recipes and compiled studies are used with synthetic prices/API boundaries.
-- ProcessingPlayerConditions and the profile selector are never mocked.
local checks,scenarios=0,0
local function check(v,label) checks=checks+1;assert(v,label) end
local function finite(v) return type(v)=='number' and v==v and v>=0 and v<math.huge end
GetBuildInfo=function()return '12.1.5','70961' end
GetTime=function()return 100 end
time=function()return 1795219200 end
CreateFrame=function()return {RegisterEvent=function()end,SetScript=function()end}end
local LL={db={characters={Player={professions={},recipes={}}},rateProfile=3,rateProfileCharacter='Player',
    tooltipDetail=3,showProfessionDetails=false,showAverageQuantity=false,
    source_itemdb_enabled=true,source_itemdb_weight=81,source_reference_enabled=true,source_reference_weight=10,
    source_legacy_enabled=true,source_legacy_weight=13,source_personal_enabled=true,source_personal_weight=65,
    source_imported_enabled=true,source_imported_weight=25,
    disenchantDataMode=1,millingDataMode=1,prospectingDataMode=1,otherConversionDataMode=1}}
for _,name in ipairs({'ItemDBRuntime.lua','ProfessionCatalog.lua','Professions.lua','ProfessionModels.lua',
    'ProfessionCalculations.lua','CraftRecording.lua','ImportedResults.lua','Observations.lua','Database.lua',
    'ConversionEngine.lua','Badges.lua'})do
    local path=name=='ItemDBRuntime.lua' and NUMERICAL_RUNTIME_PATH or 'LootLiquidator/'..name
    assert(loadfile(path))('LL',LL)
end
LL.CharacterKey=function()return 'Player'end
LL.GetCachedOperationInfo=function()end
LL.CanUseConversion=function()return false,'No game actions in a fixture','Current character'end
LL.CurrentHasEnchanting=function()return false end
LL.DisenchantExpansion=function(_,f)return f.expansionID end
LL.EligibleDisenchant=function(_,f)return f.classID==2 or f.classID==4 end
LL.DisenchantEstimate=LL.EvaluateDisenchant
LL.MarkupColor=function()return ''end
LL.Money=function(_,v)return ('%.6f copper'):format(v)end
LL.ProfessionProgression=function()return {}end
LL.GetOutputPrice=function(self,id)
    local item=self.ItemDB.professionProfiles.items[id] or {}
    return (item.qualityRank or 1)*100,'synthetic fixture price'
end
LL.Invalidate=function(self)self._processingModelCache=nil;self._processingContextCache={};self._professionOperationCache={}end
LL:MigrateEvidenceSettings();check(LL:InitializeItemDB(),LL.itemDBError)
-- A complete client salvage list supplies input eligibility, independent of
-- measured output rates. Recycling's native recipe has dynamic input slots.
LL.db.characters.Player.salvageRecipes={[1229930]={inputs={[245807]=true}}}
local data=LL.ItemDB.professionProfiles
local function sourceSignature()
    local out={}
    for _,dataset in ipairs({LL.ItemDB,LL.ItemDB.legacy or {}})do
        for _,record in ipairs(dataset.processing or {})do
            for _,m in ipairs(record.materials or {})do
                for _,field in ipairs({'expectedQuantity','dropChance','minQuantity','maxQuantity'})do
                    local v=m[field] or {}
                    out[#out+1]=table.concat({tostring(record.recordID),tostring(m.id),field,tostring(v.value),
                        tostring(v.samples),tostring(v.confidence),tostring(v.status)},':')
                end
            end
        end
    end
    return table.concat(out,'\n')
end
local originalSources=sourceSignature()
local function setProfile(profession,skill,stat,points,expansion)
    expansion=expansion or 11
    LL.db.manualProfessionProfiles=LL.db.manualProfessionProfiles or {}
    LL.db.manualProfessionProfiles.Player=LL.db.manualProfessionProfiles.Player or {}
    LL.db.manualProfessionProfiles.Player[profession..':'..expansion]=nil
    check(LL:SetManualProfessionProfile('Player',profession,expansion,{enabled=true,skill=skill or 0,
        specialization=points or 'none',stats=stat and {[stat]={percent=10}} or {},buffs={},
        benchmark={outputLevel=100,specializationBonus=0,resourcefulnessChance=0,resourcefulnessSaved=0}}),
        profession..' isolated profile saves')
    LL:Invalidate()
end
local function render(f,quote,dispatch)
    local tip={lines={}}
    function tip:AddLine(line)self.lines[#self.lines+1]=line end
    function tip:AddDoubleLine(left,right)self.lines[#self.lines+1]=left..' | '..right end
    local saved=LL.TooltipConversionOptions
    if not dispatch then LL.TooltipConversionOptions=nil end
    LL:AppendRecommendationTooltip(tip,{action='A',facts=f,conversionOptions={quote}})
    LL.TooltipConversionOptions=saved
    return table.concat(tip.lines,'\n')
end
local stats={'resourcefulness','multicraft','ingenuity','finesse','perception','deftness','craftingSpeed','inspiration'}
local scenariosFor={{name='baseline',skill=0},{name='skill',skill=100},{name='high-skill',skill=1000}}
for _,stat in ipairs(stats)do scenariosFor[#scenariosFor+1]={name=stat,stat=stat}end
local function isolated(context,profession,scenario)
    check(context.profession==profession,'actual receiver/method resolves '..profession)
    check(context.preSpecializationSkill==(scenario.skill or 0),'only the selected skill value is active')
    local count=0
    for key,value in pairs(context.stats or {})do
        if (value.percent or 0)~=0 or (value.rating or 0)~=0 then
            count=count+1
            check(key==scenario.stat and value.percent==10,'exactly the selected stat is active')
        end
    end
    check(count==(scenario.stat and scenario.stat~='inspiration' and 1 or 0),'the previous stat was fully reset: '..profession..'/'..scenario.name..' count '..count)
end
local function means(model)
    local result={}
    for _,m in ipairs(model.materials or {})do if finite(m.expectedQuantity)then
        result[m.id]=(result[m.id] or 0)+m.expectedQuantity
    end end
    return result
end
local function sameUnits(a,b,label)
    for id,value in pairs(a)do check(math.abs(value-(b[id] or 0))<1e-8,label..' '..id..' '..value..' vs '..(b[id] or 0))end
    for id,value in pairs(b)do check(math.abs(value-(a[id] or 0))<1e-8,label..' '..id)end
end
local function familyUnits(model)
    local result={}
    for _,m in ipairs(model.materials or {})do if finite(m.expectedQuantity)then
        local item=data.items[m.id] or {}
        local key=item.qualityFamilyID or m.id
        result[key]=(result[key] or 0)+m.expectedQuantity
    end end
    return result
end
local cases={
    {profession='Jewelcrafting',method='Prospect',id=237359,quality=1,classID=7,rank=1,batch=5},
    {profession='Inscription',method='Mill',id=236770,quality=1,classID=7,rank=1,batch=10},
    {profession='Inscription',method='Mill',id=236777,quality=1,classID=7,rank=2,batch=10},
    {profession='Enchanting',method='Disenchant',id=272269,quality=4,classID=2,batch=1},
    {profession='Enchanting',method='Disenchant',id=244752,quality=3,classID=4,batch=1},
    {profession='Engineering',method='Recycle',id=245807,quality=1,classID=7,rank=1,batch=5},
}
-- Exercise every current compiled modern input/category with numerical source
-- units. Source-profile-only/unlearned operations remain explicitly held.
local inputs,baselineQuotes,heldQuotes={},0,0
for _,record in ipairs(LL.ItemDB.processing)do
    local profession=record.profession or LL:ProfessionForMethod(record.method)
        or LL:ProfessionForRecipe(record.recipeID,'Player')
    local expansion=record.expansionID
    if profession and expansion and data.profiles[profession..':'..expansion] then
        local id=record.inputItemID
        local rarity,class=record.inputRarity,record.inputClassID
        if record.gearKey then
            local _,q,kind=record.gearKey:match('^gear:(%d+):(%d+):(%a+)$')
            rarity=tonumber(q);class=kind=='weapon' and 2 or 4;id=id or 999999
        end
        local numeric=false
        for _,m in ipairs(record.materials)do if finite(m.expectedQuantity.value)then numeric=true end end
        if id and numeric then
            local key=table.concat({profession,expansion,id,record.method,record.recipeID or '',record.inputCount,rarity or '',class or ''},':')
            if not inputs[key]then
                inputs[key]=true
                setProfile(profession,0,nil,nil,expansion)
                local item=data.items[id] or {}
                local f={id=id,expansionID=expansion,classID=class or 7,quality=rarity or 1,
                    reagentQuality=record.inputQualityRank or item.qualityRank,count=100,context={verifiedUnbound=true}}
                local option={name=record.method,recipeID=record.recipeID,inputCount=record.inputCount,profession=profession}
                local model,reason=LL:ResolveEvidenceModel(f,option,nil,1)
                if model then
                    baselineQuotes=baselineQuotes+1
                    local known=0
                    for _,m in ipairs(model.materials)do if m.expectedQuantity~=nil then
                        check(finite(m.expectedQuantity),'every admitted zero-profile output has finite units: '..key)
                        known=known+1
                    end end
                    check(known>0,'admitted baseline has a numerical output: '..key)
                    local value=LL:ValueProcessingModel(model,0,true,f)
                    check(finite(value),'admitted baseline has a numerical quote: '..key)
                else
                    heldQuotes=heldQuotes+1
                    check(type(reason)=='string' and #reason>0,'held source/operation has an explicit reason: '..key)
                    if NUMERICAL_DIAGNOSTIC then NUMERICAL_DIAGNOSTIC('held',key,reason)end
                end
            end
        end
    end
end
check(baselineQuotes>0,'compiled-source baseline audit executes')
local saw={}
for _,case in ipairs(cases)do
    LL.db.professionTooltipProfiles={[case.profession]='@hypothetical'}
    local baseline,baselineFamilies
    for _,scenario in ipairs(scenariosFor)do
        setProfile(case.profession,scenario.skill,scenario.stat)
        local f={id=case.id,quality=case.quality,classID=case.classID,reagentQuality=case.rank,
            expansionID=11,count=100,context={verifiedUnbound=true}}
        local selected
        for _,q in ipairs(LL:ConversionOptions(f))do
            if q.name==case.method and (q.inputCount or 1)==case.batch then selected=q;break end
        end
        check(selected and selected.yieldModel,case.id..' '..scenario.name..' has a model')
        local model=selected.yieldModel
        isolated(model.context,case.profession,scenario)
        check(finite(selected.value) and finite(selected.confidence),case.id..' '..scenario.name..' zero/one-modifier quote stays numerical: '..tostring(selected.value)..' / '..tostring(selected.confidence)..' / '..tostring(selected.why)..' / '..tostring(model.value)..' / '..tostring(model.partialValue))
        for _,m in ipairs(model.materials)do
            check(m.expectedQuantity==nil or finite(m.expectedQuantity),'target units are finite and nonnegative')
        end
        local text=render(f,selected,true)
        check(text:find('copper',1,true),case.id..' '..scenario.name..' actual tooltip selector retains the evaluated price: '..text)
        check(text:find('%%') or text:find('[avg ',1,true),'actual tooltip has numeric rates or quantities')
        for _,m in ipairs(model.materials)do if finite(m.expectedQuantity) and m.expectedQuantity>0 then
            local line=text:match('Material '..m.id..'[^\n]*')
            check(line,'each numerical output reaches the selected tooltip: '..m.id)
            check(not line:find('unavailable',1,true),'a numerical yield cannot be displayed as unavailable')
            if type(m.chance)~='number' or not m.minQuantity and not m.maxQuantity or m.inconsistentFields then
                check(case.method=='Prospect' and not line:find('[avg ',1,true) or line:find('[avg ',1,true),
                    'numerical output follows the profession display format')
            end
        end end
        if case.id==272269 then
            for _,m in ipairs(model.materials)do if m.id==243605 or m.id==243606 then
                check(finite(m.expectedQuantity),'epic primary always keeps numerical units')
                check(m.chance==nil or finite(m.chance) and m.chance<=1,'any supported epic probability remains valid')
            end end
        end
        if scenario.name=='baseline' then
            if case.id==245807 then
                check(model.sourceReferenceOnly and selected.confidence==0,'Recycling zero profile is an explicit unverified prior')
                check(model.sourceReference.observedSourceOperations==200 and model.sourceReference.observedTargetOperations==0,
                    'source observations never become zero-profile/current-build observations')
            else check(selected.confidence>0,'source-local uncertainty cannot zero the whole baseline') end
            baseline=means(model)
            baselineFamilies=familyUnits(model)
            if case.id==236770 then
                local largest=0
                for _,dataset in ipairs({LL.ItemDB,LL.ItemDB.legacy or {}})do
                    for _,record in ipairs(dataset.processing or {})do
                        if record.method=='Mill' and record.inputItemID==case.id then
                            local total=0
                            for _,m in ipairs(record.materials)do
                                if finite(m.expectedQuantity.value)then total=total+m.expectedQuantity.value end
                            end
                            largest=math.max(largest,total*case.batch/record.inputCount)
                        end
                    end
                end
                local total=0 for _,value in pairs(baselineFamilies)do total=total+value end
                check(largest>0 and total<=largest+1e-8,
                    'independent rank cohorts cannot become additional Sanguithorn cooutputs')
            end
        elseif scenario.stat then
            sameUnits(baseline,means(model),'processing stat cannot rewrite per-operation output units')
        else
            sameUnits(baselineFamilies,familyUnits(model),'skill-only quality routing conserves each material family '..case.id..'/'..scenario.name)
        end
        scenarios=scenarios+1;saw[case.profession]=true
    end
end
-- Every crafting profession follows real profile -> native recipe -> baseline
-- -> one modifier -> the same material tooltip renderer.
for _,row in ipairs({{'Alchemy',1230854},{'Blacksmithing',1229598},{'Enchanting',1236098},
    {'Engineering',1229755},{'Inscription',1230016},{'Jewelcrafting',1230437},
    {'Leatherworking',1237486},{'Tailoring',1227926},{'Cooking',1226166}})do
    local profession,id=row[1],row[2]
    local recipe=assert(data.recipes[id])
    local c={method='Craft',profession=profession,recipeID=id,expansionID=11,inputCount=1,
        outputID=recipe.outputIDs[1],outputCount=recipe.outputCount,qualityOrderVerified=recipe.qualityOrderVerified,
        outputQualityItems=recipe.outputQualityItems}
    LL.db.professionTooltipProfiles={}
    for _,scenario in ipairs(scenariosFor)do
        setProfile(profession,scenario.skill,scenario.stat)
        local f={id=999999,expansionID=11,classID=7,quality=1,count=1}
        local model=assert(LL:ProfessionCraftModel(f,c,'Player'))
        isolated(model.context,profession,scenario)
        check(finite(model.materials[1].expectedQuantity),'native craft produces numerical output at zero and each modifier')
        local value=LL:ValueProcessingModel(model,0,true,f)
        check(finite(value),'native craft valuation remains numerical')
        local text=render(f,{name='Craft',profession=profession,inputCount=1,recipeID=id,eligibleInput=true,
            value=value,confidence=model.valueConfidence,yieldModel=model,tooltipProfileLabel='Simulated'},false)
        check(text:find('[avg ',1,true) or text:find('%%'),'native craft tooltip exposes its quantity')
        scenarios=scenarios+1;saw[profession]=true
    end
end
-- Gathering has explicit native target previews. Empty general targets expose
-- modifier indexes, never invented per-node item yields or observation counts.
for _,profession in ipairs({'Herbalism','Mining','Skinning','Fishing'})do
    for _,scenario in ipairs(scenariosFor)do
        setProfile(profession,scenario.skill,scenario.stat)
        local model,target,context=LL:GatheringSimulationPreview(profession,11,nil,'Player',true)
        check(model and target,'public gathering target resolves '..profession)
        isolated(context,profession,scenario)
        check(finite(model.yieldFactor) and finite(model.speedFactor) and finite(model.rareDiscoveryFactor),
            'gathering zero and isolated modifiers have numerical indexes')
        scenarios=scenarios+1;saw[profession]=true
    end
end
local count=0 for _ in pairs(saw)do count=count+1 end
check(count==13,'all thirteen professions use the actual profile API')

-- Named-character routing uses the real snapshot reader, not a fabricated
-- ProcessingPlayerConditions receiver. The existing capture remains 200 casts.
local captured=assert(loadfile('tests/fixtures/personal-de-70783-source-subset.lua'))()
LL.db.craftResearch=captured.craftResearch
LL.db.characters['Fixture-Character']={professions={},recipes={},researchProfiles={['Enchanting:11']={
    skill=64,bonusSkill=40,specialization='none',observed=time(),
    specializationKnown=true,specializationVerified=true,
    specializationSignatureEncoding='trait-node-current-rank',specializationEncoding='invested-points',
    specializationPoints={},learnedSpecializations={},disenchantSpecializationKnown=true,
    disenchantSpecializationEncoding='invested-points',disenchantSpecializationPoints={},
    disenchantLearnedSpecializations={},buffsKnown=true,buffs={}}}}
LL.db.professionTooltipProfiles={Enchanting='Fixture-Character'}
LL.CharacterKey=function()return 'Fixture-Character'end
LL._activeResearchProfileCache={['Fixture-Character:Enchanting:11']={at=GetTime(),skill=64,spec='none',lineID=2909}}
LL.db.rateProfile=2;LL.db.rateProfileCharacter='Fixture-Character';LL:Invalidate()
local facts={id=244752,classID=4,quality=3,expansionID=11,itemLevel=168,count=1}
local options=LL:TooltipConversionOptions(facts,LL:ConversionOptions(facts))
local quoted
for _,option in ipairs(options)do if option.name=='Disenchant' then quoted=option end end
check(quoted and quoted.yieldModel,'named character tooltip resolves the actual capture')
local model=quoted.yieldModel
check(model.context.preSpecializationSkill==104 and model.context.simulated~=true,'64 skill plus 40 equipment is read once')
check(quoted.confidence==85 and model.personalStats.total==200,'named profile preserves measured confidence and denominator: '..tostring(quoted.confidence)..' / '..tostring(model.personalStats and model.personalStats.total))
local probabilities={}
for _,m in ipairs(model.materials)do probabilities[m.id]=m.chance end
check(math.abs(probabilities[243602]-.9)<1e-10 and math.abs(probabilities[243603]-.1)<1e-10,
    'the known goggles profile retains the measured 90/10 probabilities')

check(sourceSignature()==originalSources,'source means, probabilities, counts, ranges and confidence are unchanged')
print(('NUMERICAL PIPELINE STAGES: %d checks; %d zero/one-modifier scenarios; %d professions; %d compiled baselines; %d held source-scoped operations')
    :format(checks,scenarios,count,baselineQuotes,heldQuotes))
