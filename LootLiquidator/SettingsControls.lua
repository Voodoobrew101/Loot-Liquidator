-- Shared Settings canvas controls and compact editors. No calculation logic.
do -- SettingsButtons
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
local function SettingsButton(parent)
    return LL:CreateSettingsButton(parent)
end
function LL:CreateItemIgnorePanel()
    local panel=CreateFrame("Frame")
    panel:SetSize(640,580)
    SmallText(panel,"Item Ignore List",16,-15,"GameFontNormalLarge")
    SmallText(panel,"Account-wide. Checked actions are excluded from Loot Liquidator recommendations.",16,-45)
    SmallText(panel,"Processing covers Milling, Prospecting, Smelting, Recycling, and other conversions.",16,-63)
    local drop=SettingsButton(panel)
    drop:SetSize(440,35);drop:SetPoint("TOPLEFT",16,-89)
    drop:SetText("Drop an item from your bags here (ignore all by default)")
    Help(drop,"Drag an item from your inventory and release it here. This only adds its item ID to the list; it does not consume the item.")
    local entry=LL:CreateSettingsEditBox(panel)
    entry:SetSize(205,24);entry:SetPoint("TOPLEFT",24,-140)
    entry:SetAutoFocus(false)
    entry:SetMaxLetters(255)
    local add=SettingsButton(panel)
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
            local remove=SettingsButton(row)
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
