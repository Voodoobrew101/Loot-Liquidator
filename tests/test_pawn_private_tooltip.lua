-- Exercise the registered item-tooltip callback, including the real shared
-- renderer and selected-profile display projection. Figures are fixtures.
local checks=0
local function check(v,why)assert(v,why);checks=checks+1 end
local frames,callback={},nil
CreateFrame=function()
    local frame={events={}}
    function frame:RegisterEvent(event)self.events[event]=true end
    function frame:SetScript(_,fn)self.event=fn end
    frames[#frames+1]=frame;return frame
end
Enum={TooltipDataType={Item=0}}
TooltipDataProcessor={AddTooltipPostCall=function(kind,fn)
    check(kind==Enum.TooltipDataType.Item,'normal item post-call registered');callback=fn
end}
GetTime=function()return 100 end
local reads,evaluations,observations,appends,projections=0,0,0,0,0
TooltipUtil={GetDisplayedItem=function(tip)reads=reads+1;return'Input',tip.link end}
C_Item={GetItemInfo=function(id)return'Output '..id,nil,2 end,GetItemIconByID=function(id)return 100+id end}
local LL={db={showBetterBags=false,tooltipDetail=3,tooltipOutputSort='database',characters={Player={}},
    professionTooltipProfiles={}},ItemDB={version='pawn-scanner-fixture'}}
assert(loadfile('LootLiquidator/ConversionEngine.lua'))('LootLiquidator',LL)
assert(loadfile(BADGES_UNDER_TEST or 'LootLiquidator/Badges.lua'))('LootLiquidator',LL)
LL.MarkupColor=function()return''end
LL.Money=function(_,value)return tostring(value)..' copper'end
LL.CharacterKey=function()return'Player'end
local material={id=101,chance=.5,expectedQuantity=.75,minQuantity=1,maxQuantity=2,netExpectedValue=75}
local model={inputCount=1,confidence=80,materials={material},context={character='Player'}}
local option={name='Disenchant',profession='Enchanting',letter='D',available=true,value=75,yieldModel=model}
local facts={id=100,classID=4,quality=2,expansionID=9,count=1,link='item:100',context={}}
local decision={action='D',facts=facts,conversionOptions={option}}
LL.ConversionOptions=function(self,f)
    projections=projections+1;check(f.id==100,'selected display profile gets original input identity')
    return{option}
end
LL.Evaluate=function(_,link,context)
    evaluations=evaluations+1;check(link=='item:100','input hyperlink preserved');return decision
end
LL.ObserveVisibleDisenchantRestriction=function(_,link)
    observations=observations+1;check(link=='item:100','normal visible restriction observation preserved');return false
end
local append=LL.AppendRecommendationTooltip
LL.AppendRecommendationTooltip=function(self,tip,result)
    appends=appends+1;check(result==decision,'same decision reaches shared renderer');return append(self,tip,result)
end
for _,frame in ipairs(frames)do if frame.events.PLAYER_LOGIN then frame.event(frame,'PLAYER_LOGIN')end end
check(type(callback)=='function','public TooltipDataProcessor hook installed')
local function tip(anchor,name)
    return{link='item:100',anchor=anchor,lines={},
        GetAnchorType=function(self)return self.anchor end,
        GetName=function()return name or'GameTooltip'end,
        GetOwner=function(self)return self.owner end,
        IsShown=function()return false end, -- public tooltips can be processed before Show()
        AddLine=function(self,text)self.lines[#self.lines+1]=text end,
        AddDoubleLine=function(self,left,right)self.lines[#self.lines+1]=left..' | '..right end}
end
local function expected(t)
    local expectedTip=tip(t.anchor)
    append(LL,expectedTip,decision)
    return table.concat(expectedTip.lines,'\n')
end
PawnPrivateTooltipName='PawnPrivateTooltip1'
local private=tip('ANCHOR_NONE','PawnPrivateTooltip1')
_G.PawnPrivateTooltip1=private
local function public(t,why)
    local text=expected(t)
    local ev,ob,ap,read=evaluations,observations,appends,reads
    callback(t,{id=100})
    if LL.db.tooltipDetail==0 then
        check(evaluations==ev and observations==ob and appends==ap and reads==read,why..': detail-off unchanged')
    else
        check(evaluations==ev+1 and observations==ob+1 and appends==ap+1 and reads==read+1,
            why..': existing link, observation, evaluation and append path preserved')
    end
    check(table.concat(t.lines,'\n')==text,why..': full public tooltip rows unchanged')
end
for detail=0,3 do
    LL.db.tooltipDetail=detail
    for _,selection in ipairs({'@auto','@hide','Player','@hypothetical'})do
        LL.db.professionTooltipProfiles.Enchanting=selection
        local ev,ob,ap,read,proj=evaluations,observations,appends,reads,projections
        private.lines={'Native scanner stat line'}
        callback(private,{id=100,lines={{leftText='Cannot be disenchanted'}}})
        check(evaluations==ev and observations==ob and appends==ap and reads==read and projections==proj,
            'Pawn scanner never reads/evaluates/observes/appends/projects at detail '..detail..' profile '..selection)
        check(#private.lines==1 and private.lines[1]=='Native scanner stat line','Pawn native scanner lines remain pristine')
        public(tip('ANCHOR_NONE'), 'ordinary hidden/pre-show tooltip detail '..detail..' profile '..selection)
        local debug=tip('ANCHOR_TOPRIGHT','PawnPrivateTooltip1');_G.PawnPrivateTooltip1=debug
        public(debug,'explicitly anchored Pawn debug tooltip')
        _G.PawnPrivateTooltip1=private
    end
end
LL.db.tooltipDetail=3;LL.db.professionTooltipProfiles.Enchanting='Player'
check(projections>0,'named and hypothetical profile rendering exercised actual display projection helper')
public(tip('ANCHOR_NONE','PawnPrivateTooltip1'),'same name without designated global identity')
local unconfirmed=tip('ANCHOR_NONE','PawnPrivateTooltip1');unconfirmed.GetAnchorType=nil
_G.PawnPrivateTooltip1=unconfirmed
public(unconfirmed,'missing anchor API cannot positively identify the private scan')
_G.PawnPrivateTooltip1=private;PawnPrivateTooltipName=nil
public(tip('ANCHOR_NONE','PawnPrivateTooltip1'),'no designated Pawn name does not exclude a tooltip')
PawnPrivateTooltipName=17
public(tip('ANCHOR_NONE'),'non-string Pawn name cannot exclude or crash normal tooltip')
PawnPrivateTooltipName='PawnPrivateTooltip1'
local cached=tip('ANCHOR_RIGHT');cached.owner={laLink='item:100',laDecision=decision}
local ev,ob,ap=evaluations,observations,appends
callback(cached,{id=100})
check(evaluations==ev and observations==ob+1 and appends==ap+1,'normal bag-owner decision reuse preserved')
check(material.chance==.5 and material.expectedQuantity==.75 and material.netExpectedValue==75
    and option.value==75 and decision.facts==facts,'source, gold values and input identity untouched')
print('PASS: '..checks..' precise Pawn private-scanner, public/profile/detail rows and unchanged valuation checks')
