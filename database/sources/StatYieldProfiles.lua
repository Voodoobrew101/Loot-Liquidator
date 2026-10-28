-- Loot Liquidator 0.9.70. Source-conscious low/high processing overlay.
-- Expected quantities, occurrence probabilities and possible single-proc ranges
-- are distinct. Only expectedQuantity feeds prices; ranges are tooltip-only.
local _, LL = ...
local gd = LL.GameData
if not gd then return end
local max,min,floor,ceil=math.max,math.min,math.floor,math.ceil
local function pct(n) return max(0,min(1,(tonumber(n) or 0)/100)) end
local function clone(t)
    local out={}
    if type(t)=="table" then for k,v in pairs(t) do out[k]=v end end
    return out
end
local function rangeFor(expected,chance,providedMin,providedMax)
    local p=tonumber(chance) or min(1,max(.04,expected/1.5))
    p=min(1,max(0,p))
    local onHit=p>0 and expected/p or 1
    local lo=tonumber(providedMin) or max(1,floor(onHit*.65+.5))
    local hi=tonumber(providedMax) or max(lo,ceil(onHit*1.40))
    lo=max(1,floor(lo+.5));hi=max(lo,ceil(hi))
    -- A present display range must not contradict the unconditional mean.
    if p>0 and expected>p*hi then hi=max(hi,ceil(expected/p)) end
    if p>0 and expected<p*lo then lo=1 end
    return p,lo,hi
end
local function row(id,low,high,loMin,loMax,hiMin,hiMax,pLow,pHigh,basis)
    return {id=id,low=low,high=high,lowMin=loMin,lowMax=loMax,
        highMin=hiMin,highMax=hiMax,lowChance=pLow,highChance=pHigh,
        source=basis,probabilityBasis="display proxy unless separately measured"}
end
-- The War Within: per-5-ore published/player-observed source cohorts for
-- R2, applied conservatively to other input qualities as a labeled proxy.
-- Do not add the unrelated Crushed Gemstones output from the AI spreadsheet.
local tww={
    {210930,210931,210932,{
      row(212498,1.75,2.10,1,3,1,4,nil,nil,"Q2 Bismuth player batch; high modeled"),
      row(213398,4.25,4.95,2,6,3,7,nil,nil,"Q2 Bismuth player batch; high modeled"),
      row(213399,1.10,1.35,1,3,1,4,nil,nil,"Q2 Bismuth player batch; high modeled")}},
    {210933,210934,210935,{
      row(212498,1.75,2.10,1,3,1,4,nil,nil,"Q2 Aqirite player batch; high modeled"),
      row(212505,.75,.95,1,2,1,3,nil,nil,"Q2 Aqirite player batch; high modeled"),
      row(212508,1,1.25,1,2,1,3,nil,nil,"Q2 Aqirite player batch; high modeled"),
      row(213398,1.75,2.10,1,4,1,5,nil,nil,"Q2 Aqirite player batch; high modeled"),
      row(213399,.65,.80,1,2,1,3,nil,nil,"Q2 Aqirite player batch; high modeled")}},
    {210936,210937,210938,{
      row(212498,1.65,1.95,1,3,1,4,nil,nil,"Q2 Ironclaw player batch; high modeled"),
      row(212495,.65,.8,1,2,1,3,nil,nil,"Q2 Ironclaw player batch; high modeled"),
      row(212511,1,1.25,1,2,1,3,nil,nil,"Q2 Ironclaw player batch; high modeled"),
      row(213398,2.55,3.05,1,5,2,6,nil,nil,"Q2 Ironclaw player batch; high modeled"),
      row(213399,.55,.7,1,2,1,3,nil,nil,"Q2 Ironclaw player batch; high modeled")}},
}
gd.statYieldProfiles={Prospect={},Mill={}}
for _,family in ipairs(tww) do
    for i=1,3 do
        local id=family[i]
        -- Avoid overwriting exact input-specific compiled observations; the
        -- profile is applied at evaluation time, with the Q2 sample as anchor.
        gd.statYieldProfiles.Prospect[id]={batch=5,expansion=10,rows=family[4],
            evidence=i==2 and "published-player-batch-mean + modeled-high" or "borrowed-neighbor-quality + modeled-high",
            confidenceCap=i==2 and 55 or 32,
            source="https://www.wowhead.com/spell=434018/algari-prospecting"}
    end
end
local function millGroup(ids,outputIds,low,high,lowMin,lowMax,highMin,highMax,source)
    for i,id in ipairs(ids) do
        if gd.mill[id] then
            gd.statYieldProfiles.Mill[id]={batch=10,expansion=(id>230000 and 11 or 10),
              rows={row(outputIds[min(#outputIds,i)],low,high,lowMin,lowMax,highMin,highMax,1,1,source)},
              qualityFamily=#outputIds>=3 and outputIds or nil,
              source=source,evidence="documented-output + estimated mean",
              confidenceCap=40}
        end
    end
end
-- Mapping corroborated by Method; a Wowhead guide's 2024 player comment
-- reports roughly 12 pigments per ten herbs. The conservative 10 units low
-- and 12 high are independent scenario assumptions; the displayed integers
-- are provisional ranges and DO NOT feed monetary valuation.
-- https://www.wowhead.com/guide/the-war-within/professions/inscription-overview
millGroup({210796,210797,210798},{222616,222617,222618},10,12,8,12,10,15,
 "https://www.method.gg/guides/the-war-within-herb-milling-and-pigment-guide")
millGroup({210799,210800,210801},{222612,222613,222614},10,12,8,12,10,15,
 "https://www.wowhead.com/item=222614/luredrop-pigment")
millGroup({210802,210803,210804},{224800,224801,224802},10,12,8,12,10,15,
 "https://www.wowhead.com/item=224800/orbinid-pigment")
millGroup({210805,210806,210807},{224803,224804,224805},10,12,8,12,10,15,
 "https://www.wowhead.com/item=224805/blossom-pigment")
-- Midnight Milling uses 10 herbs per cast. Unlike the fabricated spreadsheet
-- inputs (1000-1099), these are actual Blizzard item IDs. Yield estimates
-- remain provisional; ore prospecting datasets are not reused as milling data.
millGroup({236761,236767},{245807},4.5,6.5,3,6,5,8,
 "https://www.wowhead.com/item=245807/powder-pigment")
millGroup({236776,236777},{245804},4.5,6.5,3,6,5,8,
 "https://www.wowhead.com/item=245804/argentleaf-pigment")
millGroup({236778,236779},{245866},4.5,6.5,3,6,5,8,
 "https://www.wowhead.com/item=245866/mana-lily-pigment")
millGroup({236770,236771},{245864},4.5,6.5,3,6,5,8,
 "https://www.wowhead.com/item=245864/sanguithorn-pigment")
-- Arathor's Spear is NOT millable (Blizzard tech-support discussion
-- March 2025). The old GameData list incorrectly included it as candidate.
-- Never recommend milling a nonexistent input -> output conversion.
for _,id in ipairs({210808,210809,210810}) do gd.mill[id]=nil end
-- Two historical research 'possible herb' IDs never acquired a verified
-- milling conversion or valid TSM yield; do not show a fictitious action.
for _,id in ipairs({36721,87821}) do
    if gd.mill[id] and #gd.mill[id].materials==0 then gd.mill[id]=nil end
end
-- Null Stone (210939) is a prospectable input despite not being ordinary ore.
-- One Wowhead player's 5-stone cast yielded 2 pebbles, a sapphire and an
-- onyx. This is a one-cast hypothesis, not a trustworthy statistical mean.
gd.statYieldProfiles.Prospect[210939]={batch=5,expansion=10,
  rows={row(213398,2,2.3,1,3,1,4,nil,nil,"one user-reported cast; provisional"),
        row(212508,1,1.15,1,2,1,3,nil,nil,"one user-reported cast; provisional"),
        row(212511,1,1.15,1,2,1,3,nil,nil,"one user-reported cast; provisional")},
  evidence="single-user-cast; very low confidence",confidenceCap=18,
  source="https://www.wowhead.com/item=210939/null-stone"}
-- Dragonflight original TSM milling rate remains the LOW endpoint. This is
-- an approximate upgraded HIGH only, not an undocumented measured multiplier.
for input,old in pairs(gd.tsmRetail and gd.tsmRetail.mill or {}) do
    if input>=191460 and input<=191472 and type(old)=="table" then
        local rank=1
        for _,mat in ipairs(old) do if mat.sourceQuality then rank=mat.sourceQuality;break end end
        local rows={}
        for _,mat in ipairs(old) do
            if mat.targetQuality==1 and mat.sourceQuality==rank then
                local low=(mat.amountOfMats or 0)*5
                rows[#rows+1]=row(mat.id,low,low*1.24,2,5,3,7,nil,nil,
                    "Original TSM amountOfMats low; upgraded count modeled")
            end
        end
        if #rows>0 then
            gd.statYieldProfiles.Mill[input]={batch=5,expansion=9,rows=rows,
                evidence="TSM-low + modeled-high",confidenceCap=42,
                source="TradeSkillMaster Retail historical milling conversion rates"}
        end
    end
end
