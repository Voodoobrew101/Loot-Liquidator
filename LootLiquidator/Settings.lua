-- Native Options > AddOns configuration. Every appearance preference applies
-- to BetterBags, Blizzard bags, banks and tooltips simultaneously.
local _, LL = ...
local COLORS={A={1,.84,.18},V={.85,.85,.85},D={.72,.36,1},
    M={.20,.88,.36},P={.25,.75,1},S={1,.55,.21},C={1,.64,.22},Q={1,.53,.18},T={.40,.94,.84}}
local NAMES={A="Auction",V="Vendor",D="Disenchant",M="Mill",P="Prospect",
    S="Smelt",Q="Insufficient Data",T="Transmog"}
local ORDER={"A","V","D","M","P","S","T","Q"}
local POSITIONS={"TOPLEFT","TOP","TOPRIGHT","LEFT","CENTER","RIGHT","BOTTOMLEFT","BOTTOM","BOTTOMRIGHT"}
function LL:GetBadgeColor(action)
    local custom=self.db and self.db.appearance and self.db.appearance.colors
    return (custom and custom[action]) or COLORS[action] or {1,1,1}
end
function LL:MarkupColor(action)
    local c=self:GetBadgeColor(action)
    return ("|cff%02x%02x%02x"):format(math.floor(c[1]*255+.5),
        math.floor(c[2]*255+.5),math.floor(c[3]*255+.5))
end
function LL:UpdateAllAppearance()
    if self.Invalidate then self:Invalidate() end
    if self.QueueBlizzardBagRefresh then self:QueueBlizzardBagRefresh() end
    if self.RefreshPreviews then self:RefreshPreviews() end
    if self.badgeSettingsPanel and self.badgeSettingsPanel.RefreshVisibility then
        self.badgeSettingsPanel:RefreshVisibility()
    end
    -- Refresh currently visible WoW tooltip only when the host exposes a
    -- supported refresh method; never simulate another item hover.
    if GameTooltip and GameTooltip.IsShown and GameTooltip:IsShown()
        and type(GameTooltip.RefreshData)=="function" then
        pcall(GameTooltip.RefreshData,GameTooltip)
    end
end
local function Section(layout,title)
    if layout and layout.AddInitializer and CreateSettingsListSectionHeaderInitializer then
        layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(title))
    end
end
local function Checkbox(category,key,name,description,default)
    local d=LL.db
    local setting=Settings.RegisterAddOnSetting(category,"LootLiquidator_"..key,key,d,
        "boolean",name,default)
    if setting.SetValueChangedCallback then
        setting:SetValueChangedCallback(function() LL:UpdateAllAppearance() end)
    end
    Settings.CreateCheckbox(category,setting,description or "")
end
local function Dropdown(category,key,title,description,options,default)
    local setting=Settings.RegisterAddOnSetting(category,"LootLiquidator_"..key,
        key,LL.db,"number",title,default)
    if setting.SetValueChangedCallback then
        setting:SetValueChangedCallback(function() LL:UpdateAllAppearance() end)
    end
    local function Values()
        local out=Settings.CreateControlTextContainer()
        for _,o in ipairs(options) do out:Add(o[1],o[2],o[3] or "") end
        return out:GetData()
    end
    LL:WithoutDropdownSteppers(Settings.CreateDropdown(category,setting,Values,description or ""))
end
-- This is a live list, read afresh when Blizzard displays the dropdown.
-- All choices are read-only in TSM. Selecting an operation here affects
-- Loot Liquidator's *estimate*, not TSM's group assignments/posting UI.
local function TSMDropdown(category,key,title)
    local setting=Settings.RegisterAddOnSetting(category,"LootLiquidator_"..key,
        key,LL.db,"string",title,key=="tsmFallbackOperation" and "@none" or "@assigned")
    if setting.SetValueChangedCallback then
        setting:SetValueChangedCallback(function() LL:UpdateAllAppearance() end)
    end
    local function Values()
        local out=Settings.CreateControlTextContainer()
        if key=="tsmFallbackOperation" then
            out:Add("@none","No override — show unknown pricing","Only used when TSM has no assigned operation")
        else
            out:Add("@assigned","Use item's assigned TSM operation",
                "Uses TSM grouping and its first auctioning operation")
        end
        local names=LL:GetAuctionOperationNames()
        for _,name in ipairs(names) do
            out:Add(name,name,"Preview prices using this operation; assign in TSM to actually post with it")
        end
        return out:GetData()
    end
    LL:WithoutDropdownSteppers(Settings.CreateDropdown(category,setting,Values,
        "Read-only price simulation. To actually post with this operation, assign it to the item in TSM."))
end
local function Slider(category,key,title,description,lower,upper,step,default)
    local setting=Settings.RegisterAddOnSetting(category,"LootLiquidator_"..key,
        key,LL.db,"number",title,default)
    if setting.SetValueChangedCallback then
        setting:SetValueChangedCallback(function() LL:UpdateAllAppearance() end)
    end
    local options=Settings.CreateSliderOptions(lower,upper,step)
    if options.SetLabelFormatter and MinimalSliderWithSteppersMixin then
        options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)
    end
    Settings.CreateSlider(category,setting,options,description or "")
end
local function ExplainOnHover(control,title,description)
    control:SetScript("OnEnter",function(self)
        if GameTooltip then
            GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
            GameTooltip:SetText(title,1,1,1)
            GameTooltip:AddLine(description,.8,.8,.8,true)
            GameTooltip:Show()
        end
    end)
    control:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
end
local PreviewPanel
local function AppearancePanel()
    local panel=CreateFrame("Frame")
    local function title(str,x,y,object)
        local fs=panel:CreateFontString(nil,"ARTWORK",object or "GameFontNormal")
        fs:SetPoint("TOPLEFT",panel,"TOPLEFT",x,y)
        fs:SetText(str)
        return fs
    end
    title("One appearance profile for every bag and bank",16,-18,"GameFontHighlight")
    -- Global badge visibility belongs here; the General page only enables the addon.
    local badgeToggle=LL:CreateSettingsCheckbox(panel)
    badgeToggle:SetSize(23,23)
    badgeToggle:SetPoint("TOPLEFT",panel,"TOPLEFT",20,-42)
    panel.llVisibilityCheckboxes={showBadges=badgeToggle}
    local badgeLabel=panel:CreateFontString(nil,"ARTWORK","GameFontHighlight")
    badgeLabel:SetPoint("LEFT",badgeToggle,"RIGHT",6,0)
    badgeLabel:SetText("Show item badges")
    badgeToggle:SetScript("OnClick",function(self)
        LL.db.showBadges=self:GetChecked()==true
        LL:UpdateAllAppearance()
    end)
    panel:HookScript("OnShow",function()panel:RefreshVisibility()end)
    title("Where to show badges",20,-88)
    -- These checkboxes have moved from General; saved keys and the actual bag
    -- integrations are unchanged. Use Blizzard's real Settings check boxes.
    local surfaces={
        {key="showBlizzardBags",label="Blizzard bags & banks",x=20},
        {key="showBetterBags",label="BetterBags",x=264},
        {key="showGuildBank",label="Guild bank",x=424},
    }
    function panel:RefreshVisibility()
        for key,checkbox in pairs(self.llVisibilityCheckboxes) do
            checkbox:SetChecked(LL.db[key]~=false)
        end
    end
    for _,surface in ipairs(surfaces) do
        local cb=LL:CreateSettingsCheckbox(panel)
        panel.llVisibilityCheckboxes[surface.key]=cb
        cb:SetSize(23,23)
        cb:SetPoint("TOPLEFT",panel,"TOPLEFT",surface.x,-110)
        local label=panel:CreateFontString(nil,"ARTWORK","GameFontHighlight")
        label:SetPoint("LEFT",cb,"RIGHT",6,0)
        label:SetText(surface.label)
        cb:SetChecked(LL.db[surface.key]~=false)
        cb:SetScript("OnClick",function(self)
            LL.db[surface.key]=self:GetChecked()==true
            LL:UpdateAllAppearance()
        end)
        panel:HookScript("OnShow",function()cb:SetChecked(LL.db[surface.key]~=false)end)
    end
    title("Badge position",20,-149)
    local displayNames={TOPLEFT="Top left",TOP="Top center",TOPRIGHT="Top right",
        LEFT="Middle left",CENTER="Center",RIGHT="Middle right",
        BOTTOMLEFT="Bottom left",BOTTOM="Bottom center",BOTTOMRIGHT="Bottom right"}
    for i,pos in ipairs(POSITIONS) do
        local btn=LL:CreateSettingsButton(panel)
        btn:SetSize(118,24)
        btn:SetPoint("TOPLEFT",20+((i-1)%3)*130,-171-math.floor((i-1)/3)*27)
        ExplainOnHover(btn,"Badge position","Places the badge at this point on the item icon. Applies to every supported bag interface.")
        btn:SetText(displayNames[pos])
        btn:SetScript("OnClick",function()
            LL.db.appearance.position=pos
            LL:UpdateAllAppearance()
            if panel.RefreshPositionButtons then panel:RefreshPositionButtons() end
        end)
        panel.llPositionButtons=panel.llPositionButtons or {}
        panel.llPositionButtons[pos]=btn
    end
    function panel:RefreshPositionButtons()
        for pos,button in pairs(self.llPositionButtons or {}) do
            if button.SetSelected then
                button:SetSelected(LL.db.appearance.position == pos)
            end
        end
    end
    panel:HookScript("OnShow",function(self) self:RefreshPositionButtons() end)
    panel:RefreshPositionButtons()
    title("Badge font size",20,-254)
    local slider=LL:CreateSettingsCanvasSlider(panel,9,22,1,
        LL.db.appearance.fontSize or 14,function(num)
            if LL.db.appearance.fontSize~=num then
                LL.db.appearance.fontSize=num
                LL:UpdateAllAppearance()
            end
        end)
    slider:SetPoint("TOPLEFT",panel,"TOPLEFT",20,-277)
    ExplainOnHover(slider,"Badge font size","DISPLAY ONLY: The shared badge font size (9 to 22) for every supported bag interface.")
    ExplainOnHover(slider.slider,"Badge font size","DISPLAY ONLY: The shared badge font size (9 to 22) for every supported bag interface.")
    panel:HookScript("OnShow",function()
        slider:SetPreferenceValue(LL.db.appearance.fontSize or 14)
    end)
    title("Colors (click to customize each action)",20,-320)
    for i,letter in ipairs(ORDER) do
        local row=math.floor((i-1)/2);local col=(i-1)%2
        local btn=LL:CreateSettingsButton(panel)
        btn:SetSize(174,26)
        btn:SetPoint("TOPLEFT",20+col*192,-344-row*31)
        local function update()
            local c=LL:GetBadgeColor(letter)
            btn:SetText(letter.."  "..NAMES[letter])
            local font=btn:GetFontString()
            if font then font:SetTextColor(c[1],c[2],c[3]) end
        end
        ExplainOnHover(btn,"Badge color: "..NAMES[letter],"DISPLAY ONLY: Change the displayed color of this badge everywhere. Gold recommendations do not change.")
        btn:SetScript("OnClick",function()
            if not ColorPickerFrame or not ColorPickerFrame.SetupColorPickerAndShow then return end
            local c=LL:GetBadgeColor(letter)
            local before={c[1],c[2],c[3]}
            ColorPickerFrame:SetupColorPickerAndShow({
                r=c[1],g=c[2],b=c[3],hasOpacity=false,
                swatchFunc=function()
                    local r,g,b=ColorPickerFrame:GetColorRGB()
                    LL.db.appearance.colors[letter]={r,g,b}
                    update();LL:UpdateAllAppearance()
                end,
                cancelFunc=function()
                    LL.db.appearance.colors[letter]=before
                    update();LL:UpdateAllAppearance()
                end,
            })
        end)
        update()
    end
    local hideUnknown=LL:CreateSettingsCheckbox(panel)
    hideUnknown:SetPoint("TOPLEFT",panel,"TOPLEFT",330,-473)
    hideUnknown:SetSize(25,25)
    hideUnknown:SetChecked(LL.db.showUnknownBadge~=false)
    local unknownLabel=panel:CreateFontString(nil,"ARTWORK","GameFontHighlight")
    unknownLabel:SetPoint("LEFT",hideUnknown,"RIGHT",3,0)
    unknownLabel:SetText("Show ?")
    ExplainOnHover(hideUnknown,"Show Insufficient Data badge",
        "Display only: Hide or show '?' without changing item recommendations.")
    hideUnknown:SetScript("OnClick",function(self)
        LL.db.showUnknownBadge=self:GetChecked()==true
        LL:UpdateAllAppearance()
    end)
    panel:HookScript("OnShow",function()
        hideUnknown:SetChecked(LL.db.showUnknownBadge~=false)
    end)
    -- Display-only badge policy belongs with badge appearance, not valuation.
    local soulbound=LL:CreateSettingsCheckbox(panel)
    soulbound:SetSize(24,24)
    soulbound:SetPoint("TOPLEFT",panel,"TOPLEFT",20,-473)
    soulbound:SetChecked(LL.db.showSoulboundVendorBadge==true)
    local boundLabel=panel:CreateFontString(nil,"ARTWORK","GameFontHighlight")
    boundLabel:SetPoint("LEFT",soulbound,"RIGHT",6,0)
    boundLabel:SetText("Show V on soulbound gear")
    ExplainOnHover(soulbound,"Bound equipment badges",
        "Display the Vendor badge on soulbound gear with no better available action.")
    soulbound:SetScript("OnClick",function(self)
        LL.db.showSoulboundVendorBadge=self:GetChecked()==true
        LL:UpdateAllAppearance()
    end)
    panel:HookScript("OnShow",function()
        soulbound:SetChecked(LL.db.showSoulboundVendorBadge==true)
    end)
    -- B4: one switch for counting alts in badges. The transfer rule
    -- (CanTransferToAlt) still decides which items can actually go to an alt.
    local alts=LL:CreateSettingsCheckbox(panel)
    panel.llIncludeAltsCheckbox=alts
    alts:SetSize(24,24)
    alts:SetPoint("TOPLEFT",panel,"TOPLEFT",264,-473)
    alts:SetChecked(LL.db.includeVerifiedAlts~=false)
    local altsLabel=panel:CreateFontString(nil,"ARTWORK","GameFontHighlight")
    altsLabel:SetPoint("LEFT",alts,"RIGHT",6,0)
    altsLabel:SetText("Include alts")
    ExplainOnHover(alts,"Include alts",
        "Let badges use your alts' professions and transmog, but only for items you can actually send to that alt (never soulbound or quest items).")
    alts:SetScript("OnClick",function(self)
        LL.db.includeVerifiedAlts=self:GetChecked()==true
        if LL.Invalidate then LL:Invalidate("includeVerifiedAlts") end
        LL:UpdateAllAppearance()
    end)
    panel:HookScript("OnShow",function()
        alts:SetChecked(LL.db.includeVerifiedAlts~=false)
    end)
    local preview=PreviewPanel()
    preview:SetParent(panel)
    preview:SetPoint("TOPLEFT",panel,"TOPLEFT",0,-510)
    preview:SetSize(560,82)
    return panel
end

-- Shared illustration uses the same LA:Paint and AppendRecommendationTooltip as
-- real bag buttons. Figures are EXAMPLES, never taken as live TSM quotes.
local previewPanels=setmetatable({}, {__mode="k"})
-- Preview-only example fixtures. Their output IDs are real materials, but
-- quantities and monetary values are ILLUSTRATIONS, never live market quotes.
-- Every example uses the normal tooltip material renderer; no second tooltip
-- implementation or dependency on TSM/ATT is needed to draw the examples.
local PREVIEW_ITEMS = {
    {name="Sample Mageroyal (62)",itemID=785,action="A",count=62,
        auction=20000,convert=16200,vendor=100,method="Mill",letter="M",inputCount=5,
        outputs={
            {id=39334,chance=1,expectedQuantity=3,minQuantity=2,maxQuantity=4,priceWeight=1},
            {id=43103,chance=.25,expectedQuantity=.5,minQuantity=1,maxQuantity=3,priceWeight=3},
        }},
    {name="Sample soulbound ring",itemID=272147,action="D",count=1,
        auction=nil,convert=480000,vendor=369500,method="Disenchant",letter="D",inputCount=1,
        outputs={{id=243605,expectedQuantity=1,priceWeight=1}}},
    {name="Sample Copper Ore (10)",itemID=2770,action="S",count=10,
        auction=35000,convert=47000,vendor=500,method="Smelt",letter="S",inputCount=10,
        outputs={{id=2840,expectedQuantity=10,minQuantity=10,maxQuantity=10,priceWeight=1}}},
}
local function SampleDecision(row)
    local options={{name=row.method,letter=row.letter,available=true,value=row.convert,
        confidence="illustrative",source="Illustrative values only",inputCount=row.inputCount}}
    -- The mock conversion total is per original item, while outputs are per
    -- processing batch. Allocate synthetic unit quotes so the breakdown adds
    -- back up to the quoted conversion value after the optional AH fee.
    local weightSum=0
    for _,material in ipairs(row.outputs or {}) do
        weightSum=weightSum+(material.expectedQuantity or 0)*(material.priceWeight or 1)
    end
    local outputs={}
    local fee=LL.AHFeeRate and LL:AHFeeRate() or .05
    if type(fee)~="number" or fee<0 or fee>=1 then fee=.05 end
    local unitBase=weightSum>0 and (row.convert or 0)*(row.inputCount or 1)
        / ((1-fee)*weightSum) or 0
    for _,material in ipairs(row.outputs or {}) do
        local price=unitBase*(material.priceWeight or 1)
        outputs[#outputs+1]={id=material.id,chance=material.chance,
            expectedQuantity=material.expectedQuantity,
            minQuantity=material.minQuantity,maxQuantity=material.maxQuantity,
            unitPrice=price,expectedValue=price*material.expectedQuantity,
            illustrative=true}
    end
    options[1].estimate={confidence="illustrative",inputCount=row.inputCount,
        note="Preview only: sample quantities and prices",materials=outputs}
    if row.itemID==2770 then
        -- Copper ore is BOTH smeltable and prospectable. The latter operates
        -- on two 5-ore batches in this ten-ore illustration. This fixture
        -- never calls TSM or alters measured/provisional Game Data.
        local gems={
            {id=774,chance=.5,expectedQuantity=.75},
            {id=818,chance=.5,expectedQuantity=.75},
            {id=1210,chance=.10,expectedQuantity=.15},
        }
        local prospectTotal=30000
        local prospectSum=0
        for _,m in ipairs(gems) do prospectSum=prospectSum+m.expectedQuantity end
        local unit=prospectTotal*5/((1-fee)*prospectSum)
        for _,m in ipairs(gems) do
            m.minQuantity=1;m.maxQuantity=2
            m.unitPrice=unit;m.expectedValue=unit*m.expectedQuantity
            m.illustrative=true
        end
        options[#options+1]={name="Prospect",letter="P",available=true,
            value=prospectTotal,inputCount=5,confidence="illustrative",
            estimate={confidence="illustrative",inputCount=5,
                note="Illustrative historical gem chances",materials=gems}}
    end
    return {action=row.action,method=row.method,conversion=options[1],
        conversionOptions=options,itemID=row.itemID,count=row.count,
        rawAuction=row.auction,netAuction=row.auction and row.auction*(1-fee) or 0,
        vendor=row.vendor,auctionEligible=row.auction~=nil,facts={name=row.name},
        isBound=row.auction==nil}
end
PreviewPanel=function()
    local panel=CreateFrame("Frame")
    panel:SetSize(560,90)
    local index=1
    local caption=panel:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall")
    caption:SetPoint("TOPLEFT",panel,"TOPLEFT",20,-7)
    caption:SetText("Sample item — hover over the icon for a tooltip preview")
    local icon=LL:CreateSettingsButton(panel)
    icon:SetSize(46,46); icon:SetPoint("TOPLEFT",panel,"TOPLEFT",20,-28)
    local texture=icon:CreateTexture(nil,"BACKGROUND")
    texture:SetAllPoints(icon)
    texture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    local name=panel:CreateFontString(nil,"ARTWORK","GameFontNormal")
    name:SetPoint("TOPLEFT",icon,"TOPRIGHT",16,-5)
    local indicator=panel:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall")
    indicator:SetPoint("TOPLEFT",name,"BOTTOMLEFT",0,-8)
    local change=LL:CreateSettingsButton(panel)
    change:SetSize(155,25);change:SetPoint("TOPLEFT",panel,"TOPLEFT",337,-37)
    change:SetText("Next sample item")
    panel.refresh=function()
        if not LL.db then return end
        local row=PREVIEW_ITEMS[index]
        if C_Item and C_Item.GetItemIconByID then
            local textureID=C_Item.GetItemIconByID(row.itemID)
            if textureID then texture:SetTexture(textureID) end
        end
        name:SetText(row.name)
        local levels={[0]="Off",[1]="Recommendation",[2]="Alternatives",[3]="Breakdown"}
        indicator:SetText("Preview only | "..(levels[LL.db.tooltipDetail or 2] or "Alternatives").." | "..
            (LL.db.tooltipShowAfterAHCut~=false and "AH net" or "AH listing"))
        LL:Paint(icon,"preview:"..row.itemID,SampleDecision(row))
    end
    change:SetScript("OnClick",function()
        index=index%#PREVIEW_ITEMS+1
        panel.refresh()
    end)
    -- Dedicated preview tooltip: never ClearLines/SetOwner on the global
    -- GameTooltip used by bags, Pawn, TSM, and comparison tooltips.
    local previewTip
    icon:SetScript("OnEnter",function()
        if not LL.AppendRecommendationTooltip then return end
        if not previewTip then
            previewTip=CreateFrame("GameTooltip","LootLiquidatorPreviewTooltip",UIParent,"GameTooltipTemplate")
        end
        previewTip:SetOwner(icon,"ANCHOR_RIGHT")
        previewTip:ClearLines()
        previewTip:AddLine(PREVIEW_ITEMS[index].name,1,1,1)
        previewTip:AddLine("ILLUSTRATIVE prices, not live quotes",1,.7,.2)
        LL:AppendRecommendationTooltip(previewTip,SampleDecision(PREVIEW_ITEMS[index]))
        previewTip:Show()
    end)
    icon:SetScript("OnLeave",function() if previewTip then previewTip:Hide() end end)
    panel:HookScript("OnShow",function() panel.refresh() end)
    previewPanels[panel]=true
    return panel
end
function LL:RefreshPreviews()
    for panel in pairs(previewPanels) do if panel.refresh then panel.refresh() end end
end

-- A single hover-preview widget serves Badges & Colors AND Tooltips.
-- No duplicate, static 14-row rendering or 335px blank frame.
function LootLiquidator_InitTooltipPreview(panel)
    if panel.llInitialized then return end
    panel.llInitialized=true
    local preview=PreviewPanel()
    preview:SetParent(panel)
    preview:SetPoint("TOPLEFT",panel,"TOPLEFT",0,0)
    preview:SetSize(560,90)
    panel.llPreview=preview
end

-- Shared compact source rows use the same native Settings canvas controls as
-- the roster. Preferences are separate from TSM's market-price selection.
function LL:CreateEvidenceSettingsPanel(category)
    local panel=CreateFrame("Frame")
    local rows={}
    local labels={itemdb="itemdb.lua research database",personal="Personal observations",
        legacy="Legacy fallback estimates"}
    local descriptions={itemdb="Compiled research, including provisional records; unknown fields remain unknown.",
        personal="Your recorded completed operations. Personal-only modes exclude all external evidence.",
        legacy="Optional historical scenarios. Never treated as verified skill coefficients."}
    for index,key in ipairs(LL.SourceOrder) do
        local source=key
        local d=LL.SourceDefaults[source]
        local enabledKey,weightKey="source_"..source.."_enabled","source_"..source.."_weight"
        local checked=Settings.RegisterAddOnSetting(category,"LootLiquidator_"..enabledKey,enabledKey,LL.db,"boolean",labels[source],d[1])
        local weighted=Settings.RegisterAddOnSetting(category,"LootLiquidator_"..weightKey,weightKey,LL.db,"number",labels[source].." weight",d[2])
        local check=LL:CreateSettingsCheckbox(panel)
        check:SetPoint("TOPLEFT",panel,"TOPLEFT",12,-30-(index-1)*78)
        local text=panel:CreateFontString(nil,"ARTWORK","GameFontHighlight")
        text:SetPoint("LEFT",check,"RIGHT",6,0);text:SetWidth(230);text:SetJustifyH("LEFT");text:SetText(labels[source])
        local slider=LL:CreateSettingsCanvasSlider(panel,0,100,1,LL.db[weightKey],function(value)
            if LL.db[weightKey]~=value then weighted:SetValue(value) end
        end)
        slider:SetPoint("TOPLEFT",panel,"TOPLEFT",285,-26-(index-1)*78)
        check:SetScript("OnClick",function(self) checked:SetValue(self:GetChecked()) end)
        local function refresh()
            check:SetChecked(LL.db[enabledKey]);slider:SetPreferenceValue(LL.db[weightKey])
        end
        for _,setting in ipairs({checked,weighted}) do
            setting:SetValueChangedCallback(function()
                if LL.Invalidate then LL:Invalidate("evidence") end
                refresh()
            end)
        end
        local note=panel:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall")
        note:SetPoint("TOPLEFT",panel,"TOPLEFT",40,-58-(index-1)*78)
        note:SetWidth(550);note:SetJustifyH("LEFT");note:SetText(descriptions[source])
        rows[#rows+1]=refresh
    end
    local reset=LL:CreateSettingsButton(panel)
    reset:SetPoint("TOPLEFT",panel,"TOPLEFT",16,-360);reset:SetSize(230,26);reset:SetText("Reset source weights")
    reset:SetScript("OnClick",function()
        for source,d in pairs(LL.SourceDefaults) do
            Settings.GetSetting("LootLiquidator_source_"..source.."_enabled"):SetValue(d[1])
            Settings.GetSetting("LootLiquidator_source_"..source.."_weight"):SetValue(d[2])
        end
    end)
    panel:SetScript("OnShow",function() for _,refresh in ipairs(rows) do refresh() end end)
    return panel
end
function LL:CreateProfessionProfilePanel(profession)
    local panel=CreateFrame("Frame")
    local selected=LL:CharacterKey() or "Current character"
    local expansion=(GetExpansionLevel and GetExpansionLevel()) or 11
    local nodeIndex,buffIndex=0,0
    local options={nodes={},buffs={}}
    local refreshing=false
    local refresh
    local function label(text,y)
        local t=panel:CreateFontString(nil,"ARTWORK","GameFontHighlight")
        t:SetPoint("TOPLEFT",panel,"TOPLEFT",16,y);t:SetWidth(590);t:SetJustifyH("LEFT");t:SetText(text)
        return t
    end
    local function choices(rows)
        local container=Settings.CreateControlTextContainer()
        for _,row in ipairs(rows) do container:Add(row[1],row[2],row[3] or "") end
        return container:GetData()
    end
    local function profile() return LL:GetManualProfessionProfile(selected,profession,expansion) or {} end
    local message=label("",-535)
    local function update(change)
        if refreshing then return end
        local p={} for k,v in pairs(profile()) do p[k]=v end
        p.buffs={} for k,v in pairs(profile().buffs or {}) do p.buffs[k]=v end
        change(p)
        local ok=LL:SetManualProfessionProfile(selected,profession,expansion,p)
        message:SetText(ok and "Simulation saved. Scanned skills and talents are unchanged." or "Could not save this selection.")
        if refresh then refresh(false) end
    end
    label(profession.." — character and expansion",-16)
    label("Choose the expansion whose recipes you want to inspect. Log into an alt and open that profession to capture its skills and specialization names.",-44)
    local character=LL:CreateSettingsDropdown(panel,function()
        local keys={} for k in pairs(LL.db.characters or {}) do keys[#keys+1]=k end
        table.sort(keys);panel.characterKeys=keys
        local rows={} for i,k in ipairs(keys) do rows[#rows+1]={i,k} end
        return choices(rows)
    end,function()
        for i,k in ipairs(panel.characterKeys or {}) do if k==selected then return i end end
        return 1
    end,function(i) selected=(panel.characterKeys or {})[i] or selected;nodeIndex=0;buffIndex=0;refresh(true) end)
    character:SetPoint("TOPLEFT",panel,"TOPLEFT",16,-90)
    local era=LL:CreateSettingsDropdown(panel,function()
        local rows={} for id=0,11 do rows[#rows+1]={id,LL:ProfessionExpansionName(id)} end
        return choices(rows)
    end,function() return expansion end,function(id) expansion=id;nodeIndex=0;buffIndex=0;refresh(true) end)
    era:SetPoint("TOPLEFT",panel,"TOPLEFT",326,-90)
    local status=label("",-132)
    local enabled=LL:CreateSettingsCheckbox(panel)
    enabled:SetPoint("TOPLEFT",panel,"TOPLEFT",16,-192)
    local enabledLabel=label("Use this what-if profile (when \"Show rates for\" is \"What-if profile\")",-194)
    enabledLabel:ClearAllPoints();enabledLabel:SetPoint("LEFT",enabled,"RIGHT",6,0)
    enabled:SetScript("OnClick",function(self) update(function(p) p.enabled=self:GetChecked()==true end) end)
    local known=LL:CreateSettingsCheckbox(panel)
    known:SetPoint("TOPLEFT",panel,"TOPLEFT",16,-235)
    local skillLabel=label("Set simulated effective skill",-238)
    skillLabel:ClearAllPoints();skillLabel:SetPoint("LEFT",known,"RIGHT",6,0)
    local skill=LL:CreateSettingsCanvasSlider(panel,0,1000,1,0,function(v)
        if not refreshing and known:GetChecked() then update(function(p) p.skill=v end) end
    end)
    skill:SetPoint("TOPLEFT",panel,"TOPLEFT",270,-232)
    known:SetScript("OnClick",function(self)
        update(function(p) p.skill=self:GetChecked() and skill:GetPreferenceValue() or nil end)
    end)
    label("Specialization (Blizzard names, grouped by tree)",-282)
    local node=LL:CreateSettingsDropdown(panel,function()
        local rows={{0,#options.nodes>0 and "Choose a specialization" or "Scan this profession to load specializations"}}
        for i,n in ipairs(options.nodes) do rows[#rows+1]={i,n.tab.." — "..n.name,n.description} end
        return choices(rows)
    end,function() return nodeIndex end,function(i) nodeIndex=i;refresh(false) end)
    node:SetPoint("TOPLEFT",panel,"TOPLEFT",16,-308)
    local function ranks()
        local out={} for id,rank in (profile().specialization or ''):gmatch('(%d+)=(%d+)') do out[id]=tonumber(rank) end
        return out
    end
    local rank=LL:CreateSettingsDropdown(panel,function()
        local rows={{-1,"Rank unknown"}}
        local n=options.nodes[nodeIndex]
        if n then for v=0,n.maxRank do rows[#rows+1]={v,tostring(v).." / "..n.maxRank.." points"} end end
        return choices(rows)
    end,function()
        local n=options.nodes[nodeIndex];return n and ranks()[tostring(n.id)] or -1
    end,function(v)
        local n=options.nodes[nodeIndex];if not n then return end
        local all=ranks();all[tostring(n.id)]=v>=0 and v or nil
        local parts={} for id,value in pairs(all) do parts[#parts+1]=id..'='..value end
        table.sort(parts)
        update(function(p) p.specialization=#parts>0 and table.concat(parts,',') or nil end)
    end)
    rank:SetPoint("TOPLEFT",panel,"TOPLEFT",326,-308)
    label("Captured character buffs (simulation only; may not affect this profession)",-356)
    local buff=LL:CreateSettingsDropdown(panel,function()
        local rows={{0,#options.buffs>0 and "Choose a captured buff" or "No buffs captured on this character"}}
        for i,b in ipairs(options.buffs) do rows[#rows+1]={i,b.name} end
        return choices(rows)
    end,function() return buffIndex end,function(i) buffIndex=i;refresh(false) end)
    buff:SetPoint("TOPLEFT",panel,"TOPLEFT",16,-382)
    local buffEnabled=LL:CreateSettingsCheckbox(panel)
    buffEnabled:SetPoint("TOPLEFT",panel,"TOPLEFT",334,-385)
    local buffLabel=label("Include selected buff",-388)
    buffLabel:ClearAllPoints();buffLabel:SetPoint("LEFT",buffEnabled,"RIGHT",6,0)
    buffEnabled:SetScript("OnClick",function(self)
        local b=options.buffs[buffIndex];if not b then return end
        update(function(p) p.buffs[tostring(b.id)]=self:GetChecked() and true or nil end)
    end)
    label("Selections do not spend knowledge or cast buffs. Unknown ranks stay unknown. Yield adjustments require a compatible approved mechanic; a selection alone supplies no bonus.",-433)
    local scan=LL:CreateSettingsButton(panel)
    scan:SetPoint("TOPLEFT",panel,"TOPLEFT",16,-492);scan:SetSize(260,26)
    scan:SetText("Refresh from current profession")
    scan:SetScript("OnClick",function()
        if selected~=LL:CharacterKey() then message:SetText("Log into the selected character to scan its profession.");return end
        LL:GetResearchProfessionSnapshot({expansionID=expansion},profession)
        refresh(true)
    end)
    refresh=function(reload)
        refreshing=true
        if reload then options=LL:GetProfessionUIOptions(selected,profession,expansion) end
        local p=profile()
        enabled:SetChecked(p.enabled==true);known:SetChecked(p.skill~=nil)
        skill:SetPreferenceValue(p.skill or 0)
        local record=LL.db.characters and LL.db.characters[selected]
        local snapshot=record and record.researchProfiles and record.researchProfiles[profession..":"..expansion]
        status:SetText(snapshot and (LL:ProfessionExpansionName(expansion).." snapshot: skill "..tostring(snapshot.skill or "unknown")..". Open the profession on that character to refresh it.")
            or ("No saved "..LL:ProfessionExpansionName(expansion).." "..profession.." scan for this character. This does not disable reference tooltips."))
        local b=options.buffs[buffIndex]
        buffEnabled:SetChecked(b and p.buffs and p.buffs[tostring(b.id)]==true or false)
        if b then buffEnabled:Enable() else buffEnabled:Disable() end
        character:Refresh();era:Refresh();node:Refresh();rank:Refresh();buff:Refresh()
        refreshing=false
    end
    panel:SetScript("OnShow",function() refresh(true) end)
    return panel
end

-- B5a: one simple choice of whose profession skill sets the rates. Uses only
-- Blizzard's own Settings dropdowns. Who can do the work is unchanged.
function LL:RateProfileCharacterChoices()
    local rows={{"","This character"}}
    local keys={}
    for key,entry in pairs(self.db and self.db.characters or {}) do
        if type(entry)=="table" then keys[#keys+1]=key end
    end
    table.sort(keys)
    for _,key in ipairs(keys) do
        local label=key
        if key==(self.CharacterKey and self:CharacterKey()) then label=key.." (this character)" end
        rows[#rows+1]={key,label}
    end
    return rows
end
function LL:AddRateProfileSettings(category,layout)
    Section(layout,"Rates")
    local mode=Settings.RegisterAddOnSetting(category,"LootLiquidator_rateProfile",
        "rateProfile",self.db,"number","Show rates for",1)
    local character=Settings.RegisterAddOnSetting(category,"LootLiquidator_rateProfileCharacter",
        "rateProfileCharacter",self.db,"string","Character","")
    for _,setting in ipairs({mode,character}) do
        if setting.SetValueChangedCallback then
            setting:SetValueChangedCallback(function()
                if LL.Invalidate then LL:Invalidate("rateProfile") end
                LL:UpdateAllAppearance()
            end)
        end
    end
    local modeInit=Settings.CreateDropdown(category,mode,function()
        local out=Settings.CreateControlTextContainer()
        out:Add(1,"Me","Use the skill of whoever would do the work: you, or the alt it can be sent to.")
        out:Add(2,"A chosen alt","Always use the character picked below, as if they did the work.")
        out:Add(3,"What-if profile","Use the what-if skill and specialization saved for the character below (Professions pages).")
        return out:GetData()
    end,"Whose profession skill is used to estimate milling, prospecting, smelting and disenchanting results. This never changes who can actually do it.")
    self:WithoutDropdownSteppers(modeInit)
    local charInit=Settings.CreateDropdown(category,character,function()
        local out=Settings.CreateControlTextContainer()
        for _,row in ipairs(LL:RateProfileCharacterChoices()) do out:Add(row[1],row[2]) end
        return out:GetData()
    end,"The alt (or what-if profile) used when \"Show rates for\" is not \"Me\". Characters appear here after you log into them once.")
    self:WithoutDropdownSteppers(charInit)
    if charInit and charInit.SetParentInitializer then
        charInit:SetParentInitializer(modeInit,function() return (LL.db.rateProfile or 1)~=1 end)
    end
    return modeInit,charInit
end

-- Settings are grouped by user intent, not by the Lua module providing them.
-- Crucially each SavedVariables key is registered exactly once so existing
-- profiles and preferences survive moving a control to another page.
function LL:RegisterNativeSettings()
    if self.settingsCategory or not self.db or not Settings
        or not Settings.RegisterVerticalLayoutCategory then return end

    local general, generalLayout=Settings.RegisterVerticalLayoutCategory("Loot Liquidator  v"..tostring(self.version or "?"))
    Settings.RegisterAddOnCategory(general)
    self.settingsCategory=general
    self:ProtectSettingsDefaults()
    Section(generalLayout,"General")
    Checkbox(general,"enabled","Enable Loot Liquidator",
        "Analyze items and recommend the most valuable available action.",true)
    self:AddRateProfileSettings(general,generalLayout)
    Section(generalLayout,"Use the pages on the left for badge appearance, tooltips, pricing, and addon integrations.")

    local appearancePanel=AppearancePanel()
    local appearance=Settings.RegisterCanvasLayoutSubcategory(general,appearancePanel,"Badges & Colors")
    Settings.RegisterAddOnCategory(appearance)
    self.badgeSettingsPanel=appearancePanel
    -- Register the moved canvas controls for WoW's Defaults button and
    -- SavedVariables metadata WITHOUT creating a duplicate visible checkbox.
    -- Default/reset callbacks refresh the same native canvas checkboxes.
    for _,row in ipairs({
        {"showBadges","Show item badges"},
        {"showBlizzardBags","Blizzard bags and banks"},
        {"showBetterBags","BetterBags"},
        {"showGuildBank","Guild bank"},
    }) do
        local setting=Settings.RegisterAddOnSetting(appearance,
            "LootLiquidator_"..row[1],row[1],self.db,"boolean",row[2],true)
        if setting.SetValueChangedCallback then
            setting:SetValueChangedCallback(function()self:UpdateAllAppearance()end)
        end
    end

    local soulboundSetting=Settings.RegisterAddOnSetting(appearance,
        "LootLiquidator_showSoulboundVendorBadge","showSoulboundVendorBadge",
        self.db,"boolean","Show V on soulbound gear",false)
    if soulboundSetting.SetValueChangedCallback then
        soulboundSetting:SetValueChangedCallback(function() self:UpdateAllAppearance() end)
    end
    local altsSetting=Settings.RegisterAddOnSetting(appearance,
        "LootLiquidator_includeVerifiedAlts","includeVerifiedAlts",
        self.db,"boolean","Include alts",true)
    if altsSetting.SetValueChangedCallback then
        altsSetting:SetValueChangedCallback(function()
            if self.Invalidate then self:Invalidate("includeVerifiedAlts") end
            self:UpdateAllAppearance()
        end)
    end

    local tooltips,ttLayout=Settings.RegisterVerticalLayoutSubcategory(general,"Tooltips")
    Settings.RegisterAddOnCategory(tooltips)
    if Settings.CreatePanelInitializer and ttLayout and ttLayout.AddInitializer then
        ttLayout:AddInitializer(Settings.CreatePanelInitializer("LootLiquidatorTooltipPreviewTemplate",{}))
    end
    Section(ttLayout,"What to display")
    -- B3: one level control replaces the old on/off box and most checkboxes.
    Dropdown(tooltips,"tooltipDetail","Tooltip",
        "How much Loot Liquidator adds to item tooltips. Badges show either way, and recommendations never change.",
        {{0,"Off — badges only"},{1,"Recommendation — one line"},
         {2,"Alternatives — every option with its gold value"},
         {3,"Breakdown — plus the materials behind each option"}},2)
    Checkbox(tooltips,"tooltipHeaderPrice","Show price in the header",
        "Add the recommended action's gold value per item to the first line, e.g. \"Loot Liquidator: Smelt 6g 87s\".",true)
    Section(ttLayout,"Extras")
    Checkbox(tooltips,"showMaterialConfidence","Show confidence per material",
        "Breakdown level: add each material's own confidence. The option's overall confidence is always shown.",false)
    Checkbox(tooltips,"showResearchDetails","Show research notes",
        "For troubleshooting: where each number came from, profession hints and which characters could do it. Makes tooltips much longer.",false)
    -- Hover-preview is intentionally at the top of this same page. No extra
    -- Tooltips subcategory or tall static preview remains.

    local rules,ruleLayout=Settings.RegisterVerticalLayoutSubcategory(general,"Pricing & Actions")
    Settings.RegisterAddOnCategory(rules)
    Section(ruleLayout,"Auction pricing")
    Checkbox(rules,"tooltipShowAfterAHCut","Deduct 5% auction-house cut",
        "VALUATION: Compare and show auction and processed-material proceeds after the AH cut. Turning off changes both displayed values and recommendations.",true)
    -- Reagents automatically use TSM lowest listing with market-average fallback;
    -- the old reagentMatchLowest checkbox was functionally a no-op.
    Section(ruleLayout,"Required extra profit (gold)")
    Slider(rules,"minConversionExtraGold","Minimum processing profit",
        "Extra net gold required over an unprocessed alternative before recommending processing the stack.",0,100,.05,0)
    Slider(rules,"minReagentProfitGold","Minimum reagent auction profit",
        "Extra net gold over vendoring the stack required before recommending a reagent auction.",0,100,.05,0)
    Slider(rules,"minGearProfitGold","Minimum gear auction profit",
        "Extra net gold over vendoring equipment required before an auction recommendation.",0,100,.05,0)

    local chars=self.RegisterNativeRosterTable and self:RegisterNativeRosterTable(general)
    if chars then
        for _,profession in ipairs({"Alchemy","Blacksmithing","Enchanting","Engineering","Herbalism",
            "Inscription","Jewelcrafting","Leatherworking","Mining","Skinning","Tailoring","Cooking","Fishing"}) do
            local page=Settings.RegisterCanvasLayoutSubcategory(chars,self:CreateProfessionProfilePanel(profession),profession)
            Settings.RegisterAddOnCategory(page)
        end
    end
    local accuracyPanel=CreateFrame("Frame")
    local accuracy=Settings.RegisterCanvasLayoutSubcategory(general,accuracyPanel,"Database & Accuracy")
    Settings.RegisterAddOnCategory(accuracy)
    local sources=self:CreateEvidenceSettingsPanel(accuracy)
    sources:SetParent(accuracyPanel);sources:SetAllPoints(accuracyPanel)
    local modes,modeLayout=Settings.RegisterVerticalLayoutSubcategory(accuracy,"Observation policy")
    Settings.RegisterAddOnCategory(modes)
    for _,record in ipairs({{"Disenchanting","disenchantDataMode"},{"Milling","millingDataMode"},
        {"Prospecting","prospectingDataMode"},{"Other processing","otherConversionDataMode"}}) do
        Dropdown(modes,record[2],record[1],"Weighted uses enabled compatible sources. Personal-only strictly excludes external evidence.",
            {{1,"Weighted evidence"},{2,"Personal observations only"},{3,"External references only"}},1)
    end
    Section(modeLayout,"Existing per-method policies and source preferences survive migration. Preference sliders are not confidence scores.")


    local research,researchLayout=Settings.RegisterVerticalLayoutSubcategory(general,"Processing Research")
    Settings.RegisterAddOnCategory(research)
    Section(researchLayout,"Record actual results")
    Checkbox(research,"recordDisenchants","Record disenchant results",
        "Record reliably matched disenchant yields to account-wide SavedVariables.",true)
    Checkbox(research,"recordConversions","Record crafting and processing results",
        "Record isolated completed crafts with measured inputs, outputs and profession context. Unresolved results never become zero samples. Export with /ll craftexport; no automatic database or mechanics approval.",true)
    Checkbox(research,"showProcessingSamples","Show sample counts in tooltips",
        "Show how many personal observations are available. Full distributions also require Detailed tooltips.",true)
    Section(researchLayout,"Evidence collection")
    Section(researchLayout,"Source preferences live in Database & Accuracy. Profession contexts live below Professions & Alts.")
    Section(researchLayout,"Confidence thresholds")
    Slider(research,"minPersonalSamples","Minimum weighted samples",
        "Minimum effective samples required before personal observations drive recommendations.",1,100,1,30)

    -- Standard integrations use Blizzard's vertical Settings controls and
    -- button initializers rather than a hand-drawn canvas of checkboxes.
    local integrations,integrationsLayout=Settings.RegisterVerticalLayoutSubcategory(general,"Integrations")
    Settings.RegisterAddOnCategory(integrations)
    Section(integrationsLayout,"Connected addons")
    Checkbox(integrations,"enableTSMIntegration","TradeSkillMaster pricing",
        "Read TSM auction pricing and operations without changing your TSM profile.",true)
    Checkbox(integrations,"enableATTIntegration","ATT research fallback (temporary)",
        "Use unreviewed cached/live ATT token relationships while migration is incomplete. Reviewed ItemDB token records work independently. ATT never supplies crafting yields.",true)
    Section(integrationsLayout,"Independent token research")
    Checkbox(integrations,"collectTokenResearch","Record direct token rewards and exchanges",
        "Passively record item-token vendor offers and directly opened equipment rewards as research candidates. No crafting outputs, no ATT dependency, and no automatic changes to valuations.",true)
    if CreateSettingsButtonInitializer and integrationsLayout.AddInitializer then
        integrationsLayout:AddInitializer(CreateSettingsButtonInitializer(
            "Token research observations","View / copy research export",function()
                if LL.TokenResearchExport and LL.ShowCopy then
                    LL:ShowCopy("Direct token observations - page 1",LL:TokenResearchExport(1))
                end
            end,"Copy direct equipment token relationships. Additional pages: /ll tokenexport 2 (etc.).",false))
    end
    TSMDropdown(integrations,"tsmFallbackOperation","TSM operation for ungrouped items")
    if CreateSettingsButtonInitializer and integrationsLayout.AddInitializer then
        integrationsLayout:AddInitializer(CreateSettingsButtonInitializer(
            "Legacy cache (research only)","Import filtered ATT cache",function()
                if LL.ImportLegacyTokenCandidates then
                    local count,skipped=LL:ImportLegacyTokenCandidates()
                    if print then print(("Loot Liquidator: %d unverified ATT relationships copied to research; %d excluded. No valuation data changed."):
                        format(count or 0,skipped or 0)) end
                end
            end,"Reads stored ATT records only. Excludes crafting reagents and non-equipment rewards. Copy via token research export for verification.",false))
    end
    Section(integrationsLayout,"ATT reward cache")
    if CreateSettingsButtonInitializer and integrationsLayout.AddInitializer then
        integrationsLayout:AddInitializer(CreateSettingsButtonInitializer(
            "ATT migration research","Copy relationships and coverage",function()
                LL:ShowCopy("ATT relationship research - page 1",LL:ATTResearchExport(1))
            end,"Export candidates, metadata and collection limits. Additional pages: /ll attexport 2. Status: /ll tokenmigration. No automatic approval.",false))
    end
    if CreateSettingsButtonInitializer and integrationsLayout.AddInitializer then
        integrationsLayout:AddInitializer(CreateSettingsButtonInitializer(
            "Update ATT cache","Update ATT Cache",function()
                if LL.StartATTCacheUpdate then
                    local ok,msg=LL:StartATTCacheUpdate()
                    if not ok and print then print("Loot Liquidator: "..tostring(msg)) end
                end
                if LL.RefreshATTCacheUI then LL.RefreshATTCacheUI() end
            end,"Refresh cached ATT reward relationships.",false))
    end
    Section(integrationsLayout,"TSM recommended setup")
    if CreateSettingsButtonInitializer and integrationsLayout.AddInitializer then
        integrationsLayout:AddInitializer(CreateSettingsButtonInitializer(
            "Recommended TSM setup","Select / copy TSM export",function()
                if LL.ShowCopy and LL.RecommendedTSMSetupText then
                    LL:ShowCopy("Recommended TSM Setup",LL:RecommendedTSMSetupText())
                end
            end,"Opens selectable text. Press Ctrl+C in WoW, then paste into TSM. Does not modify TSM.",false))
    end

    if self.CreateItemIgnorePanel then
        local ignores=Settings.RegisterCanvasLayoutSubcategory(general,
            self:CreateItemIgnorePanel(),"Ignored Items")
        Settings.RegisterAddOnCategory(ignores)
    end
    self.settingsPages={general=general,tooltips=tooltips,research=research,
        appearance=appearance,rules=rules,chars=chars,integrations=integrations}

end
function LL:OpenSettings()
    if not self.settingsCategory then self:RegisterNativeSettings() end
    if Settings and Settings.OpenToCategory and self.settingsCategory then
        Settings.OpenToCategory(self.settingsCategory:GetID())
    end
end
local init=CreateFrame("Frame")
init:RegisterEvent("PLAYER_LOGIN")
init:RegisterEvent("ADDON_LOADED")
init:SetScript("OnEvent",function()
    if LL.db then LL:RegisterNativeSettings() end
    if LL.settingsCategory then LL:ProtectSettingsDefaults() end
end)
