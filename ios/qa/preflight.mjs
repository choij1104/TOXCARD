// Pre-upload check for the TOXCARD App Store bundle (ios/www). Run after `npm run build:www`.
// Loads the shipping bundle behind a simulated Capacitor iOS bridge (qa/bridge.mjs) and runs every
// user flow of the iOS layer and every native entry point. Exit code 1 on any failure.
// Usage: node ios/qa/preflight.mjs [runs]
import { chromium } from 'playwright';
import fs from 'fs'; import path from 'path';
import { serve, bridge, WWW, chromePath } from './bridge.mjs';
const RUNS = +(process.argv[2] || 3);
const fails = []; let run = 0;
const check = (cond, msg) => { if (!cond) fails.push(`run ${run}: ${msg}`); };

// ---- static checks on the bundle ----------------------------------------------------------
const html = fs.readFileSync(path.join(WWW, 'index.html'), 'utf8');
const native = fs.readFileSync(path.join(WWW, 'native.js'), 'utf8');
const web = fs.readFileSync(path.resolve(WWW, '../../index.html'), 'utf8');
check(/^<meta name="toxcard-build" content="reference">/m.test(html), 'reference flag missing');
for (const f of [html, native]) check(!/\bfetch\(|XMLHttpRequest|sendBeacon|WebSocket|serviceWorker\.register/.test(f), 'network call in bundle');
check(!/(src|href)="https?:\/\//.test(html), 'external resource in index.html');
for (const n of ['TOXINS', 'AGENTS', 'PROTOCOLS', 'TOXIDROMES', 'VERSION']) {
  const re = new RegExp(`^const ${n}=.*$`, 'm');
  check(html.match(re)?.[0] === web.match(re)?.[0], `${n} differs from the web build`);
}

const {srv, url} = serve();
const browser = await chromium.launch(chromePath() ? {executablePath: chromePath()} : {});
const CN = '039-cyanide-smoke-inhalation-hcn-nitroprusside-acetonitrile-apri';

for (run = 1; run <= RUNS; run++) { try {
  const ctx = await browser.newContext({viewport: {width: 402, height: 874}, hasTouch: true, isMobile: true, deviceScaleFactor: 2});
  const p = await ctx.newPage(); const errs = []; const external = [];
  p.on('pageerror', e => errs.push(e.message));
  p.on('console', m => { if (m.type() === 'error') errs.push(m.text()); });
  p.on('request', r => { if (!r.url().startsWith('http://127.0.0.1') && !r.url().startsWith('data:')) external.push(r.url()); });
  await p.addInitScript(bridge({route: run === 2 ? 'open:toxin:' + CN : ''}));
  await p.goto(url); await p.waitForTimeout(500);

  // first launch
  check(await p.evaluate(() => typeof Capacitor.registerPlugin === 'function'), 'capacitor.js not loaded');
  check(await p.evaluate(() => !!window.TOXCARD_NATIVE && TOXCARD_NATIVE.native), 'iOS layer not active');
  if (run !== 2) {
    await p.waitForTimeout(900);
    check(await p.isVisible('#nStart'), 'welcome not shown on first launch');
    await p.click('#nStart'); await p.waitForTimeout(400);
    check(!(await p.$('#welcome')), 'welcome not dismissed');
  } else {
    // cold launch from a Spotlight result: route waiting in Launch.take()
    await p.waitForTimeout(300);
    check(await p.evaluate(id => stack.length === 1 && stack[0].id === id && !!document.querySelector('.n-detail'), CN), 'cold-launch Spotlight route did not open the card');
    check(!(await p.$('#welcome')), 'welcome left over a routed launch');
    await p.click('#bk'); await p.waitForTimeout(200);
  }
  await p.waitForTimeout(1300);

  // Spotlight index: every toxin and agent, unique ids
  const idx = await p.evaluate(() => window.__index || []);
  const tc = await p.evaluate(() => [TOXINS.length, AGENTS.length]);
  check(idx.length === tc[0] + tc[1], `Spotlight index has ${idx.length} items, expected ${tc[0] + tc[1]}`);
  check(new Set(idx.map(i => i.kind + ':' + i.id)).size === idx.length, 'Spotlight ids not unique');
  check(idx.every(i => i.title && (i.kind === 'toxin' || i.kind === 'agent')), 'Spotlight item without title/kind');
  check(idx.some(i => i.kind === 'agent' && i.keywords.includes('Cyanokit')), 'brand names not in Spotlight keywords');
  check(await p.evaluate(() => window.__appearance) !== undefined, 'appearance not sent to native');

  // home: four tabs, large title, A-Z sections, index, time-critical strip
  check(await p.locator('#tabs button').count() === 4, 'tab bar not four tabs');
  check(await p.isVisible('.n-lt h1'), 'large title missing');
  check(await p.locator('.n-uc').count() === 5, 'time-critical strip not five cards');
  check(await p.locator('#nResults .n-row[data-tox]').count() === tc[0], 'A-Z list does not show every toxin');
  await p.click('#nIndex [data-ix="M"]'); await p.waitForTimeout(200);
  check(await p.evaluate(() => { const el = $('ix-M'), v = $('view'); const y = el.offsetTop - v.scrollTop; return y > 30 && y < 120; }), 'section index did not jump to M');
  check((await p.evaluate(() => window.__haptics || [])).includes('selection'), 'no haptic on index');
  await p.click('[data-browse="cat"]'); await p.waitForTimeout(150);
  check(await p.locator('.n-chips button').count() > 10, 'category filter missing');
  await p.click('.n-chips button:nth-child(3)'); await p.waitForTimeout(150);
  const one = await p.evaluate(() => cat);
  check(one !== 'All' && await p.evaluate(c => [...document.querySelectorAll('#nResults .n-row[data-tox]')].every(b => T[b.dataset.tox].category === c), one), 'category filter wrong');
  await p.click('[data-cat="All"]'); await p.click('[data-browse="az"]');

  // search keeps focus while typing, scopes narrow it
  await p.click('#hq'); await p.keyboard.type('cyanokit', {delay: 15});
  check(await p.evaluate(() => document.activeElement && document.activeElement.id === 'hq'), 'search lost focus while typing');
  check(await p.locator('#nResults [data-agent="hydroxocobalamin"]').count() === 1, 'brand search did not find hydroxocobalamin');
  await p.click('[data-scope="Toxins"]'); await p.waitForTimeout(100);
  check(await p.locator('#nResults [data-agent]').count() === 0, 'Toxins scope still shows agents');
  await p.click('[data-scope="All"]');
  await p.fill('#hq', 'zzzqqq'); await p.dispatchEvent('#hq', 'input'); await p.waitForTimeout(100);
  check(await p.isVisible('#nResults .n-empty'), 'no empty state for no match');
  await p.click('#cq'); await p.waitForTimeout(100);
  check(await p.evaluate(() => q === '' && !!$('nIndex')), 'clear search did not restore the list');

  // toxin card: clinical content is the web build's viewToxin output, unchanged
  const ids = await p.evaluate(() => TOXINS.map(t => t.id));
  const sample = [CN, ...ids.filter((_, i) => i % Math.max(1, Math.floor(ids.length / 12)) === run % 7)].slice(0, 14);
  for (const id of sample) {
    const ok = await p.evaluate(async id => { push('toxin', id); await new Promise(r => setTimeout(r, 20)); const d = document.querySelector('.n-detail'); if (!d) return 'no card';
      const ref = document.createElement('div'); ref.innerHTML = viewToxin(id);
      if (d.textContent.replace(/\s+/g, ' ') !== ref.textContent.replace(/\s+/g, ' ')) return 'text differs';
      const pr = P[id] || {}; const txt = d.textContent;
      if (pr.pitfall && !txt.includes(pr.pitfall)) return 'pitfall missing';
      if (pr.agentLine && !txt.includes(pr.agentLine)) return 'agent missing';
      if (/Computed at|Dose Calculator|Weight and height/.test(document.querySelector('.app').innerText) || document.getElementById('wt') || document.querySelector('.calc')) return 'dose computation visible';
      if (!window.__viewing || window.__viewing.id !== id) return 'Siri Suggestion activity not set';
      pop(); return 'ok'; }, id);
    check(ok === 'ok', `card ${id}: ${ok}`);
  }
  // pin, share, print, copy, jump, back
  await p.evaluate(id => push('toxin', id), CN); await p.waitForTimeout(150);
  await p.click('#fav'); await p.waitForTimeout(100);
  check(await p.evaluate(id => favs.includes(id) && $('fav').getAttribute('aria-pressed') === 'true', CN), 'pin did not save');
  check(await p.evaluate(id => (window.__quick || []).some(q => q.route === 'open:toxin:' + id && q.icon === 'saved'), CN), 'quick action not set for pinned card');
  await p.click('#shr'); await p.waitForTimeout(100);
  check(await p.evaluate(id => window.__shared && window.__shared.text.includes(P[id].pitfall) && window.__shared.text.includes(P[id].dose), CN), 'share text lacks dose or pitfall');
  await p.click('#more'); await p.waitForTimeout(350);
  check(await p.isVisible('#nActions'), 'action sheet not shown');
  await p.click('#nActions [data-ai="1"]'); await p.waitForTimeout(150);
  check(await p.evaluate(id => window.__printed && window.__printed.html.includes(P[id].pitfall.slice(0, 40).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')), CN), 'print card lacks pitfall');
  await p.click('#more'); await p.waitForTimeout(350); await p.click('#nActions [data-ai="3"]'); await p.waitForTimeout(700);
  check(await p.evaluate(() => { const el = $('sec-pf'), v = $('view'); const y = el.getBoundingClientRect().top; return v.scrollTop > 0 && y > 60 && y < 200; }), 'jump to pitfall did not land below the bars');
  await p.click('.n-detail [data-agent]'); await p.waitForTimeout(150);
  check(await p.evaluate(() => stack.length === 2 && stack[1].kind === 'agent' && !!document.querySelector('.n-ahero')), 'agent from card did not open');
  check(await p.evaluate(() => $('bk').textContent.trim() === 'Cyanide'), 'back label is not the previous card');
  await p.click('#bk'); await p.click('#bk'); await p.waitForTimeout(150);
  check(await p.evaluate(() => stack.length === 0 && tab === 'home'), 'back did not return home');

  // antidotes tab
  await p.click('#tabs [data-tab="agents"]'); await p.waitForTimeout(150);
  check(await p.locator('#nResults [data-agent]').count() === tc[1], 'antidote list incomplete');
  await p.fill('#aq', 'naloxone'); await p.dispatchEvent('#aq', 'input'); await p.waitForTimeout(100);
  check(await p.locator('#nResults [data-agent]').count() >= 1, 'antidote search found nothing for naloxone');
  await p.click('#nResults [data-agent] >> nth=0'); await p.waitForTimeout(150);
  check(await p.locator('.n-adetail [data-tox]').count() >= 1, 'antidote detail lists no toxins');
  await p.click('#bk');

  // triage tab: expand, then a cause chip searches the dataset
  await p.click('#tabs [data-tab="toxidromes"]'); await p.waitForTimeout(150);
  check(await p.locator('[data-ntxd]').count() === 8, 'triage not eight toxidromes');
  await p.click('[data-ntxd="cholinergic"]'); await p.waitForTimeout(200);
  check(await p.isVisible('#tx-cholinergic .txd'), 'toxidrome did not expand');
  const chip = await p.$('#tx-cholinergic [data-find]');
  if (chip) { await chip.click(); await p.waitForTimeout(150); check(await p.evaluate(() => tab === 'home' && q.length > 0), 'cause chip did not search'); }

  // pinned tab
  await p.click('#tabs [data-tab="saved"]'); await p.waitForTimeout(150);
  check(await p.locator('#nResults [data-tox], .n-saved .n-row[data-tox]').count() >= 1, 'pinned card not listed');
  await p.click('[data-nseg="recent"]'); await p.waitForTimeout(100);
  check(await p.locator('.n-saved .n-row[data-tox]').count() >= 1, 'recent list empty');

  // settings: theme to native, rebuild index
  await p.click('#nGear'); await p.waitForTimeout(400);
  check(await p.isVisible('#nSheet'), 'settings sheet not shown');
  check(await p.evaluate(() => /does not compute weight-based doses/.test($('nSheet').textContent)), 'reference-dose note missing in settings');
  await p.click('[data-thm="dark"]'); await p.waitForTimeout(100);
  check(await p.evaluate(() => document.documentElement.getAttribute('data-theme') === 'dark' && window.__appearance === 'dark'), 'dark theme not applied natively');
  await p.click('[data-thm="system"]');
  await p.evaluate(() => { window.__index = null; }); await p.click('#nReindex'); await p.waitForTimeout(300);
  check(await p.evaluate(() => (window.__index || []).length > 200), 'rebuild index did not re-index');
  await p.click('#nDone'); await p.waitForTimeout(350);

  // routes from Siri / quick actions while running (route event)
  const routes = [['open:agent:hydroxocobalamin', () => stack.length === 1 && stack[0].kind === 'agent'],
    ['search:digoxin', () => tab === 'home' && q === 'digoxin' && document.querySelectorAll('#nResults [data-tox]').length > 0],
    ['tab:triage', () => tab === 'toxidromes'], ['tab:agents', () => tab === 'agents'], ['tab:saved', () => tab === 'saved'],
    ['tab:search', () => tab === 'home' && document.activeElement && document.activeElement.id === 'hq'],
    ['open:toxin:' + CN, () => stack.length === 1 && stack[0].id === '039-cyanide-smoke-inhalation-hcn-nitroprusside-acetonitrile-apri'],
    ['open:toxin:does-not-exist', () => true]];
  for (const [r, okFn] of routes) {
    await p.evaluate(r => { window.__route = r; window.__fire('Launch', 'route', {}); }, r); await p.waitForTimeout(200);
    check(await p.evaluate(okFn), `route ${r} not handled`);
  }

  // persistence across relaunch
  await p.reload(); await p.waitForTimeout(1500);
  check(await p.evaluate(id => { const w = document.getElementById('welcome'); return favs.includes(id) && (!w || w.hidden); }, CN), 'pins or first-run state lost after relaunch');

  check(external.length === 0, 'network requests: ' + external.slice(0, 3).join(' '));
  check(errs.length === 0, 'page errors: ' + errs.join(' | '));
  await ctx.close();
} catch (e) { fails.push(`run ${run}: ${e.message.split('\n')[0]}`); }
  process.stdout.write(fails.length ? 'x' : '.');
}
// browser without the native bridge (e.g. a desk check): the layer must still work
{ run = 'web'; const ctx = await browser.newContext({viewport: {width: 402, height: 874}}); const p = await ctx.newPage(); const errs = [];
  p.on('pageerror', e => errs.push(e.message)); await p.goto(url); await p.waitForTimeout(1500);
  await p.evaluate(() => { const w = $('welcome'); if (w) w.remove(); push('toxin', TOXINS[0].id); });
  check(await p.isVisible('.n-detail'), 'no-bridge: card did not open');
  check(errs.length === 0, 'no-bridge page errors: ' + errs.join(' | ')); await ctx.close(); }
await browser.close(); srv.close();
console.log(`\n${RUNS} runs · ${fails.length ? fails.length + ' FAILURES' : 'all passed'}`);
if (fails.length) { console.log([...new Set(fails)].slice(0, 30).join('\n')); process.exit(1); }
