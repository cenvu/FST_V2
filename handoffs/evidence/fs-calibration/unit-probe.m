#import <Foundation/Foundation.h>
#include <sys/attr.h>
#include <sys/mount.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>

// Public Darwin volume attributes; read-only research, no device access.
int main(int argc, const char **argv) {
 @autoreleasepool {
  if (argc!=2) return 2;
  NSMutableDictionary *d=[NSMutableDictionary dictionary];
  const attrgroup_t flags[]={ATTR_VOL_SIZE,ATTR_VOL_SPACEFREE,ATTR_VOL_SPACEAVAIL,ATTR_VOL_MINALLOCATION,ATTR_VOL_ALLOCATIONCLUMP};
  const char *names[]={"size","spacefree","spaceavail","minallocation","allocationclump"};
  for (int i=0;i<5;i++) {
   struct attrlist attrs={0};attrs.bitmapcount=ATTR_BIT_MAP_COUNT;attrs.volattr=ATTR_VOL_INFO|flags[i];
   char buffer[64]={0};errno=0;
   if (getattrlist(argv[1],&attrs,buffer,sizeof(buffer),0)==0) {
    off_t value;memcpy(&value,buffer+sizeof(uint32_t),sizeof(value));d[@(names[i])]=@(value);
   } else d[@(names[i])]=@{@"errno":@(errno)};
  }
  errno=0;long value=pathconf(argv[1],_PC_ALLOC_SIZE_MIN);
  d[@"pathconf_alloc_size_min"]=@(value);d[@"pathconf_errno"]=@(errno);
  NSData *data=[NSJSONSerialization dataWithJSONObject:d options:NSJSONWritingSortedKeys error:nil];
  fwrite(data.bytes,1,data.length,stdout);puts("");
 }
}
