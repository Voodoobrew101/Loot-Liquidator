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
assert(#checkboxes==3 and #sliders==3) -- B2: one row per source; frozen TSM row removed
panel.scripts.OnShow(panel)
for i,key in ipairs(LL.SourceOrder) do
    assert(sliders[i].minimum==0 and sliders[i].maximum==100 and sliders[i].step==1)
    local native=checkboxes[i].Checkbox
    native:SetChecked(false);native.scripts.OnClick(native)
    assert(LL.db['source_'..key..'_enabled']==false)
    sliders[i]:SetValue(23)
    assert(LL.db['source_'..key..'_weight']==23)
end
assert(invalidations>=2*#LL.SourceOrder-1) -- B2: scales with source rows (was a fixed 7 for four rows)
local unrelated={graphics=7,bindings='custom'}
for _,w in ipairs(all) do if w.text=='Reset source weights' and w.kind=='Button' then w.scripts.OnClick(w) end end
for key,d in pairs(LL.SourceDefaults) do assert(LL.db['source_'..key..'_weight']==d[2]);assert(LL.db['source_'..key..'_enabled']==d[1]) end
assert(unrelated.graphics==7 and unrelated.bindings=='custom')
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
for _,dropdown in ipairs(dropdowns) do
    assert(not dropdown.Control.steppersShown)
    dropdown:InitDropdown();dropdown:Refresh()
    assert(not dropdown.Control.steppersShown,'menu rebuild restored dropdown arrows')
end
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
-- B4: "Include alts" switch on the Badges page, bound to includeVerifiedAlts.
do
    local layout=function() return {AddInitializer=function() end} end
    Settings.RegisterVerticalLayoutCategory=function() return {},layout() end
    local pages={}
    Settings.RegisterVerticalLayoutSubcategory=function(_,name) pages[name]=true;return {},layout() end
    Settings.RegisterCanvasLayoutCategory=function() return {} end
    Settings.RegisterCanvasLayoutSubcategory=function() return {} end
    Settings.RegisterAddOnCategory=function() end
    Settings.VarType=Settings.VarType or {Number='number',Boolean='boolean',String='string'}
    Settings.CreateCheckbox=function(_,setting) return {setting=setting} end
    Settings.CreateDropdown=function(_,setting,options) return {setting=setting,options=options,InitFrame=function() end} end
    Settings.CreateElementInitializer=Settings.CreateElementInitializer or function() return {} end
    CreateSettingsListSectionHeaderInitializer=CreateSettingsListSectionHeaderInitializer or function() return {} end
    LL.db.includeVerifiedAlts=nil;LL.settingsCategory=nil
    local ok,err=pcall(LL.RegisterNativeSettings,LL);if not ok then print('settings build stopped early: '..tostring(err)) end
    local box=LL.badgeSettingsPanel and LL.badgeSettingsPanel.llIncludeAltsCheckbox
    assert(box,'Include alts checkbox missing on the Badges page'..(ok and '' or (': '..tostring(err))))
    local native=box.Checkbox or box.CheckBox
    assert(box:GetChecked()==true,'Include alts defaults on')
    assert(settings.LootLiquidator_includeVerifiedAlts,'Include alts registered for Defaults')
    LL.Paint=LL.Paint or function() end
    local before=invalidations
    native:SetChecked(false);native.scripts.OnClick(native)
    assert(LL.db.includeVerifiedAlts==false and invalidations>before,'switch off recalculates badges')
    native:SetChecked(true);native.scripts.OnClick(native)
    assert(LL.db.includeVerifiedAlts==true)
    print('PASS: Include alts switch on the Badges page (B4)')
    -- B5a/B5b: rate choice on the main page; what-if pages have a new home.
    assert(settings.LootLiquidator_rateProfile and settings.LootLiquidator_rateProfileCharacter,'Show rates for registered')
    assert(LL.db.rateProfileCharacter=='' or LL.db.rateProfileCharacter==nil)
    assert(pages['Professions (what-if)'],'what-if profession pages need a parent page')
    local rows=LL:RateProfileCharacterChoices()
    assert(rows[1][1]=='' and rows[2][1]=='Tester - Realm','character choices list saved characters')
    print('PASS: Show rates for + Professions (what-if) page (B5a/B5b)')
end
print('PASS: native Settings factories, slider notification regression, scoped Defaults, arrow-free dropdown refresh/reuse and profession simulations')
