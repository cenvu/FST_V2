#import <Foundation/Foundation.h>
#include <sys/mount.h>
#include <sys/statvfs.h>

// Research probe only. Does not write to queried paths.
int main(int argc, const char **argv) {
    @autoreleasepool {
        if (argc != 2) return 2;
        struct statfs fs;
        struct statvfs vfs;
        if (statfs(argv[1], &fs) || statvfs(argv[1], &vfs)) return 3;
        NSURL *url = [NSURL fileURLWithPath:@(argv[1])];
        NSMutableDictionary *out = [@{
            @"fs_type": @(fs.f_fstypename), @"device": @(fs.f_mntfromname),
            @"statfs_f_bsize": @(fs.f_bsize), @"statfs_f_iosize": @(fs.f_iosize),
            @"f_frsize": @(vfs.f_frsize), @"statvfs_f_bsize": @(vfs.f_bsize),
            @"capacity": @(vfs.f_blocks * vfs.f_frsize),
            @"ordinary_statvfs": @(vfs.f_bavail * vfs.f_frsize),
            @"read_only": @((fs.f_flags & MNT_RDONLY) != 0)
        } mutableCopy];
        for (NSString *key in @[NSURLVolumeAvailableCapacityKey, NSURLVolumeAvailableCapacityForImportantUsageKey,
                                NSURLFileSizeKey, NSURLFileAllocatedSizeKey, NSURLTotalFileAllocatedSizeKey]) {
            id value = nil; NSError *error = nil;
            if ([url getResourceValue:&value forKey:key error:&error] && value) out[key] = value;
            else out[key] = [NSNull null];
        }
        NSData *json = [NSJSONSerialization dataWithJSONObject:out options:NSJSONWritingSortedKeys error:nil];
        fwrite(json.bytes, 1, json.length, stdout); puts("");
    }
}
