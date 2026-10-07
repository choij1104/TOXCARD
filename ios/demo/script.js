window.DEMO_SCRIPT=async({sleep,tap,type,scroll,find})=>{
  await sleep(1500);
  await tap('#start',{after:1800});                                   // welcome -> home
  await tap({sel:'.jumprow',text:/^Cyanide/},{after:2200});           // a toxin card: agent, dose, pitfall
  await scroll(600,2600); await scroll(500,2000);
  await tap('#fav',{after:1200});                                     // save it
  await tap('#bk,#bk2',{after:1500});
  await tap({sel:'.tile',text:/^Antidote Browser/},{after:1800});
  await scroll(500,2000);
  await tap({sel:'button,.tap,[role=button]',text:/^Hydroxocobalamin/},{after:2200});
  await scroll(500,2000);
  await tap('#bk,#bk2',{after:1400});
  await tap({sel:'nav *,#tabs *',text:/^Home$/},{after:1400});
  await tap({sel:'.tile',text:/^Toxidrome Triage/},{after:2200});
  await scroll(500,2000);
  await tap({sel:'nav *,#tabs *',text:/^Tools$/},{after:2000});
  await tap({sel:'nav *,#tabs *',text:/^Saved$/},{after:2000});
  await tap({sel:'nav *,#tabs *',text:/^Home$/},{after:1500});
};
