-- Settings interaction fixtures with narrow native-widget stubs.
local all={}
local function widget(kind,parent,template)
    local w={kind=kind,parent=parent,template=template,scripts={}}
    local noop=function() end
    for _,name in ipairs({'SetSize','SetWidth','SetHeight','SetPoint','ClearAllPoints','SetAllPoints','SetColorTexture',
        'SetJustifyH','SetFontObject','SetTextInsets','SetAutoFocus','ClearFocus','Enable','Disable',
        'RegisterEvent','SetVertexColor','SetHighlightTexture','SetTextColor','SetObeyStepOnDrag'}) do w[name]=noop end
    function w:SetScript(k,fn) self.scripts[k]=fn end
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
    function w:SetupMenu(fn) self.menu=fn end
    if template=='SettingsCheckboxControlTemplate' then w.Checkbox=widget('CheckButton',w) end
    all[#all+1]=w
    return w
end
CreateFrame=function(kind,name,parent,template) return widget(kind,parent,template) end
UnitName=function() return 'Tester' end
GetRealmName=function() return 'Realm' end
local settings={}
Settings={}
function Settings.RegisterAddOnSetting(_,name,key,db,kind,label,default)
    local setting={}
    if db[key]==nil then db[key]=default end
    function setting:SetValue(value) db[key]=value;if self.callback then self.callback(self,value) end end
    function setting:SetValueChangedCallback(fn) self.callback=fn end
    settings[name]=setting;return setting
end
Settings.GetSetting=function(name) return settings[name] end
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
assert(invalidations>=8)
for _,w in ipairs(all) do if w.text=='Reset source weights' and w.kind=='Button' then w.scripts.OnClick(w) end end
for key,d in pairs(LL.SourceDefaults) do assert(LL.db['source_'..key..'_weight']==d[2]);assert(LL.db['source_'..key..'_enabled']==d[1]) end
local start=#all
local profile=LL:CreateProfessionProfilePanel('Jewelcrafting')
profile.scripts.OnShow(profile)
local edits,check,save={}
for i=start+1,#all do
    local w=all[i]
    if w.kind=='EditBox' then edits[#edits+1]=w end
    if w.template=='SettingsCheckboxControlTemplate' then check=w end
    if w.kind=='Button' and w.text=='Save simulation' then save=w end
end
assert(#edits==2 and save)
check:SetChecked(true);edits[1]:SetText('95');edits[2]:SetText('12=4,13=9')
save.scripts.OnClick(save)
local saved=LL:GetManualProfessionProfile('Tester - Realm','Jewelcrafting',11)
assert(saved.skill==95 and saved.specialization=='12=4,13=9' and saved.enabled and saved.simulated)
assert(LL.db.characters['Tester - Realm'].researchProfiles==nil,'UI must not overwrite scanned snapshots')
print('PASS: native checkbox clicks, 0-100 sliders, reset and manual profile Save persist preferences')
