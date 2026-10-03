# Third-Party Licenses and Source Availability

FST's source-available non-commercial license applies to FST materials, not to the components below. Their own licenses and redistribution rights remain in force. FST invokes rsync as a separate executable; its built-in SHA256/xxHash64 verification is separate from rsync's optional checksum libraries.

## Shipped components

The following components are included in the v1.4.0 packages. The ARM64 popt library is identified as 1.19, but its original build provenance remains unconfirmed.

| Component | ARM64 package | Intel package | License and authoritative source |
| --- | --- | --- | --- |
| rsync 3.4.4 | Bundled executable | Bundled native executable | GPL-3.0-or-later; [official source](https://download.samba.org/pub/rsync/src/rsync-3.4.4.tar.gz), source-file headers and `COPYING` |
| OpenSSL libcrypto 3.6.2 | `libcrypto.3.dylib` | Not bundled | Apache-2.0; [upstream license](https://github.com/openssl/openssl/blob/openssl-3.6.2/LICENSE.txt) |
| LZ4 1.10.0 | `liblz4.1.dylib` | Not bundled | BSD-2-Clause for the library; [upstream license](https://github.com/lz4/lz4/blob/v1.10.0/lib/LICENSE) |
| popt 1.19 | `libpopt.0.dylib` | Uses rsync's included popt instead | MIT; [upstream 1.19 source and COPYING](https://ftp.osuosl.org/pub/rpm/popt/releases/popt-1.x/popt-1.19.tar.gz) |
| xxHash 0.8.3 | `libxxhash.0.dylib` | Optional rsync xxhash disabled | BSD-2-Clause for the library; [upstream license](https://github.com/Cyan4973/xxHash/blob/v0.8.3/LICENSE) |
| Zstandard 1.5.7 | `libzstd.1.dylib` | Not bundled | BSD-3-Clause distribution option; [upstream license](https://github.com/facebook/zstd/blob/v1.5.7/LICENSE) |
| rsync's included popt | Source/build provenance requires confirmation | Compiled into rsync | MIT-style permission with the additional X Consortium name restriction; `popt/COPYING` in the exact rsync source archive |
| rsync's included modified zlib (based on 1.2.8) | Included code; rsync supports zlib/zlibx | Compiled into rsync | zlib license; `zlib/README`, `zlib/zlib.h` and modification notices in the exact rsync source archive |

LZ4 and Zstandard also include xxHash code. LZ4's included copy carries a BSD-2-Clause notice. Zstandard's adapted copy refers to its root BSD/GPL dual licensing; this distribution selects the BSD-3-Clause option. Both attribution headers are preserved separately from the external xxHash library notice. The LZ4 command-line tools are not shipped; their GPL license does not replace the BSD license of the shipped library.

OpenSSL attribution: Copyright (c) 1998-2026 The OpenSSL Project Authors; Copyright (c) 1995-1998 Eric A. Young, Tim J. Hudson. All rights reserved. See the [versioned upstream README](https://github.com/openssl/openssl/blob/openssl-3.6.2/README.md).

## Full license texts

The exact upstream texts are retained under [LICENSES/](LICENSES/):

- [rsync GPLv3 and OpenSSL/xxhash exception](LICENSES/rsync-COPYING.txt)
- [OpenSSL Apache License 2.0](LICENSES/openssl-LICENSE.txt)
- [LZ4 BSD license](LICENSES/lz4-LICENSE.txt) and [included xxHash notice](LICENSES/lz4-xxhash-LICENSE.txt)
- [popt 1.19 MIT license](LICENSES/popt-COPYING.txt)
- [rsync's included popt permission](LICENSES/rsync-popt-COPYING.txt)
- [rsync's included zlib notice](LICENSES/rsync-zlib-LICENSE.txt)
- [xxHash BSD license](LICENSES/xxhash-LICENSE.txt)
- [Zstandard BSD license](LICENSES/zstd-LICENSE.txt) and [included xxHash notice](LICENSES/zstd-xxhash-LICENSE.txt)

Binary redistribution must carry the applicable license, copyright and disclaimer texts. Retain upstream notices and mark modified source versions where required. Apache-2.0 redistribution must also preserve applicable notices, including any upstream NOTICE supplied with the source; OpenSSL 3.6.2 supplies `LICENSE.txt` without a separate root NOTICE. BSD/MIT attribution belongs in the accompanying materials. The zlib license requires its notice to remain in source distributions; binary documentation acknowledgment is appreciated but not mandatory.

## rsync redistribution

rsync's source-file headers grant GPL version 3 or later. Its `COPYING` includes the full GPLv3 text and a specific exception permitting compliant dynamic linking with OpenSSL and xxhash. Do not omit that exception or apply FST's non-commercial restriction to rsync.

GPLv3 sections 4–6 require preservation of notices and provision of the license and machine-readable Corresponding Source when distributing object code through an applicable section 6 route. Corresponding Source includes the source and scripts needed to build/install the covered work, along with applicable changes and dependencies. A generic upstream homepage is not proof that the complete source corresponds to a shipped binary.

The official rsync 3.4.4 source archive is available at [download.samba.org](https://download.samba.org/pub/rsync/src/rsync-3.4.4.tar.gz).

SHA-256: `bd88cf82fa653da32314fb229136407c5c90f80d1758d8f4b091767877d8fa96`.

For Intel, [the native build script](../../scripts/build-rsync-intel.sh) downloads and checks that archive, uses included popt/zlib, disables optional OpenSSL/xxhash/zstd/lz4, and records the configuration. Future Intel packaging includes that exact source archive and the build script with the app. The archive and recipe alone do not establish compliance of earlier packages.

For ARM64, the exact source, patches, dependency sources and build/install recipe corresponding to the checked-in rsync binary have not all been established. Future ARM64 packaging requires a separately reviewed corresponding-source archive via `RSYNC_ARM64_SOURCE_ARCHIVE`; the script verifies archive readability, not legal completeness. Do not distribute that package until its provenance and source completeness are verified.

## v1.4.0 remediation status

The already-published ARM64 ZIP contains rsync and five dylibs without accompanying license text. The Intel ZIP contains rsync's `COPYING` but omits the required included-popt notice and package-local corresponding-source instructions. These notice and source-availability omissions remain unresolved in the published v1.4.0 packages.

Future packaging stages project notices and the applicable third-party license texts in `Contents/Resources/ThirdPartyNotices/`, and supplies the available corresponding-source material under `Contents/Resources/ThirdPartySources/`. See [the packaging helper](../../scripts/stage-third-party-notices.sh).

**NEEDS_LEGAL_REVIEW:** confirm complete ARM64 corresponding source and dependency provenance, and review whether FST/rsync distribution qualifies as aggregation under GPLv3 section 5 rather than a combined work. The current project license itself remains pending formal legal review. The component licenses listed here do not establish compliance of the published packages or resolve that legal boundary.
