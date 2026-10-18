import { test } from 'node:test';
import assert from 'node:assert/strict';
import { blind, pickSample, rng, toCsv, translateAzure } from '../compare_azure.mjs';

const row = (src, o = {}) => ({ src, tr: `[fr] ${src}`, src_lang: 'en', target_lang: 'fr', flagged: false, ...o });

test('pickSample keeps every flagged row plus N random unflagged, no duplicates', () => {
  const rows = [
    row('a', { flagged: true }), row('a', { flagged: true }), // same message exported by two testers
    row('b'), row('c'), row('d'), row('e'),
  ];
  const picked = pickSample(rows, { random: 2, random01: rng(1) });
  assert.equal(picked.filter((r) => r.flagged).length, 1);
  assert.equal(picked.filter((r) => !r.flagged).length, 2);
  assert.equal(new Set(picked.map((r) => r.src)).size, 3);
});

test('translateAzure batches per language pair and lets Azure detect und', async () => {
  const calls = [];
  const fakeFetch = async (url, init) => {
    calls.push({ url, init });
    const body = JSON.parse(init.body);
    return { ok: true, json: async () => body.map((b) => ({ translations: [{ text: `AZ ${b.Text}` }] })) };
  };
  const rows = [row('hi'), row('yo'), row('ok', { src_lang: 'und', target_lang: 'es' })];

  const out = await translateAzure(rows, { key: 'k', region: 'westeurope', fetch: fakeFetch });

  assert.equal(calls.length, 2);
  assert.match(calls[0].url, /api-version=3\.0&to=fr&from=en$/);
  assert.match(calls[1].url, /api-version=3\.0&to=es$/);
  assert.equal(calls[0].init.headers['Ocp-Apim-Subscription-Key'], 'k');
  assert.equal(calls[0].init.headers['Ocp-Apim-Subscription-Region'], 'westeurope');
  assert.deepEqual(out, ['AZ hi', 'AZ yo', 'AZ ok']);
});

test('translateAzure fails loudly on an HTTP error', async () => {
  const fakeFetch = async () => ({ ok: false, status: 401, text: async () => 'bad key' });
  await assert.rejects(translateAzure([row('hi')], { key: 'x', region: 'r', fetch: fakeFetch }), /401.*bad key/);
});

test('blind randomises which column is ML Kit and returns the key separately', () => {
  const rows = [row('a'), row('b'), row('c'), row('d')];
  const azure = ['AZ a', 'AZ b', 'AZ c', 'AZ d'];
  const { sheet, key } = blind(rows, azure, rng(7));
  assert.equal(sheet.length, 4);
  for (const [i, s] of sheet.entries()) {
    const engineA = key[i].a;
    assert.equal(s.a, engineA === 'mlkit' ? rows[i].tr : azure[i]);
    assert.equal(s.b, engineA === 'mlkit' ? azure[i] : rows[i].tr);
    assert.equal('mlkit' in s || 'azure' in s, false);
  }
  assert.equal(new Set(key.map((k) => k.a)).size, 2); // seed 7 mixes both orders
});

test('toCsv quotes commas, quotes and newlines', () => {
  const csv = toCsv([{ id: 1, src: 'Hi, "you"\nthere' }], ['id', 'src']);
  assert.equal(csv, 'id,src\r\n1,"Hi, ""you""\nthere"\r\n');
});
