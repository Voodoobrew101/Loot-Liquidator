-- Reachable public profile previews for native Loot/Use scopes. No game actions.
local checks=0
local function check(value,label)assert(value,label);checks=checks+1 end
local function copy(v)if type(v)~='table'then return v end local r={}for k,x in pairs(v)do r[k]=copy(x)end return r end
local function same(a,b)
    if type(a)~=type(b)then return false end if type(a)~='table'then return a==b end
    for k,v in pairs(a)do if not same(v,b[k])then return false end end
    for k in pairs(b)do if a[k]==nil then return false end end return true
end
GetBuildInfo=function()return'12.1.5','70961'end
GetTime=function()return 100 end;time=function()return 100 end
CreateFrame=function()return{RegisterEvent=function()end,SetScript=function()end}end
GetItemInfo=function(id)return'Item '..id end
local LL={db={characters={Player={professions={}}}}}
for _,file in ipairs({'ItemDBRuntime.lua','ProfessionCatalog.lua','Professions.lua','ProfessionModels.lua',
    'ProfessionCalculations.lua','Database.lua','ConversionEngine.lua'})do assert(loadfile('LootLiquidator/'..file))('LL',LL)end
LL.CharacterKey=function()return'Player'end
LL.GetResearchProfessionSnapshot=function()return 0,'none'end
LL.GetCachedOperationInfo=function()end
LL.Invalidate=function(self)self._processingContextCache=nil;self._processingModelCache=nil end
LL:MigrateEvidenceSettings()
local data=LL.ItemDB.professionProfiles
local rawBefore=copy(LL.ItemDB.processing)
local targetsSeen,entriesSeen,outputEntries,methods={},{},{},{}
local targetCount=0
for _,profile in pairs(data.profiles)do
    local targets=LL:GetProfessionOpportunityTargets(profile.profession,profile.expansionID)
    if #targets>0 then
        LL.db.characters.Player.professions[profile.profession]=true
        local parts={}
        for id,node in pairs(profile.nodes)do parts[#parts+1]=id..'='..node.maxRank end
        local conditions={}
        for _,effect in ipairs(LL:GetProfessionConditionalEffects(profile.profession,profile.expansionID))do
            conditions[tostring(effect.entryID)]={active=true,stacks=effect.maxStacks}
        end
        check(LL:SetManualProfessionProfile('Player',profile.profession,profile.expansionID,{enabled=true,skill=1000,
            specialization=table.concat(parts,','),effectStates=conditions,stats={resourcefulness={percent=100},multicraft={percent=100}},buffs={}}),
            'the public profile API accepts the explicit opportunity scenario')
        for _,target in ipairs(targets)do
            targetCount=targetCount+1;check(not targetsSeen[target.targetID],'opportunity target IDs are unique');targetsSeen[target.targetID]=true
            methods[target.method]=true
            local targetBefore=copy(target)
            local model,selected,context=LL:ProfessionOpportunityPreview(profile.profession,profile.expansionID,target.targetID,'Player',true)
            check(model and selected.targetID==target.targetID and context.simulated,'a public target selection reaches the real profile model')
            check(model.actionable==false and model.value==nil and model.partialValue==nil,'a world/use preview cannot become a liquidation action or EV')
            check(model.confidence==0 and model.baselineIndex==1,'missing absolute frequencies retain a declared normalized baseline and confidence zero')
            check(#model.materials==0 and #model.namedOutputs==0,'normalized indexes cannot masquerade as priced per-input material quantities')
            check(model.params.inputFactor==1 and model.params.outputFactor==1,'world/use outcomes do not inherit crafting Resourcefulness or Multicraft')
            local applied={}
            for _,effect in ipairs(model.appliedEffects)do applied[effect.entryID]=true;entriesSeen[effect.entryID]=true end
            for _,entryID in ipairs(target.effectEntryIDs)do check(applied[entryID],'every registered native activity entry reaches the selected public preview: '..entryID)end
            local conditional={}
            local function conditionsIn(effects)
                for _,effect in ipairs(effects or{})do
                    local c=effect.condition or{}
                    if effect.scope and effect.scope.method==target.method and
                        (c.requiresActiveBuff or c.event or next(c.contextFlags or{}) or next(effect.requiredContextFlags or{}))then
                        conditional[#conditional+1]=effect
                    end
                end
            end
            local targetNode=profile.nodes[target.nodeID]
            conditionsIn(targetNode.pointEffects);conditionsIn(targetNode.learningEffects)
            for _,milestone in ipairs(targetNode.milestones)do conditionsIn(milestone.effects)end
            if #conditional>0 then
                local saved=copy(LL:GetManualProfessionProfile('Player',profile.profession,profile.expansionID))
                local inactive=copy(saved);inactive.effectStates={}
                check(LL:SetManualProfessionProfile('Player',profile.profession,profile.expansionID,inactive),'conditional activity state can be cleared through the real profile API')
                local inactiveModel=LL:ProfessionOpportunityPreview(profile.profession,profile.expansionID,target.targetID,'Player',true)
                for _,effect in ipairs(conditional)do
                    local found=false
                    for _,row in ipairs(inactiveModel.appliedEffects)do
                        if row.entryID==effect.entryID and row.metric==effect.metric and row.mechanism==effect.mechanism then found=true end
                    end
                    check(not found,'target selection does not invent an active world event, aura or regional condition')
                end
                check(LL:SetManualProfessionProfile('Player',profile.profession,profile.expansionID,saved),'the explicit activity selection can be restored')
            end
            for _,output in ipairs(model.relativeOutputs)do
                check(type(output.value)=='number' and output.value>=0 and output.confidence==0,'the reachable relative outcome has numeric units and honest confidence')
                check(output.chance==nil and output.samples==nil and output.histogram==nil,'a normalized opportunity creates no per-kill probability or observation counts')
            end
            check(same(target,targetBefore),'public opportunity projection leaves target metadata unchanged')
            local saved=copy(LL:GetManualProfessionProfile('Player',profile.profession,profile.expansionID))
            saved.benchmark={outputLevel=160,specializationBonus=25,resourcefulnessChance=100,resourcefulnessSaved=100}
            check(LL:SetManualProfessionProfile('Player',profile.profession,profile.expansionID,saved),'normalized opportunity benchmark profile saves')
            local benchmark=LL:ProfessionOpportunityPreview(profile.profession,profile.expansionID,target.targetID,'Player',true)
            check(benchmark.syntheticBenchmark and benchmark.outputIndex==model.outputIndex*2,'opportunity output benchmark affects its normalized index once')
            check(benchmark.expectedInputCount==nil and benchmark.supplyCostFactor==nil,'a Loot/Use benchmark cannot invent Resourcefulness input consumption')
            check(LL:ApplySyntheticBenchmark({expansionID=profile.expansionID},{name=target.method},benchmark,benchmark.context)==benchmark,'opportunity benchmark replay is idempotent')
            saved.benchmark=nil
            check(LL:SetManualProfessionProfile('Player',profile.profession,profile.expansionID,saved),'following opportunity targets retain an unscaled comparison scenario')
        end
        local function require(effects)
            for _,effect in ipairs(effects or{})do
                if effect.scope and (effect.scope.method=='Loot' or effect.scope.method=='Use')then
                    check(entriesSeen[effect.entryID],'every Loot/Use source entry is reachable through a public target selection')
                    if effect.metric=='extraOutput' or effect.metric=='dropChance'then outputEntries[effect.entryID]=true end
                end
            end
        end
        for _,node in pairs(profile.nodes)do
            require(node.pointEffects);require(node.learningEffects)
            for _,milestone in ipairs(node.milestones)do require(milestone.effects)end
        end
    end
end
check(methods.Loot and methods.Use,'both world loot and item use have reachable previews')
local outputCount=0 for _ in pairs(outputEntries)do outputCount=outputCount+1 end
check(outputCount>=42,'all previously disconnected world/use output entries are reachable')
check(same(LL.ItemDB.processing,rawBefore),'world/use previews preserve all source observations, quantities and counts')
check(LL:OpportunitySimulationModel({method='Craft',profession='Alchemy',expansionID=11},{})==nil,'activity previews reject ordinary crafting methods')
print('PROFESSION OPPORTUNITY PREVIEW: '..checks..' checks passed; '..targetCount..' target contexts; '..outputCount..' output entries')
