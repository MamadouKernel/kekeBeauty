import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import vm from 'node:vm';

const handlers = {};
const stored = [];
let networkFails = false;
const context = {
  URL, Promise,
  self: { location: { origin: 'https://example.test' }, addEventListener: (event, handler) => handlers[event] = handler },
  caches: {
    open: async () => ({ addAll: async files => stored.push(...files) }),
    match: async path => path === '/offline.html' ? 'offline-page' : undefined
  },
  fetch: async () => { if (networkFails) throw new Error('offline'); return 'network-response'; }
};
vm.runInNewContext(readFileSync(new URL('../src/KekeBeauty.Web/wwwroot/service-worker.js', import.meta.url), 'utf8'), context);
await new Promise(resolve => handlers.install({ waitUntil: task => task.then(resolve) }));
assert.deepEqual(stored, ['/offline.html', '/icon.svg']);
async function request(path, method = 'GET', mode = 'navigate') {
  let response;
  handlers.fetch({ request: { url: `https://example.test${path}`, method, mode }, respondWith: task => response = task });
  return await response;
}
assert.equal(await request('/mes-rendez-vous'), 'network-response');
networkFails = true;
assert.equal(await request('/mes-rendez-vous'), 'offline-page');
assert.equal(await request('/auth/verify', 'POST'), undefined);
assert.equal(await request('/rendez-vous/creer', 'POST'), undefined);
assert.equal(await request('/api/private', 'GET', 'cors'), undefined);
assert.deepEqual(stored, ['/offline.html', '/icon.svg']);
console.log('PWA: cache public uniquement, navigation hors ligne et mutations non interceptees : OK');
