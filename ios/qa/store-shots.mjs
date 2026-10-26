// Builds the App Store screenshots for TOXCARD 1.1 (1206x2622, iPhone 6.3" display).
// Runs the shipping bundle (ios/www) behind the simulated native bridge, captures six screens at
// 3x, and sets each in a captioned frame. Reference content only; no patient data.
// Usage: node ios/qa/store-shots.mjs   -> ios/store/screenshots/*.png
import { chromium } from 'playwright';
import path from 'path'; import fs from 'fs';
import { serve, bridge, chromePath } from './bridge.mjs';
const OUT = path.resolve(path.dirname(new URL(import.meta.url).pathname), '../store/screenshots');
fs.rmSync(OUT, {recursive: true, force: true}); fs.mkdirSync(OUT, {recursive: true});
const {srv, url} = serve();
const b = await chromium.launch(chromePath() ? {executablePath: chromePath()} : {});
const CN = '039-cyanide-smoke-inhalation-hcn-nitroprusside-acetonitrile-apri';
const STATUS = `(() => { document.addEventListener('DOMContentLoaded', () => {
  const s = document.createElement('style');
  s.textContent = ':root{--sat:54px;--sab:30px}#nToast,.n-bubble{display:none!important}#sbar{position:fixed;left:0;right:0;top:0;height:54px;z-index:999;display:flex;justify-content:space-between;align-items:center;padding:6px 34px 0 46px;font:600 17px/1 Inter,system-ui;color:var(--ink);pointer-events:none}#sbar i{display:inline-block;margin-left:6px;vertical-align:middle}';
  document.head.appendChild(s);
  const d = document.createElement('div'); d.id = 'sbar';
  d.innerHTML = '<span>9:41</span><span><i style="width:18px;height:11px;background:linear-gradient(90deg,currentColor 0 3px,transparent 3px 5px,currentColor 5px 8px,transparent 8px 10px,currentColor 10px 13px,transparent 13px 15px,currentColor 15px);clip-path:polygon(0 100%,100% 0,100% 100%)"></i><i style="width:25px;height:12px;border:1.5px solid currentColor;border-radius:4px;opacity:.9;position:relative"><b style="position:absolute;inset:1.5px;background:currentColor;border-radius:1.5px"></b></i></span>';
  document.body.appendChild(d); }); })();`;
async function capture(theme) {
  const ctx = await b.newContext({viewport: {width: 402, height: 874}, deviceScaleFactor: 3, hasTouch: true, isMobile: true,
    colorScheme: theme});
  const p = await ctx.newPage();
  await p.addInitScript(bridge());
  await p.addInitScript(() => { try { localStorage.setItem('tc.seen', 'true'); } catch (e) {} });
  await p.addInitScript(STATUS);
  await p.goto(url); await p.waitForTimeout(1700);
  return {ctx, p};
}
const shot = p => p.screenshot({type: 'png'});
const raw = {};
{ const {ctx, p} = await capture('light');
  raw.home = await shot(p);
  await p.evaluate(id => push('toxin', id), CN); await p.waitForTimeout(300);
  await p.evaluate(() => { const el = document.getElementById('sec-ag'); const v = document.getElementById('view'); v.scrollTop = el.offsetTop - 160; });
  await p.waitForTimeout(300); raw.card = await shot(p);
  await p.evaluate(() => { pop(); go('agents'); }); await p.waitForTimeout(200);
  await p.evaluate(() => push('agent', 'hydroxocobalamin')); await p.waitForTimeout(300); raw.agent = await shot(p);
  await p.evaluate(() => { pop(); go('toxidromes'); }); await p.click('[data-ntxd="anticholinergic"]'); await p.waitForTimeout(400);
  await p.evaluate(() => { document.getElementById('view').scrollTop = 80; }); await p.waitForTimeout(200); raw.triage = await shot(p);
  await p.evaluate(() => go('home')); await p.waitForTimeout(150); await p.click('#nGear'); await p.waitForTimeout(500);
  await p.evaluate(() => { const s = document.getElementById('nSheet'); const h = [...s.querySelectorAll('.n-sh')].find(x => /Siri/.test(x.textContent)); s.scrollTop = h.offsetTop - 120; });
  await p.waitForTimeout(200); raw.siri = await shot(p);
  await ctx.close(); }
{ const {ctx, p} = await capture('dark');
  await p.evaluate(() => { favs = ['039-cyanide-smoke-inhalation-hcn-nitroprusside-acetonitrile-apri', '047-nerve-agents-sarin-soman-tabun-vx-novichok-class',
      '001-acetaminophen-paracetamol', 'button-battery-ingestion', '041-carbon-monoxide'];
    store.set('favs', favs); q = 'organophos'; go('home'); q = 'organophos'; paint(); });
  await p.waitForTimeout(300); raw.search = await shot(p);
  await ctx.close(); }

const frames = [
  ['home', 'One card per poison', `Agent, dose and pitfall for 187 toxins. Offline from the first launch.`, 'light'],
  ['card', 'The pitfall shares the screen with the dose', 'Tier, time-critical window and sources on every card', 'light'],
  ['agent', 'Every antidote, and what it treats', '79 agents, with brand names, linked both ways', 'light'],
  ['triage', 'No history? Start from the pattern', 'Eight toxidromes, each with the finding that tells it apart', 'light'],
  ['siri', 'In iPhone Search and Siri', '“Look up an antidote in TOXCARD”', 'light'],
  ['search', 'Search by toxin, agent or brand', 'Toxins, antidotes, brands and toxidromes. Dark mode included.', 'dark']];
const fp = await b.newPage({viewport: {width: 1206, height: 2622}});
let i = 0;
for (const [k, title, sub, mode] of frames) {
  i++;
  const img = 'data:image/png;base64,' + raw[k].toString('base64');
  const bg = mode === 'dark' ? 'linear-gradient(180deg,#101413 0%,#050606 100%)' : 'linear-gradient(180deg,#0B6B4B 0%,#05392A 100%)';
  await fp.setContent(`<html><body style="margin:0;width:1206px;height:2622px;overflow:hidden;background:${bg};font-family:Inter,system-ui,sans-serif;position:relative">
  <div style="position:absolute;left:96px;right:96px;top:150px;color:#F4F7F5">
    <div style="font:600 34px/1 ui-monospace,'DejaVu Sans Mono',monospace;letter-spacing:.32em;color:${mode === 'dark' ? '#3FD39A' : '#9FE5C6'};margin-bottom:40px">TOXCARD</div>
    <div style="font-size:92px;font-weight:800;letter-spacing:-2.5px;line-height:1.04">${title}</div>
    <div style="font-size:44px;line-height:1.3;margin-top:30px;color:rgba(244,247,245,.78)">${sub}</div></div>
  <div style="position:absolute;left:153px;top:680px;width:900px;height:1910px;border-radius:118px;background:#0B0D0D;padding:20px;box-sizing:border-box;box-shadow:0 40px 120px rgba(0,0,0,.45),0 0 0 3px rgba(255,255,255,.10)">
    <img src="${img}" style="width:860px;height:1870px;border-radius:98px;display:block;object-fit:cover;object-position:top"></div>
  </body></html>`);
  await fp.waitForTimeout(250);
  await fp.screenshot({path: path.join(OUT, `${i}-${k}.png`)});
}
await b.close(); srv.close();
console.log('wrote', fs.readdirSync(OUT).join(' '));
