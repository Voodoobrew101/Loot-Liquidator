'use strict';
// Copy only lossless JSON data. Reject values JSON.stringify would omit, coerce,
// or execute; context identity must describe the exact detached snapshot.
function snapshotJSON(value, ancestors = new Set()) {
 if (value === null || typeof value === 'string' || typeof value === 'boolean') return value;
 if (typeof value === 'number' && Number.isFinite(value)) return value;
 if (typeof value !== 'object' || ancestors.has(value)) throw Error('UNSAFE_JSON_CONTEXT');
 const array = Array.isArray(value), proto = Object.getPrototypeOf(value);
 if (array ? proto !== Array.prototype : proto !== Object.prototype && proto !== null)
  throw Error('UNSAFE_JSON_CONTEXT_PROTOTYPE');
 const keys = Reflect.ownKeys(value);
 if (array && keys.length !== value.length + 1) throw Error('LOSSY_JSON_ARRAY');
 const result = array ? [] : {};
 ancestors.add(value);
 try {
  for (const key of keys) {
   if (array && key === 'length') continue;
   const descriptor = Object.getOwnPropertyDescriptor(value, key);
   if (typeof key !== 'string' || !descriptor.enumerable || !Object.hasOwn(descriptor, 'value') ||
       (array && (!/^(0|[1-9][0-9]*)$/.test(key) || Number(key) >= value.length)))
    throw Error('LOSSY_JSON_CONTEXT_PROPERTY');
   Object.defineProperty(result, key, {value: snapshotJSON(descriptor.value, ancestors),
    enumerable: true, writable: true, configurable: true});
  }
 } finally { ancestors.delete(value); }
 return result;
}
module.exports = {snapshotJSON};
