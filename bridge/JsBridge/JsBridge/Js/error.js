
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
                keys.forEach(el => {
                    resErr[el] = params[0][el];
                });
            }
            else {
                if (argCount > 4 && (Object.prototype.toString.call(params[4]) == '[object Error]')) {
                    keys.forEach(el => {
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
            /** 发送消息name:与iOS原生保持一致 */
            _Replace_ErrorApi.sendNative(JSON.parse(JSON.stringify(resErr)));
        } catch (error) { 
        }
    }
})(window.onerror);
