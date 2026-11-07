-- A collected visual must not become T because this exact source is unknown.
local checks=0
local function check(value,message) assert(value,message);checks=checks+1 end
local function eq(actual,expected,message)
    check(actual==expected,(message or '')..': '..tostring(actual)..' ~= '..tostring(expected))
end
GetTime=function() return 100 end
time=function() return 1000 end
wipe=function(t) for k in pairs(t) do t[k]=nil end return t end
SlashCmdList={}
local frames={}
CreateFrame=function()
    local f={events={},scripts={}}
    function f:RegisterEvent(event) self.events[event]=true end
    function f:SetScript(event,callback) self.scripts[event]=callback end
    frames[#frames+1]=f;return f
end
UnitClass=function() return 'Mage','MAGE' end
local LL={db={enabled=true,includeVerifiedAlts=true,characters={
    ['Main - Realm']={class='MAGE'},['Plate - Realm']={class='PALADIN'}}}}
for _,file in ipairs({'Core.lua','Professions.lua','Tokens.lua'}) do
    assert(loadfile('LootLiquidator/'..file))('LootLiquidator',LL)
end
LL.CharacterKey=function() return 'Main - Realm' end
local facts={id=24995,name='Warmaul Legplates',link='item:24995',tsmString='i:24995',
    classID=4,subClassID=4,equipLoc='INVTYPE_LEGS',quality=2,expansionID=1,
    vendor=1567,count=1,context={verifiedUnbound=true}}
LL.GetItemFacts=function() return facts end
LL.BestConversion=function() end
LL.AuctionEligible=function() return true end
LL.IsNonAuctionableByBinding=function() return false end
LL.DisenchantEligibility=function() return false end
LL.EligibleDisenchant=function() return false end
LL.ChosenTSMAuctionOperation=nil
LL.ReportMissing=function() end
LL.Price=function() end
LL.AHFeeRate=function() return .05 end
local owned,legacyOwned=false,false
local sourceRows,allSources,filteredSources={},{101,202},nil
local calls={}
C_TransmogCollection={
    GetItemInfo=function(link) calls.link=link;return 700,101 end,
    GetAppearanceSourceInfo=function(id)
        if id==101 then return {itemAppearanceID=700,isCollected=owned} end
        return sourceRows[id]
    end,
    GetAppearanceInfoBySource=function(id)
        if id==101 then return {appearanceID=700,appearanceIsCollected=legacyOwned,sourceIsCollected=false} end
    end,
    GetAppearanceSources=function(id) calls.filtered=id;return filteredSources end,
    GetAllAppearanceSources=function(id) calls.all=id;return allSources end,
    GetSourceInfo=function() end,
    SetCollectedShown=function() error('Never change collection filters') end,
    SetSourceTypeFilter=function() error('Never change collection filters') end,
}
eq(LL:AppearanceCollectionState(facts.link),false,'uncollected visual remains missing')
local missing=LL:Evaluate(facts.link,facts.context)
eq(missing.action,'T','a genuinely missing transferable plate look can go to a plate alt')
eq(missing.transmogRecipient.name,'Plate - Realm','existing recipient rules stay intact')
-- The hovered source remains uncollected; another source of exactly the same
-- visual is owned. No cache invalidation or advancing the clock is necessary.
sourceRows[202]={itemAppearanceID=700,isCollected=true}
local collected,source,appearance=LL:AppearanceCollectionState(facts.link)
eq(collected,true,'an appearance learned from another item is collected')
eq(source,101,'the hovered exact source identity stays intact')
eq(appearance,700,'the shared visual identity stays intact')
eq(calls.all,700,'all sources are looked up by appearance, never item ID')
local known=LL:Evaluate(facts.link,facts.context)
eq(known.action,'V','known appearance restores economic recommendation instead of T')
eq(known.transmogRecipient,nil,'known appearance does not advertise sending an alt for transmog')
eq(LL:UncollectedAppearance(facts),false,'direct equipment helper uses the same visual state')
-- A class-filtered list cannot hide a collected source on another class.
filteredSources=nil
eq(LL:AppearanceCollectionState(facts.link),true,'unfiltered source enumeration works across current-class limitations')
sourceRows[202]=nil
filteredSources={{visualID=700,sourceID=303,isCollected=true}}
eq(LL:AppearanceCollectionState(facts.link),true,'a known matching visual in the available source list is sufficient')
-- Never borrow collection from a different appearance or difficulty variant.
filteredSources={{visualID=701,sourceID=303,isCollected=true}}
sourceRows[202]={itemAppearanceID=701,isCollected=true}
eq(LL:AppearanceCollectionState(facts.link),false,'a different visual cannot satisfy this appearance')
filteredSources={}
sourceRows[202]={itemAppearanceID=700,isCollected=false}
C_TransmogCollection.GetSourceInfo=function(id)
    if id==202 then return {visualID=700,isCollected=true} end
end
eq(LL:AppearanceCollectionState(facts.link),true,'affirmative alternate source metadata is a valid ownership fallback')
C_TransmogCollection.GetSourceInfo=function() error('Data not ready') end
C_TransmogCollection.GetAllAppearanceSources=function() error('Data not ready') end
eq(LL:AppearanceCollectionState(facts.link),false,'failing alternate queries do not crash or replace explicit collection state')
owned=true
eq(LL:AppearanceCollectionState(facts.link),true,'affirmative current API wins a temporarily negative legacy state')
owned=false;legacyOwned=true
eq(LL:AppearanceCollectionState(facts.link),true,'affirmative appearance-wide legacy state wins a negative source')
-- A false exact-source bit by itself never proves the visual missing.
C_TransmogCollection.GetAppearanceSourceInfo=function() end
C_TransmogCollection.GetAppearanceInfoBySource=function() return {sourceIsCollected=false} end
C_TransmogCollection.GetAppearanceSources=function() end
C_TransmogCollection.GetAllAppearanceSources=function() return {} end
eq(LL:AppearanceCollectionState(facts.link),nil,'an uncollected source alone leaves appearance ownership unknown')
eq(LL:Evaluate(facts.link,facts.context).action,'V','unknown ownership cannot force a T recommendation')
C_TransmogCollection.GetItemInfo=function() error('Item loading') end
eq(LL:AppearanceCollectionState(facts.link),nil,'loading item metadata remains unknown')
C_TransmogCollection.GetItemInfo=function() return nil,nil end
eq(LL:AppearanceCollectionState(facts.link),nil,'nonappearance items remain unknown')
-- Learning or removing a source refreshes bag decisions and token snapshots.
local eventFrame
for _,frame in ipairs(frames) do if frame.events.TRANSMOG_COLLECTION_UPDATED then eventFrame=frame end end
check(eventFrame,'collection event frame exists')
local refreshed=0
LL.RequestBadgeRefresh=function() refreshed=refreshed+1 end
for _,event in ipairs({'TRANSMOG_COLLECTION_UPDATED','TRANSMOG_COLLECTION_SOURCE_ADDED',
    'TRANSMOG_COLLECTION_SOURCE_REMOVED','TRANSMOG_COLLECTION_ITEM_UPDATE'}) do
    check(eventFrame.events[event],'collection change event is registered: '..event)
    eventFrame.scripts.OnEvent(eventFrame,event)
end
eq(refreshed,4,'collection changes refresh visible badge decisions')
print('PASS: '..checks..' appearance-wide ownership, alternate sources, recommendation caching and collection refresh assertions')
