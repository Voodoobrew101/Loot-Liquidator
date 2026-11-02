-- Canvas controls are initialized by Blizzard Settings factories. Decorative
-- containers and labels are not replacement interactive widgets.
do
local _, LL = ...
local serial=0
function LL:IsLootLiquidatorSettingsCategory(category)
    local seen={}
    while category and not seen[category] do
        if category==self.settingsCategory then return true end
        seen[category]=true
        category=category.GetParentCategory and category:GetParentCategory()
    end
    return false
end
function LL:ProtectSettingsDefaults()
    local panel=SettingsPanel
    local list=panel and panel.GetSettingsList and panel:GetSettingsList()
    local button=list and list.Header and list.Header.DefaultsButton
    if not button or button.llDefaultsGuard then return end
    button.llDefaultsGuard=true
    local function OwnPage()
        return LL:IsLootLiquidatorSettingsCategory(panel:GetCurrentCategory())
    end
    local original=button:GetScript("OnClick")
    -- The shared Blizzard button opens GAME_SETTINGS_APPLY_DEFAULTS, including
    -- its 'all settings' action. Never enter that dialog from our categories.
    button:SetScript("OnClick",function(...)
        if OwnPage() then return end
        if original then return original(...) end
    end)
    local function Refresh()
        if OwnPage() then
            button:Disable();button:Hide()
            if StaticPopup_Hide then StaticPopup_Hide("GAME_SETTINGS_APPLY_DEFAULTS") end
        else
            button:Enable()
            if not panel.SearchBox or not panel.SearchBox:HasText() then button:Show() end
        end
    end
    button:HookScript("OnShow",function() if OwnPage() then button:Hide() end end)
    if EventRegistry then EventRegistry:RegisterCallback("Settings.CategoryChanged",Refresh,LL) end
    Refresh()
end

-- B5b: moved from the removed AltRosterUI.lua (alts table). Optional ElvUI
-- skinning for our canvas Settings controls.
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

local function Proxy(kind,default)
    if not LL.canvasSettingsCategory then
        -- Initializer host only; it is never registered in AddOns navigation.
        LL.canvasSettingsCategory=Settings.RegisterVerticalLayoutCategory("LootLiquidator Canvas Controls")
    end
    serial=serial+1
    local value=default
    return Settings.RegisterProxySetting(LL.canvasSettingsCategory,"LootLiquidatorCanvas_"..serial,
        kind,"",default,function() return value end,function(v) value=v end)
end
function LL:CreateSettingsControl(parent,template,initializer,kind)
    local frame=CreateFrame("Frame",nil,parent,template)
    if kind=="drop" then frame.forceSteppersHidden=true end
    if frame.SetElementData then frame:SetElementData(initializer) end
    frame.GetElementData=function() return initializer end
    frame:Init(initializer)
    if frame.Text then frame.Text:Hide() end
    if frame.Tooltip then frame.Tooltip:Hide() end
    if self.SkinSettingsCanvasControl then self:SkinSettingsCanvasControl(frame,kind) end
    return frame
end
-- Vertical Settings rows are pooled by Blizzard. Hide arrows after each native
-- menu rebuild only while the row is bound to one of our settings; other
-- categories reusing that row retain their normal dropdown behavior.
function LL:WithoutDropdownSteppers(initializer)
    local initFrame=initializer.InitFrame
    initializer.InitFrame=function(self,frame,...)
        if not frame.llDropdownSteppersHooked then
            frame.llDropdownSteppersHooked=true
            hooksecurefunc(frame,"InitDropdown",function(control)
                local setting=control:GetSetting()
                local variable=setting and setting:GetVariable()
                if type(variable)=="string" and variable:match('^LootLiquidator_') then
                    control.Control:HideSteppers()
                end
            end)
        end
        return initFrame(self,frame,...)
    end
    return initializer
end
function LL:CreateSettingsButton(parent)
    local initializer=CreateSettingsButtonInitializer("","",function() end,"",false)
    local row=self:CreateSettingsControl(parent,"SettingButtonControlTemplate",initializer,"button")
    row:SetSize(1,1);row:SetPoint("TOPLEFT",parent,"TOPLEFT",0,0)
    local button=row.Button
    button:ClearAllPoints()
    function button:SetSelected(selected)
        self:SetButtonState(selected and "PUSHED" or "NORMAL",selected==true)
    end
    return button
end
function LL:CreateSettingsCheckbox(parent)
    local setting=Proxy("boolean",false)
    local holder=self:CreateSettingsControl(parent,"SettingsCheckboxControlTemplate",
        Settings.CreateCheckboxInitializer(setting,nil,""),"check")
    local native=holder.Checkbox or holder.CheckBox
    holder:SetSize(22,22)
    native:ClearAllPoints();native:SetPoint("CENTER",holder,"CENTER",0,0)
    native:SetSize(22,22)
    function holder:SetChecked(v) setting:SetValue(v==true);native:SetChecked(v==true) end
    function holder:GetChecked() return native:GetChecked() end
    function holder:Enable() native:Enable() end
    function holder:Disable() native:Disable() end
    function holder:SetEnabled(v) native:SetEnabled(v) end
    local baseSetScript,baseHookScript=holder.SetScript,holder.HookScript
    function holder:SetScript(event,callback)
        if event=="OnClick" or event=="OnEnter" or event=="OnLeave" then
            native:SetScript(event,callback and function(_, ...)
                if event=="OnClick" then setting:SetValue(native:GetChecked()==true) end
                return callback(self,...)
            end or nil)
        else baseSetScript(self,event,callback) end
    end
    function holder:HookScript(event,callback)
        if event=="OnClick" or event=="OnEnter" or event=="OnLeave" then
            native:HookScript(event,function(_,...) return callback(self,...) end)
        else baseHookScript(self,event,callback) end
    end
    holder.llNativeCheckbox=native
    return holder
end
function LL:CreateSettingsEditBox(parent)
    -- Retail Settings has no text-entry factory. Keep text entry only for item
    -- links and copy/export utilities, using Blizzard's input template.
    local edit=CreateFrame("EditBox",nil,parent,"InputBoxTemplate")
    edit:SetSize(205,24);edit:SetAutoFocus(false)
    edit:SetScript("OnEscapePressed",function(self)self:ClearFocus()end)
    local E=type(_G.ElvUI)=="table" and _G.ElvUI[1]
    local skin=E and E.GetModule and E:GetModule("Skins",true)
    if skin and skin.HandleEditBox then skin:HandleEditBox(edit) end
    return edit
end
function LL:CreateSettingsCanvasSlider(parent,minValue,maxValue,step,initial,onChange)
    local setting=Proxy("number",initial)
    local options=Settings.CreateSliderOptions(minValue,maxValue,step)
    if options.SetLabelFormatter and MinimalSliderWithSteppersMixin then
        options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)
    end
    local control=self:CreateSettingsControl(parent,"SettingsSliderControlTemplate",
        Settings.CreateSlider(self.canvasSettingsCategory,setting,options,""),"slider")
    control:SetSize(320,30)
    local native=control.SliderWithSteppers
    -- Preserve the standard Settings slider dimensions, artwork, steppers and
    -- value label. Only position the whole native widget within this canvas.
    native:ClearAllPoints();native:SetPoint("LEFT",control,"LEFT",16,0)
    local reported=initial
    setting:SetValueChangedCallback(function(_,value)
        if value==reported then return end
        reported=value
        if onChange then onChange(value) end
    end)
    -- Keep SettingsSliderControlMixin:SetValue intact. Blizzard calls it when
    -- a setting changes; writing the setting from that method loops forever,
    -- because SettingMixin also notifies for unchanged values.
    function control:SetPreferenceValue(value)
        value=minValue+math.floor((value-minValue)/step+.5)*step
        value=math.max(minValue,math.min(maxValue,value))
        if setting:GetValue()~=value then setting:SetValue(value) end
    end
    function control:GetPreferenceValue() return setting:GetValue() end
    control.slider=native.Slider
    return control
end
function LL:CreateSettingsDropdown(parent,options,getValue,setValue)
    local setting=Proxy("number",getValue())
    local initializer=Settings.CreateDropdownInitializer(setting,options,"")
    local row=self:CreateSettingsControl(parent,"SettingsDropdownControlTemplate",initializer,"drop")
    row:SetSize(300,26)
    local control=row.Control
    if control.HideSteppers then control:HideSteppers() end
    control:ClearAllPoints();control:SetPoint("TOPLEFT",row,"TOPLEFT",0,0)
    control:SetWidth(290);control.Dropdown:SetWidth(290)
    local refreshing=false
    setting:SetValueChangedCallback(function(_,v) if not refreshing then setValue(v) end end)
    function row:Refresh()
        refreshing=true;setting:SetValue(getValue());refreshing=false
        if control.Dropdown.GenerateMenu then control.Dropdown:GenerateMenu() end
    end
    return row
end
end
do -- TSMRecommendedUI
-- Optional recommended TSM setup. TSM owns profile/group/operation imports.
-- A real TSM group+operations export can be inserted in this bundle later.
-- Never generate or modify another addon's SavedVariables.
local _, LL = ...

-- User-supplied TSM export, provided verbatim. We never change TSM settings;
-- this is only a selectable text field for Ctrl+C, then paste into TSM.
LL.RecommendedTSMExport = [=[fE5YUTrYvyyqnlYUaBfmoiRgcniawckc19QlhGKiAzheKyehjNjZQXQjztYgMIDJMnLLZs(eeOhb9imlYdGFe8kUwpcZISoNQQ(sDk7Xwa2GF95u)Nl1P6ldU7vx8Ix)SV)L)9ZF1xD(Pvxvu9Fg87)q(tOeLqBEYtY5Y98OMqaulArQgHcvps5gPDTsQhvkUUxkafbsbysJu3Brn3fxMsT37TSjX07mJsyuafKoKJqjdHktiszceYJqncXsbPzyAWiiNzuKumgd5mtHSIJlJlXyKZji016cqCGeyLf4KuGLsX(ySxkfhBLJTI7gkngXbsJZznoqACG0OUbx4gcPTOBtH3UwUlN5mhk0cMDTkshQ6rjJ4gZuSomjafjHfO0qvumgzvGrnc1yRjyRU5zgTbzmsOvgZeIcJBAx2HO0qsyiKHTg6SwNeE(1yiuwF5dOlneDw9hR6q)iApMGrthYiKMwhDVTwKkejEdgJ0USeI9CoJjKUgHurBzJlJiT2veRosPF5w2vTjDM5ULl6yD0YtAwEdtjnH7dbSw3z2QU0O7mZrrZDapizOsV5wuHq)MA3ID3oOVsvmbo1CZT2y3WCAeh1z4rR3XH21H1Iw56SAUZmNlKE352BWcE7hiLEY4gt6iJSNGXTg6EhjKAhYBz3Prl792fMU16MkAxlvN4KYW6yxsK0XgsJD3Q5U76R9fim442B7ImWgmtjrmnITPgvjrCSDMQlEUDB4Mgio0UD7hEufId1t7SZI4E)JQhphOFu9XIQhglI5rCu(WI0JtW1hpQ)XJIhpkE8O4XJ6pUbYqoQEDpvlO)iI2peQi7r9BHoY)y9JQxj)tXWRC0YrXxkJ4O(PI9P4M6vjK(9Ng9TSiILrSkI1rCcM5r6ZJ8xWXSmkEksetJydM1r(BIIVbxF(BMgWmSEkoUEafqSHI0xXOO4N4FjjM20Y((pW2NbPHh94FAKMcppQ9xCD7Ve9)YRGgEFoxg2mXPz(NlhW(tij9m7tXb(ZJyreRIyDehfFbnILrScNpIi9JRpzu(lJYp)etG9i98plO3Ukk)DVsyGDnnIJIVoQFPJINosVesODrI)eJ2pHOLSM7OAAzVDzddp7mCIfy0eiWsweJT7FNVqUDI0nzP4npCgElmt4zReymufXAeRmKiMhXce7)oTqoYo6SKL5rSkI1rC7zv4jZC4TiA(sGgkjKA)oVgIIiwizcxN)Wxhjzises6M3QOH4iBHAYq5jtrqehrHrGJ0KRX2KisfKl(TXEBjikS(ebVXfq(TJwIfQIGJ8e1pfjO1zcZmjn0tjpm6sblyDksOnLkuffkRvMG(Pw7gcHxMUk)jcsIYjNaE1sBsbVXVNCt(TK2fyQ3tzZNQYAi)N9W9KW)1hn2essajDt3neCk20rGfVMQgY)98EcQ6(wILybKuATXjEsj0b2uYMMqLL0WZvC)ir6QdL2FFBEILsGVXK0PeqM(rPew4WAcC)DAi5)Q3M1XKeeH809Ml92qAkLikjKuivuAeH80ni3fHesOTegIq5sckxseHKbvrMgvE0Ex(O9MD3PBMuNxSkF18Fz5V6PlZsRsxnjB4VByJHTfxNvvLpn7YTpTkDwT1XTF7zzZs3SSE3G)0LBVyrrzP9Y7gmYEHXxSkVmRQfV97YwnTOYfG9ddG)6wx(X)vAv2IInRduz2Ub)HhTBWF8)TnDmKcVi9MTxLEZlRYNKD348PVmRAs2Q6V69tSQT88SYI11xw(1H4RwuLTErXYPhqNFV3W)C1uyHBQVC70nvP267xu(W85RkQY(BfV9SMRn49VjlR8FSjDvDE972NChe5NDtzoi3(KDd(lLFlB4rdNyRLXPRZGF)yYjgYWFy4QnxL5D8WTxLVYLU36CCDDr5pcX5Q0LURw(BPNi)YQuzlKNMww(n5ZMx)yN3GWhpSt0JhspEi5W7kTQEE26S6rRkwLTDttPEazYUbNcTYrpV8btSBHU4)IS6fft3ZwAWIQlM8MdyKBD5CXS86rucz(Da2AKcf(tDQanGTthFvA1BYQ)PkV5(E19nx5IInWo06NpkDz96fBt9ttRxmAC6Q3S485BYxoDr5dH9N3EAZgSlVUC3GZSH5r3noBzXBDx7MbFpKMp(A3aZ6SLlpEORBC2OZZMdQ(cxUC61ZpEiC8f(d(b5KKFEVOKoV0)8E1lL6leqNtYVq8Coj(8HZ5d)ZeTwFyF(G58XoxCcrEyZFWa2h59H7g8mOB)8)7TzRshVmB0M3T4o)pVa6Zxw5oi4od0UtBHDdMm7G0fl2ny6Ik7g8RDWm4FZxm6Q08LlkFGDJ60z1zv(Jot3N8b7LGbJLJlGPZf3F96ZarRkE33LUCtw5VzwomrBpeypym1BcQNjh(HRx7tzNJBBpfu(q71VbjYx7fjCwbeO8bopdez3GxTBWF2oPD9pzlYrPZ7hIlFG)sRcgSF)vWuAGl)6MgYF9J8C3GXwjApiuNc)x()oBFYTR7)T62Ut(LV2NZthx52DwNcwGDYw2Ful8klYbPHtgPlpU9Ki8JGRsjh13bGn5Rl)g6jSJ6c5rUB18db3Ob6hLhypLXorgS2JPNWpQDRqo)W))]=]

function LL:RecommendedTSMExportAvailable()
    return type(self.RecommendedTSMExport)=="string"
        and self.RecommendedTSMExport:match("%S")~=nil
end

function LL:RecommendedTSMSetupText()
    if self:RecommendedTSMExportAvailable() then
        return self.RecommendedTSMExport
    end
    return table.concat({
        "Voodoo's Recommended TSM Setup - export not yet bundled", "",
        "Loot Liquidator does not include Voodoo's actual TSM group/operation export yet.",
        "This text is INFORMATION ONLY; it is NOT a TSM import string.", "",
        "When the actual TSM export is provided, the bundled import text will",
        "appear here. Copy that text into TSM's own import interface.", "",
        "Strategy overview:",
        "- Auction valuable items before dumping them at vendor value.",
        "- Aim for quick turnover, with 48-hour posting and a decreasing price",
        "  target after unsuccessful listings, where supported by TSM.",
        "- Avoid posting when the operation's minimum is not met.",
        "- Keep reagents on a separate lower-margin auctioning operation.", "",
        "Use TSM to configure or import operations; Loot Liquidator only",
        "reads the active settings and makes recommendations.",
    }, "\n")
end

function LL:CreateTSMRecommendedPanel()
    local panel=CreateFrame("Frame")
    local function label(text,template,y,width)
        local fs=panel:CreateFontString(nil,"ARTWORK",template or "GameFontHighlight")
        fs:SetPoint("TOPLEFT",panel,"TOPLEFT",18,y)
        fs:SetWidth(width or 650)
        fs:SetJustifyH("LEFT")
        fs:SetText(text)
        return fs
    end
    label("Voodoo's Recommended TSM Setup", "GameFontNormalLarge",-20)
    label("An optional TradeSkillMaster import preset for Loot Liquidator users.",
        "GameFontHighlight",-59)
    local status=label("", "GameFontHighlightSmall",-94,690)
    local button=self:CreateSettingsButton(panel)
    button:SetSize(290,29)
    button:SetPoint("TOPLEFT",panel,"TOPLEFT",18,-129)
    button:SetText("View recommended setup")
    button:SetScript("OnClick",function()
        if LL.ShowCopy then
            LL:ShowCopy("Voodoo's Recommended TSM Setup",LL:RecommendedTSMSetupText())
        end
    end)
    label("How to use", "GameFontNormal",-182)
    label("1. Open the text above. Once the TSM export is bundled, select and copy it.\n"..
        "2. In TSM, use its own group/operation import feature.\n"..
        "3. Your existing TSM settings remain unchanged unless you explicitly import there.\n"..
        "4. Loot Liquidator automatically reads your active TSM pricing and operations.",
        "GameFontHighlightSmall",-208,720)
    label("This addon never writes another addon's profile or SavedVariables.",
        "GameFontDisableSmall",-315)
    panel:HookScript("OnShow",function()
        status:SetText(LL:RecommendedTSMExportAvailable()
            and "|cff44dd88Ready: import text is bundled. Use the button to copy it.|r"
            or "|cffffbb55Pending: Voodoo's actual TSM export has not been provided yet.|r")
    end)
    return panel
end

end
do -- ItemIgnoreUI
-- Optional per-item, per-action protection. No automatic selling/processing.
local _, LL = ...
local function SmallText(parent,text,x,y,font)
    local fs=parent:CreateFontString(nil,"ARTWORK",font or "GameFontHighlightSmall")
    fs:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
    fs:SetText(text)
    return fs
end
local function Help(frame,text)
    if not frame or not frame.HookScript then return end
    frame:HookScript("OnEnter",function(self)
        if not GameTooltip then return end
        GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
        GameTooltip:SetText(text,1,1,1,1,true) -- r, g, b, alpha, wrap
        GameTooltip:Show()
    end)
    frame:HookScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
end
local function ItemID(value)
    if type(value)=="number" then return value end
    if type(value)~="string" then return nil end
    return tonumber(value:match("item:(%d+)")) or tonumber(value:match("^%s*(%d+)%s*$"))
end
function LL:CreateItemIgnorePanel()
    local panel=CreateFrame("Frame")
    panel:SetSize(640,580)
    SmallText(panel,"Item Ignore List",16,-15,"GameFontNormalLarge")
    SmallText(panel,"Account-wide. Checked actions are excluded from Loot Liquidator recommendations.",16,-45)
    SmallText(panel,"Processing covers Milling, Prospecting, Smelting, Recycling, and other conversions.",16,-63)
    local drop=LL:CreateSettingsButton(panel)
    drop:SetSize(440,35);drop:SetPoint("TOPLEFT",16,-89)
    drop:SetText("Drop an item from your bags here (ignore all by default)")
    Help(drop,"Drag an item from your inventory and release it here. This only adds its item ID to the list; it does not consume the item.")
    local entry=LL:CreateSettingsEditBox(panel)
    entry:SetSize(205,24);entry:SetPoint("TOPLEFT",24,-140)
    entry:SetAutoFocus(false)
    entry:SetMaxLetters(255)
    local add=LL:CreateSettingsButton(panel)
    add:SetPoint("LEFT",entry,"RIGHT",10,0);add:SetSize(110,24)
    add:SetText("Add item / ID")
    Help(entry,"Paste a full item link or enter a numeric item ID, then click Add.")
    local status=SmallText(panel,"",16,-175)
    local scroll=CreateFrame("ScrollFrame",nil,panel,"ScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT",panel,"TOPLEFT",16,-212)
    scroll:SetSize(552,325)
    local content=CreateFrame("Frame",nil,scroll)
    content:SetSize(528,325)
    scroll:SetScrollChild(content)
    local labels={{"A",293,"Ignore auctioning"},{"D",335,"Ignore disenchanting"},
        {"V",377,"Ignore vendoring"},{"P",419,"Ignore other processing"},
        {"T",461,"Ignore transmog priority"}}
    SmallText(panel,"Item",24,-194)
    for _,a in ipairs(labels) do
        local lab=SmallText(panel,a[1],a[2],-194)
        Help(lab,a[3])
    end
    local existingRows={}
    local function FreshName(id,e)
        local fn=C_Item and C_Item.GetItemInfo or GetItemInfo
        local name=nil
        if type(fn)=="function" then
            local ok,got=pcall(fn,id)
            if ok then name=got end
        end
        return (type(name)=="string" and name) or e.name or ("Item #"..id)
    end
    local function Render()
        for _,row in ipairs(existingRows) do row:Hide();row:SetParent(nil) end
        existingRows={}
        local list={}
        for key,r in pairs(LL.db and LL.db.ignoredItems or {}) do
            local id=tonumber(key)
            if id and type(r)=="table" then list[#list+1]={id=id,entry=r} end
        end
        table.sort(list,function(a,b)return a.id<b.id end)
        for i,data in ipairs(list) do
            local row=CreateFrame("Frame",nil,content)
            row:SetSize(520,29);row:SetPoint("TOPLEFT",content,"TOPLEFT",0,-(i-1)*30)
            existingRows[#existingRows+1]=row
            local name=SmallText(row,FreshName(data.id,data.entry),5,-5)
            name:SetWidth(246)
            name:SetJustifyH("LEFT")
            if name.SetWordWrap then name:SetWordWrap(false) end
            Help(name,"Item ID "..data.id..". These restrictions apply to all copies of this item on your account.")
            for _,col in ipairs(labels) do
                local key=col[1]
                local cb=LL:CreateSettingsCheckbox(row)
                cb:SetSize(23,23);cb:SetPoint("TOPLEFT",row,"TOPLEFT",col[2]-18,-2)
                cb:SetChecked(data.entry[key]==true)
                Help(cb,col[3].." for this item; unchecked actions remain eligible.")
                cb:SetScript("OnClick",function(self)
                    local new={A=data.entry.A,D=data.entry.D,V=data.entry.V,P=data.entry.P,T=data.entry.T}
                    new[key]=self:GetChecked() and true or false
                    LL:SetIgnoreEntry(data.id,new,data.entry.name)
                end)
            end
            local remove=LL:CreateSettingsButton(row)
            remove:SetSize(27,23);remove:SetPoint("TOPLEFT",row,"TOPLEFT",490,-2)
            remove:SetText("X")
            Help(remove,"Remove this item from the ignore list (all recommendations enabled).")
            remove:SetScript("OnClick",function()
                LL:SetIgnoreEntry(data.id,nil)
                Render()
            end)
        end
        content:SetHeight(math.max(325,#existingRows*30))
        status:SetText(""..#list.." ignored item IDs. Click X to remove; changes save automatically.")
    end
    local function AddItem(id,link)
        id=ItemID(id or link)
        if not id or id<1 then
            status:SetText("Invalid item link or ID")
            return false
        end
        local name=type(link)=="string" and link:match("%[(.-)%]")
        LL:SetIgnoreEntry(id,{A=true,D=true,V=true,P=true,T=true},name)
        entry:SetText("")
        Render()
        return true
    end
    local function DropItem()
        if type(GetCursorInfo)~="function" then return end
        local kind,id,link=GetCursorInfo()
        if kind=="item" and AddItem(id,link) then
            if type(ClearCursor)=="function" then ClearCursor() end
        end
    end
    drop:RegisterForDrag("LeftButton")
    drop:SetScript("OnReceiveDrag",DropItem)
    drop:SetScript("OnMouseUp",DropItem)
    add:SetScript("OnClick",function() AddItem(entry:GetText()) end)
    entry:SetScript("OnEnterPressed",function(self)
        AddItem(self:GetText());self:ClearFocus()
    end)
    panel:HookScript("OnShow",Render)
    panel.RefreshIgnoreList=Render
    return panel
end

end
