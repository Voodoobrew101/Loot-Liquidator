-- Shared canvas-settings button style for the native Options > AddOns panels.
-- UIPanelButtonTemplate renders classic red button art; these canvas buttons
-- use neutral dark surfaces and gold accents to sit alongside Settings widgets.
-- This is purely UI presentation; it does not affect badge appearance settings.
local _, LL = ...

function LL:CreateSettingsButton(parent)
    local btn = CreateFrame("Button", nil, parent)
    local label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("CENTER", btn, "CENTER", 0, 0)
    label:SetWidth(470) -- constrained to the actual button width on size change
    label:SetJustifyH("CENTER")
    if btn.SetFontString then btn:SetFontString(label) end
    btn.llLabel = label

    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(btn)
    bg:SetColorTexture(.055, .055, .058, .94)

    local lines={}
    -- A four-sided one-pixel border, using simple textures rather than the
    -- red UIPanelButtonTemplate art. Selected buttons get stronger gold edges.
    local top=btn:CreateTexture(nil,"BORDER")
    top:SetColorTexture(.29,.265,.19,.85)
    top:SetPoint("TOPLEFT",btn,"TOPLEFT",0,0)
    top:SetPoint("TOPRIGHT",btn,"TOPRIGHT",0,0)
    top:SetHeight(1)
    lines[#lines+1]=top
    local bottom=btn:CreateTexture(nil,"BORDER")
    bottom:SetColorTexture(.29,.265,.19,.85)
    bottom:SetPoint("BOTTOMLEFT",btn,"BOTTOMLEFT",0,0)
    bottom:SetPoint("BOTTOMRIGHT",btn,"BOTTOMRIGHT",0,0)
    bottom:SetHeight(1); lines[#lines+1]=bottom
    local left=btn:CreateTexture(nil,"BORDER")
    left:SetColorTexture(.29,.265,.19,.85)
    left:SetPoint("TOPLEFT",btn,"TOPLEFT",0,0)
    left:SetPoint("BOTTOMLEFT",btn,"BOTTOMLEFT",0,0)
    left:SetWidth(1); lines[#lines+1]=left
    local right=btn:CreateTexture(nil,"BORDER")
    right:SetColorTexture(.29,.265,.19,.85)
    right:SetPoint("TOPRIGHT",btn,"TOPRIGHT",0,0)
    right:SetPoint("BOTTOMRIGHT",btn,"BOTTOMRIGHT",0,0)
    right:SetWidth(1); lines[#lines+1]=right

    local highlight=btn:CreateTexture(nil,"HIGHLIGHT")
    highlight:SetAllPoints(btn)
    highlight:SetColorTexture(.34,.26,.07,.22)
    btn:SetHighlightTexture(highlight)
    btn:HookScript("OnSizeChanged",function(self,w)
        label:SetWidth(math.max(5,w-12))
    end)
    function btn:SetSelected(selected)
        bg:SetColorTexture(selected and .15 or .055, selected and .125 or .055,
            selected and .057 or .058, .94)
        for _,t in ipairs(lines) do
            if selected then t:SetColorTexture(.76,.56,.11,.95)
            else t:SetColorTexture(.29,.265,.19,.85) end
        end
    end
    return btn
end


-- Standard options pages use Settings.Create* directly. Compact custom canvases
-- use Blizzard's CURRENT Settings checkbox control and Blizzard_Menu dropdown;
-- no duplicate checked artwork or fake dropdown overlays are drawn by us.
-- The wrapper delegates state and mouse scripts to the template's real check box.
function LL:CreateSettingsCheckbox(parent)
    local holder=CreateFrame("Frame",nil,parent,"SettingsCheckboxControlTemplate")
    -- Blizzard exposes the live child as `Checkbox` (lowercase b) on
    -- current Retail. Support the alternate capitalization for older builds.
    local native=holder.Checkbox or holder.CheckBox
    if not native then
        error("Loot Liquidator requires Blizzard SettingsCheckboxControlTemplate")
    end
    holder:SetSize(22,22)
    if holder.Text then holder.Text:SetText("") end
    native:ClearAllPoints()
    native:SetPoint("CENTER",holder,"CENTER",0,0)
    native:SetSize(22,22)
    -- The outward API is intentionally compatible with our existing rows.
    -- A wrapper is needed because this Settings template has its own CheckBox.
    function holder:SetChecked(value) native:SetChecked(value==true) end
    function holder:GetChecked() return native:GetChecked() end
    function holder:Enable() native:Enable() end
    function holder:Disable() native:Disable() end
    function holder:SetEnabled(value)
        if value then native:Enable() else native:Disable() end
    end
    local baseSetScript=holder.SetScript
    function holder:SetScript(event,callback)
        if event=="OnClick" or event=="OnEnter" or event=="OnLeave" then
            native:SetScript(event, callback and function(_,...) return callback(self,...) end or nil)
        else
            baseSetScript(self,event,callback)
        end
    end
    local baseHookScript=holder.HookScript
    function holder:HookScript(event,callback)
        if event=="OnClick" or event=="OnEnter" or event=="OnLeave" then
            native:HookScript(event,function(_,...) return callback(self,...) end)
        else
            baseHookScript(self,event,callback)
        end
    end
    holder.llNativeCheckbox=native
    if LL.SkinSettingsCanvasControl then LL:SkinSettingsCanvasControl(holder,"check") end
    return holder
end

-- Compact canvas controls are allowed only where vertical settings cannot
-- express the layout (item link entry, per-character grid, color buttons).
function LL:CreateSettingsEditBox(parent)
    local edit=CreateFrame("EditBox",nil,parent)
    edit:SetSize(205,24)
    edit:SetAutoFocus(false)
    edit:SetFontObject(GameFontHighlight)
    if edit.SetTextInsets then edit:SetTextInsets(7,7,0,0) end
    local bg=edit:CreateTexture(nil,"BACKGROUND")
    bg:SetAllPoints(edit)
    bg:SetColorTexture(.045,.045,.05,.97)
    local function Edge(a,b,isHorizontal)
        local line=edit:CreateTexture(nil,"BORDER")
        line:SetColorTexture(.36,.31,.19,.95)
        line:SetPoint(a,edit,a,0,0)
        line:SetPoint(b,edit,b,0,0)
        if isHorizontal then line:SetHeight(1) else line:SetWidth(1) end
    end
    Edge("TOPLEFT","TOPRIGHT",true)
    Edge("BOTTOMLEFT","BOTTOMRIGHT",true)
    Edge("TOPLEFT","BOTTOMLEFT",false)
    Edge("TOPRIGHT","BOTTOMRIGHT",false)
    edit:SetScript("OnEscapePressed",function(self)self:ClearFocus()end)
    return edit
end

-- The badge-size control uses Blizzard's modern slider template, rather
-- than a plain Slider with recreated tracks, thumbs or +/- buttons.
function LL:CreateSettingsCanvasSlider(parent,minValue,maxValue,step,initial,onChange)
    local control=CreateFrame("Frame",nil,parent)
    control:SetSize(382,30)
    local slider=CreateFrame("Slider",nil,control,"MinimalSliderTemplate")
    slider:SetPoint("LEFT",control,"LEFT",4,0)
    slider:SetSize(302,25)
    slider:SetMinMaxValues(minValue,maxValue)
    slider:SetValueStep(step)
    if slider.SetObeyStepOnDrag then slider:SetObeyStepOnDrag(true) end
    local number=control:CreateFontString(nil,"OVERLAY","GameFontNormal")
    number:SetPoint("LEFT",slider,"RIGHT",12,0)
    number:SetWidth(48)
    number:SetJustifyH("LEFT")
    local current=nil
    local function Clamp(value)
        value=tonumber(value) or minValue
        value=math.floor((value-minValue)/step+0.5)*step+minValue
        return math.max(minValue,math.min(maxValue,value))
    end
    local function Update(value)
        local rounded=Clamp(value)
        number:SetText(tostring(rounded))
        if rounded~=current then
            current=rounded
            if onChange then onChange(rounded) end
        end
    end
    slider:SetScript("OnValueChanged",function(_,value) Update(value) end)
    function control:SetValue(value)
        value=Clamp(value)
        slider:SetValue(value)
        Update(value)
    end
    function control:GetValue() return current or minValue end
    control.slider=slider
    control:SetValue(initial)
    return control
end
