
/** 发送消息name:与iOS原生保持一致 */
const FNJSToNativeLogHandlerName = 'ZHJSLogEventHandler';
console.log = ((oriLogFunc) => {
  return function (...args) {
    /**发送至webview控制台*/
    oriLogFunc.call(console, ...args);
    /**保留error信息*/
    let errorRes = [];
    /**解析数据*/
    const parseData = (data) => {
      let res = null;
      const type = Object.prototype.toString.call(data);
      if (type == '[object Null]' || type == '[object String]' || type == '[object Number]') {
        res = data;
      } else if (type == '[object Function]') {
        res = data.toString();
      } else if (type == '[object Undefined]') {
        res = 'Undefined';
      } else if (type == '[object Boolean]') {
        res = data ? 'true' : 'false';
      } else if (type == '[object Object]') {
        res = {};
        for (const key in data) {
          const el = data[key];
          res[key] = parseData(el);
        }
      } else if (type == '[object Array]') {
        res = [];
        data.forEach(el => {
          res.push(parseData(el));
        });
      } else if (type == '[object Error]') {
        res = data;
        errorRes.push(res);
      }
      return res;
    };
    /**获取参数*/
    const params = arguments;
    const type = Object.prototype.toString.call(params);
    const argCount = params.length;
    /**发送至iOS原生*/
    if (type != '[object Arguments]') return;
    /**保留发送error*/
    let iosRes = [];
    const fetchVaule = (idx) => {
      return argCount > idx ? params[idx] : '无此参数';
    };
    if (argCount == 0) return;
    if (argCount == 1) {
      iosRes = parseData(fetchVaule(0));
    } else {
      for (let idx = 0; idx < argCount; idx++) {
        iosRes.push(parseData(fetchVaule(idx)));
      }
    }
    try {
      const handler = window.webkit.messageHandlers[FNJSToNativeLogHandlerName];
      handler.postMessage(JSON.parse(JSON.stringify(iosRes)));
    } catch (error) { }
    /**检测到log error弹窗提醒*/
    if (errorRes.length == 0) return;
    if (!window.onerror) return;
    try {
      errorRes.forEach(el => {
        window.onerror(el);
      });
    } catch (error) {
    }
  }
})(console.log);