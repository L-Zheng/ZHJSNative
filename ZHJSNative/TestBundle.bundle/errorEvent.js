
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
*/

/** 发送消息name:与iOS原生保持一致 */
var ZhengJSToNativeErrorHandlerName = 'ZhengReplaceJSErrorEventHandler';
window.onerror = (function (oriFunc) {
    /**不能使用箭头函数 否则arguments找不到*/
    return function () {
        try {
            /**发送至webview控制台*/
            if (oriFunc) oriFunc.apply(window, arguments);
            /**获取参数*/
            var lbz_params = arguments;
            /**发送至iOS原生*/
            if (Object.prototype.toString.call(lbz_params) != '[object Arguments]') return;
            var lbz_argCount = lbz_params.length;
            if (lbz_argCount == 0) return;

            var lbz_fetchVaule = function (idx) {
                return lbz_argCount > idx ? lbz_params[idx] : 'libaozheng no this params';
            };
            var lbz_firstParma = lbz_fetchVaule(0);
            var lbz_isErrorParam = (Object.prototype.toString.call(lbz_firstParma) == '[object Error]');

            var lbz_fetchErrorVaule = function (params, key) {
                return params.hasOwnProperty(key) ? params[key] : 'libaozheng no this key: ' + key;
            };
            
            var lbz_res = JSON.parse(JSON.stringify({
                message: lbz_isErrorParam ? lbz_fetchErrorVaule(lbz_firstParma, 'message') : lbz_fetchVaule(0),
                sourceURL: lbz_isErrorParam ? lbz_fetchErrorVaule(lbz_firstParma, 'sourceURL') : lbz_fetchVaule(1),
                line: lbz_isErrorParam ? lbz_fetchErrorVaule(lbz_firstParma, 'line') : lbz_fetchVaule(2),
                column: lbz_isErrorParam ? lbz_fetchErrorVaule(lbz_firstParma, 'column') : lbz_fetchVaule(3),
                stack: lbz_isErrorParam ? lbz_fetchErrorVaule(lbz_firstParma, 'stack').toString() : lbz_fetchVaule(4)
            }));
            window.webkit.messageHandlers[ZhengJSToNativeErrorHandlerName].postMessage(lbz_res);
        } catch (error) { 
        }
    }
})(window.onerror);