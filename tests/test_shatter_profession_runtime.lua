-- Real reviewed Shatter source -> inverse baseline -> selected profile -> quote.
local checks=0
local function check(value,label) assert(value,label);checks=checks+1 end
local function near(value,wanted,label) check(type(value)=='number' and math.abs(value-wanted)<1e-8,label..': '..tostring(value)..' ~= '..tostring(wanted)) end
local function copy(value) if type(value)~='table' then return value end local r={} for k,v in pairs(value)do r[k]=copy(v)end return r end
local function same(a,b)
    if type(a)~=type(b)then return false end if type(a)~='table'then return a==b end
    for k,v in pairs(a)do if not same(v,b[k])then return false end end
    for k in pairs(b)do if a[k]==nil then return false end end return true
end
GetBuildInfo=function()return '12.1.5','70961' end
GetTime=function()return 100 end;time=function()return 100 end
CreateFrame=function()return{RegisterEvent=function()end,SetScript=function()end}end
GetItemInfo=function(id)return 'Item '..id end
GetItemCount=function()return 10000 end
local LL={db={characters={Player={professions={Enchanting=true}}},rateProfile=3,rateProfileCharacter='Player',
    professionTooltipProfiles={Enchanting='@hypothetical'},
    source_itemdb_enabled=true,source_legacy_enabled=false,source_reference_enabled=false,
    source_personal_enabled=false,source_imported_enabled=false}}
for _,file in ipairs({'ItemDBRuntime.lua','ProfessionCatalog.lua','Professions.lua','ProfessionModels.lua',
    'ProfessionCalculations.lua','Database.lua','ConversionEngine.lua','Observations.lua','Badges.lua'})do
    assert(loadfile('LootLiquidator/'..file))('LL',LL)
end
LL.CharacterKey=function()return 'Player'end
LL.GetResearchProfessionSnapshot=function()return 0,'none',2874 end
LL.GetCachedOperationInfo=function()end
LL.GetOutputPrice=function(_,id)return id==219948 and 900 or id==219947 and 300 or 100 end
LL.CanUseConversion=function()return false,'Informational fixture','Current character'end
LL.EligibleDisenchant=function()return false end
LL.MarkupColor=function()return ''end
LL.Money=function(_,v)return tostring(v)..' copper'end
LL.Invalidate=function(self)self._processingContextCache=nil;self._processingModelCache=nil end
LL:MigrateEvidenceSettings()
check(LL:InitializeItemDB(),LL.itemDBError)
local metadata=LL.ItemDB.professionProfiles
local rule=assert(metadata.recipeQualityModels[470726],'compiled Shatter quality model required')
local sourceBefore=copy(LL.ItemDB.processing)
local op={name='Craft',profession='Enchanting',recipeID=470726,inputCount=1}
local function facts(rank)return{id=rule.inputRankItemIDs[rank],expansionID=10,classID=7,quality=3,reagentQuality=rank,count=100}end
local function set(skill,root,child,wrong,stats)
    check(LL:SetManualProfessionProfile('Player','Enchanting',10,{enabled=true,skill=skill,
        specialization='99890='..root..',99889='..child..',99888='..(wrong or 0)..',99887='..(wrong or 0),
        stats=stats or {},buffs={}}),'Shatter profile saves')
end
local function amount(model,id)
    for _,m in ipairs(model.materials or{})do if m.id==id then return m.expectedQuantity end end return 0
end
local function pool(model)local total=0 for _,id in ipairs(rule.rankItemIDs)do total=total+amount(model,id)end return total end
local function params(rank,skill,root,child,wrong)
    return LL:ProfessionProfileParameters('Enchanting',10,{skill=skill,preSpecializationSkill=skill,simulated=true,
        specializationPoints={['99890']=root,['99889']=child,['99888']=wrong or 0,['99887']=wrong or 0},
        learnedSpecializations={},stats={}},op,facts(rank))
end
local p=params(2,133,30,30)
near(p.skill,278,'native labels route root65 plus Uncommon80 skill to Shatter')
near(params(2,133,0,0,30).skill,133,'Rare and Epic child paths do not follow the blue shard input rarity')
near(params(2,133,30,0).skill,198,'Designated Disenchanter adds its exact65 native skill')
near(params(2,133,0,30).skill,213,'Uncommon Utilitarian adds its exact80 native skill')
local liveContext={skill=133,effectiveSkill=278,preSpecializationSkill=133,operationStatsIncludeSpecialization=true,
    specializationPoints={['99890']=30,['99889']=30},stats={}}
local live=LL:ProfessionProfileParameters('Enchanting',10,liveContext,op,facts(2))
near(live.skill,p.skill,'a native operation already containing tree Skill matches the manual profile without double addition')
for rank=1,3 do
    for _,skill in ipairs({0,1,50,133,200,277,278,500})do
        local profile=params(rank,skill,0,0)
        local units=assert(LL:RecipeQualityQuantities({3,0,0},profile,op,false))
        near(units[1]+units[2]+units[3],3,'quality curve preserves three dust')
        for index=rank+1,3 do near(units[index],0,'output quality is capped by the consumed shard rank')end
        local inverse=assert(LL:RecipeQualityQuantities(units,profile,op,true))
        for index,value in ipairs(inverse)do near(value,index==1 and 3 or 0,'source inverse recovers the declared baseline')end
    end
end
check(not LL:RecipeQualityQuantities({2,1,0},p,op,true),'nonmatching saturated observations cannot identify the declared baseline')
check(not LL:RecipeQualityQuantities({3,0,0},params(2,133,0,0),op,true),
    'a nonmax source inverse rejects negative implied quality units')
local invalid=copy(p);invalid.inputQuality=3
check(not LL:RecipeQualityQuantities({3,0,0},invalid,op,false),'conflicting item identity and native input quality is rejected')
local noInput=copy(p);noInput.inputQuality=nil
check(not LL:RecipeQualityQuantities({3,0,0},noInput,op,false),'missing native input quality is rejected')
check(not LL:RecipeQualityQuantities({2,0,1},p,op,false),'a source cannot exceed the consumed shard quality cap')
local mixed={inputCount=1,generalProfessionApplied=true,generalProjectedSources={itemdb=true},
    generalProfessionParameters=p,confidence=80,materials={
        {id=219946,expectedQuantity=2.25,confidence=80,sourceContributions={itemdb=.5,imported=.5},
            sourceEstimates={itemdb={expectedQuantity=3,inputCount=1},imported={expectedQuantity=1.5,inputCount=1}}},
        {id=219947,expectedQuantity=.75,confidence=80,sourceContributions={itemdb=.5,imported=.5},
            sourceEstimates={itemdb={expectedQuantity=0,inputCount=1},imported={expectedQuantity=1.5,inputCount=1}}},
        {id=999997,expectedQuantity=4,confidence=80}}}
local mixedBefore=copy(mixed)
local projectedMix=LL:ApplyGeneralProfessionQuality(facts(2),op,mixed,{})
near(amount(projectedMix,219946),.75+rule.targetRankMeansByInputRank[2][1]*.5,'only the selected source rank-one term is projected')
near(amount(projectedMix,219947),.75+rule.targetRankMeansByInputRank[2][2]*.5,'unselected imported rank-two units retain their original weight')
near(pool(projectedMix),3,'mixed-source projection conserves the combined primary pool')
near(amount(projectedMix,999997),4,'unrelated material families remain unchanged')
check(same(mixed,mixedBefore),'source-weighted quality projection does not mutate its input evidence')

for rank=2,3 do
    local f=facts(rank)
    set(0,0,0)
    local zero=assert(LL:ResolveEvidenceModel(f,op,nil,1))
    check(zero.recipeQualityApplied,'actual source resolver applies Shatter quality after source fusion')
    near(amount(zero,219946),3,'compiled endpoint normalizes to three rank-one dust at zero skill')
    near(pool(zero),3,'zero-profile pool is three dust')
    set(133,0,0)
    local native=assert(LL:ResolveEvidenceModel(f,op,nil,1))
    set(133,30,30)
    local full=assert(LL:ResolveEvidenceModel(f,op,nil,1))
    check(amount(full,rule.rankItemIDs[rank])>amount(native,rule.rankItemIDs[rank]),'eligible specialization skill changes actual tooltip output units')
    for index,id in ipairs(rule.rankItemIDs)do near(amount(full,id),rule.targetRankMeansByInputRank[rank][index],'full native profile reaches its exact published unit vector')end
    near(pool(full),3,'full-profile pool is three dust')
    LL:ValueProcessingModel(zero,0,true,f);LL:ValueProcessingModel(full,0,true,f)
    check((full.value or full.partialValue)>(zero.value or zero.partialValue),'rank-sensitive prices change the tooltip gold value')
    for _,m in ipairs(full.materials)do
        if m.id==219946 or m.id==219947 or m.id==219948 then
            check(m.confidence==0,'the intermediate curve keeps its declared confidence zero')
            check(m.samples==nil and m.quantityCounts==nil and m.chance==nil and m.minQuantity==nil and m.maxQuantity==nil,
                'projected units do not manufacture hit probabilities, sample counts or stack bounds')
        end
    end
    check(LL:ResolveEvidenceModel(f,op,nil,1)==full,'unchanged profiles reuse the exact cached result')
    check(LL:ApplyGeneralProfessionQuality(f,op,full,full.context)==full,'postfusion quality is idempotent')
    local quote
    for _,q in ipairs(LL:ConversionOptions(f))do if q.recipeID==470726 then quote=q end end
    check(quote and quote.yieldModel and quote.yieldModel.recipeQualityApplied,'native Shatter input mapping reaches ConversionOptions')
    local tip={lines={}}
    function tip:AddLine(text)self.lines[#self.lines+1]=text end
    function tip:AddDoubleLine(a,b)self.lines[#self.lines+1]=a..' | '..b end
    LL.db.tooltipDetail=3;LL.db.showAverageQuantity=true;LL.db.showProfessionDetails=true
    LL:AppendRecommendationTooltip(tip,{facts=f,conversionOptions={quote}})
    local text=table.concat(tip.lines,'\n'):lower()
    check(text:find('confidence',1,true),'the quote tooltip displays confidence')
    for _,word in ipairs({'estimate','provisional','unquantified'})do check(not text:find(word,1,true),'tooltip avoids a '..word..' label')end
    set(133,0,0,30)
    local wrong=assert(LL:ResolveEvidenceModel(f,op,nil,1))
    for _,id in ipairs(rule.rankItemIDs)do near(amount(wrong,id),amount(native,id),'unmatched Rare/Epic paths do not alter the Shatter vector')end
    set(133,30,30,0,{multicraft={percent=100},resourcefulness={percent=100}})
    local stats=assert(LL:ResolveEvidenceModel(f,op,nil,1))
    near(pool(stats),3,'Multicraft and Resourcefulness never inflate the three-dust completed-cast pool')
    check(stats.expectedInputCount<1,'Resourcefulness changes expected shard consumption independently')
end
LL.db.source_itemdb_enabled=false;LL:Invalidate()
check(LL:ResolveEvidenceModel(facts(2),op,nil,1)==nil,'the quality model cannot bypass disabled source evidence')
check(LL:ResolveEvidenceModel(facts(2),op,nil,2)==nil,'personal-only mode does not import published endpoint evidence')
print('SHATTER PROFESSION RUNTIME: '..checks..' checks passed')
