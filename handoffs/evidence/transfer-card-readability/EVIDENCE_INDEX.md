# Transfer card readability evidence

Native Dark Aqua captures; synthetic fixtures only. All production view bodies compiled from this patch. BEFORE uses clean baseline 21d7e3512fbe487bd1489890b3c27caf40602e8d. AFTER uses the final three-view patch.

| File | Pixels | Bytes | SHA256 |
|---|---|---:|---|
| AFTER_EMPTY_MINIMUM.png | 1800×1320 | 217065 | `95750c64f14b2124854bb0355bf7c6eed7191fb70e7e1f901dd4f4866c5cc43a` |
| AFTER_INSUFFICIENT_MINIMUM.png | 1800×1320 | 299232 | `77df7b53dff2bb110f38f08231ac5a9ec66e415e5fa0ee92e6712b656974c5b5` |
| AFTER_LOCKED_MINIMUM.png | 1800×1320 | 286934 | `e7cc6ba4d2e27fb80d830ef045a6cb59038c0b09a4ea53aa944fc8cb70e18477` |
| AFTER_LONG_NAMES_MINIMUM.png | 1800×1320 | 307769 | `bf59d24fc026c6306e11a2f5a91e342a61b572631d862e93827c8bc999e9ea09` |
| AFTER_NOT_WRITABLE_MINIMUM.png | 1800×1320 | 273819 | `e641abc932176c44c372a10e38370f25ee648059e60bd80af42865a2e414081c` |
| AFTER_READY.png | 2240×1520 | 313797 | `426981b63ce7f809c35b0b2ed55cf39d6fc8fa535436b0986cd74d028f274c03` |
| AFTER_READY_MINIMUM.png | 1800×1320 | 274326 | `6af9d15d22fce9ea545bbe4086d8764d1bdf0b21aa009578cac411465e15f707` |
| AFTER_READY_MINIMUM_SCROLLED.png | 1800×1320 | 242078 | `8065b1e2efe0e1048dd15e50b7ef1710b0da6fd10da05c8ee998af16d081909e` |
| BEFORE_LOCKED_MINIMUM.png | 1800×1320 | 283870 | `b661db41d43b60f4bbda8a3b03bced070bd4fcee3977b4f6567872400a53a1c9` |
| BEFORE_READY.png | 2240×1520 | 284541 | `5be65432bdcf196fc54fe3618bfd244e2a23bd462776faa958f31d065d6d03a4` |
| BEFORE_READY_MINIMUM.png | 1800×1320 | 258854 | `76e75d2ba2cf43d5296a4cb804451260815e5758bd0d8d3fd0a1966c3040cf27` |
| BEFORE_READY_MINIMUM_SCROLLED.png | 1800×1320 | 252400 | `9719a2fcfdea442d1ac5eac3b64130d6b4c18e0f5270f6190183021ff4a40468` |

Logs are exact gzip-compressed command output; extract using `gzip -dc <path>`. Structured canonical test summaries and `SCOPE_CHECK.json` accompany them. Build outputs and xcresult bundles stay in ignored repository-local directories.

`PRODUCTION_REVIEWED.diff` is a review copy with trailing whitespace on context lines removed for the repository whitespace gate. Canonical production changes remain in Git; production file hashes are in `SCOPE_CHECK.json`.
