/** js语句必须带有 ;  注释方式使用带有闭合标签的
 * 【iOS原生是把该文件读取成字符串执行，没有结束标志js代码出错】
 */
/**
 * 最小化该js文件： 
 * npm install -g uglify-es
 * uglifyjs event.js -b beautify=false,quote_style=1 -o min4.js
 */
/** ❗️❗️Api配置说明：sync：是否是同步方法 */
/** fund通用API */
const FNCommonAPI = {
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
};
/** 发送消息name:与iOS原生保持一致 */
const FNJSToNativeHandlerName = 'ZHJSEventHandler';
const FNCallBackSuccessKey = 'ZHCallBackSuccessKey';
const FNCallBackFailKey = 'ZHCallBackFailKey';
const FNCallBackCompleteKey = 'ZHCallBackCompleteKey';
const FNJSType = (() => {
    let type = {};
    const typeArr = ['String', 'Object', 'Number', 'Array', 'Undefined', 'Function', 'Null', 'Symbol', 'Boolean'];
    for (let i = 0; i < typeArr.length; i++) {
        ((name) => {
            type['is' + name] = (obj) => {
                return Object.prototype.toString.call(obj) == '[object ' + name + ']';
            }
        })(typeArr[i]);
    }
    return type;
})();
const FNCallBackMap = {};
const FNCallBack = (params) => {
    if (!FNJSType.isString(params) || !params) {
        return;
    }
    const newParams = JSON.parse(decodeURIComponent(params));
    if (!FNJSType.isObject(newParams)) {
        return;
    }
    const funcId = newParams.funcId;
    const res = newParams.data;
    const alive = newParams.alive;

    let randomKey = '',
        funcNameKey = '';
    const matchKey = (key) => {
        if (!funcId.endsWith(key)) return false;
        randomKey = funcId.replace(new RegExp(key, 'g'), '');
        funcNameKey = key;
        return true;
    };
    const matchRes = (matchKey(FNCallBackSuccessKey) || matchKey(FNCallBackFailKey) || matchKey(FNCallBackCompleteKey));
    if (!matchRes) return;

    let funcMap = FNCallBackMap[randomKey];
    if (!FNJSType.isObject(funcMap)) return;
    const func = funcMap[funcNameKey];
    if (!FNJSType.isFunction(func)) return;
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
    if (funcNameKey == FNCallBackCompleteKey) {
        FNRemoveCallBack(randomKey);
    }
}
/**
{
    '-request-1582972065568-79-': {
        FNCallBackSuccessKey: function
        FNCallBackFailKey: function
        FNCallBackCompleteKey: function
    }
}
 */
const FNAddCallBack = (randomKey, funcNameKey, func) => {
    let funcMap = FNCallBackMap[randomKey];
    if (!FNJSType.isObject(funcMap)) {
        const map = {};
        map[funcNameKey] = func;
        FNCallBackMap[randomKey] = map;
        return;
    }
    if (funcMap.hasOwnProperty(funcNameKey)) return;
    funcMap[funcNameKey] = func;
    FNCallBackMap[randomKey] = funcMap;
};
const FNRemoveCallBack = (randomKey) => {
    if (!FNCallBackMap.hasOwnProperty(randomKey)) return;
    delete FNCallBackMap[randomKey];
};
const FNHandleCallBackParams = (methodName, params) => {
    if (!FNJSType.isObject(params)) {
        return params;
    }
    /** 0-10000的随机整数 */
    const randomKey = `-${methodName}-${new Date().getTime()}-${Math.floor(Math.random() * 10000)}-`;
    /** 参数 */
    let newParams = params;
    /** 成功回调 */
    const success = params.success;
    if (success && FNJSType.isFunction(success)) {
        const funcId = randomKey + FNCallBackSuccessKey;
        FNAddCallBack(randomKey, FNCallBackSuccessKey, success);
        newParams[FNCallBackSuccessKey] = funcId;
    }
    /** 失败回调 */
    const fail = params.fail;
    if (fail && FNJSType.isFunction(fail)) {
        const funcId = randomKey + FNCallBackFailKey;
        FNAddCallBack(randomKey, FNCallBackFailKey, fail);
        newParams[FNCallBackFailKey] = funcId;
    }
    /** 完成回调 */
    const complete = params.complete;
    if (complete && FNJSType.isFunction(complete)) {
        const funcId = randomKey + FNCallBackCompleteKey;
        FNAddCallBack(randomKey, FNCallBackCompleteKey, complete);
        newParams[FNCallBackCompleteKey] = funcId;
    }
    return newParams;
};

/** 构造发送参数 */
const FNSendParams = (methodName, params, sync = false) => {
    /** js发送消息 以此为key包裹消息体 */
    let newParams = params;
    let res = {};
    if (!sync) {
        newParams = FNHandleCallBackParams(methodName, params);
    }
    const haveParms = !(FNJSType.isNull(newParams) || FNJSType.isUndefined(newParams));
    res = haveParms ? {
        methodName,
        params: newParams
    } : {
        methodName
    };
    /** 必须这样【JSON.parse(JSON.stringify())】 否则js运行window.webkit.messageHandlers  会报错cannot be cloned */
    return sync ? res : JSON.parse(JSON.stringify(res));
};
const FNSendParamsSync = (methodName, params) => {
    return FNSendParams(methodName, params, true);
};
const FNSendNative = (params) => {
    const handler = window.webkit.messageHandlers[FNJSToNativeHandlerName]
    handler.postMessage(params);
};
const FNSendNativeSync = (params) => {
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
const fund = (() => {
    const apiMap = FNCommonAPI;
    let res = {};
    for (const key in apiMap) {
        if (!apiMap.hasOwnProperty(key)) {
            continue;
        }
        /** 获取配置：isSync */
        const config = apiMap[key];
        const isSync = config.hasOwnProperty('sync') ? config.sync : false;
        /** 生成function */
        const func = isSync ? ((params) => {
            return FNSendNativeSync(FNSendParamsSync(key, params));
        }) : ((params) => {
            FNSendNative(FNSendParams(key, params));
        });
        res[key] = func
    }
    return res;
})();