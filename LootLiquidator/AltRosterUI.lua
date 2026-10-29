-- Professions & Alts: registered Blizzard Settings controls in a compact grid.
-- Settings.CreateDropdown/Checkbox register the initializer, NOT a live frame.
-- This canvas must host their native Settings row templates explicitly; unlike
-- Blizzard's own Settings list, ElvUI does not automatically skin canvas rows.
-- Apply the same ElvUI Settings skin code after row initialization; do not
-- substitute legacy gray dropdowns or forge a lookalike skin.
local _, LL = ...
local METHODS = {
    {key="T", title="Transmog", scan="class"},
    {key="D", title="Disenchant", profession="Enchanting"},
    {key="M", title="Milling", profession="Inscription"},
    {key="P", title="Prospecting", profession="Jewelcrafting"},
    {key="S", title="Smelting", profession="Mining"},
    {key="C", title="Craft /\nRefine", scan="recipes"},
    {key="R", title="Recycle /\nResearch", scan="research"},
    {key="X", title="Combine /\nExchange", scan="any"},
}
local MODES={"On","Auto","Off","Manual"} -- numeric SavedVariables semantics MUST NOT change
-- The Settings canvas uses WoW UI units, not physical screen pixels.
-- At the user's UI scale the prior 800-unit canvas rendered ~1340 screen
-- pixels and overflowed the visible Settings page by ~200 pixels. Keep the
-- label column usable, but use a 640-unit panel with 62-unit column pitch.
-- Final dropdown right edge = LEFT + 7*STEP + DROP_WIDTH = 606 units.
-- 34 units remain for the scroll bar and right-side breathing room.
local LEFT,STEP,PANEL_WIDTH,DROP_WIDTH=114,62,640,58
local liveFrames=setmetatable({}, {__mode="k"})
local panel
local rosterKeys={}
local settingsReady=false

local function Text(parent,font,x,y,w,value)
    local t=parent:CreateFontString(nil,"ARTWORK",font or "GameFontHighlight")
    t:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
    t:SetWidth(w)
    t:SetJustifyH("LEFT")
    if t.SetWordWrap then t:SetWordWrap(true) end
    t:SetText(value or "")
    return t
end
local function Detected(entry,m)
    if m.key=="T" then return entry.class~=nil end
    if m.profession then return type(entry.professions)=="table" and entry.professions[m.profession]~=nil end
    if m.key=="C" then return type(entry.recipes)=="table" and next(entry.recipes)~=nil end
    if m.key=="R" then return (entry.professions and entry.professions.Engineering~=nil)
        or (type(entry.recipes)=="table" and next(entry.recipes)~=nil) end
    return m.key=="X"
end
local function CheckboxValue(key,m)
    local entry=LL.db and LL.db.characters and LL.db.characters[key]
    if not entry then return false end
    local mode=LL:ProcessingMethodMode(m.key)
    local saved=entry.altMethods and entry.altMethods[m.key]
    if mode==3 then return false end
    if mode==4 then
        if saved~=nil then return saved==true end
        return Detected(entry,m)
    end
    if mode==2 then
        return Detected(entry,m) and (not LL.AltMethodEnabled or LL:AltMethodEnabled(key,m.key))
    end
    return Detected(entry,m)
end
local function MakeModeOptions()
    local out=Settings.CreateControlTextContainer()
    for idx,label in ipairs(MODES) do
        out:Add(idx,label,({
            "Evaluate even when access is not verified (recipe and binding still apply).",
            "Use scanned character professions and recipes.",
            "Disable this method.",
            "Only consider characters explicitly checked in this column."
        })[idx])
    end
    return out:GetData()
end
local function UpdateNativeStates()
    for frame,record in pairs(liveFrames) do
        if frame and record and record.kind=="check" then
            -- A mode change also changes the read-only preview state. Update
            -- the native checkbox without writing a Manual override.
            local native=frame.Checkbox or frame.CheckBox
            if native and native.SetChecked then
                native:SetChecked(CheckboxValue(record.character, METHODS[record.index]))
            end
            if frame.EvaluateState then frame:EvaluateState() end
        end
    end
    if panel and panel.RefreshRoster then panel:RefreshRoster() end
end
-- ElvUI skins Settings-created rows in SettingsListScrollUpdateChild(),
-- *not* when Settings.CreateDropdown() registers the initializer. Since a
-- canvas does not participate in that ScrollBox, mirror the exact native
-- widget skin calls from ElvUI/Game/Shared/Skins/SettingsPanel.lua.
-- This is optional integration: without ElvUI the original Blizzard widgets
-- are left intact, never painted with a hard-coded black/gold approximation.
local function ApplyElvUISettingsSkin(frame,record)
    if not frame or frame.llRosterElvUISkinned then return end
    local E=type(_G.ElvUI)=="table" and _G.ElvUI[1]
    if not E or type(E.GetModule)~="function" then return end
    local okSkin,skin=pcall(E.GetModule,E,"Skins")
    if not okSkin or not skin then return end
    if record.kind=="drop" then
        local c=frame.Control
        if not c or not c.Dropdown or type(skin.HandleButton)~="function" then return end
        -- The Settings list skins these three native buttons, not their
        -- container. Hidden steppers remain hidden after being skinned.
        local good=pcall(function()
            skin:HandleButton(c.Dropdown)
            if c.DecrementButton then skin:HandleButton(c.DecrementButton) end
            if c.IncrementButton then skin:HandleButton(c.IncrementButton) end
        end)
        if not good then return end
    elseif record.kind=="button" then
        if not frame.Button or type(skin.HandleButton)~="function" then return end
        if not pcall(skin.HandleButton,skin,frame.Button) then return end
    elseif record.kind=="slider" then
        local slider=frame.SliderWithSteppers
        -- Match ElvUI's SettingsList handler: it skins the complete step
        -- slider, not the inner Slider as a standalone legacy control.
        if not slider or type(skin.HandleStepSlider)~="function" then return end
        if not pcall(skin.HandleStepSlider,skin,slider) then return end
    else
        local checkbox=frame.Checkbox or frame.CheckBox
        if not checkbox or type(checkbox.CreateBackdrop)~="function" then return end
        -- Mirrors ElvUI's special Settings-list HandleCheckbox helper, which
        -- differs from its general-purpose HandleCheckBox() implementation.
        local good=pcall(function()
            if not checkbox.backdrop then checkbox:CreateBackdrop() end
            if checkbox.backdrop and checkbox.backdrop.SetInside then
                checkbox.backdrop:SetInside(nil,4,4)
            end
            for _,region in next,{checkbox:GetRegions()} do
                if region:IsObjectType("Texture") then
                    if region.GetAtlas and region:GetAtlas()=="checkmark-minimal" then
                        if E.private and E.private.skins and E.private.skins.checkBoxSkin then
                            if E.Media and E.Media.Textures and E.Media.Textures.Melli then
                                region:SetTexture(E.Media.Textures.Melli)
                            end
                            local checked=checkbox:GetCheckedTexture()
                            if checked then
                                checked:SetVertexColor(1,.82,0,.8)
                                if checkbox.backdrop and checked.SetInside then
                                    checked:SetInside(checkbox.backdrop)
                                end
                            end
                        end
                    else
                        region:SetTexture(nil)
                    end
                end
            end
        end)
        if not good then return end
    end
    frame.llRosterElvUISkinned=true
end

-- Reuse the same skinning path for other existing Settings canvas widgets.
function LL:SkinSettingsCanvasControl(frame,kind)
    ApplyElvUISettingsSkin(frame,{kind=kind})
end

local function AttachNative(frame,record)
    if not panel or not record or not frame then return end
    local x=LEFT+(record.index-1)*STEP
    frame:ClearAllPoints()
    if record.kind=="drop" then
        frame:SetPoint("TOPLEFT",panel,"TOPLEFT",x,-115)
        frame:SetSize(DROP_WIDTH,26)
        if frame.Text then frame.Text:Hide() end
        if frame.Tooltip then frame.Tooltip:Hide() end
        local native=frame.Control
        if native and native.Dropdown then
            -- Same native HideSteppers + width changes as the successful
            -- Widget Gallery v4.2 Settings.CreateDropdown example #3.
            frame.forceSteppersHidden=true
            if type(native.HideSteppers)=="function" then native:HideSteppers() end
            native:ClearAllPoints()
            native:SetPoint("TOPLEFT",frame,"TOPLEFT",0,0)
            native:SetWidth(DROP_WIDTH)
            native.Dropdown:SetWidth(DROP_WIDTH)
        end
    else
        local idx=record.rowIndex
        local contents=panel.llCharacterContents or panel
        frame:SetPoint("TOPLEFT",contents,"TOPLEFT",x-12+math.floor((DROP_WIDTH-23)/2),-12-(idx-1)*50)
        frame:SetSize(23,23)
        if frame.Text then frame.Text:Hide() end
        if frame.Tooltip then frame.Tooltip:Hide() end
        local checkbox=frame.Checkbox or frame.CheckBox
        if checkbox then
            checkbox:ClearAllPoints()
            checkbox:SetPoint("CENTER",frame,"CENTER",0,0)
            checkbox:SetSize(23,23)
        end
    end
    liveFrames[frame]=record
    ApplyElvUISettingsSkin(frame,record)
    if record.kind=="drop" then
        -- The Blizzard WowStyle2Dropdown button used by Settings.CreateDropdown
        -- reserves 13 UI units on BOTH sides of its text (MenuTemplates.xml).
        -- Our 58-unit column therefore had only 32 units to show "Manual".
        -- Narrow the *text insets*, not the button or column: keep all eight
        -- native Settings dropdowns aligned inside the Settings canvas.
        -- Run after optional ElvUI skinning so its button handler cannot
        -- restore the default insets. Do not change the font or menu logic.
        local dropdown=frame.Control and frame.Control.Dropdown
        local caption=dropdown and dropdown.Text
        if caption then
            caption:ClearAllPoints()
            caption:SetPoint("LEFT",dropdown,"LEFT",3,0)
            caption:SetPoint("RIGHT",dropdown,"RIGHT",-3,0)
        end
    end
end
function LootLiquidator_InitNativeRosterGrid(p)
    panel=p
    panel:SetSize(PANEL_WIDTH,520)
    Text(p,"GameFontNormalLarge",12,-10,PANEL_WIDTH-20,"Professions & Alts")
    Text(p,"GameFontHighlightSmall",12,-36,PANEL_WIDTH-20,
        "Auto: scanned data. Manual: select characters; recipes and binding still apply.")
    Text(p,"GameFontNormal",12,-87,LEFT-12,"Character / class")
    for idx,m in ipairs(METHODS) do
        local heading=Text(p,"GameFontNormalSmall",LEFT+(idx-1)*STEP,-80,STEP-3,m.title)
        heading:SetJustifyH("CENTER")
    end
    local rule=p:CreateTexture(nil,"ARTWORK")
    rule:SetColorTexture(.38,.34,.23,.8)
    rule:SetPoint("TOPLEFT",p,"TOPLEFT",12,-155)
    rule:SetSize(PANEL_WIDTH-24,1)
    local scroller=CreateFrame("ScrollFrame",nil,p,"ScrollFrameTemplate")
    scroller:SetPoint("TOPLEFT",p,"TOPLEFT",12,-168)
    scroller:SetSize(PANEL_WIDTH-24,299)
    local contents=CreateFrame("Frame",nil,scroller)
    contents:SetSize(PANEL_WIDTH-42,math.max(300,#rosterKeys*50))
    scroller:SetScrollChild(contents)
    p.llCharacterContents=contents
    p.llScroller=scroller
    p.nameLabels={}
    p.classLabels={}
    function p:RefreshRoster()
        for idx,key in ipairs(rosterKeys) do
            local entry=LL.db and LL.db.characters and LL.db.characters[key]
            if entry then
                if not self.nameLabels[idx] then
                    self.nameLabels[idx]=Text(contents,"GameFontNormal",2,-7-(idx-1)*50,LEFT-22,"")
                    self.classLabels[idx]=Text(contents,"GameFontHighlightSmall",2,-29-(idx-1)*50,LEFT-22,"")
                end
                self.nameLabels[idx]:SetText(LL.AltDisplayName and LL:AltDisplayName(key) or key)
                local class=LL.AltClassLabel and LL:AltClassLabel(entry.class) or (entry.class or "Unknown")
                if LL.CharacterKey and key==LL:CharacterKey() then class=class.." |cff7fdfff(current)|r" end
                self.classLabels[idx]:SetText(class)
            end
        end
    end
    p:HookScript("OnShow",function()
        p:RefreshRoster()
        UpdateNativeStates()
        for nativeFrame,record in pairs(liveFrames) do
            ApplyElvUISettingsSkin(nativeFrame,record)
        end
    end)
    Text(p,"GameFontHighlightSmall",12,-495,PANEL_WIDTH-24,
        "Checkboxes are editable only in Manual mode. No skill or recipe is invented.")
    p:RefreshRoster()
end

-- The roster remains a Settings *canvas* so all 8 columns are visible together.
-- Blizzard Settings.Create* returns an initializer, not a widget. A dedicated,
-- non-navigation vertical category supplies REAL native initializers, which we
-- instantiate as Settings control frames inside the canvas. This avoids the
-- Settings ScrollBox virtualization that occurs if each cell were a separate
-- off-screen vertical-layout row.
local function CreateNativeControl(holder,template,initializer,record)
    local ok,frameOrError=pcall(function()
        local frame=CreateFrame("Frame",nil,holder,template)
        if type(frame.SetElementData)=="function" then frame:SetElementData(initializer) end
        -- Settings list controls are normally given element data by the
        -- ScrollBox. A canvas has no list owner, so supply the initializer
        -- through the same getter when the native getter remains empty.
        local hasData=false
        if type(frame.GetElementData)=="function" then
            local okData,data=pcall(frame.GetElementData,frame)
            hasData=okData and data~=nil
        end
        if not hasData then frame.GetElementData=function() return initializer end end
        -- These mixins drive the same Settings setting bindings, tooltips,
        -- callbacks and ElvUI-discoverable Settings frame family.
        assert(type(frame.Init)=="function", template.." missing Settings mixin")
        frame:Init(initializer)
        return frame
    end)
    if not ok then
        if not LL.rosterNativeError then
            LL.rosterNativeError=tostring(frameOrError)
            if print then print("|cffff6a32Loot Liquidator:|r Native Settings roster control initialization failed: "..LL.rosterNativeError) end
        end
        return nil
    end
    local frame=frameOrError
    AttachNative(frame,record)
    return frame
end
local definitions={}
local created=false
local function CreateNativeWidgets()
    if created or not panel then return end
    created=true
    for _,d in ipairs(definitions) do
        local template=d.record.kind=="drop" and "SettingsDropdownControlTemplate"
            or "SettingsCheckboxControlTemplate"
        local parent=d.record.kind=="check" and (panel.llCharacterContents or panel) or panel
        d.frame=CreateNativeControl(parent,template,d.initializer,d.record)
    end
    UpdateNativeStates()
end
function LL:RegisterNativeRosterTable(root)
    if settingsReady then return self.altRosterPage end
    if not (Settings and Settings.RegisterCanvasLayoutSubcategory and
        Settings.CreateDropdown and Settings.CreateCheckbox and Settings.RegisterProxySetting) then return nil end
    settingsReady=true
    local canvas=CreateFrame("Frame")
    LootLiquidator_InitNativeRosterGrid(canvas)
    local category=Settings.RegisterCanvasLayoutSubcategory(root,canvas,"Professions & Alts")
    Settings.RegisterAddOnCategory(category)
    self.altRosterPage=category
    -- This category is never added to the visible AddOns navigation tree.
    -- It only hosts Settings.Create* initializers for our compact canvas.
    local native=Settings.RegisterVerticalLayoutCategory("LootLiquidator Internal Native Controls")
    local keys={}
    for key,entry in pairs(self.db.characters or {}) do
        if type(entry)=="table" then keys[#keys+1]=key end
    end
    table.sort(keys)
    rosterKeys=keys
    if canvas.llCharacterContents then
        canvas.llCharacterContents:SetHeight(math.max(300,#keys*50))
    end
    for i,m in ipairs(METHODS) do
        local method=m
        local setting=Settings.RegisterProxySetting(native,"LootLiquidatorRosterMode_"..method.key,
            Settings.VarType.Number,method.title,2,
            function() return LL:ProcessingMethodMode(method.key) end,
            function(value)
                if LL:SetProcessingMethodMode(method.key,value) then
                    UpdateNativeStates()
                    if LL.UpdateAllAppearance then LL:UpdateAllAppearance() end
                end
            end)
        local initializer=Settings.CreateDropdown(native,setting,MakeModeOptions,
            "Auto, On, Off or Manual: "..method.title)
        definitions[#definitions+1]={initializer=initializer,record={kind="drop",index=i,method=method.key}}
    end
    for rowIndex,key in ipairs(keys) do
        local characterKey=key
        for i,m in ipairs(METHODS) do
            local method=m
            local setting=Settings.RegisterProxySetting(native,
                "LootLiquidatorRosterCheck_"..rowIndex.."_"..method.key,
                Settings.VarType.Boolean,characterKey.." "..method.title,false,
                function() return CheckboxValue(characterKey,method) end,
                function(value)
                    if LL:ProcessingMethodMode(method.key)==4 then
                        LL:SetAltMethodEnabled(characterKey,method.key,value==true)
                        UpdateNativeStates()
                        if LL.UpdateAllAppearance then LL:UpdateAllAppearance() end
                    end
                end)
            local initializer=Settings.CreateCheckbox(native,setting,
                "Manual participation for "..characterKey.." ("..method.title..")")
            if initializer.AddModifyPredicate then
                initializer:AddModifyPredicate(function()
                    return LL:ProcessingMethodMode(method.key)==4
                end)
            end
            definitions[#definitions+1]={initializer=initializer,record={kind="check",index=i,
                rowIndex=rowIndex,character=characterKey,method=method.key}}
        end
    end
    canvas:HookScript("OnShow",CreateNativeWidgets)
    return category
end
