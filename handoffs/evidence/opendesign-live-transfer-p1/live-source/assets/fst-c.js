/* FST design fixtures only. No filesystem, transfer engine, hashing or network access. */
(() => {
  'use strict';
  const $ = id => document.getElementById(id);
  const esc = value => String(value ?? '').replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
  const paths = {
    drive: '<rect x="3" y="4" width="18" height="16" rx="2"/><path d="M3 14h18M7 17h.01M11 17h.01"/>',
    folder: '<path d="M3 7V5a2 2 0 0 1 2-2h5l2 3h7a2 2 0 0 1 2 2v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V7Z"/>',
    close: '<path d="m6 6 12 12M18 6 6 18"/>',
    check: '<path d="m5 12 4 4L19 6"/>',
    lock: '<rect x="5" y="10" width="14" height="11" rx="2"/><path d="M8 10V7a4 4 0 0 1 8 0v3M12 14v3"/>',
    arrow: '<path d="M5 12h14m-5-5 5 5-5 5"/>',
    play: '<path d="m8 5 11 7-11 7V5Z"/>',
    stop: '<rect x="6" y="6" width="12" height="12" rx="1"/>',
    retry: '<path d="M20 7v5h-5M20 12a8 8 0 1 0-2 6"/>',
    inspect: '<rect x="3" y="4" width="18" height="16" rx="2"/><path d="M15 4v16M18 8h.01M18 12h.01"/>',
    file: '<path d="M13 3H6a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V10l-7-7Z"/><path d="M13 3v7h7M8 14h8M8 17h5"/>',
    shield: '<path d="M12 3 4 6v6c0 5 8 9 8 9s8-4 8-9V6l-8-3Z"/><path d="m8 12 3 3 5-6"/>'
  };
  const icon = name => `<svg class="icon" viewBox="0 0 24 24" aria-hidden="true">${paths[name] || paths.file}</svg>`;
  const sources = [
    {id:'a001', name:'A001', path:'/Volumes/CAMERA_A/A001', bytes:98.2, files:124, folders:8, readOnly:true, current:'A001_C014_0930.mov'},
    {id:'dng', name:'B001_CinemaDNG', path:'/Volumes/CAMERA_B/B001_CinemaDNG', bytes:384, files:48000, folders:12, readOnly:true, current:'B001_Sequence_012/B001_012_0020160.dng', dng:true}
  ];
  const destinations = [
    {id:'offload', name:'OFFLOAD_01', path:'/Volumes/OFFLOAD_01/PROJECT/SHOOT_DAY_01', free:1400, filesystem:'APFS', writable:true},
    {id:'backup', name:'BACKUP_02', path:'/Volumes/BACKUP_02/PROJECT/SHOOT_DAY_01', free:2000, filesystem:'exFAT', writable:true},
    {id:'workspace', name:'WORKSPACE', path:'/Volumes/WORKSPACE/PROJECT/SHOOT_DAY_01', free:24, filesystem:'APFS', writable:true}
  ];
  const supportedScenarios = new Set(['ready','validating','copying','verifying','transfer-complete','safe-to-eject','manual-check','transfer-error','cancelled','warning','blocked-storage','inspector-open','long-paths','high-file-count','estimating','refreshed-eta','eta-unavailable','source-unavailable','destination-unavailable','destination-read-only','invalid-paths','preflight-error','rsync-error']);
  const requested = new URLSearchParams(location.search).get('scenario') || 'ready';
  const scenario = supportedScenarios.has(requested) ? requested : 'ready';
  const model = {
    tab:'transfer', source:{...sources[0]}, destination:{...destinations[0]}, bandwidth:'150', verification:'full',
    state:'ready', progress:0, eta:null, speed:0, elapsed:0, copyElapsed:0, verifyElapsed:0, endedPhase:null, errorCode:'', copyPassed:false, verifyPassed:false,
    inspector:scenario === 'inspector-open', diagnostics:false, autoScroll:true, logs:[], error:'', warning:'',
    running:false, timer:null, scroll:{transfer:0,notification:0,logs:0}, notification:{enabled:false,token:'',chatID:'',interval:'15',detail:'Standard',job:true,heartbeat:true,fail:true,copy:true,verify:true},
    formErrors:{}, testing:false, lastPreview:'No messages sent', selectedFolder:null
  };
  const terminal = () => ['copyComplete','safeToFormat','error','cancelled'].includes(model.state);
  const locked = () => ['validating','copying','verifying'].includes(model.state);
  const hasSpace = () => !storageProblem();
  const safeToEject = () => model.state === 'safeToFormat' && model.copyPassed && model.verifyPassed && model.verification !== 'none';
  const size = gb => gb >= 1000 ? `${(gb / 1000).toFixed(2)} TB` : `${gb.toFixed(1)} GB`;
  const count = n => Number(n).toLocaleString('en-US');
  const elapsed = seconds => {
    const n = Math.max(0, Math.floor(seconds));
    const mm = String(Math.floor(n / 60) % 60).padStart(2, '0');
    const ss = String(n % 60).padStart(2, '0');
    return n >= 3600 ? Math.floor(n / 3600) + ':' + mm + ':' + ss : mm + ':' + ss;
  };
  const modeLabel = () => ({none:'NONE',random33:'SAMPLE 33% — SHA256',full:'FULL 100% — xxHash64'})[model.verification];
  function storageProblem() {
    const s = model.source, d = model.destination;
    if (!s) return 'Select a source folder';
    if (!d) return 'Select a destination folder';
    if (s.available === false) return 'Source unavailable — reconnect source';
    if (d.available === false) return 'Destination unavailable — reconnect destination';
    if (!d.writable) return 'Destination is read-only — choose a writable destination';
    const a = s.path.replace(/\/+$/, ''), b = d.path.replace(/\/+$/, '');
    if (a === b || b.startsWith(a + '/') || a.startsWith(b + '/')) return 'Invalid folder combination — choose separate folders';
    if (d.free < s.bytes) return 'Insufficient destination space — choose a larger destination';
    return '';
  }
  function addLog(level, message, diagnostic = false) {
    model.logs.push({time:elapsed(model.elapsed),level,message,diagnostic});
  }
  function seedScenario() {
    if (scenario === 'high-file-count') model.source = {...sources[1]};
    if (scenario === 'long-paths') {
      model.source.path = '/Volumes/CAMERA_A/PRODUCTION_2026/UNIT_A/DAY_014/ORIGINAL_CAMERA_MEDIA/SCENE_127/TAKE_004/A001';
      model.destination.path = '/Volumes/OFFLOAD_01/PRODUCTION_2026/DELIVERY/EDITORIAL/ORIGINAL_CAMERA_MEDIA/UNIT_A/DAY_014/CAMERA_A';
    }
    if (scenario === 'blocked-storage') model.destination = {...destinations[2]};
    if (scenario === 'source-unavailable') model.source.available = false;
    if (scenario === 'destination-unavailable') model.destination.available = false;
    if (scenario === 'destination-read-only') model.destination.writable = false;
    if (scenario === 'invalid-paths') model.destination.path = model.source.path + '/OFFLOAD';
    if (scenario === 'warning') {
      model.destination.free = 115;
      model.warning = 'Limited headroom: 16.8 GB estimated after copy. Confirm capacity for the next offload.';
    }
    const copyDuration = model.source.bytes * 1000 / 142.7;
    const verifyDuration = model.source.bytes * 1000 / 496;
    if (['copying','estimating','refreshed-eta','eta-unavailable','high-file-count'].includes(scenario)) {
      Object.assign(model, {state:'copying',progress:42,speed:148.6,copyElapsed:copyDuration * .42});
    }
    if (scenario === 'estimating') {
      model.copyElapsed = 35; model.progress = 142.7 * 35 / (model.source.bytes * 1000) * 100; model.eta = 'Calculating…';
    }
    if (scenario === 'refreshed-eta') { model.speed = 192.4; model.bandwidth = '200'; }
    if (scenario === 'eta-unavailable') model.eta = '—';
    if (scenario === 'verifying') Object.assign(model, {state:'verifying',copyPassed:true,progress:64,speed:512.8,copyElapsed:copyDuration,verifyElapsed:verifyDuration * .64});
    if (scenario === 'validating') model.state = 'validating';
    if (scenario === 'transfer-complete') Object.assign(model, {state:'copyComplete',verification:'none',copyPassed:true,progress:100,copyElapsed:copyDuration});
    if (scenario === 'safe-to-eject') Object.assign(model, {state:'safeToFormat',copyPassed:true,verifyPassed:true,progress:100,copyElapsed:copyDuration,verifyElapsed:verifyDuration});
    if (scenario === 'manual-check') Object.assign(model, {state:'error',copyPassed:true,progress:64,copyElapsed:copyDuration,verifyElapsed:verifyDuration * .64,error:'Copy finished. Verification found a mismatch in A001_C014_0930.mov. Keep the source media and review the log before handoff.'});
    if (scenario === 'transfer-error') {model.destination.available = false; model.endedPhase = 'Copy'; model.errorCode = 'DESTINATION_UNAVAILABLE';}
    if (scenario === 'manual-check') {model.endedPhase = 'Verification'; model.errorCode = 'VERIFY_MISMATCH';}
    if (scenario === 'transfer-error') Object.assign(model, {state:'error',progress:42,copyElapsed:copyDuration * .42,error:'Destination disconnected during copy. Reconnect OFFLOAD_01 and review the log before retrying. The job did not complete.'});
    if (scenario === 'cancelled') Object.assign(model, {state:'cancelled',progress:42,copyElapsed:copyDuration * .42});
    if (scenario === 'preflight-error') {
      model.destination.writable = false;
      Object.assign(model, {state:'error',endedPhase:'Preflight',errorCode:'READINESS_FAILED',error:'Preflight failed: destination is read-only. Choose a writable destination and review the technical log.'});
    }
    if (scenario === 'rsync-error') Object.assign(model, {state:'error',endedPhase:'Copy · rsync',errorCode:'RSYNC_FAILURE',progress:42,copyElapsed:copyDuration * .42,error:'rsync reported an incomplete copy. Keep the source media and review the technical log before retrying.'});
    model.elapsed = model.copyElapsed + model.verifyElapsed;
    addLog('SYSTEM', 'Design fixture only. No transfer, hash, filesystem write or notification is executed.');
    addLog('INFO', 'Source selected: ' + model.source.path);
    addLog('INFO', 'Destination selected: ' + model.destination.path);
    addLog('DIAG', 'Sample data is held in browser memory; no source volume is accessed.', true);
    if (model.state === 'copying') addLog('TRANSFER', 'Copy phase: ' + Math.round(model.progress) + '%. Keep source connected.');
    if (model.state === 'verifying') { addLog('TRANSFER', 'Fixture copy passed.'); addLog('VERIFY', modeLabel() + ': ' + model.progress + '%.'); }
    if (safeToEject()) { addLog('TRANSFER', 'Fixture copy passed.'); addLog('VERIFY', 'Fixture verification passed. Copy and verification succeeded.'); }
    if (model.state === 'copyComplete') addLog('TRANSFER', 'TRANSFER COMPLETE. Verification disabled. Copy-only completion.');
    if (model.state === 'error') {
      addLog('ERROR', model.error);
      addLog('DIAG', model.errorCode + ' · Failed during ' + (model.endedPhase || (model.copyPassed ? 'Verification' : 'Copy')), true);
    }
    if (model.state === 'cancelled') addLog('WARNING', 'CANCELLED. The operation did not complete. Keep the source media.');
    if (model.warning) addLog('WARNING', model.warning);
  }
  function statePresentation() {
    if (model.state === 'error') return {title:model.copyPassed?'MANUAL CHECK REQUIRED':'TRANSFER ERROR',help:model.copyPassed?'Copy finished. Verification did not pass. Keep the source media.':'Copy did not finish. Review the issue and technical log.',tone:model.copyPassed?'warning':'error'};
    if (model.state === 'safeToFormat') return safeToEject()
      ? {title:'SAFE TO EJECT',help:'Copy passed · Verification passed · ' + modeLabel(),tone:'success'}
      : {title:'MANUAL CHECK REQUIRED',help:'A verified result has not been established. Keep the source media.',tone:'warning'};
    return ({
      ready:{title:hasSpace()?'Ready to transfer':'Setup required',help:hasSpace()?'Source and destination selected.':storageProblem(),tone:'neutral'},
      validating:{title:'VALIDATING',help:'Checking source and destination. Keep media connected.',tone:'active'},
      copying:{title:'COPYING',help:'Copy in progress. Keep source and destination connected.',tone:'active'},
      verifying:{title:'VERIFYING',help:'Copy completed. ' + modeLabel() + ' is active.',tone:'verify'},
      copyComplete:{title:'TRANSFER COMPLETE',help:'Copy completed. Verification was disabled; no hash check was performed.',tone:'complete'},
      cancelled:{title:'CANCELLED',help:'The job did not complete. Keep the source media.',tone:'warning'}
    })[model.state];
  }
  const btn = (action,label,type='ghost',glyph='',extra='') => `<button type="button" class="button ${type}" data-action="${action}" ${extra}>${glyph?icon(glyph):''}${label}</button>`;
  function endpoint(which) {
    const item = model[which], isSource = which === 'source', title = isSource ? 'Source' : 'Destination';
    let facts = '';
    if (item) {
      const parts = isSource ? [size(item.bytes), count(item.files) + ' files', item.readOnly ? 'Read-only' : ''] : [size(item.free) + ' free', item.writable ? 'Writable' : 'Read-only'];
      if (item.available === false) parts.push('Unavailable');
      facts = parts.filter(Boolean).map(p => '<span class="' + (p === 'Unavailable' || (!isSource && p === 'Read-only') ? 'unavailable' : '') + '">' + esc(p) + '</span>').join('<span class="fact-separator" aria-hidden="true">·</span>');
    }
    return '<section class="endpoint od-row" aria-label="' + title + '"><div class="endpoint-label od-field"><h2>' + title + '</h2></div><div class="endpoint-info od-field od-fill">' +
      '<div class="endpoint-summary od-row"><strong class="endpoint-name">' + (item ? esc(item.name) : 'Select ' + title.toLowerCase()) + '</strong><div class="endpoint-facts od-cluster">' + facts + '</div></div>' +
      (item ? '<button type="button" class="path-button" data-action="inspect-' + which + '" aria-label="Show full ' + which + ' path"><span class="od-truncate">' + esc(item.path) + '</span></button>' : '<span class="caption">Choose a folder to continue.</span>') +
      '</div><div class="endpoint-actions od-fixed">' + btn('choose-' + which, item ? 'Change' : 'Choose', 'ghost', '', locked() ? 'disabled' : '') +
      '<button type="button" class="button ghost icon-button" data-action="clear-' + which + '" aria-label="Clear ' + which + ' selection" ' + (!item || locked() ? 'disabled' : '') + '>' + icon(locked() ? 'lock' : 'close') + '</button></div></section>';
  }
  function readiness() {
    const problem = storageProblem(), selected = !!(model.source && model.destination);
    const facts = selected ? '<div class="readiness-facts od-cluster"><span>' + size(model.source.bytes) + ' required</span><span>' + size(model.destination.free) + ' free</span>' + (!problem ? '<span>' + size(model.destination.free - model.source.bytes) + ' estimated after copy</span>' : '') + '</div>' : '';
    return '<div class="readiness ' + (problem && selected ? 'not-ready' : '') + '" role="status">' + icon(problem ? 'lock' : 'check') + '<span class="readiness-value ' + (problem && selected ? 'blocked' : '') + '">' + esc(problem || 'Storage ready') + '</span>' + facts + '</div>';
  }
  function setup() {
    const disabled = locked() ? 'disabled' : '';
    const bandwidth = ['50','75','100','125','150','175','200','Unlimited'].map(v => '<option value="' + v + '" ' + (v === model.bandwidth ? 'selected' : '') + '>' + (v === 'Unlimited' ? v : v + ' MB/s') + '</option>').join('');
    const modes = [['none','NONE'],['random33','SAMPLE 33% — SHA256'],['full','FULL 100% — xxHash64']];
    const options = modes.map(([v,t]) => '<option value="' + v + '" ' + (v === model.verification ? 'selected' : '') + '>' + t + '</option>').join('');
    const hint = model.verification === 'none' ? 'No hash verification · Copy-only completion' : model.verification === 'random33' ? 'Sampled files · Cryptographic hash verification' : 'All files · Fast non-cryptographic verification';
    return '<section class="setup transfer-setup" aria-label="Transfer configuration"><div class="field od-field"><label for="bandwidth">Bandwidth</label><select id="bandwidth" ' + disabled + '>' + bandwidth + '</select><span class="field-hint">' + (model.bandwidth === 'Unlimited' ? 'No bandwidth cap' : 'Copy throughput limit') + '</span></div><div class="field od-field"><label for="verification">Verification</label><select id="verification" ' + disabled + '>' + options + '</select><span class="field-hint">' + hint + '</span></div></section>';
  }
  function controlBar() {
    const p = statePresentation();
    let actions;
    if (model.state === 'ready') actions = btn('start','Start Transfer','primary','',hasSpace()?'':'disabled');
    else if (model.state === 'validating') actions = btn('noop','Validating…','ghost','','disabled');
    else if (locked()) actions = btn('cancel','Cancel job','danger','stop');
    else if (model.state === 'error' || model.state === 'cancelled') actions = btn('retry','Retry Transfer','primary','',hasSpace()?'':'disabled') + btn('logs','View log','ghost');
    else actions = btn('reset','New Transfer','primary') + btn('logs','View log','ghost');
    return '<section class="control-bar" data-tone="' + p.tone + '" aria-label="Transfer controls"><div class="control-state"><div class="control-copy od-field"><h2 class="state-title" id="state-title" tabindex="-1">' + p.title + '</h2><span class="state-help">' + esc(p.help) + '</span></div></div><div class="control-actions">' + actions + '</div></section>';
  }
  function jobMetrics() {
    const total = model.source?.bytes || 0, totalMB = total * 1000;
    const copiedFraction = model.copyPassed ? 1 : ['ready','validating'].includes(model.state) ? 0 : model.progress / 100;
    const coverage = model.verification === 'none' ? 0 : model.verification === 'random33' ? 1 / 3 : 1;
    const verifyContext = model.verification !== 'none' && (model.copyPassed || model.endedPhase === 'Verification');
    const verifyFraction = model.verifyPassed ? 1 : verifyContext ? model.progress / 100 : 0;
    const progress = Math.round((verifyContext ? verifyFraction : copiedFraction) * 100);
    const progressLabel = verifyContext ? 'Verification progress' : 'Copy progress';
    const speedLabel = verifyContext ? 'Verification speed' : 'Current copy speed';
    const etaLabel = verifyContext ? 'Verification ETA' : 'Copy ETA';
    const active = ['copying','verifying'].includes(model.state);
    let eta = '—', etaHint = terminal() ? 'Job has ended' : 'Available after start';
    if (active) {
      if (model.eta === 'Calculating…') {eta = 'Calculating…'; etaHint = 'Waiting for enough observations';}
      else if (model.eta === '—' || !model.speed) etaHint = 'No reliable estimate available';
      else {
        // Fixture-only active-phase estimate; no combined workflow percentage.
        const remaining = verifyContext ? totalMB * coverage * (1 - verifyFraction) / model.speed : totalMB * (1 - copiedFraction) / model.speed;
        eta = '~' + Math.max(1, Math.ceil(remaining / 60)) + ' min';
        etaHint = verifyContext ? 'Active verification phase · Approximate' : 'Copy phase only · Approximate';
      }
    }
    return {progress,progressLabel,speedLabel,etaLabel,eta,etaHint,verifyContext,copied:total * copiedFraction,files:Math.round((model.source?.files || 0) * copiedFraction),average:model.copyElapsed > 0 ? totalMB * copiedFraction / model.copyElapsed : null,verifyPct:Math.round(verifyFraction * 100)};
  }
  function telemetry() {
    const m = jobMetrics(), active = ['copying','verifying'].includes(model.state), phase = statePresentation();
    const stopped = ['error','cancelled'].includes(model.state);
    const progressHint = safeToEject() ? 'Verification passed' : model.state === 'copyComplete' ? 'Copy completed · Verification disabled' : stopped ? m.verifyContext ? 'Stopped · No verified successful result' : model.endedPhase === 'Preflight' ? 'Copy did not start' : 'Stopped · Copy incomplete' : active ? m.verifyContext ? 'Active verification phase' : 'Active copy phase' : 'No job running';
    const target = model.source ? model.verification === 'random33' ? Math.max(1, Math.round(model.source.files / 3)) : model.source.files : 0;
    const phaseInfo = '<span>Copy <strong>' + (model.copyPassed ? 'Completed' : model.state === 'copying' ? 'Active' : stopped && model.progress > 0 ? 'Incomplete' : 'Not started') + '</strong></span><span>Verification <strong>' + (model.verification === 'none' ? 'Disabled' : model.verifyPassed ? 'Passed' : model.copyPassed ? model.state === 'verifying' ? 'Active' : model.state === 'error' ? 'Failed' : 'Incomplete' : stopped ? 'Not started' : 'Pending') + '</strong></span>' +
      (m.verifyContext ? '<span>' + count(Math.round(target * m.verifyPct / 100)) + ' / ' + count(target) + ' files checked</span><span>Verification elapsed <strong class="mono">' + elapsed(model.verifyElapsed) + '</strong></span>' : '');
    const current = model.source?.dng ? 'CinemaDNG sequence · Frame activity grouped' : model.source?.current || '—';
    const phaseName = active ? m.verifyContext ? 'Verification phase' : 'Copy phase' : model.state === 'validating' ? 'Validating folders' : stopped ? 'Stopped during ' + (model.endedPhase || (model.copyPassed ? 'Verification' : 'Copy')) : terminal() ? 'Final result' : 'Awaiting start';
    return '<section class="telemetry" data-phase="' + model.state + '" data-tone="' + phase.tone + '" aria-label="Job status"><div class="telemetry-head"><h2>Job status</h2><span class="phase-text">' + esc(phaseName) + '</span></div>' +
      '<div class="metrics od-grid"><div class="metric metric-primary od-stat"><span class="metric-label">' + m.progressLabel + '</span><span class="metric-value od-nowrap">' + m.progress + '<small>%</small></span><span class="metric-helper">' + progressHint + '</span></div>' +
      '<div class="metric od-stat"><span class="metric-label">' + m.etaLabel + '</span><span class="metric-value od-nowrap ' + (m.eta.length > 8 ? 'long' : '') + '">' + m.eta + '</span><span class="metric-helper">' + m.etaHint + '</span></div>' +
      '<div class="metric od-stat"><span class="metric-label">' + m.speedLabel + '</span><span class="metric-value od-nowrap">' + (active ? model.speed.toFixed(1) + '<small>MB/s</small>' : '—') + '</span><span class="metric-helper">' + (active ? m.verifyContext ? 'Verification read/hash throughput' : 'Observed copy throughput' : 'No active throughput') + '</span></div></div>' +
      '<progress value="' + m.progress + '" max="100" aria-label="' + m.progressLabel + '">' + m.progress + '%</progress>' +
      (model.state === 'validating' ? '<div class="loading-track" aria-label="Validating source and destination"></div>' : '') +
      '<div class="phase-summary od-cluster">' + phaseInfo + '</div>' +
      '<div class="runtime-values od-grid"><div class="runtime-stat od-stat"><span>Average copy speed</span><strong class="od-nowrap">' + (m.average === null ? '—' : m.average.toFixed(1) + ' MB/s') + '</strong></div>' +
      '<div class="runtime-stat od-stat"><span>Job elapsed</span><strong class="mono od-nowrap">' + elapsed(model.elapsed) + '</strong></div>' +
      '<div class="runtime-stat runtime-bytes od-stat"><span>Copied bytes</span><strong class="od-nowrap">' + (model.source ? size(m.copied) + ' / ' + size(model.source.bytes) : '—') + '</strong></div>' +
      '<div class="runtime-stat od-stat"><span>Copied files</span><strong class="od-nowrap">' + (model.source ? count(m.files) + ' / ' + count(model.source.files) : '—') + '</strong></div></div>' +
      '<div class="current-item od-row-top"><span class="current-item-label">Current item</span>' + (active ? '<button type="button" class="current-item-button od-fill" data-action="current-item"><span class="od-truncate">' + esc(current) + '</span></button>' : '<span class="current-item-button od-fill">—</span>') + '</div></section>';
  }
  function notices() {
    if (model.state === 'error') {
      const failedPhase = model.endedPhase || (model.copyPassed ? 'Verification' : 'Copy');
      const code = model.errorCode || (model.copyPassed ? 'VERIFY_MISMATCH' : 'TRANSFER_FAILED');
      return '<section class="notice error" data-tone="' + statePresentation().tone + '" role="alert"><h3 class="notice-title">Failed during ' + esc(failedPhase) + '</h3><p class="notice-body">' + esc(model.error) + '</p><div class="notice-actions"><details><summary>Technical detail</summary><p class="technical-details">' + esc(code) + (model.copyPassed ? ' · A001_C014_0930.mov' : ' · Operation incomplete') + '</p></details></div></section>';
    }
    if (model.warning) return '<section class="notice"><h3 class="notice-title">Storage warning</h3><p class="notice-body">' + esc(model.warning) + '</p></section>';
    return '';
  }
  const metadataRow = (label,value,mono=false) => `<div class="od-field"><dt>${label}</dt><dd class="${mono?'mono':''}">${esc(value)}</dd></div>`;
  function inspector() {
    if (!model.inspector) return '';
    const s=model.source,d=model.destination;
    return `<aside class="inspector" aria-label="Advanced information"><div class="inspector-head"><h2>Advanced information</h2><button class="button ghost icon-button" data-action="close-inspector" aria-label="Close advanced information">${icon('close')}</button></div><div class="inspector-body">
      <section class="inspector-group"><h3>Source</h3><dl class="metadata">${s?metadataRow('Full path',s.path,true)+metadataRow('Folder size',size(s.bytes))+metadataRow('File count',count(s.files))+metadataRow('Folder count',count(s.folders))+metadataRow('Filesystem','Not available')+metadataRow('Volume capacity / free space','Not available')+metadataRow('Connection type','Not available'):metadataRow('Selection','No source selected')}</dl></section>
      <section class="inspector-group"><h3>Destination</h3><dl class="metadata">${d?metadataRow('Full path',d.path,true)+metadataRow('Output folder',d.path+'/'+(s?s.name:'Source'),true)+metadataRow('Filesystem',d.filesystem)+metadataRow('Free space',size(d.free))+metadataRow('Writable',d.writable?'Yes':'No')+metadataRow('Total capacity / connection','Not available'):metadataRow('Selection','No destination selected')}</dl></section>
      ${s?`<section class="inspector-group"><h3>Current item detail</h3><p class="file-path-full">${esc(s.current)}</p></section>`:''}
      </div><p class="inspector-footnote">Unavailable device details are not exposed by the current storage models.</p></aside>`;
  }
  function transferSurface() {
    return '<section class="tab-surface" role="tabpanel" aria-labelledby="tab-transfer"><h1 class="sr-only">Media offload</h1><div class="workbench ' + (model.inspector ? 'has-inspector' : '') + '"><div class="main-flow"><div class="route-panel">' + endpoint('source') + endpoint('destination') + readiness() + '</div>' + setup() + controlBar() + telemetry() + notices() +
      '<div class="advanced-actions od-row"><button type="button" class="text-button" data-action="toggle-inspector" aria-expanded="' + model.inspector + '">' + (model.inspector ? 'Hide' : 'Show') + ' advanced information</button><button type="button" class="text-button" data-action="logs">View log <span class="mono">' + model.logs.filter(l => !l.diagnostic).length + '</span></button></div></div>' + inspector() + '</div></section>';
  }
  function notificationPreview() {
    const n=model.notification;
    let text = `FST heartbeat\nSource: ${model.source?.name||'Source'}\nDestination: ${model.destination?.name||'Destination'}\nPhase: ${statePresentation().title}\nProgress: ${model.progress}%`;
    if (n.detail === 'Standard') text += `\nElapsed: ${elapsed(model.elapsed)}${model.eta?'\nETA: '+model.eta:''}`;
    return text;
  }
  const errorMarkup = key => model.formErrors[key]?`<span class="field-error" id="${key}-error">${esc(model.formErrors[key])}</span>`:'';
  const checkbox = (key,label) => `<label class="check-row"><input type="checkbox" data-notify="${key}" ${model.notification[key]?'checked':''}><span>${label}</span></label>`;
  function notificationSurface() {
    const n=model.notification;
    return `<section class="tab-surface" role="tabpanel" aria-labelledby="tab-notification"><div class="surface-intro"><h1>Notifications</h1><span class="section-kicker">Optional · best-effort · separate from job safety</span></div><div class="notification-layout"><div><section class="settings-section"><h2>Telegram setup</h2><p class="caption">Notification delivery never changes transfer or verification results.</p>${checkbox('enabled','Enable Telegram notification')}
      <form id="notification-form" novalidate>${Object.keys(model.formErrors).length?`<div class="form-summary" role="alert">${Object.keys(model.formErrors).map(k=>`<a href="#${k}">${esc(model.formErrors[k])}</a>`).join('')}</div>`:''}<div class="settings-fields">
      <div class="field"><label for="token">Bot token${n.enabled?' · required':''}</label><input id="token" type="password" autocomplete="off" value="${esc(n.token)}" ${n.enabled?'required':''} ${model.formErrors.token?'aria-invalid="true" aria-describedby="token-error"':''}>${errorMarkup('token')}</div>
      <div class="field"><label for="chatID">Chat ID${n.enabled?' · required':''}</label><input id="chatID" type="text" value="${esc(n.chatID)}" autocomplete="off" ${n.enabled?'required':''} ${model.formErrors.chatID?'aria-invalid="true" aria-describedby="chatID-error"':''}>${errorMarkup('chatID')}</div>
      <div>${btn('test-message',model.testing?'Generating preview…':'Test message','ghost','',!n.enabled||model.testing?'disabled':'')}${model.testing?'<div class="loading-track" aria-label="Generating local message preview"></div>':''}<p class="field-hint">This visual prototype generates a local preview. No message is sent.</p></div></div></form></section>
      <section class="settings-section"><h2>Notify events</h2>${checkbox('job','Job starts')}${checkbox('heartbeat','Heartbeat while running')}${checkbox('fail','Transfer fails')}${checkbox('copy','Copy completed')}${checkbox('verify','Verify completed / Safe to eject')}<div class="setup"><div class="field"><label for="heartbeat-interval">Heartbeat interval</label><select id="heartbeat-interval"><option value="15" ${n.interval==='15'?'selected':''}>15 minutes</option><option value="30" ${n.interval==='30'?'selected':''}>30 minutes</option></select></div><div class="field"><label for="message-detail">Message detail</label><select id="message-detail"><option ${n.detail==='Compact'?'selected':''}>Compact</option><option ${n.detail==='Standard'?'selected':''}>Standard</option></select></div></div></section></div>
      <div><section class="settings-section"><h2>Notification status</h2><dl class="metadata status-list">${metadataRow('Telegram',n.enabled?'Enabled in preview':'Disabled')}${metadataRow('Connection','Not tested')}${metadataRow('Last message',model.lastPreview)}${metadataRow('Last error',Object.values(model.formErrors).join(' ')||'None')}</dl></section><section class="settings-section"><h2>Message preview</h2><pre class="message-preview" id="message-preview">${esc(notificationPreview())}</pre></section></div></div></section>`;
  }
  function logSurface() {
    const visible=model.logs.filter(l=>model.diagnostics||!l.diagnostic);
    return `<section class="tab-surface" role="tabpanel" aria-labelledby="tab-logs"><div class="surface-intro"><h1>Technical log</h1><span class="section-kicker">Structured sample log · No transfer is executed</span></div><div class="logs-toolbar"><div class="log-options"><label class="check-row"><input type="checkbox" id="diagnostics" ${model.diagnostics?'checked':''}><span>Show diagnostics</span></label><label class="check-row"><input type="checkbox" id="auto-scroll" ${model.autoScroll?'checked':''}><span>Auto-scroll</span></label></div>${btn('export-log','Log details','ghost')}</div><div class="log-feed" id="log-feed" tabindex="0" aria-label="Technical log entries">${visible.length?visible.map(l=>`<div class="log-line" data-level="${l.level}"><span class="log-time">${l.time}</span><span class="log-level">${l.level}</span><span class="log-message">${esc(l.message)}</span></div>`).join(''):'<div class="empty-state"><h2>No log entries yet</h2><p class="muted">Select source and destination, then start a job.</p></div>'}</div><div class="recent-activity"><span>${visible.length} visible / ${model.logs.length} total entries</span><span>Filtering does not change the complete log.</span></div></section>`;
  }
  function updateFooter() {
    let label, tone = statePresentation().tone;
    if (model.state === 'ready') label = hasSpace() ? 'Ready' : 'Setup required';
    else if (model.state === 'validating') label = 'Validating folders';
    else if (model.state === 'copying') label = 'Copy in progress';
    else if (model.state === 'verifying') label = 'Copy complete · Verification active';
    else if (model.state === 'copyComplete') label = 'TRANSFER COMPLETE · Not verified';
    else if (safeToEject()) label = 'SAFE TO EJECT';
    else label = statePresentation().title;
    $('footer-state').innerHTML = (safeToEject() ? icon('shield') : '') + '<span>' + label + '</span>';
    $('footer-state').className = 'footer-state ' + tone;
    $('footer-phase').textContent = model.state === 'ready' ? 'No job started' : safeToEject() ? 'Copy passed · Verification passed' : terminal() ? 'Retain source media' : 'Keep media connected';
    const rsyncError = model.state === 'error' && model.errorCode === 'RSYNC_FAILURE';
    $('footer-rsync').textContent = rsyncError ? 'rsync error' : '';
    $('footer-rsync').hidden = !rsyncError;
  }
  function render({focus='',preserve=true}={}) {
    const area=$('content');
    const active=document.activeElement;
    const activeId=active?.id;
    const activeAction=active?.dataset?.action;
    const top=preserve?area.scrollTop:0;
    for (const name of ['transfer','notification','logs']) {
      const tab=$('tab-'+name);tab.setAttribute('aria-selected',String(model.tab===name));tab.tabIndex=model.tab===name?0:-1;
    }
    $('log-count').textContent=model.logs.length;
    area.innerHTML=model.tab==='transfer'?transferSurface():model.tab==='notification'?notificationSurface():logSurface();
    area.scrollTop=top;
    updateFooter();
    if (model.tab==='logs' && model.autoScroll) { const feed=$('log-feed');feed.scrollTop=feed.scrollHeight; }
    if (focus) $(focus)?.focus({preventScroll:true});
    else if (activeId && $(activeId)) $(activeId).focus({preventScroll:true});
    else if (activeAction) document.querySelector(`[data-action="${activeAction}"]`)?.focus({preventScroll:true});
  }
  function renderTick() {
    if (model.tab==='notification') {
      $('message-preview').textContent=notificationPreview();
      $('log-count').textContent=model.logs.length;
      updateFooter();
    } else render();
  }
  function announce() { $('announcer').textContent=statePresentation().title+'. '+statePresentation().help; }
  function setTab(tab) {
    model.scroll[model.tab]=$('content').scrollTop;model.tab=tab;render({preserve:false});$('content').scrollTop=model.scroll[tab];
  }
  let toastTimer;
  function toast(message) { $('toast').textContent=message;$('toast').hidden=false;clearTimeout(toastTimer);toastTimer=setTimeout(()=>$('toast').hidden=true,5000); }
  let dialogReturn;
  function openDialog(content, actions) {
    dialogReturn=document.activeElement;
    $('dialog').innerHTML=`<div class="dialog-body">${content}</div><div class="dialog-actions">${actions}</div>`;
    $('dialog').showModal();
  }
  function closeDialog() { $('dialog').close(); }
  function pickFolder(which) {
    if (locked()) return;
    const items=which==='source'?sources:destinations;
    model.selectedFolder=model[which]?.id||items[0].id;
    openDialog(`<div class="dialog-heading"><h2>Choose ${which}</h2></div><p class="muted">Select a sample folder for this design review.</p><div class="folder-list">${items.map(item=>`<button class="folder-choice" data-action="select-folder" data-folder="${item.id}" aria-pressed="${item.id===model.selectedFolder}">${icon(which==='source'?'drive':'folder')}<span class="od-field od-fill"><strong>${esc(item.name)}</strong><span class="caption mono">${esc(item.path)}</span><span class="caption">${which==='source'?size(item.bytes)+' · '+count(item.files)+' files':size(item.free)+' free · '+item.filesystem}</span></span></button>`).join('')}</div>`,btn('close-dialog','Cancel')+btn('apply-folder','Choose folder','primary','',`data-which="${which}"`));
  }
  function resetJob() {
    clearInterval(model.timer);model.running=false;model.state='ready';model.progress=0;model.copyPassed=false;model.verifyPassed=false;model.error='';model.eta=null;model.speed=0;model.elapsed=0;model.copyElapsed=0;model.verifyElapsed=0;model.endedPhase=null;model.errorCode='';
  }
  function startJob() {
    if (!hasSpace() || locked() || model.running) return;
    resetJob();model.running=true;model.state='validating';addLog('INFO','Fixture readiness checks started.');render({focus:'state-title'});announce();
    setTimeout(()=>{
      if (!model.running || model.state!=='validating') return;
      model.state='copying';model.eta='Calculating…';model.speed=Math.min(148.6,model.bandwidth==='Unlimited'?148.6:Number(model.bandwidth));addLog('TRANSFER','Fixture copy started. Source and configuration locked.');renderTick();announce();
      model.timer=setInterval(()=>{
        if (!model.running) return;
        model.progress=Math.min(100,model.progress+5);
        if (model.state === 'copying') {
          model.copyElapsed = model.source.bytes * 1000 * model.progress / 100 / (model.speed * .96);
          model.eta = model.progress < 15 ? 'Calculating…' : null;
        } else {
          model.verifyElapsed = model.source.bytes * 1000 * (model.verification === 'random33' ? 1/3 : 1) * model.progress / 100 / 496;
          model.eta = null;
        }
        model.elapsed = model.copyElapsed + model.verifyElapsed;
        if (model.progress===100) {
          if (model.state==='copying') {
            model.copyPassed=true;addLog('TRANSFER','Fixture copy passed.');
            if (model.verification==='none') {model.state='copyComplete';finishJob();}
            else {model.state='verifying';model.progress=0;model.speed=512.8;model.eta=null;addLog('VERIFY',`${modeLabel()} fixture verification started.`);announce();}
          } else if (model.state==='verifying') {model.verifyPassed=true;model.state='safeToFormat';addLog('VERIFY','Fixture verification passed. Copy and verification succeeded.');finishJob();}
        }
        renderTick();
      },600);
    },650);
  }
  function finishJob() { clearInterval(model.timer);model.running=false;model.speed=0;model.eta=null;announce(); }
  const logText = () => model.logs.map(l => '[' + l.time + '] ' + l.level + ': ' + l.message).join('\n');
  function showLogDetails() {
    openDialog('<h2>Technical log</h2><p class="muted">Sample entries only. No report or file is exported.</p><pre class="file-path-full">' + esc(logText()) + '</pre>', btn('close-dialog','Close'));
  }
  function saveReport() { toast('Production report export is outside this visual prototype.'); }
  function validateNotify(key) {
    const n=model.notification;
    if (!n.enabled) {delete model.formErrors[key];return;}
    if (key==='token') {
      if (!n.token.trim()) model.formErrors.token='Enter a sample bot token to generate a preview.';
      else delete model.formErrors.token;
    }
    if (key==='chatID') {
      if (!/^-?\d+$/.test(n.chatID.trim())) model.formErrors.chatID='Enter a numeric sample Chat ID, such as 123456789.';
      else delete model.formErrors.chatID;
    }
  }
  function testMessage() {
    validateNotify('token');validateNotify('chatID');
    if (Object.keys(model.formErrors).length) {render({focus:Object.keys(model.formErrors)[0]});return;}
    if (!model.notification.enabled || model.testing) return;
    model.testing=true;render();
    setTimeout(()=>{model.testing=false;model.lastPreview='Preview generated · no message sent';render();toast('Preview generated locally. No Telegram message was sent.');},700);
  }
  document.addEventListener('click',event=>{
    const button=event.target.closest('[data-action]');if (!button||button.disabled) return;
    const action=button.dataset.action;
    if (action.startsWith('choose-')) {pickFolder(action.slice(7));return;}
    if (action.startsWith('clear-')) {if (!locked()) {if(terminal())resetJob();model[action.slice(6)]=null;model.warning='';addLog('INFO','Folder selection cleared. Nothing on disk was changed.');render();}return;}
    if (action.startsWith('inspect-')) {model.inspector=true;render();$('content').querySelector('.inspector')?.scrollIntoView({block:'nearest'});return;}
    if (action==='start'||action==='retry') {startJob();return;}
    if (action==='reset') {resetJob();addLog('INFO','Explicitly returned to setup for a new job.');render({focus:'state-title'});announce();return;}
    if (action==='cancel') {openDialog('<h2>Cancel this job?</h2><p>Copy or verification will stop. The job will remain incomplete. Keep the source media.</p>',btn('close-dialog','Keep running')+btn('confirm-cancel','Cancel job','danger'));return;}
    if (action==='confirm-cancel') {clearInterval(model.timer);model.running=false;model.state='cancelled';model.verifyPassed=false;model.speed=0;model.eta=null;addLog('WARNING','CANCELLED. Source retained; no verified safety result.');closeDialog();render({focus:'state-title'});announce();return;}
    if (action==='close-dialog') {closeDialog();return;}
    if (action==='select-folder') {model.selectedFolder=button.dataset.folder;for (const b of $('dialog').querySelectorAll('[data-folder]')) b.setAttribute('aria-pressed',String(b===button));return;}
    if (action==='apply-folder') {const which=button.dataset.which;const item=(which==='source'?sources:destinations).find(i=>i.id===model.selectedFolder);if(item&&!locked()){if(terminal())resetJob();model[which]={...item};model.warning='';addLog('INFO',`${which==='source'?'Source':'Destination'} selected: ${item.path}`);closeDialog();render();}return;}
    if (action==='current-item') {openDialog('<h2>Current item</h2>'+`<p class="file-path-full">${esc(model.source?.current||'No source selected')}</p>`+`<p class="muted">${model.source?.dng?'Frame activity is grouped in the compact view. The exact filename is available here.':'Current-item detail stays secondary to whole-job status.'}</p>`,btn('close-dialog','Close'));return;}
    if (action==='toggle-inspector'||action==='close-inspector') {model.inspector=action==='close-inspector'?false:!model.inspector;render();return;}
    if (action==='logs') {setTab('logs');$('tab-logs').focus();return;}
    if (action==='report') {saveReport();return;}
    if (action==='export-log') {showLogDetails();return;}
    if (action==='test-message') {testMessage();return;}
  });
  document.addEventListener('change',event=>{
    const t=event.target;
    if (t.id==='bandwidth'&&!locked()) {if(terminal())resetJob();model.bandwidth=t.value;addLog('INFO',`Bandwidth selection: ${t.value}${t.value==='Unlimited'?'':' MB/s'}`);render({focus:'bandwidth'});}
    if (t.id==='verification'&&!locked()) {if(terminal())resetJob();model.verification=t.value;render({focus:'verification'});}
    if (t.id==='diagnostics') {model.diagnostics=t.checked;render({focus:'diagnostics'});}
    if (t.id==='auto-scroll') model.autoScroll=t.checked;
    if (t.dataset.notify) {model.notification[t.dataset.notify]=t.checked;if(t.dataset.notify==='enabled')model.formErrors={};render();}
    if (t.id==='heartbeat-interval') {model.notification.interval=t.value;}
    if (t.id==='message-detail') {model.notification.detail=t.value;$('message-preview').textContent=notificationPreview();}
  });
  document.addEventListener('input',event=>{if(['token','chatID'].includes(event.target.id))model.notification[event.target.id]=event.target.value;});
  document.addEventListener('focusout',event=>{
    const key=event.target.id;if(!['token','chatID'].includes(key))return;
    validateNotify(key);
    const previous=$(key+'-error');if(previous)previous.remove();
    const input=$(key);input.setAttribute('aria-invalid',String(!!model.formErrors[key]));
    if(model.formErrors[key]){input.insertAdjacentHTML('afterend',errorMarkup(key));input.setAttribute('aria-describedby',key+'-error');}else input.removeAttribute('aria-describedby');
  });
  document.addEventListener('submit',event=>{if(event.target.id==='notification-form'){event.preventDefault();testMessage();}});
  $('dialog').addEventListener('close',()=>{
    const replacement=dialogReturn?.dataset?.action?document.querySelector(`[data-action="${dialogReturn.dataset.action}"]`):null;
    if(dialogReturn?.isConnected)dialogReturn.focus({preventScroll:true});else if(replacement)replacement.focus({preventScroll:true});else if($('state-title'))$('state-title').focus({preventScroll:true});else $('tab-'+model.tab).focus({preventScroll:true});
  });
  for (const tab of document.querySelectorAll('[role="tab"]')) {
    tab.addEventListener('click',()=>setTab(tab.dataset.tab));
    tab.addEventListener('keydown',event=>{
      const order=['transfer','notification','logs'];const i=order.indexOf(model.tab);
      const next=event.key==='ArrowRight'?order[(i+1)%3]:event.key==='ArrowLeft'?order[(i+2)%3]:event.key==='Home'?order[0]:event.key==='End'?order[2]:null;
      if(next){event.preventDefault();setTab(next);$('tab-'+next).focus();}
    });
  }
  seedScenario();render();
})();
