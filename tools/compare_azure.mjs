#!/usr/bin/env node
// Phase 10 blind A/B: ML Kit (from testers' exports) vs Azure Translator. Team-only, not shipped.
//   node --env-file=tools/.env tools/compare_azure.mjs exports/ --sample 50 --out comparison.csv
// Writes comparison.csv (id, target, src, a, b — engines hidden) and comparison.key.csv (id → engine of a).
// Sends message text to Azure: only run it on exports testers agreed to share.
import { writeFileSync } from 'node:fs';
import { pathToFileURL } from 'node:url';
import { loadExports } from './beta_metrics.mjs';

const DEFAULT_ENDPOINT = 'https://api.cognitive.microsofttranslator.com';
const BATCH = 100; // Azure: max 100 texts per request

/** Seeded PRNG (mulberry32) so a sample can be reproduced. */
export function rng(seed) {
  let a = seed >>> 0;
  return () => {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

function shuffle(list, random01) {
  const out = [...list];
  for (let i = out.length - 1; i > 0; i--) {
    const j = Math.floor(random01() * (i + 1));
    [out[i], out[j]] = [out[j], out[i]];
  }
  return out;
}

/** Every flagged message plus [random] unflagged ones; one row per (target, src). */
export function pickSample(rows, { random, random01 }) {
  const seen = new Set();
  const unique = rows.filter((r) => {
    const k = `${r.target_lang}\n${r.src}`;
    if (seen.has(k)) return false;
    seen.add(k);
    return true;
  });
  const flagged = unique.filter((r) => r.flagged);
  const others = shuffle(unique.filter((r) => !r.flagged), random01).slice(0, random);
  return [...flagged, ...others];
}

/** Azure translations for [rows], same order. `und` sources are left for Azure to detect. */
export async function translateAzure(rows, { key, region, endpoint = DEFAULT_ENDPOINT, fetch = globalThis.fetch }) {
  const groups = new Map(); // "from|to" → row indexes
  rows.forEach((r, i) => {
    const g = `${r.src_lang}|${r.target_lang}`;
    if (!groups.has(g)) groups.set(g, []);
    groups.get(g).push(i);
  });
  const out = new Array(rows.length);
  for (const [g, indexes] of groups) {
    const [from, to] = g.split('|');
    const query = `api-version=3.0&to=${to}${from === 'und' ? '' : `&from=${from}`}`;
    for (let s = 0; s < indexes.length; s += BATCH) {
      const chunk = indexes.slice(s, s + BATCH);
      const res = await fetch(`${endpoint}/translate?${query}`, {
        method: 'POST',
        headers: {
          'Ocp-Apim-Subscription-Key': key,
          'Ocp-Apim-Subscription-Region': region,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(chunk.map((i) => ({ Text: rows[i].src }))),
      });
      if (!res.ok) throw new Error(`Azure ${res.status}: ${await res.text()}`);
      const data = await res.json();
      chunk.forEach((i, k) => (out[i] = data[k].translations[0].text));
    }
  }
  return out;
}

/** Hides which column is which engine; the key goes in a separate file for after the review. */
export function blind(rows, azure, random01) {
  const sheet = [];
  const key = [];
  rows.forEach((r, i) => {
    const mlkitFirst = random01() < 0.5;
    const id = i + 1;
    sheet.push({
      id,
      target: r.target_lang,
      src: r.src,
      a: mlkitFirst ? r.tr : azure[i],
      b: mlkitFirst ? azure[i] : r.tr,
    });
    key.push({ id, a: mlkitFirst ? 'mlkit' : 'azure', flagged: Boolean(r.flagged), note: r.note ?? '' });
  });
  return { sheet, key };
}

export function toCsv(rows, columns) {
  const cell = (v) => {
    const s = v === null || v === undefined ? '' : String(v);
    return /[",\r\n]/.test(s) ? `"${s.replaceAll('"', '""')}"` : s;
  };
  return [columns.join(','), ...rows.map((r) => columns.map((c) => cell(r[c])).join(','))].join('\r\n') + '\r\n';
}

function arg(argv, name, fallback) {
  const i = argv.indexOf(name);
  return i === -1 ? fallback : argv[i + 1];
}

if (import.meta.url === pathToFileURL(process.argv[1]).href) {
  const argv = process.argv.slice(2);
  const key = process.env.AZURE_TRANSLATOR_KEY;
  const region = process.env.AZURE_TRANSLATOR_REGION;
  const paths = argv.filter((a, i) => !a.startsWith('--') && !argv[i - 1]?.startsWith('--'));
  if (!key || !region || paths.length === 0) {
    console.error('usage: node --env-file=tools/.env tools/compare_azure.mjs <exports> [--sample 50] [--seed 1] [--out comparison.csv]');
    console.error('needs AZURE_TRANSLATOR_KEY and AZURE_TRANSLATOR_REGION (see tools/.env.example)');
    process.exit(2);
  }
  const random01 = rng(Number(arg(argv, '--seed', '1')));
  const out = arg(argv, '--out', 'comparison.csv');
  const sample = pickSample(loadExports(paths), { random: Number(arg(argv, '--sample', '50')), random01 });
  const azure = await translateAzure(sample, { key, region, endpoint: process.env.AZURE_TRANSLATOR_ENDPOINT });
  const { sheet, key: answers } = blind(sample, azure, random01);
  writeFileSync(out, toCsv(sheet, ['id', 'target', 'src', 'a', 'b']));
  writeFileSync(out.replace(/\.csv$/, '') + '.key.csv', toCsv(answers, ['id', 'a', 'flagged', 'note']));
  console.log(`${sheet.length} rows → ${out} (+ key file). Review a/b blind, then open the key.`);
}
