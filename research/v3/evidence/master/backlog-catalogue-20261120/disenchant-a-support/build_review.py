"""Reproduce the finite DE-A catalogue from frozen rows and reviewed source semantics.

This is an audit artifact, not a producer, scraper, or estimator of measured casts.
Curated scope overrides below are decisions made from the quoted original evidence.
"""
import collections
import copy
import hashlib
import json
import re
from pathlib import Path

HERE = Path(__file__).resolve().parent
OUT = HERE.parent
REPO = HERE.parents[5]
INPUT = REPO.parent / '.validation/backlog-closure-20261120/inputs/disenchant_a.json'
DOC = json.loads(INPUT.read_text(encoding='utf-8'))

def digest(value):
    return hashlib.sha256(json.dumps(value, sort_keys=True, ensure_ascii=False, separators=(',', ':')).encode()).hexdigest()

CORRECTIONS = collections.defaultdict(list)
for line in (REPO / 'research/v3/corrections.jsonl').read_text(encoding='utf-8').splitlines():
    if line.strip():
        c = json.loads(line)
        CORRECTIONS[(c.get('file'), c.get('recordID'))].append(c)

NATIVE_FILES = dict(zip(range(10, 19), ['ereduns-277', 'alex-mitchell', 'astroid', 'ereduns-5918', 'imba', 'pawelc', 'ploxl', 'dmitry', 'riku6']))
NATIVE = {}
for number, name in NATIVE_FILES.items():
    text = (HERE / (name + '.lua.txt')).read_text(encoding='utf-8')
    table = 'EnchantedItemTypes' if number in (10, 12, 17) else 'EnchantedLocal'
    body = re.search(r'\b' + table + r'\s*=\s*\{(.*?)\n\}', text, re.S).group(1)
    NATIVE[number] = (table, dict(re.findall(r'\["([^"\n]+)"\]\s*=\s*"([^"\n]+)"', body)), hashlib.sha256(text.encode()).hexdigest())

# Nominal stock budgets are permitted model inputs, never renamed measured casts.
# Only the listed original cohort supplies this denominator. Purchases, quests and
# mixed-source inventories without a quantified processed stock are not filled in.
NOMINAL = {
 'artisansofazeroth-netherweave-108belts':108,
 'wowhead-21849-53050-332crafts':332,
 'reddit-g8xuhl-600-bracer-shuffle':600,
 'reddit-gdmjtv-independent-reply-1000-bracers':1000,
 'reddit-k1ke8a-comment-skill-25-1000-crafted':1000,
 'reddit-k1ke8a-comment-skill-50-1000-crafted':1000,
 'reddit-k1ke8a-comment-skill-75-1000-crafted':1000,
 'reddit-k77ujv-comment-200-shadowlace-cuffs':200,
 'wowhead-allakhazam-rough-bronze-ten-sent-to-alt':10,
 'wowhead-small-glimmering-allakhazam-rough-bronze-ten-crafted-four-shards':10,
 'allakhazam-smallglimmering-roughbronze-ten-constructed-4shards-original':10,
 'thottbot-wizardweave-five-robes-4essence4dust':5,
 'wowhead-wotlk-14132-allakhazam-three-crafted-two-essence-four-dust':3,
 'wowhead-16202-comment-magneith-21-wizardweave-robes':21,
 'wowhead-16203-comment-930224-runecloth-14-crafted-eight-gees':14,
 'wowhead-21852-darkmagi91-onehundred-bracers':100,
 'wowhead-21852-darkmagi91-onehundred-pants':100,
 'wowhead-21852-darkmagi91-100-pants-de-test':100,
 'wowhead-21852-darkmagi91-100-bracers-de-test':100,
 'wowhead-34054-854192-seven-crafted-frostwoven-belts':7,
 'wowhead-40957-jabell4610-34-crafted-mats':34,
 'wowhead-40957-jabell4610-34-crafted-helms-output-units':34,
 'wowhead-41543-143880-18-made-for-de':18,
 'wowhead-tbc-hillmans-shoulders-biocyte-491-original':491,
 'wowhead-43249-125208-100-crafted-unspecified-de':100,
 'wowhead-deathsilk-biocyte-bracers-1476':1476,
 'wowhead-deathsilk-biocyte-cowl-988':988,
 'wowhead-deathsilk-1115451-50-crafted':50,
 'reddit-1ft4m3e-2024-09-30-20k-hammer-shuffle':20000,
 'reddit-1xc29vk-forever-beta-4343-batch-1':10,
 'reddit-1xc29vk-forever-beta-4343-batch-2':10,
 'reddit-1xc29vk-forever-beta-4343-batch-3':10,
 'farli-original-20120409-halaa-six-items-pooled':6,
 'wowhead-classic-wicked-headband-allakhazam-ten-purchased-14-1-8':10,
 'allakhazam-wicked-leather-ten-purchased-material-totals-original':10,
 'wowhead-classic-wicked-headband-thottbot-ten-headbands-eight-greater':10,
 'wowhead-30599-76098-three-avenging-blades':3,
 'wowhead-76098-avenging-blades-three-purchased-reported-de':3,
}

ALIASES = {
 'blizzard-forum-538682-carynara-ten-greens-20240921':'carynara-20240921-ten-greens',
 'blizzard-eu-538682-carynara-10-greens':'carynara-20240921-ten-greens',
 'blizzard-carynara-20240921-ten-green-disenchants':'carynara-20240921-ten-greens',
 'reddit-10ldfo5-20230125-eight-epics-no-resonant':'10ldfo5-op-eight-epics',
 'reddit-10ldfo5-op-20230125-eight-epic-zero-crystals':'10ldfo5-op-eight-epics',
 'reddit-10ldfo5-20230126-four-epics-one-crystal':'10ldfo5-reply-four-epics',
 'reddit-10ldfo5-jan26-commenter-four-epics':'10ldfo5-reply-four-epics',
 'reddit-1f9qado-comment-1000-greens-20240906':'1f9qado-self-crafted-1000',
 'reddit-1f9qado-crafted-1000-greens':'1f9qado-self-crafted-1000',
 'reddit-1fpswuz-comment-before-sep24-dust':'1fpswuz-pre-sep24',
 'reddit-1fpswuz-20240928-pre-20240924-bloodelf':'1fpswuz-pre-sep24',
 'reddit-1fpswuz-comment-sep27-28-dust':'1fpswuz-post-sep24',
 'reddit-1fpswuz-20240928-post-20240924-bloodelf':'1fpswuz-post-sep24',
 'reddit-gdmjtv-original-1000-mixed-bracer-de':'gdmjtv-op1000',
 'reddit-gdmjtv-20200504-1000-tidespray-mixed-rarity':'gdmjtv-op1000',
 'wowhead-allakhazam-rough-bronze-ten-sent-to-alt':'rough-bronze-ten-four-shards',
 'wowhead-small-glimmering-allakhazam-rough-bronze-ten-crafted-four-shards':'rough-bronze-ten-four-shards',
 'allakhazam-smallglimmering-roughbronze-ten-constructed-4shards-original':'rough-bronze-ten-four-shards',
 'wowhead-11137-pegleg-16-black-mageweave-gloves':'pegleg-16-gloves',
 'wowhead-vision-pegleg-16-black-mageweave-gloves':'pegleg-16-gloves',
 'wowhead-21852-darkmagi91-onehundred-bracers':'darkmagi91-bracers100',
 'wowhead-21852-darkmagi91-100-bracers-de-test':'darkmagi91-bracers100',
 'wowhead-21852-darkmagi91-onehundred-pants':'darkmagi91-pants100',
 'wowhead-21852-darkmagi91-100-pants-de-test':'darkmagi91-pants100',
 'wowhead-22445-comment-16088-147-mixed-tbc-jc-rings':'comment16088-mixed-rings147',
 'wowhead-22445-comment-16088-147-mixed-jc-rings':'comment16088-mixed-rings147',
 'wowhead-34054-1023078-forge-of-souls-10-greens':'comment1023078-fos10greens',
 'wowhead-infinite-dust-forge-of-souls-five-runs-ten-greens':'comment1023078-fos10greens',
 'wowhead-40957-jabell4610-34-crafted-mats':'jabell4610-34helms',
 'wowhead-40957-jabell4610-34-crafted-helms-output-units':'jabell4610-34helms',
 'wowhead-43249-220069-120-explicit-de-conditional-dust':'comment220069-120rings',
 'wowhead-43249-220069-120-explicit-de':'comment220069-120rings',
}

def canonical_cohort(e, source_key, looter):
    key = e.get('studyKey')
    if key in ALIASES: return ALIASES[key]
    if looter: return 'looter:' + source_key + ':reported-N=' + str(e.get('casts'))
    if 'saereya' in (key or ''): return 'wowhead-saereya150'
    if 'mogens' in (key or ''): return 'wowhead-mogens45'
    if 'codisj1286' in (key or ''): return 'wowhead-codisj1286-approx400'
    if key and ('wicked-leather-ten-purchased' in key or 'wicked-headband-allakhazam-ten-purchased' in key): return 'allakhazam-wicked10-purchased'
    if key and ('tbc-22448-thottbot-z' in key or 'thottbot-zg-three-blues' in key): return 'thottbot-zg3blues'
    if key and ('30599-76098' in key or '76098-avenging-blades' in key): return 'comment76098-three-avenging'
    return key

def native_assert(number, e):
    table, entries, sha = NATIVE[number]
    prose = (e.get('quote') or '') + ' ' + (e.get('notes') or '')
    if table == 'EnchantedItemTypes':
        g = e['gearGroup']; level = re.search(r'\d+', g['itemLevelRange']).group()
        key = level + ':' + {'uncommon':'2','rare':'3','epic':'4'}[g['quality']] + ':' + {'armor':'4','weapon':'2'}[g['kind']]
    else:
        keys = re.findall(r'(?<!\d)(\d+:\d+:-?\d+)(?!\d)', prose)
        key = next((k for k in keys if k.split(':')[0] == str(e['inputItemID']) and k in entries), None)
    value = f"{e['outputItemID']}:{e['castsWithDrop']}:{e['totalQuantity']}:0"
    assert key in entries and value in entries[key].split(';'), (number, e['id'], key, value)
    return {'archive':str((HERE / (NATIVE_FILES[number] + '.lua.txt')).relative_to(REPO)).replace('\\','/'), 'archiveSHA256':sha,'table':table,'key':key,'tuple':value,'result':'EXACT_MATCH'}

def special_metrics(e, number):
    """Manually recovered numerics omitted by the old evidence field vocabulary."""
    k=e.get('studyKey') or '';o=e.get('outputItemID'); rank=e.get('outputRank');result=[]
    def add(metric, value=None, **extra): result.append(dict(metric=metric, value=value, **extra))
    if number==1 and o==22445: add('conditionalStackRange',lower=1,upper=3,basis='original article states positive dust branch 1–3; not observed extrema')
    if number==2:
        nominal=300 if 'pensoh' in k else 400
        if e.get('totalQuantity') is not None:add('meanUnitsPerNominalInputPrior',e['totalQuantity']/nominal,nominalInputCount=nominal,assumptions=['Use author approximate operation count only as a model denominator; no measured N assigned.'])
    if number==25 and rank:
        share={1:.3542,2:.4428,3:.2030}[rank]
        add('rankUnitShare',share,basis='share of material units, not positive-operation probability')
        add('meanUnitsPerCast',2.85*share,basis='published pooled mean2.85 multiplied by corresponding published unit share; no independent counts',arithmetic=f'2.85*{share}')
    if number==29 and 'rough20' in k:add('reportedMeanUnitsPerNominalInputRange',lower=5/20,upper=6/20,nominalInputCount=20,basis='approx20operations, approx5–6R3outcomes; nominal mean interval only; no exact totals, counts or probability',assumptions=['Interpret source5–6R3 as material-unit range and20asnominaloperations; retain original ambiguity.'])
    if number==31 or (number==33 and '100de' in k):add('reportedApproximateMeanUnitsPerCast',.06,basis='author about6 units per100DE; not exact observed total/hits')
    if number==33 and 'tailor-blue' in k:add('reportedPerCastChanceLowerBound',.25,basis='author roughly25% or more; no exact N/hits')
    if number==44:add('reportedMeanUnitsPerCastRange',lower=.02,upper=.03,basis='2–3 crystals per100 weaponDE, beta approximate source interval')
    if number==48 or number==49:pass  # explicit range fields already cover the original
    if number==53:
        if 'pegleg' in k:add('conditionalStackRange',lower=3,upper=5,basis='author typical positive dust amount; stacks not converted to item totals')
        elif '1066284' in k:add('conditionalStackRange',lower=2,upper=7,basis='author usual dust results; not proven hard/observed bounds')
    if number==61:
        add('meanUnitsPerCast',e['percentShown']/100,basis='source explicitly material units per100rare inputs, not P(hit)',arithmetic=f"{e['percentShown']}/100")
    if number==62 and 'sapphire-pendant' in k:add('reportedApproximateOccurrenceFraction',.8,basis='original8/10claim with about10nominalpurchases; no completedcastN or units inferred')
    if number==63 and 'westy543' in k:add('reportedMeanUnitsPerCastRange',lower=4/6,upper=5/6,basis='ambiguous aggregate four OR five units from sixDE; bounds retained, no midpoint fabricated')
    if number==69:add('knowledgePointsPerOneTimeDisenchant',3,basis='source3knowledge; one-time treasure only, never AH valued')
    if number==97 and 'pants-34' in k:add('reportedPerCastChance',33/34,basis='same original34pants report states oneGreaterPlanar outcome and allrestDust; source family assignment only, not dust units',arithmetic='(34-1)/34')
    if number==98:add('reportedAllPositiveAnecdote',1,basis='author fairfew allproducedLargePrismaticShard; unspecifiedN and positivequantity')
    if number==99:add('reportedApproximateOccurrenceFraction',1,basis='author approximately100%; nearby534/536 placement ambiguous, not exact K/N')
    if number==105 and o==22447:add('meanUnitsPerCast',16/17,basis='same original947919cohort companion record legacy-20261108-0015 explicitly separates17bracers/16essence from2othergreens that produced dust only',arithmetic='16/17',supportLocators=['research/v3/evidence/legacy/2026-11-08T2048-original-tbc-classic-disenchant-cohorts.jsonl:15'])
    if number==107 and 'fel-leather' in k:add('reportedAllPositiveAnecdote',1,basis='all7or8operations yielded family; exact N and quantities remain unknown')
    if number==121:add('reportedAllPositiveAnecdote',1,basis='nothing but family out of10; does not establish units per positive result')
    if number==122:
        if 'codisj1286' in k:add('reportedPerCastChanceRange',lower=.52,upper=.55,basis='original approx52–55%catchup eligible only; no exact counts')
        elif 'mikimm' in k:add('reportedPerCastChanceRange',lower=.45,upper=.50,basis='rough45–50%reported for222833cuffs, eligible state only')
    if number==232 and '220069' in k:
        add('conditionalMeanUnitsPerPositiveEvent',5.12,basis='author explicitly average per dust-positiveDE; not unconditional average')
        add('meanUnitsPerCastLowerBound',4,exclusive=True,basis='author says OVER4 perDE; no equality or total inferred')
    return result

SOURCES=[];PROPOSALS=[];NATIVE_CHECKS=[];coverage=[]
for number, source in enumerate(DOC['sources'],1):
    grouped=collections.defaultdict(list)
    for row in source['candidateRows']:grouped[row.get('studyKey')].append(row)
    cohorts=[]
    for study_key, rows in grouped.items():
        decisions=[]
        for row in rows:
            raw=row['originalEvidenceRow'];e=copy.deepcopy(raw);changes=[]
            for c in CORRECTIONS[(row['sourceFile'],raw.get('id'))]:
                if c.get('field'):
                    e[c['field']]=copy.deepcopy(c.get('value'));changes.append(c)
            text=((e.get('notes')or'')+' '+(e.get('studyKey')or'')).lower()
            native=number in NATIVE
            looter=not native and 'looter' in text
            n=e.get('casts');h=e.get('castsWithDrop');q=e.get('totalQuantity')
            ident={'itemID':e.get('outputItemID'),'name':e.get('outputName'),'rank':e.get('outputRank')}
            inp={x:e.get(x) for x in ('inputItemID','inputName','inputRank','gearGroup')}
            profile={x:e.get(x) for x in ('skill','specialization','stats','patch','dataDate')}
            profile['published']=(e.get('source')or{}).get('published')
            metric=[];reject=[];notes=[]
            if native:
                proof=native_assert(number,e);NATIVE_CHECKS.append(dict(locator=row['locator'],**proof))
                assert isinstance(h,(int,float)) and h>0 and isinstance(q,(int,float)) and q>=h
                metric.append(dict(metric='conditionalMeanUnitsPerPositiveEvent',value=q/h,basis='exact native positive-material observations and material-unit tuple',arithmetic=f'{q}/{h}'))
                notes += ['Trailing native:0 is not a zero-output bin.','Do not add local and grouped views or pooled detable as independent casts.']
                reject.append({'field':'unconditionalQuantityAndProbability','decision':'CURRENT_NUMERICAL_REJECTION','reason':f'Native {proof["table"]}[{proof["key"]}] records {h} material-positive observations and {q} units; no all-operation denominator or negative events. Q/H is conditional quantity, not E[Q/DE] or P(drop).','futureEvidenceTrigger':'A complete operation denominator or independently source-backed per-cast probability for the exact historical variant/group and material.'})
            else:
                if n is not None and n>0 and q is not None:
                    metric.append(dict(metric='meanUnitsPerCast' if not looter else 'sourceTableMeanUnitsPerReportedOperation',value=q/n,arithmetic=f'{q}/{n}',basis='firsthand reported units and operations' if not looter else 'source table occurrence*explicit fixed stack; source-reported denominator, not independently measured casts'))
                if n is not None and n>0 and h is not None:
                    metric.append(dict(metric='reportedPerCastChance' if not looter else 'sourceOccurrenceFraction',value=h/n,arithmetic=f'{h}/{n}',basis='source positive-operation count over stated operations' if not looter else 'website material-occurrence row/source operation counter; not independent controlled P(hit)'))
                if e.get('averageShown') is not None and e.get('averagePer') in ('cast','input','1000 inputs'):
                    v=e['averageShown']/(1000 if e['averagePer']=='1000 inputs' else 1)
                    metric.append(dict(metric='meanUnitsPerCast' if e['averagePer']=='cast' else 'meanUnitsPerInput',value=v,basis='published average; do not reconstruct rounded total units'))
                if e.get('minSeen') is not None and e.get('maxSeen') is not None:
                    metric.append(dict(metric='conditionalStackRange',lower=e['minSeen'],upper=e['maxSeen'],basis='website positive stack reference' if looter else 'source positive-output quantity interval; zero bins/hard bounds not inferred'))
                if e.get('percentShown') is not None:
                    meaning=e.get('percentMeaning') or ''
                    if number==61:pass
                    elif meaning in ('perCast','perInput') and not looter:
                        metric.append(dict(metric='reportedPerCastChance' if meaning=='perCast' else 'reportedPerInputChance',value=e['percentShown']/100,basis='published percentage only; no measured counts invented'))
                    elif looter:
                        metric.append(dict(metric='sourceDisplayedFraction',value=e['percentShown']/100,basis='source-displayed rounded percent; meaning not promoted to population probability'))
                    else:notes.append(f'Source percent{e["percentShown"]} has unclear denominator; no probability assigned.')
                if q is not None and h is not None and h>0 and not looter:
                    metric.append(dict(metric='conditionalMeanUnitsPerPositiveEvent',value=q/h,arithmetic=f'{q}/{h}',basis='output units/explicit positive-operation count'))
                if e.get('studyKey') in NOMINAL and q is not None:
                    nominal=NOMINAL[e['studyKey']]
                    metric.append(dict(metric='meanUnitsPerNominalInputPrior',value=q/nominal,nominalInputCount=nominal,basis='reported processed/crafted stock budget; completedDEcount is not observed',assumptions=['All stated nominal stock passed through this DE stage; no missing stock or unrelated inventory contribution. This is a model assumption, not a cast measurement.']))
                metric+=special_metrics(e,number)
                # Do not let old numeric casts fields override the report's stated unit.
                if number in (103,104,105):
                    metric=[x for x in metric if x['metric'] not in ('meanUnitsPerCast','meanUnitsPerNominalInputPrior')]
                    reject.append({'field':'directPerItemMean','decision':'CURRENT_NUMERICAL_REJECTION','reason':'Published inventory mixes ring types or17bracers plus2other greens, and may include lesser→greater essence conversion. No supported single-input direct quantity allocation. Raw totals remain pooled facts; neither17/19 nor147 is a verified matching direct-input denominator.','futureEvidenceTrigger':'Source split of actual processed input variants and pre-conversion material totals.'})
                    if number==105 and e.get('outputItemID')==22447:
                        metric += special_metrics(e,number)
                        reject=[]
                        notes.append('Current companion source separates16LesserPlanarEssence from17bracers; the2othergreens yielded only dust. Use17only for this essence mean, not for pooled28dust.')
                if number==6:
                    reject.append({'field':'normalMidnightMaterialModel','decision':'CURRENT_NUMERICAL_REJECTION','reason':'This is a dated cross-expansion anomalous single-result report, not evidence that the normal Midnight input class produces the reported old-expansion family. Input variant and fix interval are missing.','futureEvidenceTrigger':'Exact item/bonus/build identifying the anomalous route and its duration; then keep it separate from ordinaryMidnight distribution.'})
                if looter and not any(x['metric']=='sourceTableMeanUnitsPerReportedOperation' for x in metric):
                    reject.append({'field':'unconditionalMaterialQuantity','decision':'CURRENT_NUMERICAL_REJECTION','reason':f'Examined website table for input{e.get("inputItemID")}: sourceN={n}, rowoccurrences={h}, output={ident}. Occurrences are not material units; no compatible fixed-stack quantity or total units is given. A numeric mean cannot be recovered from these counters alone.','futureEvidenceTrigger':'Linked output identity plus source material units, explicit fixed stack, or positive-stack quantity model paired with the same source denominator.'})
                if ident['itemID'] is None:
                    reject.append({'field':'rankSpecificAuctionValue','decision':'CURRENT_NUMERICAL_REJECTION','reason':f'Source names {ident["name"]!r}, rank={ident["rank"]}; no verified linked itemID. Repeated same-name table row order does not identify rank; keep this outcome named/unpriced.','futureEvidenceTrigger':'Original linked material itemID or a primary-source identity join establishing the exact rank, without guessing from row order.'})
                if not metric:
                    reason=f'Examined source report: casts={n},units={q},positiveEvents={h},quoted={e.get("quote")!r}. '
                    if q is not None:reason+='Absolute source units are retained, but no compatible quantity denominator or per-positive-event count supports a per-operation mean.'
                    elif 'stack' in text:reason+='The amount is expressed in unspecified/approximate inventory stacks; source-era units per stack are unverified. No stack-to-unit multiplier is assumed.'
                    elif number==26:reason+='Fortybracers were processed, but the report gives only prices/qualitative shards, no material units, rank, positive count or numeric amount.'
                    else:reason+='Report establishes an outcome/anecdote or ambiguous scope, but no compatible numeric material quantity, probability, or positive-stack interval. No fabricated rate or unit amount is supplied.'
                    reject.append({'field':'currentNumericalOutput','decision':'CURRENT_NUMERICAL_REJECTION','reason':reason,'futureEvidenceTrigger':'An explicit material-unit quantity with matching operation/input denominator, output-positive quantity count, or a directly stated compatible mean/range/chance.'})
            if e.get('skill') or e.get('specialization') or e.get('stats'):
                notes.append('Retain the reported source profile. Do not treat a maxed/buffed endpoint as a minimum profile or add the same specialization effect twice; inverse adjustment requires a supported model.')
            else:notes.append('Source skill/profile is unknown. No knowledge points, equipped skill, or zero-profile state is fabricated.')
            if number==34:notes.append('R1.42+R2.97=1.39 conflicts with prose1.45 pooled. Keep rank means and unresolved discrepancy; do not silently rescale.')
            if number in (35,47,69,102,122,217) or e.get('outputItemID') in (227662,267653,267654,267655):
                economic='nontradable';notes.append('Knowledge/currency outcome: retain useful counts/chance, use no auction price or ordinary reagent substitution; weekly/catchup/one-time conditions remain explicit.')
            else:economic='unpriced-named' if ident['itemID'] is None else 'item-identity-does-not-prove-current-tradability'
            canonical=canonical_cohort(e,source['sourceKey'],looter)
            refs=[]
            for m in metric:
                pid='dea-'+digest([row['locator'],m])[:18];refs.append(pid)
                p=dict(proposalID=pid,sourceKey=source['sourceKey'],studyKey=study_key,canonicalCohortKey=canonical,recordID=raw.get('id'),locator=row['locator'],sourceURL=(e.get('source')or{}).get('url'),output=ident,input=inp,sourceProfile=profile,modelingConfidence=0,economicPolicy=economic,measuredCasts=None if(native or looter or e.get('studyKey') in NOMINAL) else n,sourceTableDenominator=n if looter else None,sourcePositiveEvents=h if native else None,sourceMaterialUnits=q,sourceRecordKind=e.get('sourceKind'),sourceFacts={'quote':e.get('quote'),'notes':e.get('notes')},constraints=['Never sum related copied/cohort snapshots as independent samples.','No current in-game eligibility, gear bonus/ilvl, price, or source-profile inverse is established by this proposal.','Do not convert conditional quantity, unit share, table occurrence, and per-cast probability into each other without explicit assumptions.'],**m)
                if native:p['nativeSourceVerification']=proof
                p['unit']=('units-per-positive-material-event' if m['metric']=='conditionalMeanUnitsPerPositiveEvent' else 'positive-output-units' if m['metric']=='conditionalStackRange' else 'material-unit-fraction' if m['metric']=='rankUnitShare' else 'knowledge-points' if m['metric']=='knowledgePointsPerOneTimeDisenchant' else 'source-occurrence-fraction' if m['metric'] in ('sourceOccurrenceFraction','sourceDisplayedFraction','reportedApproximateOccurrenceFraction') else 'units-per-nominal-input' if 'NominalInput' in m['metric'] else 'units-per-operation' if 'UnitsPerCast' in m['metric'] or 'UnitsPerReportedOperation' in m['metric'] else 'units-per-input' if m['metric']=='meanUnitsPerInput' else 'probability-fraction')
                if number==105 and e.get('outputItemID')==22447 and m['metric']=='meanUnitsPerCast':p['measuredCasts']=17;p['input']={'inputItemID':21849,'inputName':'Netherweave Bracers','inputRank':None,'gearGroup':None}
                p['applicability']={'method':'Disenchant','requiresExactInputOrDeclaredSourceGroup':True,'sourceVariantIsNotTargetVariant':native,'sourceContextOnly':True,'currentEligibilityGranted':False,'oneTime':number==69,'catchupOrWeeklyStateRelevant':economic=='nontradable' and number!=69,'inputFamilyIDs':[30570,30568] if number==46 else None,'requiresIwenRod':'iwen' in text,'requiresReportedActiveBuff':'buff active' in text or 'shattering essence' in text}
                if 'assumptions' not in p:p['assumptions']=[]
                PROPOSALS.append(p)
            disposition='CATALOGUED_NUMERIC_FACTS' if metric else 'CURRENT_NUMERICAL_REJECTION'
            decisions.append(dict(locator=row['locator'],recordID=raw.get('id'),rawSHA256=row.get('rawSHA256'),inputRowSHA256=digest(raw),sourceEvidenceExamined=True,disposition=disposition,currentCorrections=changes,sourceFacts={x:e.get(x) for x in ('inputItemID','inputName','gearGroup','outputItemID','outputName','outputRank','casts','totalQuantity','castsWithDrop','percentShown','percentMeaning','minSeen','maxSeen','averageShown','averagePer','quote','notes')},proposalRefs=refs,fieldRejections=reject,scopeNotes=notes,canonicalCohortKey=canonical))
            coverage.append(row['locator'])
        cohorts.append(dict(studyKey=study_key,decision='REVIEWED_ALL_ASSIGNED_FIELDS',coveredLocators=[x['locator'] for x in decisions],rowDecisions=decisions))
    SOURCES.append(dict(sourceKey=source['sourceKey'],sourceIndex=number,decision='REVIEWED_ALL_ASSIGNED_SCOPES',rawURLs=source.get('rawURLs'),priorReviewFacts=source.get('priorReviewFacts'),masterReviewFacts=source.get('masterReviewFacts'),qaReceipts=source.get('qaReceipts'),scope='All assigned candidate rows, with source-specific quantitative facts separated from rejected numerical interpretations; not page-wide validation of every possible future cohort.',coveredLocators=[r['locator'] for r in source['candidateRows']],cohorts=cohorts))

expected=[r['locator'] for s in DOC['sources'] for r in s['candidateRows']]
assert len(SOURCES)==240 and len(expected)==1880
assert len(set(expected))==len(expected)==len(coverage)
assert set(expected)==set(coverage)
assert len(NATIVE_CHECKS)==1139
summary={'sourceKeys':len(SOURCES),'candidateRows':len(coverage),'cohorts':sum(len(s['cohorts'])for s in SOURCES),'nativeRowsIndependentlyVerified':len(NATIVE_CHECKS),'numericFactProposals':len(PROPOSALS),'proposalMetrics':dict(sorted(collections.Counter(p['metric']for p in PROPOSALS).items())),'rowDecisions':dict(collections.Counter(d['disposition']for s in SOURCES for c in s['cohorts']for d in c['rowDecisions'])),'coverageMissing':[],'coverageExtra':[],'duplicateLocators':0,'candidateInputSHA256':hashlib.sha256(INPUT.read_bytes()).hexdigest(),'candidateLocatorSetSHA256':digest(sorted(expected)),'sourceKeySetSHA256':digest(sorted(s['sourceKey']for s in SOURCES))}
common={'schemaVersion':1,'lane':'disenchant_a','reviewDate':'2026-11-20','researchSnapshot':DOC['researchSnapshot'],'currentResearchBase':DOC['currentResearchBase'],'reviewer':'controlled_study_design','confidencePolicy':'Source observations are preserved verbatim; derived/context-limited proposals carry modelingConfidence0. No invented measurements,N,probability,prices,itemIDs,or currentgame eligibility.','summary':summary}
(OUT/'disenchant-a-review.json').write_text(json.dumps(dict(common,sources=SOURCES),ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(OUT/'disenchant-a-proposals.json').write_text(json.dumps(dict(common,proposals=PROPOSALS),ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(HERE/'coverage-proof.json').write_text(json.dumps(dict(summary,nativeChecks=NATIVE_CHECKS),ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps(summary,indent=2))
