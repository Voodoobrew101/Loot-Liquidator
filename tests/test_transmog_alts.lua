-- C5: an enabled alt counts for a missing appearance on any armor their armor
-- type can wear, not only class-restricted tier pieces. Transfer rules stay.
CreateFrame=function() return {RegisterEvent=function()end,SetScript=function()end} end
UnitClass=function() return 'Mage','MAGE' end
UnitName=function() return 'Main' end
GetRealmName=function() return 'Realm' end
local LL={}
assert(loadfile('LootLiquidator/Professions.lua'))('LootLiquidator',LL)
LL.ItemClassMasks={[900]=2^(1-1)} -- item 900: warrior-only (class mask)
LL.CharacterKey=function() return 'Main - Realm' end
LL.db={includeVerifiedAlts=true,characters={
    ['Main - Realm']={class='MAGE'},
    ['Plate - Realm']={class='PALADIN'},
    ['Leather - Realm']={class='DRUID'},
    ['Warrior - Realm']={class='WARRIOR'}}}
local function eq(a,b,msg) if a~=b then error(msg..': expected '..tostring(b)..', got '..tostring(a),2) end end
local function gear(id,sub,loc,context)
    return {id=id,classID=4,subClassID=sub,equipLoc=loc or 'INVTYPE_CHEST',
        context=context or {verifiedUnbound=true}}
end

-- Armor-type rule on its own.
eq(LL:ArmorTypePermitsClass(gear(1,4),'PALADIN'),true,'plate fits a paladin')
eq(LL:ArmorTypePermitsClass(gear(1,4),'MAGE'),false,'plate does not fit a mage')
eq(LL:ArmorTypePermitsClass(gear(1,2),'DEMONHUNTER'),true,'leather fits a demon hunter')
eq(LL:ArmorTypePermitsClass(gear(1,3),'EVOKER'),true,'mail fits an evoker')
eq(LL:ArmorTypePermitsClass(gear(1,1,'INVTYPE_CLOAK'),'WARRIOR'),true,'cloaks fit everyone')
eq(LL:ArmorTypePermitsClass(gear(1,6,'INVTYPE_SHIELD'),'SHAMAN'),true,'shaman can use shields')
eq(LL:ArmorTypePermitsClass(gear(1,6,'INVTYPE_SHIELD'),'DRUID'),false,'druid cannot use shields')
eq(LL:ArmorTypePermitsClass(gear(1,0,'INVTYPE_FINGER'),'MAGE'),nil,'rings have no armor-type answer')
eq(LL:ArmorTypePermitsClass({id=1,classID=2,subClassID=7},'MAGE'),nil,'weapons are not decided by armor type')

-- A class mask "no" and an armor-type "no" both win.
eq(LL:AltCanWearAppearance(gear(900,4),'PALADIN'),false,'warrior-only mask excludes a paladin')
eq(LL:AltCanWearAppearance(gear(900,4),'WARRIOR'),true,'warrior-only mask allows a warrior')
eq(LL:AltCanWearAppearance(gear(901,4),'PALADIN'),true,'ordinary plate (no mask) allows a paladin')

-- Recipient choice: a mage holding ordinary tradable plate is pointed at the
-- first plate alt (sorted by name) instead of "keep on this character".
local r=LL:DirectTransmogRecipient(gear(901,4))
assert(r and r.current==false and r.name=='Plate - Realm','ordinary plate goes to a plate alt')
r=LL:DirectTransmogRecipient(gear(902,2))
assert(r and r.name=='Leather - Realm','ordinary leather goes to the leather alt')
r=LL:DirectTransmogRecipient(gear(903,1))
assert(r and r.current==true,'cloth stays with the mage')
-- Transfer rule unchanged: soulbound gear never counts an alt.
eq(LL:DirectTransmogRecipient(gear(904,4,nil,{isSoulbound=true})),nil,'soulbound plate counts no alt')
-- The "Include alts" switch still turns alts off.
LL.db.includeVerifiedAlts=false
eq(LL:DirectTransmogRecipient(gear(905,4)),nil,'Include alts off: no alt counted')
print('PASS: C5 transmog alts by armor type, class mask, transfer rule and Include alts switch')
