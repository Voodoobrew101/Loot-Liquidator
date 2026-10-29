"use strict";

// A research preview layer. Nothing in this module promotes evidence, normalizes
// a character, reads tooltip data, or authorizes economic/runtime decisions.
const FIELDS = ["dropChance", "yieldMin", "yieldMax", "expectedQuantity"];
const POLICY_VERSION = "working-estimate-policy-v1";
const EPS = 1e-9;

function finite(v) { return typeof v === "number" && Number.isFinite(v); }
function positiveInteger(v) { return Number.isSafeInteger(v) && v >= 1; }
function score(v) { return Number.isInteger(v) && v >= 0 && v <= 100 ? v : 0; }
function evidenceValue(r, f) {
  // A retained source number can be contradictory evidence. Numeric validity
  // alone must never promote it into the working layer or a donor prior.
  if (r[f]?.status === "contradictory") return null;
  const v = r[f]?.value;
  if (!finite(v)) return null;
  if (f === "dropChance") return v >= 0 && v <= 1 ? v : null;
  if (f === "expectedQuantity") return v >= 0 ? v : null;
  return positiveInteger(v) ? v : null;
}
function operationKey(r) {
  const c = r.conditions || {};
  return JSON.stringify([r.method, r.expansionID, r.inputItemID,
    r.inputQualityRank ?? null, r.recipeSpellID ?? null,
    r.inputCountPerOperation, c.operationVariant ?? null,
    c.patchWindow ?? null, c.characterContext ?? null,
    c.effectiveSkill ?? null, c.specialization ?? null, c.operationStats ?? null,
    c.sourceContext ?? null, c.quantityBasis ?? null,
    c.eligibilityStatus ?? null, c.baselineStatus ?? null]);
}
function canonicalFamily(r, options) {
  return r.outputFamilyID ?? r.conditions?.outputFamilyID ??
    options.outputFamilyByItemID?.[r.outputItemID] ?? null;
}
function ambiguousRank(r) {
  return FIELDS.some(f => (r[f]?.blockers || []).some(b =>
    /RANK_SPECIFIC|RANK_OR_GROSS_INPUT|RANK_ALLOCATION/.test(b))) ||
    /RANK.*(?:UNRESOLVED|QUARANTINED)/.test(r.conditions?.sourceContext || "");
}
function donorKey(r) {
  return JSON.stringify([r.method, r.expansionID, r.inputCountPerOperation,
    r.outputItemID, r.inputQualityRank ?? null,
    r.conditions?.operationVariant ?? null, r.conditions?.patchWindow ?? null]);
}
function median(values) {
  const a = values.slice().sort((x, y) => x - y);
  const i = Math.floor(a.length / 2);
  return a.length % 2 ? a[i] : (a[i - 1] + a[i]) / 2;
}
function assertAdmitted(r) {
  if (!Number.isSafeInteger(r.inputItemID) || r.inputItemID < 1 ||
      !Number.isSafeInteger(r.outputItemID) || r.outputItemID < 1 ||
      r.inputItemID === r.outputItemID ||
      !positiveInteger(r.inputCountPerOperation) || !r.recordID || !r.method ||
      /^(?:ILLEGAL|INVALID_MAPPING|QUARANTINED_ILLEGAL)/.test(r.conditions?.eligibilityStatus || "")) {
    throw Error("Working estimate requires an admitted legal mapping: " + r.recordID);
  }
}

/**
 * Add r.workingEstimate without changing any original field or condition.
 * Caller must first apply identity, recipe, rank and legal-mapping admission.
 * outputFamilyByItemID is optional reviewed canonical identity data, NOT an
 * inferred grouping from adjacent numeric item IDs.
 */
function applyWorkingEstimates(records, options = {}) {
  if (!Array.isArray(records)) throw Error("Expected records array");
  const poolMean = options.unresolvedRankPoolExpectedQuantity ?? 1;
  if (!finite(poolMean) || poolMean <= 0 || poolMean > Number.MAX_SAFE_INTEGER)
    throw Error("Invalid synthetic rank pool expectation");
  const donors = new Map(), pools = new Map(), poolByRecord = new Map();
  for (const r of records) {
    assertAdmitted(r);
    const e = evidenceValue(r, "expectedQuantity");
    const forbidden = (r.expectedQuantity?.blockers || []).some(b =>
      /GROSS_INPUT|NOT_ACTUAL_CAST|RANK_SPECIFIC|RANK_OR_GROSS_INPUT/.test(b));
    if (e !== null && !forbidden && r.expectedQuantity.status !== "contradictory") {
      const k = donorKey(r);
      if (!donors.has(k)) donors.set(k, []);
      donors.get(k).push({ recordID: r.recordID, value: e });
    }
    if (ambiguousRank(r) && e === null) {
      const family = canonicalFamily(r, options);
      // Without canonical identity, use ONE explicitly synthetic operation pool
      // instead of treating every rank as an independent full-family yield.
      const id = operationKey(r) + ":family:" + (family ?? "CANONICAL_FAMILY_UNKNOWN");
      if (!pools.has(id)) pools.set(id, { id, familyID: family, records: [] });
      pools.get(id).records.push(r.recordID);
      poolByRecord.set(r, id);
    }
  }
  for (const pool of pools.values()) pool.records.sort();

  const report = {
    policyVersion: POLICY_VERSION, records: records.length,
    fullyNumericRecords: 0, previewOnlyRecords: 0,
    imputedFieldCounts: Object.fromEntries(FIELDS.map(f => [f, 0])),
    adjustedFieldCounts: Object.fromEntries(FIELDS.map(f => [f, 0])),
    recordsWithAssumptions: 0, confidenceGE90Records: 0,
    unresolvedRankPools: pools.size, unresolvedRankRecords: poolByRecord.size,
    evidenceFieldsChanged: 0, normalizedVerifiedRecords: 0
  };
  for (const r of records) {
    const raw = Object.fromEntries(FIELDS.map(f => [f, evidenceValue(r, f)]));
    const w = {
      ...raw, policyVersion: POLICY_VERSION,
      status: "COPIED_EVIDENCE_PREVIEW", economicUse: "PREVIEW_ONLY",
      modelID: "SOURCE_CONTEXT_COPY_OR_SYNTHETIC_HURDLE_V1",
      normalizedVerified: false, evidenceFieldsPreserved: true,
      fieldConfidence: {}, fieldStatus: {}, assumptions: [], sourceRecordIDs: [],
      conditionalYieldApplicable: true,
      zeroSemantics: "NO_ZERO_ASSERTION",
      uncertainty: "NO_STATISTICAL_INTERVAL_AVAILABLE_FROM_POLICY_IMPUTATION",
      targetContext: {
        contextID: "HYPOTHETICAL_PREVIEW_NOT_VERIFIED_BASELINE",
        operationBasis: "ONE_COMPLETED_OPERATION",
        inputCountPerOperation: r.inputCountPerOperation,
        inputQualityRank: r.inputQualityRank ?? null,
        outputQualityRank: r.outputQualityRank ?? null,
        gameMode: r.conditions?.gameMode ?? "UNKNOWN",
        patchWindow: r.conditions?.patchWindow ?? null,
        sourceCharacterContext: r.conditions?.characterContext ?? "UNKNOWN",
        sourceQuantityBasis: r.conditions?.quantityBasis ?? "UNKNOWN",
        eligibilityStatus: r.conditions?.eligibilityStatus ?? "UNKNOWN",
        eligibilityAssumedSatisfiedForPreview: true,
        skillAndStats: "UNRESOLVED_NO_INVERSION_APPLIED",
        sourceBaselineStatus: r.conditions?.baselineStatus ?? "UNKNOWN"
      }
    };
    for (const f of FIELDS) {
      w.fieldConfidence[f] = raw[f] === null ? 0 : score(r[f]?.confidence);
      w.fieldStatus[f] = raw[f] === null ? "POLICY_PRIOR" : "COPIED_EVIDENCE";
    }
    function assumption(text) { if (!w.assumptions.includes(text)) w.assumptions.push(text); }
    function set(f, v, why) {
      if (!finite(v)) throw Error("Nonfinite working value: " + r.recordID + ":" + f);
      if (raw[f] === null || v !== raw[f]) {
        w.fieldConfidence[f] = 0;
        w.fieldStatus[f] = raw[f] === null ? "POLICY_PRIOR" : "WORKING_CONSISTENCY_ADJUSTMENT";
        assumption(why);
      }
      w[f] = v;
    }
    for (const f of FIELDS)
      if (r[f]?.status === "contradictory")
        assumption("CONTRADICTORY_SOURCE_FIELD_EXCLUDED_FROM_WORKING_ESTIMATE:" + f);
    let p = raw.dropChance, a = raw.yieldMin, b = raw.yieldMax, e = raw.expectedQuantity;
    if (a !== null && b !== null && a > b) {
      [a, b] = [b, a];
      assumption("SOURCE_RANGE_REORDERED_IN_WORKING_LAYER_ONLY");
    }
    const poolID = poolByRecord.get(r);
    if (poolID) {
      const pool = pools.get(poolID);
      e = poolMean / pool.records.length;
      // Even an existing P for a different/ambiguous rank context cannot be
      // combined with this allocation as though it were a rank measurement.
      p = null;
      w.allocation = {
        poolID, canonicalFamilyID: pool.familyID,
        status: "UNRESOLVED_RANK_ALLOCATION_POLICY_PRIOR",
        poolExpectedQuantity: poolMean,
        allocationShare: 1 / pool.records.length,
        memberRecordIDs: pool.records.slice(),
        physicalUpperBound: false
      };
      assumption("UNIFORM_UNRESOLVED_RANK_ALLOCATION_IS_POLICY_NOT_EMPIRICAL");
      if (pool.familyID === null) assumption("CANONICAL_FAMILY_UNKNOWN_SHARED_OPERATION_PREVIEW_POOL");
    }
    if (e === null && p === null) {
      const familyDonors = donors.get(donorKey(r)) || [];
      if (familyDonors.length) {
        e = median(familyDonors.map(d => d.value));
        w.sourceRecordIDs = familyDonors.map(d => d.recordID).sort();
        assumption("COMPARABLE_OUTPUT_MEDIAN_TRANSFER_UNVALIDATED_FOR_THIS_INPUT");
      } else {
        const conditionalMean = a !== null && b !== null ? (a + b) / 2 : a ?? b ?? 1;
        e = 0.5 * conditionalMean;
        assumption("NO_EVIDENCE_POLICY_PRIOR_HALF_OCCURRENCE_AT_POSITIVE_SUPPORT");
      }
    }
    if (e === null) {
      const q = a !== null && b !== null ? (a + b) / 2 : a ?? b ?? 1;
      e = p * q;
      assumption("MISSING_EXPECTATION_USES_MIDPOINT_POSITIVE_YIELD_POLICY");
    }
    if (e === 0 || (p === 0 && raw.expectedQuantity === null && !poolID)) {
      e = 0; p = 0; a = 0; b = 0;
      w.conditionalYieldApplicable = false;
      w.zeroSemantics = "WORKING_ZERO_EXPECTATION_NOT_PROVEN_IMPOSSIBLE";
      assumption("ZERO_CONDITIONAL_BOUNDS_ARE_NOT_APPLICABLE_SENTINELS_NOT_OBSERVED_ZERO_YIELDS");
    } else {
      if (p === 0) {
        p = null;
        assumption("SOURCE_ZERO_P_CONFLICTS_WITH_POSITIVE_E_WORKING_P_REPLACED");
      }
      if (p === null) {
        let q = a !== null && b !== null ? (a + b) / 2 : a ?? b ?? Math.max(1, e);
        q = Math.max(1, q, e);
        p = e / q;
        assumption("E_ALONE_DOES_NOT_IDENTIFY_P_POSITIVE_SUPPORT_CHOSEN_BY_POLICY");
      }
      let q = e / p;
      if (q < 1) {
        p = Math.min(1, e / (a ?? 1));
        q = e / p;
        assumption("SOURCE_P_GT_E_REPAIRED_IN_WORKING_LAYER_ONLY");
      }
      // An integer two-point conditional distribution on [a,b] can realize q.
      // Any expanded support here is an assumption, never a measured bound.
      if (a === null) a = Math.max(1, Math.min(b ?? Infinity, Math.floor(q)));
      if (b === null) b = Math.max(a, Math.ceil(q));
      if (a > q + EPS) a = Math.max(1, Math.floor(q));
      if (b < q - EPS) b = Math.ceil(q);
      if (!positiveInteger(a) || !positiveInteger(b))
        throw Error("Unrepresentable integer working support: " + r.recordID);
    }
    set("dropChance", p, "OCCURRENCE_ESTIMATED_OR_REPAIRED_BY_WORKING_POLICY");
    set("yieldMin", a, "POSITIVE_LOWER_SUPPORT_IS_POLICY_WHERE_UNOBSERVED_OR_INCONSISTENT");
    set("yieldMax", b, "POSITIVE_UPPER_SUPPORT_IS_POLICY_WHERE_UNOBSERVED_OR_INCONSISTENT");
    set("expectedQuantity", e, "UNCONDITIONAL_EXPECTATION_ESTIMATED_BY_WORKING_POLICY");
    if (poolID) {
      w.fieldConfidence.dropChance = 0;
      w.fieldStatus.dropChance = "POLICY_PRIOR";
    }
    w.confidence = Math.min(score(r.mappingConfidence), score(r.conditionsConfidence),
      ...FIELDS.map(f => w.fieldConfidence[f]));
    if (w.assumptions.length) {
      w.status = "PROVISIONAL_WORKING_ESTIMATE";
      w.confidence = 0;
      report.recordsWithAssumptions++;
    }
    for (const f of FIELDS) {
      if (raw[f] === null) report.imputedFieldCounts[f]++;
      else if (w[f] !== raw[f]) report.adjustedFieldCounts[f]++;
    }
    if (w.confidence >= 90) report.confidenceGE90Records++;
    report.fullyNumericRecords++;
    report.previewOnlyRecords++;
    r.workingEstimate = w;
  }
  const errors = validateWorkingEstimates(records);
  if (errors.length) throw Error("Working estimate validation: " + errors.slice(0, 8).join(","));
  return report;
}

function validateWorkingEstimates(records) {
  const errors = [], allocations = new Map();
  for (const r of records) {
    const w = r.workingEstimate, id = r.recordID;
    if (!w) { errors.push("MISSING_WORKING_ESTIMATE:" + id); continue; }
    if (FIELDS.some(f => !finite(w[f]))) errors.push("NONFINITE_WORKING_FIELD:" + id);
    const p = w.dropChance, e = w.expectedQuantity, a = w.yieldMin, b = w.yieldMax;
    if (p < 0 || p > 1 || e < 0 || a > b) errors.push("WORKING_DOMAIN:" + id);
    if (w.conditionalYieldApplicable) {
      if (!positiveInteger(a) || !positiveInteger(b) || p <= 0 || e <= 0)
        errors.push("WORKING_POSITIVE_SUPPORT:" + id);
    } else if (p !== 0 || e !== 0 || a !== 0 || b !== 0 ||
      w.zeroSemantics !== "WORKING_ZERO_EXPECTATION_NOT_PROVEN_IMPOSSIBLE") {
      errors.push("WORKING_ZERO_NOT_APPLICABLE:" + id);
    }
    if (e + EPS < p * a || e > p * b + EPS) errors.push("WORKING_P_E_RANGE:" + id);
    if (w.economicUse !== "PREVIEW_ONLY" || w.normalizedVerified !== false ||
      w.evidenceFieldsPreserved !== true) errors.push("WORKING_SCOPE_LEAK:" + id);
    if (!Array.isArray(w.assumptions) || !w.fieldConfidence || !w.fieldStatus)
      errors.push("WORKING_METADATA:" + id);
    else {
      if (w.assumptions.length && w.confidence !== 0) errors.push("ASSUMED_WORKING_CONFIDENCE:" + id);
      for (const f of FIELDS) {
        const raw = evidenceValue(r, f);
        if ((raw === null || w[f] !== raw) && w.fieldConfidence[f] !== 0)
          errors.push("IMPUTED_FIELD_CONFIDENCE:" + id + ":" + f);
      }
    }
    if (w.allocation) {
      const x = w.allocation;
      if (!allocations.has(x.poolID)) allocations.set(x.poolID, { sum: 0, target: x.poolExpectedQuantity });
      allocations.get(x.poolID).sum += e;
      if (x.physicalUpperBound !== false) errors.push("RANK_POOL_ASSERTED_PHYSICAL_BOUND:" + id);
    }
  }
  for (const [id, x] of allocations)
    if (Math.abs(x.sum - x.target) > EPS * Math.max(1, x.target)) errors.push("RANK_POOL_DUPLICATED_E:" + id);
  return errors;
}

module.exports = { applyWorkingEstimates, validateWorkingEstimates, POLICY_VERSION, FIELDS };
