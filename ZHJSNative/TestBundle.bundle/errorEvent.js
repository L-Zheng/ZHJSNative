
/** 发送消息name:与iOS原生保持一致 */
const FNJSToNativeErrorHandlerName = 'ZHJSErrorEventHandler';
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
        const invaildDesc = '无此参数';
        const fetchVaule = (idx) => {
            return argCount > idx ? params[idx] : invaildDesc;
        };
        const iosRes = {
            'error-msg': fetchVaule(0),
            'file-url': fetchVaule(1),
            'lineNumber': fetchVaule(2),
            'columnNumber': fetchVaule(3),
            'error-stack': fetchVaule(4)
        };
        const res = JSON.parse(JSON.stringify(iosRes));
        try {
            const handler = window.webkit.messageHandlers[FNJSToNativeErrorHandlerName];
            handler.postMessage(res);
        } catch (error) { }
    }
})(window.onerror);