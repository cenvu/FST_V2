#!/usr/bin/env python3
"""Render recorded evidence; no experiments, filesystem mounts, or policy acceptance."""
import csv, gzip, hashlib, io, json, pathlib, statistics

ROOT=pathlib.Path(__file__).resolve().parent
PHASES=['matrix','boundaries','adaptive','cluster-corrected','residual']
def digest(b):return hashlib.sha256(b).hexdigest()
def load(phase):
    p=(ROOT if phase=='matrix' else ROOT/phase)/'events.json'
    return json.loads(p.read_bytes() if p.exists() else gzip.decompress(p.with_suffix('.json.gz').read_bytes()))
rows=[];phases={};archive=[]
for phase in PHASES:
    records=load(phase);jobs=[x for x in records if x['kind']=='job'];phases[phase]=dict(
        jobs=len(jobs),success=sum(x['rsync_exit']==0 for x in jobs),failure=sum(x['rsync_exit']!=0 for x in jobs),
        fatal=[x.get('traceback') for x in records if x['kind']=='fatal'],
        cleanup=[x for x in records if x['kind']=='cleanup'],source_safety=[x for x in records if x['kind']=='source_safety'])
    for index,x in enumerate(jobs,1):
        C=x['free_before']['f_frsize'] if x['fs']=='apfs' else next(e['cluster'] for e in records if e['kind']=='exfat_boot')
        R=sum(((f['size']+C-1)//C)*C for f in x['source']['files'])
        directory_floor=(x['source']['D']+1)*C if x['fs']=='exfat' else 0
        temps={a['inode'] for a in x['temp_samples']}
        inode_matches=sum(f['inode'] in temps for f in x['destination']['files'])
        samples=x['samples'];F=x['selected_capacity'];S=x['source'];D=x['destination'];B=x['free_before'];A=x['free_after']
        all_entries=x.get('destination_all_entries');da=x.get('directory_allocations')
        row=dict(phase=phase,job=index,fs=x['fs'],case=x['case'],run=x['run'],point=x['point'] or 'ample',
            image_capacity=x['image_capacity'],f_frsize=B['f_frsize'],statfs_f_bsize=B['statfs_f_bsize'],
            statfs_f_iosize=B['statfs_f_iosize'],statvfs_f_bsize=B['statvfs_f_bsize'],validated_image_unit=C,
            L=S['L'],N=S['N'],D=S['D'],source_allocated=S['allocated'],R_vfs=sum(((f['size']+B['f_frsize']-1)//B['f_frsize'])*B['f_frsize'] for f in S['files']),
            R_cluster=R,recorded_R=S['R'],destination_regular_allocated=D['allocated'],
            destination_all_file_allocated=all_entries['allocated'] if all_entries else None,
            directory_allocated=sum(a['allocated'] for a in da) if da is not None else None,
            ordinary_before=B['ordinary_statvfs'],selected_F=F,important_before=B['NSURLVolumeAvailableCapacityForImportantUsageKey'],
            ordinary_after=A['ordinary_statvfs'],free_delta=B['ordinary_statvfs']-A['ordinary_statvfs'],
            composite_residual=B['ordinary_statvfs']-A['ordinary_statvfs']-D['allocated'],
            target=x['fill']['target'] if x['fill'] else None,
            target_error=x['fill']['actual']-x['fill']['target'] if x['fill'] else None,
            rsync_exit=x['rsync_exit'],hash_integrity=x['integrity'],source_unchanged=x['source_unchanged'],
            observer_final_bytes=x['observer_final_bytes'],observed_temp_names=len(x['temp_names']),rename_inode_matches=inode_matches,
            sampled_peak_regular_allocated=max([s['allocated'] for s in samples]+[D['allocated']]),
            sampled_min_free=min([s['free'] for s in samples]+[A['ordinary_statvfs']]),
            admit_P0_capacity=F>=S['L'],admit_P1_validated_image_C=F>=R,
            admit_P2_directory_lower_floor=F>=R+directory_floor,
            actual_C_runtime_public_api_proven=False if x['fs']=='exfat' else True)
        rows.append(row)
    p=(ROOT if phase=='matrix' else ROOT/phase)/'events.json';z=p.with_suffix('.json.gz')
    data=p.read_bytes() if p.exists() else gzip.decompress(z.read_bytes())
    buffer=io.BytesIO()
    with gzip.GzipFile(filename='',fileobj=buffer,mode='wb',mtime=0) as stream:stream.write(data)
    compressed=buffer.getvalue();z.write_bytes(compressed)
    assert gzip.decompress(compressed)==data
    archive.append(dict(phase=phase,path=str(z.relative_to(ROOT)),compressed_bytes=len(compressed),compressed_sha256=digest(compressed),
                        original_json_bytes=len(data),original_json_sha256=digest(data),lossless_roundtrip=True))
    if p.exists():p.unlink()

with (ROOT/'matrix.csv').open('w',newline='') as f:
    w=csv.DictWriter(f,fieldnames=list(rows[0]));w.writeheader();w.writerows(rows)
summary=dict(task='DESTINATION_CAPACITY_FS_CALIBRATION',phases=phases,total_jobs=len(rows),
             success=sum(r['rsync_exit']==0 for r in rows),failure=sum(r['rsync_exit']!=0 for r in rows),
             success_hashes_all_correct=all(r['hash_integrity'] for r in rows if r['rsync_exit']==0),
             source_manifests_all_unchanged=all(r['source_unchanged'] for r in rows),
             missed_target_jobs=[dict(phase=r['phase'],job=r['job'],fs=r['fs'],case=r['case'],point=r['point'],error=r['target_error']) for r in rows if r['target_error'] is not None and r['target_error']!=0],
             false_admit_counts={},apfs_repeatability={},exfat_residuals=[],archive=archive)
for key in ['admit_P0_capacity','admit_P1_validated_image_C','admit_P2_directory_lower_floor']:
    summary['false_admit_counts'][key]=sum(r[key] and r['rsync_exit']!=0 for r in rows)
    summary.setdefault('observed_false_reject_counts',{})[key]=sum(not r[key] and r['rsync_exit']==0 for r in rows)
for name in ['many_small_1byte','many_small_mixed','sparse_single','sparse_many']:
    rs=[r for r in rows if r['phase']=='matrix' and r['fs']=='apfs' and r['case']==name]
    summary['apfs_repeatability'][name]=dict(runs=len(rs),R=rs[0]['R_cluster'],regular_allocations=[r['destination_regular_allocated'] for r in rs],
                                          snapshot_composite_residuals=[r['composite_residual'] for r in rs])
summary['exfat_residuals']=[r for r in rows if r['phase']=='residual']
(ROOT/'summary.json').write_text(json.dumps(summary,indent=2)+'\n')
(ROOT/'archive-manifest.json').write_text(json.dumps(archive,indent=2)+'\n')

lines=['# Full filesystem matrix','',
       'All bytes are exact observed integers. `R_vfs` uses the public minimum-unit hypothesis; `R_C` uses the image-validated allocation unit. exFAT C is boot-sector research evidence, not a proven production API input.',
       'Peak is sampled regular-file allocation only, excluding generated sidecars and directory metadata. Sampling can miss a transient peak. Capacity/admission columns are capacity-only hypotheses, not existing full preflight or safety decisions.',
       'Missed filler targets are preserved in CSV and summary; they are not exact-target tests. The APFS adaptive bracket records requested targets; actual measurements must be consulted because some intermediate fills missed.', '',
       '| Phase | FS | Case / run / point | L | N | D | R_vfs | R_C | Dest regular A | Free before / after | Exit | Hash | Observer bytes |',
       '|---|---|---|---:|---:|---:|---:|---:|---:|---|---:|---|---:|']
for r in rows:
    lines.append(f"| {r['phase']} | {r['fs']} | {r['case']} / {r['run']} / {r['point']} | {r['L']} | {r['N']} | {r['D']} | {r['R_vfs']} | {r['R_cluster']} | {r['destination_regular_allocated']} | {r['selected_F']} / {r['ordinary_after']} | {r['rsync_exit']} | {r['hash_integrity']} | {r['observer_final_bytes']} |")
lines+=['','## Phase outcomes','']
for phase,p in phases.items():lines.append(f"- {phase}: {p['jobs']} jobs, {p['success']} success, {p['failure']} failures; {len(p['fatal'])} stopped run; cleanup recorded={bool(p['cleanup'])}.")
(ROOT/'MATRIX.md').write_text('\n'.join(lines)+'\n')
print(json.dumps({k:summary[k] for k in ['total_jobs','success','failure','success_hashes_all_correct','source_manifests_all_unchanged','false_admit_counts','observed_false_reject_counts']}))
