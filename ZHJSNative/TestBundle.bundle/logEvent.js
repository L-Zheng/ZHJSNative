
/** 发送消息name:与iOS原生保持一致 */
const FNJSToNativeLogHandlerName = 'ZHJSLogEventHandler';
console.log = ((oriLogFunc) => {
    return (obj) => {
        const parseData = (data) => {
          let res = null;
          const type = Object.prototype.toString.call(data);
          if (type == '[object Null]' || type == '[object String]') {
            res = data;
          }else if (type == '[object Function]'){
            res = data.toString();
          }else if (type == '[object Undefined]') {
            res = 'Undefined';
          }else if (type == '[object Boolean]') {
            res = `[object Boolean]-->${data ? 'true' : 'false'}`;
          }else if (type == '[object Number]') {
            res = `[object Number]-->${data}`;
          }else if (type == '[object Object]') {
            res = {};
            for (const key in data) {
              const el = data[key];
              res[key] = parseData(el);
            }
          }else if (type == '[object Array]') {
            res = [];
            data.forEach(el => {
              res.push(parseData(el));
            });
          }
          return res;
        };
        let newObj = parseData(obj);
        const res = JSON.parse(JSON.stringify(newObj));
        const handler = window.webkit.messageHandlers[FNJSToNativeLogHandlerName];
        handler.postMessage(res);
        oriLogFunc.call(console,obj);
    }
})(console.log);