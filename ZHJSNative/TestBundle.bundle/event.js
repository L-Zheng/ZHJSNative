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
const FNCallBackSuccessKey = 'FNCallBackSuccessKey';
const FNCallBackFailKey = 'FNCallBackFailKey';
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

    let arr = FNCallBackMap[funcId];
    if (!FNJSType.isArray(arr) || arr.length == 0) {
        return;
    }
    arr.forEach(el => {
        if (FNJSType.isFunction(el)) {
            el(res);
        }
    });
    FNRemoveCallBack(funcId);
}
const FNAddCallBack = (funcId, func) => {
    let arr = FNCallBackMap[funcId];
    if (!FNJSType.isArray(arr)) {
        arr = [];
    }
    if (arr.indexOf(func) == -1) {
        arr.push(func);
    }
    FNCallBackMap[funcId] = arr;
};
const FNRemoveCallBack = (funcId) => {
    if (FNCallBackMap.hasOwnProperty(funcId)) {
        delete FNCallBackMap[funcId];
    }
};
const FNHandleCallBackParams = (methodName, params) => {
    if (!FNJSType.isObject(params)) {
        return params;
    }
    /** 生成随机数 */
    const CreateRandom = (methodName) => {
        /** 0-1000的随机整数 */
        return `-${methodName}-${new Date().getTime()}-${Math.floor(Math.random() * 1000)}-`;
    };
    /** 参数 */
    let newParams = params;
    /** 成功回调 */
    const success = params.success;
    if (success && FNJSType.isFunction(success)) {
        const funcId = FNCallBackSuccessKey + CreateRandom(methodName);
        FNAddCallBack(funcId, success);
        newParams[FNCallBackSuccessKey] = funcId;
    }
    /** 失败回调 */
    const fail = params.fail;
    if (fail && FNJSType.isFunction(fail)) {
        const funcId = FNCallBackFailKey + CreateRandom(methodName);
        FNAddCallBack(funcId, fail);
        newParams[FNCallBackFailKey] = funcId;
    }
    return newParams;
};

/** 构造发送参数 */
const FNSendParams = (methodName, params, sync = false) => {
    /** js发送消息 以此为key包裹消息体 */
    let res = {};
    if (!sync) {
        const newParams = FNHandleCallBackParams(methodName, params);
        res = newParams ? {
            methodName,
            params: newParams
        } : {
                methodName
            };
        /** 必须这样 否则js运行window.webkit.messageHandlers  会报错cannot be cloned */
        return JSON.parse(JSON.stringify(res));
    }
    res = params ? {
        methodName,
        params,
    } : {
            methodName
        }
    return res;
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
        console.log('❌FNSendNativeSync--error');
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