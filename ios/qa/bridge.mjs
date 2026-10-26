// Simulated Capacitor iOS native bridge for TOXCARD's QA and screenshot scripts.
// The page loads the shipping bundle (ios/www, with capacitor.js); plugin calls travel through
// Capacitor's real registerPlugin -> nativePromise / nativeCallback path and land in these mocks,
// which record every call in window.__calls and model the Swift plugins in ios/native.
import path from 'path'; import fs from 'fs'; import http from 'http';
export const WWW = path.resolve(path.dirname(new URL(import.meta.url).pathname), '../www');
const mime = {'.html':'text/html','.js':'text/javascript','.css':'text/css','.woff2':'font/woff2','.json':'application/json','.svg':'image/svg+xml','.png':'image/png'};
export function serve() {
  const srv = http.createServer((q, r) => {
    const u = decodeURIComponent(q.url.split('?')[0]);
    const f = path.join(WWW, u === '/' ? 'index.html' : u);
    if (!f.startsWith(WWW) || !fs.existsSync(f) || fs.statSync(f).isDirectory()) { r.writeHead(404); return r.end(); }
    r.writeHead(200, {'content-type': mime[path.extname(f)] || 'application/octet-stream'}); fs.createReadStream(f).pipe(r);
  }).listen(0);
  return {srv, url: `http://127.0.0.1:${srv.address().port}/index.html`};
}
export const bridge = (opts = {}) => `(() => {
  const calls = window.__calls = []; const cbs = window.__cbs = {};
  window.__route = ${JSON.stringify(opts.route || '')};
  window.__spotAvailable = ${opts.spotAvailable === false ? 'false' : 'true'};
  const m = (...n) => n.map(x => ({name:x, rtype:'promise'})).concat([{name:'addListener',rtype:'callback'},{name:'removeListener',rtype:'callback'}]);
  const H = [{name:'Launch',methods:m('take')},{name:'Spotlight',methods:m('index','clear','viewing')},
             {name:'QuickActions',methods:m('setEntries')},{name:'NativeUI',methods:m('haptic','appearance','share','printCard')}];
  const h = {
    'Launch.take': () => { const r = window.__route; window.__route = ''; return {route:r}; },
    'Spotlight.index': o => { window.__index = o.items; return {indexed: window.__spotAvailable ? o.items.length : 0, available: window.__spotAvailable}; },
    'Spotlight.clear': () => ({}),
    'Spotlight.viewing': o => { window.__viewing = o; return {}; },
    'QuickActions.setEntries': o => { window.__quick = o.items; return {count:Math.min(2,o.items.length)}; },
    'NativeUI.haptic': o => { (window.__haptics = window.__haptics || []).push(o.style); return {}; },
    'NativeUI.appearance': o => { window.__appearance = o.style; return {}; },
    'NativeUI.share': o => { window.__shared = o; return {completed:true}; },
    'NativeUI.printCard': o => { window.__printed = o; return {completed:true}; }};
  window.__fire = (plugin, ev, data) => (cbs[plugin+'.'+ev] || []).forEach(f => f(data || {}));
  window.webkit = { messageHandlers: { bridge: { postMessage: () => {} } } };
  window.Capacitor = { isNativePlatform: () => true, getPlatform: () => 'ios', platform: 'ios',
    isPluginAvailable: n => H.some(x => x.name === n), PluginHeaders: H, Plugins: {},
    nativeCallback: (p, meth, o, cb) => { calls.push(p+'.'+meth); if (meth === 'addListener') (cbs[p+'.'+o.eventName] = cbs[p+'.'+o.eventName] || []).push(cb); return 'cb'+calls.length; },
    nativePromise: (p, meth, o) => { calls.push(p+'.'+meth); const f = h[p+'.'+meth]; return f ? Promise.resolve(f(o || {})) : Promise.reject(new Error('not implemented')); } };
})();`;
export const chromePath = () => ['/opt/pw-browsers/chromium-1243/chrome-linux/chrome', '/opt/pw-browsers/chromium-1243/chrome-linux64/chrome']
  .find(p => fs.existsSync(p));
