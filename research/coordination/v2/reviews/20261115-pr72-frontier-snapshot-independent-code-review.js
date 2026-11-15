"use strict";

// Replay the independently executed review cases recorded in the adjacent JSON.
const assert = require("node:assert/strict");
const { createHash } = require("node:crypto");
const fs = require("node:fs");
const path = require("node:path");

const root = path.resolve(__dirname, "../../../..");
const recordPath = path.join(__dirname, "20261115-pr72-frontier-snapshot-independent-code-review.json");
const modelPath = "research/tools/models_v2/df_prospect_decision_frontier_v1.js";

function gitBlob(file) {
    const bytes = fs.readFileSync(file);
    return createHash("sha1").update(`blob ${bytes.length}\0`).update(bytes).digest("hex");
}

function checkPins(record) {
    assert.equal(gitBlob(__filename), record.reproduction.scriptGitBlob, "Review harness blob");
    for (const [file, expected] of Object.entries(record.sourcePins)) {
        assert.equal(gitBlob(path.join(root, file)), expected, file);
    }
}

function runCases(model) {
    const keys = model.TARGETS.slice(0, 2).map(({ stableKey }) => stableKey);
    const row = (index, priceGold) => ({ stableKey: keys[index], priceGold, eLower: 1, eUpper: 1 });
    const scenario = () => ({
        inputItemID: 188658,
        snapshotDate: "2026-11-15",
        scenarioSourceID: "independent-check",
        policy: "SCENARIO_ONLY",
        nominalInputPerCast: 5,
        costGoldPerCast: 3,
        depositGoldPerCast: 0,
        alternativeNetGoldPerCast: 25,
        feeRate: 0,
        otherRevenueGoldPerCast: 0,
        otherRevenueBasis: "EXCLUDES_SELECTED_OUTPUTS",
        costBasis: "GROSS_NO_REFUNDS",
        outputs: [row(0, 10), row(1, 10)],
    });
    const control = {
        accepted: true,
        selectedKeys: 2,
        lowerNetGoldPerCompletedCast: 17,
        decision: "ALTERNATIVE_WINS_IN_SCENARIO",
        policy: {
            confidence: 0,
            economicUse: "PREVIEW_ONLY",
            normalizedVerified: false,
            liveEconomicEligible: false,
            tooltipOnlyEligible: false,
        },
        callbackInvocations: 0,
    };
    const cases = [];

    function run(label, expected, prepare) {
        const input = scenario();
        const context = { hooks: 0 };
        const prepared = prepare(input, context) ?? input;
        let actual;
        try {
            const result = model.evaluateScenario(prepared);
            actual = {
                accepted: true,
                selectedKeys: result.selectedKeys.length,
                lowerNetGoldPerCompletedCast: result.lowerNetGoldPerCompletedCast,
                decision: result.scenarioDecision,
                policy: result.policy,
                callbackInvocations: context.hooks,
            };
        } catch (error) {
            actual = { accepted: false, error: error.message, callbackInvocations: context.hooks };
        }
        let passed = true;
        try {
            assert.deepEqual(actual, expected);
        } catch {
            passed = false;
        }
        cases.push({ label, passed, expected, actual });
    }

    function reject(label, error, prepare) {
        run(label, { accepted: false, error, callbackInvocations: 0 }, prepare);
    }

    run("plain two rows", control, () => {});
    run("frozen plain output rows and array", control, (input) => {
        input.outputs.forEach(Object.freeze);
        Object.freeze(input.outputs);
    });
    reject("ordinary empty output", "DENSE_ARRAY", (input) => { input.outputs = []; });
    reject("ordinary output array getter", "ARRAY_ACCESSOR_OR_HOLE", (input, context) => {
        Object.defineProperty(input.outputs, "0", {
            enumerable: true,
            get() { context.hooks++; return row(0, 999); },
        });
    });
    reject("ordinary output record getter", "ACCESSOR_OR_HIDDEN_FIELD", (input, context) => {
        Object.defineProperty(input.outputs[0], "priceGold", {
            enumerable: true,
            get() { context.hooks++; return 999; },
        });
    });
    reject("top-level output-array shrinking proxy", "DENSE_ARRAY", (input, context) => {
        input.outputs = new Proxy(input.outputs, {
            get(target, key, receiver) {
                if (key === "length") return ++context.hooks <= 4 ? 2 : 1;
                return Reflect.get(target, key, receiver);
            },
        });
    });
    reject("top-level output-array shrink/regrow proxy", "DENSE_ARRAY", (input, context) => {
        input.outputs = new Proxy(input.outputs, {
            get(target, key, receiver) {
                if (key === "length") return ++context.hooks % 2 === 0 ? 1 : 2;
                return Reflect.get(target, key, receiver);
            },
        });
    });

    function rejectOutputRecord(label, firstCallback) {
        reject(label, "PLAIN_RECORD", (input, context) => {
            const outputs = input.outputs;
            outputs[0] = new Proxy(outputs[0], {
                ownKeys(target) {
                    if (context.hooks++ === 0) firstCallback(outputs);
                    return Reflect.ownKeys(target);
                },
            });
        });
    }

    rejectOutputRecord("nested output-record transparent Proxy", () => {});
    rejectOutputRecord("nested output-record same-length sibling replacement", (outputs) => {
        outputs[1] = row(1, 100);
    });
    rejectOutputRecord("nested output-record shrink persists", (outputs) => { outputs.length = 1; });
    rejectOutputRecord("nested output-record shrink/regrow", (outputs) => {
        outputs.length = 1;
        outputs.push(row(1, 100));
    });
    rejectOutputRecord("nested output-record reentrancy", (outputs) => {
        const inner = model.evaluateScenario(scenario());
        outputs[1] = row(1, inner.lowerNetGoldPerCompletedCast + 100);
    });
    reject("top-level scenario proxy output alias mutation", "PLAIN_RECORD", (input, context) => {
        return new Proxy(input, {
            get(target, key, receiver) {
                if (key === "outputs" && context.hooks++ === 0) target.outputs[1] = row(1, 100);
                return Reflect.get(target, key, receiver);
            },
        });
    });
    return cases;
}

function main() {
    const record = JSON.parse(fs.readFileSync(recordPath, "utf8"));
    checkPins(record);
    const cases = runCases(require(path.join(root, modelPath)));
    const passed = cases.filter((result) => result.passed).length;
    const failed = cases.length - passed;
    console.log(JSON.stringify({
        reviewType: record.reviewType,
        runtime: process.version,
        sourcePins: record.sourcePins,
        passed,
        failed,
        modelAccepted: false,
        cases,
    }, null, 2));
    if (failed || passed !== record.execution.independentCases.passed) process.exitCode = 1;
}

try {
    main();
} catch (error) {
    console.error(`Independent Frontier replay failed: ${error.message}`);
    process.exitCode = 1;
}
