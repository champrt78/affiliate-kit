#!/usr/bin/env python3
"""Assemble the verdict-queue decision sheet from data/*.json fragments.

Each fragment is a JSON array of draft objects produced by the verdict-data
agents. Reviews carry `product`; comparisons carry `products` + `winner`.
Output: index.html — a self-contained dark-theme sheet. Ray picks one option
per draft (or writes his own), then Copy decisions -> pastes back to Claude.
The copy output is keyed by file PATH so application is unambiguous.
"""
import json, glob, os, html

HERE = os.path.dirname(os.path.abspath(__file__))
DATA_DIR = os.path.join(HERE, "data")

SITE_LABEL = {
    "mywildlifecam": "MyWildlifeCam",
    "detailerpicks": "DetailerPicks",
    "fussybean": "FussyBean",
    "starteraquarium": "StarterAquarium",
    "gameovergear": "GameOverGear",
}
SITE_ORDER = ["detailerpicks", "fussybean", "starteraquarium", "gameovergear", "mywildlifecam"]

def load():
    items = []
    for f in sorted(glob.glob(os.path.join(DATA_DIR, "*.json"))):
        with open(f, encoding="utf-8") as fh:
            try:
                arr = json.load(fh)
            except Exception as e:
                raise SystemExit(f"BAD JSON in {f}: {e}")
        if isinstance(arr, list):
            items.extend(arr)
        else:
            items.append(arr)
    return items

def main():
    items = load()
    # sort: site order, then comparisons after reviews, then title
    items.sort(key=lambda d: (
        SITE_ORDER.index(d.get("site", "")) if d.get("site") in SITE_ORDER else 99,
        0 if d.get("type") == "review" else 1,
        d.get("title", ""),
    ))
    payload = json.dumps(items, ensure_ascii=False)
    total = len(items)
    out = TEMPLATE.replace("/*__DATA__*/", payload).replace("__TOTAL__", str(total))
    with open(os.path.join(HERE, "index.html"), "w", encoding="utf-8") as fh:
        fh.write(out)
    n_rev = sum(1 for d in items if d.get("type") == "review")
    n_cmp = sum(1 for d in items if d.get("type") == "comparison")
    print(f"wrote index.html — {total} drafts ({n_rev} reviews, {n_cmp} comparisons)")
    # sanity: every item has >=2 options
    bad = [d.get("slug") for d in items if len(d.get("options", [])) < 2]
    if bad:
        print("WARN: drafts with <2 options:", bad)

TEMPLATE = r"""<!doctype html>
<html lang="en"><head><meta charset="utf-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1"/>
<title>Verdict Queue — drafts awaiting your call</title>
<style>
  :root{--bg:#0f1311;--panel:#171c1a;--panel2:#1e2522;--ink:#e8eae7;--muted:#9aa49f;--line:#2a322e;--brass:#c9a227;--good:#5fb877;--amber:#e0a83a;--sel:#1d2d22;--radius:14px;--sans:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif;--serif:Georgia,serif;}
  *{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--ink);font-family:var(--sans);line-height:1.5}
  .wrap{max-width:960px;margin:0 auto;padding:0 22px 160px}
  header.top{padding:30px 0 8px}h1{font-family:var(--serif);font-size:30px;margin:0 0 6px}
  .sub{color:var(--muted);font-size:14.5px;max-width:80ch}
  .bar{position:sticky;top:0;z-index:30;background:rgba(15,19,17,.95);backdrop-filter:blur(8px);border-bottom:1px solid var(--line);padding:12px 0;margin-bottom:14px;display:flex;gap:14px;align-items:center}
  .bar .count{font-size:14px;color:var(--muted)}.bar .count b{color:var(--good)}
  .bar .spacer{flex:1}
  .bar button{font:inherit;font-size:13px;border:1px solid var(--line);background:var(--panel2);color:var(--ink);border-radius:8px;padding:8px 15px;cursor:pointer}
  .bar button:hover{border-color:var(--brass)}
  .bar button.primary{background:var(--brass);color:#241c02;border-color:var(--brass);font-weight:700}
  h2.site{font-family:var(--serif);font-size:23px;margin:30px 0 2px;border-bottom:1px solid var(--line);padding-bottom:6px}
  h3.grp{font-size:11px;text-transform:uppercase;letter-spacing:.12em;color:var(--brass);margin:18px 0 8px}
  .card{background:var(--panel);border:1px solid var(--line);border-radius:var(--radius);padding:15px 17px;margin:11px 0}
  .card.done{border-color:var(--good)}
  .card .tt{font-family:var(--serif);font-size:17px;margin:0 0 3px}
  .card .meta{font-size:12px;color:var(--muted);margin-bottom:3px}
  .card .meta .pill{display:inline-block;background:var(--panel2);border:1px solid var(--line);border-radius:20px;padding:1px 9px;margin-right:6px;font-size:11px}
  .card .summary{font-size:13px;color:#c2ccc6;margin:6px 0 4px}
  .card .flags{font-size:12px;color:var(--amber);margin:6px 0;padding-left:2px}
  .card .flags::before{content:"⚑ ";}
  .opts{margin-top:9px;display:flex;flex-direction:column;gap:7px}
  label.opt{display:block;border:1px solid var(--line);border-radius:10px;padding:10px 12px;cursor:pointer;background:var(--panel2);transition:border-color .12s,background .12s}
  label.opt:hover{border-color:var(--brass)}
  label.opt.on{border-color:var(--good);background:var(--sel)}
  label.opt input{margin-right:8px;accent-color:var(--good)}
  label.opt .v{font-size:13.5px;font-weight:600;color:var(--ink)}
  label.opt .s{display:block;font-size:12.5px;color:var(--muted);margin-top:3px;margin-left:22px}
  .own textarea{width:100%;background:#11150f;color:var(--ink);border:1px solid var(--line);border-radius:8px;padding:8px;font:inherit;font-size:12.5px;margin-top:6px;min-height:46px;resize:vertical}
  .own{display:none;margin-left:22px;margin-top:4px}
  label.opt.on + .own.show, .own.show{display:block}
  #ex{position:fixed;inset:0;background:rgba(5,8,7,.92);display:none;align-items:center;justify-content:center;z-index:60;padding:22px}
  #ex .box{background:var(--panel);border:1px solid var(--brass);border-radius:12px;padding:18px;max-width:780px;width:100%}
  #ex textarea{width:100%;min-height:380px;font-family:ui-monospace,Menlo,monospace;font-size:12px;background:var(--panel2);color:var(--ink);border:1px solid var(--line);border-radius:8px;padding:10px}
  #ex .x{float:right;cursor:pointer;color:var(--muted);font-size:20px}
  #ex h3{margin:2px 0 10px;font-family:var(--serif)}
  .toast{position:fixed;bottom:24px;left:50%;transform:translateX(-50%);background:var(--good);color:#06210f;padding:10px 18px;border-radius:10px;font-weight:700;font-size:14px;opacity:0;transition:opacity .2s;pointer-events:none;z-index:80}
  .toast.show{opacity:1}
</style></head><body><div class="wrap">
<header class="top"><h1>Verdict Queue</h1>
<p class="sub">Every noindex draft built while you were away, waiting on one decision each. For each piece, tap the verdict you like best (or pick <b>Write my own</b> and type it). Reviews need a Bottom Line. Comparisons need the winner call. When you have gone through them, hit <b>Copy decisions</b> and paste the result back into Claude. I will write each verdict into its file, which flips the page from noindex to live. You do not have to do them all at once. Anything you skip just stays a draft.</p></header>
<div class="bar"><span class="count"><b id="ndone">0</b> / __TOTAL__ decided</span><span class="spacer"></span>
<button onclick="copyDecisions(event)" class="primary">Copy decisions</button>
<button onclick="showEx()">View / export</button>
<button onclick="resetAll()">Reset</button></div>
<div id="root"></div>
</div>
<div id="ex"><div class="box"><span class="x" onclick="document.getElementById('ex').style.display='none'">✕</span><h3>Paste this back to Claude</h3><textarea id="exT" readonly></textarea></div></div>
<div class="toast" id="toast">Copied</div>
<script>
const DATA = /*__DATA__*/;
const LSK = "verdict-queue-v1";
const st = JSON.parse(localStorage.getItem(LSK) || "{}");
// st[slug] = {choice: 0|1|2|'own', ownV:"", ownS:""}
function save(){ localStorage.setItem(LSK, JSON.stringify(st)); renderCount(); }
function key(d){ return d.path; }
function decided(d){ const s=st[key(d)]; if(!s) return false; if(s.choice==='own') return (s.ownV||'').trim().length>0; return typeof s.choice==='number'; }
function renderCount(){
  const n = DATA.filter(decided).length;
  document.getElementById('ndone').textContent = n;
  DATA.forEach(d=>{ const c=document.getElementById('card-'+cssid(d)); if(c) c.classList.toggle('done', decided(d)); });
}
function cssid(d){ return key(d).replace(/[^a-z0-9]/gi,'-'); }
function esc(s){ return (s||'').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;'); }
function card(d){
  const id=cssid(d); const s=st[key(d)]||{};
  const prod = d.type==='comparison' ? ((d.products||[]).join('  vs  ')) : (d.product||'');
  const price = d.price && d.price!=='omitted' ? d.price : (d.price==='omitted'?'price: omitted':'');
  const winner = d.type==='comparison' && d.winner ? `<span class="pill">winner: ${esc(d.winner)}</span>`:'';
  let opts = (d.options||[]).map((o,i)=>{
    const on = s.choice===i ? ' on':'';
    return `<label class="opt${on}" onclick="pick('${id}',${i})"><input type="radio" name="r-${id}" ${s.choice===i?'checked':''}><span class="v">${esc(o.verdict)}</span><span class="s">${esc(o.supporting||'')}</span></label>`;
  }).join('');
  const ownOn = s.choice==='own';
  opts += `<label class="opt${ownOn?' on':''}" onclick="pick('${id}','own')"><input type="radio" name="r-${id}" ${ownOn?'checked':''}><span class="v">Write my own</span></label>`;
  opts += `<div class="own${ownOn?' show':''}" id="own-${id}">
     <textarea placeholder="Verdict (the call, 1-2 sentences)" oninput="setOwn('${id}','ownV',this.value)">${esc(s.ownV||'')}</textarea>
     <textarea placeholder="Supporting (who it's for / the flip side)" oninput="setOwn('${id}','ownS',this.value)">${esc(s.ownS||'')}</textarea></div>`;
  const flags = (d.flags&&d.flags.length)? `<div class="flags">${d.flags.map(esc).join(' · ')}</div>`:'';
  return `<div class="card${decided(d)?' done':''}" id="card-${id}">
    <p class="tt">${esc(d.title||d.slug)}</p>
    <div class="meta"><span class="pill">${esc(prod)}</span>${winner}${price?`<span class="pill">${esc(price)}</span>`:''}</div>
    <div class="summary">${esc(d.summary||'')}</div>${flags}
    <div class="opts">${opts}</div></div>`;
}
function pick(id,choice){
  const d = DATA.find(x=>cssid(x)===id); if(!d) return;
  st[key(d)] = Object.assign({}, st[key(d)], {choice:choice});
  save();
  // re-render just this card's option states
  document.querySelectorAll(`#card-${id} label.opt`).forEach((l,idx,arr)=>{
    const isOwn = idx===arr.length-1;
    const sel = (choice==='own'&&isOwn) || (choice===idx);
    l.classList.toggle('on', sel);
    const inp=l.querySelector('input'); if(inp) inp.checked=sel;
  });
  const own=document.getElementById('own-'+id); if(own) own.classList.toggle('show', choice==='own');
}
function setOwn(id,field,val){ const d=DATA.find(x=>cssid(x)===id); if(!d)return; st[key(d)]=Object.assign({},st[key(d)],{[field]:val}); save(); }
function buildOutput(){
  const lines=["=== VERDICT DECISIONS (paste back to Claude) ===",""];
  let any=false;
  DATA.forEach(d=>{
    if(!decided(d)) return; any=true;
    const s=st[key(d)];
    let v,sup;
    if(s.choice==='own'){ v=(s.ownV||'').trim(); sup=(s.ownS||'').trim(); }
    else { const o=d.options[s.choice]; v=o.verdict; sup=o.supporting||''; }
    lines.push(">>> "+key(d));
    lines.push("TYPE: "+d.type);
    lines.push("VERDICT: "+v);
    lines.push("SUPPORTING: "+sup);
    lines.push("");
  });
  if(!any) lines.push("(nothing decided yet)");
  return lines.join("\n");
}
function copyDecisions(e){ const t=buildOutput(); navigator.clipboard.writeText(t).then(()=>toast()); }
function showEx(){ document.getElementById('exT').value=buildOutput(); document.getElementById('ex').style.display='flex'; }
function resetAll(){ if(confirm('Clear all your selections?')){ for(const k in st) delete st[k]; save(); render(); } }
function toast(){ const t=document.getElementById('toast'); t.classList.add('show'); setTimeout(()=>t.classList.remove('show'),1400); }
function render(){
  const root=document.getElementById('root'); root.innerHTML='';
  const bySite={};
  DATA.forEach(d=>{ (bySite[d.site]=bySite[d.site]||[]).push(d); });
  const order=["detailerpicks","fussybean","starteraquarium","gameovergear","mywildlifecam"];
  const label={mywildlifecam:"MyWildlifeCam",detailerpicks:"DetailerPicks",fussybean:"FussyBean",starteraquarium:"StarterAquarium",gameovergear:"GameOverGear"};
  order.filter(s=>bySite[s]).forEach(site=>{
    const arr=bySite[site];
    const h=document.createElement('h2'); h.className='site';
    h.textContent=`${label[site]||site} — ${arr.length} draft${arr.length>1?'s':''}`;
    root.appendChild(h);
    const revs=arr.filter(d=>d.type==='review'), cmps=arr.filter(d=>d.type==='comparison');
    if(revs.length){ const g=document.createElement('h3'); g.className='grp'; g.textContent='Reviews — needs a Bottom Line'; root.appendChild(g);
      revs.forEach(d=>{ const w=document.createElement('div'); w.innerHTML=card(d); root.appendChild(w.firstChild); }); }
    if(cmps.length){ const g=document.createElement('h3'); g.className='grp'; g.textContent='Comparisons — needs the winner call'; root.appendChild(g);
      cmps.forEach(d=>{ const w=document.createElement('div'); w.innerHTML=card(d); root.appendChild(w.firstChild); }); }
  });
  renderCount();
}
render();
</script></body></html>
"""

if __name__ == "__main__":
    main()
