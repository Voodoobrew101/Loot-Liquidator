-- Native Loot/Use scopes are separate, non-actionable settings previews.
-- This exercises the actual target/context/model API through slider callbacks.
local checks=0
local function check(value,label) assert(value,label);checks=checks+1 end
local widgets={}
local function widget(kind,parent)
    local w={kind=kind,parent=parent,scripts={},shown=true}
    function w:SetScript(key,value) self.scripts[key]=value end
    function w:SetText(value) self.text=value end
    function w:SetChecked(value) self.checked=value end
    function w:GetChecked() return self.checked end
    function w:Show() self.shown=true end
    function w:Hide() self.shown=false end
    function w:CreateFontString() return widget('FontString',self) end
    setmetatable(w,{__index=function() return function() end end})
    widgets[#widgets+1]=w;return w
end
CreateFrame=function(kind,_,parent) return widget(kind,parent) end
Settings={CreateControlTextContainer=function()
    local rows={}
    return {Add=function(_,id,label,tooltip) rows[#rows+1]={id=id,label=label,tooltip=tooltip} end,
        GetData=function() return rows end}
end}
GetBuildInfo=function() return '12.1.5','70961' end
GetTime=function() return 100 end
time=function() return 100 end
local era=10
GetExpansionLevel=function() return era end
local LL={db={characters={Player={professions={},recipes={},researchProfiles={}}},rateProfile=1}}
LL.UpdateAllAppearance=function() end
for _,file in ipairs({'Professions.lua','ConversionEngine.lua','ProfessionModels.lua','ProfessionCalculations.lua','Settings.lua'}) do
    assert(loadfile('LootLiquidator/'..file))('LL',LL)
end
LL.CharacterKey=function() return 'Player' end
LL.ItemDB={professionProfiles=assert(loadfile('database/profession-profile-rules.lua'))()}
LL.CreateSettingsButton=function(_,parent) return widget('Button',parent) end
LL.CreateSettingsCheckbox=function(_,parent) return widget('CheckButton',parent) end
LL.CreateSettingsCanvasSlider=function(_,parent,minimum,maximum,_,_,changed)
    local w=widget('SliderControl',parent)
    w.slider=widget('Slider',w);w.minimum=minimum;w.maximum=maximum;w.changed=changed
    function w:SetPreferenceValue(value) self.value=value end
    return w
end
LL.CreateSettingsDropdown=function(_,parent,data,get,set)
    local w=widget('Dropdown',parent);w.select=set
    function w:Refresh() self.rows=data();self.value=get() end
    return w
end
-- Limit each editor fixture to the selected real native path. All rules and
-- calculations still come from the complete compiled native metadata.
local chosenNode
LL.GetProfessionUIOptions=function(_,_,profession,expansion)
    local profile=LL.ItemDB.professionProfiles.profiles[profession..':'..expansion]
    local node=profile and profile.nodes[chosenNode]
    if not node then return {nodes={},buffs={}} end
    return {nodes={{id=chosenNode,name=node.name,maxRank=node.maxRank,tab=profession}},buffs={}}
end
local function visibleText(first)
    local lines={}
    for index=first,#widgets do
        local w=widgets[index]
        if w.shown and type(w.text)=='string' and (not w.parent or w.parent.shown) then lines[#lines+1]=w.text end
    end
    return table.concat(lines,'\n')
end
local function button(first,text)
    for index=first,#widgets do
        local w=widgets[index]
        if w.text==text and w.scripts.OnClick then return w end
    end
    error('Missing button '..text)
end
local function nodeSlider(first,maximum)
    for index=first,#widgets do
        local w=widgets[index]
        if w.kind=='SliderControl' and w.maximum==maximum then return w end
    end
    error('Missing native path slider')
end
local function selectNodeTarget(panel,first,nodeID,method)
    local selected
    for index=first,#widgets do
        local w=widgets[index]
        if w.kind=='Dropdown' and w.rows then
            for _,row in ipairs(w.rows) do
                if type(row.tooltip)=='string' and row.tooltip:find('Normalized',1,true) then selected=w;break end
            end
        end
    end
    check(selected,'native opportunity context selector is visible')
    local targets=LL:GetProfessionOpportunityTargets(panel.profession,era)
    for index,target in ipairs(targets) do
        if target.nodeID==nodeID and target.method==method then selected.select(index);return target,selected end
    end
    error('Missing native node context '..nodeID)
end

chosenNode=100939 -- TWW Textile Treasures: relative cloth-discovery milestones.
check(LL:SetManualProfessionProfile('Player','Tailoring',10,{enabled=true,skill=100,specialization='none'}),'minimum profile saves')
LL.db.professionTooltipProfiles={Tailoring='@hypothetical'}
local first=#widgets+1
local panel=LL:CreateProfessionProfilePanel('Tailoring');panel.profession='Tailoring';panel.scripts.OnShow()
local target,selector=selectNodeTarget(panel,first,chosenNode,'Loot')
check(panel.opportunityPreview and panel.opportunityPreview.actionable==false,'Loot preview never becomes a sale or conversion')
check(visibleText(first):find('Loot and item-use preview',1,true),'native opportunity result card is displayed')
check(visibleText(first):find(target.quantityBasis,1,true),'normalized denominator is visible')
local advanced=button(first,'Advanced');advanced.scripts.OnClick(advanced)
local before=visibleText(first)
nodeSlider(first,30).changed(10)
local after=visibleText(first)
check(before~=after and after:find('discovery:',1,true),'actual path slider changes displayed discovery output')
check(after:find('x baseline',1,true) and not after:find('per kill',1,true),'relative discovery remains a normalized factor')
check(LL.db.professionOpportunitySelections['Tailoring:10']==target.targetID,'selected native context is stored per profession and era')
check(LL.db.rateProfile==1,'preview leaves recommendation profile selection untouched')

local hover
for index=first,#widgets do
    local w=widgets[index]
    if w.kind=='Frame' and w.shown and w.scripts.OnEnter then hover=w;break end
end
check(hover,'displayed result has a native hover target')
local tooltipLines,tooltipShown={},false
GameTooltip={SetOwner=function()end,ClearLines=function()tooltipLines={}end,
    AddLine=function(_,line)tooltipLines[#tooltipLines+1]=line end,Show=function()tooltipShown=true end,Hide=function()tooltipShown=false end}
hover.scripts.OnEnter(hover)
check(table.concat(tooltipLines,'\n'):find('discovery:',1,true),'native hover tooltip uses the current calculated result')
nodeSlider(first,30).changed(20)
hover.scripts.OnEnter(hover)
check(table.concat(tooltipLines,'\n')~=before,'hover result refreshes after another slider milestone')
local reset=button(first,'Reset to minimum');reset.scripts.OnClick(reset)
check(not table.concat(tooltipLines,'\n'):find('discovery:',1,true),'reset immediately clears the previous output bonus from the open tooltip')
local dropdowns={}
for index=first,#widgets do if widgets[index].kind=='Dropdown' then dropdowns[#dropdowns+1]=widgets[index] end end
dropdowns[2].select(0)
check(rawget(panel,'opportunityPreview')==nil and not tooltipShown,'an era without native opportunities clears the old preview and tooltip')
dropdowns[2].select(10)
check(panel.opportunityPreview~=nil,'returning to the native era restores its current context')
hover.scripts.OnEnter(hover)
dropdowns[1].select(0)
check(rawget(panel,'opportunityPreview')==nil and not tooltipShown,'hidden profession clears its open tooltip')
hover.scripts.OnEnter(hover)
check(not tooltipShown,'hidden preview cannot expose stale hover lines')
dropdowns[1].select(-1)

-- A Use event must be explicitly selected by the existing condition control.
chosenNode=98953 -- TWW Fantastic Flasks: recover a vial after consuming a flask.
check(LL:SetManualProfessionProfile('Player','Alchemy',10,{enabled=true,skill=100,specialization='98953=1',
    effectStates={['122300']={active=false,stacks=1}}}),'item-use profile preserves inactive event')
LL.db.professionTooltipProfiles.Alchemy='@hypothetical'
first=#widgets+1
local usePanel=LL:CreateProfessionProfilePanel('Alchemy');usePanel.profession='Alchemy';usePanel.scripts.OnShow()
selectNodeTarget(usePanel,first,chosenNode,'Use')
before=visibleText(first)
advanced=button(first,'Advanced');advanced.scripts.OnClick(advanced)
local active
for index=first,#widgets do
    local w=widgets[index]
    if w.kind=='CheckButton' and w.shown then active=w end
end
check(active,'Use event has an explicit activation control')
active:SetChecked(true);active.scripts.OnClick(active)
after=visibleText(first)
check(after~=before and after:find('normalized units',1,true),'Use condition changes the displayed normalized output')
check(usePanel.opportunityPreview.actionable==false,'item-use output stays outside actionable liquidation')
local saved=LL.db.professionOpportunitySelections['Alchemy:10']
usePanel.scripts.OnShow()
check(LL.db.professionOpportunitySelections['Alchemy:10']==saved,'context selection survives refresh')
check(LL.db.professionOpportunitySelections['Tailoring:10']==target.targetID,'other profession context remains isolated')
check(not LL.db.recipeCandidates or next(LL.db.recipeCandidates)==nil,'preview creates no recipe access or bag-item self-loop')
chosenNode=100790 -- Explosives15 modifies reagent saving on item use.
check(LL:SetManualProfessionProfile('Player','Engineering',10,{enabled=true,skill=100,specialization='none'}),'item-use saving profile starts at minimum')
LL.db.professionTooltipProfiles.Engineering='@hypothetical'
first=#widgets+1
local savingPanel=LL:CreateProfessionProfilePanel('Engineering');savingPanel.profession='Engineering';savingPanel.scripts.OnShow()
selectNodeTarget(savingPanel,first,chosenNode,'Use')
advanced=button(first,'Advanced');advanced.scripts.OnClick(advanced)
nodeSlider(first,LL.ItemDB.professionProfiles.profiles['Engineering:10'].nodes[chosenNode].maxRank).changed(15)
check(visibleText(first):find('Resourcefulness extra saving: +5%',1,true),
    'item-use milestone displays its saving modifier independently of any unknown proc rate')
for index=first,#widgets do
    local w=widgets[index]
    if w.kind=='Frame' and w.shown and w.scripts.OnEnter then hover=w;break end
end
hover.scripts.OnEnter(hover)
check(tooltipShown,'item-use result opens a native tooltip')
savingPanel.scripts.OnHide()
check(rawget(savingPanel,'opportunityPreview')==nil and not tooltipShown,'closing the settings panel clears its active preview and tooltip')
print('PASS: '..checks..' native Loot/Use Settings contexts, live slider output, conditional event and hover assertions')
