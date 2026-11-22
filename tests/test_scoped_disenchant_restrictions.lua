-- Exact-instance native eligibility wins; unused catalog warnings stay offline.
local checks=0
local function check(v,why) assert(v,why);checks=checks+1 end
CreateFrame=function() return {RegisterEvent=function()end,SetScript=function()end} end
SlashCmdList={}
GetTime=function() return 100 end
local build=70961
GetBuildInfo=function() return '12.1.5',tostring(build) end
local base={recordID='midnight-20261119-1921-003',sourceURL='https://www.wowdb.com/items/251786-ever-collapsing-void-fissure',
    rawSHA256=string.rep('a',64),notes='Base197 catalog only; not all scaled variants',
    scope={kind='catalog-base-variant',itemLevel=197,sourceBuild=63534}}
local restrictions={noDisenchant={38},researchNoDisenchant={},researchNoDisenchantPolicy='native-proof-only',
    researchNoDisenchantObservations={{itemID=251786,observations={base}}}}
local LL={db={},ItemDB={schemaVersion=1,processing={},restrictions=restrictions}}
assert(loadfile('LootLiquidator/Core.lua'))('LL',LL)
assert(loadfile('LootLiquidator/Database.lua'))('LL',LL)
check(LL.ResearchNoDisenchantObservations==nil,'offline observations have no runtime alias')
check(LL.ResearchDisenchantRestrictionWarnings==nil,'unused catalog warning scanner is removed')
local function link(id,bonus)
    return 'item:'..id..'::::::::90:0:0:0:1:'..bonus
end
local function facts(level,bonus,id)
    return {id=id or 251786,classID=4,quality=4,equipLoc='INVTYPE_TRINKET',itemLevel=level,
        expansionID=11,link=link(id or 251786,bonus or 111),context={}}
end
local function eligible(f)
    LL._deRestrictionCache={}
    return LL:DisenchantEligibility(f)
end
C_TooltipInfo={GetHyperlink=function()return{id=251786,lines={}}end,
    GetItemByID=function()return{id=251786,lines={{leftText='Cannot be disenchanted'}}}end}
local f=facts(197)
local ok,reason=eligible(f)
check(ok and reason:match('Candidate only'),'base catalog is not positive native proof or hard denial')
check(not f.researchDisenchantWarnings,'unused source warnings are not copied into item facts')
f=facts(292)
ok,reason=eligible(f)
check(ok and reason:match('Candidate only'),'292bonus item not denied by197 catalog')
check(not f.researchDisenchantWarnings,'different item level does not attach offline observations')
check(not f.nativeDisenchantVerified,'absent native denial is not a positive verification')
C_TooltipInfo.GetHyperlink=function()return nil end
f=facts(292)
check(eligible(f),'unknown native bonus tooltip not replaced by base-ID warning')
C_TooltipInfo.GetHyperlink=function()return{id=251786,lines={{leftText='Cannot be disenchanted'}}}end
f=facts(292)
ok,reason=eligible(f)
check(not ok and reason=='Blizzard: Cannot be disenchanted','actual native exact-instance denial still wins')
C_TooltipInfo=nil
f=facts(292,111,38)
ok,reason=eligible(f)
check(not ok and reason=='Item database: Cannot be disenchanted','native DB2 hard flag unchanged')
-- Legacy observation payloads have no eligibility effect at any bonus scope.
local scoped={recordID='exact-bonus',scope={itemLevel=292,bonusIDs={111}}}
restrictions.researchNoDisenchantObservations[1].observations[2]=scoped
f=facts(292,111)
check(eligible(f) and not f.researchDisenchantWarnings,'matching catalog bonus neither denies nor adds unused fields')
f=facts(292,222)
check(eligible(f) and not f.researchDisenchantWarnings,'different bonus remains eligible without unused fields')
f=facts(292);f.link='item:251786'
check(eligible(f) and not f.researchDisenchantWarnings,'missing bonus identity is not a catalog denial')
scoped.scope.itemLink=link(251786,111)
f=facts(292,111)
check(eligible(f) and not f.researchDisenchantWarnings,'matching source itemlink is not a native restriction')
f=facts(292,222)
check(eligible(f) and not f.researchDisenchantWarnings,'different source itemlink is not a native restriction')
local restriction,warnings=LL:ExternalDisenchantRestriction(f)
check(restriction==nil and warnings==nil,'restriction lookup has no unused warning return')
-- Old packaged catalog IDs must not survive as hard restrictions after reload.
restrictions.researchNoDisenchant={251786};restrictions.researchNoDisenchantPolicy=nil
LL.ItemRestrictions[251786]=true
LL:UnpackItemDBTables()
check(not LL.ItemRestrictions[251786] and LL.ItemRestrictions[38],'retire only legacy catalog additions, preserve native list')
f=facts(292);check(eligible(f),'old flat catalog entry cannot still block292 variant')
-- A verified new native all-variant bit is valid at its stated build.
restrictions.researchNoDisenchant={251799};restrictions.researchNoDisenchantPolicy='native-proof-only'
restrictions.researchNoDisenchantGlobalProofs={[251799]={{build=70961}}}
LL:UnpackItemDBTables()
check(not eligible(facts(292,111,251799)),'explicit verified native proof blocks its matching build')
build=70962
check(eligible(facts(292,111,251799)),'different-build research flag does not become timeless proof')
check(not eligible(facts(292,111,38)),'genuine native DB2 prohibition survives research build mismatch')
print('SCOPED DISENCHANT RUNTIME: '..checks..' checks passed')
