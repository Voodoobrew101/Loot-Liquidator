"""Typed processing source facts must reach the real informational consumer."""
from copy import deepcopy
import json
from pathlib import Path
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
from processing_source_fact_translation import (CATALOGUE, normalize_processing_facts,
    normalize_processing_dispositions, verify_processing_fact_consumer, execute_processing_lua)


class ProcessingSourceFactTranslationTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.research = Path(self.temporary.name)
        folder = self.research / CATALOGUE
        folder.mkdir(parents=True)
        rows = []
        for rank, item in enumerate((2001, 2002, 2003), 1):
            rows.append({'locator': f'research/v3/evidence/test.jsonl:{rank}',
                'outputIdentity': {'itemIDs': [item], 'nativeName': 'Source Pigment', 'sourceRank': rank}})
        (folder / 'processing-review.json').write_text(json.dumps({'sources': [{'cohorts': [{'rowDecisions': rows}]}]}), encoding='utf-8')

    def tearDown(self):
        self.temporary.cleanup()

    def original(self, metric, **extra):
        fact = {'factID': 'processing:test', 'metric': metric, 'unit': 'input',
            'method': 'Mill', 'sourceKey': 'reddit:source-post', 'sourceStudyKey': 'source-cohort',
            'sourceRows': [], 'inputItemIDs': [1001], 'outputItemIDs': [2001],
            'confidence0to100': 0, 'sourceSupportConfidence': 5, 'observedSamplesAdded': 0,
            'sourceConditions': {'skill': 75, 'specialization': 'known source allocation'},
            'details': {'proposalID': 'p:test', 'outputIdentity': {'itemIDs': [2001], 'nativeName': 'Source Pigment'}}}
        fact.update(extra)
        return fact

    def adapt(self, fact):
        policy = {'models': [{'recordID': 'priced-unchanged', 'samples': 0}], 'facts': [fact]}
        before = deepcopy(policy)
        result, report = normalize_processing_facts(policy, self.research)
        self.assertEqual(policy, before)
        self.assertEqual(result['models'], before['models'])
        self.assertFalse(report['pricedModelsChanged'])
        return result, report

    def test_known_profile_quantity_stays_source_only(self):
        result, report = self.adapt(self.original('knownInvestedSourceMean', value=2.3))
        fact = result['facts'][0]
        self.assertEqual(fact['metric'], 'sourceProfileMeanUnitsPerInput')
        self.assertEqual(fact['sourceKey'], 'itemdb')
        self.assertEqual(fact['reviewedSourceKey'], 'reddit:source-post')
        self.assertEqual(fact['sourceProfile']['skill'], 75)
        self.assertEqual(fact['value'], 2.3)
        self.assertTrue(fact['sourceContextOnly'])
        self.assertFalse(fact['targetProfileAdjusted'])
        self.assertEqual(report['observedSamplesAdded'], 0)

    def test_input_family_is_source_context_not_each_rank_observation(self):
        result, _ = self.adapt(self.original('sourceOperationMean', value=2, unit='cast', inputItemIDs=[1001, 1002]))
        fact = result['facts'][0]
        self.assertEqual(fact['inputFamilyIDs'], [1001, 1002])
        self.assertNotIn('inputItemID', fact)
        self.assertIn('not a per-item measured allocation', fact['referenceConditions']['inputScope'])
        self.assertEqual(fact['metric'], 'sourceProfileMeanUnitsPerOperation')

    def test_missing_input_has_precise_terminal_lookup_rejection(self):
        original = self.original('sourceQuantityContext', value=1, inputItemIDs=[])
        result, report = self.adapt(original)
        self.assertEqual(result['facts'], [])
        decision = report['decisions'][0]
        self.assertEqual(decision['decision'], 'REJECTED_CURRENT_LOOKUP')
        self.assertIn('exact verified processing input', decision['reason'])
        self.assertEqual(decision['retainedSourceFact'], original)

    def test_era_alone_never_creates_item_match(self):
        result, report = self.adapt(self.original('sourceQuantityContext', value=1, inputItemIDs=[], expansionID=10))
        self.assertEqual(result['facts'], [])
        self.assertEqual(report['rejectedOriginalFacts'], 1)

    def test_superseded_wrong_unit_not_resurrected(self):
        result, report = self.adapt(self.original('supersededUnitTranscription', value=.135))
        self.assertFalse(result['facts'])
        self.assertIn('factor-of-ten', report['decisions'][0]['reason'])

    def test_quality_shares_bind_each_reported_rank(self):
        original = self.original('qualityUnitShare')
        original['details'].update(reportedRankUnits=[{'rank': rank, 'units': count,
            'sourceLocator': f'research/v3/evidence/test.jsonl:{rank}'} for rank, count in ((1, 0), (2, 1), (3, 3))],
            unitShares={'1': 0, '2': .25, '3': .75})
        result, report = self.adapt(original)
        facts = sorted(result['facts'], key=lambda f: f['outputRank'])
        self.assertEqual([(f['outputItemID'], f['outputRank'], f['value']) for f in facts],
                         [(2001, 1, 0), (2002, 2, .25), (2003, 3, .75)])
        self.assertEqual(sum(f['value'] for f in facts), 1)
        self.assertEqual(len(report['decisions'][0]['factIDs']), 3)
        self.assertEqual(facts[0]['factID'], original['factID'])

    def test_unknown_quality_identity_does_not_assign_first_item(self):
        original = self.original('qualityUnitShare')
        original['details'].update(reportedRankUnits=[{'rank': 2, 'units': 1, 'sourceLocator': 'missing:1'}], unitShares={'2': 1})
        result, report = self.adapt(original)
        self.assertFalse(result['facts'])
        self.assertIn('rank-specific output identity', report['decisions'][0]['reason'])

    def test_composition_is_share_not_hit_probability(self):
        original = self.original('sourceOutputComposition')
        original['details'].update(outcomes=[{'itemIDs': [2002], 'share': .2,
            'sourceLocator': 'research/v3/evidence/test.jsonl:2'}])
        result, _ = self.adapt(original)
        fact = result['facts'][0]
        self.assertEqual(fact['metric'], 'rankUnitShare')
        self.assertEqual(fact['outputItemID'], 2002)
        self.assertIn('not probability per operation', fact['referenceConditions']['shareBasis'])
        self.assertNotIn('dropChance', fact)

    def test_scalar_colour_share_preserves_unknown_unit_denominator(self):
        original = self.original('sourceOutputComposition')
        original['details']['reportedOutputUnitShare'] = .72
        result, _ = self.adapt(original)
        self.assertEqual(result['facts'][0]['value'], .72)
        self.assertIn('physical unit denominator unspecified', result['facts'][0]['referenceConditions']['shareBasis'])

    def test_histogram_summary_is_conditional_on_positive_bins(self):
        original = self.original('reportedHistogram')
        original['details']['sourceField'] = {'sourceBins': {'0': 10, '1': 2, '3': 2}}
        result, _ = self.adapt(original)
        fact = result['facts'][0]
        self.assertEqual(fact['metric'], 'conditionalMeanUnitsPerPositiveEvent')
        self.assertEqual(fact['value'], 2)
        self.assertEqual(fact['observedSamplesAdded'], 0)
        self.assertNotIn('samples', fact)

    def test_empty_positive_histogram_is_not_conditional_zero_mean(self):
        original = self.original('reportedHistogram')
        original['details']['sourceField'] = {'sourceBins': {'0': 10}}
        result, _ = self.adapt(original)
        self.assertEqual(result['facts'][0]['metric'], 'sourceReportedMaterialUnits')
        self.assertEqual(result['facts'][0]['value'], 0)

    def test_refund_identity_is_input_and_probability_is_not_invented(self):
        original = self.original('resourcefulnessReturnMagnitude')
        original['details'].update(observedReturnedInputFraction=.1, sourceReturnedInputUnits=10,
            sourceNominalInputs=100, conditionalSavedFractionModel=.4, sourceResourcefulnessPercent=25)
        result, _ = self.adapt(original)
        self.assertEqual({f['outputItemID'] for f in result['facts']}, {1001})
        self.assertEqual({f['metric'] for f in result['facts']}, {
            'sourceRefundFractionOfReportedInputBudget', 'sourceModeledReturnFractionPerResourcefulnessEvent'})
        self.assertTrue(all('dropChance' not in f for f in result['facts']))
        self.assertTrue(all(f['observedSamplesAdded'] == 0 for f in result['facts']))

    def test_accepted_refund_coefficient_preserves_selection(self):
        original = self.original('resourcefulnessReturnMagnitude')
        original['details'].update(returnFractionPerAcceptedResourcefulnessProc=.45, formula='250/(110*5)')
        result, _ = self.adapt(original)
        fact = result['facts'][0]
        self.assertEqual(fact['metric'], 'sourceReturnFractionPerAcceptedResourcefulnessEvent')
        self.assertIn('not all attempts', fact['referenceConditions']['coefficientBasis'])

    def test_nominal_event_budget_is_not_binomial_probability(self):
        original = self.original('sourceNominalEventIntensity')
        original['details'].update(eventsPerModeledInput=.108, formula='54/(25*20)')
        result, _ = self.adapt(original)
        fact = result['facts'][0]
        self.assertEqual(fact['metric'], 'sourceNominalEventsPerInput')
        self.assertIn('no observed all-attempt cast denominator', fact['referenceConditions']['nominalBudget'])

    def test_supported_reference_remains_byte_equivalent(self):
        original = self.original('sourceProfileMeanUnitsPerInput', sourceKey='itemdb', value=1.1)
        result, _ = self.adapt(original)
        self.assertEqual(result['facts'], [original])

    def test_dispositions_remove_unqueryable_ids_and_preserve_reason(self):
        _, report = self.adapt(self.original('sourceQuantityContext', value=1, inputItemIDs=[]))
        receipt = {'decisions': [{'proposalID': 'p:test', 'status': 'METADATA_REFERENCE',
            'factIDs': ['processing:test'], 'modelIDs': []}],
            'fieldDecisions': [{'factIDs': ['processing:test'], 'decision': 'SOURCE_FACT'}]}
        result = normalize_processing_dispositions(receipt, report)
        self.assertEqual(result['decisions'][0]['factIDs'], [])
        self.assertEqual(result['decisions'][0]['decision'], 'REJECTED_CURRENT_NUMERICAL')
        self.assertEqual(result['fieldDecisions'][0]['decision'], 'REJECTED_CURRENT_NUMERICAL')
        self.assertEqual(receipt['decisions'][0]['factIDs'], ['processing:test'])

    def test_duplicates_fail_instead_of_hiding_missing_coverage(self):
        original = self.original('knownInvestedSourceMean', value=1)
        with self.assertRaisesRegex(ValueError, 'Duplicate input fact ID'):
            normalize_processing_facts({'facts': [original, original]}, self.research)

    def test_actual_query_and_renderer_accept_literal_dimensional_facts(self):
        fixtures = []
        for metric in ('knownInvestedSourceMean', 'resourcefulnessReturnMagnitude', 'sourceNominalEventIntensity'):
            original = self.original(metric, factID='test:' + metric, value=1.3)
            original['details'].update(observedReturnedInputFraction=.1, sourceReturnedInputUnits=10,
                sourceNominalInputs=100, conditionalSavedFractionModel=.4, sourceResourcefulnessPercent=25,
                eventsPerModeledInput=.108, formula='54/(25*20)')
            fixtures.extend(self.adapt(original)[0]['facts'])
        result = verify_processing_fact_consumer({'facts': fixtures}, ROOT)
        self.assertEqual(result['failures'], [])
        self.assertEqual(result['queriedFacts'], len(fixtures))
        self.assertEqual(result['renderedFacts'], len(fixtures))
        self.assertEqual(result['policyNegativeChecks'], 2 * len(fixtures))
        # Native subprocess results and embedded results share this serializer,
        # including failure messages containing Windows paths/control bytes.
        escaped = execute_processing_lua(r'''return {text='quote" slash'..string.char(92)..' CR'..string.char(13)..' LF'..string.char(10)..' tab'..string.char(9)}''', ROOT)
        self.assertEqual(escaped, {'text': 'quote" slash\\ CR\r LF\n tab\t'})

    def test_actual_item_tooltip_source_reference_does_not_create_action_or_ev(self):
        import research_v3_to_baselines as bridge
        original = self.original('knownInvestedSourceMean', value=1.3)
        facts = self.adapt(original)[0]['facts']
        script = '''
            LL={db={tooltipDetail=3,showResearchDetails=true}}
            CreateFrame=function()return{RegisterEvent=function()end,SetScript=function()end}end
            GetBuildInfo=function()return '12.1.5','123456','',120105 end
            GetItemInfo=function()return 'Source Pigment' end
        '''
        for name in ('Database.lua', 'Observations.lua', 'ReviewedSourceFacts.lua', 'Badges.lua'):
            script += 'assert(loadfile(' + json.dumps((ROOT / 'LootLiquidator' / name).as_posix()) + '))("LootLiquidator",LL)\n'
        script += 'LL.ItemDB=' + bridge.lua({'reviewedSourceFacts': {'schemaVersion': 1, 'facts': facts}}) + '\n'
        script += '''
            LL.MarkupColor=function()return ''end
            LL.Money=function(_,value)return tostring(value)..' copper'end
            LL.ProfessionProgression=function()return {}end
            decision={facts={id=1001,expansionID=0,classID=7,quality=1},conversionOptions={},action=nil}
            function render()
                local tooltip={lines={}}
                function tooltip:AddLine(line)self.lines[#self.lines+1]=line end
                function tooltip:AddDoubleLine(left,right)self.lines[#self.lines+1]=left..' | '..right end
                LL:AppendRecommendationTooltip(tooltip,decision)
                return table.concat(tooltip.lines,'\\n')
            end
            local text=render()
            assert(text:find('source-profile mean 1.3 units per input',1,true),'source mean missing')
            assert(text:find('skill 75',1,true),'source skill missing')
            assert(text:find('Confidence 0%',1,true),'confidence missing')
            assert(not text:find('copper',1,true),'source fact acquired economic value')
            assert(#decision.conversionOptions==0 and decision.action==nil,'source fact created an action')
            LL.db.source_itemdb_enabled=false
            assert(not render():find('Processing source facts',1,true),'disabled source leaked')
            LL.db.source_itemdb_enabled=true
            LL.db.source_itemdb_weight=0
            assert(not render():find('Processing source facts',1,true),'zero-weight source leaked')
            LL.db.source_itemdb_weight=nil
            LL.db.professionTooltipProfiles={Inscription='@hide'}
            assert(not render():find('Processing source facts',1,true),'hidden profile leaked')
            return {passed=true}
        '''
        self.assertEqual(execute_processing_lua(script, ROOT), {'passed': True})


if __name__ == '__main__':
    unittest.main()
