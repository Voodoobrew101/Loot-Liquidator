local LL={db={characters={}},CharacterKey=function()return 'Untrained - Realm'end}
CreateFrame=function()return {RegisterEvent=function()end,SetScript=function()end}end
assert(loadfile('LootLiquidator/ProfessionCatalog.lua'))('LL',LL)
assert(loadfile('LootLiquidator/Professions.lua'))('LL',LL)
-- No trade-skill window, learned profession, saved scan or trait config exists.
C_TradeSkillUI=nil;C_Traits=nil;C_ProfSpecs=nil
assert(LL.ProfessionCatalogBuild=='12.1.5.70783')
local count,paths=0,0
local supported={Alchemy=true,Blacksmithing=true,Enchanting=true,Engineering=true,
    Inscription=true,Jewelcrafting=true,Leatherworking=true,Mining=true,Tailoring=true}
for key,catalog in pairs(LL.ProfessionCatalog) do
    count=count+1
    local profession,expansion=key:match('^(.-):(%d+)$')
    assert(supported[profession]and(tonumber(expansion)==9 or tonumber(expansion)==10 or tonumber(expansion)==11),
        'Only supported item-processing control catalogs ship')
    local options=LL:GetProfessionUIOptions('Untrained - Realm',profession,tonumber(expansion))
    assert(options.source=='Wago' and #options.nodes==#catalog.nodes)
    local ids={}
    for _,node in ipairs(options.nodes) do
        assert(not ids[node.id] and node.name~='' and node.tab~='' and node.maxRank>0)
        ids[node.id]=true;paths=paths+1
        assert(node.requirementsKnown==false)
        assert(LL:ProfessionNodeRequirements(node,{},0)==nil,'unknown requirements must stay editable')
    end
    for _,node in ipairs(options.nodes) do assert(not node.parentID or ids[node.parentID]) end
end
assert(count==27 and paths==384,'Shared method-scoped controls and their prerequisites remain')
local catalog=LL:GetProfessionUIOptions('Untrained - Realm','Enchanting',11)
local crystal
for _,node in ipairs(catalog.nodes) do if node.id==107646 then crystal=node end end
assert(crystal.name=='Crystal Collector' and crystal.maxRank==30 and crystal.parentID==107649)
assert(crystal.tab=='Disenchanting Delegate')
crystal.name='changed'
assert(LL:GetProfessionUIOptions('Untrained - Realm','Enchanting',11).nodes[1].name~='changed','do not mutate bundled data')
-- Optional static client metadata enriches thresholds without an owned profession.
C_ProfSpecs={GetPerksForPath=function()return {{perkID=5}}end,
    GetUnlockRankForPerk=function()return 10 end,GetDescriptionForPerk=function()return 'A researched client description'end}
local enriched=LL:GetProfessionUIOptions('Untrained - Realm','Enchanting',11)
assert(enriched.nodes[1].milestones[1].rank==10)
assert(LL.ProfessionCatalog['Enchanting:11'].nodes[1].milestones==nil)
assert(LL.ProfessionCatalog['Herbalism:11']==nil and LL.ProfessionCatalog['Skinning:11']==nil
    and LL.ProfessionCatalog['Fishing:11']==nil,'Retired simulated catalogs must not ship')
assert(#LL.ProfessionCatalog['Mining:9'].nodes==0,'World-gathering/refining controls cannot be substituted for Smelt controls')
local diamond={}
for _,node in ipairs(LL.ProfessionCatalog['Jewelcrafting:11'].nodes)do diamond[node.id]=true end
for id=106978,106981 do assert(diamond[id],'Every native ore-specific Diamond unlock remains')end
local milling={}
for _,node in ipairs(LL.ProfessionCatalog['Inscription:11'].nodes)do milling[node.id]=true end
for _,id in ipairs({106278,106280,109653,109655,109660})do assert(milling[id],'Native Milling/value controls remain')end
print('PASS: 27 scoped processing catalogs, native DE/Diamond/Milling controls, prerequisites and static milestone enrichment')
