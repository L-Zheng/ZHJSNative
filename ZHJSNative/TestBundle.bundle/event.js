
/** js语句必须带有 ;  注释方式使用带有闭合标签的 */
const FNJSToNativeHandlerName = 'ZHJSEventHandler';
const FNJSDataType = function (data) {
    return Object.prototype.toString.call(data);
};
const FNType = (function () {
    var type = {};
    var typeArr = ['String', 'Object', 'Number', 'Array', 'Undefined', 'Function', 'Null', 'Symbol', 'Boolean'];
    for (var i = 0; i < typeArr.length; i++) {
        (function (name) {
            type['is' + name] = function (obj) {
                return FNJSDataType(obj) == '[object ' + name + ']';
            }
        })(typeArr[i]);
    }
    return type;
})();
const FNRandom = function () {
    /** 0-100的随机整数 */
    return `--${Math.floor(Math.random() * 100)}--${new Date().getTime()}--`;
};

const FNCallBackSuccessKey = 'FNCallBackSuccessKey';
const FNCallBackFailKey = 'FNCallBackFailKey';
const FNCallBackMap = {};
const FNCallBack = function (params) {
    if (!FNType.isString(params) || !params) {
        return;
    }
    const newParams = JSON.parse(decodeURIComponent(params));
    if (!FNType.isObject(newParams)) {
        return;
    }
    const funcId = newParams.funcId;
    const res = newParams.data;

    let arr = FNCallBackMap[funcId];
    if (!FNType.isArray(arr) || arr.length == 0) {
        return;
    }
    arr.forEach(el => {
        if (FNType.isFunction(el)) {
            el(res);
        }
    });
    FNRemoveCallBack(funcId);
}
const FNAddCallBack = function (funcId, func) {
    let arr = FNCallBackMap[funcId];
    if (!FNType.isArray(arr)) {
        arr = [];
    }
    if (arr.indexOf(func) == -1) {
        arr.push(func);
    }
    FNCallBackMap[funcId] = arr;
};
const FNRemoveCallBack = function (funcId) {
    let arr = FNCallBackMap[funcId];
    if (!FNType.isArray(arr)) {
        return;
    }
    FNCallBackMap[funcId] = null;
};
const FNHandleCallBackParams = function (params) {
    if (!FNType.isObject(params)) {
        return params;
    }
    let newParams = params;

    const success = params.success;
    const fail = params.fail;

    if (success && FNType.isFunction(success)) {
        const funcId = FNCallBackSuccessKey + FNRandom();
        FNAddCallBack(funcId, success);
        newParams[FNCallBackSuccessKey] = funcId;
    }
    if (fail && FNType.isFunction(fail)) {
        const funcId = FNCallBackFailKey + FNRandom();
        FNAddCallBack(funcId, fail);
        newParams[FNCallBackFailKey] = funcId;
    }
    return newParams;
};

/** 构造发送参数 */
const FNSendParams = function (methodName, params, sync = false) {
    /** js发送消息 以此为key包裹消息体 */
    let res = {};
    if (!sync) {
        const newParams = FNHandleCallBackParams(params);
        res = newParams ? { 'methodName': methodName, 'params': newParams } : { 'methodName': methodName };
        /** 必须这样 否则js运行window.webkit.messageHandlers  会报错cannot be cloned */
        return JSON.parse(JSON.stringify(res));
    }
    res = params ? { 'methodName': methodName, 'params': params } : { 'methodName': methodName };
    return res;
};
const FNSendParamsSync = function (methodName, params) {
    return FNSendParams(methodName, params, true);
};
const FNSendNative = function (params) {
    const handler = window.webkit.messageHandlers[FNJSToNativeHandlerName]
    handler.postMessage(params);
};
const FNSendNativeSync = function (params) {
    let res = prompt(JSON.stringify(params));
    try {
        res = JSON.parse(res);
        return res.data;
    } catch (error) {
        console.log('FNSendNativeSync--error');
        console.log(error);
    }
    return null;
};

const FNCommonParams = function (params) {
    return params;
    const data = params.data ? params.data : {};
    const Info = fund.getUserInfoSync();
    try {
        const userInfo = Info.userInfo;
        const common = {
            deviceid: userInfo.deviceid,
            plat: userInfo.plat,
            serverversion: userInfo.serverversion,
            version: userInfo.appv,
            appVersion: userInfo.appv
        }
        let newData = data;
        for (const key in common) {
            const el = common[key];
            newData[key] = el;
        }
        params.data = newData;
        return params;
    } catch (error) {
        return params;
    }
};
/** ❗️❗️Api配置说明：sync：是否是同步方法 */
/** fund通用API */
const FNCommonAPI = {
    /** 通用短链 */
    commonLinkTo: { sync: false },
    /** 请求 */
    request: { sync: false },
    /** 获取系统信息 */
    getSystemInfoSync: { sync: true },
    /** 获取用户信息 */
    getUserInfoSync: { sync: true },
    /** 登录 */
    login: { sync: false },
    /** 注册分享 */
    registerShare: { sync: false },
    /** 分享到微信 */
    shareWeChat: { sync: false },
    /** 弹窗提示 */
    showToast: { sync: false },
    /** 预览图片 */
    previewImage: { sync: false },
    getJsonSync: { sync: true }
};
/** ❗️❗️Api配置说明：sync：是否是同步方法 */
/** fund业务API */
const FNBusinessApi = {
    /** 获取表情资源 */
    getEmotionResourceSync: { sync: true },
    getBigEmotionResourceSync: { sync: true },
    /** 获取原生url配置 */
    getUrlConfigSync: { sync: true },
    /** 关注状态 */
    getFollowStatusSync: { sync: true },
    /** 关注列表中插入id */
    updateFollowStatus: { sync: false },
    /** 机构主页 */
    navigateToOrganizationHome: { sync: false },
    /** 问题详情 */
    navigateToQuestionDetail: { sync: false },
    /** 调起评论键盘 */
    showReplyKeyboard: { sync: false },
    /** 文章是否点赞 */
    getLikeArticleStatusSync: { sync: true },
    /** 点赞文章列表中插入id */
    updateLikeArticleStatus: { sync: false },
    /** 打赏 */
    showBottomRewardView: { sync: false }
};
/** 注入的api 如fund.reques({})  */
/** ❗️❗️❗️❗️ 警告
 * 注释必须使用带有闭合标签的注释方式 
 * js语句后面必须带有分号；【iOS原生是把该文件读取成字符串执行，没有结束标志js代码出错】
 */
var fund = (function () {
    const apiMap = Object.assign(FNCommonAPI, FNBusinessApi);
    let res = {};
    for (const key in apiMap) {
        if (!apiMap.hasOwnProperty(key)) {
            continue;
        }
        //获取配置：isSync
        const config = apiMap[key];
        const isSync = config.hasOwnProperty('sync') ? config.sync : false;
        //生成function
        const func = isSync ? (function (params) {
            return FNSendNativeSync(FNSendParamsSync(key, params));
        }) : (function (params) {
            FNSendNative(FNSendParams(key, params));
        });
        res[key] = func
    }
    return res;
})();
/**
setTimeout(() => {
    console.log('😁article-event');
   fund.request({
       url: `https://gbapi.eastmoney.com/follow/api/Follow/GetFollowFansCount`,
       method: 'GET',
       header: {},
       data: {
        gtoken: '8C38855A5D1D453FBCA56D9F79E5B94a',
        userid: '',
        uid: '1842024924190188',
        bizflag: '2',
        passportid: ''
       },
       success: function (res) {
        console.log('js-request-success');
        console.log(res);
       },
       fail: function (error) {
        console.log('js-request-fail');
           console.log(error);
       }
   });
}, 5000);

 setTimeout(() => {
    console.log('😁article-event');
   fund.showToast({ "1111": "2222" });
}, 5000);
setTimeout(() => {
    console.log('😁');
    console.log(fund.getUserInfoSync({ "1111": "2222" }));
}, 5000);
 */