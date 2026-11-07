-- Native Settings interface fixtures; no hand-painted control implementations.
local all,settings={},{}
local function widget(kind,parent,template)
    local w={kind=kind,parent=parent,template=template,scripts={},shown=true,enabled=true}
    local noop=function() end
    for _,name in ipairs({'SetSize','SetWidth','SetHeight','ClearAllPoints','SetAllPoints','SetColorTexture',
        'SetJustifyH','SetFontObject','SetTextInsets','SetAutoFocus','ClearFocus',
        'RegisterEvent','SetVertexColor','SetHighlightTexture','SetTextColor','SetObeyStepOnDrag','SetButtonState','SetTexture','SetParent','SetScrollChild','SetMaxLetters','RegisterForDrag'}) do w[name]=noop end
    function w:SetPoint(...) self.point={...} end
    function w:Enable() self.enabled=true end
    function w:Disable() self.enabled=false end
    function w:SetEnabled(v) self.enabled=v end
    function w:Show() local was=self.shown;self.shown=true;if not was and self.scripts.OnShow then self.scripts.OnShow(self) end end
    function w:Hide() self.shown=false;self.hideCount=(self.hideCount or 0)+1 end
    function w:SetScript(k,fn) self.scripts[k]=fn end
    function w:GetScript(k) return self.scripts[k] end
    function w:HookScript(k,fn) local old=self.scripts[k];self.scripts[k]=function(...) if old then old(...) end;fn(...) end end
    function w:SetText(v) self.text=v end
    function w:GetText() return self.text or '' end
    function w:SetChecked(v) self.checked=v end
    function w:GetChecked() return self.checked end
    function w:SetFontString(v) self.fontString=v end
    function w:GetFontString() return self.fontString end
    function w:CreateFontString() return widget('FontString',self) end
    function w:CreateTexture() return widget('Texture',self) end
    function w:SetMinMaxValues(a,b) self.minimum=a;self.maximum=b end
    function w:SetValueStep(v) self.step=v end
    function w:SetValue(v)
        if kind=='Slider' then
            v=math.max(self.minimum,math.min(self.maximum,v))
            v=self.minimum+math.floor((v-self.minimum)/self.step+.5)*self.step
        end
        local changed=self.value~=v
        self.value=v
        if changed and self.scripts.OnValueChanged then self.scripts.OnValueChanged(self,v) end
    end
    function w:Init(initializer)
        self.initializer=initializer
        local s=initializer.setting
        if template=='SettingsCheckboxControlTemplate' then
            self.Checkbox=widget('CheckButton',self,'SettingsCheckboxTemplate')
        elseif template=='SettingsSliderControlTemplate' then
            self.SliderWithSteppers=widget('Frame',self)
            local slider=widget('Slider',self.SliderWithSteppers,'MinimalSliderWithSteppersTemplate')
            self.SliderWithSteppers.Slider=slider
            slider.minimum=initializer.options.minValue;slider.maximum=initializer.options.maxValue;slider.step=initializer.options.step
            slider.value=s:GetValue()
            slider:SetScript('OnValueChanged',function(_,v) s:SetValue(v) end)
            -- Blizzard SettingsControlMixin.OnSettingValueChanged calls the
            -- control's SetValue, which must update the widget, not the setting.
            function self.SliderWithSteppers:SetValue(v) slider:SetValue(v) end
            function self:SetValue(v) self.SliderWithSteppers:SetValue(v) end
            self.nativeSetValue=self.SetValue
            s.observers[#s.observers+1]=function(v) self:SetValue(v) end
        elseif template=='SettingsDropdownControlTemplate' then
            self.Control=widget('Frame',self)
            self.Control.HideSteppers=function(control) control.steppersShown=false end
            self.Control.Dropdown=widget('DropdownButton',self.Control)
            self.Control.Dropdown.GenerateMenu=function() self.menu=initializer.options() end
            function self:InitDropdown()
                self.Control.steppersShown=not self.forceSteppersHidden
                self.menu=initializer.options()
            end
            function self:SetValue() self:InitDropdown() end
            s.observers[#s.observers+1]=function(v) self:SetValue(v) end
            self:InitDropdown()
        elseif template=='SettingButtonControlTemplate' then
            self.Button=widget('Button',self,'UIPanelButtonTemplate')
            self.Button:SetScript('OnClick',initializer.click)
        end
    end
    all[#all+1]=w
    return w
end
CreateFrame=function(kind,name,parent,template) return widget(kind,parent,template) end
UnitName=function() return 'Tester' end
GetRealmName=function() return 'Realm' end
Settings={}
function Settings.RegisterVerticalLayoutCategory() return {} end
function Settings.RegisterProxySetting(_,name,kind,label,default,get,set)
    local setting={observers={},notifications=0,depth=0}
    function setting:GetValue() return get() end
    function setting:SetValue(value)
        -- SettingMixin.ApplyValue notifies even when the value is unchanged.
        -- The previous stub's early return concealed alpha4's recursion.
        self.depth=self.depth+1
        assert(self.depth<30,'recursive Settings setting -> control:SetValue -> setting')
        if get()~=value then set(value) end
        self.notifications=self.notifications+1
        for _,observer in ipairs(self.observers) do observer(value) end
        if self.callback then self.callback(self,value) end
        self.depth=self.depth-1
    end
    function setting:SetValueChangedCallback(fn) self.callback=fn end
    settings[name]=setting;return setting
end
function Settings.RegisterAddOnSetting(cat,name,key,db,kind,label,default)
    if db[key]==nil then db[key]=default end
    return Settings.RegisterProxySetting(cat,name,kind,label,default,function()return db[key]end,function(v)db[key]=v end)
end
Settings.GetSetting=function(name) return settings[name] end
Settings.CreateCheckboxInitializer=function(setting) return {setting=setting,factory='checkbox'} end
Settings.CreateSliderOptions=function(lo,hi,step) return {minValue=lo,maxValue=hi,step=step} end
Settings.CreateSliderInitializer=function(setting,options) return {setting=setting,options=options,factory='slider'} end
Settings.CreateSlider=function(category,setting,options)
    assert(category,'native slider must have a Settings layout host')
    local initializer=Settings.CreateSliderInitializer(setting,options)
    initializer.createdBySettingsSlider=true
    return initializer
end
Settings.CreateDropdownInitializer=function(setting,options) return {setting=setting,options=options,factory='dropdown'} end
Settings.CreateControlTextContainer=function()
    local c={};function c:Add(value,label,tooltip) self[#self+1]={value=value,label=label,tooltip=tooltip} end
    function c:GetData() return self end;return c
end
CreateSettingsButtonInitializer=function(_,_,click) return {click=click,factory='button'} end
local LL={ItemDB={schemaVersion=1,processing={},mechanicRules={}},db={characters={['Tester - Realm']={}},appearance={colors={}}}}
LL.CharacterKey=function() return 'Tester - Realm' end
local invalidations=0
LL.Invalidate=function() invalidations=invalidations+1 end
for _,file in ipairs({'Database.lua','BuildInfo.lua','SettingsControls.lua','Settings.lua','Professions.lua'}) do
    assert(loadfile('LootLiquidator/'..file))('LootLiquidator',LL)
end
LL:MigrateEvidenceSettings()
-- B8b: Database & Accuracy is a native vertical page: one checkbox and one
-- weight slider per source (slider nested under its checkbox), plus a Reset
-- button. Changed on purpose from the old canvas-row test.
local createdChecks,createdSliders,layoutItems={}, {}, {}
local function nestable(t) function t:SetParentInitializer(parent,pred) self.parent=parent;self.predicate=pred end;return t end
Settings.CreateCheckbox=function(_,setting) local i=nestable({setting=setting,factory='checkbox'});createdChecks[#createdChecks+1]=i;return i end
local baseCreateSlider=Settings.CreateSlider
Settings.CreateSlider=function(category,setting,options) local i=nestable(baseCreateSlider(category,setting,options));createdSliders[#createdSliders+1]=i;return i end
local accuracyLayout={AddInitializer=function(_,i) layoutItems[#layoutItems+1]=i end}
CreateSettingsButtonInitializer=function(name,_,click) return {name=name,click=click,factory='button'} end
LL:AddEvidenceSettings({},accuracyLayout)
assert(#createdChecks==#LL.SourceOrder and #createdSliders==#LL.SourceOrder and #LL.SourceOrder==5)
for i,key in ipairs(LL.SourceOrder) do
    local check,slider=createdChecks[i],createdSliders[i]
    assert(slider.options.minValue==0 and slider.options.maxValue==100 and slider.options.step==1)
    assert(slider.parent==check,'weight slider sits under its source switch')
    check.setting:SetValue(false)
    assert(LL.db['source_'..key..'_enabled']==false and slider.predicate()==false)
    slider.setting:SetValue(23)
    assert(LL.db['source_'..key..'_weight']==23)
end
assert(invalidations>=2*#LL.SourceOrder-1) -- B2: scales with source rows (was a fixed 7 for four rows)
local unrelated={graphics=7,bindings='custom'}
local resetButton
for _,i in ipairs(layoutItems) do if i.name=='Reset source weights' then resetButton=i end end
assert(resetButton,'Reset source weights button missing')
resetButton.click()
for key,d in pairs(LL.SourceDefaults) do assert(LL.db['source_'..key..'_weight']==d[2]);assert(LL.db['source_'..key..'_enabled']==d[1]) end
assert(unrelated.graphics==7 and unrelated.bindings=='custom')
Settings.CreateSlider=baseCreateSlider;Settings.CreateCheckbox=nil
CreateSettingsButtonInitializer=function(_,_,click) return {click=click,factory='button'} end
print('PASS: Database & Accuracy uses native checkboxes, sliders and a Reset button (B8b)')
local panel=CreateFrame('Frame')
-- Every settings control was initialized with its Blizzard factory.
for _,w in ipairs(all) do
    if w.template and w.template:match('ControlTemplate$') then assert(w.initializer and w.initializer.factory) end
end
-- Slider notifications use the native rendering setter. Same-value events,
-- refreshes, clamping and user drags must settle without a callback cycle.
local changes=0
local slider=LL:CreateSettingsCanvasSlider(panel,9,22,1,12,function() changes=changes+1 end)
assert(slider.SetValue==slider.nativeSetValue,'native Settings SetValue must never be replaced')
assert(slider.initializer.createdBySettingsSlider,'canvas slider must use Settings.CreateSlider')
slider:SetPreferenceValue(15)
assert(slider:GetPreferenceValue()==15 and slider.slider.value==15 and changes==1)
for i=1,100 do
    slider:SetPreferenceValue(15)
    slider.initializer.setting:SetValue(15) -- Blizzard emits this even if unchanged
end
assert(changes==1 and slider.initializer.setting.depth==0)
slider.slider:SetValue(17)
assert(slider:GetPreferenceValue()==17 and changes==2)
slider:SetPreferenceValue(99)
assert(slider:GetPreferenceValue()==22 and slider.slider.value==22 and changes==3)
slider:SetPreferenceValue(8.7)
assert(slider:GetPreferenceValue()==9 and slider.slider.value==9 and changes==4)
-- Shared Defaults must never open the game-wide reset dialog from our pages,
-- even if Blizzard search or another skin shows the header again.
local game,root,child,grandchild={},{},{},{}
function child:GetParentCategory() return root end
function grandchild:GetParentCategory() return child end
local current=game
local defaults=widget('Button')
local nativeClicks=0
defaults:SetScript('OnClick',function() nativeClicks=nativeClicks+1 end)
SettingsPanel={GetCurrentCategory=function() return current end,
    GetSettingsList=function() return {Header={DefaultsButton=defaults}} end,
    SearchBox={HasText=function() return false end}}
local categoryChanged
EventRegistry={RegisterCallback=function(_,event,fn) assert(event=='Settings.CategoryChanged');categoryChanged=fn end}
LL.settingsCategory=root
LL:ProtectSettingsDefaults()
defaults.scripts.OnClick(defaults);assert(nativeClicks==1)
for _,category in ipairs({root,child,grandchild}) do
    current=category;categoryChanged()
    assert(not defaults.shown and not defaults.enabled)
    defaults:Show();assert(not defaults.shown)
    defaults.scripts.OnClick(defaults);assert(nativeClicks==1,'addon page reached global defaults popup')
end
current=game;categoryChanged()
assert(defaults.shown and defaults.enabled)
defaults.scripts.OnClick(defaults);assert(nativeClicks==2,'game settings handler must remain intact')
LL:ProtectSettingsDefaults();defaults.scripts.OnClick(defaults);assert(nativeClicks==3,'guard must be idempotent')
-- Profession editor: no typed node IDs, explicit unknowns, native controls,
-- independent character/expansion settings, measured scan untouched.
local char=LL.db.characters['Tester - Realm']
local realProfessionOptions=LL.GetProfessionUIOptions
-- These controls exercise native widget behavior under a declared synthetic
-- future model. Real shipped research support is tested through the same UI
-- below; this fixture does not make unsupported production inputs visible.
local function syntheticControlSupport(_,profession,expansion,nodes)
    local support={skill=true,nodes={},stats={},buffs={['123']=true},dependencyNodes={}}
    for _,node in ipairs(nodes or {}) do support.nodes[tostring(node.id)]=true end
    for _,stat in ipairs(LL:ProfessionSimulationStatOptions(profession)) do
        support.stats[stat.key]={rating=true,percent=true}
    end
    return support
end
LL.GetProfessionSimulationControlSupport=syntheticControlSupport
char.professionOptions={['Jewelcrafting:11']={nodes={{id=12,name='Gem Cutting',tab='Gems',maxRank=30}},buffs={{id=123,name='Profession Tea'}}}}
LL.GetProfessionUIOptions=function(_,character,profession,expansion)
    return char.professionOptions[profession..':'..expansion] or {nodes={},buffs={}}
end
local start=#all
local profile=LL:CreateProfessionProfilePanel('Jewelcrafting')
profile.scripts.OnShow(profile)
local dropdowns={}
for i=start+1,#all do
    local w=all[i]
    if w.template=='SettingsDropdownControlTemplate' then dropdowns[#dropdowns+1]=w end
end
assert(#dropdowns==2,'only character and expansion need dropdowns')
local function find(text)
    for i=start+1,#all do
        local w=all[i]
        if w.kind=='Button' and w.text==text then return w end
    end
    error('Missing button '..text)
end
local function press(text) local w=find(text);w.scripts.OnClick(w) end
local selector=dropdowns[1]
local rows=(selector.options or selector.initializer.options)()
assert(rows[2].label=='Simulated')
assert(selector.initializer.setting:GetValue()==-2)
selector.initializer.setting:SetValue(-1)
local saved=LL:GetManualProfessionProfile('Tester - Realm','Jewelcrafting',11)
assert(saved.enabled and saved.skill==0 and saved.specialization=='none' and not saved.buffs)
assert(char.researchProfiles==nil,'simulation never overwrites scanned data')
assert(find('Advanced').point[5]==-200,'Advanced stays directly below the status text')
press('Advanced')
local sliders={}
for i=start+1,#all do if all[i].kind=='Slider' then sliders[#sliders+1]=all[i] end end
assert(#sliders==10,'Advanced reveals skill, specialization and all eight stat sliders together')
sliders[1]:SetValue(95)
local holder=sliders[2].parent.parent
local hidden=holder.hideCount or 0
for value=1,4 do sliders[2]:SetValue(value) end
assert((holder.hideCount or 0)==hidden,'changing a slider must never hide it and cancel continuous dragging')
saved=LL:GetManualProfessionProfile('Tester - Realm','Jewelcrafting',11)
assert(saved.skill==95 and saved.specialization=='12=4')
local check
for i=start+1,#all do if all[i].template=='SettingsCheckboxControlTemplate' then check=all[i] end end
check.Checkbox:SetChecked(true);check.Checkbox.scripts.OnClick(check.Checkbox)
assert(LL:GetManualProfessionProfile('Tester - Realm','Jewelcrafting',11).buffs['123'])
sliders[4]:SetValue(17)
selector.initializer.setting:SetValue(0)
selector.initializer.setting:SetValue(-1)
saved=LL:GetManualProfessionProfile('Tester - Realm','Jewelcrafting',11)
assert(saved.skill==95 and saved.specialization=='12=4' and saved.buffs['123']
    and saved.stats.resourcefulness.percent==17,
    'returning to Simulated preserves specialization points, skill, buffs and stats')
press('Reset to minimum')
saved=LL:GetManualProfessionProfile('Tester - Realm','Jewelcrafting',11)
assert(saved.skill==0 and saved.specialization=='none' and saved.buffs==nil)
selector.initializer.setting:SetValue(0)
assert(not holder.shown,'hidden mode hides simulation controls')
selector.initializer.setting:SetValue(1)
dropdowns[2].initializer.setting:SetValue(10)
assert(not LL:GetManualProfessionProfile('Tester - Realm','Jewelcrafting',10),'browsing real character is read only')
assert(LL:ProfessionExpansionName(11)=='Midnight')
selector.initializer.setting:SetValue(-1)
assert(LL:GetManualProfessionProfile('Tester - Realm','Jewelcrafting',10).skill==0)
print('PASS: Simulated minimum, continuous sliders, one Advanced section, reset and character isolation')
-- Multi-level trees are visible with indentation and enforce known thresholds.
char.professionOptions['Jewelcrafting:11'].nodes={
    {id=12,name='Gem Cutting',tab='Gems',maxRank=30},
    {id=13,parentID=12,name='Rare Gems',tab='Gems',maxRank=20,
        requirements={{kind='node',nodeID=12,rank=10,name='Gem Cutting'}}},
    {id=14,parentID=13,name='Epic Gems',tab='Gems',maxRank=15,
        requirements={{kind='node',nodeID=13,rank=5,name='Rare Gems'}}}}
dropdowns[2].initializer.setting:SetValue(11)
local function lastSlider()
    for i=#all,start+1,-1 do if all[i].kind=='Slider' then return all[i] end end
end
local grandchild=lastSlider()
local child
for i=start+1,#all do if all[i].kind=='Slider' and all[i].maximum==20 then child=all[i] end end
assert(child.enabled==false,'child locked below prerequisite')
sliders[2]:SetValue(10)
assert(child.enabled==true,'exact parent boundary unlocks child')
child:SetValue(5);grandchild:SetValue(4)
assert(child.parent.parent.point[4]>sliders[2].parent.parent.point[4],'branch sliders are indented')
assert(LL:GetManualProfessionProfile('Tester - Realm','Jewelcrafting',11).specialization:find('14=4',1,true))
sliders[2]:SetValue(9)
saved=LL:GetManualProfessionProfile('Tester - Realm','Jewelcrafting',11)
assert(not saved.specialization:find('13=5',1,true) and not saved.specialization:find('14=4',1,true),
    'lowering parent clears dependent allocations through every branch level')
local speedInput
for i=start+1,#all do if all[i].kind=='Slider' and all[i].maximum==200 then speedInput=all[i] end end
speedInput:SetValue(125.5)
saved=LL:GetManualProfessionProfile('Tester - Realm','Jewelcrafting',11)
assert(saved.stats.craftingSpeed.percent==126,'speed bonus is whole-number and not capped at 100 percent')
press('Hide advanced')
assert(not speedInput.parent.parent.shown,'single Advanced section hides stats')
assert(not holder.shown,'Advanced hides all specialization controls')
assert(not sliders[1].parent.parent.shown,'Advanced also hides simulated skill')
assert(find('Advanced').point[5]==-200,'collapsing keeps Advanced at the top')
assert(LL:GetManualProfessionProfile('Tester - Realm','Jewelcrafting',11).stats.craftingSpeed.percent==126)
for i=start+1,#all do
    local w=all[i]
    assert(not(w.kind=='Button' and w.text and (w.text:match('^Show .*branches') or w.text=='Show Gems')),'no nested disclosure buttons')
end
press('Reset to minimum')
assert(LL:GetManualProfessionProfile('Tester - Realm','Jewelcrafting',11).stats==nil)
print('PASS: nested branches, prerequisite boundary and cascade, stat controls and collapse preservation')
assert(LL:SetManualProfessionProfile('Tester - Realm','Jewelcrafting',11,
    {enabled=true,skill=1250,specialization='none',stats={craftingSpeed={rating=12000,percent=275}}}))
profile.scripts.OnShow(profile);press('Advanced')
assert(sliders[1].value==1250 and sliders[1].maximum>=1250,'saved skill expands editing span')
assert(speedInput.value==275 and speedInput.maximum>=275,'saved speed expands editing span')
local largeRating=false
for i=start+1,#all do
    if all[i].kind=='Slider' and all[i].value==12000 then largeRating=all[i].maximum>=12000 end
end
assert(largeRating,'saved ratings above the starting span remain available')
print('PASS: high saved skill, rating and speed values survive whole-number slider layout')

-- Pooled vertical controls must hide arrows for our settings after every
-- rebuild, then restore normal behavior when reused by another category.
hooksecurefunc=function(frame,method,callback)
    local original=frame[method]
    frame[method]=function(self,...) original(self,...);callback(self,...) end
end
local variable='LootLiquidator_disenchantDataMode'
local pooled={Control={HideSteppers=function(self)self.steppersShown=false end},
    GetSetting=function()return {GetVariable=function()return variable end}end}
function pooled:InitDropdown() self.Control.steppersShown=true end
local initializer=LL:WithoutDropdownSteppers({InitFrame=function(_,frame)frame:InitDropdown()end})
initializer:InitFrame(pooled);assert(not pooled.Control.steppersShown)
pooled:InitDropdown();assert(not pooled.Control.steppersShown)
variable='OtherAddon_option'
initializer:InitFrame(pooled);assert(pooled.Control.steppersShown,'pooled frame changed other addon dropdowns')
variable='LootLiquidator_tsmFallbackOperation'
pooled:InitDropdown();assert(not pooled.Control.steppersShown)
-- Canvas sliders must take the same modern ElvUI skin path as native Settings
-- list sliders, passing the complete step-slider container.
-- B5b: SkinSettingsCanvasControl now lives in SettingsControls.lua (loaded above).
local skinned=0
local stepSlider={Slider={}}
local fakeSkin={HandleStepSlider=function(_,native)
    assert(native==stepSlider);skinned=skinned+1
end,HandleSliderFrame=function()error('legacy inner-slider skin must not be used')end}
ElvUI={{GetModule=function()return fakeSkin end}}
LL:SkinSettingsCanvasControl({SliderWithSteppers=stepSlider},'slider')
assert(skinned==1)
ElvUI=nil
-- B4 + B8a: "Include alts" switch on the Badges page, bound to includeVerifiedAlts.
-- B8a changed the page from a canvas to a native vertical list on purpose,
-- so the test now looks for the native checkbox registered on that page.
do
    local layouts={}
    local function layout(name) local l={items={},AddInitializer=function(self,i) self.items[#self.items+1]=i end};layouts[name]=l;return l end
    Settings.RegisterVerticalLayoutCategory=function() return {name='root'},layout('root') end
    local pages={}
    Settings.RegisterVerticalLayoutSubcategory=function(_,name) local c={name=name};pages[name]=c;return c,layout(name) end
    Settings.RegisterCanvasLayoutCategory=function() return {} end
    local canvases={}
    Settings.RegisterCanvasLayoutSubcategory=function(_,_,name) canvases[#canvases+1]=name;return {} end
    Settings.RegisterAddOnCategory=function() end
    Settings.VarType=Settings.VarType or {Number='number',Boolean='boolean',String='string'}
    local created={}
    Settings.CreateCheckbox=function(cat,setting)
        local i={category=cat,setting=setting}
        function i:AddShownPredicate(fn) self.shownPredicate=fn end
        created[#created+1]=i;return i
    end
    Settings.CreateDropdown=function(cat,setting,options) local i={category=cat,setting=setting,options=options,InitFrame=function() end};created[#created+1]=i;return i end
    local baseSlider=Settings.CreateSlider
    Settings.CreateSlider=function(cat,setting,options) local i=baseSlider(cat,setting,options);i.category=cat;created[#created+1]=i;return i end
    Settings.CreatePanelInitializer=function(template) return {template=template} end
    Settings.CreateElementInitializer=Settings.CreateElementInitializer or function() return {} end
    CreateSettingsListSectionHeaderInitializer=function(title)
        return {title=title,InitFrame=function(_,frame)
            frame.title=title
            frame:SetTooltipFunc(function()return title end)
        end}
    end
    CreateSettingsButtonInitializer=function(name,text,click) return {name=name,text=text,click=click,factory='button'} end
    LL.db.includeVerifiedAlts=nil;LL.settingsCategory=nil
    local ok,err=pcall(LL.RegisterNativeSettings,LL);if not ok then print('settings build stopped early: '..tostring(err)) end
    assert(ok,tostring(err))
    local buildSection,rateSection,details=false,false,nil
    for _,item in ipairs(layouts.root.items)do
        if item.title=='PRs & build' then buildSection=true end
        if item.title=='Rates' then rateSection=true end
        if item.name=='Build details' then details=item end
    end
    assert(buildSection and details and not rateSection,'main page shows build provenance instead of global Rates')
    local shownTitle,shownText
    local originalCopy=LL.ShowCopy
    LL.ShowCopy=function(_,title,text)shownTitle,shownText=title,text end
    details.click();assert(shownTitle=='PRs & build' and shownText:find('Source commit:',1,true))
    LL.ShowCopy=originalCopy
    local headingFrame={SetTooltipFunc=function(self,fn)self.tooltipFunc=fn end}
    local count=0
    for _,layout in pairs(layouts) do
        for _,initializer in ipairs(layout.items) do
            if initializer.title then
                initializer:InitFrame(headingFrame)
                assert(headingFrame.title==initializer.title,'native heading initialization preserved')
                assert(headingFrame.tooltipFunc==nil,'heading must not show a floating hover label')
                count=count+1
            end
        end
    end
    assert(count>2,'exercise multiple headings including Extras and What to display')
    local other=CreateSettingsListSectionHeaderInitializer('Other addon heading')
    other:InitFrame(headingFrame)
    assert(headingFrame.tooltipFunc()=='Other addon heading','pooled rows restore other addons hover behavior')
    print('PASS: section headings suppress hover labels without altering native initialization or pooled reuse')
    local badges=pages['Badges & Colors']
    assert(badges,'Badges & Colors page missing')
    local function control(cat,variable)
        for _,i in ipairs(created) do if i.category==cat and i.setting==settings[variable] then return i end end
    end
    local toggle
    for _,i in ipairs(layouts.Tooltips.items) do if i.name=='Advanced' then toggle=i end end
    assert(toggle and toggle.text()=='Show advanced options','Advanced is a real collapsed button')
    local advanced={}
    for _,key in ipairs({'showTooltipExplanations','showProfessionDetails','showResearchDetails'}) do
        local i=assert(control(pages.Tooltips,'LootLiquidator_'..key))
        assert(i.shownPredicate and not i.shownPredicate(),'advanced control starts hidden')
        advanced[#advanced+1]=i
    end
    local repairs=0
    SettingsPanel.GetSettingsList=function() return {RepairDisplay=function(_,layout)
        assert(layout==layouts.Tooltips);repairs=repairs+1
    end} end
    local button={SetText=function(self,text) self.text=text end}
    toggle.click(button)
    assert(button.text=='Hide advanced options' and toggle.text()==button.text)
    for _,i in ipairs(advanced) do assert(i.shownPredicate());i.setting:SetValue(true) end
    toggle.click(button)
    for _,i in ipairs(advanced) do assert(not i.shownPredicate() and i.setting:GetValue()==true) end
    toggle.click(button)
    for _,i in ipairs(advanced) do assert(i.shownPredicate() and i.setting:GetValue()==true) end
    assert(repairs==3,'each click repairs native layout without rebuilding settings')
    assert(control(pages.Tooltips,'LootLiquidator_showMaterialConfidence').shownPredicate==nil,'Extras stay visible')
    print('PASS: Advanced expands/collapses three controls, repairs native layout and preserves checkbox values')
    local alts=control(badges,'LootLiquidator_includeVerifiedAlts')
    assert(alts,'Include alts checkbox missing on the Badges page')
    assert(LL.db.includeVerifiedAlts==true,'Include alts defaults on')
    LL.Paint=LL.Paint or function() end
    local before=invalidations
    alts.setting:SetValue(false)
    assert(LL.db.includeVerifiedAlts==false and invalidations>before,'switch off recalculates badges')
    alts.setting:SetValue(true)
    assert(LL.db.includeVerifiedAlts==true)
    print('PASS: Include alts switch on the Badges page (B4)')
    -- B8a: every badge control is a native Settings control on that page.
    for _,key in ipairs({'showBadges','showUnknownBadge','showSoulboundVendorBadge','showBlizzardBags','showBetterBags','showGuildBank'}) do
        assert(control(badges,'LootLiquidator_'..key),key..' missing on the Badges page')
    end
    local position=control(badges,'LootLiquidator_appearance_position')
    local size=control(badges,'LootLiquidator_appearance_fontSize')
    assert(position and size,'position dropdown and font size slider are native')
    assert(#position.options()==9 and position.setting:GetValue()=='TOPRIGHT')
    position.setting:SetValue('BOTTOMLEFT');assert(LL.db.appearance.position=='BOTTOMLEFT')
    assert(size.options.minValue==9 and size.options.maxValue==22)
    size.setting:SetValue(18);assert(LL.db.appearance.fontSize==18)
    local colorButtons,reset=0,nil
    for _,i in ipairs(layouts['Badges & Colors'].items) do
        if i.factory=='button' and i.text=='Change color' then colorButtons=colorButtons+1 end
        if i.factory=='button' and i.text=='Reset colors' then reset=i end
    end
    assert(colorButtons==#LL.BadgeColorOrder and reset,'one color button per badge and a reset')
    LL.db.appearance.colors.A={0,0,0};reset.click();assert(next(LL.db.appearance.colors)==nil)
    -- Only the hypothetical profession pages and Ignored Items stay as canvas pages.
    for _,name in ipairs(canvases) do assert(name~='Badges & Colors' and name~='Database & Accuracy',name..' is still a canvas page') end
    local accuracy=pages['Database & Accuracy']
    assert(accuracy and control(accuracy,'LootLiquidator_source_itemdb_enabled'),'Database & Accuracy is native')
    print('PASS: Badges & Colors and Database & Accuracy are native Settings pages (B8a/B8b)')
    -- Profession pages replace the redundant global rate controls.
    assert(not settings.LootLiquidator_rateProfile and not settings.LootLiquidator_rateProfileCharacter,'global Rates controls are retired')
    assert(LL.db.rateProfileCharacter=='' or LL.db.rateProfileCharacter==nil)
    assert(pages['Professions (Simulated)'],'hypothetical profession pages need a parent page')
    local rows=LL:RateProfileCharacterChoices()
    assert(rows[1][1]=='' and rows[2][1]=='Tester - Realm','character choices list saved characters')
    print('PASS: Show rates for + Professions (Simulated) page (B5a/B5b)')
end
print('PASS: native Settings factories, slider notification regression, scoped Defaults, arrow-free dropdown refresh/reuse and profession simulations')
do
    -- Inert ancestors may label a working branch without becoming sliders.
    -- Unsupported siblings and entire inactive trees do not clutter the editor.
    local previousSupport=LL.GetProfessionSimulationControlSupport
    char.professionOptions['Inscription:11']={nodes={
        {id=81,name='Heading parent',tab='Working tree',maxRank=30},
        {id=82,name='Working child',parentID=81,tab='Working tree',maxRank=20},
        {id=83,name='Inactive sibling',parentID=81,tab='Working tree',maxRank=20},
        {id=84,name='Inactive tree',tab='No calculation',maxRank=30}},buffs={}}
    LL.GetProfessionSimulationControlSupport=function()
        return {skill=false,nodes={['82']=true},stats={},buffs={},dependencyNodes={}}
    end
    local first=#all
    local editor=LL:CreateProfessionProfilePanel('Inscription')
    editor.scripts.OnShow(editor)
    local advanced
    for i=first+1,#all do if all[i].kind=='Button' and all[i].text=='Advanced' then advanced=all[i] end end
    assert(advanced);advanced.scripts.OnClick(advanced)
    local function shown(w)
        while w do if w.shown==false then return false end;w=w.parent end
        return true
    end
    local active,parent,child=0,nil,nil
    for i=first+1,#all do
        local w=all[i]
        if shown(w) then
            if w.kind=='Slider' then active=active+1 end
            if w.kind=='FontString' and w.text then
                if w.text:find('Heading parent',1,true)==1 then parent=w end
                if w.text:find('Working child',1,true)==1 then child=w end
                assert(w.text:find('Inactive sibling',1,true)~=1 and w.text~='No calculation',
                    'unsupported siblings and empty trees remain hidden')
            end
        end
    end
    assert(active==1 and parent and child,'only the working child has a slider; its ancestor remains a heading')
    assert(child.point[4]>parent.point[4],'the remaining branch keeps its hierarchy')
    LL.GetProfessionSimulationControlSupport=previousSupport
    print('PASS: filtered tree keeps inert ancestor labels without dead sliders or inactive siblings')
end
do
    -- Exercise real research support and the bundled catalog through the UI.
    -- Catalog membership alone must never expose a slider with no calculation.
    LL.GetProfessionUIOptions=realProfessionOptions
    assert(loadfile('LootLiquidator/ProfessionCatalog.lua'))('LL',LL)
    assert(loadfile('LootLiquidator/ProfessionModels.lua'))('LL',LL)
    assert(loadfile('LootLiquidator/ItemDBRuntime.lua'))('LL',LL)
    GetBuildInfo=function() return '12.1.5','70783' end
    assert(LL:InitializeItemDB())
    local function shown(w)
        while w do if w.shown==false then return false end;w=w.parent end
        return true
    end
    local function labelsAfter(first,prefix)
        local result={}
        for i=first+1,#all do
            local w=all[i]
            if w.kind=='FontString' and w.text and w.text:find(prefix,1,true)==1 and shown(w) then result[#result+1]=w end
        end
        return result
    end
    local function slidersAfter(first)
        local result={}
        for i=first+1,#all do if all[i].kind=='Slider' and shown(all[i]) then result[#result+1]=all[i] end end
        return result
    end
    local function sliderAt(label,first)
        for _,w in ipairs(slidersAfter(first)) do
            if w.parent.parent.point and w.parent.parent.point[5]==label.point[5]+5 then return w end
        end
    end
    assert(LL:SetManualProfessionProfile('Tester - Realm','Enchanting',11,{enabled=true,skill=245,
        specialization='107646=12,107648=17,107649=9,107647=8',
        stats={resourcefulness={rating=250,percent=17}},buffs={['123']=true}}))
    LL.db.professionTooltipProfiles.Enchanting=nil
    local before=#all
    local editor=LL:CreateProfessionProfilePanel('Enchanting')
    editor.scripts.OnShow(editor)
    local toggle,selector
    for i=before+1,#all do
        local w=all[i]
        if w.kind=='Button' and w.text=='Advanced' then toggle=w end
        if w.template=='SettingsDropdownControlTemplate' and not selector then selector=w end
    end
    assert(selector.initializer.setting:GetValue()==-2)
    toggle.scripts.OnClick(toggle)
    local delegate=assert(labelsAfter(before,'Disenchanting Delegate (')[1])
    local shard=assert(labelsAfter(before,'Shard Supplier')[1])
    local slider=sliderAt(delegate,before)
    assert(slider and slider.maximum==30 and slider.parent.parent.shown)
    assert(sliderAt(shard,before),'the sourced max-specialization reference keeps both required point sliders')
    assert(#slidersAfter(before)==2,'Enchanting has only its two calculated reference-allocation sliders')
    assert(#labelsAfter(before,'Crystal Collector')==0 and #labelsAfter(before,'Dust Deliverer')==0,
        'skill-only branches without an output model stay hidden')
    assert(#labelsAfter(before,'Skill before specialization')==0,'skill alone has no Enchanting output model')
    assert(#labelsAfter(before,'Resourcefulness rating')==0 and #labelsAfter(before,'Crafting speed')==0,
        'context-only crafting stats are not displayed as working controls')
    assert(LL.db.professionTooltipProfiles.Enchanting==nil,'opening Advanced does not change the tooltip profile')
    slider:SetValue(7)
    assert(selector.initializer.setting:GetValue()==-1,'editing a specialization switches to Simulated')
    local saved=LL:GetManualProfessionProfile('Tester - Realm','Enchanting',11)
    assert(saved.specialization:find('107649=7',1,true))
    assert(saved.specialization:find('107646=12',1,true) and saved.specialization:find('107648=17',1,true)
        and saved.skill==245 and saved.stats.resourcefulness.percent==17 and saved.buffs['123'],
        'editing a supported slider preserves hidden points, skill, stats and buffs')
    selector.initializer.setting:SetValue(1)
    assert(slider.parent.parent.shown,'character view also exposes the specialization editor')
    toggle.scripts.OnClick(toggle)
    assert(not slider.parent.parent.shown,'one Advanced toggle still collapses everything')
    -- A newly supplied executable formula brings its control back on refresh.
    -- This coefficient is explicitly synthetic; it is never shipped research.
    local added={ruleID='synthetic-ui-only:crystal-output',kind='quantity-multiplier',
        method='Disenchant',profession='Enchanting',expansionID=11,inputRarity=4,
        nodeID=107646,maxRank=30,perPoint=.01,build=70783,
        applyPolicy='EXECUTE',evidenceStatus='SOURCED_PROVISIONAL',confidence0to100=70,
        sourceClaimIDs={'synthetic-ui-test-only'}}
    LL.ItemDB.specializationRules[#LL.ItemDB.specializationRules+1]=added
    editor.scripts.OnShow(editor);toggle.scripts.OnClick(toggle)
    local restored=assert(labelsAfter(before,'Crystal Collector')[1],'new compatible research restores the named slider')
    local restoredSlider=assert(sliderAt(restored,before))
    assert(restoredSlider.value==12,'the returning control restores its saved point value')
    table.remove(LL.ItemDB.specializationRules)
    editor.scripts.OnShow(editor)
    assert(#labelsAfter(before,'Crystal Collector')==0 and not shown(restoredSlider),
        'removing executable support hides an existing pooled control again')
    assert(LL:GetManualProfessionProfile('Tester - Realm','Enchanting',11).specialization:find('107646=12',1,true),
        'hiding a control never deletes the saved allocation')
    local function nativePanel(profession,expansion)
        local first=#all
        local panel=LL:CreateProfessionProfilePanel(profession)
        panel.scripts.OnShow(panel)
        local dropdowns,advanced={},nil
        for i=first+1,#all do
            local w=all[i]
            if w.template=='SettingsDropdownControlTemplate' then dropdowns[#dropdowns+1]=w end
            if w.kind=='Button' and w.text=='Advanced' then advanced=w end
        end
        if expansion~=11 then dropdowns[2].initializer.setting:SetValue(expansion) end
        assert(advanced);advanced.scripts.OnClick(advanced)
        return first,panel
    end
    local jcFirst=nativePanel('Jewelcrafting',11)
    assert(#slidersAfter(jcFirst)==3,'Midnight Jewelcrafting shows base skill and two quality-linked point controls')
    assert(#labelsAfter(jcFirst,'Skill before specialization')==1)
    local twwFirst=nativePanel('Jewelcrafting',10)
    assert(#slidersAfter(twwFirst)==4,'TWW Jewelcrafting shows the four effective gem-replacement branches')
    assert(#labelsAfter(twwFirst,'Skill before specialization')==0,'a replacement model does not make unrelated skill effective')
    local unusedFirst=nativePanel('Blacksmithing',11)
    assert(#slidersAfter(unusedFirst)==0,'an unmodeled profession does not expose inert skill, stat or point sliders')
    print('PASS: real research hides inactive sliders, retains calculated points and restores controls and saved values with new support')
end
