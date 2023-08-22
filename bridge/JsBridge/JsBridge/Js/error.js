
/** Vue配置 
import Vue from 'vue';
Vue.config.errorHandler = ((oriFunc) => {
    return function (err, vm, info) {
        try {
            if (oriFunc) oriFunc.call(null, err, vm, info);
            if (window.onerror) window.onerror.call(null, err);
        } catch (error) {
            
        }
    }
})(Vue.config.errorHandler);

1、本地的 html 文件
【Vue 项目(main.js 或者 App.vue) 或者 本地静态 html <script>】 里面的报错
[object Arguments] “Object”原型

["Script error.", "", 0, 0, null]

2、本地服务的 html
【Vue 项目(main.js 或者 App.vue)】 里面的报错
[object Arguments] “Object”原型

[
    // message  [object String]
    "TypeError: a.b is not a function. (In 'a.b()', 'a.b' is undefined)",
    // sourceURL [object String]
    "undefined",
    // line [object Number]
    21, 
    // column [object Number]
    4, 
    // [object Error]  “TypeError”原型
    {
        column: 4,
        line: 21,
        message: "a.b is not a function. (In 'a.b()', 'a.b' is undefined)",
        // 当在 App.vue 里报错时, stack = '@'
        stack: `eval code@
        eval@[native code]
        ./src/main.js@http://172.31.35.54:8080/js/index.js:2076:5
        __webpack_require__@http://172.31.35.54:8080/js/index.js:849:34
        fn@http://172.31.35.54:8080/js/index.js:151:39
        @http://172.31.35.54:8080/js/index.js:2089:37
        __webpack_require__@http://172.31.35.54:8080/js/index.js:849:34
        checkDeferredModules@http://172.31.35.54:8080/js/index.js:46:42
        @http://172.31.35.54:8080/js/index.js:925:38
        global code@http://172.31.35.54:8080/js/index.js:926:12`,
    }
]

3、本地服务的 html
【本地静态 html <script>】 里面的报错
[object Arguments] “Object”原型

[
    "TypeError: a.b is not a function. (In 'a.b()', 'a.b' is undefined)",
    "http://172.31.35.54:9090/index.html",
    13, 
    8, 
    // [object Error]  “TypeError”原型
    {
        column: 8,
        line: 13,
        message: "a.b is not a function. (In 'a.b()', 'a.b' is undefined)",
        sourceURL: "http://172.31.35.54:9090/index.html",
        stack: "global code@http://172.31.35.54:9090/index.html:13:8" ,
    }
]
*/

/*
https://blog.csdn.net/weixin_44727080/article/details/113347346

window.onerror是一个全局变量，默认值为null。
当有js运行时错误触发时，window会触发error事件，并执行window.onerror()。
onerror可以接受多个参数。

若该函数返回true，则阻止执行默认事件处理函数，如异常信息不会在console中打印。
没有返回值或者返回值为false的时候，异常信息会在console中打印
*/
window.onerror = (function (oriFunc) {
    /**不能使用箭头函数 否则arguments找不到*/
    return function () {
        try {
            /**发送至webview控制台*/
            if (oriFunc) {
                oriFunc.apply(window, arguments);
            }
            /**获取参数*/
            var params = arguments;
            // console.log('lbz-error1', params)
            /**发送至iOS原生*/
            if (Object.prototype.toString.call(params) != '[object Arguments]') {
                return;
            }
            var argCount = params.length;
            if (argCount == 0) {
                return;
            }
            var resErr = {};
            var keys = ['message', 'sourceURL', 'line', 'column', 'stack'];
            if (Object.prototype.toString.call(params[0]) == '[object Error]') {
                // 不能直接将 Error 直接赋值给 resErr, JSON.stringify(params[0]) 是一个空 json.
                keys.forEach(function (el) {
                    resErr[el] = params[0][el];
                });
            }
            else {
                if (argCount > 4 && (Object.prototype.toString.call(params[4]) == '[object Error]')) {
                    keys.forEach(function (el) {
                        resErr[el] = params[4][el];
                    });
                }
                else {
                    var minCount = Math.min(keys.length, argCount);
                    for (let i = 0; i < minCount; i++) {
                        resErr[keys[i]] = params[i];
                    }
                }
            }
            // console.log('lbz-error2', resErr)
            /** 发送消息name:与iOS原生保持一致 */
            _Replace_ErrorApi.sendNative(JSON.parse(JSON.stringify(resErr)));
        } catch (error) { 
        }
    }
})(window.onerror);
/* 
监听js运行时错误事件，会比window.onerror先触发，与onerror的功能大体类似，
不过事件回调函数传参只有一个保存所有错误信息的参数，不能阻止默认事件处理函数的执行，
但可以全局捕获资源加载异常的错误

当资源（如img或script）加载失败，加载资源的元素会触发一个Event接口的error事件，
并执行该元素上的onerror()处理函数。这些error事件不会向上冒泡到window，
但可以在捕获阶段被捕获, 因此如果要全局监听资源加载错误，需要在捕获阶段捕获事件

["Script error.", "", 0, 0, null] 
这种类型的报错会先触发 addEventListener('error'), 此时 
    Object.prototype.toString.call(arg) 为 [object ErrorEvent]
    arg.target 为 undefined
再触发 onerror
*/
// 使用 vue 项目本地服务调试时, 手动点击执行的js报错捕获不到, 但是自己写的简单的html能捕获到, 可能 vue 做了处理
window.addEventListener('error', function (arg) {
    var type = Object.prototype.toString.call(arg);
    // 资源找不到报错为 先触发addEventListener 后触发onerror
    if (type === '[object Event]' && arg.target && arg.target.tagName) {
        var res = {
            message: 'the resource(' + arg.target.tagName + ': ' + (arg.target.src || arg.target.href) + ') load fail.',
            tagName: arg.target.tagName,
            src: arg.target.src,
            href: arg.target.href
        };
        // console.log('lbz-addListen-error1', res);
        _Replace_ErrorApi.sendNative(JSON.parse(JSON.stringify(res)));
    }
    /*
    else if (type === '[object ErrorEvent]') {
        var keys = ['message', 'sourceURL', 'line', 'column', 'stack'];
        var resErr = {};
        if (arg.error) {
            keys.forEach(function (el) {
                resErr[el] = arg.error[el];
            });
        } else {
            resErr = {
                message: arg.message,
                sourceURL: arg.filename,
                line: arg.lineno,
                column: arg.colno,
                stack: arg.stack
            }
        }
        console.log('lbz-addListen-error2', resErr)
    }
    */
    // console.log('lbz-addListen-end', arg, type, arg.target, arg.target.tagName, arg.target.src || arg.target.href)
    // arg.preventDefault();
    return true;
  }, true);
