/** js语句必须带有 ;  注释方式使用带有闭合标签的
 * 【iOS原生是把该文件读取成字符串执行，没有结束标志js代码出错】
 *  var变量的作用区域 当前function上下文 
 */
/** ❌ios9 特殊处理
 * 不识别  forof、let变量、() => {}箭头函数 、function函数不能有默认值 如：function(params = {})() 、多参数函数 function (...args)
 *         识别 const、 var、 function(){}
 *    如果当前function里面又调用了其他function  var作用域不会延伸到其它function  递归调用也是如此
 *    如果当前function里面有其他function函数体  var作用域会延伸到其它function函数体
 */
/** ❌ios8 特殊处理
 * 不识别  let、const变量、() => {}箭头函数 、function函数不能有默认值(ios9不支持) 如：function(params = {})() 、多参数函数 function (...args)
 * 不识别模板字符串语法  `--${}`
 * 不识别语法  endsWith
 */
/**  函数参数 ...args 
var fo = function (a, b, c){console.log(a + b + c)}
var jo = function (a, b, c){fo.apply(this, arguments)}
var args = [1, 2, 3]

jo(...args) ==
jo(1, 2, 3) == 
fo(1, 2, 3) == 
fo.apply(this, [1, 2, 3]) == 
jo.apply(this, [1, 2, 3]) == 
fo.call(this, 1, 2, 3)
// 函数形参
var test = function (name, ...args){
    // name = 'my'  args = [1, 2, 3]
    console.log(name, args);
}
test('my', 1, 2, 3) == 
test.apply(this, ['my', 1, 2, 3])
// 深拷贝对象
var a = {name: 'my'}
var b = { ...a }
var c = ['j', 'k'] // 若数组里面包含对象，无法深拷贝
var d = [ ...c ]
*/
/**
 * 最小化该js文件： 
 * uglify-es库地址 ：https://github.com/mishoo/UglifyJS2
 * npm install -g uglify-es
 * uglifyjs event.js -b beautify=false,quote_style=1 -o event-min.js
 */
/** 发送消息name:与iOS原生保持一致 */
;var My_JsBridge = (function (){
var msgHandlerName = '_Replace_msgHandlerName';
var bridgeSyncIdentifier = '_Replace_bridgeSyncIdentifier';
var bridgeAsyncIdentifier = '_Replace_bridgeAsyncIdentifier';
var callSuccessKey = '_Replace_callSuccessKey';
var callFailKey = '_Replace_callFailKey';
var callCompleteKey = '_Replace_callCompleteKey';
var callJsFuncArgKey = '_Replace_callJsFuncArgKey';
var jsType = (function() {
    var type = {};
    var typeArr = ['String', 'Object', 'Number', 'Array', 'Undefined', 'Function', 'AsyncFunction', 'Null', 'Symbol', 'Boolean', 'Arguments', 'Error', 'Window'];
    for (var i = 0; i < typeArr.length; i++) {
        (function(name) {
            type['is' + name] = function(obj) {
                return Object.prototype.toString.call(obj) == '[object ' + name + ']';
            };
        })(typeArr[i]);
    }
    return type;
})();
var callMap_keyId = 0;
var callMap_data = {};
/**
{
    '-MyApi-moduleName-request-arg0-1582972065568-79-': {
        callSuccessKey: function
        callFailKey: function
        callCompleteKey: function
        callJsFuncArgKey: function
    }
}
 */
var callMap_add = function(randomKey, funcNameKey, func) {
    var funcMap = callMap_data[randomKey];
    if (!jsType.isObject(funcMap)) {
        var map = {};
        map[funcNameKey] = func;
        callMap_data[randomKey] = map;
    } else {
        /** if (funcMap.hasOwnProperty(funcNameKey)) return; */
        funcMap[funcNameKey] = func;
        callMap_data[randomKey] = funcMap;
    }
    return randomKey + funcNameKey;
};
var callMap_remove = function(randomKey) {
    if (!callMap_data.hasOwnProperty(randomKey)) return;
    delete callMap_data[randomKey];
};

/** 构造参数 */
var makeParams = function(apiPrefix, moduleName, methodName, params, index) {
    if (!jsType.isObject(params) && !(jsType.isFunction(params) || jsType.isAsyncFunction(params))) {
        return params;
    }
    /** 0-10000的随机整数 Math.floor(Math.random() * 10000).toString() */
    /** 生成 callMap 的 key, -MyApi-moduleName-request-arg0-1582972065568-79- */
    var randomKey = '-' + apiPrefix + '-' + (jsType.isUndefined(moduleName) ? 'Undefined' : moduleName) + '-' + methodName + '-arg' + index + '-' + new Date().getTime().toString() + '-' + (callMap_keyId++).toString() + '-';
    
    /** 参数 */
    var newParams = {};
    var funcId = '';

    /** function 参数 */
    if (jsType.isFunction(params) || jsType.isAsyncFunction(params)) {
        funcId = callMap_add(randomKey, callJsFuncArgKey, params);
        newParams[callJsFuncArgKey] = funcId;
        return newParams;
    }

    newParams = params;
    /** 成功回调 */
    var success = params.success;
    if (success && (jsType.isFunction(success) || jsType.isAsyncFunction(success))) {
        funcId = callMap_add(randomKey, callSuccessKey, success);
        newParams[callSuccessKey] = funcId;
    }
    /** 失败回调 */
    var fail = params.fail;
    if (fail && (jsType.isFunction(fail) || jsType.isAsyncFunction(fail))) {
        funcId = callMap_add(randomKey, callFailKey, fail);
        newParams[callFailKey] = funcId;
    }
    /** 完成回调 */
    var complete = params.complete;
    if (complete && (jsType.isFunction(complete) || jsType.isAsyncFunction(complete))) {
        funcId = callMap_add(randomKey, callCompleteKey, complete);
        newParams[callCompleteKey] = funcId;
    }
    return newParams;
};
/** 发送参数，因为与 Native 的同步通信使用的是 prompt，为防止开发者也使用 prompt，这里使用 bridgeIdentifier 用于 Native 判断是否是 bridge 通信消息 */
var sendParams = function(apiPrefix, moduleName, methodName, bridgeIdentifier, params) {
    /** arguments */
    var newParams = params;
    /** 处理参数 */
    var resArgs = [];
    if (jsType.isArguments(newParams)) {
        var argCount = newParams.length;
        for (var argIdx = 0; argIdx < argCount; argIdx++) {
            resArgs.push(makeParams(apiPrefix, moduleName, methodName, newParams[argIdx], argIdx));
        }
    }
    return {apiPrefix, moduleName, methodName, bridgeIdentifier, args: resArgs};
};

/** 发送到 Native */
var sendNativeAsync = function(params) {
    var handler = window.webkit.messageHandlers[msgHandlerName];
    /** 必须这样【JSON.parse(JSON.stringify())】 否则js运行window.webkit.messageHandlers  会报错cannot be cloned */
    handler.postMessage(JSON.parse(JSON.stringify(params)));
};
var sendNativeSync = function(params) {
    var res = prompt(JSON.stringify(params));
    if (jsType.isNull(res)) {
        return undefined;
    }
    if (jsType.isString(res) && res.length == 0) {
        return null;
    }
    if (!res) return null;
    try {
        res = JSON.parse(res);
        return res.data;
    } catch (error) {
        if ((jsType.isFunction(window.onerror) || jsType.isAsyncFunction(window.onerror)) && jsType.isError(error)) {
            window.onerror.apply(window, [error]);
        }
    }
    return null;
};

/** 接收 Native 的回调 */
var receviceNativeCall = function(params) {
    var funcRes = null;
    if (!jsType.isString(params) || !params) {
        return funcRes;
    }
    var newParams = JSON.parse(decodeURIComponent(params));
    if (!jsType.isObject(newParams)) {
        return funcRes;
    }
    var funcId = newParams.funcId;
    var resDatas = (jsType.isArray(newParams.data) ? newParams.data : []);
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
    var matchRes = (matchKey(callSuccessKey) || matchKey(callFailKey) || matchKey(callCompleteKey) || matchKey(callJsFuncArgKey));
    if (!matchRes) return funcRes;

    var funcMap = callMap_data[randomKey];
    if (!jsType.isObject(funcMap)) return funcRes;
    var func = funcMap[funcNameKey];
    if (!(jsType.isFunction(func) || jsType.isAsyncFunction(func))) return funcRes;
    try {
        /** 调用js function
        原生传参@[] resDatas=[] 调用func()
            success: function () {}
            success: function (res) {}   res为[object Undefined]类型
            success: function (res, res1) {}   res/res1均为[object Undefined]类型
        原生传参@[[NSNull null]] resDatas=[null] 调用func(null)
            success: function () {}
            success: function (res) {}   res为[object Null]类型
            success: function (res, res1) {}   res为[object Null]类型  res1为[object Undefined]类型
        原生传参@[@"x1"] resDatas=["x1"] 调用func("x1")
            success: function () {}
            success: function (res) {}   res为[object String]类型
            success: function (res, res1) {}   res为[object String]类型  res1为[object Undefined]类型
        原生传参@[@"x1", @"x2"] resDatas=["x1", "x2"] 调用func("x1", "x2")
            success: function () {}
            success: function (res) {}   res为[object String]类型
            success: function (res, res1, res2) {}   res/res1均为[object String]类型  res2为[object Undefined]类型
            */
        /** js中数组越界为 [object Undefined] 
        * 可变参数长度 可以直接使用 func.apply(this, resDatas) 调用
        * 此处this指向暂时不知怎么获取？
        */
        /** ❌...args仅支持iOS10以上, >= ios10 */
        funcRes = func(...resDatas);
        /**
        if (resDatas.length == 0) {
            funcRes = func();
        } else if (resDatas.length == 1) {
            funcRes = func(resDatas[0]);
        } else if (resDatas.length == 2) {
            funcRes = func(resDatas[0], resDatas[1]);
        } else if (resDatas.length == 3) {
            funcRes = func(resDatas[0], resDatas[1], resDatas[2]);
        } else if (resDatas.length == 4) {
            funcRes = func(resDatas[0], resDatas[1], resDatas[2], resDatas[3]);
        } else if (resDatas.length == 5) {
            funcRes = func(resDatas[0], resDatas[1], resDatas[2], resDatas[3], resDatas[4]);
        } else {
            funcRes = func(resDatas);
        }
        */
    } catch (error) {
        if ((jsType.isFunction(window.onerror) || jsType.isAsyncFunction(window.onerror)) && jsType.isError(error)) {
            window.onerror.apply(window, [error]);
        }
        funcRes = null;
    }
    if (alive) return funcRes;
    /** 回调complete后删除 */
    if (funcNameKey == callCompleteKey || funcNameKey == callJsFuncArgKey) {
        callMap_remove(randomKey);
    }
    return funcRes;
}
/** 构造 api，当要移除 api 时，apiMap 为 {} */
var makeApi = function(apiPrefix, moduleName, apiMap) {
    if (!apiPrefix || !jsType.isString(apiPrefix) || !jsType.isObject(apiMap)) {
        return {};
    }
    var res = {};
    var mapKeys = Object.keys(apiMap);
    for (var i = 0; i < mapKeys.length; i++) {
        (function(methodName) {
            /** 获取配置：isSync */
            var config = apiMap[methodName];
            var isSync = config.hasOwnProperty('sync') ? config.sync : false;
            /** 生成function */
            res[methodName] = isSync ? (function () {
                return sendNativeSync(sendParams(apiPrefix, moduleName, methodName, bridgeSyncIdentifier, arguments));
            }) : (function () {
                sendNativeAsync(sendParams(apiPrefix, moduleName, methodName, bridgeAsyncIdentifier, arguments));
            });
        })(mapKeys[i]);
    }
    return res;
};
/** 向 api 中加入 module api */
var makeModuleApi = function (apiPrefix, desApi, moduleApiMap) {
    if (!apiPrefix || !jsType.isString(apiPrefix) || !desApi || !jsType.isObject(desApi) || !moduleApiMap || !jsType.isObject(moduleApiMap)) {
        return desApi;
    }
    var resModuleMap = {};
    var mapKeys = Object.keys(moduleApiMap);
    for (var i = 0; i < mapKeys.length; i++) {
        (function(moduleName) {
            resModuleMap[moduleName] = makeApi(apiPrefix, moduleName, moduleApiMap[moduleName]);
        })(mapKeys[i]);
    }

    var modulesKey = 'registerModules';
    var requireModuleKey = 'requireModule';

    desApi[modulesKey] = function() {
        return resModuleMap;
    };
    desApi[requireModuleKey] = function(moduleName) {
        if (!moduleName || !jsType.isString(moduleName)) {
            return undefined;
        }
        return resModuleMap[moduleName];
    };
    /** 将moduleName同步到api中,即：MyApi.registerModules().xx = MyApi.xx() = MyApi.requireModule('xx') */
    mapKeys = Object.keys(resModuleMap);
    for (var j = 0; j < mapKeys.length; j++) {
        (function(moduleName) {
            desApi[moduleName] = function () {
                var moduleFunc = desApi[requireModuleKey];
                if (!moduleFunc) {
                    return moduleFunc;
                }
                if (!(jsType.isFunction(moduleFunc) || jsType.isAsyncFunction(moduleFunc))) {
                    return undefined;
                }
                return moduleFunc(moduleName);
            };
        })(mapKeys[j]);
    }
    return desApi;
}

return [receviceNativeCall, makeApi, makeModuleApi];
})();

var _Replace_receviceNativeCall = My_JsBridge[0];
var _Replace_makeApi = My_JsBridge[1];
var _Replace_makeModuleApi = My_JsBridge[2];


/** ❗️❗️Api配置说明：sync：是否是同步方法 */
/**
生成api：👉 var MyApi = {
    request: function(){}, 
    getJsonSync: function(){}
};👈
var MyApi = _Replace_makeApi('MyApi', undefined, {
    request: {
        sync: false
    },
    getJsonSync: {
        sync: true
    }
});
加入module api：👉 var MyApi = {
    request: function(){}, 
    getJsonSync: function(){},
    requireModule: {
        play: function(){}
    }
}👈
var MyApi = _Replace_makeModuleApi('MyApi', MyApi, {
    voice: {
        play: {
            sync: false
        }
    }
});
 
 
var My_JsBridge_ApiInjectFinish_MyApi = document.createEvent('Event');
My_JsBridge_ApiInjectFinish_MyApi.initEvent('MyEventName');
window.dispatchEvent(My_JsBridge_ApiInjectFinish_MyApi);
 
window.addEventListener('MyEventName', () => {});
*/
