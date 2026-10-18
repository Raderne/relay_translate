import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { loadExports, metrics, percentile, report } from '../beta_metrics.mjs';

const row = (o = {}) => ({
  src: 'Hello', tr: 'Salut', src_lang: 'en', target_lang: 'fr', app_label: 'WhatsApp',
  engine: 'mlkit', ms: 100, flagged: false, note: null, ...o,
});

test('percentile uses nearest rank', () => {
  assert.equal(percentile([100, 200, 300, 400, 500, 600, 700, 800, 900, 1000], 90), 900);
  assert.equal(percentile([5], 90), 5);
  assert.equal(percentile([], 90), null);
});

test('metrics: flag rate, und rate, p90 skips rows without ms', () => {
  const rows = [
    row({ flagged: true, ms: 1200 }),
    row({ src_lang: 'und', ms: null }),
    row({ ms: 300 }),
    row({ target_lang: 'es', ms: 500, app_label: 'Telegram' }),
  ];
  const m = metrics(rows);
  assert.equal(m.total, 4);
  assert.equal(m.flaggedRate, 0.25);
  assert.equal(m.undRate, 0.25);
  assert.equal(m.p90Ms, 1200);
  assert.deepEqual(m.byTarget, { fr: { total: 3, flagged: 1 }, es: { total: 1, flagged: 0 } });
  assert.deepEqual(m.apps, ['Telegram', 'WhatsApp']);
});

test('loadExports reads every .json in a folder and tags the tester by file name', () => {
  const dir = mkdtempSync(join(tmpdir(), 'relay-exports-'));
  writeFileSync(join(dir, 'ana.json'), JSON.stringify([row()]));
  writeFileSync(join(dir, 'ben.json'), JSON.stringify([row(), row({ src: 'brb' })]));
  writeFileSync(join(dir, 'notes.txt'), 'ignored');
  const rows = loadExports([dir]);
  assert.equal(rows.length, 3);
  assert.deepEqual([...new Set(rows.map((r) => r.tester))].sort(), ['ana', 'ben']);
});

test('report marks each Phase 10 target as met or missed', () => {
  const text = report(metrics([row({ flagged: true }), row(), row(), row()]));
  assert.match(text, /Flagged\s+25\.0%\s+< 10%\s+MISSED/);
  assert.match(text, /Detection failures \(und\)\s+0\.0%\s+< 5%\s+met/);
  assert.match(text, /Latency p90\s+100 ms\s+< 1000 ms\s+met/);
});
