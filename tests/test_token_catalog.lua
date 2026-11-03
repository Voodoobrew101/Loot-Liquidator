-- Synthetic reviewed relationships test routing only; no real approval is invented.
local outdir=assert(arg[1])
local function clone(t) if type(t)~='table' then return t end local n={}for k,v in pairs(t)do n[k]=clone(v)end return n end
GetBuildInfo=function()return 'synthetic','150','Oct 29 2026',120105 end
WOW_PROJECT_ID=1;WOW_PROJECT_MAINLINE=1
GetTime=function()return 100 end
time=function()return 1000 end
CreateFrame=function()return {RegisterEvent=function()end,SetScript=function()end}end
local approved={recordID='synthetic-only',tokenID=900001,kind='open',gameMode='Retail',inputClassID=15,
    patchStartBuild=100,patchEndBuild=200,rewards={900010,900011},listComplete=true,
    requirementsReviewed=true,requirements={},evidenceStatus='VERIFIED_RELATIONSHIP',
    independentReview='APPROVED',reviewedBy='synthetic fixture',confidence0to100=90,
    sourceRevision='fixture',sourceURLs={'https://example.test/one','https://example.test/two'}}
local LL={ItemDB={schemaVersion=1,processing={},tokenRewards={clone(approved)}},db={}}
assert(loadfile('LootLiquidator/Database.lua'))('LootLiquidator',LL)
assert(loadfile('LootLiquidator/Tokens.lua'))('LootLiquidator',LL)
assert(not LL.itemDBError)
-- A record marked APPROVED still needs the full review.
for field,value in pairs({listComplete=false,requirementsReviewed=false,
    sourceRevision='',confidence0to100=89,reviewedBy=''}) do
    local bad=clone(approved);bad[field]=value;assert(not LL:ValidateTokenCatalog({bad}),field)
end
-- C4b3 (owner, session 15; changed on purpose): an unreviewed research list counts at its
-- confidence with one https source and no class ID; no source, no confidence, or REJECTED
-- still doesn't.
local research={recordID='v3token:900006',tokenID=900006,kind='open',gameMode='Retail',
    patchStartBuild=1,patchEndBuild=2147483647,rewards={900010},listComplete=false,requirementsReviewed=false,
    requirements={},evidenceStatus='RESEARCH_RELATIONSHIP',independentReview='NOT_REVIEWED',confidence0to100=40,
    sourceRevision='fixture',sourceURLs={'https://example.test/one'}}
assert(LL:ValidateTokenCatalog({research}),'unreviewed research list accepted')
for field,value in pairs({sourceURLs={},confidence0to100=false,evidenceStatus='REJECTED',sourceRevision=''}) do
    local bad=clone(research);bad[field]=value~=false and value or nil;assert(not LL:ValidateTokenCatalog({bad}),field)
end
bad=clone(research);bad.requirements={questID=1};assert(not LL:ValidateTokenCatalog({bad}),'unchecked requirement still refused')
bad=clone(approved);bad.requirements={questID=1};assert(not LL:ValidateTokenCatalog({bad}))
bad=clone(approved);bad.expectedQuantity=1;assert(not LL:ValidateTokenCatalog({bad}))
bad=clone(approved);bad.sourceOrigin='ATT';assert(not LL:ValidateTokenCatalog({bad}))
bad.licenseSPDX='MIT';bad.licenseText='AllTheThings: Permission is hereby granted';assert(LL:ValidateTokenCatalog({bad}))
bad=clone(approved);bad.sourceURLs={approved.sourceURLs[1],approved.sourceURLs[1]};assert(not LL:ValidateTokenCatalog({bad}))
bad=clone(approved);bad.kind='exchange';assert(not LL:ValidateTokenCatalog({bad}))
bad.costs={['900010']={{kind='item',id=900001,quantity=1}},['900011']={{kind='item',id=900001,quantity=1},{kind='money',quantity=20}}}
assert(LL:ValidateTokenCatalog({bad}))
local overlap=clone(approved);overlap.recordID='second';assert(not LL:ValidateTokenCatalog({approved,overlap}))
assert(not LL:ValidateTokenCatalog({named=approved}))
-- C6 (changed on purpose): AllTheThings was removed. Tokens come only from
-- ItemDB's catalog; a loaded ATT and an old saved ATT cache are never read.
local calls=0
C_AddOns={IsAddOnLoaded=function() calls=calls+1;error('token lookup must not query ATT') end}
AllTheThings={SearchForField=function()error('must not search ATT')end}
local collected=false
C_TransmogCollection={GetItemInfo=function()return 1,2 end,GetAppearanceSourceInfo=function()return {isCollected=collected}end}
local f={id=900001,classID=15,equipLoc='',link='item:900001'}
local token=assert(LL:TokenInfo(f));assert(token.standalone and token.possibleMissingAppearance and calls==0)
assert(LL:StandaloneTokenInfo({id=279576,classID=12,equipLoc='INVTYPE_NON_EQUIP_IGNORE'})==nil)
local realSignature=GetBuildInfo
GetBuildInfo=function()return 'synthetic','unknown','Oct 29 2026',120105 end
assert(LL:StandaloneTokenInfo(f)==nil,'unparseable build must not admit a catalog record')
GetBuildInfo=nil
assert(LL:StandaloneTokenInfo(f)==nil)
GetBuildInfo=realSignature
WOW_PROJECT_ID=2;assert(LL:TokenInfo(f)==nil);WOW_PROJECT_ID=1
collected=true;LL:InvalidateTokenCache();token=LL:TokenInfo(f);assert(not token.possibleMissingAppearance)
assert(LL:TokenInfo({id=900001,classID=7,equipLoc=''})==nil)
assert(LL:TokenInfo({id=900001,classID=15,equipLoc='INVTYPE_HEAD'})==nil)
GetBuildInfo=function()return 'synthetic','201','Oct 29 2026',120105 end
assert(LL:TokenInfo(f)==nil)
GetBuildInfo=function()return 'synthetic','150','Oct 29 2026',120105 end
LL.ItemDB.tokenRewards[1].evidenceStatus='REJECTED';assert(LL:TokenInfo(f)==nil)
LL.ItemDB.tokenRewards[1].evidenceStatus='VERIFIED_RELATIONSHIP'
-- C4b3: an unreviewed list works too, labelled, with its confidence carried along.
LL.ItemDB.tokenRewards[1].independentReview='PENDING';LL:InvalidateTokenCache()
local unreviewed=assert(LL:TokenInfo(f),'unreviewed list used')
assert(unreviewed.source:find('not yet reviewed',1,true) and unreviewed.catalogConfidence==90 and not unreviewed.catalogReviewed)
LL.ItemDB.tokenRewards[1].independentReview='APPROVED';LL:InvalidateTokenCache()
assert(LL:TokenInfo(f).catalogReviewed)
-- An old saved ATT cache stays in saved data (never thrown away) but is not used.
LL.db.attRewardCache={['900002']={kind='open',rewards={900010}}}
LL.db.enableATTIntegration=true
assert(LL:TokenInfo({id=900002,classID=15,equipLoc=''})==nil,'saved ATT cache is not a token source')
assert(LL.db.attRewardCache['900002'],'saved ATT cache left untouched')
for _,name in ipairs({'ATTTokenInfo','ATTAvailable','ATTResearchExport','ATTResearchStatus','StartATTCacheUpdate',
    'HarvestATTItemMetadata','ATTCacheStatus','RememberATTItem','ATTTokenDiagnostics','ImportLegacyTokenCandidates'}) do
    assert(LL[name]==nil,name..' removed')
end
assert(calls==0)
-- C4b1: the compiler takes checked token lists from the research team's ItemDB
-- export (database/research/itemdb.lua, field tokenRewards) into the SAME
-- generated ItemDB. (Before C4b1 they came from database/records.lua; changed on
-- purpose: the owner wants the research team, not this branch, to approve them.)
local originalLoadfile,originalArg=loadfile,arg
local researchTokens,recordsTokens={approved},nil
loadfile=function(path)
    if path=='database/att-token-baselines.lua' then return function()return {schemaVersion=1,tokenRewards={}}end end
    if path=='database/research/itemdb.lua' then
        local real=assert(originalLoadfile(path))
        return function() local r=real();r.tokenRewards=researchTokens;return r end
    end
    if path=='database/records.lua' then return function()return {tokenRewards=recordsTokens,processing={},mechanicRules={}}end end
    return originalLoadfile(path)
end
arg={outdir..'/TokenFixture.lua','database/evidence-baselines.lua','tests/fixtures/research-v3-empty.lua'}
assert(originalLoadfile('tools/compile_itemdb.lua'))()
local compiled={};assert(originalLoadfile(outdir..'/TokenFixture.lua'))('LootLiquidator',compiled)
assert(#compiled.ItemDB.tokenRewards==1 and compiled.ItemDB.tokenRewards[1].tokenID==900001)
assert(#compiled.ItemDB.buildReport.tokenRewardsSkipped==0)
-- A record that fails the check is skipped with its reason; the good one ships.
local unchecked=clone(approved);unchecked.recordID='unchecked';unchecked.tokenID=900002;unchecked.sourceURLs={}
local overlapping=clone(approved);overlapping.recordID='overlap'
researchTokens={approved,unchecked,overlapping}
assert(originalLoadfile('tools/compile_itemdb.lua'))()
compiled={};assert(originalLoadfile(outdir..'/TokenFixture.lua'))('LootLiquidator',compiled)
assert(#compiled.ItemDB.tokenRewards==1 and compiled.ItemDB.tokenRewards[1].recordID=='synthetic-only','only the checked record ships')
local skipped=compiled.ItemDB.buildReport.tokenRewardsSkipped
assert(#skipped==2 and skipped[1].recordID=='unchecked' and skipped[1].reason:find('Token catalog requires',1,true)
    and skipped[2].recordID=='overlap' and skipped[2].reason:find('Overlapping',1,true),'skipped records carry their reason')
-- C4b3: token lists from the research v3 notes compile into the same ItemDB, after the
-- reviewed export: a reviewed record for the same token wins (the v3 one is skipped as
-- overlapping); a new token ships unreviewed with its confidence.
researchTokens={approved}
arg={outdir..'/TokenFixture.lua','database/evidence-baselines.lua','tests/fixtures/research-v3-tokens.lua'}
assert(originalLoadfile('tools/compile_itemdb.lua'))()
compiled={};assert(originalLoadfile(outdir..'/TokenFixture.lua'))('LootLiquidator',compiled)
local byID={} for _,r in ipairs(compiled.ItemDB.tokenRewards) do byID[r.tokenID]=r end
assert(#compiled.ItemDB.tokenRewards==2 and byID[900001].recordID=='synthetic-only','reviewed record wins')
assert(byID[900007].independentReview=='NOT_REVIEWED' and byID[900007].confidence0to100==40,'v3 list ships unreviewed')
assert(compiled.ItemDB.buildReport.tokenRewardsFromResearchV3==1)
assert(compiled.ItemDB.buildReport.tokenRewardsSkipped[1].recordID=='v3token:900001')
arg={outdir..'/TokenFixture.lua','database/evidence-baselines.lua','tests/fixtures/research-v3-empty.lua'}
-- Tokens in database/records.lua (hand approval on this branch) fail the build.
researchTokens,recordsTokens={approved},{approved}
local ok,message=pcall(assert(originalLoadfile('tools/compile_itemdb.lua')))
assert(not ok and tostring(message):find('belong in the research export',1,true),'records.lua must not carry token lists')
loadfile,arg=originalLoadfile,originalArg
-- Quest-class equipment tokens must reach the main recommendation/tooltip
-- consumer, while unrelated quest items remain excluded. Tokens never run the
-- crafting conversion evaluator on their own input item.
SlashCmdList={};max,min=math.max,math.min
assert(loadfile('LootLiquidator/Core.lua'))('LootLiquidator',LL)
LL.db.enabled=true
LL.ItemDB.tokenRewards[1].inputClassID=12
assert(LL:InitializeItemDB())
local questToken={id=900001,classID=12,equipLoc='',link='item:900001',bindType=4,
    context={isQuest=true},count=1,vendor=0,quality=4,expansionID=11}
LL.GetItemFacts=function()return questToken end
LL.BestConversion=function()error('equipment token must not run a crafting conversion')end
local decision=LL:Evaluate('item:900001',{})
assert(decision and decision.tokenInfo and decision.tokenInfo.standalone and not decision.questItem)
questToken.id=999999
decision=LL:Evaluate('item:999999',{})
assert(decision.questItem and not decision.tokenInfo)
-- C6: old ATT switches are dropped from saved data; old ATT caches are kept.
local saved={enableATTIntegration=true,showATTTooltipDetails=true,showATTTokenDEQuotes=false,
    attRewardCache={['1']={}},attResearchScans={},attItemResearch={}}
LL:RemoveRetiredSettings(saved)
assert(saved.enableATTIntegration==nil and saved.showATTTooltipDetails==nil and saved.showATTTokenDEQuotes==nil)
assert(saved.attRewardCache and saved.attResearchScans and saved.attItemResearch,'old ATT caches kept')
AllTheThings=nil
print('PASS: token catalog compiler/runtime route, installed ATT never read, evidence/scope rejection')
