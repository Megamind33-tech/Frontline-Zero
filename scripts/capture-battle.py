#!/usr/bin/env python3
"""Capture a real rendered battle, sampling process RSS outside Godot/procfs FileAccess."""
import argparse, json, os, pathlib, re, subprocess, time
root=pathlib.Path(__file__).resolve().parents[1]
args=argparse.ArgumentParser()
args.add_argument('--benchmark',action='store_true')
options=args.parse_args()
os.chdir(root)
env=os.environ.copy()
for key,part in [('XDG_DATA_HOME','data'),('XDG_CONFIG_HOME','config'),('XDG_CACHE_HOME','cache')]:
 env[key]=str(root/'.tools/capture-profile'/part)
command=['bash','scripts/render-host.sh']
if options.benchmark:command+=['--max-fps','60']
else:command+=['--fixed-fps','30','--write-movie',str(root/'dist/IRON_CROSSING-gameplay.avi')]
command+=['--script','tests/battle_capture.gd']
if options.benchmark:command+=['--','--benchmark']
log=root/'dist'/('battle-host-render.log' if options.benchmark else 'battle-movie.log')
peak_kb=0
started=time.monotonic()
def descendants(pid):
 try:children=[int(p) for p in pathlib.Path(f'/proc/{pid}/task/{pid}/children').read_text().split()]
 except (OSError,ValueError):return []
 return children+[p for child in children for p in descendants(child)]
with log.open('w') as stream:
 process=subprocess.Popen(command,stdout=stream,stderr=subprocess.STDOUT,env=env)
 while process.poll() is None:
  for pid in descendants(process.pid):
   try:
    if 'godot' not in pathlib.Path(f'/proc/{pid}/comm').read_text().lower():continue
    status=pathlib.Path(f'/proc/{pid}/status').read_text()
    match=re.search(r'^VmHWM:\s+(\d+) kB',status,re.M)
    if match:peak_kb=max(peak_kb,int(match.group(1)))
   except OSError:pass
  time.sleep(.5)
 if process.returncode:raise SystemExit(f'Render failed ({process.returncode}); inspect {log}')
text=log.read_text()
if re.search(r'SCRIPT ERROR:|^ERROR:',text,re.M):raise SystemExit(f'Render error; inspect {log}')
report=root/'dist'/('IRON_CROSSING-host-performance.json' if options.benchmark else 'IRON_CROSSING-movie-evidence.json')
data=json.loads(report.read_text())
data['process_rss_peak_mib']=peak_kb/1024 if peak_kb else None
data['rss_sampling']='external /proc process-tree sampling at 0.5 s; Godot process VmHWM'
data['host_elapsed_seconds']=round(time.monotonic()-started,3)
report.write_text(json.dumps(data,indent=2)+'\n')
print(json.dumps(data,indent=2))
