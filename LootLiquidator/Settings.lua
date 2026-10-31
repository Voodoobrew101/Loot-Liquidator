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
local function Checkbox(category,key,name,description,default,onChange)
    local d=LL.db
    local setting=Settings.RegisterAddOnSetting(category,"LootLiquidator_"..key,key,d,
        "boolean",name,default)
    if setting.SetValueChangedCallback then
        setting:SetValueChangedCallback(onChange or function() LL:UpdateAllAppearance() end)
    end
    return Settings.CreateCheckbox(category,setting,description or ""),setting
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
    return Settings.CreateSlider(category,setting,options,description or ""),setting
end
local PreviewPanel
-- B8a: Badges & Colors uses Blizzard's own vertical Settings list (checkboxes,
-- dropdown, slider, buttons) instead of a hand-placed canvas page. Saved keys
-- are unchanged: db.showBadges/showBlizzardBags/..., db.appearance.position,
-- db.appearance.fontSize and db.appearance.colors.
local POSITION_NAMES={TOPLEFT="Top left",TOP="Top center",TOPRIGHT="Top right",
    LEFT="Middle left",CENTER="Center",RIGHT="Middle right",
    BOTTOMLEFT="Bottom left",BOTTOM="Bottom center",BOTTOMRIGHT="Bottom right"}
local function Appearance()
    LL.db.appearance=LL.db.appearance or {position="TOPRIGHT",fontSize=14,colors={}}
    LL.db.appearance.colors=LL.db.appearance.colors or {}
    return LL.db.appearance
end
-- Nested appearance keys go through a proxy so a replaced db.appearance table
-- can never leave the control writing to a stale table.
local function AppearanceSetting(category,key,kind,label,default)
    local setting=Settings.RegisterProxySetting(category,"LootLiquidator_appearance_"..key,kind,label,default,
        function() local v=Appearance()[key];if v==nil then return default end;return v end,
        function(v) Appearance()[key]=v end)
    if setting.SetValueChangedCallback then
        setting:SetValueChangedCallback(function() LL:UpdateAllAppearance() end)
    end
    return setting
end
function LL:PickBadgeColor(letter)
    if not ColorPickerFrame or not ColorPickerFrame.SetupColorPickerAndShow then return false end
    local c=self:GetBadgeColor(letter)
    local before={c[1],c[2],c[3]}
    ColorPickerFrame:SetupColorPickerAndShow({
        r=c[1],g=c[2],b=c[3],hasOpacity=false,
        swatchFunc=function()
            local r,g,b=ColorPickerFrame:GetColorRGB()
            Appearance().colors[letter]={r,g,b};LL:UpdateAllAppearance()
        end,
        cancelFunc=function() Appearance().colors[letter]=before;LL:UpdateAllAppearance() end,
    })
    return true
end
function LL:ResetBadgeColors()
    Appearance().colors={}
    self:UpdateAllAppearance()
end
LL.BadgeColorOrder=ORDER
function LL:AddBadgeSettings(category,layout)
    if Settings.CreatePanelInitializer and layout and layout.AddInitializer then
        layout:AddInitializer(Settings.CreatePanelInitializer("LootLiquidatorTooltipPreviewTemplate",{}))
    end
    Section(layout,"Badges")
    Checkbox(category,"showBadges","Show item badges",
        "Show the letter badges on item icons. Tooltips are set on the Tooltips page.",true)
    Checkbox(category,"includeVerifiedAlts","Include alts",
        "Let badges use your alts' professions and transmog, but only for items you can actually send to that alt (never soulbound or quest items).",true,
        function()
            if LL.Invalidate then LL:Invalidate("includeVerifiedAlts") end
            LL:UpdateAllAppearance()
        end)
    Checkbox(category,"showUnknownBadge","Show ? badge",
        "Display only: show or hide the ? badge (not enough data). Recommendations do not change.",true)
    Checkbox(category,"showSoulboundVendorBadge","Show V on soulbound gear",
        "Show the Vendor badge on soulbound gear that has no better use.",false)
    Section(layout,"Where to show badges")
    Checkbox(category,"showBlizzardBags","Blizzard bags & banks","Bags, bank and Warband bank.",true)
    Checkbox(category,"showBetterBags","BetterBags","Only used when BetterBags is installed.",true)
    Checkbox(category,"showGuildBank","Guild bank","Badges in the guild bank window.",true)
    Section(layout,"Look")
    local position=AppearanceSetting(category,"position","string","Badge position","TOPRIGHT")
    self:WithoutDropdownSteppers(Settings.CreateDropdown(category,position,function()
        local out=Settings.CreateControlTextContainer()
        for _,pos in ipairs(POSITIONS) do out:Add(pos,POSITION_NAMES[pos]) end
        return out:GetData()
    end,"Where the badge sits on the item icon, in every bag."))
    local size=AppearanceSetting(category,"fontSize","number","Badge font size",14)
    local sizeOptions=Settings.CreateSliderOptions(9,22,1)
    if sizeOptions.SetLabelFormatter and MinimalSliderWithSteppersMixin then
        sizeOptions:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)
    end
    Settings.CreateSlider(category,size,sizeOptions,"Size of the badge letter (9 to 22), in every bag.")
    Section(layout,"Colors")
    if CreateSettingsButtonInitializer and layout and layout.AddInitializer then
        for _,letter in ipairs(ORDER) do
            layout:AddInitializer(CreateSettingsButtonInitializer(
                self:MarkupColor(letter)..letter.."|r  "..NAMES[letter],"Change color",
                function() LL:PickBadgeColor(letter) end,
                "Display only: change the color of this badge everywhere. Recommendations do not change.",false))
        end
        layout:AddInitializer(CreateSettingsButtonInitializer("Default colors","Reset colors",
            function() LL:ResetBadgeColors() end,"Put every badge color back to the default.",false))
    end
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

-- B8b: Database & Accuracy uses Blizzard's own vertical Settings list: one
-- switch per evidence source with its weight slider underneath. Saved keys are
-- unchanged (source_<name>_enabled / source_<name>_weight).
local SOURCE_LABELS={itemdb="Built-in research database",personal="Your recorded results",
    imported="Imported results",legacy="Old disenchant estimates"}
local SOURCE_DESCRIPTIONS={itemdb="The addon's own research database, including rough estimates (shown with lower confidence).",
    personal="Results you recorded yourself. They take over as you record more.",
    imported="Results pasted in from other players (Processing Research > Import). Kept separate from your own.",
    legacy="Older disenchant tables. Counted weakly; never treated as exact."}
function LL:AddEvidenceSettings(category,layout)
    Section(layout,"Where numbers come from")
    local function changed()
        if LL.Invalidate then LL:Invalidate("evidence") end
        LL:UpdateAllAppearance()
    end
    for _,source in ipairs(LL.SourceOrder) do
        local d=LL.SourceDefaults[source]
        local enabledKey,weightKey="source_"..source.."_enabled","source_"..source.."_weight"
        local label=SOURCE_LABELS[source] or source
        local checkInit=Checkbox(category,enabledKey,label,SOURCE_DESCRIPTIONS[source],d[1],changed)
        local slider=Settings.RegisterAddOnSetting(category,"LootLiquidator_"..weightKey,weightKey,
            LL.db,"number",label.." weight",d[2])
        if slider.SetValueChangedCallback then slider:SetValueChangedCallback(changed) end
        local options=Settings.CreateSliderOptions(0,100,1)
        if options.SetLabelFormatter and MinimalSliderWithSteppersMixin then
            options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)
        end
        local sliderInit=Settings.CreateSlider(category,slider,options,
            "How much this source counts compared with the others (0 to 100). This is not a confidence score.")
        if sliderInit and sliderInit.SetParentInitializer and checkInit then
            sliderInit:SetParentInitializer(checkInit,function() return LL.db[enabledKey]~=false end)
        end
    end
    if CreateSettingsButtonInitializer and layout and layout.AddInitializer then
        layout:AddInitializer(CreateSettingsButtonInitializer("Reset source weights","Reset",
            function() LL:ResetEvidenceSettings() end,"Turn every source back on with its default weight.",false))
    end
end
function LL:ResetEvidenceSettings()
    for source,d in pairs(LL.SourceDefaults) do
        local on=Settings.GetSetting and Settings.GetSetting("LootLiquidator_source_"..source.."_enabled")
        local weight=Settings.GetSetting and Settings.GetSetting("LootLiquidator_source_"..source.."_weight")
        if on then on:SetValue(d[1]) else LL.db["source_"..source.."_enabled"]=d[1] end
        if weight then weight:SetValue(d[2]) else LL.db["source_"..source.."_weight"]=d[2] end
    end
    if LL.Invalidate then LL:Invalidate("evidence") end
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

-- B6a: recorded-results buttons. Confirmations use Blizzard's StaticPopup.
local function Notify(message)
    if print and message then print("|cff66ccffLoot Liquidator|r: "..message) end
end
function LL:ShowRecordedResultsExport()
    if not self.ExportRecordedResultsPage then return end
    local title,text=self:ExportRecordedResultsPage()
    if self.ShowCopy then self:ShowCopy(title,text) end
end
local function Confirm(key,text,accept)
    if not StaticPopupDialogs or not StaticPopup_Show then accept();return end
    StaticPopupDialogs[key]=StaticPopupDialogs[key] or {
        text=text,button1=YES or "Yes",button2=NO or "No",
        timeout=0,whileDead=true,hideOnEscape=true,preferredIndex=3}
    StaticPopupDialogs[key].OnAccept=accept
    StaticPopup_Show(key)
end
function LL:ConfirmResetRecordedResults()
    local n=self.RecordedResultsCount and self:RecordedResultsCount() or 0
    Confirm("LOOTLIQUIDATOR_RESET_RESULTS",
        "Reset all recorded results?\n\nThe previous set is kept as one backup until the next reset.",
        function()
            local _,message=LL:ResetRecordedResults()
            Notify(message)
        end)
    return n
end
function LL:ConfirmStartNewBatch()
    Confirm("LOOTLIQUIDATOR_NEW_BATCH","Start a new batch of recorded results?",function()
        local _,message=LL:StartNewBatch()
        Notify(message)
    end)
end
-- B7: paste another player's exported results into a standard StaticPopup.
local function PopupEditBox(popup) return popup and ((popup.GetEditBox and popup:GetEditBox()) or popup.editBox or popup.EditBox) end
local function RunImport(text)
    local _,message=LL:ImportRecordedResults(text)
    Notify(message)
end
LL.RunImportFromPopup=RunImport
function LL:ShowImportResultsDialog()
    if not StaticPopupDialogs or not StaticPopup_Show then return false end
    StaticPopupDialogs.LOOTLIQUIDATOR_IMPORT_RESULTS=StaticPopupDialogs.LOOTLIQUIDATOR_IMPORT_RESULTS or {
        text="Import results from another player\n\nPaste the text from their Export button (one page at a time), then click Import.",
        button1="Import",button2=CANCEL or "Cancel",hasEditBox=true,editBoxWidth=350,maxLetters=0,maxBytes=0,
        timeout=0,whileDead=true,hideOnEscape=true,preferredIndex=3,
        OnShow=function(popup) local box=PopupEditBox(popup);if box then box:SetText("");box:SetFocus() end end,
        OnAccept=function(popup) local box=PopupEditBox(popup);RunImport(box and box:GetText() or "") end,
        EditBoxOnEnterPressed=function(box)
            local popup=box:GetParent();RunImport(box:GetText());if popup then popup:Hide() end
        end,
        EditBoxOnEscapePressed=function(box) local popup=box:GetParent();if popup then popup:Hide() end end}
    StaticPopup_Show("LOOTLIQUIDATOR_IMPORT_RESULTS")
    return true
end
function LL:ConfirmClearImportedResults()
    Confirm("LOOTLIQUIDATOR_CLEAR_IMPORTED","Remove all imported results?\n\nYour own recorded results are not touched.",function()
        local _,message=LL:ClearImportedResults()
        Notify(message)
    end)
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

    -- B8a: native vertical page (was a hand-placed canvas).
    local appearance,appearanceLayout=Settings.RegisterVerticalLayoutSubcategory(general,"Badges & Colors")
    Settings.RegisterAddOnCategory(appearance)
    self:AddBadgeSettings(appearance,appearanceLayout)

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

    -- B5b: the alts table is gone. Alts count automatically (the "Include
    -- alts" switch and the transfer rule); "Show rates for" on the General
    -- page picks whose skill is used. What-if profiles live under this page.
    local chars,charsLayout=Settings.RegisterVerticalLayoutSubcategory(general,"Professions (what-if)")
    if chars then
        Settings.RegisterAddOnCategory(chars)
        Section(charsLayout,"Your characters' professions are read automatically when you log into them.")
        Section(charsLayout,"To try a different skill or specialization, pick a profession on the left, set it up, then choose \"What-if profile\" under \"Show rates for\" on the main page.")
        for _,profession in ipairs({"Alchemy","Blacksmithing","Enchanting","Engineering","Herbalism",
            "Inscription","Jewelcrafting","Leatherworking","Mining","Skinning","Tailoring","Cooking","Fishing"}) do
            local page=Settings.RegisterCanvasLayoutSubcategory(chars,self:CreateProfessionProfilePanel(profession),profession)
            Settings.RegisterAddOnCategory(page)
        end
    end
    -- B8b: native vertical page (was a hand-placed canvas).
    local accuracy,accuracyLayout=Settings.RegisterVerticalLayoutSubcategory(general,"Database & Accuracy")
    Settings.RegisterAddOnCategory(accuracy)
    self:AddEvidenceSettings(accuracy,accuracyLayout)
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
        "Record isolated completed crafts with measured inputs, outputs and profession context. Unresolved results never become zero samples. Use the Export button below; nothing is sent anywhere automatically.",true)
    Checkbox(research,"showProcessingSamples","Show sample counts in tooltips",
        "Show how many personal observations are available. Full distributions also require Detailed tooltips.",true)
    -- B6a: buttons instead of slash commands for recorded results.
    if CreateSettingsButtonInitializer and researchLayout and researchLayout.AddInitializer then
        researchLayout:AddInitializer(CreateSettingsButtonInitializer(
            "Export recorded results","Export",function() LL:ShowRecordedResultsExport() end,
            "Opens your recorded results as text to copy (Ctrl+C). Long lists come in pages: click again for the next page.",false))
        researchLayout:AddInitializer(CreateSettingsButtonInitializer(
            "Start new batch","Start new batch",function() LL:ConfirmStartNewBatch() end,
            "Count the next results you record as a new group, e.g. after changing gear or specialization.",false))
        researchLayout:AddInitializer(CreateSettingsButtonInitializer(
            "Reset recorded results","Reset",function() LL:ConfirmResetRecordedResults() end,
            "Clear your recorded results so estimates use only the built-in database. Asks first; the previous set is kept as one backup.",false))
        -- B7: import another player's export as a separate source.
        researchLayout:AddInitializer(CreateSettingsButtonInitializer(
            "Import results","Import",function() LL:ShowImportResultsDialog() end,
            "Paste results another player exported. They are checked for damaged or impossible values and kept separate from your own results, with their own confidence (weight: Database & Accuracy > Imported results).",false))
        researchLayout:AddInitializer(CreateSettingsButtonInitializer(
            "Remove imported results","Remove",function() LL:ConfirmClearImportedResults() end,
            "Remove everything you imported. Your own recorded results are not touched. Asks first.",false))
    end
    Section(researchLayout,"Evidence collection")
    Section(researchLayout,"Source preferences live in Database & Accuracy. What-if profession profiles live under Professions (what-if).")
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
            end,"Copy direct equipment token relationships. Additional pages: /ll debug tokenexport 2 (etc.).",false))
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
            end,"Export candidates, metadata and collection limits. Additional pages: /ll debug attexport 2. Status: /ll debug tokenmigration. No automatic approval.",false))
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
