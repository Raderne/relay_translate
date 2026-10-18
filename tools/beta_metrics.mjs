#!/usr/bin/env node
// Phase 10 metrics from testers' "Export beta feedback" files. Team-only, not shipped.
//   node tools/beta_metrics.mjs exports/            (a folder of .json exports, or file paths)
// Survey score and download complaints come from the Google Form, not from here.
import { readdirSync, readFileSync, statSync } from 'node:fs';
import { basename, extname, join } from 'node:path';
import { pathToFileURL } from 'node:url';

/** Rows from every export, each tagged with `tester` (the file name). */
export function loadExports(paths) {
  const files = paths.flatMap((p) =>
    statSync(p).isDirectory()
      ? readdirSync(p).filter((f) => extname(f) === '.json').map((f) => join(p, f))
      : [p],
  );
  return files.flatMap((f) => {
    const tester = basename(f, '.json');
    return JSON.parse(readFileSync(f, 'utf8')).map((r) => ({ ...r, tester }));
  });
}

/** Nearest-rank percentile; null for no data. */
export function percentile(values, p) {
  if (values.length === 0) return null;
  const sorted = [...values].sort((a, b) => a - b);
  return sorted[Math.max(0, Math.ceil((p / 100) * sorted.length) - 1)];
}

export function metrics(rows) {
  const total = rows.length;
  const rate = (n) => (total === 0 ? 0 : n / total);
  const byTarget = {};
  for (const r of rows) {
    const t = (byTarget[r.target_lang] ??= { total: 0, flagged: 0 });
    t.total += 1;
    if (r.flagged) t.flagged += 1;
  }
  return {
    total,
    testers: new Set(rows.map((r) => r.tester).filter(Boolean)).size,
    flaggedRate: rate(rows.filter((r) => r.flagged).length),
    // Only `und` is visible in the export; a confidently wrong language needs the flags/notes.
    undRate: rate(rows.filter((r) => r.src_lang === 'und').length),
    // Rows flagged before their translation was logged have no ms.
    p90Ms: percentile(rows.map((r) => r.ms).filter((ms) => typeof ms === 'number'), 90),
    byTarget,
    apps: [...new Set(rows.map((r) => r.app_label))].sort(),
  };
}

const pct = (x) => `${(x * 100).toFixed(1)}%`;

/** The Phase 10 targets table: value, target, met / MISSED. */
export function report(m) {
  const line = (label, value, target, ok) =>
    `${label.padEnd(26)}${value.padEnd(10)}${target.padEnd(12)}${ok ? 'met' : 'MISSED'}`;
  const lines = [
    `${m.total} translations from ${m.testers} testers · apps: ${m.apps.join(', ')}`,
    '',
    line('Flagged', pct(m.flaggedRate), '< 10%', m.flaggedRate < 0.1),
    line('Detection failures (und)', pct(m.undRate), '< 5%', m.undRate < 0.05),
    line('Latency p90', m.p90Ms === null ? 'n/a' : `${m.p90Ms} ms`, '< 1000 ms', m.p90Ms !== null && m.p90Ms < 1000),
    '',
    'By target language:',
    ...Object.entries(m.byTarget).map(
      ([lang, t]) => `  ${lang}  ${t.total} translations, ${pct(t.total ? t.flagged / t.total : 0)} flagged`,
    ),
  ];
  return lines.join('\n');
}

if (import.meta.url === pathToFileURL(process.argv[1]).href) {
  const paths = process.argv.slice(2);
  if (paths.length === 0) {
    console.error('usage: node tools/beta_metrics.mjs <exports folder or .json files>');
    process.exit(2);
  }
  console.log(report(metrics(loadExports(paths))));
}
