window.DEMO_SCRIPT=async({sleep,tap,type,scrollEl})=>{
  const scroll=(px,ms)=>scrollEl('#view',px,ms);
  await sleep(1500);
  await tap('#nStart',{after:1800});                                   // first launch -> Cards
  await tap({sel:'.n-uc',text:/^Act now\s*Cyanide/},{after:2200});      // a card: agent, dose, pitfall
  await scroll(600,2600); await scroll(500,2000);
  await tap('#fav',{after:1200});                                       // pin it (also becomes a quick action)
  await tap('#more',{after:1200});                                      // share / print / copy
  await tap({sel:'#nActions button',text:'Cancel'},{after:900});
  await tap('.n-detail [data-agent="hydroxocobalamin"]',{after:2000});  // the antidote and everything it treats
  await scroll(500,2000);
  await tap('#bk',{after:1200}); await tap('#bk',{after:1400});
  await type('#hq','digoxin',1600);                                     // search
  await tap('#cq',{after:1000});
  await tap('#nIndex [data-ix="S"]',{after:1600});                      // A-Z index
  await tap({sel:'#tabs button',text:/Antidotes/},{after:1800});
  await scroll(500,2000);
  await tap({sel:'#tabs button',text:/Triage/},{after:1400});
  await tap('[data-ntxd="anticholinergic"]',{after:2400});
  await tap({sel:'#tabs button',text:/Pinned/},{after:1800});
  await tap('#nGear',{after:2400});                                     // Siri & Search, data review dates
  await scrollEl('#nSheet',600,2200);
  await tap('#nDone',{after:1200});
  await tap({sel:'#tabs button',text:/Cards/},{after:1500});
};
