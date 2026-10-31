"use strict";
// Operational contracts for the five existing agents, independent of candidate values.
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const crypto = require("node:crypto");
const root = path.resolve(__dirname, "../..");
const read = relative => fs.readFileSync(path.join(root, relative), "utf8");
const workflow = JSON.parse(read("research/coordination/five-agent-workflow.json"));
const bootstrap = JSON.parse(read("research/prompts/five-agent/automation-prompts.json"));
const expectedRoles = ["coordinator", "completion-engineer", "baseline-modeller", "evidence-researcher", "independent-validator"];

function owns(pattern, file) {
  if (pattern.endsWith("/")) return file.startsWith(pattern);
  const escaped = pattern.split("*").map(s => s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")).join(".*");
  return new RegExp("^" + escaped + "$").test(file);
}

function validateWorkflow(w, b) {
  const errors = [];
  const check = (condition, label) => { if (!condition) errors.push(label); };
  check(JSON.stringify(Object.keys(w.roles).sort()) === JSON.stringify(expectedRoles.slice().sort()), "exactly-five-functional-roles");
  check(w.canonicalBranch === "implementation/five-agent-completion", "research-implementation-branch");
  check(w.runtimeDependencyBranch === "implementation/five-agent-runtime-profiles", "runtime-dependency-recognized");
  check(w.gates.production.authorized === false, "no-production-authorization");
  check(w.legacy.preservePath === "research/coordination/assignments.json", "legacy-queue-preserved");
  check(w.canonicalScorecard === "research/coordination/completion-readiness.json", "single-current-scorecard");
  check(w.canonicalPriorityBacklog === "research/coordination/completion-priorities.json", "current-not-hardcoded-priorities");
  check(w.scheduling.preserveExistingSchedules === true && w.scheduling.createDuplicateAutomations === false, "existing-schedules-only");
  check(w.scheduling.zeroDeltaPivot.consecutiveCycles === 2, "zero-delta-pivot");
  check(w.gates.evidence90.threshold === 90 && /not.*statistical probability|never a statistical probability/i.test(w.gates.evidence90.basis), "evidence-score-is-not-probability");
  check(/minimum/i.test(w.gates.evidence90.aggregation), "weakest-field-promotion-gate");
  check(w.economicPolicy.workingFallbacks.confidence === 0 && w.economicPolicy.workingFallbacks.economicUse === "PREVIEW_ONLY" && w.economicPolicy.workingFallbacks.normalizedVerified === false && w.economicPolicy.workingFallbacks.operationalEstimatesAffectLiveValuation === false, "fallback-isolation");
  check(b.automations.length === 5 && new Set(b.automations.map(a => a.existingAutomation)).size === 5, "five-existing-automations");
  check(new Set(b.automations.map(a => a.functionalRole)).size === 5, "one-bootstrap-per-role");
  check(w.tasks.length >= 5 && new Set(w.tasks.map(t => t.id)).size === w.tasks.length, "unique-concrete-tasks");
  for (const [role, definition] of Object.entries(w.roles)) {
    const automation = b.automations.find(a => a.functionalRole === role);
    check(Boolean(automation && automation.existingAutomation === definition.automation && automation.preserveSchedule), "bootstrap-identity:" + role);
    check(Boolean(automation && automation.prompt.includes(definition.prompt) && automation.prompt.includes(w.commonPrompt)), "bootstrap-role-files:" + role);
    check(w.tasks.some(t => t.id === definition.initialTask && t.owner === role), "initial-task-owner:" + role);
    check(fs.existsSync(path.join(root, definition.prompt)), "role-file-exists:" + role);
  }
  const roleEntries = Object.entries(w.roles);
  for (let a = 0; a < roleEntries.length; a++) for (let b = a + 1; b < roleEntries.length; b++) {
    const [nameA, roleA] = roleEntries[a], [nameB, roleB] = roleEntries[b];
    for (const ownA of roleA.owns) for (const ownB of roleB.owns) {
      const sampleA = ownA.replace(/\*/g, "example") + (ownA.endsWith("/") ? "example.json" : "");
      const sampleB = ownB.replace(/\*/g, "example") + (ownB.endsWith("/") ? "example.json" : "");
      check(!owns(ownA, sampleB) && !owns(ownB, sampleA), "disjoint-ownership:" + nameA + ":" + nameB);
    }
  }
  for (const [queueName, count] of [["priorQueue29ExpectedQuantityTargets", 36], ["pendingQueue30UniverseLeads", 24]]) {
    const keys = Object.values(w.legacy[queueName]).flatMap(group => group.stableKeys);
    check(keys.length === count && new Set(keys).size === count, "preserved-unique-backlog:" + queueName);
  }
  return errors;
}

assert.deepEqual(validateWorkflow(workflow, bootstrap), []);
const clone = value => JSON.parse(JSON.stringify(value));
let bad = clone(workflow);
bad.roles["evidence-researcher"].owns.push("research/tools/compile_itemdb.js");
assert(validateWorkflow(bad, bootstrap).some(e => e.startsWith("disjoint-ownership:")), "must detect an agent claiming compiler ownership");
bad = clone(workflow);
bad.economicPolicy.workingFallbacks.economicUse = "LIVE";
assert(validateWorkflow(bad, bootstrap).includes("fallback-isolation"), "must reject accidental live activation");
bad = clone(workflow);
const firstGroup = Object.values(bad.legacy.priorQueue29ExpectedQuantityTargets)[0];
firstGroup.stableKeys[1] = firstGroup.stableKeys[0];
assert(validateWorkflow(bad, bootstrap).includes("preserved-unique-backlog:priorQueue29ExpectedQuantityTargets"), "must detect duplicate evidence assignments");
const badBootstrap = clone(bootstrap);
badBootstrap.automations[1].functionalRole = badBootstrap.automations[0].functionalRole;
assert(validateWorkflow(workflow, badBootstrap).includes("one-bootstrap-per-role"), "must reject duplicate functional agent roles");

// Check the original evidence inputs and frozen runtime source blobs against their
// pinned Git blob IDs. Candidate counts may change; immutable inputs must not.
const sourceManifest = JSON.parse(read("research/proposed/itemdb-compiler-source-shas.json"));
const immutableInputs = {
  primary: "research/ledger/processing-output-fields.csv",
  supplemental: "research/ledger/supplemental-output-fields.csv",
  midnightCandidate: "research/proposed/itemdb-midnight-milling-candidate.json",
  gameData: "GameData.lua",
  statYield: "StatYieldProfiles.lua"
};
for (const [key, file] of Object.entries(immutableInputs)) {
  const bytes = fs.readFileSync(path.join(root, file));
  const hash = crypto.createHash("sha1").update(Buffer.from("blob " + bytes.length + "\0")).update(bytes).digest("hex");
  assert.equal(hash, sourceManifest[key], "original evidence/frozen source changed: " + file);
}
const common = read(workflow.commonPrompt);
assert(common.includes('economicUse="PREVIEW_ONLY"') && common.includes("confidence 0"));
assert(common.includes("Evidence") && common.includes("Working estimates") && common.includes("Economic use"));
assert(common.includes("whole independent study families") && /not.*statistical accuracy/.test(common));
assert(common.includes("--check") && common.includes("test_generated_working_estimates.lua"));
for (const automation of bootstrap.automations) {
  assert(automation.prompt.includes("completion-readiness.json") && automation.prompt.includes("completion-priorities.json"));
  assert(!/to100%with|confidence0|liveEV|atleast90/.test(automation.prompt), "bootstrap must remain readable");
}
console.log("PASS: five functional agents, disjoint ownership, existing schedules, preserved backlogs and raw evidence, preview isolation and independent confidence policy");
