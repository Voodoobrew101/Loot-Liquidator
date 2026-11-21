"""Source-contract catalogue. Reads original/corrected evidence; writes this lane only.

No sample size is synthesized. Proposed fields are independent: an occurrence
reference is not a unit mean, and positive-event quantity is not unconditional EV.
"""
from __future__ import annotations
import collections, csv, hashlib, io, json, pathlib, re, subprocess, sys
sys.dont_write_bytecode = True
ROOT = pathlib.Path(__file__).resolve().parents[5]
OUT = pathlib.Path(__file__).resolve().parent
INPUT = ROOT.parent / '.validation/backlog-closure-20261120/inputs/disenchant_b_and_leads.json'
sys.path.insert(0, str(ROOT / 'research/v3/tools'))
import build_estimates as engine

def sha(v):
    return hashlib.sha256(v if isinstance(v, bytes) else json.dumps(v, sort_keys=True, ensure_ascii=False, separators=(',', ':')).encode()).hexdigest()

def write(name, value):
    (OUT / ('disenchant-b-leads-' + name)).write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n', encoding='utf-8', newline='\n')

def num(v): return isinstance(v, (int, float)) and not isinstance(v, bool)

# These IDs are source-linked rank families, not an ordering inferred from IDs.
FAMILIES = {'Storm Dust': [219946,219947,219948], 'Gleaming Shard':[219949,219950,219951],
 'Refulgent Crystal':[219952,219954,219955], 'Eversinging Dust':[243599,243600],
 'Radiant Shard':[243602,243603], 'Dawn Crystal':[243605,243606]}

# Explicit reported input cohorts. A nominal count is NEVER recorded as casts.
# Values have been read in the original quotes and retained primary-source notes.
NOMINAL = {
 'wowhead-mask-979581-thirty-made-about-eighty-dust': (30, 'crafted-masks', 80, True),
 'wowhead-10978-allakhazam-rough-bronze-10-crafted-four-shards':(10,'crafted-leggings',None,False),
 'allakhazam-10978-10roughbronzeleggings-4shards':(10,'crafted-leggings',None,False),
 'wowhead-tbc-souldust-biocyte-1382-azure-silk-cloaks':(1382,'reported-cloaks-disenchanted',None,False),
 'wowhead-lesser-nether-1001850-20-white-bandit-masks':(20,'crafted-masks',None,False),
 'wowhead-14128-thottbot-anon-five-robes-four-each':(5,'reported-robes',None,False),
 'thottbot-headband-8-greater-from-ten':(10,'reported-headbands',None,False),
 'allakhazam-headband-ten-bought-14-1-8':(10,'purchased-headbands',None,False),
 'wowhead-21849-85599-120-bracers':(120,'reported-bracers',None,False),
 'wowhead-netherweave-bracers-53050-332-crafts':(332,'crafted-bracers',None,False),
 'wowhead-21849-original-53050-332-crafted':(332,'crafted-bracers',None,False),
 'wowhead-21852-70404-thirty-crafted-pants-disenchant-totals':(30,'crafted-pants',None,False),
 'reddit-k5qxv1-625-shrouded-bracers-craft-and-de':(625,'crafted-bracers',None,False),
 'wowhead-arcane-dust-16088-147-mixed-blood-draenite-rings':(147,'mixed-crafted-rings',None,False),
 'wowhead-22445-16088-147-mixed-rings':(147,'mixed-crafted-rings',None,False),
 'wowhead-16088-147crafted-rings-three-outcomes':(147,'mixed-crafted-rings',None,False),
 'wowhead-34054-cymre-14-mixed-icc-greens':(14,'reported-mixed-dungeon-greens',None,False),
 'wowhead-34054-903227-26-mixed-crafted-jc-items':(26,'mixed-crafted-jewellery',None,False),
}

LEADS = {
4:('METADATA_REFERENCE','https://us.forums.blizzard.com/en/wow/t/create-all-button-frequently-fails-to-work/1958838','Queue interruptions and split/bank stacks make planned queue size an unsafe completed-operation denominator. No output-yield study or current universal failure probability is reported.','Original forum opened 2026-11-20; retained master stack-risk note agrees.'),
5:('METADATA_REFERENCE','https://us.forums.blizzard.com/en/wow/t/fate-weaver-season-3-ilvl-350/2154715','One August2025 ritual failure on an ilvl350 Fate Weaver item, including spec swaps, is a historical eligibility/context report. It is not a zero-material cast or a token reward distribution.','Original forum opened; retained T0027 master audit.'),
6:('METADATA_REFERENCE','https://us.forums.blizzard.com/en/wow/t/feedback-housing-dyes-and-inventory-management/2209314','Housing dye inventory feedback describes milling queues stopping at mismatched stacks; no per-material experiment. Retain denominator warning and naming context, no yield coefficient.','Original forum opened.'),
7:('ADMIT','https://us.forums.blizzard.com/en/wow/t/resourcefulness-bugged/2261410','Zarp reports800 shard shatters,15% Resourcefulness,67 skill and45 shards returned. This is a source refund-per-reported-operation reference45/800, not gear disenchant output or Resourcefulness proc probability. Other posters report different Engineering recipes/profiles and must stay separate.','Original forum post6 opened; returned unit total and profile read directly.'),
8:('ADMIT','https://us.forums.blizzard.com/en/wow/t/we-need-a-mass-ink-option/226400','Nirosu post7 reports140 Riverbud mass mills and2272 Ultramarine,918 Crimson,376 Viridescent units. Native recipe256217 consumes20 herbs. Retain140 source-reported operations, not560 ordinary casts. Per-input and per-mass-operation means usable as historical source references, without invented hits.','Original forum and post7 opened; retained original-source master audit.'),
9:('METADATA_REFERENCE','https://us.forums.blizzard.com/en/wow/t/why-did-sanguithorn-become-immediately-worthless/2268090','March2026 firsthand statement says Sanguithorn Pigment cannot be selected for Recycling, unlike other pigments. This is an epoch-specific input-selection report, not a measured output zero, rank-wide eternal exclusion or recipe-drop chance.','Original forum post5 opened; guide cross-check.'),
10:('METADATA_REFERENCE','https://us.forums.blizzard.com/en/blizzard/t/commodities-api-item-rankquality/51895','Developers discuss ItemAPI responses lacking explicit profession rank. This explains a quality-ID crosswalk gap; it supplies no prospect/mill/disenchant output numbers. Native rank mapping must establish identity.','Original developer forum opened; this is the Blizzard developer forum, not the WoW forum of the same numeric ID.'),
11:('ADMIT','https://boostmatch.gg/blog/wow/articles/wow-midnight-engineering-guide','Guide explicitly models5-item Recycling, approximately1.5 pooled primary units at base and3 at30 Recycling points. Keep endpoints at their source specialization, no empirical N or invented rank split; actual native legal input and basic/advanced output family must match.','Original current guide opened; matching WoWProfessions guide read, not independent experiments.'),
12:('ADMIT','https://docs.google.com/spreadsheets/d/11kVrPOVY0Jei3xmBL1q_I9fsFAl3QY6d/edit','Original39167-byte workbook re-read through connected Drive: all387 matrix rows catalogued separately.212 source probabilities,212 minima,190 maxima; no expected-quantity column or populatedM:S values despite104 advertised quantities. Valid source-model probabilities/ranges remain reference-only with samples0/cap0.48 explicit MoPClassic rows are rejected for Retail;128 blank modern identity rows supply no quantity/chance. Native rank families replace representative-ID-as-exact-rank assumptions; no midpoint or actual N invented.','Original connected Drive readable extraction retrieved2026-11-20; whole387-row matrix plus guide/coverage/exclusions locally retained and checked.'),
13:('ADMIT','https://docs.google.com/spreadsheets/d/1f-d39_TW0MARV5Egib2IPuW8kTU5-_C8PIgAkz2A4IU/edit','Fresh native CellData establishes H9 label AVERAGE VALUE PER SINGLE PROSPECT and B10/C10 scale H1:H7 by scenario cast count with5ore cost. Seven ratios therefore support source-model per-prospect means, not observed N or P(hit). Source explicitly saysR2 BrilliantSilver; native70961 maps that to237365, not the old candidate237364(R1). Output shorthand maps only to legal native family pools under explicit assumptions, no rank pricing invented. Diamond remains SilverScrapper-unlock conditional; source skill/spec unknown.','Original native metadata and exact prospecting example A1:J12 formulas/effective values read2026-11-20; source cells locally retained. No original sheet edits.'),
24:('METADATA_REFERENCE','https://guildloot.de/en/item/tbc/23758-cogspinner-goggles/','Cogspinner Goggles23758 is rare historicalTBC ilvl106 gear, not uncommon; current Retail scaling is a separate version. Rarity/catalog identity does not prove current disenchant access or a drop distribution. Do not apply a blanket class exclusion.','Public page unavailable during this pass; retained original identity cross-check and original-source Cogspinner cohort inspected.'),
25:('METADATA_REFERENCE','https://www.ironsongtribe.com/thread-2958-post-11061.html','Patch2.1 PTR notes reverse older no-disenchant restrictions including Valanos Longbow and Blackout Truncheon. Historical no-DE claims therefore cannot become timeless current exclusions; no numerical yield data.','Original dated patch-note mirror opened; source is PTR announcement, not a new live cast.'),
26:('ADMIT','https://www.reddit.com/r/woweconomy/comments/109yr4s/','Original Jan2023 source reports500 Magma Thresher inputs and13 named material quantities, allR2 claimed,25 Prospecting KP. Preserve per-reported-fish quantities with no invented100/500 casts. Fish batch, exact output rank links and current recipe access remain unknown; legal family-unpriced/reference display only until bound.','Direct source fetch unavailable; four retained primary-thread extraction/audit receipts inspected, exact source table retained.'),
39:('METADATA_REFERENCE','https://www.reddit.com/r/woweconomy/comments/1sv5u5a/recycling_changes/','Author reports losing about40 effective Recycling skill after patch, changing R1 input formerly givingR2 Evercore. This is source epoch/quality-profile evidence, not a yield quantity, refund count or proof of a specific fixed40-skill coefficient.','Original Reddit post opened.'),
40:('METADATA_REFERENCE','https://www.reddit.com/r/woweconomy/comments/1swweyv/change_in_skill_after_patch/','Separate author reports365/405 Recycling skill after patch despite100 profession and max nodes/tools. Missing55 from Bots is a hypothesis, not a verified additive formula; no material quantities. Keep profile/epoch diagnostic, not a universal skill subtraction.','Original Reddit post opened.'),
41:('ADMIT','https://www.reddit.com/r/woweconomy/comments/6ygegx/prospect_5000_empyrium_results/','Original post includes three OP mass-prospect arms plus copied BizGob,Camzaman,DeanDipp arms. OP reports250,150,250 batches; overlap is not independently established, so retain separate vectors rather than summing. BizGob original6ydssd verifies291 batches. Camzaman original6x188h verifies3000purchased inputs and quantities, not150 actual casts: retain per-input means, actualNunknown. DeanDipp225 is secondary-reported only. IcyVeins summary and post/comment copies add no independent measurements.','Original post, original BizGob and Camzaman sources opened; DeanDipp original inaccessible, source-linked repost retained with its status explicit.'),
42:('ADMIT','https://www.reddit.com/r/woweconomy/comments/6ywwdq/prospecting_7780_emyprium/','Original author explicitly389×20 Empyrium prospects, six gem totals and1556 Gem Chips; source says initial JC1/800. Chip mean4 per reported mass operation is a sample mean, not a universal guaranteed yield.','Original Reddit linked source opened and author skill reply read.'),
43:('ADMIT','https://www.reddit.com/r/woweconomy/comments/98oyfb/bfa_milling_data_30k_anchor_weed_600k_common_herbs/','Bilis explicitly used beta copies:30000 Anchor Weed manual5batch/6000operations plus six100000-herb mass20batch/5000operations each. All21 numeric quantity fields are preserved as beta-era references, not modern live casts. Do not double add common-herb summary or substitute bugged Anchor mass recipe.','Original complete table and author beta/operation-count replies opened; retained exact table cross-check.'),
47:('ADMIT','https://www.reddit.com/r/woweconomy/comments/u0f32m/how_to_make_crafting_profitable_material_prices/','SygonPaul provides per-herb quantity ratios used in price formulas, not new observed casts. The21 BfA ratios agree with rounded Bilis vectors, but the post does not identify original cohort lineage: retain source-model references without claiming independent measurement or proven direct copying. The outer5 in a pricing formula must not divide those already-per-herb ratios by5. Legion price terms also subtract seed byproduct value and contain typos; do not parse them as raw output experiments.','Original Reddit text, formula tables and author corrections opened.'),
49:('ALREADY_REPRESENTED','https://repos.wowace.com/wow/reagentmaker/file/42baf007f3c7/ProspectingData.lua?style=paper','2015 static ReagentMaker Enchantrix-derived table is already transcribed, including36 Cobalt/FelIron/Adamantite gem references in legacy20261115-154901..154936. chanceToHaveOne plus explicit one-unit assumption can supply reference E=p per5ore, samples0. Other coefficients greater than1 prove the generic field is not universally P; do not duplicate upstream tables or normalize gem chance sums.','Current public retrieval unavailable; retained pinned-source tuple contract and36 exact current transcription rows inspected.'),
50:('REJECTED_CURRENT_NUMERICAL_USE','https://worldofwarcraft.fandom.com/et/wiki/Frostwoven_Belt','Archived table22%dust/75%essence/3%shard with dust1–2 conflicts with literal7belt source21dust (each≥3) and separate6belt1–2 outcomes. Do not silently invert table labels or blend incompatible epochs. Preserve archived ranges as contradictory historical metadata; current numerical baseline cannot be selected from it.','Public archive unavailable; retained primary-page/comment comparison and exact7-operation arithmetic inspected.'),
51:('ADMIT','https://www.wow-professions.com/midnight/engineering-guide','Current guide states5 consumed items per Recycling and around3 pooled Evercore/Aetherlume at30Recycling points, double base. Usable source-model quantity endpoints with no observedN, no output rank allocation, no blanket input eligibility. Native input recipe/family is required.','Original guide opened, Recycling subsection read.'),
52:('METADATA_REFERENCE','https://www.wow-professions.com/midnight/engineering-specialization-guide-and-builds','Guide states Recycling cannot Multicraft and output quality depends on skill/inputquality. Relevant to correct simulation scope; does not provide an MC proc amount for Recycling or independent measured yield counts.30Recycling+BitsBots skill context must not be confused with a zero-spec endpoint.','Original guide opened, Multicraft and Recycling sections read.'),
53:('ADMIT','https://www.wow-professions.com/midnight/npc/melaris','Melaris lists bag260537 for600 Enchanter Moxie currency3258, not600gold. Retained original bag comments give7 complete material vectors (2explicitbeta,5epochunknown), plus named recipe extras. Preserve Use/Open method and actual per-bag vectors; currency cost remains non-copper/unpriced, no invented recipe chance.','Original vendor listing opened; seven retained original-comment vectors independently audited in master note.'),
83:('METADATA_REFERENCE','https://www.wowhead.com/item=201360/glimmer-of-order','Glimmer of Order is a special knowledge treasure with explicit disenchant use despite CannotBeDestroyed, not evidence that all knowledge powders are valid DE inputs. Powder267653/Dust227662 output-side tabs do not grant action access.','Wowhead blocked; retained original tooltip/native-spell direction-control receipt and current source rows inspected.'),
236:('ALREADY_REPRESENTED','https://www.wowhead.com/cata/item=52180/nightstone','Primary jaymoney80Obsidium prospects,370112 one5ore prospect and9576631200ore output totals are already transcribed in legacy20261107T1046 file. Do not count public comment again. Separate370112 threeElementiumstacks has unknown stack size and therefore no cast denominator.','Original Nightstone page/comments opened and compared with retained exact source identities.'),
239:('ALREADY_REPRESENTED','https://www.wowhead.com/ptr-2/item=72234/green-tea-leaf','Existing retained Rubilac214+1UK45272 actual5herb mills, plus TwilightJasmine257849104, establish six historical material means across590reported operations. Source21.5%/25% displayed quantity/cast ratios are not P(hit). Other raw herb totals remain per-input only; no new cohort from this summary lead.','Retained original-source six-cohort master audit and already-transcribed evidence inspected; PTR URL label alone does not classify original events as PTR.'),
240:('ALREADY_REPRESENTED','https://www.wowhead.com/news/10-0-economy-speculation-wowhead-economy-weekly-wrap-up-223-326714','EconomyWrapUp223 republishes SygonPaul pricing formulas from redditu0f32m; no independent milling sample. Reference quantities keep original provenance and units, no double weighting or direct inferred casts.','Original Reddit author explicitly links this reprint; retained dashboard source link inspected.'),
241:('METADATA_REFERENCE','https://www.wowhead.com/news/roll-for-tertiary-stats-with-dimensius-omni-tokens-in-manaforge-omega-377408','Curio redemption is staged Curio→one of20 tokens237581..237600→class gear. Final item catalog rows are not directly purchasable SKUs for a three-Curio cost; no random DE yield or tertiary probability is reported by this source lead.','Retained original article/source-stage audit inspected; exact native token identities must drive stage costs.'),
242:('ALREADY_REPRESENTED','https://www.wowhead.com/ptr-2/news/roll-for-tertiary-stats-with-dimensius-omni-tokens-in-manaforge-omega-377408','PTR-hosted copy of the same Curio article, not an independent reward or rate sample. Keep direct token cost versus transitive final gear distinction; existing stage identity audit supplies the decision.','Same article alias and two retained master source-stage receipts inspected.'),
244:('METADATA_REFERENCE','https://www.wowhead.com/spell=1280952/disenchant','Native Disenchant spell identifies an operation and special-target direction; it supplies no measured per-material distribution. Knowledge powder output tabs cannot be used to synthesize an input conversion or eligibility.','Primary web page blocked; retained native spell/source-direction audit inspected.'),
245:('METADATA_REFERENCE','https://www.wowhead.com/cata/spell=83966/bountiful-bags','Historical guild-perk extra materials matter to source normalization. Falynn20headbands explicitly had BountifulBags; Warcanon source531Silvery/181mills=2.933701657, not the erroneous printed1.5801. No universal quantitative perk multiplier is established; preserve epoch/perk and exact source quantities separately.','Primary page script-blocked; retained original Falynn/Warcanon/perk source receipts inspected.'),
246:('REJECTED_CURRENT_NUMERICAL_USE','https://wowwiki-archive.fandom.com/wiki/Boulderfist_Legplates','Archived22%dust/75%essence/3%shard and ranged quantities conflict with TBC2.4.3armor75/22/3 and separate lesser-essence observations. Do not select or swap categories without source-version proof, or use archive levels as current itemLink identity.','Retained original archive/TBC reference conflict audit inspected; archive states historical reference only.'),
247:('REJECTED_CURRENT_NUMERICAL_USE','https://wowwiki-archive.fandom.com/wiki/Duskweave_Belt','Archived22%dust/75%essence reverses dust-majority actual49belt sample (37dustpositives,12essencepositives;111dustunits,18essenceunits). Keep measured/historical cohorts separate from contradictory archive and scaled current CannotDE catalog. No silent correction or inferred hotfix date.','Two retained primary-comment/archive audits inspected; exact source histogram and units preserved.'),
248:('REJECTED_CURRENT_NUMERICAL_USE','https://wowwiki-archive.fandom.com/wiki/Stoneguard_Band','Archive dust2–5/22%,essence1–2/75%,shard1/3% contradicts500ring Classic source2095dust/381positive (mean5.4987>5),163essence/106positive,13shard/13positive. Classic itemilvl162 versus Retail14 is unresolved context; no blending or modern Retail admission from archive.','Retained original article/archive/itemvariant comparison inspected; not a new empirical source.'),
}

def scope(r):
    s={k:r.get(k) for k in ('method','inputItemID','inputName','inputRank','inputsPerCast','gearGroup','dataDate','patch')}
    variant=re.search(r'\["(\d+:\d+:-?\d+)"\]',str(r.get('quote') or ''))
    if variant:s['exactNativeItemSignature']=variant.group(1)
    if r.get('outputItemID') in (267654,227662):
        s['condition']={'type':'profession-knowledge-drop','weeklyEligibility':'unverified','sourceProfileOnly':True}
    if 'beta' in str(r.get('gearGroup') or {}).lower() or 'beta' in str(r.get('notes') or '').lower() and 'historical' in str(r.get('notes') or '').lower():
        s['sourceEnvironment']='beta-or-historical-context-preserved-in-source-facts'
    return s

def material(r):
    m={k:r.get(k) for k in ('outputItemID','outputName','outputRank')}
    if not m['outputItemID']:
        for name,ids in FAMILIES.items():
            if name.lower() in str(m['outputName']).lower():m['legalFamilyIDs']=ids; m['rankBinding']='unverified';break
    if r.get('outputItemID') in (267654,227662) or 'knowledge' in str(r.get('outputName') or '').lower():m['economicPolicy']='nontradable-knowledge'
    return m

def field(name,value,unit,basis,**kw):
    return dict(field=name,value=value,unit=unit,basis=basis,**kw)

def contract(c,r):
    n,h,q=(r.get(k) for k in ('casts','castsWithDrop','totalQuantity'))
    note=(r.get('notes') or '')+' '+(r.get('quote') or '')
    low=note.lower(); fs=[]; rejected=[]
    native=any(x in low for x in ('enchantrix','enchantedlocal','enchanteditemtypes','savedisenchant','positive material counter'))
    looter='looter' in low or 'wowhead-looter' in str(r.get('studyKey'))
    selected=any(x in low for x in ('self-selected','single positive','positive anecdote'))
    if r.get('studyKey')=='typeless-midnight-20261031-9910':selected=True
    conditional=native or (h is not None and n is None)
    # N/H/Q remain untouched source facts even if an active model uses zero samples.
    if num(h) and h>0 and num(q) and q>=h:
        fs.append(field('conditionalQuantity',q/h,'material-units / recorded-material-positive-event','Q/H',numerator=q,denominator=h,denominatorMeaning='recorded-material-positive-events',notActualCastDenominator=True))
    elif num(h) and h>0 and num(q) and q<h:
        rejected.append('Q<H is inconsistent with at least one material unit per positive event; retain counters, do not fit a positive quantity.')
    if num(n) and n>0 and num(q) and q>=0 and not selected:
        fs.append(field('expectedQuantity',q/n,'material-units / source-reported-operation','Q/N',numerator=q,denominator=n,sourceOperationDenominator=n,sourceCounterSemantics='website-reported-aggregate' if looter else 'source-reported-completed-operations'))
    if selected and num(q) and q>0 and not num(h):
        fs.append(field('observedPositiveQuantity',q,'reported-material-units in this selected positive anecdote','source-explicit-positive-outcome',unconditionalEV=False,hardGameBounds=False))
    a,per=r.get('averageShown'),r.get('averagePer')
    if num(a) and a>=0 and per in ('cast','input'):
        fs.append(field('expectedQuantity' if per=='cast' else 'expectedQuantityPerInput',a,'material-units / '+('source-reported-operation' if per=='cast' else 'reported-input-item'),'source-explicit-mean',actualSampleDenominator=n if num(n) else None,rounded=True))
    # Source K sometimes deliberately lives in the quote rather than measured H.
    kh=h
    if kh is None and looter:
        matches=re.findall(r'(\d[\d,]*)\s+out of\s+(\d[\d,]*)', str(r.get('quote') or ''))
        if not matches:matches=re.findall(r'(?:K\s*=\s*|occurrence\s+)(\d[\d,]*)\s*(?:/|out of)\s*(\d[\d,]*)',note)
        if matches:
            x,y=map(lambda v:int(v.replace(',','')),matches[0])
            if num(n) and y==n:kh=x
        if kh is None:
            pairs={(int(x.replace(',','')),int(y.replace(',',''))) for x,y in re.findall(r'(\d[\d,]*)\s+out of\s+(\d[\d,]*)',note)}
            same={x for x,y in pairs if num(n) and y==n}
            if len(same)==1:kh=same.pop()
        if kh is None:
            m=re.search(r'\bK\s*=\s*(\d[\d,]*)',note)
            if m:kh=int(m.group(1).replace(',',''))
    if num(n) and n>0 and num(kh) and 0<=kh<=n and not selected:
        fs.append(field('dropChance',kh/n,'source-material-occurrences / source-reported-operation','K/N' if looter else 'H/N',numerator=kh,denominator=n,referenceOnly=looter,reportedNumeratorMeaning='source-material-occurrences' if looter else 'source-positive-operations',neverMaterialUnits=True))
    if num(r.get('minSeen')) and num(r.get('maxSeen')) and r['minSeen']>0 and r['maxSeen']>=r['minSeen']:
        fs.append(field('positiveQuantityRange',[r['minSeen'],r['maxSeen']],'material-units / positive-event','source-positive-stack-range',hardGameBounds=False))
        if looter and r['minSeen']==r['maxSeen'] and num(n) and n>0 and num(kh) and q is None:
            fs.append(field('expectedQuantity',kh*r['minSeen']/n,'material-units / source-reported-operation','K*fixed-positive-stack/N',numerator=kh*r['minSeen'],denominator=n,referenceOnly=True))
    nominal=NOMINAL.get(r.get('studyKey'))
    if nominal and not num(n):
        den,meaning,override,approx=nominal;qty=q if num(q) else override
        if num(qty):fs.append(field('expectedQuantityPerInput',qty/den,'material-units / reported-nominal-input','source-units/reported-inputs',numerator=qty,denominator=den,denominatorMeaning=meaning,reportedCompletedCasts=None,approximate=approx,modelAssumption='All reported nominal inputs contributed to the stated material tally; this is not a completed-cast measurement.'))
    if conditional: rejected.append('Full completed-operation denominator is absent; Q/H can inform positive-event quantity only, never unconditional mean or occurrence chance.')
    if not any(f['field']=='expectedQuantity' for f in fs): rejected.append('No supported unconditional per-operation material-unit mean: occurrence counts alone do not specify a positive stack distribution, and unallocated totals alone do not specify an operation denominator.')
    if not r.get('outputItemID'):
        rejected.append('Exact material ID/rank is unverified; preserve a named/unpriced field. Distinct unidentified source rows cannot be assigned to ranks by row order or collapsed into a family occurrence probability.')
    if not r.get('inputItemID') and not (r.get('gearGroup') or {}).get('quality'):
        rejected.append('Exact input identity and a rarity-scoped gear category are both absent. Quantities remain source-context facts; no fabricated bag-item conversion or broad rarity inference from output material alone.')
    if 'around 600' in low or 'approximately 600' in low:
        rejected.append('Approximate600 wands is not an exact event denominator; zero reported Crystal units is a context-specific anecdote, not a hard population zero.')
    if 'one run' in low or 'per-run' in low or 'per-run' in str(r.get('studyKey')):
        if not num(n):rejected.append('A dungeon run aggregates unidentified inputs; one run is not one disenchant operation.')
    if r.get('inputItemID')==272246:
        rejected.append('Miststalker272246 base CannotDE versus positive historical Looter table is an unresolved eligibility/variant conflict. Numeric reference cannot grant action access or overwrite verified eligibility.')
    if r.get('outputItemID') in (267654,227662):
        rejected.append('Knowledge eligibility/weekly cap was not established. The source-specific zero cannot become a zero chance or baseline for an eligible character; knowledge is not a marketable material.')
    if native:rejected.append('Native SaveDisenchant is per reagent loot slot; summing positive-material counters does not establish casts or mutual exclusivity. No nominal one-primary budget is adopted without a separate era/rarity mechanism contract.')
    merged={}
    for f in fs:
        key=f['field']
        if key not in merged:merged[key]=f
        else:merged[key].setdefault('corroboratingSourceFields',[]).append(f)
    return list(merged.values()),rejected

def main():
    inp=json.loads(INPUT.read_text(encoding='utf-8-sig')); sources=inp['sources']; allrows=engine.load()
    current=collections.defaultdict(list);replacers=collections.defaultdict(list)
    for r in allrows:
        current[(r['_file'],r.get('id'))].append(r)
        if r.get('replaces'):replacers[r['replaces']].append(r)
    corrections=[]
    for line,raw in enumerate((ROOT/'research/v3/corrections.jsonl').read_text(encoding='utf-8').splitlines(),1):
        try:corrections.append((line,json.loads(raw)))
        except ValueError:pass
    review=[]; proposals=[];counts=collections.Counter();coverage=[];files={}
    for index,s in enumerate(sources):
        reviewed=[]
        for c in s.get('candidateRows',[]):
            hits=current.get((c['sourceFile'],c['recordID']),[])
            if len(hits)>1:raise AssertionError(('ambiguous effective row',c['locator']))
            r={k:v for k,v in (hits[0] if hits else c['originalEvidenceRow']).items() if not k.startswith('_')}
            corr=[dict(locator='research/v3/corrections.jsonl:'+str(ln),**cr) for ln,cr in corrections if cr.get('recordID')==c['recordID'] and cr.get('file') in (None,c['sourceFile'])]
            fs,rej=contract(c,r)
            for f in fs:
                f['decision']='METADATA_REFERENCE' if not r.get('outputItemID') and f['field'] in ('dropChance','positiveQuantityRange') else 'ADMIT'
                if f['decision']=='METADATA_REFERENCE':
                    f['currentNumericalUseRejected']='An individual same-name source row has no linked material/rank identity. Preserve this row counter/range as source metadata, not a rank-bound or pooled-family probability.'
            active=bool(hits)
            if not active:rej.insert(0,'Frozen row is superseded or excluded by the current append-only effective interpreter; its old numbers are not reactivated by this review.')
            decision='ADMIT' if active and any(f['decision']=='ADMIT' for f in fs) else 'REJECTED_CURRENT_NUMERICAL_USE'
            if index==21: decision='ALREADY_REPRESENTED';rej.insert(0,'Four gear-group zero cross-check rows represent the same Classic beta itemized operations; no additional independent denominator or cohort is added.')
            # Mixed category and unknown linked rank fields are useful facts, but
            # this catalogue does not silently create exact item/rank bindings.
            profile={k:r.get(k) for k in ('skill','specialization','stats','inputRank')}
            profile.update(normalizationPolicy='Preserve the reported source profile. Invert a verified forward curve only when the same scope/profile is identifiable; otherwise an explicit unknown-profile prior may use confidence0, never claim a neutral source capture.',sourceProfileConfidence=0)
            rr=dict(locator=c['locator'],recordID=c['recordID'],studyKey=r.get('studyKey'),decision=decision,currentEffective=active,
                    frozenRawSHA256=c['rawSHA256'],frozenEffectiveSHA256=c['effectiveSHA256'],currentEffectiveSHA256=sha(r),
                    scope=scope(r),material=material(r),sourceProfile=profile,sourceFacts=r,fieldDecisions=fs,
                    currentNumericalLimits=rej,correctionReceipts=corr,replacedBy=[dict(recordID=a.get('id'),sourceFile=a['_file']) for a in replacers.get(c['recordID'],[])],
                    futureEvidenceTrigger='Only the listed missing field/identity/context needs new evidence. Existing original quotes, quantities and provenance stay credited; no routine re-review or new game batch is requested.')
            reviewed.append(rr);coverage.append(c['locator']);counts[decision]+=1
            fpath=ROOT/c['sourceFile']
            if c['sourceFile'] not in files:files[c['sourceFile']]=sha(fpath.read_bytes())
            if decision=='ADMIT':
                for f in fs:
                    if f['decision']!='ADMIT':continue
                    proposals.append(dict(proposalID='deb:'+c['recordID']+':'+f['field'],sourceKey=s['sourceKey'],locator=c['locator'],recordID=c['recordID'],studyKey=r.get('studyKey'),scope=scope(r),material=material(r),field=f,sourceProfile=profile,
                        sourceRecordSHA256=sha(r),sourceFileSHA256=files[c['sourceFile']],sourceURLs=s.get('rawURLs') or [r.get('source',{}).get('url')],
                        empiricalSamples=0,modelConfidenceCap=0,sourceSupportMaximum=20,sourceReportedCounters={k:r.get(k) for k in ('casts','castsWithDrop','totalQuantity','inputsProcessed','inputsPurchased','inputsRefunded')},
                        application=dict(exactOutputBindingKnown=bool(r.get('outputItemID')),exactInputBindingKnown=bool(r.get('inputItemID')),categoryScopeKnown=bool((r.get('gearGroup') or {}).get('quality')),actionAccessGranted=False,
                            numericalValuationEligible=bool(r.get('outputItemID')) and bool(r.get('inputItemID') or (r.get('gearGroup') or {}).get('quality')) and f['field'] in ('expectedQuantity','expectedQuantityPerInput'),
                            standaloneFieldOnly=f['field'] in ('dropChance','conditionalQuantity','positiveQuantityRange','observedPositiveQuantity'),namedUnpricedOnly=not bool(r.get('outputItemID'))),
                        integrationPolicy='Field-only reference. Preserve source filters, cohort dedupe, current access/variant gates and extra outputs. Unpriced named/rank-unknown fields cannot create numerical gold EV. Do not blend incompatible source profiles/epochs or count aliases as extra samples.'))
        lead=None
        if s.get('explicitLeadStillPending'):
            dec,url,facts,inspection=LEADS[index];lead=dict(decision=dec,url=url,facts=facts,inspection=inspection,readExistingPublishedInformation=True,futureEvidenceTrigger='Specific missing identity/unit/epoch in the facts above, if numerical use is rejected; otherwise implementation of the preserved source contract, not another generic source review.')
        refs=[]
        for receipt in s.get('masterReviewFacts',[]):
            path=ROOT/receipt['receiptPath']
            refs.append(dict(path=receipt['receiptPath'],sha256=sha(path.read_bytes()) if path.exists() else None,title=receipt.get('title')))
        summary='; '.join(sorted(set(f['field'] for rr in reviewed for f in rr['fieldDecisions']))) or (lead['facts'] if lead else 'No identifiable numerical operation field is supplied; original facts retained below.')
        review.append(dict(sourceIndex=index,sourceKey=s['sourceKey'],sourceURLs=s.get('rawURLs'),reviewStatus='REVIEWED_CURRENT_BASELINE_PIPELINE',
            reviewScope='All frozen candidate locators and every supplied numerator, quantity, mean, range, input/output identity, source profile and epoch; explicit lead assessed separately.',
            sourceConclusion=summary,existingReviewFactsCredited=refs,leadDecision=lead,rows=reviewed))
    expected=[c['locator'] for s in sources for c in s.get('candidateRows',[])]
    assert len(sources)==249 and len(expected)==1249
    assert len(coverage)==len(set(coverage))==1249 and set(coverage)==set(expected)
    assert len(LEADS)==35 and sum(x['leadDecision'] is not None for x in review)==35
    revision=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip()
    receipt=dict(schemaVersion=1,lane='disenchant-b-and-35-leads',researchRevision='0cd0bad8867e7a8d909b4ecae74f6136a3e23d42',checkoutRevision=revision,
       inputSHA256=sha(INPUT.read_bytes()),sourceCount=len(review),candidateRowCount=len(coverage),explicitLeadCount=35,currentEffectiveRowCount=sum(r['currentEffective'] for s in review for r in s['rows']),
       rowDecisionCounts=dict(counts),proposalFieldCount=len(proposals),coverageExact=True,coveredLocators=sorted(coverage),rawSourceFileSHA256=files,
       noNewGameActions=True,noFabricatedCasts=True,zeroActiveEmpiricalSamplesForProposals=True,sourceRowsUntouched=True)
    write('review.json',dict(receipt=receipt,sources=review))
    workbook,wbprops=workbook_review()
    write('workbook-review.json',workbook)
    write('proposals.json',dict(schemaVersion=1,receipt=receipt,fieldProposals=proposals,leadModelProposals=lead_models(),workbookFieldProposals=wbprops))
    print(json.dumps({k:v for k,v in receipt.items() if k not in ('coveredLocators','rawSourceFileSHA256')},indent=2))

def lead_models():
    p=[]
    def add(id,key,method,inputid,batch,outputs,**kw):
        p.append(dict(proposalID='deb-lead:'+id,sourceKey=key,method=method,inputItemID=inputid,inputsPerCast=batch,materials=outputs,empiricalSamples=0,modelConfidenceCap=0,sourceSupportMaximum=20,**kw))
    def mats(ids,values,den):return [dict(id=i,expectedQuantity=q/den,sourceQuantity=q,sourceDenominator=den) for i,q in zip(ids,values)]
    add('nirosu-riverbud-140','blizzforum:226400','Mill',152505,20,mats([153635,153636,153669],[2272,918,376],140),recipeID=256217,expansionID=7,sourceReportedCompletedOperations=140,sourceEpoch='2019-07-29 BfA',sourceInputs=2800,denominatorMeaning='reported-mass-milling-operations',noOrdinaryCastConversion=True)
    names=['Argulite','Labradorite','Chemirine','Hesselian','Lightsphene','Florid Malachite']
    gemids=[151718,151579,151720,151721,151719,151722]
    arms=[('op-250a',250,[34,29,34,16,32,14]),('op-150',150,[20,21,18,2,19,6]),('op-250b',250,[37,28,32,21,25,14]),('bizgob-291',291,[34,38,30,16,32,18]),('camzaman-150',150,[16,15,20,13,17,6]),('deandipp-225',225,[27,27,36,20,32,22])]
    for arm,n,vals in arms:
        iscam=arm.startswith('camzaman'); donor={'bizgob-291':'reddit:6ydssd','camzaman-150':'reddit:6x188h','deandipp-225':'reddit:6yq5yi'}.get(arm,'reddit:6ygegx')
        outputs=[dict(id=iid,name=name,sourceQuantity=q,**({'expectedQuantityPerReportedInput':q/3000} if iscam else {'expectedQuantity':q/n})) for iid,name,q in zip(gemids,names,vals)]
        add('empyrium-'+arm,'reddit:6ygegx','Prospect',151564,None if iscam else 20,outputs,recipeID=None if iscam else 247761,canonicalOriginalSourceKey=donor,
            identityMappingReceipts=['legacy-20261107-001..006','https://www.wowhead.com/spell=247761/mass-prospect-empyrium'],sourceReportedCompletedOperations=None if iscam else n,sourceReportedInputs=3000 if iscam else 20*n,
            sourceCounterProof='Original Camzaman purchased-input tally, not a completed-cast counter.' if iscam else ('Secondary-source225×20 retelling; original page not retrieved.' if arm.startswith('deandipp') else 'Original author explicitly reported mass batches.'),
            sourceEpoch='Legion2017',arm=arm,keepDerivativeAggregateUnweighted=True,overlapPolicy='OP three arm overlaps unverified: preserve alternatives, do not sum as independent batches. Copied donor vectors belong only to original donor source/cohort, not the repost.')
    add('empyrium-singing-sunflower-4800','reddit:6ygegx','Prospect',151564,None,[dict(id=iid,name=name,sourceQuantity=q,expectedQuantityPerReportedInput=q/4800) for iid,name,q in zip(gemids,names,[33,28,29,11,32,17])]+[dict(id=129100,name='Gem Chip',sourceQuantity=960,expectedQuantityPerReportedInput=.2)],
        canonicalOriginalSourceKey='reddit:6x188h',sourceURL='https://www.reddit.com/r/woweconomy/comments/6x188h/prospecting_3000_empyrium/',originalCommenter='-SingingSunflower-',sourceReportedInputs=4800,sourceReportedCompletedOperations=None,sourceEpoch='Legion2017',overlapPolicy='Separate named commenter, not Camzaman original3000ore. No manual/mass operation denominator invented.')
    add('empyrium-maiazndrew-389','reddit:6ywwdq','Prospect',151564,20,[dict(id=iid,name=name,sourceQuantity=q,expectedQuantity=q/389) for iid,name,q in zip(gemids,names,[56,32,40,55,55,53])]+[dict(id=129100,name='Gem Chip',sourceQuantity=1556,expectedQuantity=4)],recipeID=247761,identityMappingReceipts=['legacy-20261107-001..006','https://www.wowhead.com/spell=247761/mass-prospect-empyrium'],sourceReportedCompletedOperations=389,sourceInputs=7780,sourceSkill='1/800 at start',sourceEpoch='Legion2017')
    bfa=[(152510,30000,6000,5,[24819,9478,9844]),(152511,100000,5000,20,[82510,31595,13237]),(152508,100000,5000,20,[82453,31243,13248]),(152509,100000,5000,20,[82190,31583,13223]),(152505,100000,5000,20,[82486,31595,13030]),(152506,100000,5000,20,[82595,31534,13137]),(152507,100000,5000,20,[82676,31775,13367])]
    for iid,inputs,n,batch,values in bfa:
        add('bilis-'+str(iid),'reddit:98oyfb','Mill',iid,batch,mats([153635,153636,153669],values,n),sourceReportedCompletedOperations=n,sourceInputs=inputs,sourceEpoch='BfA2018beta',onlySourceEpochReference=True,neverPromoteToCurrentLiveCapture=True)
    for iid,inputs,n,batch,values in bfa:
        rounded=[round(q/inputs,3) for q in values]
        add('sygon-bfa-'+str(iid),'reddit:u0f32m','Mill',iid,None,[dict(id=oid,expectedQuantityPerReportedInput=v) for oid,v in zip([153635,153636,153669],rounded)],sourceEpoch='2022 source-model reference',sourceReportedCompletedOperations=None,
            unitMeaning='Published per-input-herb yield ratio, independently read from the source formula; not the outer5x pricing expression.',originalCohortIndependenceUnknown=True,noIndependentSampleWeight=True)
    for source in ('boostmatch.gg/blog/wow/articles/wow-midnight-engineering-guide','wow-professions.com/midnight/engineering-guide'):
        add('recycling-'+('boostmatch' if source.startswith('boost') else 'wowprof'),source,'Recycle',None,5,[dict(name='Evercore or Aetherlume, native input-specific family',basePooledExpectedQuantity=1.5,fullPooledExpectedQuantity=3)],expansionID=11,profession='Engineering',sourceReportedCompletedOperations=None,sourceProfileEndpoints=[{'RecyclingPoints':0},{'RecyclingPoints':30}],inputPolicy='Require native legal recipe input/target family; no universal crafted-reagent allowlist.',rankPolicy='No quality split supplied; pooled output only, no arbitrarily selected rank price.')
    add('magma-thresher-500','reddit:109yr4s','Prospect',199344,None,[dict(name=name,sourceQuantity=q,expectedQuantityPerReportedInput=q/500) for name,q in [('Diamond',0),('Nozdorite',6),('Neltharite',3),('Ysemerald',2),('Alexstraszite',4),('Malygite',1),('Eternity Amber',45),('Mystic Sapphire',11),('Queen\'s Ruby',16),('Sundered Onyx',17),('Vibrant Emerald',16),('Glass',121),('Stone',140)]],sourceReportedCompletedOperations=None,sourceReportedInputs=500,sourceEpoch='2023-01-12 Dragonflight',sourceSpecialization='25 Prospecting KP',sourceOutputRank='allR2 claimed; exact links absent',inputPolicy='No guessed fish consumption batch; per-input reference or informational named pool only until native recipe access/batch verified.')
    for reporter,epoch,values in [('Katahn1','beta',[53,23,8,1]),('Katahn2','beta',[62,24,9,1]),('Footzies1','unknown',[61,22,7,1]),('Raex1','unknown',[59,20,7,1]),('Grimmella1','unknown',[64,28,6,3]),('kassia1213-1','unknown',[56,20,5,1]),('kassia1213-2','unknown',[68,27,9,1])]:
        extras=['BS Plans: Murder Row Fishhook'] if reporter=='kassia1213-2' else []
        add('moxie-bag-'+reporter,'wow-professions.com/midnight/npc/melaris','Use',260537,1,[dict(name=name,legalRankIDs=rankids,sourceQuantity=q,expectedQuantity=q) for name,rankids,q in zip(['Eversinging Dust','Radiant Shard','Dawn Crystal','Petrified Root'],[[243599,243600],[243602,243603],[243605,243606],[251285]],values)],sourceURL='https://www.wowhead.com/item=260537/master-enchanters-surplus-reagents',sourceReportedCompletedOperations=1,sourceEpoch=epoch,reporter=reporter,sourceCurrencyCost={'currencyID':3258,'amount':600},rankKnown=reporter in ('Katahn1','Katahn2','Footzies1'),namedUnpricedExtras=extras,neverTreatCurrencyAsCopper=True,accessGrantedByStudy=False)
    p[-1]['additionalNamedRecipeReceipt']={'reporter':'TomiOmit','name':'Design: Stabilizing Gemstone Bandolier','materialCounts':None,'notAnEighthMaterialVector':True,'noDropChanceInferred':True}
    add('zarp-shatter-refunds','blizzforum:2261410','Craft',None,None,[],sourceReportedCompletedOperations=800,sourceReturnedUnits=45,refundUnitsPerReportedOperation=45/800,sourceResourcefulnessPercent=15,sourceSkill=67,recipePolicy='Recipe/input shard identity is not stated in this comment; do not bind by a generic word shatter to one era/recipe.',notProcChance=True)
    native,nsrc=native_items()
    silver=[]
    for label,name,value in [('Stone','Dusk-Shrouded Stone',1.367),('Glass','Crystalline Glass',.905),('Diamond','Eversong Diamond',.0635),('Lapis','Amani Lapis',.2185),('Flaw Lapis','Flawless Amani Lapis',.193),('Garnet','Sanguine Garnet',.2225),('Flaw Garnet','Flawless Sanguine Garnet',.1835)]:
        ids=sorted(int(k) for k,v in native.items() if v.get('name')==name and v.get('expansionID')==11)
        assert len(ids)==2,(name,ids)
        silver.append(dict(name=name,sourceLabel=label,legalRankIDs=ids,rankUnknown=True,expectedQuantity=value,sourceFormula='='+str({'Stone':2734,'Glass':1810,'Diamond':127,'Lapis':437,'Flaw Lapis':386,'Garnet':445,'Flaw Garnet':367}[label])+'/2000',
            interpretationAssumption='Flaw abbreviation interpreted as native Flawless species; no Flawed species exists in this native gem family.' if label.startswith('Flaw ') else 'Source generic shorthand interpreted as this native species, output quality pooled.',
            condition={'requires':'Silver Scrapper at least1 invested point','sourceUnlockState':'assumed-eligible-not-captured'} if label=='Diamond' else None))
    assert native['237365']['name']=='Brilliant Silver Ore' and native['237365']['qualityRank']==2
    add('silver-source-calculator','gdoc:1f-d39_TW0MARV5Egib2IPuW8kTU5-_C8PIgAkz2A4IU','Prospect',237365,5,silver,sourceReportedCompletedOperations=None,sourceProfile='unknown skill/equipment/specialization; confidence0 unknown-source-profile prior',sourceInputRank=2,nativeIdentityReceipt=nsrc,
        denominatorMeaning='Source-calculator rates per single prospect, not2000 measured operations. Scenario1000 casts is not observed N.',rankPolicy='Pooled quality outputs only. No arbitrary exact-rank market price.',sourceCellsReceipt='disenchant-b-leads-original-silver-cells.json')
    return p

def native_items():
    path=ROOT.parent/'catalogue-backlog-pipeline-20261120/database/research/profession-effect-catalog-70961.json'
    x=json.loads(path.read_text(encoding='utf-8'));return x['recipeRouting']['items'],dict(path=str(path),sha256=sha(path.read_bytes()),build=70961)

def workbook_review():
    path=OUT/'disenchant-b-leads-original-prospecting-workbook.txt';text=path.read_text(encoding='utf-8');matrix=list(csv.DictReader(io.StringIO(text.split('\f')[0])))
    native,nsrc=native_items();reviews=[];props=[];counts=collections.Counter()
    def number(v):
        try:return float(v.replace('~','').replace('%','').strip())
        except (ValueError,AttributeError):return None
    for row in matrix:
        ix=int(row['']);prob=number(row['Probability %']);mn=number(row['Yield Min']);mx=number(row['Yield Max']);inp=int(row['Ore Item-ID']);oid=int(row['Output Item-ID']);exp=row['Expansion'];modern='separate item IDs' in row['Quality']
        im=native.get(str(inp),{});om=native.get(str(oid),{});fields=[];limitations=[]
        if prob is not None:fields.append(field('dropChance',prob/100,'reference occurrences / nominal5ore operation','source-model-percentage',sourceDisplayed=row['Probability %'],referenceOnly=True))
        if mn is not None:fields.append(field('positiveQuantityMinimum',mn,'source-reference-material-units / positive-event','source-reference-minimum',hardGameBounds=False))
        if mx is not None:fields.append(field('positiveQuantityMaximum',mx,'source-reference-material-units / positive-event','source-reference-maximum',hardGameBounds=False))
        if not fields:dec='METADATA_REFERENCE';limitations.append('No probability, quantity or range in this actual matrix row. Advertised104 quantity rows do not fill this blank.')
        elif exp=='Mists of Pandaria':dec='REJECTED_CURRENT_NUMERICAL_USE';limitations.append('Workbook explicitly cites MoPClassic prospecting table, excluded from current Retail evidence. Original numbers preserved, not zeroed.')
        else:dec='ADMIT'
        mat=dict(outputItemID=oid,outputName=row['Prospects into Gem'],representativeVariantOnly=modern)
        op=dict(method='Prospect',inputItemID=inp,inputName=row['Ore'],inputsPerCast=5,sourceExpansion=exp,sourceEnvironment='historical/reference; original per-row source not linked',inputRankUnknown=modern)
        if modern:
            if im.get('qualityFamilyID'):
                op['legalInputRankIDs']=sorted(int(k) for k,v in native.items() if v.get('qualityFamilyID')==im['qualityFamilyID'] and v.get('name')==im.get('name'))
                op['inputItemID']=None
            if om.get('qualityFamilyID'):
                mat['legalRankIDs']=sorted(int(k) for k,v in native.items() if v.get('qualityFamilyID')==om['qualityFamilyID'] and v.get('name')==om.get('name'))
                mat['outputItemID']=None;mat['rankPolicy']='Native family pool, source representative ID is not an observed quality-linked outcome.'
            limitations.append('Source rates refer to generic rank/species references, not a verified input/output rank pair; retain native pools and unpriced named fields where family-aware pricing is unavailable.')
        if 'Eversong Diamond' in row['Prospects into Gem']:
            op['condition']={'requires':'At least1 invested point in this ore-specific ProficientProcessor/ProspectingPro child node','sourceUnlockState':'assumed-eligible-not-captured'}
        if mx is None and mn is not None:limitations.append('Minimum alone does not establish conditional mean or maximum; no one-unit assumption or E=P.')
        limitations.append('No empiricalN,H,Q or histogram. This is one compiled reference workbook, not a new independent experiment per row. Stronger compatible source quantities retain precedence.')
        review=dict(matrixRowIndex=ix,worksheetRow=ix+2,rawRow=row,decision=dec,scope=op,material=mat,fieldDecisions=fields,currentNumericalLimits=limitations,sourceRecordSHA256=sha(row))
        reviews.append(review);counts[dec]+=1
        if dec=='ADMIT':
            for f in fields:props.append(dict(proposalID='deb-workbook:'+str(ix)+':'+f['field'],sourceKey='gdoc:11kVrPOVY0Jei3xmBL1q_I9fsFAl3QY6d',worksheet='Prospecting matrix',worksheetRow=ix+2,scope=op,material=mat,field=f,sourceRecordSHA256=sha(row),sourceExtractionSHA256=sha(path.read_bytes()),empiricalSamples=0,modelConfidenceCap=0,sourceSupportMaximum=20,standaloneFieldOnly=True,unconditionalEVGranted=False))
    assert len(reviews)==387 and sum(number(r['Probability %']) is not None for r in matrix)==212
    assert sum(number(r['Yield Min']) is not None for r in matrix)==212 and sum(number(r['Yield Max']) is not None for r in matrix)==190
    return dict(receipt=dict(sourceCount=1,matrixRows=387,probabilityRows=212,minimumRows=212,maximumRows=190,expectedQuantityColumnPresent=False,sourceAdvertised104QuantityRowsNotReproducible=True,sourceExtractionSHA256=sha(path.read_bytes()),nativeMappingReceipt=nsrc,decisionCounts=dict(counts),empiricalCastsAdded=0),rows=reviews),props

def addendum():
    path=INPUT.with_name('disenchant_b_and_leads-current-addendum.json')
    inp=json.loads(path.read_text(encoding='utf-8-sig')); reviews=[];proposals=[];locators=[];failures=[]
    blobids={'dmitry_popov':'9237e3019a187ad8da98d1720fda18fc3ae80649','justin':'fd220ce89b1b517bdcad7dad4aa4f5f8b40b8b56','ryan_curran':'48f2eb7088137ece966d4c9d8a3a26f0f11ab746','sskuartfe':'70b58a52b7e3480b670f2e6deda5c0c74d3ccdf6','tk':'1845f110bdd8c37a2290a2faf7dc6ef8479f8b55','xiph':'ab360d1a6363a8ffc718efe3f0ac6a9bbd09ae0e'}
    for s in inp['sources']:
        name=s['sourceKey'].split('/')[-1].removesuffix('.lua');cache=OUT/('disenchant-b-leads-native-'+name+'.lua.txt')
        raw=cache.read_text(encoding='utf-8');match=re.search(r'EnchantedLocal\s*=\s*\{(.*?)\n\}',raw,re.S)
        assert match, name
        native={k:{int(v.split(':')[0]):list(map(int,v.split(':')[1:])) for v in values.split(';')}
                for k,values in re.findall(r'\["([0-9:\-]+)"\]\s*=\s*"([0-9:;]+)"',match.group(1))}
        rows=[]
        for c in s['candidateRows']:
            r=c['originalEvidenceRow']; sc=scope(r); sig=sc.get('exactNativeItemSignature')
            if not sig:
                m=re.search(r'(?:variant|key)\s+(\d+:\d+:-?\d+)',r.get('notes',''));sig=m.group(1) if m else None;sc['exactNativeItemSignature']=sig
            got=native.get(sig,{}).get(r.get('outputItemID'))
            expected=[r.get('castsWithDrop'),r.get('totalQuantity'),0]
            good=got==expected and r.get('casts') is None
            if not good:failures.append(dict(locator=c['locator'],signature=sig,got=got,expected=expected))
            fs,rej=contract(c,r)
            assert len(fs)==1 and fs[0]['field']=='conditionalQuantity', (c['locator'],fs)
            record=dict(locator=c['locator'],recordID=c['recordID'],studyKey=r.get('studyKey'),decision='ADMIT',admittedField='conditionalQuantity',unconditionalMeanDecision='REJECTED_CURRENT_NUMERICAL_USE',
                scope=sc,material=material(r),sourceFacts=r,fieldDecisions=fs,sourceNativeTupleVerified=good,nativeTuple=got,nativeSourceBlobSHA=blobids[name],nativeLFCacheSHA256=sha(cache.read_bytes()),
                frozenRawSHA256=c['rawSHA256'],frozenEffectiveSHA256=c['effectiveSHA256'],currentNumericalLimits=rej,
                futureEvidenceTrigger='For unconditional use only: full completed-operation denominator or a separately verified same-era one-primary-event mechanism. No new review is required for the verified positive-event units.')
            rows.append(record);locators.append(c['locator'])
            proposals.append(dict(proposalID='deb-addendum:'+c['recordID']+':conditionalQuantity',sourceKey=s['sourceKey'],locator=c['locator'],recordID=c['recordID'],studyKey=r.get('studyKey'),scope=sc,material=material(r),field=fs[0],empiricalSamples=0,modelConfidenceCap=0,sourceSupportMaximum=20,
                sourceReportedCounters={'casts':None,'castsWithDrop':r['castsWithDrop'],'totalQuantity':r['totalQuantity']},sourceNativeTupleVerified=good,nativeSourceBlobSHA=blobids[name],sourceRecordSHA256=sha(r),
                application={'standaloneFieldOnly':True,'actionAccessGranted':False,'unconditionalEVGranted':False,'currentEraOrVariantTransferVerified':False}))
        reviews.append(dict(sourceKey=s['sourceKey'],reviewStatus='REVIEWED_CURRENT_BASELINE_PIPELINE',primarySourcePin='5918ca3e44f6e4bba9071731ab28be3189498001',nativeSourceBlobSHA=blobids[name],sourceNativeRowsVerified=len(rows),
            sourceConclusion='Original exact-variant EnchantedLocal positive material counters independently reparsed. Q/H is a conditional source quantity, H is not all casts; trailing0 is not a zero bin. Historical-source profile/era remain unknown. No group/local aggregate double counting or current action access.',rows=rows))
    assert len(reviews)==6 and len(locators)==len(set(locators))==515 and not failures,failures[:5]
    receipt=dict(schemaVersion=1,researchRevision='0cd0bad8867e7a8d909b4ecae74f6136a3e23d42',inputSHA256=sha(path.read_bytes()),sourceCount=6,candidateRowCount=515,verifiedOriginalTuples=515,coverageExact=True,coveredLocators=sorted(locators),unconditionalEVProposals=0,actualCastsInvented=0,
        retrieval='Exact pinned GitHub connector files fetched2026-11-20. Local display copies normalize CRLF to LF; upstream Git blob SHA is separately retained, not confused with local cache SHA256.')
    write('current-addendum-review.json',dict(receipt=receipt,sources=reviews));write('current-addendum-proposals.json',dict(receipt=receipt,fieldProposals=proposals))
    print(json.dumps({k:v for k,v in receipt.items() if k!='coveredLocators'},indent=2))

if __name__=='__main__':
    addendum() if '--addendum' in sys.argv else main()
