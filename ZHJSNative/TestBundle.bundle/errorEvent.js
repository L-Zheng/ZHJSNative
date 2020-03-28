
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
const ZhengJSToNativeErrorHandlerName = 'ZhengReplaceJSErrorEventHandler';
window.onerror = ((oriFunc) => {
    /**不能使用箭头函数 否则arguments找不到*/
    return function (...args) {
        /**发送至webview控制台*/
        if (oriFunc) oriFunc.apply(window, args);
        /**获取参数*/
        const params = arguments;
        const type = Object.prototype.toString.call(params);
        const argCount = params.length;
        /**发送至iOS原生*/
        if (type != '[object Arguments]') return;
        if (argCount == 0) return;

        const fetchVaule = (idx) => {
            return argCount > idx ? params[idx] : 'no this params';
        };
        const firstParma = fetchVaule(0);
        const isErrorParam = (Object.prototype.toString.call(firstParma) == '[object Error]');

        const iosRes = {
            message: isErrorParam ? firstParma.message : fetchVaule(0),
            sourceURL: isErrorParam ? firstParma.sourceURL : fetchVaule(1),
            line: isErrorParam ? firstParma.line : fetchVaule(2),
            column: isErrorParam ? firstParma.column : fetchVaule(3),
            stack: isErrorParam ? firstParma.stack.toString() : fetchVaule(4)
        };
        const res = JSON.parse(JSON.stringify(iosRes));
        try {
            const handler = window.webkit.messageHandlers[ZhengJSToNativeErrorHandlerName];
            handler.postMessage(res);
        } catch (error) { }
    }
})(window.onerror);