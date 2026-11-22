-- Compare cached classification with the previous complete native-node walk.
-- Full compiled profession profiles are used; no invented large payloads.
local LL={}
CreateFrame=function()return {RegisterEvent=function()end,SetScript=function()end}end
GetTime=function()return 100 end;time=GetTime
GetBuildInfo=function()return '12.1.5','70961' end
for _,name in ipairs({'ItemDBRuntime.lua','ProfessionCatalog.lua','Professions.lua','ProfessionModels.lua'})do
    assert(loadfile('LootLiquidator/'..name))('LL',LL)
end
local originalFilter=LL.ProfessionEffectAffectsTooltip
local visits=0
LL.ProfessionEffectAffectsTooltip=function(self,...)
    visits=visits+1
    return originalFilter(self,...)
end
local profiles=assert(LL.ItemDB.professionProfiles.profiles)
local nodes,profileCount={},0
for _,profile in pairs(profiles)do
    profileCount=profileCount+1
    for id in pairs(profile.nodes or {})do nodes[tostring(id)]=true end
end
local nodeCount=0;for _ in pairs(nodes)do nodeCount=nodeCount+1 end
assert(profileCount>10 and nodeCount>500,'Regression must load the full native profession trees')

local function previousClassification(expansion)
    local irrelevant={}
    for key,profile in pairs(profiles)do
        for id,node in pairs(profile.nodes or {})do
            local relevant=false
            local function effects(list)
                for _,effect in ipairs(list or {})do
                    if (effect.scope or {}).scopeUnknown
                        or originalFilter(LL,effect,'Enchanting',expansion,'Disenchant')then relevant=true end
                end
            end
            if key=='Enchanting:'..tostring(expansion)or expansion==nil and key:match('^Enchanting:')then
                effects(node.pointEffects);effects(node.learningEffects)
                for _,milestone in ipairs(node.milestones or {})do effects(milestone.effects)end
            end
            if not relevant then irrelevant[tostring(id)]=true end
        end
    end
    return irrelevant
end
local checks=0
local function context(expansion)
    return {profession='Enchanting',effectiveSkill=100,specialization='none',expansionID=expansion}
end
for _,scope in ipairs({'*',9,10,11})do
    local expansion=scope~='*'and scope or nil
    local expected=previousClassification(expansion)
    local baseline=assert(LL:DisenchantObservationProfileKey(context(expansion)))
    local cached=assert(LL._disenchantNodeScopeCache.scopes[tostring(scope)])
    for id in pairs(nodes)do assert(cached[id]==expected[id],'Native-node classification changed: '..scope..'/'..id)end
    for id in pairs(cached)do assert(expected[id],'Cached classification added a native node')end
    local traversed=visits
    for id in pairs(nodes)do
        local result=expected[id]and baseline or nil
        for _,field in ipairs({'specializationPoints','disenchantSpecializationPoints',
            'learnedSpecializations','disenchantLearnedSpecializations'})do
            local c=context(expansion);c[field]={[id]=field:find('earned',1,true)and true or 1}
            assert(LL:DisenchantObservationProfileKey(c)==result,'Profile matching changed for '..field..'/'..id)
            checks=checks+1
        end
        local c=context(expansion);c.specialization=id..'=1'
        assert(LL:DisenchantObservationProfileKey(c)==result,'Raw specialization matching changed: '..id)
        checks=checks+1
    end
    assert(visits==traversed,'Repeated observation matching traversed the native profession trees')
    local c=context(expansion);c.inputExpansionID=c.expansionID;c.expansionID=nil
    assert(LL:DisenchantObservationProfileKey(c)==baseline,'Input-expansion fallback changed the profile key')
    c=context(expansion);c.buffs={['999999999']=true}
    assert(LL:DisenchantObservationProfileKey(c)==baseline,'Unmodeled auras changed matching')
    c=context(expansion);c.fieldStatus={effectiveSkill='unknown'}
    assert(LL:DisenchantObservationProfileKey(c)==nil,'Unknown skills became a measured profile')
end

-- Replacing immutable source identities/revisions or the filter must refresh.
local function refreshed(change)
    local before=LL._disenchantNodeScopeCache
    change()
    assert(LL:DisenchantObservationProfileKey(context(11)))
    assert(LL._disenchantNodeScopeCache~=before,'Native classification did not refresh after source change')
end
refreshed(function()LL.ItemDB.version=tostring(LL.ItemDB.version)..':scope-regression'end)
refreshed(function()LL.ItemDB.professionProfiles.revision='scope-regression'end)
refreshed(function()LL.ItemDB.professionProfiles.version='scope-regression'end)
refreshed(function()
    local replacement={};for k,v in pairs(profiles)do replacement[k]=v end
    LL.ItemDB.professionProfiles.profiles=replacement
end)
refreshed(function()
    local replacement={};for k,v in pairs(LL.ItemDB.professionProfiles)do replacement[k]=v end
    LL.ItemDB.professionProfiles=replacement
end)
refreshed(function()
    local replacement={};for k,v in pairs(LL.ItemDB)do replacement[k]=v end
    LL.ItemDB=replacement
end)
refreshed(function()
    LL.ProfessionEffectAffectsTooltip=function(self,...)return originalFilter(self,...)end
end)
print(('PASS: %d profile checks preserve %d native nodes across expansions; repeated matches skip tree traversal and source changes refresh'):format(checks,nodeCount))
