local root=arg[1] or 'LootLiquidator/'
local onEvent,tooltipCallback
CreateFrame=function()
    return {RegisterEvent=function()end,SetScript=function(_,event,callback)
        if event=='OnEvent' then onEvent=callback end
    end}
end
Enum={TooltipDataType={Item=1}}
TooltipDataProcessor={AddTooltipPostCall=function(kind,callback)
    assert(kind==Enum.TooltipDataType.Item);tooltipCallback=callback
end}
local LL={db={showTooltips=true}}
assert(loadfile(root..'Badges.lua'))('LootLiquidator',LL)
onEvent(nil,'PLAYER_LOGIN')
assert(tooltipCallback)
local evaluated,appended
LL.Evaluate=function(_,link) evaluated=link;return {link=link} end
LL.AppendRecommendationTooltip=function(_,tooltip,decision) appended=decision.link end
local sentinel={}
_G._=sentinel
local lookupCalls=0
local tooltip={GetItem=function()return 'Bag item','item:10' end}
C_Item={GetItemInfo=function()lookupCalls=lookupCalls+1;return 'Cached item','item:20' end}
tooltipCallback(tooltip,{id=20})
assert(evaluated=='item:10' and appended=='item:10' and lookupCalls==0)
assert(_G._==sentinel,'tooltip:GetItem must not overwrite global _')
tooltip.GetItem=function()return nil,nil end
tooltipCallback(tooltip,{id=20})
assert(evaluated=='item:20' and appended=='item:20' and lookupCalls==1)
assert(_G._==sentinel,'GetItemInfo fallback must not overwrite global _')
TooltipUtil={GetDisplayedItem=function()return 'Displayed item','item:30' end}
tooltip.GetItem=function()error('displayed item must take precedence')end
tooltipCallback(tooltip,{id=20})
assert(evaluated=='item:30' and appended=='item:30' and lookupCalls==1)
print('PASS: tooltip fallback order and global discard isolation')

assert(loadfile(root..'ATTIntegration.lua'))('LootLiquidator',LL)
LL.ItemPermitsClass=function()return true end
C_Item.GetItemInfo=function()
    lookupCalls=lookupCalls+1
    return 'Reward','item:40',4,100,1,'Armor','Plate',1,'INVTYPE_HEAD',123,500,nil,4
end
for _,token in ipairs({{rewards={}},{rewards={40,41}}}) do
    assert(LL:TokenDEQuotes({id=1},token,{class='WARRIOR'})==nil)
end
assert(LL:TokenDEQuotes(nil,nil,nil)==nil)
print('PASS: retired token quote hook never supplies aggregate Destroy valuation')
