/* FRONTLINE ZERO deterministic fixed-step simulation. No runtime dependencies. */
(function(root,factory){const api=factory();if(typeof module==='object')module.exports=api;else root.FZ=api;})(typeof globalThis!=='undefined'?globalThis:this,()=>{
'use strict';
const W=1000,H=650,STEP=1/30;
const CHASSIS={wheeled:{hp:90,speed:105,capacity:5,cost:40},tracked:{hp:240,speed:52,capacity:10,cost:90}};
const WEAPONS={autocannon:{weight:2,damage:13,range:130,reload:.55,cost:25},cannon:{weight:4,damage:48,range:170,reload:1.8,cost:40},howitzer:{weight:6,damage:95,range:290,minRange:80,reload:3.4,cost:65}};
const ARMOR={light:{weight:1,hp:0,speed:1,cost:5},heavy:{weight:4,hp:140,speed:.72,cost:30}};
function blueprint(b){
 if(!b||!CHASSIS[b.chassis]||!WEAPONS[b.weapon]||!ARMOR[b.armor])throw Error('Unknown module');
 const c=CHASSIS[b.chassis],w=WEAPONS[b.weapon],a=ARMOR[b.armor];if(w.weight+a.weight>c.capacity)throw Error('Payload exceeds chassis capacity');
 return {...b,type:b.weapon==='howitzer'?'artillery':b.chassis==='wheeled'?'scout':'tank',hp:c.hp+a.hp,speed:c.speed*a.speed,damage:w.damage,range:w.range,minRange:w.minRange||0,reload:w.reload,cost:c.cost+w.cost+a.cost};
}
const PRESETS={scout:{chassis:'wheeled',weapon:'autocannon',armor:'light'},tank:{chassis:'tracked',weapon:'cannon',armor:'light'},artillery:{chassis:'tracked',weapon:'howitzer',armor:'light'}};
const terrain=[{x:390,y:75,w:220,h:115,type:'cover'},{x:390,y:465,w:220,h:115,type:'cover'},{x:440,y:235,w:120,h:180,type:'mud'}];
const distance=(a,b)=>Math.hypot(a.x-b.x,a.y-b.y);
function zone(u){return terrain.find(z=>u.x>=z.x&&u.x<=z.x+z.w&&u.y>=z.y&&u.y<=z.y+z.h);}
class Battle{
 constructor(loadout=['tank','tank','scout','scout','artillery'],custom=PRESETS.tank){
  if(!Array.isArray(loadout)||loadout.length<1||loadout.length>12)throw Error('Choose 1–12 units');
  const builds=loadout.map(k=>blueprint(k==='custom'?custom:PRESETS[k]));if(builds.reduce((a,b)=>a+b.cost,0)>600)throw Error('Deployment budget exceeded');
  this.units=[];this.time=0;this.result=null;this.score=[0,0];this.hq=[{x:65,y:325,hp:1600,maxHp:1600,team:0},{x:935,y:325,hp:1600,maxHp:1600,team:1}];
  this.points=[{x:500,y:130,progress:0,owner:-1},{x:500,y:520,progress:0,owner:-1}];this.events=[];this.nextId=1;
  builds.forEach((b,i)=>this.spawn(0,b,130,175+i*65));
  ['tank','tank','scout','scout','artillery'].forEach((k,i)=>this.spawn(1,blueprint(PRESETS[k]),870,175+i*65));
 }
 spawn(team,b,x,y){const u={...b,id:this.nextId++,team,x,y,maxHp:b.hp,hp:b.hp,cooldown:0,order:null,direct:null};this.units.push(u);return u;}
 command(ids,x,y,targetId=null){if(!Number.isFinite(x)||!Number.isFinite(y))return;ids.forEach((id,i)=>{const u=this.units.find(v=>v.id===id&&v.team===0&&v.hp>0);if(u)u.order={x:Math.max(15,Math.min(W-15,x+(i%3)*22)),y:Math.max(15,Math.min(H-15,y+Math.floor(i/3)*22)),targetId};});}
 tick(dt=STEP){
  if(this.result)return;if(!Number.isFinite(dt)||dt<=0||dt>.1)throw Error('Use fixed steps of at most 100ms');
  this.time+=dt;this.events=[];
  for(const u of this.units){if(u.hp<=0)continue;u.cooldown=Math.max(0,u.cooldown-dt);
   const enemies=this.units.filter(v=>v.team!==u.team&&v.hp>0);
   if(u.team===1){const p=this.points[u.id%2];u.order=u.type==='scout'?{x:p.x,y:p.y}:{x:150,y:240+(u.id%3)*80};}
   let target=enemies.find(v=>u.order&&v.id===u.order.targetId&&distance(u,v)<=u.range&&distance(u,v)>=u.minRange);
   if(!target)target=enemies.filter(v=>distance(u,v)<=u.range&&distance(u,v)>=u.minRange).sort((a,b)=>distance(u,a)-distance(u,b))[0];
   const h=this.hq[1-u.team];if(!target&&h.hp>0&&distance(u,h)<=u.range&&distance(u,h)>=u.minRange)target=h;
   if(target&&u.cooldown===0){const cover=zone(target);target.hp-=u.damage*(cover&&cover.type==='cover'?.6:1);u.cooldown=u.reload;this.events.push({x:u.x,y:u.y,tx:target.x,ty:target.y,team:u.team});}
   let dx=0,dy=0;
   if(u.direct){dx=u.direct.x;dy=u.direct.y;}else if(u.order){const d=distance(u,u.order);if(d>5&&(!target||u.order.targetId||u.team===0)){dx=(u.order.x-u.x)/d;dy=(u.order.y-u.y)/d;}}
   const len=Math.hypot(dx,dy);if(len>0){const slow=zone(u)?.type==='mud'?.5:1;u.x=Math.max(15,Math.min(W-15,u.x+dx/Math.max(1,len)*u.speed*slow*dt));u.y=Math.max(15,Math.min(H-15,u.y+dy/Math.max(1,len)*u.speed*slow*dt));}
  }
  for(const p of this.points){const near=[0,1].map(t=>this.units.some(u=>u.hp>0&&u.team===t&&distance(u,p)<65));if(near[0]!==near[1])p.progress=Math.max(-6,Math.min(6,p.progress+(near[0]?dt:-dt)));if(p.progress===6)p.owner=0;else if(p.progress===-6)p.owner=1;else if(Math.abs(p.progress)<.05)p.owner=-1;if(p.owner>=0&&!near[1-p.owner])this.score[p.owner]+=dt;}
  for(let t=0;t<2;t++){if(this.hq[1-t].hp<=0||!this.units.some(u=>u.team===1-t&&u.hp>0)||this.score[t]>=120){this.result={winner:t,reason:this.hq[1-t].hp<=0?'headquarters destroyed':this.score[t]>=120?'territory secured':'army eliminated',seconds:Math.round(this.time)};break;}}
  if(!this.result&&this.time>=900)this.result={winner:this.score[0]===this.score[1]?-1:this.score[0]>this.score[1]?0:1,reason:'time limit',seconds:900};
 }
}
function readCampaign(storage){try{const s=JSON.parse(storage.getItem('fz-campaign-v1'));if(s&&s.version===1&&Number.isInteger(s.wins)&&s.wins>=0&&Number.isInteger(s.losses)&&s.losses>=0&&Array.isArray(s.history)&&s.history.length<=20)return s;}catch{}return {version:1,wins:0,losses:0,territory:'contested',history:[]};}
function record(storage,result,id){if(!result||![0,1,-1].includes(result.winner))throw Error('Battle must be finished');const c=readCampaign(storage);if(c.history.some(h=>h.id===id))return c;c.wins+=result.winner===0?1:0;c.losses+=result.winner===1?1:0;c.territory=result.winner===0?'Aster':result.winner===1?'Veyr':c.territory;c.history.unshift({id,...result});c.history=c.history.slice(0,20);storage.setItem('fz-campaign-v1',JSON.stringify(c));return c;}
return {Battle,blueprint,PRESETS,CHASSIS,WEAPONS,ARMOR,terrain,W,H,STEP,readCampaign,record};
});
