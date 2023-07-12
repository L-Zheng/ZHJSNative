sh error-shell.sh
sh event-shell.sh
sh console-shell.sh
sh network-shell.sh
sh socket-shell.sh

# 写入文件
res='#import <Foundation/Foundation.h>'

content=`cat event-min.js`
res=${res}'
static NSString * const JsBridge_resource_event = @"'${content}'";'

content=`cat console-min.js`
res=${res}'
static NSString * const JsBridge_resource_console = @"'${content}'";'

content=`cat network-min.js`
res=${res}'
static NSString * const JsBridge_resource_network = @"'${content}'";'

content=`cat error-min.js`
res=${res}'
static NSString * const JsBridge_resource_error = @"'${content}'";'

content=`cat socket-min.js`
res=${res}'
static NSString * const JsBridge_resource_socket = @"'${content}'";'

echo "${res}" > ../Base/JsBridgeResource.h


# static NSString * const JsBridge_resource_event = @"";
# static NSString * const JsBridge_resource_console = @"";
# static NSString * const JsBridge_resource_network = @"";
# static NSString * const JsBridge_resource_error = @"";
# static NSString * const JsBridge_resource_socket = @"";