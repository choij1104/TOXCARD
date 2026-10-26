/* TOXCARD for iOS — presentation layer and native bridge of the App Store build.
   Injected after the app script by ios/scripts/build-reference.sh; the web and Android builds
   never load it. It replaces navigation, lists and sheets, and connects the native features in
   ios/native/*.swift: Spotlight, Siri and Shortcuts, Home Screen quick actions, haptics, the
   share sheet and AirPrint.
   Clinical content is not touched here. Every toxin card is rendered by the app's own
   viewToxin(), doses by doseTable(), toxidromes by txdHTML(), from the same embedded data as
   the web build, and REFERENCE_BUILD stays in force: no dose is computed anywhere. */
(function(){
"use strict";
if(typeof paint!=="function"||typeof viewToxin!=="function") return;

/* ---------- native bridge ---------- */
const CAP=window.Capacitor;
const NATIVE=!!(CAP&&typeof CAP.isNativePlatform==="function"&&CAP.isNativePlatform()&&typeof CAP.registerPlugin==="function");
const plug=n=>{try{return NATIVE?CAP.registerPlugin(n):null}catch(e){return null}};
const Launch=plug("Launch"), Spot=plug("Spotlight"), Quick=plug("QuickActions"), UI=plug("NativeUI");
function nat(p,m,o){
  if(!p) return Promise.resolve(null);
  try{return Promise.resolve(p[m](o||{})).catch(()=>null)}catch(e){return Promise.resolve(null)}
}
const haptic=s=>{nat(UI,"haptic",{style:s||"selection"})};

/* ---------- icons (drawn for this build) ---------- */
const NI={
  cards:'<rect x="3.5" y="6.5" width="13" height="14" rx="2.2"/><path d="M7.5 6.5V5.7a2.2 2.2 0 0 1 2.2-2.2h8.6a2.2 2.2 0 0 1 2.2 2.2v10.6a2.2 2.2 0 0 1-2.2 2.2h-1.8"/><path d="M7 11.5h6M7 15h4"/>',
  vial:'<path d="M9 3.5h6"/><path d="M10 3.5v5.6l-4.6 8.2A2.2 2.2 0 0 0 7.3 20.5h9.4a2.2 2.2 0 0 0 1.9-3.2L14 9.1V3.5"/><path class="f" d="M7.6 15h8.8l1.4 2.6a1 1 0 0 1-.9 1.4H7.1a1 1 0 0 1-.9-1.4z"/>',
  pulse:'<path d="M2.5 12.5h4l2-5 3.5 10 2.5-7 1.5 2h5.5"/>',
  pin:'<path d="M12 3.4 14.65 8.77l5.93.86-4.29 4.18 1.01 5.9L12 16.91l-5.3 2.79 1.01-5.9-4.29-4.18 5.93-.86z"/>',
  gear:'<circle cx="12" cy="12" r="3"/><path d="M19.4 13.5a7.6 7.6 0 0 0 0-3l2-1.6-2-3.4-2.4 1a7.6 7.6 0 0 0-2.6-1.5L14 2.5h-4l-.4 2.5A7.6 7.6 0 0 0 7 6.5l-2.4-1-2 3.4 2 1.6a7.6 7.6 0 0 0 0 3l-2 1.6 2 3.4 2.4-1a7.6 7.6 0 0 0 2.6 1.5l.4 2.5h4l.4-2.5a7.6 7.6 0 0 0 2.6-1.5l2.4 1 2-3.4z"/>',
  search:'<circle cx="10.5" cy="10.5" r="6.5"/><path d="m15.5 15.5 5 5"/>',
  chev:'<path d="m9 5 7 7-7 7"/>',
  back:'<path d="m15 4.5-7.5 7.5 7.5 7.5"/>',
  share:'<path d="M12 3.5v11"/><path d="m8 7.3 4-3.8 4 3.8"/><path d="M8.5 10.5H7a2 2 0 0 0-2 2v6a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2v-6a2 2 0 0 0-2-2h-1.5"/>',
  more:'<circle cx="12" cy="12" r="9"/><circle cx="8" cy="12" r=".6" fill="currentColor"/><circle cx="12" cy="12" r=".6" fill="currentColor"/><circle cx="16" cy="12" r=".6" fill="currentColor"/>',
  warn:'<path d="M12 4 21 19.5H3z"/><path d="M12 10v4.4M12 16.9v.1"/>',
  x:'<circle cx="12" cy="12" r="9.5"/><path d="m9 9 6 6m0-6-6 6"/>',
  siri:'<path d="M12 3.5a3 3 0 0 1 3 3v5a3 3 0 0 1-6 0v-5a3 3 0 0 1 3-3z"/><path d="M5.5 11a6.5 6.5 0 0 0 13 0M12 17.5v3"/>',
  spot:'<circle cx="10.5" cy="10.5" r="6.5"/><path d="m15.5 15.5 5 5"/><path d="M8 10.5h5M10.5 8v5"/>',
  hold:'<rect x="6" y="2.5" width="12" height="19" rx="3"/><path d="M10 6h4M9.5 12h5M9.5 15.5h5"/>',
  card:'<rect x="3.5" y="5" width="17" height="14" rx="2.5"/><path d="M3.5 9.5h17M7 13.5h6"/>'
};
const ic=(k,c="")=>`<svg viewBox="0 0 24 24" class="${c}" aria-hidden="true">${NI[k]}</svg>`;
const MARK=`<svg class="n-mark" viewBox="0 0 120 120" aria-hidden="true"><defs><linearGradient id="nmg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#0E7A56"/><stop offset="1" stop-color="#053A2A"/></linearGradient></defs><rect width="120" height="120" rx="27" fill="url(#nmg)"/><path d="M60 17 97 38.5v43L60 103 23 81.5v-43z" fill="#F7FAF8"/><path d="M60 28 88 44v32L60 92 32 76V44z" fill="#095C41"/><path d="M60 36c0 0-15 16-15 27a15 15 0 0 0 30 0c0-11-15-27-15-27z" fill="#E85434"/><path d="M57.2 56h5.6v6.2H69v5.6h-6.2V74h-5.6v-6.2H51v-5.6h6.2z" fill="#F7FAF8"/></svg>`;

/* ---------- state for this layer ---------- */
const TITLES={home:"TOXCARD",agents:"Antidotes",toxidromes:"Triage",saved:"Pinned"};
const NTABS=[["home","Cards","cards"],["agents","Antidotes","vial"],["toxidromes","Triage","pulse"],["saved","Pinned","pin"]];
const SCOPE_LABEL={All:"All",Toxins:"Toxins",Antidotes:"Antidotes",Brands:"Brands",Tools:"Toxidromes"};
let browse=store.get("browse","az");          // "az" | "cat"
let spotState=null;                           // last Spotlight result, for Settings
const tierOf=id=>{const t=(P[id]||{}).tier;return "ABCDN".includes(t||"")&&t?t:"N"};
const tierTxt=t=>t==="N"?"–":t;
const letterOf=s=>{const c=String(s).trim().charAt(0).toUpperCase();return /[A-Z]/.test(c)?c:"#"};
const byName=(a,b)=>a.name.localeCompare(b.name,undefined,{sensitivity:"base"});

/* ---------- rows ---------- */
function tRow(t){
  const p=P[t.id]||{}, tr=tierOf(t.id);
  return `<button class="n-row" data-tox="${t.id}"><span class="n-tab t${tr}" aria-label="Tier ${tr==="N"?"none":tr}">${tierTxt(tr)}</span>
    <span class="n-tx"><b>${esc(t.name)}</b><span>${esc(p.agentLine||t.category)}</span></span>${ic("chev","n-chev")}</button>`;
}
function aRow(a){
  return `<button class="n-row" data-agent="${a.id}"><span class="n-ico acc">${ic("vial")}</span>
    <span class="n-tx"><b>${esc(a.name)}</b><span>${a.treats.length} indication${a.treats.length===1?"":"s"} · ${esc(a.class)}${a.brands.length?" · "+esc(a.brands.join(", ")):""}</span></span>${ic("chev","n-chev")}</button>`;
}
function xRow(t){
  return `<button class="n-row" data-gotxd="${t.id}"><span class="n-ico amber">${ic("pulse")}</span>
    <span class="n-tx"><b>${esc(t.name)}</b><span>${esc(t.tell)}</span></span>${ic("chev","n-chev")}</button>`;
}
function sectioned(list,row){
  const g=new Map(); list.slice().sort(byName).forEach(x=>{const L=letterOf(x.name);if(!g.has(L))g.set(L,[]);g.get(L).push(x)});
  const keys=[...g.keys()].sort((a,b)=>a==="#"?1:b==="#"?-1:a.localeCompare(b));
  return {keys,html:keys.map(L=>`<div class="n-sh" id="ix-${L==="#"?"num":L}">${L}</div><div class="n-group">${g.get(L).map(row).join("")}</div>`).join("")};
}
const indexBar=keys=>`<nav class="n-index" id="nIndex" aria-label="Section index">${keys.map(L=>`<span data-ix="${L==="#"?"num":L}">${L}</span>`).join("")}</nav>`;
const footer=()=>`<div class="n-foot">Data ${esc(VERSION.version)} · reviewed ${esc(VERSION.lastReviewed)} · supply watch due ${esc(VERSION.supplyWatchDue||"—")}<br>
  US Poison Control <b>1-800-222-1222</b><br><br>Decision support for trained clinicians. Not a protocol and not a substitute for a regional poison center.<br>© 2026 HAKOYA LLC</div>`;

/* ---------- root views ---------- */
function searchBox(){
  return `<div class="n-search" role="search">${ic("search")}
    <input id="hq" type="search" enterkeyhint="search" placeholder="Toxin, antidote or brand" value="${esc(q)}" autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false" aria-label="Search toxins, antidotes and brand names">
    <button class="n-clr" id="cq" aria-label="Clear search"${q?"":" hidden"}>${ic("x")}</button></div>`;
}
function resultsHTML(){
  const r=scopedSearch(q);
  const n=(r.toxins||[]).length+(r.agents||[]).length+(r.txd||[]).length;
  const seg=`<div class="n-seg scroll" role="tablist">${SCOPES.map(x=>`<button data-scope="${x}" aria-pressed="${x===scope}">${SCOPE_LABEL[x]||x}</button>`).join("")}</div>`;
  if(!n) return seg+`<div class="n-empty">${ic("search")}Nothing matches “${esc(q)}” in ${esc(SCOPE_LABEL[scope]||scope)}.<br>Try another scope, a brand name, or an agent.</div>`;
  return seg
    +((r.toxins||[]).length?`<div class="n-sh">Toxins<span>${r.toxins.length}</span></div><div class="n-group">${r.toxins.map(tRow).join("")}</div>`:"")
    +((r.agents||[]).length?`<div class="n-sh">Antidotes and agents<span>${r.agents.length}</span></div><div class="n-group">${r.agents.map(aRow).join("")}</div>`:"")
    +((r.txd||[]).length?`<div class="n-sh">Toxidromes<span>${r.txd.length}</span></div><div class="n-group">${r.txd.map(xRow).join("")}</div>`:"");
}
function browseHTML(){
  const urg=URGENT.filter(u=>T[u.id]);
  const strip=urg.length?`<div class="n-sh">Time-critical<span>${urg.length}</span></div><div class="n-urgent">${urg.map(u=>
    `<button class="n-uc" data-tox="${u.id}"><span class="k">${ic("warn")}Act now</span><b>${esc(shortName(T[u.id].name))}</b><span>${esc(u.line)}</span></button>`).join("")}</div>`:"";
  const seg=`<div class="n-sh">All ${TOXINS.length} toxins</div><div class="n-seg"><button data-browse="az" aria-pressed="${browse==="az"}">A–Z</button><button data-browse="cat" aria-pressed="${browse==="cat"}">By category</button></div>`;
  let list="", idx="";
  if(browse==="az"){ const s=sectioned(TOXINS,tRow); list=s.html; idx=indexBar(s.keys); }
  else{
    const cats=["All",...[...new Set(TOXINS.map(t=>t.category))].sort()];
    const g={}; TOXINS.filter(t=>cat==="All"||t.category===cat).forEach(t=>(g[t.category]??=[]).push(t));
    list=`<div class="n-chips">${cats.map(c=>`<button data-cat="${esc(c)}" aria-pressed="${c===cat}">${esc(c)}</button>`).join("")}</div>`
      +Object.keys(g).sort().map(c=>`<div class="n-sh">${esc(c)}<span>${g[c].length}</span></div><div class="n-group">${g[c].slice().sort(byName).map(tRow).join("")}</div>`).join("");
  }
  return strip+seg+list+footer()+idx;
}
function homeBody(){ return searchBox()+`<div id="nResults">${q.trim()?resultsHTML():browseHTML()}</div>`; }
function agentsResults(){
  const k=agentQ.trim().toLowerCase();
  const list=AGENTS.filter(a=>!k||(a.name+" "+a.brands.join(" ")+" "+a.class).toLowerCase().includes(k));
  if(!list.length) return `<div class="n-empty">${ic("vial")}No agent matches that.</div>`;
  const s=sectioned(list,aRow);
  return `<p class="n-lede">${list.length} agent${list.length===1?"":"s"}, and every toxin each one treats.</p>${s.html}${k?"":indexBar(s.keys)}`;
}
function agentsBody(){
  return `<div class="n-search" role="search">${ic("search")}<input id="aq" type="search" enterkeyhint="search" placeholder="Agent or brand name" value="${esc(agentQ)}" autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false" aria-label="Search agents and brand names"></div>`
    +`<div id="nResults">${agentsResults()}</div>`;
}
function triageBody(){
  return `<p class="n-lede">Pick the pattern in front of you. Each one names the finding that separates it from the one it is confused with.</p>
  <div class="n-group">${TOXIDROMES.map(t=>{const o=openTox===t.id;
    return `<div class="n-txd${o?" open":""}" id="tx-${t.id}"><button class="n-row" data-ntxd="${t.id}" aria-expanded="${o}"><span class="n-ico amber">${ic("pulse")}</span>
      <span class="n-tx"><b>${esc(t.name)}</b><span class="${o?"wrap":""}">${esc(o?t.onset:t.tell)}</span></span>${ic("chev","n-chev")}</button>${o?txdHTML(t):""}</div>`}).join("")}</div>`;
}
function savedBody(){
  const s=favs.filter(id=>T[id]), r=recent.filter(id=>T[id]);
  const seg=`<div class="n-seg"><button data-nseg="saved" aria-pressed="${!showRecent}">Pinned <small>${s.length}</small></button><button data-nseg="recent" aria-pressed="${showRecent}">Recent <small>${r.length}</small></button></div>`;
  const l=showRecent?r:s;
  if(!l.length) return seg+`<div class="n-empty">${ic(showRecent?"cards":"pin")}${showRecent?"Nothing viewed yet.":"Nothing pinned yet.<br>Tap the star on any card to keep it here, in the Home Screen quick actions, and one tap away."}</div>`;
  return seg+`<div class="n-group">${l.map(id=>tRow(T[id])).join("")}</div>`;
}

/* ---------- detail views ---------- */
function agentDetail(id){
  const a=A[id]; const rows=a.treats.map(x=>T[x]).filter(Boolean);
  return `<div class="n-ahero"><span class="n-ico acc">${ic("vial")}</span><div><h3>${esc(a.name)}</h3><div class="badges">
      <span class="badge teal">${esc(a.class)}</span><span class="badge">${a.treats.length} indication${a.treats.length>1?"s":""}</span></div></div></div>
    ${a.brands.length?`<div class="n-box"><h4>Also known as</h4><p>${esc(a.brands.join(" · "))}</p></div>`:""}
    <div class="n-sh">Used for<span>${rows.length}</span></div><div class="n-group">${rows.map(tRow).join("")}</div>`;
}
/* Same text as the web build's "Copy dose and pitfall". */
const cardText=id=>{const pr=P[id]||{}, tx=T[id];return tx.name+"\n\n"+pr.agentLine+"\n\n"+pr.dose+"\n\nPitfall: "+pr.pitfall};
const agentText=id=>{const a=A[id];return a.name+" ("+a.class+")"+(a.brands.length?"\nAlso known as: "+a.brands.join(", "):"")
  +"\n\nUsed for:\n"+a.treats.map(x=>T[x]).filter(Boolean).map(t=>"• "+t.name).join("\n")};
function printHTML(id){
  const t=T[id], p=P[id]||{};
  return `<html><head><meta charset="utf-8"><style>body{font:12pt -apple-system,Helvetica,sans-serif;color:#000}
    h1{font-size:20pt;margin:0 0 2pt}.s{color:#444;margin:0 0 14pt}h2{font-size:10pt;letter-spacing:.08em;text-transform:uppercase;color:#444;margin:16pt 0 4pt}
    table{border-collapse:collapse;width:100%;font:10.5pt ui-monospace,Menlo,monospace}td{border-top:.5pt solid #bbb;padding:5pt 0;vertical-align:top}
    td.k{width:30%;font:600 10.5pt -apple-system,Helvetica,sans-serif;padding-right:8pt}td.v span{display:block}
    .pit{border-left:3pt solid #b3261e;padding:6pt 10pt;background:#f7e3df}.f{color:#555;font-size:9pt;margin-top:18pt}</style></head><body>
    <h1>${esc(t.name)}</h1><p class="s">${esc(t.category)} · Tier ${p.tier==="N"?"—":esc(p.tier)}</p>
    ${p.window?`<h2>Time-critical window</h2><p>${esc(p.window)}</p>`:""}
    <h2>Agent</h2><p>${esc(p.agentLine)}</p><h2>Dose and management</h2>${doseTable(p.dose)}
    <h2>Pitfall</h2><p class="pit">${esc(p.pitfall)}</p>
    <h2>Sources</h2>${(p.sources||[]).map(s=>`<p>${esc(s.type)} · ${esc(s.label)}</p>`).join("")}
    <p class="f">TOXCARD data ${esc(VERSION.version)} · last reviewed ${esc(p.lastReviewed||VERSION.lastReviewed)}. Confirm every dose against your own formulary before administration. US Poison Control 1-800-222-1222.</p></body></html>`;
}

/* ---------- overlays ---------- */
function toast(msg){
  let t=$("nToast"); if(!t){t=document.createElement("div");t.id="nToast";t.className="n-toast";t.setAttribute("role","status");document.body.appendChild(t)}
  t.textContent=msg; t.classList.add("on"); clearTimeout(toast._h); toast._h=setTimeout(()=>t.classList.remove("on"),1700);
}
function closeOverlays(){
  ["nScrim","nSheet","nActions"].forEach(id=>{const el=$(id);if(!el)return;el.classList.remove("on");setTimeout(()=>el.remove(),300)});
}
function scrim(){const s=document.createElement("div");s.className="n-scrim";s.id="nScrim";s.onclick=closeOverlays;document.body.appendChild(s);requestAnimationFrame(()=>s.classList.add("on"));}
function actionSheet(items){
  closeOverlays(); scrim();
  const a=document.createElement("div"); a.className="n-actions"; a.id="nActions"; a.setAttribute("role","menu");
  a.innerHTML=`<div class="grp">${items.map((x,i)=>`<button role="menuitem" data-ai="${i}">${esc(x[0])}</button>`).join("")}</div><button class="cancel" data-ai="c">Cancel</button>`;
  document.body.appendChild(a); requestAnimationFrame(()=>a.classList.add("on"));
  a.querySelectorAll("[data-ai]").forEach(b=>b.onclick=()=>{closeOverlays();const x=items[+b.dataset.ai];if(x)x[1]()});
}
function themeNow(){const t=store.get("theme","system");return t==="light"||t==="dark"?t:"system"}
function applyTheme(t){
  store.set("theme",t);
  if(t==="system") document.documentElement.removeAttribute("data-theme"); else document.documentElement.setAttribute("data-theme",t);
  nat(UI,"appearance",{style:t});
}
function settingsSheet(){
  closeOverlays(); scrim();
  const s=document.createElement("div"); s.className="n-sheet"; s.id="nSheet"; s.setAttribute("role","dialog"); s.setAttribute("aria-label","Settings");
  const th=themeNow(), n=TOXINS.length+AGENTS.length;
  const spot=!NATIVE?"Available on iPhone":spotState&&spotState.available===false?"Not available on this iPhone":spotState&&typeof spotState.indexed==="number"?`${spotState.indexed} entries`:"Indexing…";
  s.innerHTML=`<div class="n-grab"></div><div class="n-sheethead"><h2>Settings</h2><button id="nDone">Done</button></div>
    <div class="n-sh">Appearance</div>
    <div class="n-seg">${["system","light","dark"].map(x=>`<button data-thm="${x}" aria-pressed="${x===th}">${x[0].toUpperCase()+x.slice(1)}</button>`).join("")}</div>
    <div class="n-sh">Siri &amp; Search</div>
    <div class="n-group"><div class="n-set"><span class="n-ico acc">${ic("spot")}</span><span class="n-tx"><b>In iPhone Search</b></span><span class="v" id="nSpotV">${spot}</span></div>
      <button class="n-set act" id="nReindex"><span class="n-ico acc">${ic("search")}</span><span class="n-tx"><b>Rebuild Search index</b></span></button></div>
    <p class="n-para">All ${n} toxins and antidotes appear when you swipe down on the Home Screen and search. A result opens its card here. Ask Siri <q>Look up an antidote in TOXCARD</q>, <q>Look up a toxin in TOXCARD</q> or <q>Open toxidrome triage in TOXCARD</q>; the same actions are in the Shortcuts app.</p>
    <p class="n-para">Touch and hold the TOXCARD icon for Search, Toxidrome Triage and your two latest pinned cards.</p>
    <div class="n-sh">Doses</div>
    <div class="n-group"><div class="n-set"><span class="n-tx"><b>Doses are shown exactly as their sources state them. This build does not compute weight-based doses.</b></span></div></div>
    <div class="n-sh">Data</div>
    <div class="n-group">
      <div class="n-set"><span class="n-tx"><b>Dataset</b></span><span class="v">${esc(VERSION.version)}</span></div>
      <div class="n-set"><span class="n-tx"><b>Last reviewed</b></span><span class="v">${esc(VERSION.lastReviewed)}</span></div>
      <div class="n-set"><span class="n-tx"><b>Next full review</b></span><span class="v">${esc(VERSION.nextReviewDue||"—")}</span></div>
      <div class="n-set"><span class="n-tx"><b>Supply-volatile agents re-checked</b></span><span class="v">${esc(VERSION.supplyWatchDue||"—")}</span></div>
      <div class="n-set"><span class="n-tx"><b>Contents</b></span><span class="v">${TOXINS.length} toxins · ${AGENTS.length} agents · ${TOXIDROMES.length} toxidromes</span></div></div>
    ${(VERSION.changelog||[]).length?`<div class="n-sh">Updates</div><div class="n-group">${VERSION.changelog.slice(0,4).map(c=>`<div class="n-set"><span class="n-tx"><span class="wrap" style="font-size:14.5px;color:var(--ink)">${esc(c)}</span></span></div>`).join("")}</div>`:""}
    <div class="n-sh">About</div>
    <div class="n-group"><a class="n-set act" href="tel:18002221222" style="text-decoration:none"><span class="n-tx"><b>US Poison Control · 1-800-222-1222</b></span></a>
      <div class="n-set"><span class="n-tx"><span class="wrap" style="font-size:14.5px;color:var(--mut)">Decision support for trained clinicians. Not a protocol and not a substitute for a regional poison center. Nothing you do in TOXCARD leaves this iPhone: no account, no network, no analytics.</span></span></div></div>
    <div class="n-foot">TOXCARD · © 2026 HAKOYA LLC</div>`;
  document.body.appendChild(s); requestAnimationFrame(()=>s.classList.add("on"));
  $("nDone").onclick=closeOverlays;
  s.querySelectorAll("[data-thm]").forEach(b=>b.onclick=()=>{applyTheme(b.dataset.thm);haptic("selection");
    s.querySelectorAll("[data-thm]").forEach(x=>x.setAttribute("aria-pressed",x===b))});
  $("nReindex").onclick=async()=>{const v=$("nSpotV"); if(v)v.textContent="Indexing…"; await indexSpotlight(true);
    const w=$("nSpotV"); if(w)w.textContent=spotState&&typeof spotState.indexed==="number"?`${spotState.indexed} entries`:"Available on iPhone";
    haptic("success"); toast("Search index rebuilt")};
}

/* ---------- paint ---------- */
paint=function(){
  const top=stack[stack.length-1], v=$("view"), tb=$("tb");
  closeOverlays();
  document.body.classList.toggle("n-pushed",!!top);
  document.body.classList.remove("n-scrolled");
  if(top){
    const isTox=top.kind==="toxin", name=isTox?T[top.id].name:A[top.id].name;
    const prev=stack[stack.length-2];
    const prevLabel=prev?(prev.kind==="toxin"?shortName(T[prev.id].name):A[prev.id].name):{home:"Cards",agents:"Antidotes",toxidromes:"Triage",saved:"Pinned"}[tab]||"Back";
    const pinned=isTox&&favs.includes(top.id);
    tb.innerHTML=`<button class="n-back" id="bk" aria-label="Back to ${esc(prevLabel)}">${ic("back")}<span>${esc(prevLabel)}</span></button>
      <span class="n-navtitle">${esc(shortName(name))}</span><span class="n-spacer"></span>
      ${isTox?`<button class="n-ib" id="fav" aria-label="${pinned?"Unpin":"Pin"}" aria-pressed="${pinned}">${ic("pin")}</button>`:""}
      <button class="n-ib" id="shr" aria-label="Share">${ic("share")}</button>
      ${isTox?`<button class="n-ib" id="more" aria-label="More">${ic("more")}</button>`:""}`;
    v.innerHTML=isTox?`<article class="n-detail tier-${tierOf(top.id)}">${viewToxin(top.id)}</article>`:`<article class="n-adetail">${agentDetail(top.id)}</article>`;
    $("bk").onclick=()=>{haptic("light");pop()};
    $("shr").onclick=()=>shareEntry(top);
    if(isTox){
      $("fav").onclick=()=>toggleFav(top.id);
      $("more").onclick=()=>actionSheet([
        ["Share card",()=>shareEntry(top)],
        ["Print card",()=>printEntry(top.id)],
        ["Copy dose and pitfall",()=>copyEntry(top.id)],
        ["Jump to pitfall",()=>{const el=$("sec-pf");if(el)scrollToEl(el,true)}]]);
    }
  }else{
    tb.innerHTML=`<span class="n-navtitle">${TITLES[tab]||"TOXCARD"}</span><span class="n-spacer"></span>
      <button class="n-ib" id="nGear" aria-label="Settings">${ic("gear")}</button>`;
    const lt=tab==="home"?`<h1 class="n-word">TOX<em>CARD</em></h1>`:`<h1>${TITLES[tab]}</h1>`;
    const body={home:homeBody,agents:agentsBody,toxidromes:triageBody,saved:savedBody}[tab]||homeBody;
    v.innerHTML=`<div class="n-root n-${tab}"><div class="n-lt">${lt}</div>${body()}</div>`;
    $("nGear").onclick=settingsSheet;
  }
  $("tabs").innerHTML=NTABS.map(([k,l,i])=>`<button data-tab="${k}" aria-current="${k===tab}">${ic(i)}<span>${l}</span></button>`).join("");
  v.scrollTop=0;
  bindAll(v); wire($("tb"));
  if(top&&top.kind==="toxin"){
    wireJump();
    v.querySelectorAll("[data-jump]").forEach(b=>b.onclick=()=>{const el=$("sec-"+b.dataset.jump);if(el){haptic("selection");scrollToEl(el,true)}});
  }
};
function bindAll(v){
  wire(v); bindLocal(v); bindInputs(); bindIndex();
}
function bindLocal(root){
  root.querySelectorAll("[data-browse]").forEach(b=>b.onclick=()=>{if(browse===b.dataset.browse)return;browse=b.dataset.browse;store.set("browse",browse);haptic("selection");repaintKeep()});
  root.querySelectorAll("[data-cat]").forEach(b=>b.onclick=()=>{cat=b.dataset.cat;haptic("selection");repaintKeep()});
  root.querySelectorAll("[data-scope]").forEach(b=>b.onclick=()=>{scope=b.dataset.scope;haptic("selection");refreshResults()});
  root.querySelectorAll("[data-nseg]").forEach(b=>b.onclick=()=>{showRecent=b.dataset.nseg==="recent";haptic("selection");paint()});
  root.querySelectorAll("[data-ntxd]").forEach(b=>b.onclick=()=>{const id=b.dataset.ntxd;openTox=openTox===id?null:id;haptic("selection");
    repaintKeep(); const el=$("tx-"+id); if(openTox&&el){const v=$("view"),bar=document.querySelector(".topbar").offsetHeight;const y=el.offsetTop-v.scrollTop;if(y<bar||y>v.clientHeight*.5)scrollToEl(el,true)}});
  root.querySelectorAll("[data-gotxd]").forEach(b=>b.onclick=()=>{openTox=b.dataset.gotxd;q="";go("toxidromes");const el=$("tx-"+openTox);if(el)scrollToEl(el,false)});
}
/* scroll so an element sits just below the navigation bar (and the entry's sticky section bar) */
function scrollToEl(el,smooth){
  const v=$("view"), bar=document.querySelector(".topbar"), jb=stack.length?document.querySelector(".n-detail .jump"):null;
  const y=el.offsetTop-(bar?bar.offsetHeight:0)-(jb&&jb!==el?jb.offsetHeight:0)-8;
  if(smooth) v.scrollTo({top:Math.max(0,y),behavior:"smooth"}); else v.scrollTop=Math.max(0,y);
}
/* re-render the current root view, keeping the scroll position */
function repaintKeep(){const v=$("view"),y=v.scrollTop;paint();v.scrollTop=y;onScroll()}
function refreshResults(){
  const box=$("nResults"); if(!box) return;
  box.innerHTML=tab==="agents"?agentsResults():(q.trim()?resultsHTML():browseHTML());
  wire(box); bindLocal(box); bindIndex();
  const cq=$("cq"); if(cq) cq.hidden=!q;
}
function bindInputs(){
  const hq=$("hq");
  if(hq){
    hq.oninput=e=>{q=e.target.value;refreshResults()};
    hq.onkeydown=e=>{if(e.key==="Enter")hq.blur()};
  }
  const cq=$("cq"); if(cq) cq.onclick=()=>{q="";const h=$("hq");if(h)h.value="";refreshResults();if(h)h.focus()};
  const aq=$("aq"); if(aq){ aq.oninput=e=>{agentQ=e.target.value;refreshResults()}; aq.onkeydown=e=>{if(e.key==="Enter")aq.blur()}; }
}
/* A-Z index: tap or drag along the right edge */
function bindIndex(){
  const nav=$("nIndex"); if(!nav) return;
  let last=null, bubble=null;
  const jump=L=>{if(!L||L===last)return;last=L;const el=$("ix-"+L);if(!el)return;
    scrollToEl(el,false);haptic("selection");
    if(!bubble){bubble=document.createElement("div");bubble.className="n-bubble";document.body.appendChild(bubble)}
    bubble.textContent=L==="num"?"#":L;};
  const at=(x,y)=>{const el=document.elementFromPoint(x,y);return el&&el.dataset?el.dataset.ix:null};
  const end=()=>{last=null;nav.classList.remove("on");if(bubble){bubble.remove();bubble=null}};
  nav.addEventListener("touchstart",e=>{nav.classList.add("on");const t=e.touches[0];jump(at(t.clientX,t.clientY));e.preventDefault()},{passive:false});
  nav.addEventListener("touchmove",e=>{const t=e.touches[0];const r=nav.getBoundingClientRect();jump(at(r.left+r.width/2,t.clientY));e.preventDefault()},{passive:false});
  nav.addEventListener("touchend",end); nav.addEventListener("touchcancel",end);
  nav.querySelectorAll("[data-ix]").forEach(s=>s.onclick=()=>{jump(s.dataset.ix);setTimeout(end,350)});
}
function onScroll(){const v=$("view");document.body.classList.toggle("n-scrolled",!stack.length&&v.scrollTop>38)}
$("view").addEventListener("scroll",onScroll,{passive:true});

/* ---------- navigation ---------- */
go=function(t){
  if(t==="calc"||t==="toxins") t="home";
  if(t==="tools"){settingsSheet();return}
  if(t==="recent"){tab="saved";stack=[];q="";showRecent=true;paint();return}
  if(!TITLES[t]) t="home";
  if(t!==tab||stack.length) haptic("selection");
  if(t===tab&&!stack.length){const v=$("view");if(v.scrollTop>0){v.scrollTo({top:0,behavior:"smooth"});return}}
  tab=t;stack=[];q="";showRecent=t==="saved"?showRecent:false;paint();
};
push=function(kind,id){
  if(kind==="toxin"?!T[id]:!A[id]) return;
  stack.push({kind,id}); if(kind==="toxin") remember(id);
  haptic("light"); paint(); viewing(kind,id); if(kind==="toxin") syncQuick();
};
pop=function(){stack.pop();paint();const top=stack[stack.length-1];if(top)viewing(top.kind,top.id)};
toggleFav=function(id){
  favs=favs.includes(id)?favs.filter(x=>x!==id):[id,...favs]; store.set("favs",favs);
  const on=favs.includes(id), b=$("fav");
  if(b){b.setAttribute("aria-pressed",on);b.setAttribute("aria-label",on?"Unpin":"Pin")}
  haptic(on?"success":"light"); toast(on?"Pinned":"Removed from Pinned"); syncQuick();
};
/* left-edge swipe goes back, as in a navigation controller */
(function(){
  let sx=null,sy=0;
  document.addEventListener("touchstart",e=>{const t=e.touches[0];sx=(stack.length&&t.clientX<24)?t.clientX:null;sy=t.clientY},{passive:true});
  document.addEventListener("touchend",e=>{if(sx==null)return;const t=e.changedTouches[0];
    if(t.clientX-sx>80&&Math.abs(t.clientY-sy)<70){haptic("light");pop()} sx=null},{passive:true});
})();

/* ---------- share, print, copy ---------- */
async function shareEntry(top){
  const isTox=top.kind==="toxin", text=isTox?cardText(top.id):agentText(top.id), title=isTox?T[top.id].name:A[top.id].name;
  if(UI){const r=await nat(UI,"share",{title,text});if(r)return}
  if(navigator.share){try{await navigator.share({title,text});return}catch(e){return}}
  copyText(text);
}
async function printEntry(id){
  if(UI){const r=await nat(UI,"printCard",{title:T[id].name,html:printHTML(id)});if(r)return}
  try{window.print()}catch(e){}
}
function copyText(t){
  try{const cp=navigator.clipboard&&navigator.clipboard.writeText(t);if(cp&&cp.catch)cp.catch(()=>{})}catch(e){}
  toast("Copied");
}
const copyEntry=id=>{copyText(cardText(id));haptic("success")};

/* ---------- Spotlight, Siri Suggestions, quick actions ---------- */
function spotItems(){
  return TOXINS.map(t=>{const p=P[t.id]||{};
      return {id:t.id,kind:"toxin",title:t.name,subtitle:[t.category,p.agentLine].filter(Boolean).join(" · "),
        keywords:[...(t.aka||[]),t.category,...(p.antidoteIds||[]).map(i=>A[i]?A[i].name:"").filter(Boolean)]}})
    .concat(AGENTS.map(a=>({id:a.id,kind:"agent",title:a.name,subtitle:`${a.class} · ${a.treats.length} indication${a.treats.length===1?"":"s"}`,
      keywords:[...a.brands,a.class]})));
}
async function indexSpotlight(force){
  if(!Spot) return null;
  const sig=VERSION.version+"/"+TOXINS.length+"/"+AGENTS.length+"/n1";
  if(!force&&store.get("spot",null)===sig){spotState={indexed:TOXINS.length+AGENTS.length,available:true};return spotState}
  const r=await nat(Spot,"index",{version:VERSION.version,items:spotItems()});
  if(r){spotState=r; if(typeof r.indexed==="number"&&r.available!==false) store.set("spot",sig)}
  return r;
}
function viewing(kind,id){
  if(!Spot) return;
  const isTox=kind==="toxin", e=isTox?T[id]:A[id]; if(!e) return;
  nat(Spot,"viewing",{id,kind,title:e.name,subtitle:isTox?((P[id]||{}).agentLine||e.category):e.class});
}
function syncQuick(){
  if(!Quick) return;
  const s=favs.filter(id=>T[id]), src=s.length?s:recent.filter(id=>T[id]);
  nat(Quick,"setEntries",{items:src.slice(0,2).map(id=>({route:"open:toxin:"+id,title:shortName(T[id].name),
    subtitle:T[id].category,icon:s.length?"saved":"recent"}))});
}

/* ---------- routes from Spotlight, Siri, quick actions ---------- */
function focusSearch(){setTimeout(()=>{const h=$("hq");if(h){h.focus();h.setSelectionRange(h.value.length,h.value.length)}},60)}
function dismissWelcome(){const w=$("welcome");if(w){store.set("seen",true);w.remove()}}
function route(r){
  if(!r||typeof r!=="string") return false;
  const i=r.indexOf(":"), kind=r.slice(0,i), arg=r.slice(i+1);
  closeOverlays(); dismissWelcome();
  if(kind==="open"){
    const j=arg.indexOf(":"), k=arg.slice(0,j), id=arg.slice(j+1);
    if(k==="toxin"&&T[id]){tab="home";q="";stack=[];push("toxin",id);return true}
    if(k==="agent"&&A[id]){tab="agents";agentQ="";stack=[];push("agent",id);return true}
    return false;
  }
  if(kind==="search"){tab="home";stack=[];q=arg;scope="All";paint();focusSearch();return true}
  if(kind==="tab"){
    if(arg==="search"){tab="home";stack=[];q="";paint();focusSearch();return true}
    const t={agents:"agents",triage:"toxidromes",saved:"saved"}[arg]; if(!t) return false;
    tab=t;stack=[];q="";paint();return true;
  }
  return false;
}
async function takeRoute(){const r=await nat(Launch,"take");if(r&&r.route)route(r.route)}

/* ---------- first launch ---------- */
(function(){
  const sp=$("splash");
  if(sp) sp.innerHTML=`${MARK}<h1>TOX<em>CARD</em></h1><p>Toxin · Agent · Pitfall</p><div class="cred">HAKOYA LLC<br>Decision support for trained clinicians</div>`;
  const w=$("welcome"); if(!w) return;
  w.innerHTML=`${MARK}<div class="wm">TOX<em>CARD</em></div>
    <div class="sub">Clinical toxicology, one card per poison.</div>
    <ul>
      <li>${ic("card")}<span><b>Toxin, agent, pitfall</b>Every card puts the dose and the mistake that kills on one screen.</span></li>
      <li>${ic("pulse")}<span><b>Toxidrome triage</b>No history? Start from the pattern in front of you.</span></li>
      <li>${ic("spot")}<span><b>In iPhone Search and Siri</b>All ${TOXINS.length} toxins and ${AGENTS.length} antidotes, straight from the Home Screen.</span></li>
      <li>${ic("hold")}<span><b>Offline, private</b>No account and no network. Nothing leaves this iPhone.</span></li>
    </ul>
    <div class="go"><button id="nStart">Continue</button>
    <p class="n-fine">For trained clinicians. Not a substitute for a regional poison center, 1-800-222-1222.</p></div>`;
  $("nStart").onclick=()=>{store.set("seen",true);haptic("light");w.style.transition="opacity .3s ease";w.style.opacity="0";setTimeout(()=>w.remove(),320)};
})();

/* ---------- start ---------- */
if(typeof TABS!=="undefined"&&!TITLES[tab]) tab="home";
nat(UI,"appearance",{style:themeNow()});
paint();
window.TOXCARD_NATIVE={route,takeRoute,indexSpotlight,syncQuick,settingsSheet,spotItems,get spot(){return spotState},native:NATIVE};
if(Launch){
  try{const h=Launch.addListener("route",()=>takeRoute());if(h&&h.catch)h.catch(()=>{})}catch(e){}
}
document.addEventListener("resume",takeRoute);
document.addEventListener("visibilitychange",()=>{if(!document.hidden)takeRoute()});
setTimeout(takeRoute,50);
setTimeout(()=>{indexSpotlight(false);syncQuick()},1200);
})();
