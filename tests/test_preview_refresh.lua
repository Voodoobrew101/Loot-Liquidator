-- Use the real preview builder, painter and asynchronous bag refresh queue.
local frames,timers={},{}
local function frame()
    local w={scripts={},shown=true}
    local noop=function()end
    for _,key in ipairs({'SetSize','SetPoint','SetAllPoints','SetTexture','SetParent',
        'SetFont','ClearAllPoints','SetTextColor','RegisterEvent'}) do w[key]=noop end
    function w:SetText(text)self.text=text end
    function w:Show()self.shown=true end
    function w:Hide()self.shown=false end
    function w:SetScript(event,fn)self.scripts[event]=fn end
    function w:HookScript(event,fn)self.scripts[event]=fn end
    function w:CreateFontString()return frame()end
    function w:CreateTexture()return frame()end
    frames[#frames+1]=w
    return w
end
CreateFrame=frame
C_Timer={After=function(_,fn)timers[#timers+1]=fn end}
local LL={db={tooltipDetail=3,showBadges=true},AHFeeRate=function()return .05 end}
assert(loadfile('LootLiquidator/ItemDBRuntime.lua'))('LL',LL)
assert(loadfile('LootLiquidator/Badges.lua'))('LL',LL)
assert(loadfile('LootLiquidator/Settings.lua'))('LL',LL)
LL.CreateSettingsButton=function()return frame()end
LL.Invalidate=function(self)self:RequestBadgeRefresh()end
local evaluations={}
LL.Evaluate=function(_,link)
    evaluations[#evaluations+1]=link
    if link:find('preview:',1,true) then return nil end
    return {action='V',facts={}}
end
local host=frame()
LootLiquidator_InitTooltipPreview(host)
local panel=host.llPreview
LL:RefreshPreviews()
local sample
for _,w in ipairs(frames) do
    if w.laDecision and w.laDecision.itemID then sample=w end
end
assert(sample and sample.laLetter.shown and sample.laLetter.text=='A')
local itemID=sample.laDecision.itemID
local bag=frame()
LL:Paint(bag,'item:123',{action='V',facts={}})
local function drain()
    while #timers>0 do local fn=table.remove(timers,1);fn() end
end
for i=1,6 do
    LL.db.tooltipHeaderPrice=i%2==0
    LL:UpdateAllAppearance()
    assert(sample.laDecision.itemID==itemID and sample.laLetter.shown,'sample survives immediate refresh')
    drain()
    assert(sample.laDecision.itemID==itemID and sample.laLetter.shown and sample.laLetter.text=='A',
        'delayed bag jobs must not hide or change sample')
    assert(bag.laLetter.shown and bag.laLetter.text=='V','real bag refresh still works')
end
assert(#evaluations==6,'only the real bag item is re-evaluated')
for _,link in ipairs(evaluations) do assert(link=='item:123') end
LL.db.showBadges=false;LL:UpdateAllAppearance();drain()
assert(not sample.laLetter.shown,'sample respects disabled badges')
LL.db.showBadges=true;LL:UpdateAllAppearance();drain()
assert(sample.laLetter.shown,'sample restores without Next sample item')
local nextButton
for _,w in ipairs(frames) do if w.text=='Next sample item' then nextButton=w end end
assert(nextButton);nextButton.scripts.OnClick()
assert(sample.laDecision.itemID~=itemID and sample.laLetter.shown,'cycling samples still works')
print('PASS: header-price toggles preserve preview badge through delayed refresh; real bags, badge toggle and sample cycling work')
