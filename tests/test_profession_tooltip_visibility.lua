-- Tooltip visibility follows real eligibility; hypothetical profiles grant no access.
CreateFrame=function()return {RegisterEvent=function()end,SetScript=function()end}end
local LL={db={}}
assert(loadfile('LootLiquidator/Professions.lua'))('LL',LL)
assert(loadfile('LootLiquidator/Badges.lua'))('LL',LL)
LL.CharacterKey=function()return 'Player'end
LL.MarkupColor=function()return ''end
LL.Money=function(_,v)return tostring(v)..' copper'end
LL.ProfessionProgression=function()return {}end
local function render(option,level,show)
    LL.db.tooltipDetail=level;LL.db.professionTooltipProfiles=show and {Inscription="@hypothetical",Jewelcrafting="@hypothetical"} or nil
    local tip={lines={}}
    function tip:AddLine(s)self.lines[#self.lines+1]=s end
    function tip:AddDoubleLine(l,r)self.lines[#self.lines+1]=l..' | '..r end
    LL:AppendRecommendationTooltip(tip,{action='A',rawAuction=20,netAuction=19,vendor=5,
        facts={id=1,classID=7},conversionOptions={option}})
    return table.concat(tip.lines,'\n')
end
local n=0
for _,method in ipairs({{'Mill','Inscription','M','Milling'},{'Prospect','Jewelcrafting','P','Prospecting'}}) do
    for _,scenario in ipairs({'none','current','alt','alt-off','alt-excluded','missing-recipe','bound','hypothetical'}) do
        local player={professions={},recipes={}}
        local alt={professions={[method[2]]=true},recipes={[700001]={learned=true}}}
        LL.db={characters={Player=player},includeVerifiedAlts=true}
        local f={id=1,classID=7,context={}}
        if scenario=='current' then player.professions[method[2]]=true;player.recipes[700001]={learned=true}
        elseif scenario=='missing-recipe' then player.professions[method[2]]=true
        elseif scenario=='hypothetical' then
            LL.db.rateProfile=3
            assert(LL:SetManualProfessionProfile('Player',method[2],9,{enabled=true,skill=100}))
        elseif scenario~='none' then
            LL.db.characters.Alt=alt
            if scenario=='alt-off' then LL.db.includeVerifiedAlts=false end
            if scenario=='alt-excluded' then alt.altMethods={[method[3]]=false} end
            if scenario=='bound' then f.context.isSoulbound=true end
        end
        local available=LL:CanUseConversion(f,{method=method[1],profession=method[2],recipeID=700001})
        assert(available==(scenario=='current' or scenario=='alt'),scenario..' eligibility')
        local option={name=method[1],letter=method[3],available=available,value=50,
            yieldModel={inputCount=5,materials={{id=10,chance=.2,minQuantity=1,maxQuantity=2,netExpectedValue=250}}}}
        for level=0,3 do
            for _,show in ipairs({false,true}) do
                local text=render(option,level,show)
                local visible=level>=2 and (available or show)
                assert((text:find(method[4],1,true)~=nil)==visible,scenario..' visibility')
                assert((text:find('20% Material 10 [1-2]',1,true)~=nil)==(visible and level==3))
                if level==0 then assert(text=='') else assert(text:find('Auction',1,true)) end
                assert(option.available==available and option.value==50,'display never changes eligibility or prices')
                n=n+1
            end
        end
        LL.db.professionTooltipProfiles=nil
        assert((render(option,3,nil):find(method[4],1,true)~=nil)==available,'unset defaults off')
    end
end
print('PASS: '..n..' profession tooltip cases: current, verified/enabled alts, recipe/binding exclusions, hypothetical profiles and all levels')
-- Filtering precedes method deduplication, retaining an eligible lower-priced recipe.
LL.db={tooltipDetail=3}
local tip={lines={}}
function tip:AddLine(s)self.lines[#self.lines+1]=s end
function tip:AddDoubleLine(l,r)self.lines[#self.lines+1]=l..' | '..r end
LL:AppendRecommendationTooltip(tip,{action='A',facts={id=1,classID=7},conversionOptions={
    {name='Craft',letter='C',available=false,value=500},
    {name='Craft',letter='C',available=true,value=50}}})
local text=table.concat(tip.lines,'\n')
assert(text:find('50 copper',1,true) and not text:find('500 copper',1,true),'available recipe stays visible')
print('PASS: unavailable recipe filtering preserves the usable alternative')
