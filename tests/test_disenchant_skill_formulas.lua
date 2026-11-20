-- Primary build-70961 trait effects and independently captured invested-point
-- boundaries establish skill arithmetic, not a material-quality probability.
local checks=0
local function check(value,label) assert(value,label);checks=checks+1 end
local function near(actual,expected,label)
    check(type(actual)=='number' and math.abs(actual-expected)<1e-8,
        (label or '')..': '..tostring(actual)..' ~= '..tostring(expected))
end
local function copy(value)
    if type(value)~='table' then return value end
    local result={} for key,item in pairs(value) do result[key]=copy(item) end return result
end
local build='70961'
GetBuildInfo=function() return '12.1.5',build end
CreateFrame=function() return {RegisterEvent=function()end,SetScript=function()end} end
local LL={}
for _,file in ipairs({'Professions.lua','ProfessionModels.lua'}) do
    assert(loadfile('LootLiquidator/'..file))('LL',LL)
end
local exported=assert(loadfile('database/specialization-effects.lua'))()
LL.ItemDB={specializationRules=exported.specializationRules}
local de={name='Disenchant',recipeID=13262,inputCount=1}
local function facts(rarity)
    return {id=999990+rarity,expansionID=11,quality=rarity,classID=4}
end
local function context(node,rank,learned)
    local result={simulated=true,profileKind='manual-simulation',profession='Enchanting',
        skill=100,effectiveSkill=100,specialization='none',specializationPoints={}}
    if node then
        result.specializationPoints[tostring(node)]=rank
        if learned~=nil then result.learnedSpecializations={[tostring(node)]=learned} end
    end
    return result
end
local ranks={0,1,4,5,9,10,14,15,19,20,24,25,29,30}
-- Totals below include one learning reward only for positive invested ranks.
-- Learning at zero is tested separately because legacy zero entries are ambiguous.
local delegate={0,6,9,10,14,20,24,25,29,40,44,45,49,70}
local children={0,6,9,15,19,25,29,35,39,40,44,55,59,80}
local nodes={
    {id=107649,name='Disenchanting Delegate',rarity=3,totals=delegate},
    {id=107648,name='Dust Deliverer',rarity=2,totals=children},
    {id=107647,name='Shard Supplier',rarity=3,totals=children},
    {id=107646,name='Crystal Collector',rarity=4,totals=children},
}
local function apply(node,rank,learned,rarity)
    return LL:ApplySpecializationSkill(facts(rarity or node.rarity),de,context(node.id,rank,learned))
end
for _,node in ipairs(nodes) do
    for index,rank in ipairs(ranks) do
        local projected=apply(node,rank)
        near(projected.effectiveSkill,100+node.totals[index],node.name..' invested rank '..rank)
        near(projected.specializationSkillBonus or 0,node.totals[index],node.name..' exact skill contribution '..rank)
    end
    near(apply(node,0,true).effectiveSkill,105,node.name..' explicit learned zero receives learning reward')
    near(apply(node,0,false).effectiveSkill,100,node.name..' explicit unlearned zero receives no reward')
    near(apply(node,0,1).effectiveSkill,100,node.name..' truthy non-boolean does not establish learning')
    local numericKey=context(node.id,0)
    numericKey.learnedSpecializations={[node.id]=true}
    near(LL:ApplySpecializationSkill(facts(node.rarity),de,numericKey).effectiveSkill,105,
        node.name..' numeric learned-map key is accepted')
    local legacy=context()
    legacy.specializationPoints=nil
    legacy.specialization=node.id..'=0'
    near(LL:ApplySpecializationSkill(facts(node.rarity),de,legacy).effectiveSkill,100,
        node.name..' legacy explicit zero does not grant free learning')
    legacy.specialization=node.id..'=10'
    near(LL:ApplySpecializationSkill(facts(node.rarity),de,legacy).effectiveSkill,125-((node.id==107649) and 5 or 0),
        node.name..' saved positive point string establishes learning')
    for _,invalid in ipairs({-1,31,1.5,'10',math.huge}) do
        local input=context(node.id,invalid,true)
        check(LL:ApplySpecializationSkill(facts(node.rarity),de,input)==input,
            node.name..' invalid point allocation cannot receive even learning skill: '..tostring(invalid))
    end
    local input=context(node.id,0/0,true)
    check(LL:ApplySpecializationSkill(facts(node.rarity),de,input)==input,node.name..' NaN allocation is rejected')
    for _,rarity in ipairs({2,3,4}) do
        near(apply(node,30,nil,rarity).effectiveSkill,
            100+((node.id==107649 or rarity==node.rarity) and node.totals[#node.totals] or 0),
            node.name..' rarity '..rarity..' scope')
    end
    -- New learning/milestone observations and Crystal's inferred coefficient
    -- cannot retroactively alter the older source-build simulation.
    for _,older in ipairs({'70783','70960'}) do
        build=older
        near(apply(node,30,true).effectiveSkill,node.id==107646 and 100 or 130,
            node.name..' older build '..older..' retains only previously sourced per-point skill')
        near(apply(node,0,true).effectiveSkill,100,node.name..' older build does not acquire free learning')
    end
    build='70961'
end
local absent=context()
check(LL:ApplySpecializationSkill(facts(3),de,absent)==absent,'absent node points do not imply a learned tree')
local combined=context()
combined.specializationPoints=nil
combined.specialization='107649=30,107648=30,107647=30,107646=30'
for _,rarity in ipairs({2,3,4}) do
    local projected=LL:ApplySpecializationSkill(facts(rarity),de,combined)
    near(projected.effectiveSkill,250,'generic and matching-rarity nodes add exactly once for rarity '..rarity)
    near(LL:ApplySpecializationSkill(facts(rarity),de,projected).effectiveSkill,250,'replay does not double-add skill')
    near(combined.effectiveSkill,100,'caller-owned context is not mutated')
    projected.specialization='107649=1';projected.specializationPoints=nil
    near(LL:ApplySpecializationSkill(facts(rarity),de,projected).effectiveSkill,106,
        'lowering points recalculates from the stored base skill')
    projected.specialization='none';projected.specializationPoints=nil;projected.learnedSpecializations=nil
    near(LL:ApplySpecializationSkill(facts(rarity),de,projected).effectiveSkill,100,
        'resetting an applied allocation removes its previous bonus')
end
for _,kind in ipairs({'live','scanned'}) do
    local live=copy(combined)
    live.simulated=false;live.profileKind=kind;live.skill=159;live.effectiveSkill=159
    check(LL:ApplySpecializationSkill(facts(3),de,live)==live,'actual '..kind..' skill is not projected again')
end
local stale=copy(combined);stale.stale=true
check(LL:ApplySpecializationSkill(facts(3),de,stale)==stale,'stale manual context cannot acquire a fresh bonus')
local wrongEra=facts(3);wrongEra.expansionID=10
check(LL:ApplySpecializationSkill(wrongEra,de,combined)==combined,'Midnight arithmetic does not cross expansion scope')
check(LL:ApplySpecializationSkill(facts(3),{name='Prospect',recipeID=13262},combined)==combined,
    'disenchant skill cannot affect another processing method')

-- Corrupt numeric metadata fails closed. These cases exercise the public
-- runtime boundary with one real rule, rather than substituting a fake formula.
local original=LL.ItemDB
LL.db={}
local learnedInput={['107649']=true}
check(LL:SetManualProfessionProfile('Player','Enchanting',11,{enabled=true,skill=100,
    specialization='107649=0',learnedSpecializations=learnedInput}),'explicit learning state can be saved')
learnedInput['107649']=nil
check(LL:GetManualProfessionProfile('Player','Enchanting',11).learnedSpecializations['107649'],
    'saved learning state is copied from caller-owned input')
for _,invalid in ipairs({{['0']=true},{['-1']=true},{['107649']=false},{['107649']='true'}}) do
    check(not LL:SetManualProfessionProfile('Player','Enchanting',11,{learnedSpecializations=invalid}),
        'invalid learned state is rejected by the profile boundary')
end
local dust
for _,rule in ipairs(exported.specializationRules) do
    if rule.nodeID==107648 and (rule.kind=='skill-per-point' or rule.kind=='skill-milestones') then dust=rule end
end
check(dust~=nil,'real Dust Deliverer numeric rule exists')
local malformed={
    {name='milestone list type',skillMilestones='invalid'},
    {name='missing rank',skillMilestones={{skill=5}}},
    {name='zero rank',skillMilestones={{rank=0,skill=5}}},
    {name='negative rank',skillMilestones={{rank=-1,skill=5}}},
    {name='fractional rank',skillMilestones={{rank=5.5,skill=5}}},
    {name='rank beyond cap',skillMilestones={{rank=31,skill=5}}},
    {name='duplicate rank',skillMilestones={{rank=5,skill=5},{rank=5,skill=10}}},
    {name='descending rank',skillMilestones={{rank=10,skill=5},{rank=5,skill=10}}},
    {name='missing skill',skillMilestones={{rank=5}}},
    {name='negative skill',skillMilestones={{rank=5,skill=-1}}},
    {name='infinite skill',skillMilestones={{rank=5,skill=math.huge}}},
    {name='NaN skill',skillMilestones={{rank=5,skill=0/0}}},
    {name='negative learning skill',learningSkill=-1},
    {name='non-numeric learning skill',learningSkill='5'},
    {name='infinite learning skill',learningSkill=math.huge},
    {name='negative build gate',skillMilestoneBuild=-1},
    {name='fractional build gate',skillMilestoneBuild=70961.5},
    {name='non-numeric build gate',skillMilestoneBuild='70961'},
}
for _,case in ipairs(malformed) do
    local rule=copy(dust)
    for key,value in pairs(case) do if key~='name' then rule[key]=value end end
    LL.ItemDB={specializationRules={rule}}
    local input=context(107648,30,true)
    check(LL:ApplySpecializationSkill(facts(2),de,input)==input,'malformed '..case.name..' rejects the entire rule')
end
LL.ItemDB=original
print('PASS: '..checks..' sourced disenchant skill boundaries, learned states, scope, build gates and invalid metadata assertions')
