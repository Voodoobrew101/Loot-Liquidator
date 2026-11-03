-- C2b: disenchant research targets. RESEARCH ONLY, not compiled, not shipped.
--
-- These are the gear groups (expansion x quality x armor/weapon) that have NO
-- disenchant record at all: neither in ItemDB nor in the old estimates
-- (ItemDB.legacy). The addon shows "?" for disenchanting such gear.
--
-- Borrowing from another quality is wrong (green/blue/purple give different
-- materials: dust / shards / crystals), so these need real data, not guesses.
-- Do NOT write numbers here. Research agents submit evidence records (source
-- link, raw casts and drops, date, patch); see claude/research-agent-proposal.md.
--
-- tests/test_disenchant_gaps.lua recomputes the gaps from ItemDBRuntime.lua and
-- fails if this list is out of date (remove an entry once data covers it).
--
-- otherKindHasData=true: the same expansion and quality has data for the other
-- gear kind (armor vs weapon). Usually the same materials, so those are the
-- cheapest to close: confirm the materials match and record a few casts.
-- variesByItemLevel=true: Classic and TBC materials change with item level
-- inside the expansion, so one record per item-level band is needed.

local EXPANSIONS={[0]='Classic',[1]='The Burning Crusade',[2]='Wrath of the Lich King',
    [3]='Cataclysm',[4]='Mists of Pandaria',[5]='Warlords of Draenor',[6]='Legion',
    [7]='Battle for Azeroth',[8]='Shadowlands',[9]='Dragonflight',[10]='The War Within',
    [11]='Midnight'}
local QUALITIES={[2]='Uncommon (green)',[3]='Rare (blue)',[4]='Epic (purple)'}

local keys={
    'gear:0:2:armor','gear:0:2:weapon','gear:0:3:armor','gear:0:3:weapon','gear:0:4:armor','gear:0:4:weapon',
    'gear:1:2:armor','gear:1:2:weapon','gear:1:3:weapon','gear:1:4:armor','gear:1:4:weapon',
    'gear:3:4:armor','gear:3:4:weapon',
    'gear:4:3:armor','gear:4:3:weapon','gear:4:4:armor','gear:4:4:weapon',
    'gear:5:3:armor','gear:5:3:weapon','gear:5:4:armor','gear:5:4:weapon',
    'gear:6:3:armor','gear:6:3:weapon',
    'gear:7:3:armor','gear:7:3:weapon','gear:7:4:armor','gear:7:4:weapon',
    'gear:8:3:armor','gear:8:3:weapon','gear:8:4:armor','gear:8:4:weapon',
    'gear:9:3:armor','gear:9:3:weapon',
}
local otherKindHasData={['gear:1:3:weapon']=true}

local targets={}
for i,key in ipairs(keys) do
    local e,q,kind=key:match('^gear:(%d+):(%d+):(%a+)$')
    e,q=tonumber(e),tonumber(q)
    targets[i]={key=key,expansionID=e,expansion=EXPANSIONS[e],quality=q,qualityName=QUALITIES[q],
        gearKind=kind,status='needs-data',variesByItemLevel=(e<=1) or nil,
        otherKindHasData=otherKindHasData[key] or nil,
        -- Research order: cheapest to close first, then newest expansions.
        priority=otherKindHasData[key] and 1 or (e>=7 and 2 or (e>=2 and 3 or 4))}
end

return {
    schemaVersion='loot-liquidator.disenchant-gaps/1',
    generatedForBuild='12.1.x',
    whereToLook={
        'https://warcraft.wiki.gg/wiki/Disenchanting',
        'https://www.wowhead.com/ (item page > "Disenchants into" tab, which shows sample counts)',
        'Players\' own recorded results (Settings > Processing Research > Export)',
    },
    evidenceNeeded='Per target: material item IDs, casts, drops per material, smallest and largest amount seen, date, game patch, source link.',
    targets=targets,
}
