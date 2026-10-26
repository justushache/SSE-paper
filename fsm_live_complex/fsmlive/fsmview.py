#!/usr/bin/env python3
"""Live FSM viewer (lab manual Fig. 6 style). Edit JSON, save, browser re-renders.

Usage:  python3 fsmview.py main.json [port]      -> http://localhost:8765
Needs only the Python standard library. Graphviz runs in the browser (viz.js,
from viz-standalone.js next to this script, else the jsdelivr CDN).

JSON
  "include":   ["complex_ops.json", ...]     files with substate definitions
  "substates": { "CMUL": { "params": ["a","b","d"], "states": [...] } }
  "states":    [ { "id", "rt", "flags", "mem", "next" } ]
In substates, write parameters as {a}, {b}, {d}; finish with "next": "RET".
Call a substate from "next" (also inside branches), chains allowed:
  "next": "CMUL o b t BF2"                 NAME <one register per param> RETURN_STATE
  "next": "CMUL o b t CADD u t b IL7"      CMUL, then CADD, then IL7
Groups (drawn as columns that start at the top):
  { "group": "INNER", "col": 1, "states": [ ... ] }   col optional; same col = stacked
  groups may be nested; ungrouped runs of states form their own column
Tab "Transfer table": lab manual Table 2, sources per datapath input (unit + bus),
built from the RT lines "src -> BUS -> dst" with calls expanded.
"""
import sys, os, json, http.server, webbrowser

PATH = os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else "fsm.json")
PORT = int(sys.argv[2]) if len(sys.argv) > 2 else 8765
HERE = os.path.dirname(os.path.abspath(__file__))
VIZ = os.path.join(HERE, "viz-standalone.js")
CDN = "https://cdn.jsdelivr.net/npm/@viz-js/viz@3.11.0/lib/viz-standalone.js"


def collect(path, seen, out):
    """Read path + its includes (recursively). Returns stamp parts."""
    path = os.path.abspath(path)
    if path in seen:
        return
    seen.add(path)
    try:
        with open(path, encoding="utf-8") as f:
            text = f.read()
        out.append({"name": os.path.relpath(path, os.path.dirname(PATH)), "text": text,
                    "mtime": os.path.getmtime(path)})
    except OSError as e:
        out.append({"name": path, "text": None, "error": str(e), "mtime": 0})
        return
    try:
        inc = json.loads(text).get("include", [])
    except Exception:
        return  # syntax error is reported by the browser
    for p in inc:
        collect(os.path.join(os.path.dirname(path), p), seen, out)


PAGE = r"""<!doctype html><html><head><meta charset="utf-8"><title>FSM live</title>
<style>
 body{margin:0;font:13px Arial,sans-serif;background:#fff;color:#222}
 header{display:flex;gap:14px;align-items:center;padding:8px 12px;border-bottom:1px solid #ccd;position:sticky;top:0;background:#fff;flex-wrap:wrap}
 #status{color:#2F5F8F} #err{color:#b00;white-space:pre-wrap;padding:0 12px}
 #out,#tbl{padding:12px;overflow:auto} button,label{font:inherit}
 .tab{border:1px solid #ccd;background:#f4f6fa;padding:3px 10px;cursor:pointer} .tab.on{background:#2F5F8F;color:#fff;border-color:#2F5F8F}
 #tbl table{border-collapse:collapse;margin-top:8px} #tbl td,#tbl th{border:1px solid #333;padding:3px 9px;text-align:center}
 #tbl tr.mux td{background:#63A9E8} #tbl td.dst{font-weight:bold} #tbl .op{font-weight:normal;color:#555;font-size:11px}
 #tbl tr.done td{text-decoration:line-through;color:#888}
</style></head><body>
<header><b id="title">FSM</b><button class="tab" data-tab="graph">State graph</button><button class="tab" data-tab="table">Transfer table</button>
<span id="status">waiting…</span><span style="flex:1"></span>
<label class="graphonly"><input type="checkbox" id="expand"> expand calls</label>
<label class="graphonly"><input type="checkbox" id="stubs"> stubs between groups</label>
<button class="graphonly" onclick="dl()">Save SVG</button></header>
<div id="err"></div><div id="out"></div><div id="tbl"></div>
<script src="/viz.js"></script>
<script>
const esc=s=>String(s).replace(/&/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;").replace(/"/g,"&quot;");
const arr=v=>Array.isArray(v)?v:(v==null||v===""?[]:[v]);
const lines=v=>{const a=arr(v).filter(x=>x!=="");return a.length?a.map(esc).join('<BR ALIGN="LEFT"/>')+'<BR ALIGN="LEFT"/>':' ';};
const subst=(v,m)=>typeof v==="string"?v.replace(/\{(\w+)\}/g,(x,k)=>m&&k in m?m[k]:x):Array.isArray(v)?v.map(x=>subst(x,m)):v;
const short=id=>String(id).split("›").pop();
let C="#2F5F8F", SUBS={}, WARN=[];

function nextList(nx){ if(typeof nx==="string") return [["",nx]]; if(nx&&typeof nx==="object") return Object.entries(nx); return []; }

// "CMUL o b t CADD u t b IL7" -> {calls:[{name,args}], ret} | null
function parseChain(t){
  const k=String(t).trim().split(/\s+/); if(!SUBS[k[0]]) return null;
  const calls=[]; let i=0;
  while(i<k.length&&SUBS[k[i]]){
    const n=(SUBS[k[i]].params||[]).length;
    if(i+n>=k.length){WARN.push(`call "${t}": ${k[i]} needs ${n} registers + return state`);return null;}
    calls.push({name:k[i],args:k.slice(i+1,i+1+n)}); i+=n+1;
  }
  if(i!==k.length-1){WARN.push(`call "${t}": expected exactly one return state at the end`);return null;}
  return {calls,ret:k[i]};
}

// flatten groups -> [{s, path:[group names], top: top-level group index}]
function flatten(states){
  const out=[], groups=[]; let anon=null;
  states.forEach(item=>{
    if(item&&item.group!==undefined&&Array.isArray(item.states)){
      anon=null; const gi=groups.length; groups.push({name:item.group,col:item.col,items:[]});
      (function rec(list,path){ for(const x of list){
        if(x&&x.group!==undefined&&Array.isArray(x.states)) rec(x.states,[...path,x.group]);
        else {const e={s:x,path,top:gi}; out.push(e); groups[gi].items.push(e);} } })(item.states,[item.group]);
    } else {
      if(!anon){anon={name:null,col:undefined,items:[]}; groups.push(anon);}
      const e={s:item,path:[],top:groups.length-1}; out.push(e); anon.items.push(e);
    }
  });
  return {flat:out,groups};
}

// expansion of calls (incl. chains and nested calls inside substates)
function expandList(entries, scope, depth){
  const out=[];
  for(const e of entries){
    const s=e.s, id=scope.prefix+s.id, nn={}, nl=nextList(s.next), sub=[];
    for(const[c,t] of nl) nn[c]=resolve(subst(t,scope.m),scope,id+(c?"["+c+"]":""),e,sub,depth);
    out.push({...e,s:{...s,id,rt:subst(s.rt,scope.m),flags:subst(s.flags,scope.m),mem:subst(s.mem,scope.m),
      next:nl.length===1&&nl[0][0]===""?nn[""]:nn}});
    out.push(...sub);
  }
  return out;
}
function resolve(t,scope,callerId,e,out,depth){
  const ch=parseChain(t);
  if(!ch) return t==="RET"?(scope.ret??"RET"):scope.prefix+t;
  if(depth>8){WARN.push("call depth > 8 (recursion?)");return t;}
  let entry=resolve(ch.ret,scope,callerId,e,out,depth); const blocks=[];
  for(let k=ch.calls.length-1;k>=0;k--){
    const call=ch.calls[k], def=SUBS[call.name], m={};
    (def.params||[]).forEach((p,i)=>m[p]=call.args[i]);
    const p=`${callerId}›${k}${call.name}›`;
    blocks.unshift(expandList(def.states.map(s=>({s,path:e.path,top:e.top})),{prefix:p,ret:entry,m},depth+1));
    entry=p+def.states[0].id;
  }
  for(const b of blocks) out.push(...b);
  return entry;
}

// empty rows of the Fig. 5 box shrink to a thin strip instead of a full text line
const cell=v=>arr(v).filter(x=>x!=="").length?`<TD ALIGN="LEFT" BALIGN="LEFT">${lines(v)}</TD>`:'<TD><FONT POINT-SIZE="2"> </FONT></TD>';
function stateNode(s,nextTxt){
  const mem=s.mem?`<TD BGCOLOR="#4FA3E0" ALIGN="LEFT"><FONT COLOR="white"><B>M</B></FONT> ${esc(s.mem)}</TD>`:cell("");
  const rt=arr(s.rt).filter(x=>x!=="").length?lines(s.rt):'<FONT COLOR="#999999">(no transfer)</FONT>';
  return `"${s.id}"[tooltip="${esc(s.id)}" label=<<TABLE BORDER="0" CELLBORDER="1" CELLSPACING="0" CELLPADDING="2" COLOR="${C}">`+
    `<TR><TD ROWSPAN="4" ALIGN="LEFT" BALIGN="LEFT" WIDTH="150">${rt}</TD>${mem}</TR>`+
    `<TR>${cell(s.flags)}</TR>`+
    `<TR>${cell(nextTxt)}</TR>`+
    `<TR><TD BGCOLOR="#7FFFFF" ALIGN="LEFT" WIDTH="90"><FONT POINT-SIZE="11"><B>${esc(short(s.id))}</B></FONT></TD></TR></TABLE>>];`;
}

function toDot(g,doExpand,stubs){
  C=g.color||"#2F5F8F";
  const head=[`digraph fsm{rankdir=TB;nodesep=0.35;ranksep=0.3;splines=ortho;newrank=true;`,
   `node[shape=plain fontname="Arial" fontsize=10];edge[color="${C}" fontcolor="${C}" fontname="Arial" fontsize=9];`];
  if(!g.states) return defsOnly(head);
  const {flat,groups}=flatten(g.states);
  let entries=doExpand?expandList(flat,{prefix:"",ret:null,m:{}},0):flat;
  const ids=new Set(entries.map(e=>e.s.id)), groupOf=new Map(entries.map(e=>[e.s.id,e.top]));
  const nodes=new Map(), E=[];           // nodes: key -> {dot, path, top}
  const order=[];                        // vertical order = file order (+ call boxes after caller)
  const add=(id,dot,e,seq=true)=>{nodes.set(id,{dot,path:e.path,top:e.top}); if(seq) order.push(id);};
  let pending=0;
  for(const e of entries){
    const s=e.s, txt=[];
    for(const[c,t] of nextList(s.next)){
      txt.push((c?c+": ":"")+(doExpand?short(t):t));
      const ch=doExpand?null:parseChain(t);
      if(ch){
        let prev=s.id, pc=c;
        ch.calls.forEach((call,k)=>{
          const cid=`call:${s.id}:${c}:${k}`, def=SUBS[call.name];
          const bind=(def.params||[]).map((p,i)=>`${p}=${call.args[i]}`).join(", ");
          add(cid,`"${cid}"[shape=box style="rounded,bold" peripheries=2 color="${C}" fontname="Arial" fontsize=10 label="${esc(call.name)}\\n${esc(bind)}\\n(${def.states.length} states)"];`,e);
          groupOf.set(cid,e.top); E.push([prev,cid,pc]); prev=cid; pc=""; pending++;
        });
        E.push([prev,ch.ret,"ret"]);
      } else E.push([s.id,t,c]);
    }
    add(s.id,stateNode(s,txt),e,false);
    order.splice(order.length-pending,0,s.id); pending=0;
  }
  const anchors=[];
  // terminal / unknown targets
  for(const[a,b] of E) if(!nodes.has(b)){
    const e={path:[],top:groupOf.get(a)}; groupOf.set(b,e.top);
    add(b,`"${b}"[shape=box style=rounded color="${C}" fontname="Arial" fontsize=10 label="${esc(short(b))}"];`,e,false);
    anchors.push([a,b]);
  }
  // columns
  let maxc=-1; const colOf=groups.map(gr=>{const c=gr.col!==undefined?gr.col:maxc+1; maxc=Math.max(maxc,c); return c;});
  const body=[];
  // clusters (nested by path) per top group
  const tree={kids:new Map(),nodes:[]};
  for(const[id,n] of nodes){
    let t=tree; const path=n.path.length?n.path:(groups[n.top]&&groups[n.top].name?[groups[n.top].name]:[]);
    path.forEach((p,i)=>{const key=n.top+"/"+path.slice(0,i+1).join("/");
      if(!t.kids.has(key)) t.kids.set(key,{label:p,kids:new Map(),nodes:[]}); t=t.kids.get(key);});
    t.nodes.push(n.dot);
  }
  let ci=0;
  (function emit(t){ body.push(...t.nodes);
    for(const k of t.kids.values()){ body.push(`subgraph cluster_${ci++}{label="${esc(k.label)}";labeljust=l;fontname="Arial";fontsize=12;fontcolor="${C}";color="${C}";style=dashed;`);
      emit(k); body.push("}"); } })(tree);
  // edges
  let si=0;
  for(const[a,b,c] of E){
    const cross=groupOf.get(a)!==groupOf.get(b);
    // ortho routing misplaces xlabels; a tail label stays at the branch state it belongs to
    const lab=c&&c!=="ret"?`taillabel="${esc(c)}" labeldistance=3 labelangle=-70 labelfontsize=9`:"";
    if(cross&&stubs){
      const sid=`stub${si++}`, n=nodes.get(a);
      body.push(`"${sid}"[shape=plaintext fontcolor="${C}" fontname="Arial" fontsize=10 label="→ ${esc(short(b))}"];`);
      body.push(`"${a}"->"${sid}"[${lab}];`);
    } else body.push(`"${a}"->"${b}"[${[lab,"constraint=false"].filter(Boolean).join(",")}];`);
  }
  for(const[a,b] of anchors) body.push(`"${a}"->"${b}"[style=invis];`);
  // sequence chain inside each top group
  const seqOf=gi=>order.filter(id=>nodes.get(id).top===gi);
  groups.forEach((_,gi)=>{const q=seqOf(gi); for(let i=1;i<q.length;i++) body.push(`"${q[i-1]}"->"${q[i]}"[style=invis weight=20];`);});
  // first node of each group; stack groups sharing a column, top groups of columns side by side
  const firstOf=gi=>seqOf(gi)[0]||null, lastOf=gi=>{const q=seqOf(gi);return q[q.length-1]||null;};
  const tops={}, lastInCol={};
  groups.forEach((gr,gi)=>{
    const c=colOf[gi], f=firstOf(gi); if(!f) return;
    if(tops[c]===undefined) tops[c]=gi;
    else body.push(`"${lastOf(lastInCol[c])}"->"${f}"[style=invis weight=20 minlen=2];`);
    lastInCol[c]=gi;
  });
  const firstRow=Object.keys(tops).map(Number).sort((x,y)=>x-y).map(c=>firstOf(tops[c])).filter(Boolean);
  if(firstRow.length>1){
    body.push(`{rank=same;${firstRow.map(x=>`"${x}"`).join(";")}}`);
    for(let i=1;i<firstRow.length;i++) body.push(`"${firstRow[i-1]}"->"${firstRow[i]}"[style=invis];`);
  }
  for(const r of g.same_rank||[]) body.push(`{rank=same;${r.map(x=>`"${x}"`).join(";")}}`);
  return [head.join("\n")+"\n"+body.join("\n")+"}",entries.length];
}

function defsOnly(head){
  const o=[...head]; let i=0, count=0;
  for(const[name,d] of Object.entries(SUBS)){
    if(!d._local) continue;
    o.push(`subgraph cluster_${i++}{label="${esc(name)}(${(d.params||[]).join(", ")})  ·  ${d.states.length} states";fontname="Arial";fontsize=12;color="${C}";style=dashed;`);
    const pre=name+"›";
    for(const s of d.states){
      const nl=nextList(s.next);
      o.push(stateNode({...s,id:pre+s.id},nl.map(([c,t])=>(c?c+": ":"")+t)));
      for(const[c,t] of nl){ const tgt=t==="RET"?pre+"RET":(parseChain(t)?null:pre+t); if(tgt) o.push(`"${pre+s.id}"->"${tgt}"${c?`[xlabel="${esc(c)}"]`:""};`); }
    }
    o.push(`"${pre}RET"[shape=box style=rounded color="${C}" fontname="Arial" fontsize=10 label="RET"];}`);
    count+=d.states.length;
  }
  return [o.join("\n")+"}",count];
}

// lab manual Table 2: sources per datapath input. An input is (unit, bus), calls are always expanded.
// Trailing "(op)" is the operation/mode, not part of the unit: ALU(+) and ALU(-) are one ALU input.
function transferTable(g){
  if(!g.states) return '<p>no "states" - transfer table needs a main FSM</p>';
  const entries=expandList(flatten(g.states).flat,{prefix:"",ret:null,m:{}},0);
  const split=t=>{const m=/^(.*\w)\s*\(([^()]*)\)$/.exec(t); return m?[m[1],m[2]]:[t,null];};
  const rows=new Map(), bad=[];
  for(const e of entries) for(const r of arr(e.s.rt)){
    const line=String(r).trim(); if(!line) continue;
    const p=line.split(/->|→/).map(x=>x.trim());
    if(p.length!==3||p.some(x=>!x)){bad.push(`${short(e.s.id)}: "${line}"`);continue;}
    const [src]=split(p[0]), bus=p[1], [dst,op]=split(p[2].replace(/\s{2,}.*$/,""));
    const key=dst+"\u0000"+bus;
    if(!rows.has(key)) rows.set(key,{dst,bus,ops:new Set(),srcs:new Map()});
    const row=rows.get(key); if(op) row.ops.add(op);
    if(!row.srcs.has(src)) row.srcs.set(src,new Set());
    row.srcs.get(src).add(short(e.s.id));
  }
  if(bad.length) WARN.push("transfer table: unparsed RT lines (expected \"src -> BUS -> dst\"):\n  "+[...new Set(bad)].join("\n  "));
  const R=[...rows.values()], max=Math.max(1,...R.map(r=>r.srcs.size));
  const muxes=R.filter(r=>r.srcs.size>1), mux2=muxes.reduce((n,r)=>n+r.srcs.size-1,0);
  const head=`<tr><th rowspan="2">✓</th><th colspan="${max}">Sources</th><th rowspan="2">Destination</th><th rowspan="2">Bus</th></tr><tr>`+
    Array.from({length:max},(_,i)=>`<th>${i+1}</th>`).join("")+"</tr>";
  // the checkbox only strikes the row through on screen; ticks survive re-renders, not a reload
  const body=R.map(r=>{const k=r.dst+"|"+r.bus, d=DONE.has(k);
    return `<tr class="${r.srcs.size>1?"mux":""}${d?" done":""}"><td><input type="checkbox" data-k="${esc(k)}"${d?" checked":""}></td>`+
    Array.from({length:max},(_,i)=>{const s=[...r.srcs.entries()][i];
      return s?`<td title="${esc([...s[1]].join(", "))}">${esc(s[0])}</td>`:"<td></td>";}).join("")+
    `<td class="dst">${esc(r.dst)}${r.ops.size?` <span class="op">(${esc([...r.ops].join(", "))})</span>`:""}</td><td>${esc(r.bus)}</td></tr>`;}).join("");
  return `<div>${R.length} inputs · ${muxes.length} with &gt;1 source (highlighted) · ${mux2} MUX2 equivalent`+
    `${muxes.length?` · largest MUX${Math.max(...muxes.map(r=>r.srcs.size))}`:""} · hover a source for its states</div>`+
    `<table>${head}${body}</table>`;
}

function showTab(t){
  if(t!=="table") t="graph";
  for(const b of document.querySelectorAll(".tab")) b.classList.toggle("on",b.dataset.tab===t);
  document.getElementById("out").style.display=t==="graph"?"":"none";
  document.getElementById("tbl").style.display=t==="table"?"":"none";
  for(const x of document.querySelectorAll(".graphonly")) x.style.display=t==="graph"?"":"none";
  history.replaceState(null,"","#"+t);
}
const DONE=new Set();
document.getElementById("tbl").addEventListener("change",e=>{const k=e.target.dataset.k; if(k===undefined) return;
  e.target.checked?DONE.add(k):DONE.delete(k); e.target.closest("tr").classList.toggle("done",e.target.checked);});
for(const b of document.querySelectorAll(".tab")) b.onclick=()=>showTab(b.dataset.tab);
showTab(location.hash.slice(1));

let lastStamp=null, lastData=null, viz=null;
async function render(){
  const d=lastData; WARN=[]; SUBS={};
  let main;
  for(const f of d.files){
    if(f.text==null){err("cannot read "+f.name+": "+f.error);return;}
    let j; try{j=JSON.parse(f.text);}catch(e){err(`${f.name}: JSON error: ${e.message}`);return;}
    if(!main) main=j;
    for(const[n,s] of Object.entries(j.substates||{})){
      if(!Array.isArray(s.states)){err(`${f.name}: substate ${n} has no "states"`);return;}
      SUBS[n]={...s,_local:f===d.files[0]};
    }
  }
  if(!main.states&&!Object.keys(main.substates||{}).length){err('no "states" or "substates"');return;}
  viz=viz||await Viz.instance();
  const ex=document.getElementById("expand").checked, st=document.getElementById("stubs").checked;
  let dot,count; try{[dot,count]=toDot(main,ex,st);}catch(e){err("build: "+e.stack);return;}
  let svg; try{svg=viz.renderSVGElement(dot);}catch(e){err("graphviz: "+e);return;}
  document.getElementById("out").replaceChildren(svg);
  try{document.getElementById("tbl").innerHTML=transferTable(main);}catch(e){err("table: "+e.stack);return;}
  document.getElementById("title").textContent=main.title||"FSM";
  document.getElementById("status").textContent=`updated ${new Date().toLocaleTimeString()} · ${count} states${main.states&&!ex?" (calls collapsed)":""}`;
  err([...new Set(WARN)].join("\n"));
}
async function tick(){
  try{
    const d=await (await fetch("/data",{cache:"no-store"})).json();
    if(d.stamp!==lastStamp){lastStamp=d.stamp;lastData=d;await render();}
  }catch(e){err(String(e));}
}
function err(m){document.getElementById("err").textContent=m;}
function dl(){const s=document.querySelector("#out svg");if(!s)return;
  const a=document.createElement("a");a.href=URL.createObjectURL(new Blob([s.outerHTML],{type:"image/svg+xml"}));
  a.download=(document.getElementById("title").textContent||"fsm").replace(/[^\w-]+/g,"_")+".svg";a.click();}
for(const id of ["expand","stubs"]) document.getElementById(id).onchange=()=>lastData&&render();
setInterval(tick,500); tick();
</script></body></html>"""


class H(http.server.BaseHTTPRequestHandler):
    def log_message(self, *a): pass

    def send(self, body, ctype):
        b = body.encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(b)))
        self.end_headers()
        self.wfile.write(b)

    def do_GET(self):
        if self.path.startswith("/viz.js"):
            if os.path.exists(VIZ):
                with open(VIZ, encoding="utf-8") as f:
                    self.send(f.read(), "text/javascript")
            else:
                self.send_response(302); self.send_header("Location", CDN); self.end_headers()
        elif self.path.startswith("/data"):
            files = []
            collect(PATH, set(), files)
            stamp = "|".join(f"{f['name']}:{f['mtime']}" for f in files)
            self.send(json.dumps({"stamp": stamp, "files": files}), "application/json")
        else:
            self.send(PAGE, "text/html; charset=utf-8")


if __name__ == "__main__":
    print(f"watching {PATH} (+ includes)\nopen http://localhost:{PORT}   Ctrl+C to stop")
    try:
        webbrowser.open(f"http://localhost:{PORT}")
    except Exception:
        pass
    http.server.ThreadingHTTPServer(("127.0.0.1", PORT), H).serve_forever()
