-- Collection changes must refresh recommendations without throwing away
-- unchanged profession calculations. Other invalidations keep their scope.
local checks=0
local function check(value,why) checks=checks+1;assert(value,why) end
local frames={}
CreateFrame=function()
    local frame={events={}}
    function frame:RegisterEvent(event) self.events[event]=true end
    function frame:SetScript(name,fn) self[name]=fn end
    frames[#frames+1]=frame;return frame
end
SlashCmdList={};GetTime=function()return 100 end
wipe=function(t)for k in pairs(t)do t[k]=nil end end
local LL={db={enabled=true,showSoulboundVendorBadge=true},ItemDB={}}
assert(loadfile('LootLiquidator/Core.lua'))('LootLiquidator',LL)
assert(loadfile('LootLiquidator/Tokens.lua'))('LootLiquidator',LL)
local collectionFrame
for _,frame in ipairs(frames)do
    if frame.events.TRANSMOG_COLLECTION_UPDATED then collectionFrame=frame end
end
check(collectionFrame~=nil,'real token collection event frame is registered')
local refreshes,clears,blizzard,guild,tokens=0,0,0,0,0
LL.RequestBadgeRefresh=function()refreshes=refreshes+1 end
LL.ClearBadgeDecisionCache=function()clears=clears+1 end
LL.QueueBlizzardBagRefresh=function()blizzard=blizzard+1 end
LL.QueueGuildRefresh=function()guild=guild+1 end
local invalidateTokens=LL.InvalidateTokenCache
LL.InvalidateTokenCache=function(self)tokens=tokens+1;invalidateTokens(self)end
local collected=false
LL.AppearanceCollectionState=function()return collected end
LL.DirectTransmogRecipient=function()return {name='Player',current=true}end
LL.TokenInfo=function()end
LL.GetItemFacts=function(_,link,ctx)
    return {id=1,link=link,tsmString='i:1',name='Fixture armor',classID=4,
        quality=4,expansionID=9,itemLevel=441,count=1,vendor=50,context=ctx or {}}
end
LL.DisenchantEligibility=function()return true end
LL.EligibleDisenchant=function()return true end
LL.AuctionEligible=function()return false end
LL.IsNonAuctionableByBinding=function()return true end
LL.Price=function()end;LL.ReportMissing=function()end
LL.AHFeeRate=function()return 0 end
local builds=0
LL.BestConversion=function(_,f)
    builds=builds+1
    local option={name='Disenchant',available=true,value=25,letter='D',
        yieldModel={inputCount=1,materials={{id=100,expectedQuantity=1,chance=1,minQuantity=1,maxQuantity=1}}}}
    f.conversionOptions={option};return option
end
local old=LL:Evaluate('item:1',{})
check(old.action=='T','missing usable appearance takes collection priority')
check(LL:Evaluate('item:1',{})==old and builds==1,'unchanged decision is cached')
local numericalFields={'_processingModelCache','_categorySourceProjectionCache',
    '_processingContextCache','_professionOperationCache'}
local function prime()
    local saved={}
    for _,field in ipairs(numericalFields)do LL[field]={sentinel=field};saved[field]=LL[field]end
    LL._tooltipProjectionCache={priced=true};LL._deRestrictionCache={};LL._enchantCache={}
    return saved
end
for _,event in ipairs({'TRANSMOG_COLLECTION_UPDATED','TRANSMOG_COLLECTION_SOURCE_ADDED',
    'TRANSMOG_COLLECTION_SOURCE_REMOVED','TRANSMOG_COLLECTION_ITEM_UPDATE'})do
    local saved=prime();local before=refreshes
    collectionFrame.OnEvent(collectionFrame,event,123)
    for _,field in ipairs(numericalFields)do check(LL[field]==saved[field],event..' preserves '..field)end
    check(LL._tooltipProjectionCache==nil,'priced tooltip projections are always refreshed')
    check(LL._deRestrictionCache==nil and LL._enchantCache==nil,'restriction/access snapshots still refresh')
    check(refreshes==before+1 and clears==refreshes and tokens==refreshes
        and blizzard==refreshes and guild==refreshes,'every collection event refreshes all badge hosts and token decisions')
end
collected=true
local fresh=LL:Evaluate('item:1',{})
check(fresh~=old and builds==2 and fresh.action~='T','learning the appearance produces a fresh liquidation decision')
check(fresh.converted==old.converted and fresh.vendor==old.vendor,'collection refresh preserves gold calculations')
check(fresh.conversionOptions[1].yieldModel.materials[1].expectedQuantity==1,
    'collection changes leave the material quantities intact')
local saved=prime()
LL:Invalidate('evidence')
check(LL._processingModelCache==nil and LL._categorySourceProjectionCache==nil,
    'new evidence still discards numerical models')
check(LL._processingContextCache==saved._processingContextCache
    and LL._professionOperationCache==saved._professionOperationCache,'existing evidence context behavior remains intact')
for _,reason in ipairs({'full','profession','includeVerifiedAlts'})do
    prime();LL:Invalidate(reason=='full' and nil or reason)
    for _,field in ipairs(numericalFields)do check(LL[field]==nil,reason..' still clears '..field)end
end
prime();collectionFrame.OnEvent(collectionFrame,'COVENANT_CHOSEN')
for _,field in ipairs(numericalFields)do check(LL[field]==nil,'covenant choice retains broad invalidation')end
print('PASS: '..checks..' appearance invalidation checks')
