#!/usr/bin/env python3
"""Bounded image-only evidence collector. No app imports/changes, no real-volume writes.

Blank fixed-length raw images are exclusively created, hashed, attached WITHOUT
a filesystem, and matched to hdiutil's image-path before newfs is permitted.
All device arguments come from that receipt. No disk identifier is hard-coded.
"""
import argparse, ctypes, fnmatch, hashlib, json, os, pathlib, plistlib, re, shutil
import subprocess, tempfile, time, traceback

REPO = pathlib.Path(__file__).resolve().parents[3]
OUT = pathlib.Path(__file__).resolve().parent
BASE_OUT = OUT
RSYNC = REPO / 'FishSockTransfer/FishSockTransfer/rsync'
EXCLUDES = ['.DS_Store', '._*', '.Spotlight-V100', '.Trashes', '.fseventsd', '.TemporaryItems']
SIZE = 512 * 1024**2
PROBE = REPO / 'build/fs-calibration-probe'
SWIFT_PROBE = REPO / 'build/fs-calibration-runtime-probe'
EVENTS = []
MOUNTS = {}
ROOT = None
LIBC = ctypes.CDLL('/usr/lib/libSystem.B.dylib', use_errno=True)
LIBC.listxattr.restype = ctypes.c_ssize_t
LIBC.getxattr.restype = ctypes.c_ssize_t

def xattrs(path):
    p=os.fsencode(path);n=LIBC.listxattr(p,None,0,0)
    if n<0: raise OSError(ctypes.get_errno(), 'listxattr', str(path))
    names=ctypes.create_string_buffer(n)
    if n: assert LIBC.listxattr(p,names,n,0)==n
    out={}
    for key in names.raw.split(b'\0'):
        if not key:continue
        k=LIBC.getxattr(p,key,None,0,0,0)
        if k<0: raise OSError(ctypes.get_errno(), 'getxattr',str(path))
        buf=ctypes.create_string_buffer(k)
        if k: assert LIBC.getxattr(p,key,buf,k,0,0)==k
        out[os.fsdecode(key)]=hashlib.sha256(buf.raw).hexdigest()
    return out

def save():
    (OUT / 'events.json').write_text(json.dumps(EVENTS, indent=2) + '\n')

def read_events(path):
    if path.exists():return json.loads(path.read_text())
    import gzip
    return json.loads(gzip.decompress(path.with_suffix('.json.gz').read_bytes()))

def event(kind, **kw):
    EVENTS.append(dict(kind=kind, at=time.time(), **kw)); save()

def run(args, check=True):
    p = subprocess.run([str(a) for a in args], capture_output=True, timeout=120)
    if p.returncode and check:
        raise RuntimeError(f'{args}: {p.returncode}: {p.stderr.decode(errors="replace")}')
    return p

def sha(path):
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        for b in iter(lambda: f.read(1024**2), b''): h.update(b)
    return h.hexdigest()

def info():
    return plistlib.loads(run(['hdiutil', 'info', '-plist']).stdout)['images']

def prove(path, dev=None):
    matches = [i for i in info() if pathlib.Path(i['image-path']).resolve() == path.resolve()]
    assert len(matches) == 1, ('image provenance uncertain', path)
    entities = matches[0]['system-entities']
    if dev is not None: assert dev in [e['dev-entry'] for e in entities]
    return entities

def attach(path, label, readonly=False, nomount=False):
    assert path.parent == ROOT and path.is_file() and path.stat().st_size == SIZE
    event('pre_attach_registered_image',image=str(path),sha256=sha(path),size=SIZE,readonly=readonly,nomount=nomount)
    args = ['hdiutil', 'attach', '-plist', '-nobrowse', '-noautoopen', '-imagekey', 'diskimage-class=CRawDiskImage']
    if nomount: args += ['-nomount']
    else:
        mount = ROOT / label; mount.mkdir(exist_ok=True)
        args += ['-mountpoint', mount]
    if readonly: args += ['-readonly']
    args += [path]
    receipt = plistlib.loads(run(args).stdout)
    devices = [e['dev-entry'] for e in receipt['system-entities']]
    whole = next(d for d in devices if re.fullmatch('/dev/disk[0-9]+', d))
    MOUNTS[str(path)] = whole
    entities = prove(path, whole)
    di = plistlib.loads(run(['diskutil', 'info', '-plist', whole]).stdout)
    assert di.get('VirtualOrPhysical') == 'Virtual', di
    event('attach_proven', image=str(path), sha256=sha(path), size=SIZE,
          whole=whole, entities=entities, disk_info=di, readonly=readonly, nomount=nomount)
    if nomount: return whole
    mounted = [e for e in entities if 'mount-point' in e]
    assert len(mounted) == 1 and pathlib.Path(mounted[0]['mount-point']).resolve() == mount.resolve()
    return mount

def detach(path):
    dev = MOUNTS[str(path)]; prove(path, dev)
    for attempt in range(12):
        p=run(['hdiutil', 'detach', dev],check=False)
        if p.returncode==0:break
        event('detach_retry',image=str(path),device=dev,exit=p.returncode,
              stderr=p.stderr.decode(errors='replace'),attempt=attempt+1)
        time.sleep(.5)
    else:
        # Only a proven disposable image; no fallback disk or owner media.
        prove(path,dev)
        run(['hdiutil','detach','-force',dev])
        event('detach_force_disposable_only',image=str(path),device=dev)
    del MOUNTS[str(path)]
    assert not any(pathlib.Path(i['image-path']).resolve() == path.resolve() for i in info())
    event('detached', image=str(path), device=dev)

def blank(fs, label, cluster=None):
    path = ROOT / (label + '.img')
    with open(path, 'xb') as f: f.truncate(SIZE)
    assert path.stat().st_size == SIZE
    event('blank_before_filesystem', image=str(path), sha256=sha(path), size=SIZE,
          exclusive_new_file=True, filesystem=None)
    dev = attach(path, label, nomount=True)
    prove(path, dev)
    cmd = ['/sbin/newfs_apfs', '-v', label, dev] if fs == 'apfs' else ['/sbin/newfs_exfat', '-v', label]
    if fs == 'exfat':
        if cluster: cmd += ['-b', str(cluster)]
        cmd += [dev]
    p = run(cmd, check=False)
    event('filesystem_creation', fs=fs, image=str(path), proven_device=dev, argv=cmd,
          exit=p.returncode, stdout=p.stdout.decode(errors='replace'), stderr=p.stderr.decode(errors='replace'))
    detach(path)
    if p.returncode: return None
    if fs == 'exfat':
        with open(path, 'rb') as f: boot = f.read(512)
        assert boot[3:11] == b'EXFAT   '
        event('exfat_boot', image=str(path), boot_sha256=hashlib.sha256(boot).hexdigest(),
              bytes_per_sector_shift=boot[108], sectors_per_cluster_shift=boot[109],
              cluster=1 << (boot[108] + boot[109]), cluster_count=int.from_bytes(boot[92:96], 'little'))
    return path

def probe(path): return json.loads(run([PROBE, path]).stdout)
def free(path):
    s = os.statvfs(path); return s.f_bavail * s.f_frsize
def roundup(s, c): return ((s+c-1)//c)*c
def excluded(name): return any(fnmatch.fnmatchcase(name, pat) for pat in EXCLUDES)

def scan(path, c, hashes=False, all_entries=False):
    files=[]; dirs=[]
    if not path.exists(): return dict(L=0,N=0,D=0,R=0,allocated=0,files=[],dirs=[])
    for base, ds, ns in os.walk(path):
        if not all_entries: ds[:] = [d for d in ds if not excluded(d)]
        for d in ds: dirs.append(str((pathlib.Path(base)/d).relative_to(path)))
        for n in ns:
            if not all_entries and excluded(n): continue
            p=pathlib.Path(base)/n
            try: s=p.lstat()
            except FileNotFoundError:
                if hashes: raise
                continue  # Temp-to-final rename can race a telemetry scan.
            if not p.is_file() or p.is_symlink(): continue
            row=dict(path=str(p.relative_to(path)), size=s.st_size, allocated=s.st_blocks*512,
                     mode=s.st_mode, mtime_ns=s.st_mtime_ns, inode=s.st_ino)
            if hashes:
                row['sha256']=sha(p)
                row['xattrs']=xattrs(p)
            files.append(row)
    return dict(L=sum(f['size'] for f in files), N=len(files), D=len(dirs),
                R=sum(roundup(f['size'],c) for f in files), allocated=sum(f['allocated'] for f in files),
                files=sorted(files,key=lambda f:f['path']), dirs=sorted(dirs))

def content(p, n, sparse=False):
    p.parent.mkdir(parents=True,exist_ok=True)
    with open(p,'xb') as f:
        if sparse:
            f.write(b'A'*min(n,4096))
            if n>4096: f.seek(n-4096);f.write(b'Z'*4096)
        else:
            block=bytes(range(256))*4096
            while n: b=block[:min(n,len(block))];f.write(b);n-=len(b)

def fixtures(m):
    defs = {
      'ordinary_large_aligned':[16*1024**2], 'ordinary_large_unaligned':[16*1024**2+123],
      'many_small_1byte':[1]*1024, 'many_small_mixed':[0,1,511,4095,4096,4097,8191,8192]*128,
      'zero_length_files':[0]*512, 'nested_many_directories':[1]*256,
      'sparse_single':[128*1024**2], 'sparse_many':[4*1024**2+i*97 for i in range(24)],
      'cinema_like_large_files':[32*1024**2+123]*3,
      'cinema_like_many_frames':[65536+i%19 for i in range(1024)],
      'excluded_entries':[4097], 'mixed_workload':[0,1,4097,8192,8*1024**2+123]*64,
      'near_small':[1]*4096,'near_nested':[1]*128,'near_large':[8*1024**2]
    }
    # Mixed workload bounded to 32 MiB plus small entries (no cinema taxonomy).
    defs['mixed_workload']=[0,1,4097,8192]*64+[8*1024**2+123]*4
    for name,sizes in defs.items():
        d=m/name;d.mkdir()
        for i,n in enumerate(sizes):
            sub=f'b{i:04d}/a/b/c' if name in ('nested_many_directories','near_nested') else ''
            content(d/sub/f'f{i:04d}.bin', n, sparse=name.startswith('sparse'))
        if name == 'nested_many_directories':
            for i in range(128): (d/f'empty{i:04d}/a/b').mkdir(parents=True)
        if name=='excluded_entries':
            for n in EXCLUDES:
                if n=='._*': n='._excluded'
                if n.startswith('.') and n not in ('.DS_Store','._excluded'):
                    content(d/n/'ignored.bin',1024**2)
                else: content(d/n,1024**2)
    d=m/'compressed_source_where_supported';d.mkdir()
    tmp=m/'compression_input'; content(tmp,8*1024**2)
    p=run(['/usr/bin/ditto','--hfsCompression',tmp,d/'f0000.bin'],check=False)
    tmp.unlink()
    event('compression_fixture',exit=p.returncode,probe=probe(d/'f0000.bin'))
    return list(defs) + ['compressed_source_where_supported']

def boundary_fixtures(m):
    definitions={'boundary_small':[8200]*4096,
                 'boundary_nested':[262144]*128,
                 'boundary_large':[32*1024**2]}
    for name,sizes in definitions.items():
        d=m/name;d.mkdir()
        for i,n in enumerate(sizes):
            sub=f'b{i:04d}/a/b/c' if name=='boundary_nested' else ''
            content(d/sub/f'f{i:04d}.bin',n)
    return list(definitions)

def fresh(template, label):
    path=ROOT/(label+'.img');assert not path.exists()
    shutil.copyfile(template,path)
    event('disposable_copy_before_mount',image=str(path),size=path.stat().st_size,sha256=sha(path),
          template=str(template),template_sha256=sha(template))
    return path,attach(path,label)

def fill_to(m, target):
    # Uses real writes ONLY inside the proven 512 MiB image. Never host filler.
    c=os.statvfs(m).f_frsize; p=m/'filler'; assert p.parent==m
    b=bytes(range(256))*4096
    with open(p,'xb') as f:
        for iteration in range(64):
            current=free(m);delta=current-target
            if abs(delta)<=c: break
            if delta>0:
                amount=max(c,(delta//c)*c)
                try:
                    while amount: chunk=b[:min(amount,len(b))];f.write(chunk);amount-=len(chunk)
                    f.flush();os.fsync(f.fileno())
                except OSError as e:
                    if e.errno!=28: raise
                    event('filler_enospc',mount=str(m),target=target,current=free(m))
                    # Release bounded tail and retry; never expand the backing image.
                    f.truncate(max(0,f.tell()-8*1024**2));f.seek(0,2)
            else:
                length=f.seek(0,2);f.truncate(max(0,length+delta));f.seek(0,2)
            time.sleep(.03)
    return dict(target=target,actual=free(m),difference=free(m)-target,unit=c,iterations=iteration+1)

def job(template, src, fs, name, runno=1, target=None, point=None, allocation_unit=None):
    path,m=fresh(template,f'work{len(EVENTS):04d}')
    try:
        c=allocation_unit or os.statvfs(m).f_frsize;source=scan(src,c,hashes=True)
        fill=fill_to(m,target) if target is not None else None
        before=probe(m);assert not (m/src.name).exists()
        argv=[str(RSYNC),'-a','-h','--info=name1,progress2','--outbuf=N']+[f'--exclude={e}' for e in EXCLUDES]+[str(src),str(m)+'/']
        stdout=ROOT/'stdout';stderr=ROOT/'stderr';samples=[];temp_names=set();temp_pairs=[]
        with stdout.open('wb') as so,stderr.open('wb') as se:
            proc=subprocess.Popen(argv,stdout=so,stderr=se);start=time.monotonic()
            while proc.poll() is None:
                if time.monotonic()-start>90: proc.kill();raise RuntimeError('bounded rsync timeout')
                dest=scan(m/src.name,c)
                tm=[f for f in dest['files'] if f['path'].split('/')[-1].startswith('.')]
                temp_names.update(f['path'] for f in tm)
                for t in tm:
                    temp_pairs.append(dict(path=t['path'],inode=t['inode'],allocated=t['allocated'],size=t['size']))
                samples.append(dict(t=time.monotonic()-start,free=free(m),allocated=dest['allocated'],logical=dest['L'],temps=len(tm)))
                time.sleep(.005)
        after=probe(m);dest=scan(m/src.name,c,hashes=True)
        directory_allocations=[]
        jobroot=m/src.name
        if jobroot.exists():
            for dirname in ['']+dest['dirs']:
                dp=jobroot/dirname;ds=dp.stat()
                directory_allocations.append(dict(path=dirname,size=ds.st_size,allocated=ds.st_blocks*512))
        bypath={f['path']:f for f in dest['files']}
        integrity=all(f['path'] in bypath and bypath[f['path']]['sha256']==f['sha256'] for f in source['files']) and set(bypath)==set(f['path'] for f in source['files'])
        if proc.returncode==0: assert integrity and dest['dirs']==source['dirs']
        observer=min(source['L'],dest['L'])
        ap=probe(m/src.name/dest['files'][0]['path']) if dest['files'] else None
        selected=before.get('NSURLVolumeAvailableCapacityForImportantUsageKey')
        if selected is None or selected<=0: selected=before.get('NSURLVolumeAvailableCapacityKey')
        runtime=json.loads(run([SWIFT_PROBE,src,m,str(selected if selected is not None else -1)]).stdout)
        assert runtime['logical']==source['L'] and runtime['files']==source['N'] and runtime['folders']==source['D']
        assert runtime['observer_final_bytes']==observer
        row=dict(kind='job',fs=fs,case=name,run=runno,point=point,image=str(path),image_capacity=SIZE,
          source=source,destination=dest,free_before=before,free_after=after,fill=fill,
          argv=argv,rsync_exit=proc.returncode,stderr=stderr.read_text(errors='replace'),
          stdout_tail=stdout.read_text(errors='replace')[-1800:],integrity=integrity,
          observer_final_bytes=runtime['observer_final_bytes'],observer_method='Actual unchanged DestinationActivitySnapshotter; no safety authority',
          runtime=runtime,
          selected_capacity=selected,admit_P0=selected is not None and selected>=source['L'],
          admit_P1=selected is not None and selected>=source['R'],
          regular_allocation_minus_R=dest['allocated']-source['R'],samples=samples,
          temp_names=sorted(temp_names),temp_samples=temp_pairs,
          foundation_file_allocation_sample=ap,source_unchanged=scan(src,c,hashes=True)==source)
        row['directory_allocations']=directory_allocations
        row['rounding_unit']=c
        row['unit_provenance']='image boot sector (research only)' if allocation_unit else 'statvfs.f_frsize hypothesis'
        row['destination_all_entries']=scan(m/src.name,c,hashes=False,all_entries=True)
        assert row['source_unchanged']
        EVENTS.append(row);save()
        print(json.dumps({k:row[k] for k in ['fs','case','run','point','rsync_exit','integrity','selected_capacity','regular_allocation_minus_R']}),flush=True)
        return row
    finally:
        detach(path);path.unlink()

def main():
    global ROOT,OUT
    parser=argparse.ArgumentParser();parser.add_argument('--matrix-only',action='store_true')
    parser.add_argument('--boundaries-only',action='store_true')
    parser.add_argument('--adaptive-only',action='store_true')
    parser.add_argument('--cluster-corrected',action='store_true')
    parser.add_argument('--residual-only',action='store_true')
    parser.add_argument('--output-dir');args=parser.parse_args()
    if args.output_dir:
        OUT=(REPO/args.output_dir).resolve()
        assert BASE_OUT==OUT or BASE_OUT in OUT.parents
        OUT.mkdir(parents=True,exist_ok=True)
    assert 'version 3.4.4' in run([RSYNC,'--version']).stdout.decode()
    host=shutil.disk_usage('/tmp');assert host.free>8*SIZE
    ROOT=pathlib.Path(tempfile.mkdtemp(prefix='FST-FS-Calibration-',dir='/tmp'))
    event('startup',repo=str(REPO),root=str(ROOT),host_free=host.free,bounded_image_bytes=SIZE,
          max_concurrent_images=3,rsync_sha256=sha(RSYNC),rsync_version=run([RSYNC,'--version']).stdout.decode())
    run(['xcrun','clang','-fobjc-arc','-framework','Foundation',BASE_OUT/'probe.m','-o',PROBE])
    swift_dir=REPO/'build/fs-calibration-swift';swift_dir.mkdir(exist_ok=True)
    engine=REPO/'FishSockTransfer/FishSockTransfer/Engines/RsyncEngine.swift'
    engine_text=engine.read_text()
    snippet=engine_text[engine_text.index('nonisolated struct DestinationActivitySample:'):engine_text.index('nonisolated private struct RsyncCopyTimingState')]
    (swift_dir/'Observer.swift').write_text('import Foundation\n'+snippet)
    (swift_dir/'Runner.swift').write_text('''import Foundation
@main struct Runner {
 static func main() async throws {
  let src=URL(fileURLWithPath:CommandLine.arguments[1]);let dst=URL(fileURLWithPath:CommandLine.arguments[2])
  let m=try await DriveService().sourceMetadata(for:src)
  let obs=try DestinationActivitySnapshotter.snapshot(destinationRootURL:dst.appendingPathComponent(src.lastPathComponent),totalBytes:m.totalSizeBytes,totalFiles:m.fileCount,copyStartedAt:Date(),previousSamples:[]).snapshot
  var admit=true;var errorText=""
  do { _ = try TransferPreflightValidator.validate(source:src,destination:dst,sourceMetadata:m,destinationFreeSpaceBytes:Int64(CommandLine.arguments[3])) } catch { admit=false;errorText=String(describing:error) }
  let obj:[String:Any]=["logical":m.totalSizeBytes,"files":m.fileCount,"folders":m.folderCount,"observer_final_bytes":obs.copiedBytes,"preflight_after_copy":admit,"preflight_after_copy_error":errorText]
  print(String(data:try JSONSerialization.data(withJSONObject:obj,options:.sortedKeys),encoding:.utf8)!)
 }
}
''')
    production=[REPO/'FishSockTransfer/FishSockTransfer'/p for p in ['Services/DriveService.swift','Models/StorageMetadata.swift','Models/TransferFileExclusionPolicy.swift','Engines/TransferEvent.swift']]
    run(['xcrun','swiftc','-parse-as-library',*production,swift_dir/'Observer.swift',swift_dir/'Runner.swift','-o',SWIFT_PROBE])
    event('runtime_probe',production_sources={str(p.relative_to(REPO)):sha(p) for p in production},
          engine_sha256=sha(engine),exact_observer_snippet_sha256=hashlib.sha256(snippet.encode()).hexdigest(),
          generated_files='repo-ignored build only; no Swift production/test mutation')
    try:
        source_image=blank('apfs','source')
        assert source_image
        sm=attach(source_image,'source');names=boundary_fixtures(sm) if args.boundaries_only or args.adaptive_only or args.cluster_corrected or args.residual_only else fixtures(sm);detach(source_image)
        source_sha=sha(source_image);sm=attach(source_image,'source',readonly=True)
        assert probe(sm)['read_only']
        source_manifest={n:scan(sm/n,4096,hashes=True,all_entries=True) for n in names}
        filesystem_set=[('exfat',None)] if args.cluster_corrected or args.residual_only else ([('apfs',None)] if args.adaptive_only else [('apfs',None),('exfat',None)])
        for fs,cl in filesystem_set:
            template=blank(fs,'base'+fs,cl)
            if not template: event('not_executed',fs=fs,reason='platform filesystem creation failed');continue
            for name in ([] if args.boundaries_only or args.adaptive_only or args.cluster_corrected or args.residual_only else names):
                if name.startswith('near_'):continue
                repeat=5 if fs=='apfs' and name in ('many_small_1byte','many_small_mixed','sparse_single','sparse_many') else 1
                for k in range(repeat):job(template,sm/name,fs,name,k+1)
            if not args.matrix_only:
                for name in (names if args.boundaries_only or args.adaptive_only or args.cluster_corrected or args.residual_only else ['near_small','near_nested','near_large']):
                    # Unit comes from a proven mount, not preferred I/O.
                    p,m=fresh(template,'unitprobe');c=os.statvfs(m).f_frsize;detach(p);p.unlink()
                    if args.cluster_corrected or args.residual_only:
                        with open(template,'rb') as f:boot=f.read(512)
                        assert boot[3:11]==b'EXFAT   '
                        c=1 << (boot[108]+boot[109])
                    s=scan(sm/name,c);L=s['L'];R=s['R']
                    if args.residual_only:
                        ample=job(template,sm/name,fs,name,point='ample_residual_measurement',allocation_unit=c)
                        observed=ample['free_before']['ordinary_statvfs']-ample['free_after']['ordinary_statvfs']
                        event('measured_residual_search_input',fs=fs,case=name,R=R,observed_final_free_delta=observed,
                              observed_residual=observed-R,production_constant=False)
                        for offset in [-1,0,1,2]:
                            job(template,sm/name,fs,name,target=observed+offset*c,
                                point=f'observed_final_cost{offset:+d}_clusters',allocation_unit=c)
                        continue
                    if args.adaptive_only:
                        # Search points derived from observed allocator residual;
                        # doubling/bisection is search control, never policy slack.
                        previous=read_events(OUT.parent/'boundaries/events.json')
                        measured=next(e for e in previous if e['kind']=='job' and e['fs']==fs and e['case']==name and e['point']=='R')
                        residual=min(a['free'] for a in measured['samples'])
                        low=R;high=R+roundup(2*residual,c)
                        row=job(template,sm/name,fs,name,target=high,point='R+twice_observed_ENOSPC_free_probe')
                        for k in range(3):
                            if row['rsync_exit']==0:break
                            low=high;high=R+2*(high-R)
                            row=job(template,sm/name,fs,name,target=high,point=f'adaptive_expand_{k}')
                        assert row['rsync_exit']==0
                        for k in range(5):
                            mid=((low+high)//(2*c))*c
                            row=job(template,sm/name,fs,name,target=mid,point=f'adaptive_bisect_{k}')
                            if row['rsync_exit']==0:high=mid
                            else:low=mid
                        event('observed_boundary_bracket',fs=fs,case=name,last_failed_target=low,first_success_target=high,
                              width=high-low,unit=c,universal_guarantee=False,derivation='measured_ENOSPC_free_then_bisection')
                        continue
                    points=[('L-epsilon',max(0,L-c)),('L',L),('R-epsilon',max(0,R-c)),('R',R),('R+small_residual',R+c)]
                    # exFAT directories require >=one cluster each; APFS remains
                    # uncertain. Additional points measure, never promote constants.
                    mech=R+(s['D']+1)*c
                    points += [('R+directory_clusters',mech),('R+directory_clusters+entry_cluster',mech+c),('R+1MiB_probe',R+1024**2)]
                    for point,target in points:job(template,sm/name,fs,name,target=target,point=point,allocation_unit=c if args.cluster_corrected else None)
            template.unlink()
        after_manifest={n:scan(sm/n,4096,hashes=True,all_entries=True) for n in names}
        assert after_manifest==source_manifest
        detach(source_image);assert sha(source_image)==source_sha
        event('source_safety',read_only_entire_rsync_phase=True,manifest_before_equals_after=True,
              image_sha256_before_equals_after=True,sha256=source_sha)
    except Exception:
        event('fatal',traceback=traceback.format_exc());raise
    finally:
        for p in list(MOUNTS):detach(pathlib.Path(p))
        remaining=[i['image-path'] for i in info() if str(ROOT) in i['image-path']]
        assert not remaining
        shutil.rmtree(ROOT)
        event('cleanup',all_test_mounts_detached=True,root_removed=not ROOT.exists(),remaining_test_images=remaining)

if __name__=='__main__':main()
