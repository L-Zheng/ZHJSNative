/** js语句必须带有 ;  注释方式使用带有闭合标签的
 * 【iOS原生是把该文件读取成字符串执行，没有结束标志js代码出错】
 *  var变量的作用区域 当前function上下文 
 */
/** ❌ios9 特殊处理
 * 不识别  let变量、() => {}箭头函数 、function函数不能有默认值 如：function(params = {})() 、多参数函数 function (...args)
 *         识别 const、 var、 function(){}
 *    如果当前function里面又调用了其他function  var作用域不会延伸到其它function
 *    如果当前function里面有其他function函数体  var作用域会延伸到其它function函数体
 */
/** ❌ios8 特殊处理
 * 不识别  let、const变量、() => {}箭头函数 、function函数不能有默认值 如：function(params = {})() 、多参数函数 function (...args)
 * 不识别模板字符串语法  `--${}`
 * 不识别语法  endsWith
 */
/**  函数参数 ...args  代表将参数arguments分割成args数组  等价于[arg1, arg2, arg3]
    foo.apply(this, arguments) == 
    foo.apply(this, [arg1, arg2, arg3]) == 
    foo.apply(this, args) == 
    foo.call(this, arg1, arg2, arg3) == 
    this.foo(arg1, arg2, arg3);
*/
/**
 * 最小化该js文件： 
 * uglify-es库地址 ：https://github.com/mishoo/UglifyJS2
 * npm install -g uglify-es
 * uglifyjs event.js -b beautify=false,quote_style=1 -o min-event.js
 * uglifyjs logEvent.js -b beautify=false,quote_style=1 -o min-log.js
 * uglifyjs errorEvent.js -b beautify=false,quote_style=1 -o min-error.js
 * uglifyjs socketEvent.js -b beautify=false,quote_style=1 -o min-socket.js
 */
/** 发送消息name:与iOS原生保持一致 */
var ZhengJSToNativeHandlerName = 'ZhengReplaceJSEventHandler';
var ZhengCallBackSuccessKey = 'ZhengReplaceCallBackSuccessKey';
var ZhengCallBackFailKey = 'ZhengReplaceCallBackFailKey';
var ZhengCallBackCompleteKey = 'ZhengReplaceCallBackCompleteKey';
var ZhengJSType = (function() {
    var type = {};
    var typeArr = ['String', 'Object', 'Number', 'Array', 'Undefined', 'Function', 'Null', 'Symbol', 'Boolean'];
    for (var i = 0; i < typeArr.length; i++) {
        (function(name) {
            type['is' + name] = function(obj) {
                return Object.prototype.toString.call(obj) == '[object ' + name + ']';
            }
        })(typeArr[i]);
    }
    return type;
})();
var ZhengCallBackMap = {};
var ZhengReplaceIosCallBack = function(params) {
    var funcRes = null;
    if (!ZhengJSType.isString(params) || !params) {
        return funcRes;
    }
    var newParams = JSON.parse(decodeURIComponent(params));
    if (!ZhengJSType.isObject(newParams)) {
        return funcRes;
    }
    var funcId = newParams.funcId;
    var res = newParams.data;
    var alive = newParams.alive;

    var randomKey = '',
        funcNameKey = '';
    var matchKey = function(key) {
        var matchNumber = funcId.length - key.length;
        if ((matchNumber >= 0) && funcId.lastIndexOf(key) == matchNumber) {
        }else{
            return false;
        }
        //ios 8不识别此语法
        // if (!funcId.endsWith(key)) return false;
        randomKey = funcId.replace(new RegExp(key, 'g'), '');
        funcNameKey = key;
        return true;
    };
    var matchRes = (matchKey(ZhengCallBackSuccessKey) || matchKey(ZhengCallBackFailKey) || matchKey(ZhengCallBackCompleteKey));
    if (!matchRes) return funcRes;

    var funcMap = ZhengCallBackMap[randomKey];
    if (!ZhengJSType.isObject(funcMap)) return funcRes;
    var func = funcMap[funcNameKey];
    if (!ZhengJSType.isFunction(func)) return funcRes;
    try {
        /** 
         * 原函数没有参数 complete: () => {}  调用func(res) 不会报错
         * 原函数有参数 complete: (res) => {}  调用func() 会报错 走catch
         */
        funcRes = func(res);
    } catch (error) {
        // console.log('CallBack-error');
        // console.log(error);
        funcRes = null;
    }
    if (alive) return funcRes;
    /** 回调complete后删除 */
    if (funcNameKey == ZhengCallBackCompleteKey) {
        ZhengRemoveCallBack(randomKey);
    }
    return funcRes;
}
/**
{
    '-request-1582972065568-79-': {
        ZhengCallBackSuccessKey: function
        ZhengCallBackFailKey: function
        ZhengCallBackCompleteKey: function
    }
}
 */
var ZhengAddCallBack = function(randomKey, funcNameKey, func) {
    var funcMap = ZhengCallBackMap[randomKey];
    if (!ZhengJSType.isObject(funcMap)) {
        var map = {};
        map[funcNameKey] = func;
        ZhengCallBackMap[randomKey] = map;
        return;
    }
    if (funcMap.hasOwnProperty(funcNameKey)) return;
    funcMap[funcNameKey] = func;
    ZhengCallBackMap[randomKey] = funcMap;
};
var ZhengRemoveCallBack = function(randomKey) {
    if (!ZhengCallBackMap.hasOwnProperty(randomKey)) return;
    delete ZhengCallBackMap[randomKey];
};
var ZhengHandleCallBackParams = function(methodName, params, index) {
    if (!ZhengJSType.isObject(params)) {
        return params;
    }
    /** 0-10000的随机整数 -request-1582972065568-0-79- */
    var randomKey = '-' + methodName + '-' + new Date().getTime().toString() + '-' + index + '-' + Math.floor(Math.random() * 10000).toString() + '-';
    /** 参数 */
    var newParams = params;
    var funcId = '';

    /** 成功回调 */
    var success = params.success;
    if (success && ZhengJSType.isFunction(success)) {
        funcId = randomKey + ZhengCallBackSuccessKey;
        ZhengAddCallBack(randomKey, ZhengCallBackSuccessKey, success);
        newParams[ZhengCallBackSuccessKey] = funcId;
    }
    /** 失败回调 */
    var fail = params.fail;
    if (fail && ZhengJSType.isFunction(fail)) {
        funcId = randomKey + ZhengCallBackFailKey;
        ZhengAddCallBack(randomKey, ZhengCallBackFailKey, fail);
        newParams[ZhengCallBackFailKey] = funcId;
    }
    /** 完成回调 */
    var complete = params.complete;
    if (complete && ZhengJSType.isFunction(complete)) {
        funcId = randomKey + ZhengCallBackCompleteKey;
        ZhengAddCallBack(randomKey, ZhengCallBackCompleteKey, complete);
        newParams[ZhengCallBackCompleteKey] = funcId;
    }
    return newParams;
};

/** 构造发送参数 */
var ZhengSendParams = function(apiPrefix, methodName, params) {
    /** arguments */
    var newParams = params;
    /** 处理参数 */
    var resArgs = [];
    if (Object.prototype.toString.call(newParams) === '[object Arguments]') {
        var argCount = newParams.length;
        for (var argIdx = 0; argIdx < argCount; argIdx++) {
            resArgs.push(ZhengHandleCallBackParams(methodName, newParams[argIdx], argIdx));
        }
    }
    return {methodName, apiPrefix, args: resArgs};
};
var ZhengSendNative = function(params) {
    var handler = window.webkit.messageHandlers[ZhengJSToNativeHandlerName];
    /** 必须这样【JSON.parse(JSON.stringify())】 否则js运行window.webkit.messageHandlers  会报错cannot be cloned */
    handler.postMessage(JSON.parse(JSON.stringify(params)));
};
var ZhengSendNativeSync = function(params) {
    var res = prompt(JSON.stringify(params));
    try {
        res = JSON.parse(res);
        return res.data;
    } catch (error) {
        console.log('❌SendNativeSync--error');
        console.log(error);
    }
    return null;
};
/** 当要移除api时 apiMap为{} */
var ZhengReplaceGeneratorAPI = function(apiPrefix, apiMap) {
    if (!apiPrefix || !ZhengJSType.isString(apiPrefix) || !ZhengJSType.isObject(apiMap)) {
        return {};
    }
    var res = {};
    var mapKeys = Object.keys(apiMap);
    for (var i = 0; i < mapKeys.length; i++) {
        (function(name) {
            /** 获取配置：isSync */
            var config = apiMap[name];
            var isSync = config.hasOwnProperty('sync') ? config.sync : false;
            /** 生成function */
            res[name] = isSync ? (function () {
                return ZhengSendNativeSync(ZhengSendParams(apiPrefix, name, arguments));
            }) : (function () {
                ZhengSendNative(ZhengSendParams(apiPrefix, name, arguments));
            });
        })(mapKeys[i]);
    }
    return res;
};
/** ❗️❗️Api配置说明：sync：是否是同步方法 */
/**
var fund = ZhengReplaceGeneratorAPI('fund', {
    request: {
        sync: false
    },
    getJsonSync: {
        sync: true
    },
    getNumberSync: {
        sync: true
    },
    getBoolSync: {
        sync: true
    },
    getStringSync: {
        sync: true
    },
    commonLinkTo: {
        sync: false
    }
});
var zheng = ZhengReplaceGeneratorAPI('zheng', {

});
 */

// var ZhengReadyEvent = document.createEvent('Event');
// ZhengReadyEvent.initEvent('ZhengJSBridgeReady');
// window.dispatchEvent(ZhengReadyEvent);
