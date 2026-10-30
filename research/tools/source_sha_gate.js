"use strict";
// F002 research-only provenance gate. Git blob pins identify exact source bytes;
// they do not independently verify game mechanics or constitute an external trust root.
const fs=require("node:fs"),path=require("node:path"),os=require("node:os"),crypto=require("node:crypto");
const DECLARED_INPUTS=Object.freeze({
  primary:"research/ledger/processing-output-fields.csv",
  supplemental:"research/ledger/supplemental-output-fields.csv",
  midnightCandidate:"research/proposed/itemdb-midnight-milling-candidate.json",
  gameData:"GameData.lua",
  statYield:"StatYieldProfiles.lua",
  curatedAdditions:"research/proposed/itemdb-curated-additions.json",
  rankAudit:"research/coordination/submissions/loot-liquidator-dragonflight/2026-10-28-1231-dragonflight-batch012-40key-field-audit.jsonl",
  midnightAudit:"research/coordination/submissions/loot-liquidator-midnight/2026-10-28-1211-midnight-batch012-35key-field-audit.csv",
  batch014Dragonflight:"research/coordination/submissions/loot-liquidator-dragonflight/2026-10-28-1432-dragonflight-q16-batch014-40key-fourfield-audit.jsonl",
  batch014TWW:"research/coordination/submissions/loot-liquidator-war-within/2026-10-28-2116-warwithin-batch014-q16-35key-fourfield-audit.jsonl",
  tooltipFallbacks:"research/proposed/itemdb-tooltip-fallbacks-q25.json"
});
// These three direct compiler inputs were not recorded in the older source SHA
// manifest. Pin their immutable historical blobs without editing raw evidence.
const LEGACY_INPUT_PINS=Object.freeze({
  "research/coordination/submissions/loot-liquidator-dragonflight/2026-10-28-1328-dragonflight-batch013-40key-field-audit.jsonl":"c98256cca6d66c1e7ad9150694367b0e12fa1a1b",
  "research/coordination/submissions/loot-liquidator-war-within/2026-10-28-1321-warwithin-batch013-35key-field-audit.jsonl":"7bef38d9a4612782a3d48887b35c7b9c170e5cec",
  "research/coordination/submissions/loot-liquidator-legacy/2026-10-28-1340-legacy-batch013-40key-field-audit.jsonl":"17623c171026fee53fc723b8c9d383453f74c869"
});
function gitBlobSHA(bytes){
  return crypto.createHash("sha1").update("blob "+bytes.length+"\0").update(bytes).digest("hex");
}
function verifySourcePins(root,options={}){
  const declared=options.declaredInputs||DECLARED_INPUTS;
  const fixed=options.legacyPins||LEGACY_INPUT_PINS;
  const manifestPath=options.manifestPath||"research/proposed/itemdb-compiler-source-shas.json";
  const manifest=JSON.parse(fs.readFileSync(path.join(root,manifestPath),"utf8"));
  const expected=new Map();
  for(const [key,relative] of Object.entries(declared)){
    if(typeof relative!=="string"||!relative||expected.has(relative))
      throw Error("F002_SOURCE_PIN_INVALID_PATH:"+key);
    expected.set(relative,{key,sha:manifest[key]});
  }
  for(const [relative,sha] of Object.entries(fixed)){
    if(expected.has(relative))throw Error("F002_SOURCE_PIN_DUPLICATE_PATH:"+relative);
    expected.set(relative,{key:relative,sha});
  }
  for(const [relative,pin] of expected){
    if(typeof pin.sha!=="string"||!/^[a-f0-9]{40}$/.test(pin.sha))
      throw Error("F002_SOURCE_PIN_MISSING_OR_INVALID:"+pin.key);
    let bytes;
    try{bytes=fs.readFileSync(path.join(root,relative));}
    catch(error){throw Error("F002_SOURCE_PIN_INPUT_UNREADABLE:"+relative+":"+error.code);}
    const actual=gitBlobSHA(bytes);
    if(actual!==pin.sha)
      throw Error("F002_SOURCE_PIN_STALE_OR_TAMPERED:"+relative+":expected="+pin.sha+":actual="+actual);
  }
  // The legacy 'mechanics' manifest entry is a reference, not a file
  // currently loaded by this compiler; do not claim to have verified it.
  return {verifiedDirectInputs:expected.size,declared:Object.keys(declared).length,
    legacy:Object.keys(fixed).length,mechanicsReferenceNotLoaded:true};
}
function selfTest(){
  const assert=require("node:assert/strict");
  const dir=fs.mkdtempSync(path.join(os.tmpdir(),"ll-f002-source-pins-"));
  const manifestPath="pins.json",a="a.csv",b="b.jsonl";
  const write=(name,value)=>fs.writeFileSync(path.join(dir,name),value);
  const declared={primary:a},fixed={[b]:gitBlobSHA(Buffer.from("original-b"))};
  const check=()=>verifySourcePins(dir,{declaredInputs:declared,legacyPins:fixed,manifestPath});
  let passed=0;
  try{
    write(a,"original-a");write(b,"original-b");
    write(manifestPath,JSON.stringify({primary:gitBlobSHA(Buffer.from("original-a"))}));
    assert.equal(check().verifiedDirectInputs,2);passed++;
    write(a,"tampered-a");assert.throws(check,/F002_SOURCE_PIN_STALE_OR_TAMPERED:a.csv/);passed++;
    write(a,"original-a");write(b,"tampered-b");
    assert.throws(check,/F002_SOURCE_PIN_STALE_OR_TAMPERED:b.jsonl/);passed++;
    write(b,"original-b");write(manifestPath,JSON.stringify({primary:"0".repeat(40)}));
    assert.throws(check,/F002_SOURCE_PIN_STALE_OR_TAMPERED:a.csv/);passed++;
    write(manifestPath,JSON.stringify({primary:"invalid"}));
    assert.throws(check,/F002_SOURCE_PIN_MISSING_OR_INVALID:primary/);passed++;
    write(manifestPath,"{}");
    assert.throws(check,/F002_SOURCE_PIN_MISSING_OR_INVALID:primary/);passed++;
    write(manifestPath,JSON.stringify({primary:gitBlobSHA(Buffer.from("original-a"))}));
    fs.rmSync(path.join(dir,b));assert.throws(check,/F002_SOURCE_PIN_INPUT_UNREADABLE:b.jsonl/);passed++;
    assert.throws(()=>verifySourcePins(dir,{declaredInputs:{primary:a},legacyPins:{[a]:"0".repeat(40)},manifestPath}),
      /F002_SOURCE_PIN_DUPLICATE_PATH:a.csv/);passed++;
    return {passed,failed:0};
  }finally{fs.rmSync(dir,{recursive:true,force:true});}
}
module.exports={gitBlobSHA,verifySourcePins,selfTest,DECLARED_INPUTS,LEGACY_INPUT_PINS};
if(require.main===module){
  try{const result=selfTest();console.log("PASS: F002 source blob pin adversarial tests "+result.passed+"/"+result.passed);}
  catch(error){console.error(error);process.exitCode=1;}
}
