# Typography retune evidence index

BASELINE=523a38b8243612afc6d0c525961fef4f55b6a3c2
FINAL_RESULT=PASS
VISUAL=8_BEFORE_AND_8_AFTER_NATIVE_DARK_AQUA_PNGS
REQUIRED=AFTER_READY1120x760;AFTER_READY_MINIMUM900x660;AFTER_READY_MINIMUM_SCROLLED900x660
OTHER_STATES=LongNamesPathsCountsFilesystem;LockedCopying;InsufficientCapacity;NonWritable;Empty
REVIEW=ImplementerOnly;BRAINPending

Every numbered claim is supported in VALIDATION.md, actual test summaries,
VISUAL_METRICS.json, SCOPE_CHECK.json, and corresponding raw compressed logs.
CaptureNative.swift/capture_native.py reuse the prior fixture harness exactly.
Production review diff is a whitespace-normalized reading copy.
Initial staged diff check found one blank EOF line in this copy; removed
that artifact-only line and refreshed its manifest hash, then reran the gate.
Production Swift and completed build/tests remain unchanged.
Ignored logs/DerivedData/xcresult/capture compilation units stay local to this
evidence directory. No alternate Desktop artifacts. BRAIN_RETURN_FACTS.md
contains owner-requested compact fallback facts to append to the canonical
exported Desktop packet; its full report/evidence bodies are not embedded.

| Artifact | Bytes | SHA256 |
|---|---:|---|
| [AFTER_CAPTURE.log.gz](AFTER_CAPTURE.log.gz) | 1349 | `2cc27668a455b2aa32604444a0c1d219bf18864380fa298f1c11113e2f122b64` |
| [AFTER_EMPTY_MINIMUM.png](AFTER_EMPTY_MINIMUM.png) | 218057 | `9df183e49b7c7970d9848b1bb2010420ef32a9285d5d5203116e371f6c65d2ff` |
| [AFTER_INSUFFICIENT_MINIMUM.png](AFTER_INSUFFICIENT_MINIMUM.png) | 290393 | `d0f3b1af3c7493babbfe6fe72f218adf5884e9e1c5d1e679b9a98d6148861810` |
| [AFTER_LOCKED_MINIMUM.png](AFTER_LOCKED_MINIMUM.png) | 282477 | `91bb6155d413bad4a55c95123f34bee00f5b9607c65d21ba78f28e198c76c0b0` |
| [AFTER_LONG_NAMES_MINIMUM.png](AFTER_LONG_NAMES_MINIMUM.png) | 297071 | `9f80581a58476ae9365c3766e8313202126793eac2b3dba5f99a6995e76a25ea` |
| [AFTER_NOT_WRITABLE_MINIMUM.png](AFTER_NOT_WRITABLE_MINIMUM.png) | 266641 | `98ee1d2f42bc0114fc6672332b80759ccf902926aa2fd0b1315487b7c81bfdbc` |
| [AFTER_READY.png](AFTER_READY.png) | 298964 | `76db950a3a504684cc8b658b32bb60aad66869b8e135cc7efcba850c03e8c935` |
| [AFTER_READY_MINIMUM.png](AFTER_READY_MINIMUM.png) | 266685 | `109f0ff701d9f60c0d6e5da0b994f0d2998349ea7ee053025aa13781e9355c56` |
| [AFTER_READY_MINIMUM_SCROLLED.png](AFTER_READY_MINIMUM_SCROLLED.png) | 247314 | `f58408e90e5082a2e6e3f6ecad915b490fc2ea2b92f376917fe9d22394d2ea14` |
| [BEFORE_CAPTURE.log.gz](BEFORE_CAPTURE.log.gz) | 1352 | `366a0aaaffeae56139833ab761e9ca6ba3b03cd12f4dce270018690a65debb47` |
| [BEFORE_EMPTY_MINIMUM.png](BEFORE_EMPTY_MINIMUM.png) | 217065 | `95750c64f14b2124854bb0355bf7c6eed7191fb70e7e1f901dd4f4866c5cc43a` |
| [BEFORE_INSUFFICIENT_MINIMUM.png](BEFORE_INSUFFICIENT_MINIMUM.png) | 298213 | `a587f4df4160b425d6377cf4805603d713c64283c0778a3487269dc783967fdc` |
| [BEFORE_LOCKED_MINIMUM.png](BEFORE_LOCKED_MINIMUM.png) | 285836 | `91dcd436138f0245de7cf78a3a038cba69262923367ec24a95218a316fbb69dd` |
| [BEFORE_LONG_NAMES_MINIMUM.png](BEFORE_LONG_NAMES_MINIMUM.png) | 307769 | `bf59d24fc026c6306e11a2f5a91e342a61b572631d862e93827c8bc999e9ea09` |
| [BEFORE_NOT_WRITABLE_MINIMUM.png](BEFORE_NOT_WRITABLE_MINIMUM.png) | 272687 | `dee697169cd50d1c83eccee85451c25a307b73aaea0af1a139968d106cf7dcab` |
| [BEFORE_READY.png](BEFORE_READY.png) | 313246 | `278995fa405d4ca849fe6991ecdc767569c0c6e7a309851f97db90c6a91186b7` |
| [BEFORE_READY_MINIMUM.png](BEFORE_READY_MINIMUM.png) | 273173 | `ae4e736f59224873fbc08e15b4a90770edc97bf987e90c57a3d88d1c31fd5ae7` |
| [BEFORE_READY_MINIMUM_SCROLLED.png](BEFORE_READY_MINIMUM_SCROLLED.png) | 241534 | `e1ac7d895decef8b92fdf2c75b2525dec0126c8d692fa2e82294e774d44cafeb` |
| [BRAIN_RETURN_FACTS.md](BRAIN_RETURN_FACTS.md) | 1383 | `87b28f28f3932d6b8b8c0ac36a1ab1217fda616e8cb989aa876fc6fd21d571d1` |
| [BUILD.log.gz](BUILD.log.gz) | 18601 | `88dcfd2ef4d17d77847e85946f2081162abb469f2be6f62a751af2d541729cef` |
| [CaptureNative.swift](CaptureNative.swift) | 14458 | `665de3be65fa407201169f544f8c4277f6d2218b9d2969ef535ab23b550283d0` |
| [FOCUSED_TESTS.log.gz](FOCUSED_TESTS.log.gz) | 11336 | `0564bcd7f40e54e94ba43667557ebc3f4eea6ec709fdb614fff145ba612debee` |
| [FOCUSED_TEST_SUMMARY.json](FOCUSED_TEST_SUMMARY.json) | 1156 | `14b7bd999c9fdf51617ca7cac1f3beee8e63b084d7c41a8773f02ad2829c8546` |
| [FULL_TESTS.log.gz](FULL_TESTS.log.gz) | 47323 | `cac381d058bdc3c048bd9a5d9def7ef96ca0cdcb53dc1ab0df847cf020276560` |
| [FULL_TEST_SUMMARY.json](FULL_TEST_SUMMARY.json) | 1156 | `29df79bfb57932c911f99cacf1b83f23959759d2ccffdfd4e0b9b143b17c77a6` |
| [PRESENTATION_TEST.log.gz](PRESENTATION_TEST.log.gz) | 1015 | `56b49a7a38de97ce3bfa239582f89b05163b3ac3873d98433930dbb91e37a67a` |
| [PRODUCTION_REVIEWED.diff](PRODUCTION_REVIEWED.diff) | 12175 | `612a0bbbfa7451a024276e2f6847265b0e76da5957013895738815c596cd25f9` |
| [SCOPE_CHECK.json](SCOPE_CHECK.json) | 1759 | `f73baeced692b246569845a0bf74c78e71e5ecf1034861803b7ac1c91eb47fbf` |
| [VALIDATION.md](VALIDATION.md) | 8407 | `150d9e82b4de0c1267f57ddf26cadaf5d8b85ccb4fdc108e662de8a4a8e97f24` |
| [VISUAL_METRICS.json](VISUAL_METRICS.json) | 2873 | `a75898b826d922e94d01259bf7d67a7fcf93cc2c87250366fb5da587ab19367b` |
| [capture_native.py](capture_native.py) | 2933 | `c47ac03164339efb935b484a7ede3305e1f58369617fb6d3425ef3eb14da93e0` |
