"use strict";

// A research preview layer. Nothing in this module promotes evidence, normalizes
// a character, reads tooltip data, or authorizes economic/runtime decisions.
const FIELDS = ["dropChance", "yieldMin", "yieldMax", "expectedQuantity"];
const {createHash} = require("node:crypto");
const SERIALIZED_ATTESTATION_VERSION = "working-estimate-source-context-v1.0.0";
const sha256 = text => createHash("sha256").update(text, "utf8").digest("hex");
const POLICY_VERSION = "working-estimate-policy-v1";
const EPS = 1e-9;
// Same-process source-identity lease. Deliberately non-serialized: a reloaded
// preview must be recompiled before this validation can certify source identity.
const sourceIdentityAtBuild = new WeakMap();
// Pin the generated working preview independently of its source evidence.
// This in-process lease cannot attest a separately loaded serialized artifact.
const workingIdentityAtBuild = new WeakMap();

function finite(v) { return typeof v === "number" && Number.isFinite(v); }
function positiveInteger(v) { return Number.isSafeInteger(v) && v >= 1; }
function score(v) { return Number.isInteger(v) && v >= 0 && v <= 100 ? v : 0; }
const ADMISSIBLE_EVIDENCE_STATUSES = new Set([
  "official", "measured", "community-reported", "modeled", "proxy"
]);
// A number reported per gross input, unresolved output rank, or an unverified
// cast denominator is not per-completed-operation P/E evidence. Preserve the
// original source field unchanged; only its working-preview eligibility changes.
// Unknown basis alone remains unknown, not a fabricated zero or normalization.
const INAPPLICABLE_CAST_FIELD_BLOCKER =
  /GROSS[_ -]?INPUT|NOT[_ -]?ACTUAL[_ -]?CAST|NO[_ -]?ACTUAL[_ -]?CAST|RANK[_ -]?(?:SPECIFIC|OR[_ -]?GROSS[_ -]?INPUT|ALLOCATION)|PER[_ -]?(?:ORE|INPUT)/i;
const INAPPLICABLE_QUANTITY_BASIS =
  /GROSS[_ -]?INPUT|NOT[_ -]?ACTUAL[_ -]?CAST|NO[_ -]?ACTUAL[_ -]?CAST|PER[_ -]?(?:ORE|INPUT)|INPUT[_ -]?EQUIVALENT/i;
function castBasisApplicable(r, f) {
  if (f !== "dropChance" && f !== "expectedQuantity") return true;
  const source = r[f];
  if (Array.isArray(source?.blockers) &&
      source.blockers.some(b => typeof b === "string" &&
        INAPPLICABLE_CAST_FIELD_BLOCKER.test(b))) return false;
  const basis = r.conditions?.quantityBasis;
  if (typeof basis === "string" && INAPPLICABLE_QUANTITY_BASIS.test(basis))
    return false;
  return true;
}
function evidenceValue(r, f) {
  // A finite source number is not automatically admissible evidence.
  // Unknown, contradictory or unrecognized statuses and untraceable claims
  // must remain separate from the preview, even with high source confidence.
  const source = r[f];
  if (!castBasisApplicable(r, f)) return null;
  if (!source || !ADMISSIBLE_EVIDENCE_STATUSES.has(source.status) ||
      !Array.isArray(source.sourceClaimIDs) ||
      source.sourceClaimIDs.length === 0 ||
      !source.sourceClaimIDs.every(id => typeof id === "string" && id.trim().length > 0))
    return null;
  const v = source.value;
  if (!finite(v)) return null;
  if (f === "dropChance") return v >= 0 && v <= 1 ? v : null;
  if (f === "expectedQuantity") return v >= 0 ? v : null;
  return positiveInteger(v) ? v : null;
}
// Legacy identifier is retained only for unchanged, non-colliding preview
// pools. Its stable serialized value avoids rewriting unrelated candidate rows.
function legacyOperationKey(r) {
  const c = r.conditions || {};
  return JSON.stringify([r.method, r.expansionID, r.inputItemID,
    r.inputQualityRank ?? null, r.recipeSpellID ?? null,
    r.inputCountPerOperation, c.operationVariant ?? null,
    c.patchWindow ?? null, c.characterContext ?? null,
    c.effectiveSkill ?? null, c.specialization ?? null, c.operationStats ?? null,
    c.sourceContext ?? null, c.quantityBasis ?? null,
    c.eligibilityStatus ?? null, c.baselineStatus ?? null]);
}
// Strict grouping includes game mode, the complete available direct reagent
// vector and eligibility discriminators; missing vectors remain UNKNOWN, not
// proof of any physical reagent recipe.
function operationKey(r) {
  const c = r.conditions || {};
  return stableDonorContext([legacyOperationKey(r), c.gameMode ?? null,
    canonicalDirectReagents(r), c.skillLineID ?? null,
    c.minimumRecipeSkill ?? null, c.requiredProfession ?? null,
    c.requiresLearnedRecipe ?? null, c.requiresForge ?? null,
    c.requiresBench ?? null, c.unlocks ?? null]);
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
function stableDonorContext(v){if(v===null||v===undefined||typeof v!=="object")return JSON.stringify(v??null);if(Array.isArray(v))return "["+v.map(stableDonorContext).join(",")+"]";return "{"+Object.keys(v).sort().map(k=>JSON.stringify(k)+":"+stableDonorContext(v[k])).join(",")+"}";}
function canonicalDirectReagents(r) {
  if (!Array.isArray(r.reagents) || !r.reagents.length)
    return ["UNKNOWN_DIRECT_REAGENT_VECTOR"];
  const rows = r.reagents.map(x =>
    x && Number.isSafeInteger(x.itemID) && x.itemID > 0 &&
    Number.isSafeInteger(x.quantity) && x.quantity > 0 ? {...x} : null);
  if (rows.includes(null)) return ["INVALID_DIRECT_REAGENT_VECTOR", r.recordID];
  return rows.sort((a,b) => stableDonorContext(a).localeCompare(stableDonorContext(b)));
}
// Capture full source identity independently of the smaller, historical
// serialized targetContext. This catches post-build recipe/reagent/skill/stat
// mutation without rewriting research candidate artifacts during the transition.
function sourceIdentity(r) {
  return stableDonorContext({
    recordID: r.recordID, method: r.method, expansionID: r.expansionID,
    inputItemID: r.inputItemID, outputItemID: r.outputItemID,
    inputQualityRank: r.inputQualityRank ?? null,
    outputQualityRank: r.outputQualityRank ?? null,
    recipeSpellID: r.recipeSpellID ?? null,
    inputCountPerOperation: r.inputCountPerOperation,
    outputFamilyID: r.outputFamilyID ?? null,
    directReagents: canonicalDirectReagents(r),
    conditions: r.conditions ?? null,
    mappingConfidence: r.mappingConfidence ?? null,
    conditionsConfidence: r.conditionsConfidence ?? null,
    // A source change to value, status, confidence, claims or blockers
    // invalidates the preview, even if the displayed number stays unchanged.
    evidenceFields: Object.fromEntries(FIELDS.map(f => [f, r[f] ?? null]))
  });
}
// Group by strict identity, then retain the old ID only if unambiguous.
// Colliding legacy IDs get distinct strict-context suffixes. This preserves
// byte-identical preview output when no real context collision exists.
function collectRankPools(records, options = {}) {
  const strictGroups = new Map(), legacyCounts = new Map();
  for (const r of records) {
    if (!ambiguousRank(r) || evidenceValue(r, "expectedQuantity") !== null) continue;
    const familyID = canonicalFamily(r, options);
    const suffix = ":family:" + (familyID ?? "CANONICAL_FAMILY_UNKNOWN");
    const strictID = operationKey(r) + suffix;
    const legacyID = legacyOperationKey(r) + suffix;
    if (!strictGroups.has(strictID))
      strictGroups.set(strictID, {strictID, legacyID, familyID, records: [], rows: []});
    const pool = strictGroups.get(strictID);
    pool.records.push(r.recordID);
    pool.rows.push(r);
  }
  for (const pool of strictGroups.values())
    legacyCounts.set(pool.legacyID, (legacyCounts.get(pool.legacyID) || 0) + 1);
  const pools = new Map(), poolByRecord = new Map();
  for (const pool of strictGroups.values()) {
    pool.records.sort();
    pool.id = legacyCounts.get(pool.legacyID) === 1 ? pool.legacyID :
      pool.legacyID + ":strict-context:" + pool.strictID;
    pools.set(pool.id, pool);
    for (const row of pool.rows) poolByRecord.set(row, pool.id);
  }
  return {pools, poolByRecord};
}

function donorKey(r){
  const c=r.conditions||{};
  // Unknown recipe/rank/skill or an incomplete reagent vector is not a
  // transferable context. The independent F005 fixture supplies all of these.
  if(!Number.isSafeInteger(r.recipeSpellID)||r.recipeSpellID<1||
     !Number.isSafeInteger(r.inputQualityRank)||!Number.isSafeInteger(r.outputQualityRank)||
     !Array.isArray(r.reagents)||!r.reagents.length||
     !r.reagents.some(v=>v&&v.itemID===r.inputItemID&&v.quantity===r.inputCountPerOperation)||
     typeof c.gameMode!=="string"||!c.gameMode||c.gameMode==="UNKNOWN"||
     typeof c.patchWindow!=="string"||!c.patchWindow||c.patchWindow==="UNKNOWN"||
     typeof c.effectiveSkill!=="number"||!Number.isFinite(c.effectiveSkill)||
     typeof c.operationVariant!=="string"||!c.operationVariant||
     typeof c.eligibilityStatus!=="string"||!c.eligibilityStatus||
     typeof c.baselineStatus!=="string"||!c.baselineStatus)return null;
  const reagents=r.reagents.map(v=>
    v&&Number.isSafeInteger(v.itemID)&&Number.isSafeInteger(v.quantity)&&v.quantity>0?
    {...v,itemID:v.itemID===r.inputItemID?"PRIMARY_INPUT":v.itemID}:null);
  if(reagents.includes(null))return null;
  reagents.sort((a,b)=>stableDonorContext(a).localeCompare(stableDonorContext(b)));
  // The primary input ID may vary within a proposed family prior, but its
  // quantity and every other direct reagent/quality property must match.
  // This remains confidence-zero preview, never evidence or economic use.
  return stableDonorContext([r.method,r.expansionID,r.recipeSpellID,
    r.inputCountPerOperation,r.inputQualityRank,r.outputItemID,
    r.outputQualityRank,reagents,c]);
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
// Reconstruct the serialized target from the current source on validation.
// A stale preview must not retain a former patch, rank, mode or eligibility.
function workingTargetContext(r) {
  return {
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
  };
}

function applyWorkingEstimates(records, options = {}) {
  if (!Array.isArray(records)) throw Error("Expected records array");
  const poolMean = options.unresolvedRankPoolExpectedQuantity ?? 1;
  if (!finite(poolMean) || poolMean <= 0 || poolMean > Number.MAX_SAFE_INTEGER)
    throw Error("Invalid synthetic rank pool expectation");
  const donors = new Map();
  const {pools, poolByRecord} = collectRankPools(records, options);
  for (const r of records) {
    assertAdmitted(r);
    const e = evidenceValue(r, "expectedQuantity");
    // evidenceValue already applies the same cast-basis and rank contract
    // used by target copying, unresolved pools, and donor validation.
    if (e !== null && r.expectedQuantity.status !== "contradictory") {
      const k = donorKey(r);
      if (k !== null && !donors.has(k)) donors.set(k, []);
      if (k !== null) donors.get(k).push({ recordID: r.recordID, value: e });
    }
  }

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
      targetContext: workingTargetContext(r)
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
    for (const f of FIELDS) {
      if (r[f]?.status === "contradictory")
        assumption("CONTRADICTORY_SOURCE_FIELD_EXCLUDED_FROM_WORKING_ESTIMATE:" + f);
      else if (finite(r[f]?.value) && raw[f] === null)
        assumption("UNQUALIFIED_SOURCE_FIELD_EXCLUDED_FROM_WORKING_ESTIMATE:" + f);
    }
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
      const key = donorKey(r);
      const familyDonors = key === null ? [] : (donors.get(key) || []);
      if (familyDonors.length) {
        e = median(familyDonors.map(d => d.value));
        w.sourceRecordIDs = familyDonors.map(d => d.recordID).sort();
        assumption("CONTEXT_MATCHED_PRIMARY_INPUT_NORMALIZED_MEDIAN_TRANSFER_PREVIEW_ONLY");
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
    sourceIdentityAtBuild.set(w, sourceIdentity(r));
    workingIdentityAtBuild.set(w, stableDonorContext(w));
  }
  const errors = validateWorkingEstimates(records, options);
  if (errors.length) throw Error("Working estimate validation: " + errors.slice(0, 8).join(","));
  return report;
}

function validateWorkingEstimates(records, options = {}) {
  const errors = [], allocations = new Map(), byRecordID = new Map();
  const seal = options.serializedAttestation || null, sealedEntries = new Map();
  if (seal) {
    if (seal.contractVersion !== SERIALIZED_ATTESTATION_VERSION ||
        seal.hashAlgorithm !== "sha256" || seal.recordCount !== records.length ||
        !Array.isArray(seal.entries) || seal.entries.length !== records.length)
      errors.push("SERIALIZED_ATTESTATION_CONTRACT_OR_COUNT_MISMATCH");
    if (typeof options.expectedAttestationSHA256 !== "string" ||
        !/^[0-9a-f]{64}$/.test(options.expectedAttestationSHA256) ||
        sha256(stableDonorContext(seal)) !== options.expectedAttestationSHA256)
      errors.push("SERIALIZED_ATTESTATION_UNPINNED_OR_TAMPERED");
    if (Array.isArray(seal.entries)) {
      let lastID = null;
      for (const entry of seal.entries) {
        if (!entry || typeof entry.recordID !== "string" ||
            (lastID !== null && entry.recordID <= lastID) ||
            !/^[0-9a-f]{64}$/.test(entry.sourceSHA256 || "") ||
            !/^[0-9a-f]{64}$/.test(entry.workingSHA256 || ""))
          errors.push("SERIALIZED_ATTESTATION_ENTRY_INVALID_OR_UNSORTED");
        if (entry && typeof entry.recordID === "string")
          sealedEntries.set(entry.recordID, entry);
        lastID = entry?.recordID ?? lastID;
      }
    }
  }
  const poolMean = options.unresolvedRankPoolExpectedQuantity ?? 1;
  if (!finite(poolMean) || poolMean <= 0 || poolMean > Number.MAX_SAFE_INTEGER)
    errors.push("INVALID_SYNTHETIC_RANK_POOL_POLICY");
  const {pools: expectedPools, poolByRecord: expectedPoolByRecord} =
    collectRankPools(records, options);
  // A donor ID must resolve to one unambiguous original evidence record.
  for (const r of records) {
    if (byRecordID.has(r.recordID)) errors.push("DUPLICATE_WORKING_RECORD_ID:" + r.recordID);
    else byRecordID.set(r.recordID, r);
  }
  for (const r of records) {
    const w = r.workingEstimate, id = r.recordID;
    if (!w) { errors.push("MISSING_WORKING_ESTIMATE:" + id); continue; }
    if (seal) {
      const entry = sealedEntries.get(id);
      if (!entry || entry.sourceSHA256 !== sha256(sourceIdentity(r)))
        errors.push("SERIALIZED_SOURCE_IDENTITY_STALE_OR_TAMPERED:" + id);
      if (!entry || entry.workingSHA256 !== sha256(stableDonorContext(w)))
        errors.push("SERIALIZED_WORKING_PREVIEW_STALE_OR_TAMPERED:" + id);
    } else {
      if (!sourceIdentityAtBuild.has(w) ||
          sourceIdentityAtBuild.get(w) !== sourceIdentity(r))
        errors.push("WORKING_SOURCE_IDENTITY_STALE_OR_UNVERIFIABLE:" + id);
      if (!workingIdentityAtBuild.has(w) ||
          workingIdentityAtBuild.get(w) !== stableDonorContext(w))
        errors.push("WORKING_PREVIEW_ATTESTATION_STALE_OR_TAMPERED:" + id);
    }
    if (!w.targetContext ||
        stableDonorContext(w.targetContext) !== stableDonorContext(workingTargetContext(r)))
      errors.push("WORKING_TARGET_CONTEXT_STALE:" + id);
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
      const ceiling = Math.min(score(r.mappingConfidence), score(r.conditionsConfidence),
        ...FIELDS.map(f => score(w.fieldConfidence[f])));
      if (!Number.isInteger(w.confidence) || w.confidence < 0 ||
          w.confidence > ceiling)
        errors.push("WORKING_CONFIDENCE_EXCEEDS_EVIDENCE_CEILING:" + id);
      if (w.assumptions.length && w.confidence !== 0)
        errors.push("ASSUMED_WORKING_CONFIDENCE:" + id);
      if (w.status !== (w.assumptions.length ?
          "PROVISIONAL_WORKING_ESTIMATE" : "COPIED_EVIDENCE_PREVIEW"))
        errors.push("WORKING_STATUS_PROVENANCE_MISMATCH:" + id);
      for (const f of FIELDS) {
        const raw = evidenceValue(r, f);
        const fieldStatus = w.fieldStatus[f];
        const copied = fieldStatus === "COPIED_EVIDENCE";
        if (copied && (raw === null || w[f] !== raw ||
            w.fieldConfidence[f] !== score(r[f]?.confidence)))
          errors.push("WORKING_FALSE_COPIED_EVIDENCE:" + id + ":" + f);
        if (!copied && fieldStatus !== "POLICY_PRIOR" &&
            fieldStatus !== "WORKING_CONSISTENCY_ADJUSTMENT")
          errors.push("WORKING_UNKNOWN_FIELD_PROVENANCE:" + id + ":" + f);
        if (!copied && w.fieldConfidence[f] !== 0)
          errors.push("IMPUTED_FIELD_CONFIDENCE:" + id + ":" + f);
        if (raw === null && copied)
          errors.push("WORKING_MISSING_SOURCE_MISLABELED:" + id + ":" + f);
      }
    }
    // Donor ancestry is a contract, not a decorative source label. Reject
    // missing, duplicated, context-incompatible or non-evidentiary donors.
    if (!Array.isArray(w.sourceRecordIDs)) {
      errors.push("WORKING_DONOR_ANCESTRY_MISSING:" + id);
    } else if (w.sourceRecordIDs.length) {
      const targetKey = donorKey(r), donorValues = [], seen = new Set();
      if (w.allocation || evidenceValue(r, "expectedQuantity") !== null ||
          targetKey === null) errors.push("WORKING_DONOR_TARGET_INELIGIBLE:" + id);
      for (const donorID of w.sourceRecordIDs) {
        if (typeof donorID !== "string" || seen.has(donorID)) {
          errors.push("WORKING_DONOR_ID_DUPLICATE_OR_INVALID:" + id);
          continue;
        }
        seen.add(donorID);
        const donor = byRecordID.get(donorID);
        if (!donor) {
          errors.push("WORKING_DONOR_ID_UNRESOLVED:" + id + ":" + donorID);
          continue;
        }
        const donorE = evidenceValue(donor, "expectedQuantity");
        if (donor === r || targetKey === null || donorKey(donor) !== targetKey ||
            donorE === null) {
          errors.push("WORKING_DONOR_CONTEXT_OR_EVIDENCE_MISMATCH:" + id + ":" + donorID);
        } else donorValues.push(donorE);
      }
      if (donorValues.length === w.sourceRecordIDs.length &&
          Math.abs(w.expectedQuantity - median(donorValues)) >
            EPS * Math.max(1, Math.abs(w.expectedQuantity))) {
        errors.push("WORKING_DONOR_MEDIAN_MISMATCH:" + id);
      }
      if (JSON.stringify(w.sourceRecordIDs) !==
          JSON.stringify(w.sourceRecordIDs.slice().sort()))
        errors.push("WORKING_DONOR_ORDER_NONDETERMINISTIC:" + id);
    }
    const expectedPoolID = expectedPoolByRecord.get(r);
    if (expectedPoolID && !w.allocation)
      errors.push("RANK_POOL_ALLOCATION_MISSING:" + id);
    if (w.allocation) {
      const x = w.allocation, expectedPool = expectedPools.get(expectedPoolID);
      if (!expectedPool || x.poolID !== expectedPoolID)
        errors.push("RANK_POOL_CONTEXT_OR_ID_MISMATCH:" + id);
      if (expectedPool) {
        if (x.canonicalFamilyID !== expectedPool.familyID)
          errors.push("RANK_POOL_FAMILY_MISMATCH:" + id);
        if (!Array.isArray(x.memberRecordIDs) ||
            JSON.stringify(x.memberRecordIDs) !== JSON.stringify(expectedPool.records))
          errors.push("RANK_POOL_MEMBER_ANCESTRY_MISMATCH:" + id);
        const share = 1 / expectedPool.records.length;
        if (!finite(x.allocationShare) || Math.abs(x.allocationShare - share) > EPS)
          errors.push("RANK_POOL_ALLOCATION_SHARE_MISMATCH:" + id);
        if (!finite(x.poolExpectedQuantity) || x.poolExpectedQuantity <= 0 ||
            Math.abs(e - x.poolExpectedQuantity * share) >
              EPS * Math.max(1, Math.abs(e)))
          errors.push("RANK_POOL_MEMBER_EXPECTATION_MISMATCH:" + id);
      }
      // Member E/P and pool sum may be mutually self-consistent after tampering.
      // Anchor the serialized pool target to the explicit policy used to build it.
      if (x.poolExpectedQuantity !== poolMean)
        errors.push("RANK_POOL_POLICY_ANCHOR_MISMATCH:" + id);
      if (x.status !== "UNRESOLVED_RANK_ALLOCATION_POLICY_PRIOR")
        errors.push("RANK_POOL_STATUS_MISMATCH:" + id);
      if (x.physicalUpperBound !== false)
        errors.push("RANK_POOL_ASSERTED_PHYSICAL_BOUND:" + id);
      if (!allocations.has(x.poolID))
        allocations.set(x.poolID, {sum: 0, target: x.poolExpectedQuantity});
      const acc = allocations.get(x.poolID);
      if (!finite(x.poolExpectedQuantity) || x.poolExpectedQuantity <= 0 ||
          x.poolExpectedQuantity !== acc.target)
        errors.push("RANK_POOL_TARGET_MISMATCH:" + id);
      acc.sum += e;
    }
  }
  for (const [id, x] of allocations)
    if (!finite(x.target) ||
        Math.abs(x.sum - x.target) > EPS * Math.max(1, x.target))
      errors.push("RANK_POOL_DUPLICATED_E:" + id);
  return errors;
}

// Detached, versioned attestation for JSON-serialized research candidates.
// The expected SHA-256 must be pinned outside the artifact (e.g. coordinator
// acceptance record). A self-reported digest is not an independent trust root.
function createWorkingAttestation(records) {
  if (!Array.isArray(records)) throw Error("Expected records array");
  const entries = records.map(r => {
    if (!r.workingEstimate || typeof r.recordID !== "string")
      throw Error("Cannot attest incomplete working record");
    return {recordID:r.recordID,sourceSHA256:sha256(sourceIdentity(r)),
      workingSHA256:sha256(stableDonorContext(r.workingEstimate))};
  }).sort((a,b) => a.recordID.localeCompare(b.recordID));
  for (let i=1;i<entries.length;i++)
    if (entries[i-1].recordID === entries[i].recordID)
      throw Error("Duplicate attestation record ID: " + entries[i].recordID);
  const attestation = {contractVersion:SERIALIZED_ATTESTATION_VERSION,
    hashAlgorithm:"sha256",recordCount:entries.length,entries};
  return {attestation,sha256:sha256(stableDonorContext(attestation))};
}
function validateSerializedWorkingEstimates(records, attestation, expectedAttestationSHA256, options={}) {
  return validateWorkingEstimates(records, {...options,serializedAttestation:attestation,
    expectedAttestationSHA256});
}
module.exports = { applyWorkingEstimates, validateWorkingEstimates,
  createWorkingAttestation, validateSerializedWorkingEstimates,
  SERIALIZED_ATTESTATION_VERSION, POLICY_VERSION, FIELDS };
