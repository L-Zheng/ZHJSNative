
/** Vue配置 
import Vue from 'vue';
Vue.config.errorHandler = ((oriFunc) => {
    return function (err, vm, info) {
        if (oriFunc) oriFunc.call(null, err, vm, info);
        if (window.onerror) window.onerror.call(null, err);
    }
})(Vue.config.errorHandler);
*/

/** 发送消息name:与iOS原生保持一致 */
var ZhengJSToNativeErrorHandlerName = 'ZhengReplaceJSErrorEventHandler';
window.onerror = (function (oriFunc) {
    /**不能使用箭头函数 否则arguments找不到*/
    return function () {
        /**发送至webview控制台*/
        if (oriFunc) oriFunc.call(window, arguments);
        /**获取参数*/
        var params = arguments;
        var type = Object.prototype.toString.call(params);
        var argCount = params.length;
        /**发送至iOS原生*/
        if (type != '[object Arguments]') return;
        if (argCount == 0) return;

        var fetchVaule = function (idx) {
            return argCount > idx ? params[idx] : 'libaozheng no this params';
        };
        var firstParma = fetchVaule(0);
        var isErrorParam = (Object.prototype.toString.call(firstParma) == '[object Error]');

        var iosRes = {
            message: isErrorParam ? firstParma.message : fetchVaule(0),
            sourceURL: isErrorParam ? firstParma.sourceURL : fetchVaule(1),
            line: isErrorParam ? firstParma.line : fetchVaule(2),
            column: isErrorParam ? firstParma.column : fetchVaule(3),
            stack: isErrorParam ? firstParma.stack.toString() : fetchVaule(4)
        };
        var res = JSON.parse(JSON.stringify(iosRes));
        try {
            var handler = window.webkit.messageHandlers[ZhengJSToNativeErrorHandlerName];
            handler.postMessage(res);
        } catch (error) { }
    }
})(window.onerror);