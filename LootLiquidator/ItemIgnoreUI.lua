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
