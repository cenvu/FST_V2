# FST v1.1 Release Notes

Version: 1.1  
Build: 20260630  
Package: `dist/FishSockTransfer-v1.1-b20260630-local-macOS13_5plus-arm64.zip`  
Package type: local owner-side ad-hoc build  
Platform: macOS 13.5+, Apple Silicon arm64 only

---

## Release State

FST v1.1 has been locally packaged and runtime tested on the owner Apple Silicon environment.

This release supports the locked MVP workflow:

```text
SOURCE -> COPY -> VERIFY -> SAFE TO EJECT
```

FST does not format media and does not eject media. It provides transfer and verification evidence for operator handoff.

---

## Completed in v1.1

- Bundled rsync 3.4.4 remains the only production transfer engine.
- Rsync stdout/stderr pipe draining was fixed so progress and logs do not stall behind pipe backpressure.
- Report timing fields now separate Copy Duration, Verify Duration, Total Duration, and Copy Average Speed.
- Copy Average Speed is based on copy duration only.
- Verification disabled reports Verify Duration as N/A where applicable.
- TXT reports include a summary at the top and FULL TECHNICAL LOG at the bottom.
- In-app Technical Logs hide verbose DIAG entries by default.
- Show Diagnostics reveals the full runtime diagnostic log stream.
- Verification modes are disclosed as SHA256 Sample 33% and xxHash64 Full 100%.
- xxHash64 is documented as fast non-cryptographic hash verification.
- SHA256 is documented as strong cryptographic hash verification.
- Package script validates app version, build number, minimum macOS, bundled rsync 3.4.4, arm64 architecture, dylib loader paths, ad-hoc codesign structure, and zip AppleDouble safety.

---

## Package Notes

Build the local package with:

```bash
bash scripts/package-local-arm64.sh
```

Expected output:

```text
dist/FishSockTransfer-v1.1-b20260630-local-macOS13_5plus-arm64.zip
```

Limitations:

- Local owner-side ad-hoc package only
- Not notarized
- Not Developer ID signed
- Apple Silicon arm64 only
- macOS 13.5+
- Not for Intel Macs

For owner-controlled testing only, if macOS blocks the app because it is unsigned or unnotarized, remove quarantine after unzipping:

```bash
xattr -dr com.apple.quarantine /path/to/FishSockTransfer.app
```

---

## Known Limitations

- Single source, single destination, single active job only.
- Multi-destination is deferred.
- Intel and universal packages are not included.
- Production-grade Developer ID signing and notarization are future work.
- Full release automation is future work.
- Performance optimization versus commercial tools is future work.
- xxHash64 Full 100% verification can dominate total duration on larger media sets.
- `Report saved:` may not appear inside the same report file because it is logged after report write.

---

## Safety Language

SAFE TO EJECT is shown only after copy success and verification pass.

Verification disabled ends at TRANSFER COMPLETE / COPY COMPLETE, never SAFE TO EJECT.

Operator-facing formatting language is forbidden in production workflow wording. The app does not format media.
