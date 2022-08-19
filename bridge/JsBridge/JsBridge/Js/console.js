
console.log = (function (oriLogFunc) {
  return function () {
    /**发送至webview控制台*/
    oriLogFunc.apply(console, arguments);
    try {
      /**保留error信息*/
      var errorRes = [];
      /**解析数据*/
      var parseData = function (data) {
        var res = null;
        var type = Object.prototype.toString.call(data);
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
          var mapKeys = Object.keys(data);
          for (var i = 0; i < mapKeys.length; i++) {
            (function (key) {
              res[key] = parseData(data[key]);
            })(mapKeys[i]);
          }
        } else if (type == '[object Array]') {
          res = [];
          data.forEach(function (el) {
            res.push(parseData(el));
          });
        } else if (type == '[object Error]') {
          res = data;
          errorRes.push(res);
        } else if (type == '[object Window]') {
          res = data.toString();
        } else {
          res = data;
        }
        return res;
      };
      /**获取参数*/
      var params = arguments;
      /**发送至iOS原生*/
      if (Object.prototype.toString.call(params) != '[object Arguments]') return;
      var argCount = params.length;
      /**保留发送error*/
      var iosRes = [];
      var fetchVaule = function (aIdx) {
        return argCount > aIdx ? params[aIdx] : 'no this params at index: ' + aIdx;
      };
      if (argCount == 0) return;
      if (argCount == 1) {
        iosRes = parseData(fetchVaule(0));
      } else {
        for (var idx = 0; idx < argCount; idx++) {
          iosRes.push(parseData(fetchVaule(idx)));
        }
      }
      /** 发送消息name:与iOS原生保持一致 */
      _Replace_ConsoleApi.sendNative('log', JSON.parse(JSON.stringify(iosRes)));
    } catch (error) { }
    /**检测到log error弹窗提醒*/
    return;
    if (errorRes.length == 0) return;
    if (!window.onerror) return;
    try {
      errorRes.forEach(function (el) {
        window.onerror(el);
      });
    } catch (error) {
    }
  }
})(console.log);
