local checks=0
local function check(v,label)checks=checks+1;assert(v,label)end
GetBuildInfo=function()return '12.1.5','70961'end
GetTime=function()return 100 end
time=function()return 1795219200 end
CreateFrame=function()return {RegisterEvent=function()end,SetScript=function()end}end
local LL={db={characters={Player={professions={},recipes={}}},rateProfile=3,rateProfileCharacter='Player',
    tooltipDetail=3,showAverageQuantity=false,professionTooltipProfiles={Jewelcrafting='@hypothetical'},
    source_itemdb_weight=81,source_reference_weight=10,source_legacy_weight=13}}
for _,name in ipairs({'ItemDBRuntime','ProfessionCatalog','Professions','ProfessionModels','ProfessionCalculations',
    'CraftRecording','Observations','Database','ConversionEngine','Badges'})do
    assert(loadfile('LootLiquidator/'..name..'.lua'))('LL',LL)
end
LL.CharacterKey=function()return 'Player'end
LL.GetCachedOperationInfo=function()end
LL.GetOutputPrice=function()return 100 end
LL.CanUseConversion=function()return false,'Fixture','Player'end
LL.EligibleDisenchant=function()return false end
LL.MarkupColor=function()return ''end
LL.Money=function(_,v)return tostring(v)..' copper'end
LL.ProfessionProgression=function()return {}end
LL:MigrateEvidenceSettings();check(LL:InitializeItemDB(),LL.itemDBError)
local function signature()
    local parts={}
    for _,r in ipairs(LL.ItemDB.processing)do for _,m in ipairs(r.materials)do
        for _,key in ipairs({'expectedQuantity','dropChance','minQuantity','maxQuantity'})do
            parts[#parts+1]=table.concat({r.recordID,m.id,key,tostring(m[key].value),tostring(m[key].samples)},':')
        end
    end end
    return table.concat(parts,'|')
end
local before=signature()
local function profile(node,learned)
    check(LL:SetManualProfessionProfile('Player','Jewelcrafting',11,{enabled=true,skill=0,
        specialization=node and ('106982=30,'..node..'=1') or 'none',
        learnedSpecializations=learned and {[tostring(learned)]=true} or {},stats={}}),'manual profile')
    LL._processingModelCache=nil;LL._processingContextCache={};LL._professionOperationCache={}
end
local function resolve(id)
    local item=LL.ItemDB.professionProfiles.items[id]
    local f={id=id,expansionID=11,reagentQuality=item.qualityRank,classID=7,quality=1,count=100}
    local option={name='Prospect',profession='Jewelcrafting',recipeID=1231127,inputCount=5}
    return assert(LL:ResolveEvidenceModel(f,option,nil,1)),f,option
end
local function diamond(m)
    for _,x in ipairs(m.materials)do if x.id==242608 or x.id==242712 then return x end end
end
local function totalDiamonds(model)
    local total=0
    for _,m in ipairs(model.materials)do if m.id==242608 or m.id==242712 then total=total+(m.expectedQuantity or 0)end end
    return total
end
for _,rule in ipairs(LL.ItemDB.professionOutputGates.rules)do
    for _,id in ipairs(rule.inputItemIDs)do
        profile();local locked,f,option=resolve(id);local m=assert(diamond(locked))
        check(locked.outputGate.eligible==false and m.expectedQuantity==0 and m.chance==0,'known locked ore has numerical zero')
        check(m.structuralZero and not m.quantityCounts and not m.samples,'zero is eligibility, not invented observations')
        local tip={lines={}}
        function tip:AddLine(s)self.lines[#self.lines+1]=s end
        function tip:AddDoubleLine(a,b)self.lines[#self.lines+1]=a..' | '..b end
        LL:AppendRecommendationTooltip(tip,{action='A',facts=f,conversionOptions={{name='Prospect',profession='Jewelcrafting',
            recipeID=1231127,inputCount=5,yieldModel=locked,value=LL:ValueProcessingModel(locked,0,true,f)}}})
        local text=table.concat(tip.lines,'\n')
        local zeroLine=text:match('[^\n]*242608[^\n]*')
        check(zeroLine and zeroLine:find('0%%') and not zeroLine:find('unavailable',1,true),
            'zero reaches the actual diamond row in simulated tooltip dispatch')
        profile(rule.nodeID);local unlocked=resolve(id);m=assert(diamond(unlocked))
        check(unlocked.outputGate.eligible==true and totalDiamonds(unlocked)>0,
            'one-point '..id..' eligibility='..tostring(unlocked.outputGate and unlocked.outputGate.eligible)..' mean='..tostring(m.expectedQuantity)..' conditional='..tostring(m.conditionalExpectedQuantity))
        profile(nil,rule.nodeID);local learnedOnly=resolve(id)
        check(diamond(learnedOnly).chance==0,'learning at zero cannot satisfy a rank-one milestone')
        local foreign=rule.nodeID==106980 and 106979 or 106980
        profile(foreign);check(diamond(resolve(id)).chance==0,'another ore specialization cannot unlock this ore')
        for _,ctx in ipairs({{profession='Jewelcrafting',specializationKnown=false},
            {profession='Jewelcrafting',expansionID=10,specializationKnown=true,specializationEncoding='invested-points',specializationPoints={}},
            {profession='Enchanting',specializationKnown=true,specializationEncoding='invested-points',specializationPoints={}},
            {profession='Jewelcrafting',stale=true,specializationKnown=true,specializationEncoding='invested-points',specializationPoints={}}})do
            local unresolved={materials={{id=242608,conditionalExpectedQuantity=.025,
                conditionalRequirement='Proficient Processor per-ore unlock'}}}
            check(LL:ApplyProfessionOutputGates(f,option,unresolved,ctx)==unresolved,'unknown/stale/foreign context never invents a zero')
        end
    end
end
-- Isolate the actual conditional calculator source from other measured or
-- modeled cohorts: the unlock activates its quantity, not an invented P(hit).
LL.db.source_itemdb_enabled=false;LL.db.source_legacy_enabled=false
LL.db.source_personal_enabled=false;LL.db.source_imported_enabled=false
profile(106980)
local referenceOnly=resolve(237363)
local activated=assert(diamond(referenceOnly))
check(activated.gateReferenceActivated and math.abs(activated.expectedQuantity-.045)<1e-10,
    'Tin-vestigator activates the published conditional mean once per five ore')
check(activated.chance==nil and activated.samples==nil and activated.conditionalExpectedQuantity==nil,
    'unlocked quantity does not fabricate occurrence counts or remain conditional')
check(not referenceOnly.hasConditionalReferences,'the resolved diamond no longer remains a conditional reference')
local conditionOnly={unknownOutputs=true,outputQuantityCompletenessTracked=true,materials={{id=242608,conditionalExpectedQuantity=.045,
    conditionalConfidence=10,conditionalRequirement='Proficient Processor per-ore unlock'}}}
local resolvedCondition=LL:ApplyProfessionOutputGates({id=237363,expansionID=11},
    {name='Prospect',recipeID=1231127},conditionOnly,{profession='Jewelcrafting',specializationKnown=true,
    specializationEncoding='invested-points',specializationPoints={['106980']=1}})
check(not resolvedCondition.unknownOutputs,'resolving the only unknown material repairs partial-yield status')
for _,tracked in ipairs({false,true})do
    local omitted={unknownOutputs=true,outputQuantityCompletenessTracked=tracked,unknownOutputIdentities=tracked,
        materials={{id=242608,expectedQuantity=.045}}}
    local result=LL:ApplyProfessionOutputGates({id=237363,expansionID=11},{name='Prospect',recipeID=1231127},omitted,
        {profession='Jewelcrafting',specializationKnown=true,specializationEncoding='invested-points',specializationPoints={}})
    check(result.unknownOutputs,'resolving Diamond eligibility cannot clear unrelated or untracked source omissions')
end
check(signature()==before,'all original means, probabilities and observation counts remain unchanged')
print('PROSPECTING OUTPUT GATES: '..checks..' checks passed')
