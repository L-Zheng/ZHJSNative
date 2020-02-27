
/** 发送消息name:与iOS原生保持一致 */
const FNJSToNativeLogHandlerName = 'ZHJSLogEventHandler';
console.log = (function(oriLogFunc){
    return function(obj){
        let newObj = obj;
        const type = Object.prototype.toString.call(newObj);
        if (type == '[object Function]'){
          newObj = newObj.toString();
        }
        const res = JSON.parse(JSON.stringify(newObj));
        const handler = window.webkit.messageHandlers[FNJSToNativeLogHandlerName];
        handler.postMessage(res);
        oriLogFunc.call(console,obj);
    }
})(console.log);