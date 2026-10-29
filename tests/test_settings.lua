-- Native Settings interface fixtures; no hand-painted control implementations.
local all,settings={},{}
local function widget(kind,parent,template)
    local w={kind=kind,parent=parent,template=template,scripts={},shown=true,enabled=true}
    local noop=function() end
    for _,name in ipairs({'SetSize','SetWidth','SetHeight','ClearAllPoints','SetAllPoints','SetColorTexture',
        'SetJustifyH','SetFontObject','SetTextInsets','SetAutoFocus','ClearFocus',
        'RegisterEvent','SetVertexColor','SetHighlightTexture','SetTextColor','SetObeyStepOnDrag','SetButtonState'}) do w[name]=noop end
    function w:SetPoint(...) self.point={...} end
    function w:Enable() self.enabled=true end
    function w:Disable() self.enabled=false end
    function w:SetEnabled(v) self.enabled=v end
    function w:Show() local was=self.shown;self.shown=true;if not was and self.scripts.OnShow then self.scripts.OnShow(self) end end
    function w:Hide() self.shown=false end
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
    function w:SetValue(v) self.value=v;if self.scripts.OnValueChanged then self.scripts.OnValueChanged(self,v) end end
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
        elseif template=='SettingsDropdownControlTemplate' then
            self.Control=widget('Frame',self)
            self.Control.HideSteppers=function() end
            self.Control.Dropdown=widget('DropdownButton',self.Control)
            self.Control.Dropdown.GenerateMenu=function() self.menu=initializer.options() end
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
    local setting={}
    function setting:GetValue() return get() end
    function setting:SetValue(value)
        if get()==value then return end
        set(value);if self.callback then self.callback(self,value) end
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
for _,file in ipairs({'Database.lua','SettingsControls.lua','Settings.lua','Professions.lua'}) do
    assert(loadfile('LootLiquidator/'..file))('LootLiquidator',LL)
end
LL:MigrateEvidenceSettings()
local panel=LL:CreateEvidenceSettingsPanel({})
local checkboxes,sliders={},{ }
for _,w in ipairs(all) do
    if w.template=='SettingsCheckboxControlTemplate' then checkboxes[#checkboxes+1]=w end
    if w.kind=='Slider' then sliders[#sliders+1]=w end
end
assert(#checkboxes==4 and #sliders==4)
panel.scripts.OnShow(panel)
for i,key in ipairs(LL.SourceOrder) do
    assert(sliders[i].minimum==0 and sliders[i].maximum==100 and sliders[i].step==1)
    local native=checkboxes[i].Checkbox
    native:SetChecked(false);native.scripts.OnClick(native)
    assert(LL.db['source_'..key..'_enabled']==false)
    sliders[i]:SetValue(23)
    assert(LL.db['source_'..key..'_weight']==23)
end
assert(invalidations>=7)
local unrelated={graphics=7,bindings='custom'}
for _,w in ipairs(all) do if w.text=='Reset source weights' and w.kind=='Button' then w.scripts.OnClick(w) end end
for key,d in pairs(LL.SourceDefaults) do assert(LL.db['source_'..key..'_weight']==d[2]);assert(LL.db['source_'..key..'_enabled']==d[1]) end
assert(unrelated.graphics==7 and unrelated.bindings=='custom')
-- Every settings control was initialized with its Blizzard factory.
for _,w in ipairs(all) do
    if w.template and w.template:match('ControlTemplate$') then assert(w.initializer and w.initializer.factory) end
end
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
char.professionOptions={['Jewelcrafting:11']={nodes={{id=12,name='Gem Cutting',tab='Gems',maxRank=30}},buffs={{id=123,name='Profession Tea'}}}}
LL.GetProfessionUIOptions=function(_,character,profession,expansion)
    return char.professionOptions[profession..':'..expansion] or {nodes={},buffs={}}
end
local start=#all
local profile=LL:CreateProfessionProfilePanel('Jewelcrafting')
profile.scripts.OnShow(profile)
local checks,dropdowns,skillSlider={},{},nil
for i=start+1,#all do
    local w=all[i]
    assert(w.kind~='EditBox','profession editor must not require typing')
    if w.template=='SettingsCheckboxControlTemplate' then checks[#checks+1]=w end
    if w.template=='SettingsDropdownControlTemplate' then dropdowns[#dropdowns+1]=w end
    if w.kind=='Slider' then skillSlider=w end
end
assert(#checks==3 and #dropdowns==5 and skillSlider)
local function click(w,value) w.Checkbox:SetChecked(value);w.Checkbox.scripts.OnClick(w.Checkbox) end
click(checks[1],true);click(checks[2],true);skillSlider:SetValue(95)
dropdowns[3].initializer.setting:SetValue(1) -- choose Blizzard specialization
dropdowns[4].initializer.setting:SetValue(4) -- rank selection
dropdowns[5].initializer.setting:SetValue(1);click(checks[3],true)
local saved=LL:GetManualProfessionProfile('Tester - Realm','Jewelcrafting',11)
assert(saved.skill==95 and saved.specialization=='12=4' and saved.enabled and saved.simulated)
assert(saved.buffs['123']==true)
assert(char.researchProfiles==nil,'UI must not overwrite scanned snapshots')
dropdowns[2].initializer.setting:SetValue(10)
assert(LL:GetManualProfessionProfile('Tester - Realm','Jewelcrafting',10)==nil,'browsing must not create a simulation')
assert(LL:ProfessionExpansionName(11)=='Midnight')
print('PASS: native Settings factories, scoped weight reset, Defaults guard, named profession selections and preserved snapshots')
