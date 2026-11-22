-- Real compiled Prospect source; only game identity/access/price APIs are stubbed.
-- Repeated stack moves/count changes must not retain expired full quote graphs.
local now=100
GetTime=function()return now end;time=GetTime
GetBuildInfo=function()return'12.1.5','70961','',120105 end
CreateFrame=function()return{RegisterEvent=function()end,SetScript=function()end}end
SlashCmdList={};GetItemInfo=function(id)return'Item '..id end
GetItemCount=function()return 100000 end
wipe=function(t)for k in pairs(t)do t[k]=nil end return t end
local LL={}
for line in io.lines('LootLiquidator/LootLiquidator.toc')do
    if line:match('%.lua$')then assert(loadfile('LootLiquidator/'..line))('LootLiquidator',LL)end
end
LL.db={enabled=true,characters={Player={professions={Jewelcrafting=true}}},rateProfile=3,
    rateProfileCharacter='Player',source_personal_enabled=false,source_imported_enabled=false}
LL.CharacterKey=function()return'Player'end
LL.GetResearchProfessionSnapshot=function()return 0,'none',7946 end
LL.GetCachedOperationInfo=function()end
LL.GetOutputPrice=function()return 100 end -- Deterministic fixture prices, not game quotes.
LL:MigrateEvidenceSettings();assert(LL:InitializeItemDB(),LL.itemDBError)
assert(LL:SetManualProfessionProfile('Player','Jewelcrafting',9,
    {enabled=true,skill=100,specialization='none',buffs={}}))
LL.DisenchantEligibility=function()return false end;LL.EligibleDisenchant=function()return false end
LL.TokenInfo=function()end;LL.AppearanceCollectionState=nil
LL.AuctionEligible=function()return false end;LL.IsNonAuctionableByBinding=function()return true end
LL.Price=function()end;LL.ReportMissing=function()end
LL.GetItemFacts=function(self,link,context)
    return {id=190394,link=link,name='Draconium',classID=7,subClassID=7,expansionID=9,
        quality=1,reagentQuality=3,count=context.count,tsmString='i:190394',context=context,vendor=1}
end
LL.BestConversion=function(self,f)
    local option={name='Prospect',letter='P',recipeID=374627,inputCount=5,
        profession='Jewelcrafting',available=true}
    local model=self:ResolveEvidenceModel(f,option,nil,1)
    option.yieldModel=model;option.materials=model and model.materials
    option.value=model and self:ValueProcessingModel(model,0,true,f)
    f.conversionOptions={option}
    return option
end
local function memory()collectgarbage('collect');return collectgarbage('count')end
local start=memory()
local firstValue,firstMeans
for i=1,192 do
    now=now+6
    local result=assert(LL:Evaluate('item:190394',
        {count=5+math.floor((i-1)/40),bagID=math.floor((i-1)/40)%5,slotID=(i-1)%40+1}))
    local model=assert(result.conversionOptions[1].yieldModel)
    assert(#model.materials>1,'Actual multi-output source must reach the decision')
    if not firstMeans then
        firstValue=result.converted;firstMeans={}
        for _,m in ipairs(model.materials)do if type(m.expectedQuantity)=='number'then firstMeans[m.id]=m.expectedQuantity end end
    end
    assert(type(result.converted)=='number'and math.abs(result.converted-firstValue)<1e-9,
        'Cache expiry must preserve per-item value')
    for _,m in ipairs(model.materials)do
        if type(m.expectedQuantity)=='number'then
            assert(firstMeans[m.id]and math.abs(m.expectedQuantity-firstMeans[m.id])<1e-9,
                'Cache expiry must preserve compiled material means')
        end
    end
    if i%32==0 then
        assert(memory()-start<8192,'Expired real processing decisions retained more than 8 MiB')
    end
end
local retained=memory()-start
LL:Invalidate()
assert(memory()-start<1024,'Invalidation must release runtime quote graphs')

-- Rapid bag repaint requests can all fit within the expiry window. Their
-- decisions still need a finite cap, while repeated identical requests reuse.
now=now+1
local firstRapid=LL:Evaluate('item:190394',{count=5,bagID=0,slotID=1})
assert(LL:Evaluate('item:190394',{count=5,bagID=0,slotID=1})==firstRapid,
    'A current identical decision should be reused')
for i=2,256 do
    now=now+0.001
    LL:Evaluate('item:190394',
        {count=5+math.floor((i-1)/200),bagID=math.floor((i-1)/40)%5,slotID=(i-1)%40+1})
end
assert(LL:Evaluate('item:190394',{count=5,bagID=0,slotID=1})==firstRapid,
    'A full decision cache must preserve current hits, including the oldest')
for i=257,300 do
    now=now+0.001
    LL:Evaluate('item:190394',
        {count=5+math.floor((i-1)/200),bagID=math.floor((i-1)/40)%5,slotID=(i-1)%40+1})
end
assert(LL:Evaluate('item:190394',{count=5,bagID=0,slotID=1})~=firstRapid,
    'Rapid distinct decisions must evict the oldest entry before expiry')
LL:Invalidate()
assert(memory()-start<1024,'Invalidation must release rapidly cached decisions')
print(('PASS: 192 actual-source stack/slot changes retain %.1f KiB; means/value unchanged; expiry, cap, and invalidation release quotes'):format(retained))
