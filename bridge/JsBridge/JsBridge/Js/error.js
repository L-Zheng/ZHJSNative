
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

window.onerror = (function (oriFunc) {
    /**不能使用箭头函数 否则arguments找不到*/
    return function () {
        try {
            /**发送至webview控制台*/
            if (oriFunc) oriFunc.apply(window, arguments);
            /**获取参数*/
            var params = arguments;
            /**发送至iOS原生*/
            if (Object.prototype.toString.call(params) != '[object Arguments]') return;
            var argCount = params.length;
            if (argCount == 0) return;

            var fetchValue = function (idx) {
                return argCount > idx ? params[idx] : 'no this params at index: ' + idx;
            };
            var firstParma = fetchValue(0);
            var isError = (Object.prototype.toString.call(firstParma) == '[object Error]');

            var fetchErrorValue = function (params, key) {
                return params.hasOwnProperty(key) ? params[key] : 'no this key: ' + key;
            };
            
            var resErr = JSON.parse(JSON.stringify({
                message: isError ? fetchErrorValue(firstParma, 'message') : fetchValue(0),
                sourceURL: isError ? fetchErrorValue(firstParma, 'sourceURL') : fetchValue(1),
                line: isError ? fetchErrorValue(firstParma, 'line') : fetchValue(2),
                column: isError ? fetchErrorValue(firstParma, 'column') : fetchValue(3),
                stack: isError ? fetchErrorValue(firstParma, 'stack').toString() : fetchValue(4)
            }));
            /** 发送消息name:与iOS原生保持一致 */
            My_JsBridge_Error_Replace_Api.sendNative(resErr);
        } catch (error) { 
        }
    }
})(window.onerror);
