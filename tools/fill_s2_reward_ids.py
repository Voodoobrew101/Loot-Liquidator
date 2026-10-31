"""One-off (C4a5, session 13): write the Season 2 (Tier 36) tier-piece names and item IDs
into database/research/tokens-midnight-s2.json. Every ID below was read next to its item
name on a public page (URL kept per piece). Kept in the repo as the record of where each
number came from; re-running it is harmless (same result)."""
import json
from pathlib import Path

MD = 'https://www.mythicdrake.com/items/'
MD_INDEX = 'https://www.mythicdrake.com/items/ (index page; item link URL ends in -<id>/)'
WH = 'https://www.wowhead.com/item='

# class -> slot -> (name, id, source, evidence-or-None)
def md(slug, i):
    return (f'{MD}{slug}-{i}/', f'MythicDrake item URL {slug}-{i} (listed on {MD_INDEX})')

P = {
 'Warrior': {
  'Head': ("Tempered Horns of the Jade Warlord", 271456, 'https://wownexus.gg/item-sets/2067', 'Blizzard API item-set 2067 JSON on WoWNexus: "Tempered Horns of the Jade Warlord", id 271456'),
  'Shoulders': ("Raging Pauldrons of the Jade Warlord", 271454, 'https://wownexus.gg/item-sets/2067', 'Blizzard API item-set 2067 JSON on WoWNexus: "Raging Pauldrons of the Jade Warlord", id 271454'),
  'Chest': ("Cuirass of the Jade Warlord", 271459, 'https://wownexus.gg/item-sets/2067', 'Blizzard API item-set 2067 JSON on WoWNexus: "Cuirass of the Jade Warlord", id 271459'),
  'Hands': ("Jeweled Gauntlets of the Jade Warlord", 271457, 'https://wownexus.gg/item-sets/2067', 'Blizzard API item-set 2067 JSON on WoWNexus: "Jeweled Gauntlets of the Jade Warlord", id 271457'),
  'Legs': ("Greaves of the Jade Warlord", 271455, 'https://www.wowhead.com/ptr/item=271455/greaves-of-the-jade-warlord', None),
 },
 'Paladin': {
  'Head': ("Warhelm of the Consecrated Flame", 271465, f'{WH}271465/warhelm-of-the-consecrated-flame', None),
  'Shoulders': ("Pauldrons of the Consecrated Flame", 271463) + md('pauldrons-of-the-consecrated-flame', 271463),
  'Chest': ("Bulwark of the Consecrated Flame", 271468) + md('bulwark-of-the-consecrated-flame', 271468),
  'Hands': ("Gauntlets of the Consecrated Flame", 271466) + md('gauntlets-of-the-consecrated-flame', 271466),
  'Legs': ("Greaves of the Consecrated Flame", 271464) + md('greaves-of-the-consecrated-flame', 271464),
 },
 'Death Knight': {
  'Head': ("Baleful Grave-Knight's Casque", 271474, f'{WH}271474/baleful-grave-knights-casque', None),
  'Shoulders': ("Baleful Grave-Knight's Gibbets", 271472) + md('baleful-grave-knights-gibbets', 271472),
  'Chest': ("Baleful Grave-Knight's Breastplate", 271477) + md('baleful-grave-knights-breastplate', 271477),
  'Hands': ("Baleful Grave-Knight's Deathgrips", 271475) + md('baleful-grave-knights-deathgrips', 271475),
  'Legs': ("Baleful Grave-Knight's Greaves", 271473) + md('baleful-grave-knights-greaves', 271473),
 },
 'Shaman': {
  'Head': ("Serpent Crown of the Ophidian Oracle", 271483) + md('serpent-crown-of-the-ophidian-oracle', 271483),
  'Shoulders': ("Hissing Mantle of the Ophidian Oracle", 271481) + md('hissing-mantle-of-the-ophidian-oracle', 271481),
  'Chest': ("Fanged Raiment of the Ophidian Oracle", 271486) + md('fanged-raiment-of-the-ophidian-oracle', 271486),
  'Hands': ("Hexing Grips of the Ophidian Oracle", 271484) + md('hexing-grips-of-the-ophidian-oracle', 271484),
  'Legs': ("Leggings of the Ophidian Oracle", 271482) + md('leggings-of-the-ophidian-oracle', 271482),
 },
 'Hunter': {
  'Head': ("Skulking Viper's Weeping Fangs", 271492) + md('skulking-vipers-weeping-fangs', 271492),
  'Shoulders': ("Jaws of the Skulking Viper", 271490) + md('jaws-of-the-skulking-viper', 271490),
  'Chest': ("Skulking Viper's Scuteplate", 271495) + md('skulking-vipers-scuteplate', 271495),
  'Hands': ("Skulking Viper's Hidepiercers", 271493) + md('skulking-vipers-hidepiercers', 271493),
  'Legs': ("Skulking Viper's Coiled Legwraps", 271491) + md('skulking-vipers-coiled-legwraps', 271491),
 },
 'Evoker': {
  'Head': ("Calamitous Echo's Magmashapers", 271501) + md('calamitous-echos-magmashapers', 271501),
  'Shoulders': ("Calamitous Echo's Sundered Peaks", 271499) + md('calamitous-echos-sundered-peaks', 271499),
  'Chest': ("Searing Caldera of Calamity", 271504) + md('searing-caldera-of-calamity', 271504),
  'Hands': ("Calamitous Echo's Ebon Greathorns", 271502) + md('calamitous-echos-ebon-greathorns', 271502),
  'Legs': ("Earthen Pillars of Calamity", 271500) + md('earthen-pillars-of-calamity', 271500),
 },
 'Rogue': {
  'Head': ("Chosen Bloodslayer's Spirit Shroud", 271510) + md('chosen-bloodslayers-spirit-shroud', 271510),
  'Shoulders': ("Chosen Bloodslayer's Voodoo Guards", 271508) + md('chosen-bloodslayers-voodoo-guards', 271508),
  'Chest': ("Chosen Bloodslayer's Banded Poncho", 271513) + md('chosen-bloodslayers-banded-poncho', 271513),
  'Hands': ("Chosen Bloodslayer's Fanged Grips", 271511) + md('chosen-bloodslayers-fanged-grips', 271511),
  'Legs': ("Chosen Bloodslayer's Reinforced Pants", 271509) + md('chosen-bloodslayers-reinforced-pants', 271509),
 },
 'Monk': {
  'Head': ("Monkey King's Unyielding Visage", 271519) + md('monkey-kings-unyielding-visage', 271519),
  'Shoulders': ("Tassels of the Monkey King", 271517, f'{WH}271517/tassels-of-the-monkey-king', None),
  'Chest': ("Battle Gi of the Monkey King", 271522) + md('battle-gi-of-the-monkey-king', 271522),
  'Hands': ("Monkey King's Fighting Fists", 271520) + md('monkey-kings-fighting-fists', 271520),
  'Legs': ("Pantaloons of the Monkey King", 271518) + md('pantaloons-of-the-monkey-king', 271518),
 },
 'Druid': {
  'Head': ("Enigmatic Dreamwatcher's Somnolent Stare", 271528) + md('enigmatic-dreamwatchers-somnolent-stare', 271528),
  'Shoulders': ("Enigmatic Dreamwatcher's Plumage", 271526) + md('enigmatic-dreamwatchers-plumage', 271526),
  'Chest': ("Enigmatic Dreamwatcher's Lunar Raiment", 271531) + md('enigmatic-dreamwatchers-lunar-raiment', 271531),
  'Hands': ("Enigmatic Dreamwatcher's Gauntlets", 271529) + md('enigmatic-dreamwatchers-gauntlets', 271529),
  'Legs': ("Enigmatic Dreamwatcher's Leggings", 271527) + md('enigmatic-dreamwatchers-leggings', 271527),
 },
 'Demon Hunter': {
  'Head': ("Abyssal Doomhound's Relentless Stare", 271537) + md('abyssal-doomhounds-relentless-stare', 271537),
  'Shoulders': ("Abyssal Doomhound's Jaws", 271535) + md('abyssal-doomhounds-jaws', 271535),
  'Chest': ("Abyssal Doomhound's Coreguard", 271540) + md('abyssal-doomhounds-coreguard', 271540),
  'Hands': ("Abyssal Doomhound's Studded Gauntlets", 271538) + md('abyssal-doomhounds-studded-gauntlets', 271538),
  'Legs': ("Abyssal Doomhound's Legwraps", 271536) + md('abyssal-doomhounds-legwraps', 271536),
 },
 'Warlock': {
  'Head': ("Skull of the Damned Necrolyte", 271546) + md('skull-of-the-damned-necrolyte', 271546),
  'Shoulders': ("Spires of the Damned Necrolyte", 271544, f'{WH}271544/spires-of-the-damned-necrolyte', None),
  'Chest': ("Damned Necrolyte's Rattling Robes", 271549) + md('damned-necrolytes-rattling-robes', 271549),
  'Hands': ("Damned Necrolyte's Charred Grasps", 271547) + md('damned-necrolytes-charred-grasps', 271547),
  'Legs': ("Damned Necrolyte's Leg Bindings", 271545) + md('damned-necrolytes-leg-bindings', 271545),
 },
 'Priest': {
  'Head': ("Cosmic Penitent's Truesight", 271555) + md('cosmic-penitents-truesight', 271555),
  'Shoulders': ("Cosmic Penitent's Echoing Screams", 271553) + md('cosmic-penitents-echoing-screams', 271553),
  'Chest': ("Cosmic Penitent's Eclipsing Robes", 271558) + md('cosmic-penitents-eclipsing-robes', 271558),
  'Hands': ("Cosmic Penitent's Celestial Grips", 271556) + md('cosmic-penitents-celestial-grips', 271556),
  'Legs': ("Enveloping Legwraps of the Cosmic Penitent", 271554) + md('enveloping-legwraps-of-the-cosmic-penitent', 271554),
 },
 'Mage': {
  'Head': ("Crown of the Primal Leywarden", 271564) + md('crown-of-the-primal-leywarden', 271564),
  'Shoulders': ("Primal Leywarden's Manaflux", 271562) + md('primal-leywardens-manaflux', 271562),
  'Chest': ("Crest of the Primal Leywarden", 271567) + md('crest-of-the-primal-leywarden', 271567),
  'Hands': ("Primal Leywarden's Manashapers", 271565) + md('primal-leywardens-manashapers', 271565),
  'Legs': ("Primal Leywarden's Tailored Legwraps", 271563) + md('primal-leywardens-tailored-legwraps', 271563),
 },
}

NAME_SOURCE = 'https://www.method.gg/guides/wow-midnight-season-2-tier-set-stats'

path = Path('database/research/tokens-midnight-s2.json')
doc = json.loads(path.read_text())
for t in doc['tokens']:
    for r in t['rewards']:
        name, iid, src, ev = P[r['class']][t['slot']]
        if r['name'] is not None and r['name'].lower() != name.lower():
            raise SystemExit(f"name conflict {t['name']} {r['class']}: {r['name']} vs {name}")
        if r['name'] is None:
            r['nameSource'] = NAME_SOURCE
        r['name'] = name
        r['itemID'] = iid
        r['source'] = src
        if ev:
            r['evidence'] = ev
        else:
            r.pop('evidence', None)
    t['rewardNames'] = [r['name'] for r in t['rewards']]
    t['rewardIDs'] = [r['itemID'] for r in t['rewards']]
    t['status'] = 'ids-complete-unreviewed'

doc['task'] = 'C4a4 + C4a5'
doc['collected'] = '2026-10-31 (sessions 12 and 13)'
doc['conflicts'][0] = (
    "Evoker hands vs head: SETTLED in session 13. The names sound swapped but the item tooltips "
    "(warcraft.wiki.gg item pages) say Calamitous Echo's Magmashapers = Mail Head (from Venomcast Effigy) "
    "and Calamitous Echo's Ebon Greathorns = Mail Hands (from Venomcast Idol). The item numbers agree: "
    "271501 Magmashapers sits in the head position and 271502 Greathorns in the hands position of the "
    "evoker block. Sources: https://warcraft.wiki.gg/wiki/Calamitous_Echo's_Magmashapers, "
    "https://warcraft.wiki.gg/wiki/Calamitous_Echo's_Ebon_Greathorns.")
doc['stillMissing'] = [
    "Nothing to collect: 20/20 tokens, 65/65 reward names and IDs, each with its source.",
    "Independent check by the research team (task C4b) before anything goes into ItemDB. Weakest links: "
    "the 52 IDs read only from MythicDrake item URLs (one source each); the numbering pattern below "
    "agrees with every one of them.",
]
doc['rewardIDPattern'] = (
    "Observed, not used as data: tier pieces are 271451-271567 in blocks of 9 per class (cloak, wrist, "
    "waist, shoulder, legs, head, hands, feet, chest), class order Warrior, Paladin, Death Knight, Shaman, "
    "Hunter, Evoker, Rogue, Monk, Druid, Demon Hunter, Warlock, Priest, Mage. Same layout as Season 1. "
    "All 65 IDs were read from pages next to their names; every one also fits this pattern.")
path.write_text(json.dumps(doc, indent=1, ensure_ascii=False) + '\n')

# Self-check: every ID fits the observed pattern.
ORDER = ['Warrior', 'Paladin', 'Death Knight', 'Shaman', 'Hunter', 'Evoker', 'Rogue', 'Monk', 'Druid',
         'Demon Hunter', 'Warlock', 'Priest', 'Mage']
POS = {'Shoulders': 3, 'Legs': 4, 'Head': 5, 'Hands': 6, 'Chest': 8}
for c, slots in P.items():
    for s, v in slots.items():
        assert v[1] == 271451 + 9 * ORDER.index(c) + POS[s], (c, s, v[1])
print('S2 rewards written: 65/65, all fit the 9-per-class pattern')
