/** js语句必须带有 ;  注释方式使用带有闭合标签的
 * 【iOS原生是把该文件读取成字符串执行，没有结束标志js代码出错】
 *  var变量的作用区域 当前function上下文 
 *    如果当前function里面又调用了其他function  var作用域不会延伸到其它function
 *    如果当前function里面有其他function函数体  var作用域会延伸到其它function函数体
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
const ZhengJSToNativeHandlerName = 'ZhengReplaceJSEventHandler';
const ZhengCallBackSuccessKey = 'ZhengReplaceCallBackSuccessKey';
const ZhengCallBackFailKey = 'ZhengReplaceCallBackFailKey';
const ZhengCallBackCompleteKey = 'ZhengReplaceCallBackCompleteKey';
const ZhengJSType = (function() {
    let type = {};
    const typeArr = ['String', 'Object', 'Number', 'Array', 'Undefined', 'Function', 'Null', 'Symbol', 'Boolean'];
    for (let i = 0; i < typeArr.length; i++) {
        (function(name) {
            type['is' + name] = function(obj) {
                return Object.prototype.toString.call(obj) == '[object ' + name + ']';
            }
        })(typeArr[i]);
    }
    return type;
})();
const ZhengCallBackMap = {};
const ZhengReplaceIosCallBack = function(params) {
    if (!ZhengJSType.isString(params) || !params) {
        return;
    }
    const newParams = JSON.parse(decodeURIComponent(params));
    if (!ZhengJSType.isObject(newParams)) {
        return;
    }
    const funcId = newParams.funcId;
    const res = newParams.data;
    const alive = newParams.alive;

    let randomKey = '',
        funcNameKey = '';
    const matchKey = function(key) {
        if (!funcId.endsWith(key)) return false;
        randomKey = funcId.replace(new RegExp(key, 'g'), '');
        funcNameKey = key;
        return true;
    };
    const matchRes = (matchKey(ZhengCallBackSuccessKey) || matchKey(ZhengCallBackFailKey) || matchKey(ZhengCallBackCompleteKey));
    if (!matchRes) return;

    let funcMap = ZhengCallBackMap[randomKey];
    if (!ZhengJSType.isObject(funcMap)) return;
    const func = funcMap[funcNameKey];
    if (!ZhengJSType.isFunction(func)) return;
    try {
        /** 
         * 原函数没有参数 complete: () => {}  调用func(res) 不会报错
         * 原函数有参数 complete: (res) => {}  调用func() 会报错 走catch
         */
        func(res);
    } catch (error) {
        console.log('CallBack-error');
        console.log(error);
    }
    if (alive) return;
    /** 回调complete后删除 */
    if (funcNameKey == ZhengCallBackCompleteKey) {
        ZhengRemoveCallBack(randomKey);
    }
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
const ZhengAddCallBack = function(randomKey, funcNameKey, func) {
    let funcMap = ZhengCallBackMap[randomKey];
    if (!ZhengJSType.isObject(funcMap)) {
        const map = {};
        map[funcNameKey] = func;
        ZhengCallBackMap[randomKey] = map;
        return;
    }
    if (funcMap.hasOwnProperty(funcNameKey)) return;
    funcMap[funcNameKey] = func;
    ZhengCallBackMap[randomKey] = funcMap;
};
const ZhengRemoveCallBack = function(randomKey) {
    if (!ZhengCallBackMap.hasOwnProperty(randomKey)) return;
    delete ZhengCallBackMap[randomKey];
};
const ZhengHandleCallBackParams = function(methodName, params) {
    if (!ZhengJSType.isObject(params)) {
        return params;
    }
    /** 0-10000的随机整数 */
    const randomKey = `-${methodName}-${new Date().getTime()}-${Math.floor(Math.random() * 10000)}-`;
    /** 参数 */
    let newParams = params;
    let funcId = '';

    /** 成功回调 */
    const success = params.success;
    if (success && ZhengJSType.isFunction(success)) {
        funcId = randomKey + ZhengCallBackSuccessKey;
        ZhengAddCallBack(randomKey, ZhengCallBackSuccessKey, success);
        newParams[ZhengCallBackSuccessKey] = funcId;
    }
    /** 失败回调 */
    const fail = params.fail;
    if (fail && ZhengJSType.isFunction(fail)) {
        funcId = randomKey + ZhengCallBackFailKey;
        ZhengAddCallBack(randomKey, ZhengCallBackFailKey, fail);
        newParams[ZhengCallBackFailKey] = funcId;
    }
    /** 完成回调 */
    const complete = params.complete;
    if (complete && ZhengJSType.isFunction(complete)) {
        funcId = randomKey + ZhengCallBackCompleteKey;
        ZhengAddCallBack(randomKey, ZhengCallBackCompleteKey, complete);
        newParams[ZhengCallBackCompleteKey] = funcId;
    }
    return newParams;
};

/** 构造发送参数 */
const ZhengSendParams = function(apiPrefix, methodName, params, sync) {
    /** js发送消息 以此为key包裹消息体 */
    let newParams = params;
    let res = {};
    if (!sync) {
        newParams = ZhengHandleCallBackParams(methodName, params);
    }
    const haveParms = !(ZhengJSType.isNull(newParams) || ZhengJSType.isUndefined(newParams));
    res = haveParms ? {
        methodName,
        apiPrefix,
        params: newParams
    } : {
        methodName,
        apiPrefix
    };
    /** 必须这样【JSON.parse(JSON.stringify())】 否则js运行window.webkit.messageHandlers  会报错cannot be cloned */
    return sync ? res : JSON.parse(JSON.stringify(res));
};
const ZhengSendNative = function(params) {
    const handler = window.webkit.messageHandlers[ZhengJSToNativeHandlerName]
    handler.postMessage(params);
};
const ZhengSendNativeSync = function(params) {
    let res = prompt(JSON.stringify(params));
    try {
        res = JSON.parse(res);
        return res.data;
    } catch (error) {
        console.log('❌SendNativeSync--error');
        console.log(error);
    }
    return null;
};
const ZhengReplaceGeneratorAPI = function(apiPrefix, apiMap) {
    if (!apiPrefix || !ZhengJSType.isString(apiPrefix) || !ZhengJSType.isObject(apiMap)) {
        return {};
    }
    let res = {};
    let mapKeys = Object.keys(apiMap);
    for (let i = 0; i < mapKeys.length; i++) {
        (function(name) {
            /** 获取配置：isSync */
            const config = apiMap[name];
            const isSync = config.hasOwnProperty('sync') ? config.sync : false;
            /** 生成function */
            res[name] = isSync ? (function (params) {
                return ZhengSendNativeSync(ZhengSendParams(apiPrefix, name, params, true));
            }) : (function (params) {
                ZhengSendNative(ZhengSendParams(apiPrefix, name, params, false));
            });
        })(mapKeys[i]);
    }
    return res;
};
/** ❗️❗️Api配置说明：sync：是否是同步方法 */
/**
const fund = ZhengGeneratorAPI('fund', {
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
const zheng = ZhengGeneratorAPI('zheng', {

});
 */

// var ZhengReadyEvent = document.createEvent('Event');
// ZhengReadyEvent.initEvent('ZhengJSBridgeReady');
// window.dispatchEvent(ZhengReadyEvent);
