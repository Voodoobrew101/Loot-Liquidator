'use strict';
const assert=require('node:assert/strict');
const {snapshotJSON}=require('../tools/models_v2/json_context_snapshot.js');
const input={profile:{nodes:[1,{rank:2},null]},zero:0,flag:false};
const output=snapshotJSON(input);
assert.deepEqual(output,input);
input.profile.nodes[1].rank=9;
assert.equal(output.profile.nodes[1].rank,2);
assert.equal(JSON.stringify(output),JSON.stringify(snapshotJSON(output)));
for(const value of [NaN,Infinity,undefined,()=>true,1n,Symbol('x'),new Date(),new Map()])
 assert.throws(()=>snapshotJSON({nested:[value]}));
const cycle={};cycle.self=cycle;assert.throws(()=>snapshotJSON(cycle));
const shared={rank:2};assert.deepEqual(snapshotJSON([shared,shared]),[{rank:2},{rank:2}]);
for(const array of [new Array(2),['x',,],Object.assign(['x'],{extra:1})])
 assert.throws(()=>snapshotJSON(array));
let getterCalls=0;
const getter={};Object.defineProperty(getter,'rank',{enumerable:true,get(){getterCalls++;return 1;}});
assert.throws(()=>snapshotJSON(getter));assert.equal(getterCalls,0);
const protoKey=JSON.parse('{"__proto__":{"rank":2}}');
assert.equal(Object.getPrototypeOf(snapshotJSON(protoKey)),Object.prototype);
assert.equal(Object.hasOwn(snapshotJSON(protoKey),'__proto__'),true);
console.log('PASS: detached JSON context, invalid nested types, cycles, dense arrays, non-executed accessors and literal prototype keys');
