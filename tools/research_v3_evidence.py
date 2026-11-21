"""Select v3 evidence field by field without changing the vendored calculator.

The snapshot calculator supplies identity, cohort lineage, unlocks and epochs.
Its fitted estimates and simulation counts are not source observations.
"""

from collections import Counter, defaultdict
from dataclasses import dataclass
from math import inf, isclose


FIELDS = ('dropChance', 'expectedQuantity', 'minQuantity', 'maxQuantity')
REPORTED_CAST_BASES = (None, 'reported')
PRISMATIC_STUDY_ALIASES = {'wowhead-superbondez-prismatic-ore-400', 'wowhead-prismatic-ore-superbondez-400-80'}
RUNECLOTH_MIRROR_SOURCES = {
    'wowhead-illusiondust-1115352-runecloth-headband-5': 'wowhead:item=16204@mop-classic',
    'wowhead-16204-1115352-five-headband-source-explicit-outcomes': 'wowhead:item=16204@cata',
}
RUNECLOTH_MIRROR_OUTCOMES = {
    16204: (4, 'Rune Cloth Headband gave me Illusion Dust 4 out of 5 time'),
    16203: (1, 'the other was Greater Eternal Essance'),
}


@dataclass(frozen=True)
class Observation:
    value: float
    casts: int = 0
    amount: int | None = None
    weight: float = 1.0
    source: str = 'reported'
    reported_casts: int = 0


@dataclass(frozen=True)
class Histogram:
    casts: int
    hits: int
    total: int
    minimum: int | None
    maximum: int | None
    includes_zero: bool

    def complete(self, row, casts):
        return self.casts == casts if casts is not None else row.get('casts') is None and self.includes_zero


def number(value):
    return value if type(value) in (int, float) and 0 <= value < inf else None


def count(value):
    value = number(value)
    return int(value) if value is not None and value <= (2**53 - 1) and value == int(value) else None


def batch_for(row, method, item):
    stated = row.get('inputsPerCast')
    if stated is None:
        # Magma Thresher has published per-input yields but no verified default
        # operation size. An explicit or linked batch can still establish it.
        if method == 'Prospect' and item == '199344':
            return None
        return {'Disenchant': 1, 'Prospect': 5}.get(method)
    batch = count(stated)
    if method == 'Disenchant' and batch != 1:
        return None
    return batch or None


def source_author(row):
    author = (row.get('source') or {}).get('author')
    return author.strip().casefold() if isinstance(author, str) else None


def identified_cohort(module, row, vectors):
    # The two November 7 rank corrections transcribed the same Superbondez
    # report (400 ore, 80 prospects). Their output vectors differ because
    # one corrected only Amber, so the whole-study fingerprint cannot link them.
    if (not row.get('cohortKey') and row.get('studyKey') in PRISMATIC_STUDY_ALIASES
            and row.get('method') == 'Prospect' and row.get('inputItemID') == 194545
            and row.get('casts') == 80 and source_author(row) == 'superbondez'
            and module.source_key(row) == 'wowhead:item=194545'):
        return ('cohort', 'wowhead-superbondez-prismatic-ore-400')
    # Both reviewed Classic pages quote the same author and explicitly describe
    # the same five tests. Other records on these game versions remain separate.
    mirror = RUNECLOTH_MIRROR_SOURCES.get(row.get('studyKey'))
    if (not row.get('cohortKey') and mirror and module.source_key(row) == mirror
            and row.get('method') == 'Disenchant' and row.get('inputItemID') == 13866
            and row.get('casts') == 5 and source_author(row) == '1115352'
            and (row.get('castsWithDrop'), row.get('quote')) == RUNECLOTH_MIRROR_OUTCOMES.get(row.get('outputItemID'))):
        return ('cohort', 'wowhead-16204-comment-1115352-runecloth-headband-5')
    return module.study_identity(row, vectors)


def source_batch_key(module, row, identity):
    casts = count(row.get('casts'))
    url = row.get('originalSource') or (row.get('source') or {}).get('url')
    if (casts and isinstance(url, str) and url and isinstance(row.get('inputItemID'), int)
            and isinstance(row.get('outputItemID'), int) and row.get('castsBasis') in REPORTED_CAST_BASES):
        return (*identity, row.get('inputRank'), row.get('outputRank'), module.normalize_url(url), casts)
    return None


def source_batch_context(row):
    return (source_author(row), row.get('dataDate') or row.get('observedOn'), row.get('patch'),
            row.get('recipeID'), row.get('operationVariant'))


def distribution(row):
    """Read actual stack counts; completeness is checked separately."""
    raw = row.get('histogram')
    if not isinstance(raw, dict) or not raw:
        return None
    bins = {}
    for label, amount in raw.items():
        if type(label) is not str or not label.isascii() or not label.isdecimal():
            return None
        try:
            units = count(int(label))
        except ValueError:
            return None
        n = count(amount)
        if units is None or n is None or units in bins:
            return None
        bins[units] = n
    casts = sum(bins.values())
    if not casts:
        return None
    hits = casts - bins.get(0, 0)
    total = sum(units * n for units, n in bins.items())
    positive = [units for units, n in bins.items() if units > 0 and n > 0]
    return Histogram(casts, hits, total, min(positive, default=None), max(positive, default=None), 0 in bins)


def row_support(module, row, batch, weight, notes, shared_casts=None):
    reported = row.get('castsBasis') in REPORTED_CAST_BASES
    casts = count(row.get('casts')) if reported else None
    hits = count(row.get('castsWithDrop'))
    total = count(row.get('totalQuantity'))
    lo, hi = (count(row.get(key)) or None for key in ('minSeen', 'maxSeen'))
    histogram = distribution(row) if reported else None
    complete = histogram and histogram.complete(row, casts)
    conflicts = set()
    if row.get('histogram') is not None and not complete:
        notes['incomplete or invalid histogram'] += 1
    if complete:
        casts = histogram.casts
        observed = (histogram.hits, histogram.total, histogram.minimum, histogram.maximum)
        for name, field, value in zip(FIELDS, (hits, total, lo, hi), observed):
            if field is not None and field != value:
                conflicts.add(name)
        hits, total, lo, hi = observed
    elif reported and row.get('casts') is None:
        casts = shared_casts

    if casts and row.get('castsWithDrop') is not None and (hits is None or hits > casts):
        conflicts.add('dropChance')
    if casts and row.get('totalQuantity') is not None and total is None:
        conflicts.add('expectedQuantity')
    if (lo is not None and hi is not None and lo > hi) or (hits == 0 and (lo is not None or hi is not None)):
        conflicts.update(('minQuantity', 'maxQuantity'))
    if (casts and hits is not None and hits <= casts and total is not None
            and (total < hits or (hits == 0 and total > 0))):
        conflicts.update(('dropChance', 'expectedQuantity'))

    supports = defaultdict(list)
    if casts and hits is not None:
        supports['dropChance'].append(Observation(hits / casts, casts, hits, weight=weight))
    elif module.same_unit(row, batch):
        pct = number(module.chance_from_percent(row))
        if pct is not None and pct <= 1:
            supports['dropChance'].append(Observation(pct, source='reportedRate'))

    if casts and total is not None:
        supports['expectedQuantity'].append(Observation(total / casts, casts, total, weight=weight))
    else:
        average = number(module.unit_average(row, batch))
        if average is not None:
            # Rounded per-cast means can have a real source sample size but
            # cannot be multiplied into an observed integer output total.
            reported_casts = casts if casts and row.get('averagePer') == 'cast' else 0
            supports['expectedQuantity'].append(Observation(average, source='reportedMean', reported_casts=reported_casts))
        elif total is not None:
            inputs = number(row.get('inputsProcessed'))
            equivalent = number(row.get('casts')) if row.get('castsBasis') in module.EQUIVALENT_BASES else None
            unit = module.row_unit(row)
            if inputs:
                supports['expectedQuantity'].append(Observation(total * batch / inputs, source='nominalInput'))
            elif equivalent and unit:
                supports['expectedQuantity'].append(Observation(total * batch / (equivalent * unit), source='nominalInput'))
            else:
                notes['quantity total has no usable denominator'] += 1

    if module.same_unit(row, batch):
        bound_n = hits if casts and hits is not None and hits <= casts and 'dropChance' not in conflicts else 0
        for name, value, hist_bound in (('minQuantity', lo, histogram.minimum if histogram else None),
                                        ('maxQuantity', hi, histogram.maximum if histogram else None)):
            if value is not None:
                supports[name].append(Observation(value, bound_n, weight=weight))
            elif hist_bound is not None:
                supports[name].append(Observation(hist_bound, histogram.hits, weight=weight))
    for field in conflicts:
        supports.pop(field, None)
        notes[f'inconsistent source {field}'] += 1
    return supports


def provisional_candidates(values):
    # A figure stated by a source is more specific than a nominal-input proxy.
    reported = [v for v in values if v.source != 'nominalInput']
    return reported or values


def choose_observation(values):
    """Resolve within one known cohort, where aliases cannot add observations."""
    measured = [v for v in values if v.casts]
    if measured:
        first = measured[0]
        if any((v.casts, v.amount, v.value) != (first.casts, first.amount, first.value) for v in measured):
            return None
        return Observation(first.value, first.casts, first.amount, weight=min(v.weight for v in measured))
    candidates = provisional_candidates(values)
    first = candidates[0]
    if not all(isclose(v.value, first.value, rel_tol=1e-9) for v in candidates):
        return None
    sizes = {v.reported_casts for v in candidates if v.reported_casts}
    return Observation(first.value, source=first.source, reported_casts=sizes.pop() if len(sizes) == 1 else 0)


def combine(field, observations, notes):
    direct = [o for o in observations if o.casts]
    if field in ('minQuantity', 'maxQuantity'):
        extreme = min if field == 'minQuantity' else max
        value = extreme(o.value for o in (direct or observations))
        supporting = [o for o in direct if o.value == value]
        casts = sum(o.casts * o.weight for o in supporting)
        return {'value': value, 'casts': casts, 'sampleSizeKnown': bool(casts),
                'status': 'measured' if supporting and all(o.weight == 1 for o in supporting) else 'provisional'}

    amount_key = 'hits' if field == 'dropChance' else 'total'
    if direct:
        casts = sum(o.casts * o.weight for o in direct)
        amount = sum(o.amount * o.weight for o in direct)
        return {'value': amount / casts, 'casts': casts, amount_key: amount, 'sampleSizeKnown': True,
                'status': 'measured' if all(o.weight == 1 for o in direct) else 'provisional'}
    candidates = provisional_candidates(observations)
    chosen = candidates[0]
    if not all(isclose(v.value, chosen.value, rel_tol=1e-9) for v in candidates):
        notes[f'conflicting uncounted {field}'] += 1
        return None
    result = {'value': chosen.value, 'casts': 0, 'sampleSizeKnown': False, 'priorWeight': 0,
              'status': 'provisional', 'basis': chosen.source}
    reported_casts = sum(v.reported_casts for v in candidates)
    if reported_casts:
        result['reportedCasts'] = reported_casts
    return result


def build_field_support(module, rows, names):
    """Return operation-size estimates, reason counts and unplaced drop records.

    Each estimate carries only the supported fields. A field with no known
    denominator can contribute an explicitly provisional value but no casts.
    """
    vectors, _, pooled = module.study_vectors(rows)
    copies = module.misplaced_copies(rows, names, vectors, pooled)
    conditions = module.load_conditions(rows)
    rate_changes = module.load_rate_changes()
    families = defaultdict(set)
    for row in rows:
        if isinstance(row.get('inputName'), str) and row.get('inputItemID'):
            families[row['inputName'].strip().lower()].add(str(row['inputItemID']))

    grouped = defaultdict(list)
    known_batches = defaultdict(set)
    matched_batches = defaultdict(list)
    pending = []
    notes = Counter()
    unplaced = 0
    for row in rows:
        if not module.is_study_row(row):
            continue
        identity = module.key_of(row, names)
        if identity is None:
            unplaced += 1
            continue
        if id(row) in copies:
            notes['duplicate pooled or less-specific cohort'] += 1
            continue
        method, item, output = identity
        batch = batch_for(row, method, item)
        stated = row.get('inputsPerCast') is not None
        if stated and batch is None:
            notes['batch size (inputs per cast) not stated or invalid'] += 1
            continue
        cohort = identified_cohort(module, row, vectors)
        context = (method, item, cohort)
        source = source_batch_key(module, row, identity)
        if stated and row.get('castsBasis') in REPORTED_CAST_BASES:
            known_batches[context].add(batch)
            if source and count(row.get('inputsProcessed')) == batch * source[-1]:
                matched_batches[source].append((batch, source_batch_context(row)))
        pending.append((row, identity, cohort, context, batch, stated, source))

    for row, (method, item, output), cohort, context, batch, stated, source in pending:
        if not stated:
            batches = known_batches[context]
            if not batches and source:
                scope = source_batch_context(row)
                batches = {b for b, original in matched_batches[source]
                           if all(not incoming or not donor or incoming == donor for incoming, donor in zip(scope, original))}
            if len(batches) == 1:
                batch = next(iter(batches))
                row = dict(row, inputsPerCast=batch)
                notes['+operation size recovered from matching source'] += 1
            elif len(batches) > 1:
                notes['matching source reports conflicting operation sizes'] += 1
                continue
        if batch is None:
            notes['batch size (inputs per cast) not stated or invalid'] += 1
            continue
        grouped[(method, item, output, batch)].append((row, cohort, context))

    estimates = []
    for (method, item, output, batch), cohort_rows in sorted(grouped.items(), key=lambda p: repr(p[0])):
        requires = module.condition_for(conditions, method, item, output, families)
        cohorts = defaultdict(lambda: defaultdict(list))
        denominators = defaultdict(set)
        eligible = []
        unnamed_ranks = Counter(module.study_ref(row) for row, _, _ in cohort_rows
                                 if row.get('outputItemID') is None and row.get('outputRank') is None)
        for row, cohort, context in cohort_rows:
            if len(known_batches[context]) > 1 or known_batches[context] and batch not in known_batches[context]:
                notes['same cohort reports conflicting operation sizes'] += 1
                continue
            if requires is not None and module.unlock_state(row) is not True:
                notes['conditional cohort lacks matching unlock evidence'] += 1
                continue
            if (row.get('outputItemID') is None and row.get('outputRank') is None
                    and unnamed_ranks[module.study_ref(row)] > 1):
                notes['same cohort has indistinguishable output rows'] += 1
                continue
            weight, _ = module.epoch_weight(row, method, item, rate_changes)
            if not weight:
                continue
            eligible.append((row, cohort, weight))
            if len(cohort) == 2 and cohort[0] == 'cohort' and row.get('castsBasis') in REPORTED_CAST_BASES:
                stated = count(row.get('casts'))
                histogram = distribution(row) if stated is None else None
                casts = stated or (histogram.casts if histogram and histogram.complete(row, stated) else None)
                if casts:
                    denominators[cohort].add(casts)

        for row, cohort, weight in eligible:
            sizes = denominators[cohort]
            shared_casts = next(iter(sizes)) if len(sizes) == 1 else None
            for field, options in row_support(module, row, batch, weight, notes, shared_casts).items():
                if field in row.get('_reviewedSupersededFields', []):
                    notes['reviewed cohort field replaced by explicit normalized model'] += 1
                    continue
                cohorts[cohort][field].extend(options)

        selected = defaultdict(list)
        counted_cohorts = defaultdict(set)
        for cohort, fields in cohorts.items():
            for field, options in fields.items():
                observation = choose_observation(options)
                if observation is not None:
                    selected[field].append(observation)
                    if observation.casts and field in ('dropChance', 'expectedQuantity'):
                        counted_cohorts[field].add(cohort)
                else:
                    notes[f'conflicting {field} in one cohort'] += 1
        supports = {field: support for field, observations in selected.items()
                    if (support := combine(field, observations, notes)) is not None}
        for field, cohort_ids in counted_cohorts.items():
            supports[field]['_countedCohorts'] = cohort_ids
        if supports:
            estimates.append({'method': method, 'input': item, 'outputItemID': output, 'inputsPerCast': batch,
                              'conditional': requires is not None, 'requires': requires,
                              'studies': len(cohorts), 'fieldSupport': supports})
    return estimates, notes, unplaced
