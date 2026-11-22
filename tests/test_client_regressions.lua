-- Regressions from alpha3 client reports. Real shipped DB, then scoped fixtures.
local LL={}
UnitName=function() return 'Tester' end
GetRealmName=function() return 'Realm' end
GetBuildInfo=function() return '12.1.5','123456' end
GetTime=function() return 100 end
time=function() return 100 end
CreateFrame=function()
    return {RegisterEvent=function()end,SetScript=function()end}
end
for _,file in ipairs({'ItemDBRuntime.lua','ProfessionModels.lua',
    'Database.lua','Professions.lua','ConversionEngine.lua','Badges.lua'}) do
    assert(loadfile('LootLiquidator/'..file))('LootLiquidator',LL)
end
LL.db={characters={['Tester - Realm']={details={},professions={Enchanting={}},recipes={}}},
    processingModes={D=1,S=1,M=1,P=1},tooltipDetail=3,showMaterialBreakdown=true,showTooltips=true}
LL:MigrateEvidenceSettings();assert(LL:InitializeItemDB())
local gear={id=272234,quality=4,classID=4,expansionID=11,count=1}
local option={name='Disenchant',recipeID=13262,inputCount=1}
local function finite(value)return type(value)=='number'and value==value and math.abs(value)<math.huge end
local function categoryMaterials(model,legacyEnabled)
    assert(model and model.isDisenchantCategory and model.gearKey=='gear:11:4:armor'
        and model.inputCount==1,'ordinary epic armor resolves its disenchant category')
    assert(model.sources and model.sources.itemdb>0,'independent category evidence remains available')
    assert(legacyEnabled and model.sources.legacy and model.sources.legacy>0
        or not legacyEnabled and not model.sources.legacy,'legacy source participation follows its setting')
    local byID={}
    for _,material in ipairs(model.materials)do
        local id=material.id
        assert(finite(id)and id>0 and id%1==0 and not byID[id],'category outputs have distinct real item IDs')
        assert(LL.ItemDB.professionProfiles.items[id],'category output retains native item identity')
        assert(finite(material.expectedQuantity)and material.expectedQuantity>=0,'category output has a usable quantity')
        assert(material.chance==nil or finite(material.chance)and material.chance>=0 and material.chance<=1,
            'known output chances remain probabilities')
        assert(material.minQuantity==nil or finite(material.minQuantity)and material.minQuantity>=0,'valid lower quantity bound')
        assert(material.maxQuantity==nil or finite(material.maxQuantity)and material.maxQuantity>=0,'valid upper quantity bound')
        assert(not material.minQuantity or not material.maxQuantity or material.maxQuantity>=material.minQuantity,
            'known output range remains ordered')
        local weight,total=0,0
        for source,share in pairs(material.sourceContributions or{})do
            local evidence=material.sourceEstimates and material.sourceEstimates[source]
            assert(finite(share)and share>0 and model.sources[source]and model.sources[source]>0,
                'every contributing output source is enabled')
            assert(evidence and finite(evidence.expectedQuantity)and evidence.expectedQuantity>=0
                and evidence.inputCount==1,'every output retains its source quantity and denominator')
            weight=weight+share;total=total+share*evidence.expectedQuantity
        end
        assert(math.abs(weight-1)<1e-9 and math.abs(material.expectedQuantity-total)<1e-9,
            'output quantity matches its actual weighted source evidence')
        byID[id]=material
    end
    for _,id in ipairs({243605,243606})do
        local crystal=byID[id]
        assert(crystal and crystal.expectedQuantity>0 and finite(crystal.chance)and crystal.chance>0,
            'both supported epic crystal identities retain positive quantities and chances')
    end
    return byID
end
-- Legacy is a weak default contributor; independent category studies can
-- legitimately add supported materials beyond its two primary crystal rows.
local model,reason=LL:ComputeEvidenceModel(gear,option,nil,1,{})
local defaults=categoryMaterials(model,true)
local defaultMeans={}
for id,material in pairs(defaults)do defaultMeans[id]=material.expectedQuantity end
-- A player who switches legacy off still gets that choice honoured.
LL.db.source_legacy_enabled=false;LL._processingModelCache=nil
model,reason=LL:ComputeEvidenceModel(gear,option,nil,1,{})
-- Independent category studies can answer this item with legacy disabled.
-- The user's choice disables that source, not independently sourced ItemDB.
categoryMaterials(model,false)
-- Old saved data from before schema 2 had legacy off by default: migrate it on once.
local old={source_legacy_enabled=false,evidenceSchemaVersion=1};local saved=LL.db;LL.db=old
LL:MigrateEvidenceSettings();assert(old.source_legacy_enabled==true and old.evidenceSchemaVersion==2)
old.source_legacy_enabled=false;LL:MigrateEvidenceSettings();assert(old.source_legacy_enabled==false,'later manual choice respected')
LL.db=saved
LL.db.source_legacy_enabled=true
model=LL:ComputeEvidenceModel(gear,option,nil,1,{})
local restored=categoryMaterials(model,true)
for id,mean in pairs(defaultMeans)do
    assert(restored[id]and math.abs(restored[id].expectedQuantity-mean)<1e-12,
        'reenabling legacy restores the default output identities and quantities')
end
for id in pairs(restored)do assert(defaultMeans[id]~=nil,'reenabling legacy does not invent extra outputs')end
-- Specific item research must be searched in addition to expansion/rarity pools.
local function field(value) return {value=value,status=value and 'measured' or 'unknown',confidence=80} end
local record={recordID='specific-gear',method='Disenchant',profession='Enchanting',inputItemID=272234,
    inputCount=1,recipeID=13262,sourceKey='itemdb',source='independent fixture',studyID='study',
    expansionID=11,samples=60,referenceConditions={},materials={{id=243605,
        expectedQuantity=field(2),dropChance=field(nil),minQuantity=field(nil),maxQuantity=field(nil)}}}
LL.ItemDB={schemaVersion=1,processing={record},mechanicRules={}}
LL.db.source_legacy_enabled=false
assert(LL:InitializeItemDB())
model=LL:ComputeEvidenceModel(gear,option,nil,1,{})
assert(model and model.materials[1].expectedQuantity==2,'item-specific disenchant evidence was dropped')
local none=LL:ComputeEvidenceModel(gear,option,nil,2,{})
assert(not none,'personal-only policy must not borrow external yields')
-- Candidate names may be shown to non-enchanters; no numeric EV/price is invented.
LL.ResolveEvidenceModel=function() return nil,'Insufficient Data: matching sources disabled' end
LL.EligibleDisenchant=function() return true end
LL.DisenchantExpansion=function(_,f)return f.expansionID end
LL.GetLearnedDisenchantEstimate=function()return nil end
LL.GetOutputPrice=function()return 10000 end
local estimate=LL:EvaluateDisenchant(gear)
assert(estimate.yieldModel and #estimate.yieldModel.materials==2 and not estimate.value)
for _,material in ipairs(estimate.yieldModel.materials) do
    assert(material.expectedQuantity==nil and material.chance==nil and material.netExpectedValue==nil)
end
assert(estimate.yieldModel.partialPrice)
-- Smelting remains visible when recipe/yield access is unknown.
LL.GetBadgeColor=function()return {1,1,1}end
LL.MarkupColor=function()return '|cffffffff'end
LL.Money=function(_,value)return tostring(value)end
LL.ProfessionProgression=function()return {}end
local tip={lines={}}
function tip:AddLine(text)self.lines[#self.lines+1]=text end
function tip:AddDoubleLine(a,b)self.lines[#self.lines+1]=a..' '..b end
local decision={facts={id=2770,classID=7},count=1,conversionOptions={{name='Smelt',letter='S',available=false,
    why='No character with verified Smelt Copper recipe',note='Insufficient Data: matching yield sources disabled'}}}
LL.TooltipConversionOptions=nil -- This diagnostic fixture renders explicitly supplied options.
LL.db.professionTooltipProfiles={Mining="@hypothetical"};LL.db.showProfessionDetails=true;LL.db.showResearchDetails=true
LL:AppendRecommendationTooltip(tip,decision)
local text=table.concat(tip.lines,'\n')
assert(text:find('Smelting',1,true) and not text:find('verified Smelt Copper',1,true) and not text:find('sources disabled',1,true),
    'compact method header stays visible without access/source explanation panels')
assert(decision.conversionOptions[1].available==false and decision.conversionOptions[1].value==nil,
    'compact presentation does not grant access or fabricate value')
-- Built-in specialization labels/ranks are cached only for the selected owner.
local char=LL.db.characters['Tester - Realm']
char.details[300]={parentName='Enchanting',name='Midnight Enchanting'}
C_TradeSkillUI={}
C_ProfSpecs={GetConfigIDForSkillLine=function()return 7 end,GetSpecTabIDsForSkillLine=function()return {9}end,
    GetRootPathForTab=function()return 12 end,GetChildrenForPath=function()return nil end,
    GetSpendEntryForPath=function()return 50 end,GetTabInfo=function()return {name='Disenchanting'}end,
    GetDescriptionForPath=function()return 'Blizzard description' end}
C_Traits={GetNodeInfo=function()return {currentRank=4,maxRanks=30}end,
    GetEntryInfo=function()return {definitionID=99}end,GetDefinitionInfo=function()return {spellID=1000}end}
C_Spell={GetSpellName=function()return 'Designated Disenchanter' end}
C_UnitAuras={GetAuraDataByIndex=function(_,index)if index==1 then return {spellId=2000,name='Artisan Tea'} end end}
local catalog=LL:GetProfessionUIOptions('Tester - Realm','Enchanting',11)
assert(catalog.nodes[1].name=='Designated Disenchanter' and catalog.nodes[1].maxRank==30)
assert(#catalog.buffs==0 and not char.researchProfiles,'unmodeled active auras cannot enter the profession catalog or invent a snapshot')
LL.db.characters['Alt - Realm']={professionOptions={['Enchanting:11']=catalog}}
C_ProfSpecs.GetConfigIDForSkillLine=function()error('offline alt must not read live traits')end
assert(LL:GetProfessionUIOptions('Alt - Realm','Enchanting',11)==catalog)
assert(LL:ProfessionDetailMatchesExpansion({name='Dragon Isles Enchanting'},9))
assert(LL:ProfessionDetailMatchesExpansion({name='Khaz Algar Enchanting'},10))
assert(not LL:ProfessionDetailMatchesExpansion({name='Khaz Algar Enchanting'},11))
local factor=LL:ProfessionFactor({skillFactors={{skill=0,factor=1},{skill=100,factor=2}},referenceProfile={}},
    {effectiveSkill=50,buffs={['2000']=true}})
assert(not factor,'unmodeled buff selections must not silently inherit a numeric skill model')
print('PASS: exact-item disenchant lookup, source gates, non-economic candidate outputs, visible Smelt diagnostics, Blizzard catalog and offline isolation')

-- Shipped per-item NO_DISENCHANT exceptions take priority over profession On.
SlashCmdList={}
local restricted={db={ignoredItems={}}}
-- C3: the no-disenchant list ships inside ItemDB and is unpacked by Database.lua.
assert(loadfile('LootLiquidator/ItemDBRuntime.lua'))('LootLiquidator',restricted)
assert(loadfile('LootLiquidator/Database.lua'))('LootLiquidator',restricted)
local restrictedCount,hintCount=0,0
for _ in pairs(restricted.ItemRestrictions) do restrictedCount=restrictedCount+1 end
for _ in pairs(restricted.DB2Processable) do hintCount=hintCount+1 end
-- D1c4 (changed on purpose): the research team's no-disenchant flags add to the
-- 21061 game-file entries; none are removed.
assert(restrictedCount==21061+#restricted.ItemDB.restrictions.researchNoDisenchant and hintCount==140,'C3: full no-disenchant list and processing hints unpacked from ItemDB')
assert(#restricted.ItemDB.restrictions.noDisenchant==21061,'D1c4: game-file list unchanged')
assert(restricted.ItemRestrictionsBuild=='12.1.7.70493' and restricted.DB2Processable[765]=='Mill' and restricted.DB2Processable[2770]=='Prospect')
assert(restricted.LegacyDB==restricted.ItemDB.legacy and #restricted.LegacyDB.processing>0,'C3: old estimates come from ItemDB')
assert(loadfile('LootLiquidator/Core.lua'))('LootLiquidator',restricted)
local holiday={id=143902,quality=4,classID=4,equipLoc='INVTYPE_FINGER',expansionID=11}
local eligible,why=restricted:DisenchantEligibility(holiday)
assert(not eligible and why:find('Cannot be disenchanted',1,true))
local worn={id=272147,quality=4,classID=4,equipLoc='INVTYPE_FINGER',expansionID=11,
    context={isSoulbound=true},link='item:272147'}
assert(restricted:DisenchantEligibility(worn),'wearing or soulbinding eligible gear does not itself forbid disenchant')
print('PASS: holiday item exception preserved; ordinary worn gear remains a candidate')
