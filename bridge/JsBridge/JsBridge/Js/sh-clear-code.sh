sh error-shell.sh
sh event-shell.sh
sh console-shell.sh
sh socket-shell.sh

# 写入文件
res='#import <Foundation/Foundation.h>'

res=${res}'
static NSString * const JsBridge_resource_event = @"";'

res=${res}'
static NSString * const JsBridge_resource_console = @"";'

res=${res}'
static NSString * const JsBridge_resource_error = @"";'

res=${res}'
static NSString * const JsBridge_resource_socket = @"";'

echo "${res}" > ../Base/JsBridgeResource.h


# static NSString * const JsBridge_resource_event = @"";
# static NSString * const JsBridge_resource_console = @"";
# static NSString * const JsBridge_resource_error = @"";
# static NSString * const JsBridge_resource_socket = @"";
