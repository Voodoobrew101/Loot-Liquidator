-- Real ItemDB -> item facts -> token economics -> decision -> tooltip.
-- Game APIs and prices are controlled; no live-client verification is claimed.
CreateFrame=function()return {RegisterEvent=function()end,SetScript=function()end}end
GetBuildInfo=function()return '12.1.5','123456','',120105 end
GetTime=function()return 100 end
time=function()return 1000 end
SlashCmdList={};WOW_PROJECT_ID=1;WOW_PROJECT_MAINLINE=1
wipe=function(t)for k in pairs(t)do t[k]=nil end return t end
local G=10000
local LL={db={}}
for _,name in ipairs({'ItemDBRuntime.lua','Core.lua','Professions.lua','ProfessionModels.lua',
    'Database.lua','ConversionEngine.lua','Tokens.lua','Badges.lua'}) do
    assert(loadfile('LootLiquidator/'..name))('LootLiquidator',LL)
end
LL.db.enabled=true;LL.db.tooltipDetail=3;LL.db.includeVerifiedAlts=true
LL.db.characters={['Pal-Realm']={class='PALADIN',professions={Enchanting=true},spells={[13262]=true}}}
LL.CharacterKey=function()return 'Pal-Realm'end
LL.ReportMissing=function()end
LL.Price=function()return nil end
LL.ProfessionProgression=function()return {}end
LL.Money=function(_,value)return tostring(value)..' copper'end
LL.MarkupColor=function()return ''end
UnitClass=function()return 'Paladin','PALADIN'end
IsPlayerSpell=function(id)return id==13262 end
local prices,missing,notLoaded={},nil,{}
local items={
    [270913]={name='Venomforged Idol',vendor=0,class=15,bind=1},
    [271457]={name='Warrior Gloves',vendor=46*G,class=4,loc='INVTYPE_HAND'},
    [271466]={name='Paladin Gloves',vendor=44*G,class=4,loc='INVTYPE_HAND'},
    [271475]={name='Death Knight Gloves',vendor=47*G,class=4,loc='INVTYPE_HAND'},
    [900001]={name='Synthetic Exchange',vendor=0,class=15,bind=1},
    [900002]={name='Synthetic Use',vendor=0,class=15,bind=1},
    [900003]={name='Alternative Paladin Reward',vendor=60*G,class=4,loc='INVTYPE_HAND'},
}
local function idOf(value)return tonumber(value) or tonumber(tostring(value):match('item:(%d+)'))end
local queried={}
C_Item={GetItemInfo=function(value)
    queried[#queried+1]=value
    local id=idOf(value);local item=items[id]
    if not item or notLoaded[id] then return nil end
    local vendor=tostring(value):find('exactvariant',1,true) and 55*G or item.vendor
    return item.name,'item:'..id,4,200,1,'Armor','Plate',1,item.loc or '',0,vendor,item.class,4,item.bind or 1,11
end,GetItemInfoInstant=function(value)
    local id=idOf(value);local item=items[id]
    if item then return id,'Armor','Plate',item.loc or '',0,item.class,4 end
end,RequestLoadItemDataByID=function()end}
C_TransmogCollection={GetItemInfo=function(value)local id=idOf(value);return id,id end,
    GetAppearanceSourceInfo=function(id)return {isCollected=id~=missing}end,
    GetAppearanceInfoBySource=function(id)return {appearanceIsCollected=id~=missing,appearanceIsUsable=true}end}
LL.ItemClassMasks={[271457]=1,[271466]=2,[271475]=32,[900003]=2}
LL.GetOutputPrice=function(_,id)return prices[id] or 100000000 end -- synthetic net copper
local balances={[400005]=2}
GetItemCount=function(id)return balances[id] or 0 end
GetMoney=function()return 10000000 end
UnitLevel=function()return 90 end
C_CurrencyInfo={GetCurrencyInfo=function()return {quantity=100}end}
assert(LL:InitializeItemDB(),LL.itemDBError)
local function render(decision)
    local tip={lines={}}
    function tip:AddLine(text)self.lines[#self.lines+1]=text end
    function tip:AddDoubleLine(a,b)self.lines[#self.lines+1]=a..' | '..b end
    LL:AppendRecommendationTooltip(tip,decision)
    return table.concat(tip.lines,'\n')
end
local proofs={}
local function proof(name,decision)
    proofs[#proofs+1]={name=name,action=decision.action,text=render(decision)}
end
local r=assert(LL:Evaluate('item:270913',{count=1,isSoulbound=true}))
assert(r.action=='D' and r.tokenPiece.itemID==271466 and r.tokenPiece.ownClass)
assert(r.tokenPiece.disenchant>44*G and r.tokenPiece.disenchantAvailable)
assert(r.tokenPiece.disenchantConfidence<=r.tokenInfo.catalogConfidence)
local text=render(r)
assert(text:find('Redeemed reward disenchant outputs',1,true) and text:find('copper',1,true),text)
assert(text:find('Base reward estimate',1,true),'base variants must not pretend to be exact')
proof('Midnight token: eligible opener can disenchant',r)
LL.db.characters['Pal-Realm'].professions={};LL._enchantCache=nil
r=LL:Evaluate('item:270913',{isSoulbound=true})
assert(r.action=='V' and r.tokenQuote.value==44*G and not r.tokenPiece.disenchant,
    'non-enchanter still gets the actual own-class reward vendor estimate')
proof('Midnight token: non-enchanter can vendor the reward',r)

local function catalog(id,rewards,kind,costs)
    return {recordID='synthetic:'..id,tokenID=id,gameMode='Retail',kind=kind or 'open',
        requirements={},confidence0to100=60,sourceRevision='synthetic-only',
        patchStartBuild=1,patchEndBuild=2147483647,sourceURLs={'https://example.invalid/synthetic'},
        rewards=rewards,costs=costs,independentReview='NOT_REVIEWED'}
end
local synthetic=catalog(900002,{271466,900003})
LL.ItemDB.tokenRewards[#LL.ItemDB.tokenRewards+1]=synthetic
assert(LL:InitializeItemDB());LL:Invalidate()
r=LL:Evaluate('item:900002',{isSoulbound=true})
assert(r.tokenPiece.vendor==44*G,'unknown loot specialization must not select the highest same-class reward')
synthetic.rewardSelection='choice';LL:Invalidate()
r=LL:Evaluate('item:900002',{isSoulbound=true})
assert(r.tokenPiece.vendor==60*G,'a documented choice may choose the better reward')
synthetic.rewards={271466};synthetic.rewardSelection=nil
synthetic.rewardLinks={['271466']='item:271466:exactvariant'};LL:Invalidate()
r=LL:Evaluate('item:900002',{isSoulbound=true})
assert(r.tokenPiece.vendor==55*G and r.tokenPiece.variantVerified and not r.tokenPiece.variantNote)
assert(r.tokenPiece.link=='item:271466:exactvariant','exact variant survives all valuation queries')
synthetic.rewardLinks=nil

local exchange=catalog(900001,{271466},'exchange',{['271466']={
    {kind='item',id=900001,quantity=2},{kind='item',id=400005,quantity=2},{kind='money',quantity=20000}}})
LL.ItemDB.tokenRewards[#LL.ItemDB.tokenRewards+1]=exchange
prices[400005]=10000
assert(LL:InitializeItemDB());LL:Invalidate()
r=LL:Evaluate('item:900001',{count=2,isSoulbound=true})
assert(r.action=='V' and r.tokenQuote.value==(44*G-40000)/2,'subtract extras and divide by consumed token quantity once')
assert(render(r):find('Exchange, then vendor',1,true),'exchange is not called opening')
proof('Exchange: subtract additional items and money, then normalize by two tokens',r)
balances[400005]=0
r=LL:Evaluate('item:900001',{count=2,isSoulbound=true})
assert(r.action=='Q' and r.tokenQuote.informational and not r.tokenPiece.vendorAvailable,
    'inventory change must invalidate availability immediately, without a stale decision cache')
assert(render(r):find('Additional exchange costs unavailable',1,true))
proof('Exchange: known value with unavailable inventory',r)
exchange.costs={['271466']={{kind='item',id=900001,quantity=1},{kind='currency',id=99,quantity=10}}}
LL:Invalidate()
r=LL:Evaluate('item:900001',{isSoulbound=true})
assert(r.action=='Q' and r.tokenPiece.vendor==nil and r.tokenPiece.vendorGross==44*G,
    'owned currency is not a fabricated zero-copper cost')
assert(render(r):find('before exchange costs',1,true) and render(r):find('no verified gold value',1,true))
proof('Currency exchange: gross reward shown, net value unknown',r)
missing=271466;LL:Invalidate()
r=LL:Evaluate('item:900001',{isSoulbound=true})
assert(r.action=='T','affordable collection can win even when currency opportunity cost is unpriced')
exchange.costsComplete=false;LL:Invalidate()
r=LL:Evaluate('item:900001',{isSoulbound=true})
assert(r.action~='T' and r.action=='Q','unknown full exchange requirements never promise collection or free gear')
missing=nil

LL.ItemClassMasks[900002]=1;LL:Invalidate()
r=LL:Evaluate('item:900002',{isSoulbound=true})
assert(r.action=='Q' and r.tokenQuote.informational and r.tokenPiece.vendor==44*G,
    'wrong-class price stays visible but does not authorize opening')
proof('Wrong-class token: informative price without an opening recommendation',r)
LL.ItemClassMasks[900002]=nil
notLoaded[271466]=true
r=LL:Evaluate('item:900002',{isSoulbound=true})
assert(r.action=='Q')
notLoaded[271466]=nil
r=LL:Evaluate('item:900002',{isSoulbound=true})
assert(r.action=='V','reward prices that finish loading must appear immediately')

LL.db.characters['War-Realm']={class='WARRIOR',professions={Enchanting=true},spells={[13262]=true}}
LL:Invalidate()
r=LL:Evaluate('item:270913',{verifiedWarbound=true,isBound=true})
assert(r.action=='D' and r.tokenPiece.character=='War-Realm' and r.tokenPiece.current==false)
assert(r.why:find('Send to War-Realm',1,true),'alt must be the token opener and disenchanter')
proof('Verified Warbound token: enabled alt opens and disenchants',r)
r=LL:Evaluate('item:270913',{isSoulbound=true})
assert(r.action=='V' and r.tokenPiece.current,'soulbound token cannot borrow another class enchanter')
LL.db.characters['War-Realm'].altMethods={D=false};LL:Invalidate()
r=LL:Evaluate('item:270913',{verifiedWarbound=true,isBound=true})
assert(r.action~='D','disabled alt disenchant stays disabled')

-- Catalog curiosity paths remain informative, including intermediate tokens.
for _,id in ipairs({210947,206046,249367,270909,228819,237602,225634}) do
    local token=LL:TokenInfo({id=id,classID=15,equipLoc=''})
    assert(token and token.kind=='exchange' and token.costsComplete==false,'curio relationship retained: '..id)
    assert(not LL:TokenRedemptionCost({id=id},token,token.rewards[1],true).available)
    for _,reward in ipairs(token.rewards) do assert(not LL._tokenRewardIndex[reward],'intermediate token is resolved to its gear') end
end
local att
for _,record in ipairs(LL.ItemDB.tokenRewards)do if record.tokenID==52027 then att=record end end
assert(att and att.sourceOrigin=='ATT' and att.costsComplete,'pinned ATT exchange compiles into the same ItemDB')
local reward
for _,id in ipairs(att.rewards)do
    local mask=att.rewardClassMasks[tostring(id)]
    if mask and math.floor(mask/2)%2==1 and not att.rewardRequirements[tostring(id)].unverified then reward=id;break end
end
assert(reward)
items[52027]={name='Conqueror Mark',vendor=0,class=15,bind=1}
items[reward]={name='ATT Paladin Reward',vendor=50*G,class=4,loc='INVTYPE_HAND'}
for _,cost in ipairs(att.costs[tostring(reward)])do
    if cost.kind=='item' and cost.id~=52027 then balances[cost.id]=cost.quantity;prices[cost.id]=2*G end
end
LL:Invalidate()
r=LL:Evaluate('item:52027',{isSoulbound=true,count=1})
assert(r.action=='V' and r.tokenQuote.value==48*G and r.tokenPiece.itemID==reward,
    'real ATT extra-equipment cost, source class mask and partial loading reach the actual decision')
assert(render(r):find('Additional exchange costs',1,true))
proof('ATT Sanctification exchange: consumed equipment is costed',r)
for _,cost in ipairs(att.costs[tostring(reward)])do
    if cost.kind=='item' and cost.id~=52027 then
        items[cost.id]={name='Consumed Bound Gear',vendor=2*G,class=4,loc='INVTYPE_HAND',bind=1}
    end
end
LL.db.characters['Pal-Realm'].professions={Enchanting=true};LL._enchantCache=nil;LL:Invalidate()
r=LL:Evaluate('item:52027',{isSoulbound=true,count=1})
assert(r.tokenPiece.cost.value>=r.tokenPiece.disenchantModel.value and r.tokenPiece.vendor<0,
    'consumed bound gear retains its own eligible disenchant opportunity value')
assert(r.action~='V' and render(r):find('net loss',1,true),'an exchange cannot profit by discarding the cost of its existing gear')
proof('ATT exchange: existing bound gear retains its disenchant opportunity value',r)
if arg and arg[1] then
    local out=assert(io.open(arg[1],'w'))
    out:write('# Actual offline token tooltip proofs\n\nGenerated by `tests/test_token_value_pipeline.lua` through the real decision engine and formatter. Item facts and prices are controlled synthetic fixtures; these are not live WoW prices or client screenshots. Exact/base variant and unavailable-action labels are intentional.\n')
    for _,p in ipairs(proofs)do
        out:write('\n## ',p.name,'\n\nAction: `',p.action,'`\n\n```text\n',
            p.text:gsub('|c%x%x%x%x%x%x%x%x',''):gsub('|r',''),'\n```\n')
    end
    out:close()
end
print('PASS: actual token values, class/alt eligibility, exact/base variants, costs, quantities, loading, currency and tooltip propagation')
