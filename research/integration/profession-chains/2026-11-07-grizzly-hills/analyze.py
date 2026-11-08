"""Reproduce this research-only cost screen from its frozen TSM price subset."""
import csv
import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parent
snapshot = json.loads((ROOT / 'price-snapshot.json').read_text())
items = snapshot['items']
FEE = .05

def price(item, field='dbMinBuyout'):
    value = items['i:' + str(item)]['values'].get(field)
    assert value is not None and value > 0, (item, field)
    return value / 10000

rows = []
def case(route, cost, gross, basis, limits):
    rows.append(dict(route=route, inputCostGold=cost, grossOutputGold=gross,
                     terminalSaleAfter5PercentFeeGold=gross * (1-FEE),
                     marginAfterFeeBeforeDepositsGold=gross*(1-FEE)-cost,
                     basis=basis, limits=limits))

core_yield = 388/200
r2 = 37/405
shard_value = (1-r2)*price(243602) + r2*price(243603)
case('5 R1 Powder -> R1 Evercores', 5*price(245807), core_yield*price(243581),
     'Measured Engineering40/bonus0/no-spec sample:388cores/200casts.',
     'Only R1 Powder and this profile; no universal Recycling yield.')
case('Purchased R1 Evercore -> Shade -> sell shards', price(243581), shard_value,
     'Nominal one core per Shade; measured82-skill i165 DE368R1/37R2 over405casts.',
     'Conditional combined estimate; no craft refunds or input variant changes.')
case('Purchased R1 Evercore -> craft/sell i165 Shade', price(243581), price('244752::i165'),
     'Nominal one core per Shade; exact Grizzly Hills i165 listing9g.',
     'Listing scenario only; exact output variant, deposits and weak/unknown liquidity matter.')
case('R1 Radiant Shard ->3 R1 Dust', price(243602), 3*price(243599),
     'Spell1280394 nominal3 and input-quality cap.',
     'Zero refunds; native pilot required; thin margin and no depth guarantee.')
case('R2 Radiant Shatter: all outputs R1', price(243603), 3*price(243599),
     'Lower output-quality scenario, not measured.', 'Actual R2 dust mix unknown; zero refunds.')
case('R2 Radiant Shatter: all outputs R2', price(243603), 3*price(243600),
     'Upper output-quality scenario, not measured.', 'Actual R2 dust mix unknown; zero refunds.')
case('R1 Dawn Crystal ->3 R1 Shards', price(243605), 3*price(243602),
     'Spell1280401 nominal3.', 'Zero refunds; not a reason to buy expensive crystals for research.')
case('Craft bolt using R1 linen', price(236963)+4*price(251665), price(239700),
     'Spell1228939:1linen+4thread ->nominal1bolt.',
     'AH input quotes; output rank needs native preview; vendor discounts/procs unmodeled.')
case('Craft bolt using R2 linen, R2 output scenario', price(236965)+4*price(251665), price(239701),
     'Same recipe; R2 linen costs2.51g; R2 output is a scenario.',
     'AH input quotes; R2 input does not certify R2 output; vendor discounts/procs unmodeled.')
case('Craft R1 Imbued Bolt', 2*price(239700)+4*price(251665), price(239702),
     'Spell1228940:2bolts+4thread ->nominal1imbuedbolt.',
     'AH input quotes; vendor discounts/procs unmodeled.')
case('Craft R1 Copper Ingot', 5*price(237359)+2*price(243060), price(238197),
     'Spell1230761:5ore+2flux ->nominal1ingot.',
     'AH input quotes; vendor discounts/procs unmodeled.')
case('Refine10 R1 Glass ->1 R2 Glass', 10*price(242787), price(242786),
     'Spell1307462 nominal ratio.', 'Native pilot required; no procs assumed.')
case('Refine18 R1 Stone ->1 R2 Stone', 18*price(242788), price(242789),
     'Spell1307466 nominal ratio.', 'Native pilot required; no procs assumed.')
for output in (243984,243985):
    case('5R1Dust+AHVellum -> '+('R1' if output==243984 else 'R2')+' Nature Wrath scroll',
         5*price(243599)+price(38682), price(output),
         'Spell1236073 plus one vellum for a saleable enchant.',
         'R2 output from R1 dust is conditional on native skill/quality preview; no free Concentration. Vendor vellum may be cheaper.')
case('6R1Bloom+5AHVials ->5R1HealthPotions', 6*price(236761)+5*price(240991), 5*price(241305),
     'Spell1230866 nominal5potions.',
     'Vendor vial quotes, output rank and procs can change result; none assumed.')
for name, source, target in [('Light->Wild',236949,236951), ('Wild->Void',236951,236952),
                             ('Void->Primal',236952,236950), ('Primal->Light',236950,236949)]:
    case('10->8 Motes '+name+' BEFORE Derivate cost', 10*price(source), 8*price(target),
         'Nominal transmute leg.', '18h recharge;2BoP Derivate omitted from numeric subtotal, not free. Actual cost is higher.')

ranked = []
for item in snapshot['nativeRecyclingEligibility']['inputIDs']:
    entry = items['i:'+str(item)]; v = entry['values']
    ranked.append(dict(itemID=item, name=entry['name'], minBuyoutGold=v['dbMinBuyout']/10000,
                       batch5InputCostGold=5*v['dbMinBuyout']/10000,
                       dbMarketGold=v['dbMarket']/10000 if v.get('dbMarket') else None,
                       dbRegionSaleAvgGold=v['dbRegionSaleAvg']/10000 if v.get('dbRegionSaleAvg') else None,
                       regionSaleRate=v.get('dbRegionSaleRate'), yieldMeasuredForThisInput=item==245807,
                       eligibilityDoesNotEstablishOutputFamilyOrYield=True))
ranked.sort(key=lambda row:(row['minBuyoutGold'],row['itemID']))
summary = dict(schemaVersion='loot-liquidator.profession-chain-cost-screen/1',
               artifactStatus='RESEARCH_ONLY_NOT_SHIPPED', automaticMechanicsPromotion=False,
               sellerFeeScenario=FEE, cases=rows,
               assumptions=['Buy inputs at snapshot minima; charge seller fee once at terminal sale.',
                            'Deposits, time, price depth and sale delays are not modeled.',
                            'Procs, BoP reagents and Concentration are not assumed free.',
                            'Measured yields remain scoped to recipe/input/rank/skill/spec/build.',
                            'Compare ranks by actual price and native output-quality eligibility, not numerical rank.'],
               breakEvenChecks=dict(
                   milling10R1BloomInputCostGold=10*price(236761),
                   R1PigmentNeededAtCurrentMin=10*price(236761)/(.95*price(245807)),
                   R1PigmentNeededAtRegionSaleAvg=10*price(236761)/(.95*price(245807,'dbRegionSaleAvg')),
                   powderCurrentToRegionSaleAvgRatio=price(245807)/price(245807,'dbRegionSaleAvg'),
                   prospect5R1CopperOreInputCostGold=5*price(237359),
                   crush3CheapestR1GemsPlusStoneInputCostGold=3*min(price(i) for i in (242553,242554,242606,242607))+price(242788),
                   CourtlyWristsNominalAHMaterialCostGold=2*price(239700)+2*price(251665),
                   BouquetR1TradableInputsBeforeDerivateCostGold=20*price(243599)+4*price(243602),
                   SchoolOfGemsFishBeforeDerivateCostGold=4*price(238383)+12*price(238369)+20*price(238365),
                   BoxOfRocksR1MaterialsBeforeDerivateCostGold=8*price(238525)+18*price(238518)+18*price(238520),
                   nominalFullMoteCycleRetention=.8**4))
assert len(ranked)==88 and ranked[0]['itemID']==239700
assert math.isclose(rows[0]['inputCostGold'],14.4) and math.isclose(rows[0]['grossOutputGold'],4.85)
assert math.isclose(rows[3]['marginAfterFeeBeforeDepositsGold'],.28)
assert math.isclose(summary['breakEvenChecks']['CourtlyWristsNominalAHMaterialCostGold'],3.3)
assert all(math.isfinite(r['marginAfterFeeBeforeDepositsGold']) for r in rows)
(ROOT/'cost-analysis.json').write_text(json.dumps(summary,indent=2,allow_nan=False)+'\n',encoding='utf-8')
for name,data in [('cost-comparisons.csv',rows),('recycling-inputs-ranked.csv',ranked)]:
    with (ROOT/name).open('w',newline='',encoding='utf-8') as handle:
        writer=csv.DictWriter(handle,fieldnames=list(data[0]));writer.writeheader();writer.writerows(data)
print(json.dumps(dict(snapshotItems=len(items),eligibleInputs=len(ranked),costCases=len(rows),
                      automaticPromotion=False,checks='passed')))
