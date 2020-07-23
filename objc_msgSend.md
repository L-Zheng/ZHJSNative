# objc_msgSend

## 发现 `objc_msgSend`

```ObjectiveC
Person *person = [Person alloc];
[person setLbz_name:@"ffff"];
```

使用 `clang -rewrite-objc main.m` 编译以上代码得到:

```ObjectiveC
Person *person = (   (Person *(*)(id, SEL))(void *)  objc_msgSend)
                    (
                        (id)objc_getClass("Person"),
                        sel_registerName("alloc")
                    );

(  (void (*)(id, SEL, NSString *))(void *)  objc_msgSend  )
(
        (id)person,
        sel_registerName("setLbz_name:"),
        (NSString *)&__NSConstantStringImpl__var_folders_r7_f6d_j39n1sqcpcqn9yp633540000gn_T_main_5cca37_mi_0
);
```

可以看到 ObjectiveC 是通过 `objc_msgSend` 发送消息的。

## 使用 `objc_msgSend`

> `objc_msgSend方法` 导致的编译器报错 `Too many arguments to function call, expected 0, have 2`  
解决：选择 `Target` ->`Build Settings` -> `Apple Clang - Preprocessing` -> `Enable Strict Checking of objc_msgSend方法 Calls` -> 选择 `NO`。

```ObjectiveC
// 1、objc_msgSend 接受者  方法编号  参数
objc_msgSend(id _Nullable self, SEL _Nonnull op, ...)

Person *person = [Person alloc];

// 发送实例方法
objc_msgSend(person, sel_registerName("testInstance"));
// objc_msgSend(person, @selector(testInstance));

// 发送类方法
objc_msgSend([person class], sel_registerName("testClass"));
// objc_msgSend(person, @selector(testInstance));
```

```ObjectiveC
// 2、objc_msgSendSuper objc_super接受者  方法编号  参数
objc_msgSendSuper(struct objc_super * _Nonnull super, SEL _Nonnull op, ...)
struct objc_super {
    __unsafe_unretained _Nonnull id receiver;
    __unsafe_unretained _Nonnull Class super_class;
};

Person *p = [Person alloc];
Student *s = [Student alloc];

// 向父类发消息(对象方法)
struct objc_super tSuper;
tSuper.receiver = s;
lgSuper.super_class = [Person class];// student的父类是Person
objc_msgSendSuper(&tSuper, @selector(testInstance));

// 向父类发消息(类方法)
struct objc_super tSuper;
tSuper.receiver = [s class];
// 获取 元类的父类
lgSuper.super_class = class_getSuperclass(object_getClass([s class]));
objc_msgSendSuper(&tSuper, @selector(testInstance));
```

## `objc_msgSend` 底层流程

查看 `objc` 源码，在 `objc-msg-arm64.s` 文件中，看里面的注释。

> objc_msgSend的底层使用汇编实现：  
1、汇编效率更高，提高性能。  
2、~~在发送消息时，参数类型、个数都是未知的。而objc_msgSend是静态C函数。~~  

> 总体流程：  
`objc_msgSend` --> 获取isa、class：`GetClassFromIsa_p16` --> 找catche_t方法缓存：`CacheLookup`
>> --> 有缓存：缓存命中 `CacheHit`  
--> 调用方法：`TailCallCachedImp x17, x12, x1, x16`  
--> `return;`

>> --> 没有缓存：缓存缺失 `CheckMiss`  
--> `objc_msgSend_uncached`  
--> `MethodTableLookup`  
--> objc-runtime-new.mm.进入类中查找(本文下面的章节)：`lookUpImpOrForward`  
>>> --> 默认转发处理函数(崩溃函数)  
--> 缓存中查找。<font color=#ff0000 size=4 face="微软雅黑">存在：流程终止 goto call;</font>  
--> 如果类没有实现，先实现类，因为方法存在于类中  
--> 如果类没有初始化，先初始化类，此过程会调用initialize方法  
--> 开始循环遍历查找、二分查找比较 `method_t->name`。<font color=#ff0000 size=4 face="微软雅黑">存在：流程终止 goto call;</font>  
--> 没有找到方法，尝试resolver进行动态决议。`resolveInstanceMethod` `resolveClassMethod`  
--> 决议后，再次进行查找`goto lookUpImpOrForward`。<font color=#ff0000 size=4 face="微软雅黑">存在：流程终止 goto call;</font>
>> 消息快速转发：
`- (id)forwardingTargetForSelector:(SEL)aSelector`。
>>> 1、`return obj;` 交由obj对象处理。<font color=#ff0000 size=4 face="微软雅黑">流程终止。</font>
2、`return nil;` or `return [super forwardingTargetForSelector:sel];` <font color=#ff0000 size=4 face="微软雅黑">进入下一阶段。</font>
>> 消息慢速转发：
`- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector`  
>>> 1、`return NSMethodSignature实例对象;` <font color=#ff0000 size=4 face="微软雅黑">进入下个方法。</font>  
2、`return nil;` or `return [super methodSignatureForSelector:sel];` <font color=#ff0000 size=4 face="微软雅黑">流程终止 App崩溃</font>
>> `- (void)forwardInvocation:(NSInvocation *)anInvocation`  
>>> 1、`自行处理 or 不做任何处理` <font color=#ff0000 size=4 face="微软雅黑">消息处理 or 丢弃。</font>  
2、`[super forwardInvocation:sel];` <font color=#ff0000 size=4 face="微软雅黑">流程终止 App崩溃</font>  
>>
> --> call: 调用方法：`TailCallFunctionPointer x17`

```C
// 👇函数入口
ENTRY _objc_msgSend
UNWIND _objc_msgSend, NoFrame

cmp p0, #0   // nil check and tagged pointer check
#if SUPPORT_TAGGED_POINTERS
b.le LNilOrTagged  //  (MSB tagged pointer looks negative)
#else
b.eq LReturnZero
#endif
ldr p13, [x0]  // p13 = isa
GetClassFromIsa_p16 p13  // p16 = class
LGetIsaDone:
// calls imp or objc_msgSend_uncached
CacheLookup NORMAL, _objc_msgSend

// 👇查找方法缓存
.macro CacheLookup
.endmacro
```

找到缓存的方法

```ObjectiveC
// 找到了
.macro CacheHit
.if $0 == NORMAL
    TailCallCachedImp x17, x12, x1, x16 // authenticate and call imp
.elseif $0 == GETIMP
    mov p0, p17
    cbz p0, 9f   // don't ptrauth a nil imp
    AuthAndResignAsIMP x0, x12, x1, x16 // authenticate imp and re-sign as IMP
9: ret    // return IMP
.elseif $0 == LOOKUP
    // No nil check for ptrauth: the caller would crash anyway when they
    // jump to a nil IMP. We don't care if that jump also fails ptrauth.
    AuthAndResignAsIMP x17, x12, x1, x16 // authenticate imp and re-sign as IMP
    ret    // return imp via x17
.else
.abort oops
.endif
.endmacro
```

没有找到缓存的方法

```ObjectiveC
.macro CheckMiss
.endmacro

// 👇 发送方法 objc_msgSend_uncached
STATIC_ENTRY __objc_msgSend_uncached
UNWIND __objc_msgSend_uncached, FrameWithNoSaves

// THIS IS NOT A CALLABLE C FUNCTION
// Out-of-band p16 is the class to search

MethodTableLookup//👈类中查找方法 imp存在x17寄存器中
TailCallFunctionPointer x17//👈执行方法

END_ENTRY __objc_msgSend_uncached

// 👇类中查找方法
.macro MethodTableLookup
    // push frame
    SignLR
    stp fp, lr, [sp, #-16]!
    mov fp, sp
    // 👇准备方法参数
    // save parameter registers: x0..x8, q0..q7
    sub sp, sp, #(10*8 + 8*16)
    stp q0, q1, [sp, #(0*16)]
    stp q2, q3, [sp, #(2*16)]
    stp q4, q5, [sp, #(4*16)]
    stp q6, q7, [sp, #(6*16)]
    stp x0, x1, [sp, #(8*16+0*8)]
    stp x2, x3, [sp, #(8*16+2*8)]
    stp x4, x5, [sp, #(8*16+4*8)]
    stp x6, x7, [sp, #(8*16+6*8)]
    str x8,     [sp, #(8*16+8*8)]

    // lookUpImpOrForward(obj, sel, cls, LOOKUP_INITIALIZE | LOOKUP_RESOLVER)
    // receiver and selector already in x0 and x1
    mov x2, x16
    mov x3, #3
    /**👇跳转到objc-runtime-new.mm的c函数lookUpImpOrForward
    */
    bl _lookUpImpOrForward

    /**👇获得的imp方法在寄存器x0中，复制到寄存器x17中
    */
    // IMP in x0
    mov x17, x0

    // restore registers and return
    ldp q0, q1, [sp, #(0*16)]
    ldp q2, q3, [sp, #(2*16)]
    ldp q4, q5, [sp, #(4*16)]
    ldp q6, q7, [sp, #(6*16)]
    ldp x0, x1, [sp, #(8*16+0*8)]
    ldp x2, x3, [sp, #(8*16+2*8)]
    ldp x4, x5, [sp, #(8*16+4*8)]
    ldp x6, x7, [sp, #(8*16+6*8)]
    ldr x8,     [sp, #(8*16+8*8)]

    mov sp, fp
    ldp fp, lr, [sp], #16
    AuthenticateLR

.endmacro
```

## 查找或动态决议方法 `lookUpImpOrForward`

看下 `lookUpImpOrForward` 方法的实现。

```ObjectiveC
IMP lookUpImpOrForward(id inst, SEL sel, Class cls, int behavior){
    //👇 默认转发处理函数(崩溃函数)：看本文下面的章节
    const IMP forward_imp = (IMP)_objc_msgForward_impcache;
    IMP imp = nil;
    Class curClass;

    runtimeLock.assertUnlocked();

    //👇 优先查找缓存
    if (fastpath(behavior & LOOKUP_CACHE)) {
        imp = cache_getImp(cls, sel);
        if (imp) goto done_nolock;
    }
    runtimeLock.lock();

    checkIsKnownClass(cls);

    //👇 如果类没有实现，先实现类，因为方法存在于类中，
    // 转到 --> realizeClassWithoutSwift
    if (slowpath(!cls->isRealized())) {
        cls = realizeClassMaybeSwiftAndLeaveLocked(cls, runtimeLock);
    }

    //👇 如果类没有初始化，先初始化类，此过程会调用initialize方法
    if (slowpath((behavior & LOOKUP_INITIALIZE) && !cls->isInitialized())) {
        cls = initializeAndLeaveLocked(cls, inst, runtimeLock);
    }

    runtimeLock.assertLocked();
    curClass = cls;

    //👇 开始循环遍历查找
    for (unsigned attempts = unreasonableClassCount();;) {
        //👇 本类中查找：如何查找：看本文下面的章节
        Method meth = getMethodNoSuper_nolock(curClass, sel);
        if (meth) {
            imp = meth->imp;
            goto done;
        }

        //👇 父类为nil，返回默认转发函数(崩溃函数)
        if (slowpath((curClass = curClass->superclass) == nil)) {
            imp = forward_imp;
            break;
        }

        // Halt if there is a cycle in the superclass chain.
        if (slowpath(--attempts == 0)) {
            _objc_fatal("Memory corruption in class list.");
        }

        //👇 父类缓存中查找方法
        imp = cache_getImp(curClass, sel);
        if (slowpath(imp == forward_imp)) {
            break;
        }
        //👇 父类中找到方法，将此方法缓存在本类中
        if (fastpath(imp)) {
            goto done;
        }
    }

    //👇 没有找到方法，尝试resolver进行动态决议，动态决议后，再次进行查找方法(此时不会再进行决议了)
    if (slowpath(behavior & LOOKUP_RESOLVER)) {
        // 👇 异或：相同取0 不同取1
        behavior ^= LOOKUP_RESOLVER;
        // 👇 如何进行动态决议：看本文下面的章节
        return resolveMethod_locked(inst, sel, cls, behavior);
    }
//👇 找到方法处理
 done:
    log_and_fill_cache(cls, imp, sel, inst, curClass);
    runtimeLock.unlock();
//👇 没有找到方法处理
 done_nolock:
    if (slowpath((behavior & LOOKUP_NIL) && imp == forward_imp)) {
        return nil;
    }
    return imp;
}
```

### 初始化类 `initializeAndLeaveLocked`

<font color=#ff0000 size=4 face="微软雅黑">initialize调用顺序：父类-->子类</font>  [参见+load与+initialize.md](../+load与+initialize.md)

`initializeAndLeaveLocked` -->  
`initializeAndMaybeRelock` -->  
`initializeNonMetaClass`

```ObjectiveC
void initializeNonMetaClass(Class cls)
{
    // 依次递归调用父类
    supercls = cls->superclass;
    if (supercls  &&  !supercls->isInitialized()) {
        initializeNonMetaClass(supercls);
    }
    // 调用initialize方法
    callInitialize(cls);
}

void callInitialize(Class cls)
{
    // 发送消息
    ((void(*)(Class, SEL))objc_msgSend)(cls, @selector(initialize));
}
```

### 默认转发处理函数(崩溃函数) `objc_defaultForwardHandler`

在上面的 `lookUpImpOrForward` 函数分析中，如果没有找到selector，最终会返回 `_objc_msgForward_impcache`。这是什么？？

在 `objc-msg-arm64.s` 中发现以下代码。

```ObjectiveC
STATIC_ENTRY __objc_msgForward_impcache

// 👇 跳转函数
b   __objc_msgForward

END_ENTRY __objc_msgForward_impcache


ENTRY __objc_msgForward

// 👇 将函数_objc_forward_handler 读取到寄存器x17中
adrp    x17, __objc_forward_handler@PAGE
ldr p17, [x17, __objc_forward_handler@PAGEOFF]
// 👇 执行函数
TailCallFunctionPointer x17

END_ENTRY __objc_msgForward
```

`_objc_forward_handler` 又是什么？

在 `objc-runtime.mm` 中有定义

```ObjectiveC
// Default forward handler halts the process.
__attribute__((noreturn, cold)) void
objc_defaultForwardHandler(id self, SEL sel){
    _objc_fatal("%c[%s %s]: unrecognized selector sent to instance %p "
                "(no message forward handler is installed)",
                class_isMetaClass(object_getClass(self)) ? '+' : '-',
                object_getClassName(self), sel_getName(sel), self);
}
void *_objc_forward_handler = (void*)objc_defaultForwardHandler;
```

可以看到：当selector找不到时，上面的代码就是xcode控制台输出的崩溃信息。

### `getMethodNoSuper_nolock` 如何查找

直接上代码

```ObjectiveC
static method_t * getMethodNoSuper_nolock(Class cls, SEL sel){
    // 👇 获取方法列表 开始遍历
    auto const methods = cls->data()->methods();
    for (auto mlists = methods.beginLists(),
              end = methods.endLists();
         mlists != end;
         ++mlists){
        // 👇 调用函数
        method_t *m = search_method_list_inline(*mlists, sel);
        if (m) return m;
    }

    return nil;
}

ALWAYS_INLINE static method_t * search_method_list_inline(const method_list_t *mlist, SEL sel){
    int methodListIsFixedUp = mlist->isFixedUp();
    int methodListHasExpectedSize = mlist->entsize() == sizeof(method_t);

    // 👇 一般情况下：方法都是排序好的
    if (fastpath(methodListIsFixedUp && methodListHasExpectedSize)) {
        return findMethodInSortedMethodList(sel, mlist);
    } else {
        // 👇 未排序，查找
        for (auto& meth : *mlist) {
            if (meth.name == sel) return &meth;
        }
    }
    return nil;
}

// 👇 真正开始查找
ALWAYS_INLINE static method_t * findMethodInSortedMethodList(SEL key, const method_list_t *list){
    const method_t * const first = &list->first;
    const method_t *base = first;
    const method_t *probe;
    uintptr_t keyValue = (uintptr_t)key;
    uint32_t count;
    /** 👇 大概的查找算法是：二分法
    将 selector转换成 unsign long型
    获取list的的首地址
    （可以使用lldb调试 p list->get(0) p &(list->get(0))输出方法，
    每个 method_t 占用 24字节）
    将 list->count 右移两位，使数量减半
    首地址first+数组索引，获取method_t
    比较 method_t->name，注意只比较name，不区分是类方法还是实例方法，然后依次二分区域查找。
    */
    for (count = list->count; count != 0; count >>= 1) {
        probe = base + (count >> 1);

        uintptr_t probeValue = (uintptr_t)probe->name;

        if (keyValue == probeValue) {
            while (probe > first && keyValue == (uintptr_t)probe[-1].name) {
                probe--;
            }
            return (method_t *)probe;
        }

        if (keyValue > probeValue) {
            base = probe + 1;
            count--;
        }
    }

    return nil;
}
```

### `resolveMethod_locked` 如何动态决议

```ObjectiveC
static NEVER_INLINE IMP resolveMethod_locked(id inst, SEL sel, Class cls, int behavior){
    if (! cls->isMetaClass()) {
        // 👇 实例方法 当调用[p test]时来到这里
        // 拿到 class 发送类方法 resolveInstanceMethod:
        resolveInstanceMethod(inst, sel, cls);
    }
    else {
        // 👇 类方法 当调用[Person test]时来到这里
        // 拿到 class(指向metaClass的class) 发送类方法 resolveClassMethod:
        resolveClassMethod(inst, sel, cls);
        if (!lookUpImpOrNil(inst, sel, cls)) {
            // 仍然没有决议找到 给元类发送类方法：即：去NSObject的元类中决议
            resolveInstanceMethod(inst, sel, cls);
        }
    }
    // 👇 决议后 再次查找方法
    return lookUpImpOrForward(inst, sel, cls, behavior | LOOKUP_CACHE);
}

static void resolveInstanceMethod(id inst, SEL sel, Class cls)
{
    // 👇 决议方法：resolveInstanceMethod
    SEL resolve_sel = @selector(resolveInstanceMethod:);
    /** 👇 方法是否实现
    默认在NSObject.mm中实现了此方法
    + (BOOL)resolveInstanceMethod:(SEL)sel {
        return NO;
    }
    */
    if (!lookUpImpOrNil(cls, resolve_sel, cls->ISA())) {
        return;
    }
    /** 👇 调用方法resolveInstanceMethod
    接受者是class而不是对象 可以看出 调用的是类方法
    */
    BOOL (*msg)(Class, SEL, SEL) = (typeof(msg))objc_msgSend;
    bool resolved = msg(cls, resolve_sel, sel);

    // 👇 决议后 再次查找方法
    IMP imp = lookUpImpOrNil(inst, sel, cls);

    if (resolved  &&  PrintResolving) {
        if (imp) {
            _objc_inform("RESOLVE: method %c[%s %s] "
                         "dynamically resolved to %p",
                         cls->isMetaClass() ? '+' : '-',
                         cls->nameForLogging(), sel_getName(sel), imp);
        }
        else {
            // Method resolver didn't add anything?
            _objc_inform("RESOLVE: +[%s resolveInstanceMethod:%s] returned YES"
                         ", but no new implementation of %c[%s %s] was found",
                         cls->nameForLogging(), sel_getName(sel),
                         cls->isMetaClass() ? '+' : '-',
                         cls->nameForLogging(), sel_getName(sel));
        }
    }
}

```

## `objc_msgSend` 方法调用调试信息、崩溃分析[unrecognized selector sent to instance]

### 方法调用调试信息

在 `lookUpImpOrForward` 函数的结尾，当找到目标方法时，会执行 `log_and_fill_cache`。

```ObjectiveC
static void log_and_fill_cache(Class cls, IMP imp, SEL sel, id receiver, Class implementer)
{
#if SUPPORT_MESSAGE_LOGGING
    // 👇 输出方法调用栈
    if (slowpath(objcMsgLogEnabled && implementer)) {
        bool cacheIt = logMessageSend(implementer->isMetaClass(),
                                      cls->nameForLogging(),
                                      implementer->nameForLogging(),
                                      sel);
        if (!cacheIt) return;
    }
#endif
    // 👇 缓存方法
    cache_fill(cls, sel, imp, receiver);
}
// 👇 输出方法调用栈
bool logMessageSend(bool isClassMethod,
                    const char *objectsClass,
                    const char *implementingClass,
                    SEL selector)
{
    char    buf[ 1024 ];

    // Create/open the log file
    if (objcMsgLogFD == (-1))
    {
        snprintf (buf, sizeof(buf), "/tmp/msgSends-%d", (int) getpid ());
        objcMsgLogFD = secure_open (buf, O_WRONLY | O_CREAT, geteuid());
        if (objcMsgLogFD < 0) {
            // no log file - disable logging
            objcMsgLogEnabled = false;
            objcMsgLogFD = -1;
            return true;
        }
    }
}
```

以上代码可以看出，在debug环境下，当 `objcMsgLogEnabled = true` 时，`objc` 会输出 `方法调用信息` 到文件 `/tmp/msgSends` 中去。

如何将 `objcMsgLogEnabled = true` ??  
调用方法 `instrumentObjcMessageSends(true)`

```ObjectiveC
void instrumentObjcMessageSends(BOOL flag)
{
    bool enable = flag;

    // Shortcut NOP
    if (objcMsgLogEnabled == enable)
        return;

    // If enabling, flush all method caches so we get some traces
    if (enable)
        _objc_flush_caches(Nil);

    // Sync our log file
    if (objcMsgLogFD != -1)
        fsync (objcMsgLogFD);

    objcMsgLogEnabled = enable;
}
```

因此，在 `没有链接 objc 源码的` 项目中，运行以下代码。 `链接 objc 源码的话，可能会造成其他崩溃`。

```ObjectiveC
instrumentObjcMessageSends(true);
[person test];//调用一个未实现的方法
instrumentObjcMessageSends(false);
```

打开文件 `/tmp/msgSends` 有以下信息，可以看到消息的决议、转发。

```ObectiveC
+ Person NSObject resolveInstanceMethod:
- Person NSObject forwardingTargetForSelector:
- Person Person methodSignatureForSelector:
- Person Person forwardInvocation:
```

### 崩溃分析[unrecognized selector sent to instance]

在崩溃栈中的 `__forwarding__` 汇编中，可以依次看到以下方法(在系统的CoreFundation库中)。

```ObjectiveC
"forwardingTargetForSelector:"
"methodSignatureForSelector:"
"_forwardStackInvocation:"
"forwardInvocation:"
```

> 结合 `Xcode Developer Document`，`forwardingTargetForSelector` 函数的具体介绍。

## 消息转发流程

三个流程。

```ObjectiveC
// 1、👇动态决议
+ (BOOL)resolveInstanceMethod:(SEL)sel{
    // todo 自行决议处理 return NO;进入第二步
    // 系统默认NO
    return [super resolveInstanceMethod:sel];
}
// 2、👇快速转发：交给一个对象来处理
- (id)forwardingTargetForSelector:(SEL)aSelector{
    if (aSelector == @selector(test)) {
        // todo 返回要处理的对象 return nil 进入第三步
        return [[Student alloc] init];
    }
    // 进入第三步
    return [super forwardingTargetForSelector:aSelector];
}
// 3、👇慢速转发：自行构造MethodSignature，指定对象处理
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector{
    if (aSelector == @selector(test)) {
        // 自行构造MethodSignature return nil：消息转发结束，App崩溃
        return [NSMethodSignature signatureWithObjCTypes:"v@:"];
    }
    // 消息转发结束，App崩溃
    return [super methodSignatureForSelector:aSelector];
}
- (void)forwardInvocation:(NSInvocation *)anInvocation{
   SEL aSelector = [anInvocation selector];
   // 1、指定对象处理 App不崩溃
   if ([[Student alloc] respondsToSelector:aSelector]){
       [anInvocation invokeWithTarget:[Student alloc]];
       return;
   }
   /** 2、交由父类处理 App崩溃
   - (void)forwardInvocation:(NSInvocation *)invocation {
        [self doesNotRecognizeSelector:
        (invocation ? [invocation selector] : 0)];
    }
    // Replaced by CF (throws an NSException)
    - (void)doesNotRecognizeSelector:(SEL)sel {
        _objc_fatal("-[%s %s]: unrecognized selector sent to instance %p",
                    object_getClassName(self), sel_getName(sel), self);
    }
   */
   [super forwardInvocation:anInvocation];
}
```

![1](./objc_msgSend1.png)

## 消息转发应用

```ObjectiveC
@interface Person : NSObject
- (void)test1;
+ (void)test2;
@end
@implementation Person
- (void)test11{
    NSLog(@"------------%s--------", __func__);
    NSLog(@"%@",self);
}
+ (void)test22{
    NSLog(@"------------%s--------", __func__);
    NSLog(@"%@",self);
}
// 👇 调用实例方法[p test1] 决议到 实例方法[p test11]
// 此时test11里面的self 是 对象p
+ (BOOL)resolveInstanceMethod:(SEL)sel{
    // self 为 [Peroson class]
    if (sel == @selector(test1)) {
        IMP imp = class_getMethodImplementation(self, @selector(test11));
        Method method = class_getInstanceMethod(self, @selector(test11));
        const char *type = method_getTypeEncoding(method);
        // 给[Peroson class]添加实例方法
        return class_addMethod(self, sel, imp, type);
    }
    return [super resolveInstanceMethod:sel];
}
// 👇 调用实例方法[p test1] 决议到 类方法[Person test22]
// 此时test22里面的self 不是 [Peroson class] 而是 对象p
+ (BOOL)resolveInstanceMethod:(SEL)sel{
    // self 为 [Peroson class]
    if (sel == @selector(test1)) {
        //获取元类
        Class metaClass = object_getClass(self);
        IMP imp = class_getMethodImplementation(metaClass, @selector(test22));
        Method method = class_getInstanceMethod(metaClass, @selector(test22));
        const char *type = method_getTypeEncoding(method);
        // 给[Peroson class]添加实例方法
        return class_addMethod(self, sel, imp, type);
    }
    return [super resolveInstanceMethod:sel];
}
// 👇 调用类方法[Person test2] 决议到 实例方法[Person test11]
// 此时test11里面的self 不是 对象p 而是 [Peroson class]
+ (BOOL)resolveClassMethod:(SEL)sel{
    // self 为 [Peroson class]
    if (sel == @selector(test2)) {
        //获取元类
        Class metaClass = object_getClass(self);
        IMP imp = class_getMethodImplementation(self, @selector(test11));
        Method method = class_getInstanceMethod(self, @selector(test11));
        const char *type = method_getTypeEncoding(method);
        // 给[Peroson class]的元类添加类方法
        return class_addMethod(metaClass, sel, imp, type);
    }
    return [super resolveClassMethod:sel];
}
// 👇 调用类方法[Person test2] 决议到 类方法[Person test22]
// 此时test22里面的self 是 [Peroson class]
+ (BOOL)resolveClassMethod:(SEL)sel{
    // self 为 [Peroson class]
    if (sel == @selector(test2)) {
        //获取元类
        Class metaClass = object_getClass(self);
        IMP imp = class_getMethodImplementation(metaClass, @selector(test22));
        Method method = class_getClassMethod(metaClass, @selector(test22));
        const char *type = method_getTypeEncoding(method);
        // 给[Peroson class]的元类添加类方法
        return class_addMethod(metaClass, sel, imp, type);
    }
    return [super resolveClassMethod:sel];
}
@end
```

## 注意点

给 `NSObject` 添加实例方法 `- (void)testObj{}`。  
使用 `[Person testObj]` 为什么会调用到 `NSObject` 的实例方法？？
> 此句代码会在 `Person` 的元类中 查找 `testObj` 方法， 然后依次向父类中查找。根据 `isa` 走位图( `NSObject元类` 的父类是 `NSObject`)，因此找到了 `NSObject` 中的 `testObj` 方法。  
`查找时只比较name，不区分是类方法还是实例方法。[getMethodNoSuper_nolock章节有介绍]`。

## 问题

当我们自行实现决议方法，而不作任何处理的话。  
为什么系统会调用两次决议方法？？

```ObjectiveC
+ (BOOL)resolveInstanceMethod:(SEL)sel{
    return [super resolveInstanceMethod:sel];
}
```

第一次调用：正常的 `objc_msgSend` 流程。
第二次调用：在此方法处断点分析。

在栈中的 `__forwarding__` 汇编中，可以依次看到以下方法(在系统的CoreFundation库中)。

```ObjectiveC
"forwardingTargetForSelector:"
"methodSignatureForSelector:"

0x7fff2f10904a <+402>:  callq  *0x57864380(%rip)         ; (void *)0x00000001002c1840: objc_msgSend

/** 在此处依次执行函数
methodSignatureForSelector
-->__methodDescriptionForSelector
--> class_getInstanceMethod
--> lookUpImpOrForward
*/
0x7fff2f109050 <+408>:  testq  %rax, %rax

"_forwardStackInvocation:"
"forwardInvocation:"
```

由此发现：系统在调用了 `methodSignatureForSelector` 函数后，又来到 `class_getInstanceMethod` 查找了一次方法，因此来到 `resolveInstanceMethod` 函数。

为什么这样做？？不知道🤣🤣🤣
