# Bounded host diagnostics

TASK=PATCH3_NOTIFICATION_CANONICAL_VERIFICATION_RECOVERY
OBSERVED_AT=2026-10-02T16:26:44+07:00
HOST=macOS worker host; see uname output
SCOPE=READ_ONLY_HOST_OBSERVATION
DISK_ACTIONS=NONE
OWNER_MEDIA_TOUCHED=NONE

## `uname -a` (exit=0)

```text
Darwin Cens-MacBook-Pro.local 24.6.0 Darwin Kernel Version 24.6.0: Tue Apr 21 20:19:01 PDT 2026; root:xnu-11417.140.69.710.16~1/RELEASE_ARM64_T6000 arm64
```

## `sw_vers` (exit=0)

```text
ProductName:		macOS
ProductVersion:		15.7.7
BuildVersion:		24G720
```

## `hdiutil info` (exit=0)

```text
framework       : 671.140.2
driver          : 671.140.2
```

## `diskutil list` (exit=0)

```text
/dev/disk0 (internal, physical):
   #:                       TYPE NAME                    SIZE       IDENTIFIER
   0:      GUID_partition_scheme                        *1.0 TB     disk0
   1:             Apple_APFS_ISC Container disk1         524.3 MB   disk0s1
   2:                 Apple_APFS Container disk3         994.7 GB   disk0s2
   3:        Apple_APFS_Recovery Container disk2         5.4 GB     disk0s3

/dev/disk3 (synthesized):
   #:                       TYPE NAME                    SIZE       IDENTIFIER
   0:      APFS Container Scheme -                      +994.7 GB   disk3
                                 Physical Store disk0s2
   1:                APFS Volume MBP                     18.5 GB    disk3s1
   2:              APFS Snapshot com.apple.os.update-... 18.5 GB    disk3s1s1
   3:                APFS Volume Preboot                 16.4 GB    disk3s2
   4:                APFS Volume Recovery                2.4 GB     disk3s3
   5:                APFS Volume Macintosh HD - Data     814.7 GB   disk3s5
   6:                APFS Volume VM                      3.2 GB     disk3s6
```

## `getconf DARWIN_USER_TEMP_DIR` (exit=0)

```text
/var/folders/89/bwjml4px7bd8_gc4y493myh80000gn/T/
```

## `find /var/folders/89/bwjml4px7bd8_gc4y493myh80000gn/T/ -maxdepth 1 -type d -name FSTCapacityImageQA-* -print` disposable FST temp-root inspection (exit=0)

```text
(no matching temp roots)
```

## Assessment

HDIUTIL_ATTACHED_IMAGES=NONE_LISTED
FST_DISPOSABLE_TEMP_ROOTS=0
No stale image/root was detached, ejected, deleted, mounted, or otherwise changed. `diskutil list` reports the internal system disk only; no owner device was operated on.
TASK_DISCOVERY=No matching GitHub Issue; no duplicate recovery task found in relevant Task Registry / Work History entries.
