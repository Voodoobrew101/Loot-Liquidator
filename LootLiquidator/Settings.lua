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
        local initializer=CreateSettingsListSectionHeaderInitializer(title)
        local initFrame=initializer.InitFrame
        initializer.InitFrame=function(self,frame,...)
            initFrame(self,frame,...)
            -- Native headers install a title-only tooltip across the whole row.
            -- These headings are labels; keep hover help on actual controls.
            -- Native Init restores its own tooltip when a pooled row is reused.
            frame:SetTooltipFunc(nil)
        end
        layout:AddInitializer(initializer)
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
-- Curated, complete ItemDB studies; prices alone are illustrative. Copy fields
-- into preview rows so previews never mutate research records or saved data.
local PREVIEW_ITEMS = {}
for _,sample in ipairs({
    {id=2447,name="Peacebloom",method="Mill",action="A",auction=20000,value=16200},
    {id=765,name="Silverleaf",method="Mill",action="M",auction=12000,value=18000},
    {id=239671,method="Disenchant",action="D",value=480000},
    {id=239675,method="Disenchant",action="D",value=520000},
    {id=258920,method="Disenchant",action="D",value=360000},
}) do
    for _,record in ipairs(LL.ItemDB and LL.ItemDB.processing or {}) do
        if record.recordID==("evidence:v3:%s:%d:x%d"):format(sample.method,sample.id,
            sample.method=="Mill" and 5 or 1) then
            local outputs,confidence={},100
            local complete=#(record.materials or {})>0
            for _,material in ipairs(record.materials or {}) do
                local output={id=material.id,priceWeight=1}
                for target,source in pairs({chance="dropChance",expectedQuantity="expectedQuantity",
                    minQuantity="minQuantity",maxQuantity="maxQuantity"}) do
                    local field=material[source]
                    if type(field)~="table" or type(field.value)~="number"
                        or (field.confidence or 0)<85 then complete=false;break end
                    output[target]=field.value
                    output.confidence=math.min(output.confidence or 100,field.confidence)
                end
                confidence=math.min(confidence,output.confidence or 0)
                outputs[#outputs+1]=output
            end
            if complete then
                PREVIEW_ITEMS[#PREVIEW_ITEMS+1]={name="Sample "..(sample.name or ("item "..sample.id)),
                    itemID=sample.id,action=sample.action,count=record.inputCount,
                    auction=sample.auction,convert=sample.value,vendor=100,
                    method=sample.method,letter=sample.method=="Mill" and "M" or "D",
                    inputCount=record.inputCount,outputs=outputs,confidence=confidence,
                    source=record.recordID}
            end
            break
        end
    end
end
local function SampleDecision(row)
    local options={{name=row.method,letter=row.letter,available=true,value=row.convert,
        confidence=row.confidence,source=row.source,inputCount=row.inputCount}}
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
            confidence=material.confidence,unitPrice=price,expectedValue=price*material.expectedQuantity,
            netExpectedValue=price*material.expectedQuantity*(1-fee),
            illustrative=true}
    end
    options[1].yieldModel={confidence=row.confidence,inputCount=row.inputCount,
        note="ItemDB study yields; illustrative prices only",materials=outputs}
    return {action=row.action,method=row.method,conversion=options[1],
        conversionOptions=options,converted=row.convert,itemID=row.itemID,count=row.count,
        rawAuction=row.auction,netAuction=row.auction and row.auction*(1-fee) or 0,
        vendor=row.vendor,auctionEligible=row.auction~=nil,facts={name=row.name},
        isBound=row.auction==nil}
end
PreviewPanel=function()
    local panel=CreateFrame("Frame")
    panel:SetSize(560,90)
    if #PREVIEW_ITEMS==0 then return panel end
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
        local itemName=C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(row.itemID)
        name:SetText(itemName and ("Sample "..itemName) or row.name)
        local levels={[0]="Off",[1]="Recommendation",[2]="Alternatives",[3]="Breakdown"}
        indicator:SetText("Preview only | "..(levels[LL.db.tooltipDetail or 2] or "Alternatives").." | "..
            (LL.db.tooltipShowAfterAHCut~=false and "AH net" or "AH listing"))
        -- This illustrative decision has no live item link. Do not register
        -- the sample with the asynchronous bag refresh/evaluation queue.
        LL:Paint(icon,nil,SampleDecision(row))
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
    imported="Imported results",legacy="Old disenchant estimates",reference="Reference tables and calculators"}
local SOURCE_DESCRIPTIONS={itemdb="The addon's own research database, including rough estimates (shown with lower confidence).",
    personal="Results you recorded yourself. They take over as you record more.",
    imported="Results pasted in from other players (Processing Research > Import). Kept separate from your own.",
    legacy="Older disenchant tables. Counted weakly; never treated as exact.",
    reference="Historical Retail conversion tables and sourced calculator estimates. Fill missing fields at lower confidence; do not replace usable research or recorded results. Auction prices still refresh separately."}
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
    local panel=CreateFrame('Frame')
    local scroll=CreateFrame('ScrollFrame',nil,panel,'UIPanelScrollFrameTemplate')
    scroll:SetPoint('TOPLEFT',panel,'TOPLEFT',0,0)
    scroll:SetPoint('BOTTOMRIGHT',panel,'BOTTOMRIGHT',-28,0)
    local body=CreateFrame('Frame',nil,scroll)
    body:SetWidth(640);scroll:SetScrollChild(body)
    local current=LL:CharacterKey() or 'Current character'
    local selection=LL.db.professionTooltipProfiles and LL.db.professionTooltipProfiles[profession]
    local selected=selection and selection:sub(1,1)~='@' and selection or current
    local expansion=(GetExpansionLevel and GetExpansionLevel()) or 11
    local options={nodes={},buffs={}}
    local treeRows,nodeRows,buffRows,statRows={},{},{},{}
    local advancedOpen=false
    local controlSupport={nodes={},stats={},buffs={}}
    local visible={}
    local refreshing=false
    local refresh
    local function place(w,y,x)
        visible[w]=true
        w:ClearAllPoints();w:SetPoint('TOPLEFT',body,'TOPLEFT',x or 16,-y);w:Show()
    end
    local function label(text,width)
        local w=body:CreateFontString(nil,'ARTWORK','GameFontHighlight')
        w:SetWidth(width or 590);w:SetJustifyH('LEFT');w:SetText(text);return w
    end
    local function button(text,click)
        local w=LL:CreateSettingsButton(body);w:SetSize(590,26);w:SetText(text)
        w:SetScript('OnClick',click);return w
    end
    local function hover(w,lines)
        w:SetScript('OnEnter',function(self)
            if not GameTooltip then return end
            GameTooltip:SetOwner(self,'ANCHOR_RIGHT');GameTooltip:ClearLines()
            for _,text in ipairs(lines()) do GameTooltip:AddLine(text,1,1,1,true) end
            GameTooltip:Show()
        end)
        w:SetScript('OnLeave',function()if GameTooltip then GameTooltip:Hide() end end)
    end
    local function profile() return LL:GetManualProfessionProfile(current,profession,expansion) or {} end
    local function minimum()
        LL:SetManualProfessionProfile(current,profession,expansion,
            {enabled=true,skill=0,specialization='none',buffs={}})
    end
    local function useSimulation()
        selection='@hypothetical';selected=current
        LL.db.professionTooltipProfiles=LL.db.professionTooltipProfiles or {}
        LL.db.professionTooltipProfiles[profession]=selection
    end
    local function update(change)
        if refreshing then return end
        useSimulation()
        local p={} for k,v in pairs(profile()) do p[k]=v end
        p.enabled=true;p.skill=p.skill or 0;p.specialization=p.specialization or 'none'
        p.buffs={} for k,v in pairs(profile().buffs or {}) do p.buffs[k]=v end
        change(p)
        local points={} for id,n in (p.specialization or ''):gmatch('(%d+)=(%d+)') do points[id]=tonumber(n) end
        local adjusted=false
        for _=1,#options.nodes do
            local changed=false
            for _,n in ipairs(options.nodes) do
                if (points[tostring(n.id)] or 0)>0 and LL:ProfessionNodeRequirements(n,points,p.skill)==false then
                    points[tostring(n.id)]=0;changed=true;adjusted=true
                end
            end
            if not changed then break end
        end
        if adjusted then
            local parts={} for id,n in pairs(points) do if n>0 then parts[#parts+1]=id..'='..n end end
            table.sort(parts);p.specialization=#parts>0 and table.concat(parts,',') or 'none'
        end
        LL:SetManualProfessionProfile(current,profession,expansion,p)
        LL:UpdateAllAppearance();refresh(false)
    end
    local function choices(rows)
        local c=Settings.CreateControlTextContainer()
        for _,r in ipairs(rows) do c:Add(r[1],r[2],r[3] or '') end
        return c:GetData()
    end
    local title=label(profession..' — tooltip results')
    local intro=label('Choose a character, Simulated results, or Don\'t show. Only modifiers with researched output calculations are shown.')
    local character=LL:CreateSettingsDropdown(body,function()
        local keys={} for k in pairs(LL.db.characters or {}) do keys[#keys+1]=k end
        table.sort(keys);panel.characterKeys=keys
        local rows={{0,"Don't show"},{-1,'Simulated'},{-2,'Automatic — available characters'}}
        for i,k in ipairs(keys) do rows[#rows+1]={i,k} end
        return choices(rows)
    end,function()
        if not selection or selection=='@auto' then return -2 end
        if selection=='@hide' then return 0 end
        if selection=='@hypothetical' then return -1 end
        for i,k in ipairs(panel.characterKeys or {}) do if k==selected then return i end end
        return 0
    end,function(i)
        selection=i==0 and '@hide' or i==-1 and '@hypothetical' or i==-2 and '@auto' or (panel.characterKeys or {})[i]
        if not selection then return end
        selected=selection:sub(1,1)=='@' and current or selection
        LL.db.professionTooltipProfiles=LL.db.professionTooltipProfiles or {}
        LL.db.professionTooltipProfiles[profession]=selection
        if selection=='@hypothetical' then
            local saved=LL:GetManualProfessionProfile(current,profession,expansion)
            if saved then
                saved.enabled=true
                LL:SetManualProfessionProfile(current,profession,expansion,saved)
            else minimum() end
        end
        LL:UpdateAllAppearance();refresh(true)
    end)
    local era=LL:CreateSettingsDropdown(body,function()
        local rows={} for id=0,11 do rows[#rows+1]={id,LL:ProfessionExpansionName(id)} end
        return choices(rows)
    end,function()return expansion end,function(id)
        expansion=id
        if selection=='@hypothetical' and not LL:GetManualProfessionProfile(current,profession,expansion) then minimum() end
        refresh(true)
    end)
    local status=label('')
    local skillLabel=label('Skill before specialization',245)
    local skill=LL:CreateSettingsCanvasSlider(body,0,300,1,0,function(v)update(function(p)p.skill=v end)end)
    skill.expandRange=true
    hover(skill.slider,function()
        return {'Profession skill before specialization bonuses','Named specialization points add their researched skill bonuses for the selected operation. Zero is the editor minimum, not proof that a recipe is usable.',
            'The resulting effective skill changes quantities or quality when a compatible researched formula is available.'}
    end)
    local reset=button('Reset to minimum',function()useSimulation();minimum();LL:UpdateAllAppearance();refresh(false)end)
    local scan=button('Refresh specialization choices from current profession',function()
        LL:GetResearchProfessionSnapshot({expansionID=expansion},profession);refresh(true)
    end)
    local empty=label('No calculated output modifiers are available for this profession and expansion yet. Saved choices are retained for future research.')
    local advanced=button('Advanced',function()advancedOpen=not advancedOpen;refresh(false)end)
    local buffsTitle=label('Buffs')
    local noBuffs=label('No captured buffs. Open this profession on the character to refresh available choices.')
    local statsTitle=label('Profession / crafting stats')
    local statsNote=label('Whole-number simulation controls. Ratings and percentages are separate. Slider ranges are editing spans, not game caps; saved values above a span are retained.')
    local scannedStats=label('')
    local note=label('Controls return as supported calculations are added. Simulated choices never change your actual character.')
    local function ranks()
        local out={} for id,n in (profile().specialization or ''):gmatch('(%d+)=(%d+)') do out[id]=tonumber(n) end
        return out
    end
    local function setRank(id,value)
        local all=ranks();all[tostring(id)]=value
        for _,n in ipairs(options.nodes) do
            if n.id==id and value>0 and LL:ProfessionNodeRequirements(n,all,profile().skill)==false then refresh(false);return end
        end
        -- Removing a prerequisite must not leave a known-invalid descendant.
        for _=1,#options.nodes do
            local changed=false
            for _,n in ipairs(options.nodes) do
                if (all[tostring(n.id)] or 0)>0 and LL:ProfessionNodeRequirements(n,all,profile().skill)==false then
                    all[tostring(n.id)]=0;changed=true
                end
            end
            if not changed then break end
        end
        local parts={} for key,n in pairs(all) do parts[#parts+1]=key..'='..n end
        table.sort(parts)
        update(function(p)p.specialization=table.concat(parts,',') end)
    end
    refresh=function(reload)
        refreshing=true
        if reload then options=LL:GetProfessionUIOptions(selected,profession,expansion) end
        controlSupport=LL.GetProfessionSimulationControlSupport
            and LL:GetProfessionSimulationControlSupport(profession,expansion,options.nodes)
            or {nodes={},stats={},buffs={}}
        controlSupport.nodes=controlSupport.nodes or {}
        controlSupport.stats=controlSupport.stats or {}
        controlSupport.buffs=controlSupport.buffs or {}
        -- Hiding an active native slider cancels its mouse drag. Lay out the
        -- controls first, then hide only those no longer used on this page.
        visible={}
        place(title,16);place(intro,46);place(character,96);place(era,96,326);place(status,138)
        local y=200
        if selection~='@hide' then
            advanced:SetText(advancedOpen and 'Hide advanced' or 'Advanced')
            place(advanced,y);y=y+38
        end
        if selection~='@hide' then
            status:SetText(selection=='@hypothetical'
                and 'Simulated profile. Only modifiers with researched output effects are available.'
                or 'Uses scanned character data. Advanced shows researched modifiers; editing switches to Simulated.')
            if advancedOpen then
            if controlSupport.skill then
                skill:SetPreferenceValue(profile().skill or 0)
                place(skillLabel,y+6);place(skill,y,270);y=y+44
            end
            local supportedNodes,displayNodes,byID={},{},{}
            for _,n in ipairs(options.nodes) do
                byID[n.id]=n
                if controlSupport.nodes[tostring(n.id)] or controlSupport.nodes[n.id] then
                    supportedNodes[n.id]=true;displayNodes[n.id]=true
                end
            end
            -- Keep the tree's useful headings, without retaining an inactive
            -- slider merely because it is an ancestor in the catalog.
            for id in pairs(supportedNodes) do
                local parent=byID[id] and byID[id].parentID
                local seen={}
                while parent and byID[parent] and not seen[parent] do
                    seen[parent]=true;displayNodes[parent]=true;parent=byID[parent].parentID
                end
            end
            local supportedStats,supportedBuffs={},{}
            for _,stat in ipairs(LL:ProfessionSimulationStatOptions(profession)) do
                local fields=controlSupport.stats[stat.key]
                if type(fields)=='table' and (fields.rating or fields.percent) then
                    supportedStats[#supportedStats+1]={stat=stat,fields=fields}
                end
            end
            for _,b in ipairs(options.buffs) do
                if controlSupport.buffs[tostring(b.id)] or controlSupport.buffs[b.id] then supportedBuffs[#supportedBuffs+1]=b end
            end
            local anyControls=controlSupport.skill or next(supportedNodes) or #supportedStats>0 or #supportedBuffs>0
            if anyControls then place(reset,y);y=y+40
            else place(empty,y);y=y+68 end
            local groups,order={},{}
            for _,n in ipairs(options.nodes) do
                if displayNodes[n.id] then
                    local tree=n.tab or profession
                    if not groups[tree] then groups[tree]={};order[#order+1]=tree end
                    groups[tree][#groups[tree]+1]=n
                end
            end
            local points=ranks()
            local function renderNode(n,nodes,depth,visited)
                if visited[n.id] then return end
                visited[n.id]=true
                local key=expansion..':'..n.id
                if not nodeRows[key] then
                    nodeRows[key]={label=label(n.name,220)}
                end
                local row=nodeRows[key]
                if supportedNodes[n.id] then
                    if not row.slider then
                        local id=n.id
                        row.slider=LL:CreateSettingsCanvasSlider(body,0,n.maxRank,1,0,function(v)setRank(id,v)end)
                    end
                    hover(row.slider.slider,function()
                        local lines=LL:ProfessionNodeTooltip(n,ranks()[tostring(n.id)] or 0,ranks(),profile().skill)
                        local effects=controlSupport.nodeEffects and controlSupport.nodeEffects[tostring(n.id)] or {}
                        for _,rule in ipairs(LL.ItemDB and LL.ItemDB.specializationRules or {}) do
                            local supported=false
                            for _,id in ipairs(effects) do if id==rule.ruleID then supported=true end end
                            if supported and rule.kind=='reference-context' then
                                local required={}
                                for id,points in pairs(rule.requiredNodes or {}) do
                                    local name='Specialization'
                                    for _,node in ipairs(options.nodes) do if tostring(node.id)==tostring(id) then name=node.name;break end end
                                    required[#required+1]=name..': '..points..' points'
                                end
                                table.sort(required)
                                lines[#lines+1]='Calculated yield reference requires '..table.concat(required,', ')..'.'
                            end
                        end
                        if controlSupport.dependencyNodes and controlSupport.dependencyNodes[tostring(n.id)] then
                            lines[#lines+1]='These points unlock a specialization with a researched output effect.'
                        end
                        return lines
                    end)
                    local allowed,why=LL:ProfessionNodeRequirements(n,points,profile().skill)
                    row.label:SetText(n.name..' ('..n.maxRank..' points)'..(allowed==false and ' — locked' or allowed==nil and ' — requirements unknown' or ''))
                    row.slider:SetPreferenceValue(points[tostring(n.id)] or 0)
                    row.slider.slider:SetEnabled(allowed~=false)
                    place(row.label,y+5,28+math.min(depth,4)*12);place(row.slider,y,270+math.min(depth,4)*8)
                    y=y+math.max(48,(row.label.GetStringHeight and row.label:GetStringHeight() or 0)+16)
                else
                    row.label:SetText(n.name)
                    place(row.label,y+5,28+math.min(depth,4)*12);y=y+32
                end
                local children={}
                for _,child in ipairs(nodes) do if child.parentID==n.id then children[#children+1]=child end end
                for _,child in ipairs(children) do renderNode(child,nodes,depth+1,visited) end
            end
            for _,tree in ipairs(order) do
                if not treeRows[tree] then
                    treeRows[tree]=label(tree)
                end
                treeRows[tree]:SetText(tree)
                place(treeRows[tree],y);y=y+38
                do
                    local ids={} for _,n in ipairs(groups[tree]) do ids[n.id]=true end
                    local visited={}
                    for _,n in ipairs(groups[tree]) do
                        if not n.parentID or not ids[n.parentID] then renderNode(n,groups[tree],0,visited) end
                    end
                end
            end
            if #supportedStats>0 then
                place(statsTitle,y);y=y+30
                place(statsNote,y);y=y+60
                for _,entry in ipairs(supportedStats) do
                    local stat,fields=entry.stat,entry.fields
                    if not statRows[stat.key] then
                        statRows[stat.key]={}
                    end
                    local row=statRows[stat.key]
                    local key=stat.key
                    local function set(field,v)
                        update(function(p)
                            local stats={} for k,entry in pairs(p.stats or {}) do stats[k]={rating=entry.rating,percent=entry.percent} end
                            stats[key]=stats[key] or {};stats[key][field]=v;p.stats=stats
                        end)
                    end
                    local chance=LL:IsProfessionChanceStat(key)
                    if fields.rating and not row.rating then
                        row.rating=LL:CreateSettingsCanvasSlider(body,0,1000,1,0,function(v)set('rating',v)end)
                        row.rating.expandRange=true;row.label=label(stat.name..' rating',245)
                    end
                    if fields.percent and not row.percent then
                        row.percent=LL:CreateSettingsCanvasSlider(body,0,chance and 100 or 200,1,0,function(v)set('percent',v)end)
                        row.percent.expandRange=not chance
                        row.percentLabel=label(stat.name..(chance and ' chance (%)' or ' bonus (%)'),245)
                    end
                    local v=profile().stats and profile().stats[stat.key] or {}
                    if fields.rating then
                        row.rating:SetPreferenceValue(v.rating or 0)
                        place(row.label,y+5);place(row.rating,y,270);y=y+44
                    end
                    if fields.percent then
                        row.percent:SetPreferenceValue(v.percent or 0)
                        place(row.percentLabel,y+5);place(row.percent,y,270);y=y+44
                    end
                end
            end
            if #supportedBuffs>0 then
                place(buffsTitle,y);y=y+30
                for _,b in ipairs(supportedBuffs) do
                    if not buffRows[b.id] then
                        local id=b.id
                        local check=LL:CreateSettingsCheckbox(body)
                        check:SetScript('OnClick',function(self)update(function(p)p.buffs[tostring(id)]=self:GetChecked() and true or nil end)end)
                        buffRows[b.id]={check=check,label=label(b.name,535)}
                    end
                    local row=buffRows[b.id]
                    row.check:SetChecked(profile().buffs and profile().buffs[tostring(b.id)]==true or false)
                    place(row.check,y,28);place(row.label,y+3,64);y=y+34
                end
            end
            place(note,y+8);y=y+64
            end
        elseif selection=='@hide' then status:SetText('Processing results for '..profession..' are hidden from tooltips.')
        end
        if selection~='@hide' then
            if advancedOpen then
                place(scan,y);y=y+40
                local record=LL.db.characters and LL.db.characters[selected]
                local snapshot=record and record.researchProfiles and record.researchProfiles[profession..':'..expansion]
                local text={'Scanned '..selected..' — '..LL:ProfessionExpansionName(expansion)}
                text[#text+1]='Profession skill: '..tostring(snapshot and snapshot.skill or 'not captured')
                local op=options.operation
                if op then
                    text[#text+1]='Last captured base recipe: '..op.recipeID..' (without optional reagent choices)'
                    for _,s in ipairs(op.stats or {}) do
                        text[#text+1]=s.name..': '..tostring(s.rating or '?')..' rating / '..tostring(s.percent or '?')..'%'
                    end
                    if op.upperSkillThreshold and op.upperSkillThreshold>0 then
                        text[#text+1]='Captured base-recipe quality threshold: '..op.upperSkillThreshold..' skill'
                    end
                else text[#text+1]='No recipe stats captured. Open the profession, hover a supported processing item, then refresh.' end
                scannedStats:SetText(table.concat(text,'\n'));place(scannedStats,y);y=y+#text*20+20
            end
        end
        local function hideUnused(w) if w and not visible[w] then w:Hide() end end
        for _,w in pairs(treeRows) do hideUnused(w) end
        for _,row in pairs(nodeRows) do hideUnused(row.label);hideUnused(row.slider) end
        for _,row in pairs(buffRows) do hideUnused(row.check);hideUnused(row.label) end
        for _,row in pairs(statRows) do
            hideUnused(row.label);hideUnused(row.percentLabel);hideUnused(row.rating);hideUnused(row.percent)
        end
        for _,w in ipairs({skillLabel,skill,reset,scan,empty,advanced,buffsTitle,noBuffs,note,statsTitle,statsNote,scannedStats}) do hideUnused(w) end
        body:SetHeight(math.max(y,260))
        character:Refresh();era:Refresh();refreshing=false
    end
    panel:SetScript('OnShow',function()refresh(true)end)
    return panel
end

-- B6a: recorded-results buttons. Confirmations use Blizzard's StaticPopup.
local function Notify(message)
    if print and message then print("|cff66ccffLoot Liquidator|r: "..message) end
end
function LL:ShowRecordedResultsExport()
    if not self.ExportRecordedResultsPage then return end
    -- A recording can finish while this window is open. Freeze one bounded
    -- snapshot so Previous/Next never shift casts between export pages.
    local function snapshot(value)
        if type(value)~='table' then return value end
        local out={} for key,entry in pairs(value) do out[key]=snapshot(entry) end return out
    end
    local proxy=setmetatable({db={craftResearch=snapshot(self.db and self.db.craftResearch)}},{__index=self})
    local function show(page)
        local title,text,current,pages=proxy:ExportRecordedResultsPage(page)
        if self.ShowCopy then self:ShowCopy(title,text,{page=current,pages=pages,onPage=show}) end
    end
    show(1)
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
        out:Add(3,"Simulated profile","Use the simulated skill and specialization saved for the character below (Professions pages).")
        return out:GetData()
    end,"Whose profession skill is used to estimate milling, prospecting, smelting and disenchanting results. This never changes who can actually do it.")
    self:WithoutDropdownSteppers(modeInit)
    local charInit=Settings.CreateDropdown(category,character,function()
        local out=Settings.CreateControlTextContainer()
        for _,row in ipairs(LL:RateProfileCharacterChoices()) do out:Add(row[1],row[2]) end
        return out:GetData()
    end,"The alt (or simulated profile) used when \"Show rates for\" is not \"Me\". Characters appear here after you log into them once.")
    self:WithoutDropdownSteppers(charInit)
    if charInit and charInit.SetParentInitializer then
        charInit:SetParentInitializer(modeInit,function() return (LL.db.rateProfile or 1)~=1 end)
    end
    return modeInit,charInit
end

-- Settings are grouped by user intent, not by the Lua module providing them.
-- Crucially each SavedVariables key is registered exactly once so existing
-- profiles and preferences survive moving a control to another page.
-- Expansion is presentation state for this Settings session, never a tooltip preference.
function LL:AddTooltipAdvancedSettings(category,layout)
    local expanded=false
    local function buttonText() return expanded and "Hide advanced options" or "Show advanced options" end
    local toggle=CreateSettingsButtonInitializer("Advanced",buttonText,function(button)
        expanded=not expanded
        if button then button:SetText(buttonText()) end
        local list=SettingsPanel and SettingsPanel:GetSettingsList()
        if list then list:RepairDisplay(layout) end
    end,"Expand or collapse the three advanced tooltip controls. Their values are preserved.",false)
    layout:AddInitializer(toggle)
    local control=Checkbox(category,"showTooltipExplanations","Show processing explanations",
        "Breakdown level: explain input batches, output ranges and average quantities, and show reference or profession adjustment notes. Hidden by default.",false)
    control:AddShownPredicate(function() return expanded end)
    control=Checkbox(category,"showProfessionDetails","Show profession details",
        "Show profession skill, the character and profile used, profession progression, eligible characters, recipe/unlock eligibility and disenchant candidate notes. Short unavailable indicators remain visible. Hidden by default.",false)
    control:AddShownPredicate(function() return expanded end)
    control=Checkbox(category,"showResearchDetails","Show research notes",
        "For troubleshooting: show fallback and source-conflict explanations, evidence contributions, research casts and material source notes. Short provisional and incomplete-data indicators remain visible.",false)
    control:AddShownPredicate(function() return expanded end)
end

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
    Checkbox(tooltips,"showAverageQuantity","Show average output quantity",
        "Breakdown level: show average units per operation, including zero outcomes. Estimated averages remain estimates. Hidden by default; gold calculations are unchanged.",false)
    Dropdown(tooltips,"tooltipOutputSort","Sort material outputs",
        "Sort breakdown rows before the display limit. Missing values appear last. Gold calculations are unchanged.",
        {{"value","Value — highest first"},{"chance","Drop chance — highest first"},
         {"quantity","Average quantity — highest first"},{"name","Name — A to Z"},
         {"database","Database order"}},"value")
    Checkbox(tooltips,"showMaterialConfidence","Show confidence per material",
        "Breakdown level: add each material's own confidence. The option's overall confidence is always shown.",false)
    Checkbox(tooltips,"showProfessionThresholds","Show known profession breakpoints",
        "Show the next researched skill breakpoint for this exact recipe and item when available. No bonus or threshold is guessed.",true)
    self:AddTooltipAdvancedSettings(tooltips,ttLayout)
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
    -- page picks whose skill is used. Simulated profiles live under this page.
    local chars,charsLayout=Settings.RegisterVerticalLayoutSubcategory(general,"Professions (Simulated)")
    if chars then
        Settings.RegisterAddOnCategory(chars)
        Section(charsLayout,"Your characters' professions are read automatically when you log into them.")
        Section(charsLayout,"Choose a profession, then pick a character, Don't show, or Simulated in its dropdown.")
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
            "Opens your recorded results as text to copy (Ctrl+C). Use Previous and Next in the export window for additional pages.",false))
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
    Section(researchLayout,"Source preferences live in Database & Accuracy. Simulated profession profiles live under Professions (Simulated).")
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
    Section(integrationsLayout,"Independent token research")
    Checkbox(integrations,"collectTokenResearch","Record direct token rewards and exchanges",
        "Passively record item-token vendor offers and directly opened equipment rewards as research candidates. No crafting outputs and no automatic changes to valuations.",true)
    if CreateSettingsButtonInitializer and integrationsLayout.AddInitializer then
        integrationsLayout:AddInitializer(CreateSettingsButtonInitializer(
            "Token research observations","View / copy research export",function()
                if LL.TokenResearchExport and LL.ShowCopy then
                    LL:ShowCopy("Direct token observations - page 1",LL:TokenResearchExport(1))
                end
            end,"Copy direct equipment token relationships. Additional pages: /ll debug tokenexport 2 (etc.).",false))
    end
    TSMDropdown(integrations,"tsmFallbackOperation","TSM operation for ungrouped items")
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
