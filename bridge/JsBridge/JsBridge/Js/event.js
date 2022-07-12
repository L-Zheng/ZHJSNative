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
var My_JsBridge_Key_WebHandler = 'My_JsBridge_Replace_WebHandler';
var My_JsBridge_Key_jsToNativeMethodSync = 'My_JsBridge_Replace_jsToNativeMethodSync';
var My_JsBridge_Key_jsToNativeMethodAsync = 'My_JsBridge_Replace_jsToNativeMethodAsync';
var My_JsBridge_Key_callSuccess = 'My_JsBridge_Replace_callSuccess';
var My_JsBridge_Key_callFail = 'My_JsBridge_Replace_callFail';
var My_JsBridge_Key_callComplete = 'My_JsBridge_Replace_callComplete';
var My_JsBridge_Key_callJsFunctionArg = 'My_JsBridge_Replace_callJsFunctionArg';
var My_JsBridge_Type = (function() {
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
var My_JsBridge_callMap = {};
var My_JsBridge_Replace_nativeCallJs = function(params) {
    var funcRes = null;
    if (!My_JsBridge_Type.isString(params) || !params) {
        return funcRes;
    }
    var newParams = JSON.parse(decodeURIComponent(params));
    if (!My_JsBridge_Type.isObject(newParams)) {
        return funcRes;
    }
    var funcId = newParams.funcId;
    var resDatas = (My_JsBridge_Type.isArray(newParams.data) ? newParams.data : []);
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
    var matchRes = (matchKey(My_JsBridge_Key_callSuccess) || matchKey(My_JsBridge_Key_callFail) || matchKey(My_JsBridge_Key_callComplete) || matchKey(My_JsBridge_Key_callJsFunctionArg));
    if (!matchRes) return funcRes;

    var funcMap = My_JsBridge_callMap[randomKey];
    if (!My_JsBridge_Type.isObject(funcMap)) return funcRes;
    var func = funcMap[funcNameKey];
    if (!My_JsBridge_Type.isFunction(func)) return funcRes;
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
        if (My_JsBridge_Type.isFunction(window.onerror) && Object.prototype.toString.call(error) == '[object Error]') {
            window.onerror.apply(window, [error]);
        }
        funcRes = null;
    }
    if (alive) return funcRes;
    /** 回调complete后删除 */
    if (funcNameKey == My_JsBridge_Key_callComplete || funcNameKey == My_JsBridge_Key_callJsFunctionArg) {
        My_JsBridge_callMap_remove(randomKey);
    }
    return funcRes;
}
/**
{
    '-MyApi-moduleName-request-1582972065568-arg0-79-88-': {
        My_JsBridge_Key_callSuccess: function
        My_JsBridge_Key_callFail: function
        My_JsBridge_Key_callComplete: function
        My_JsBridge_Key_callJsFunctionArg: function
    }
}
 */
var My_JsBridge_callMap_add = function(randomKey, funcNameKey, func) {
    var funcMap = My_JsBridge_callMap[randomKey];
    if (!My_JsBridge_Type.isObject(funcMap)) {
        var map = {};
        map[funcNameKey] = func;
        My_JsBridge_callMap[randomKey] = map;
    } else {
        /** if (funcMap.hasOwnProperty(funcNameKey)) return; */
        funcMap[funcNameKey] = func;
        My_JsBridge_callMap[randomKey] = funcMap;
    }
    return randomKey + funcNameKey;
};
var My_JsBridge_callMap_remove = function(randomKey) {
    if (!My_JsBridge_callMap.hasOwnProperty(randomKey)) return;
    delete My_JsBridge_callMap[randomKey];
};
var My_JsBridge_makeParams = function(apiPrefix, moduleName, methodName, params, index) {
    if (!My_JsBridge_Type.isObject(params) && !My_JsBridge_Type.isFunction(params)) {
        return params;
    }
    /** 0-10000的随机整数 -MyApi-moduleName-request-1582972065568-arg0-79-88- */
    var randomKey = '-' + apiPrefix + '-' + (My_JsBridge_Type.isUndefined(moduleName) ? 'Undefined' : moduleName) + '-' + methodName + '-' + new Date().getTime().toString() + '-arg' + index + '-' + Math.floor(Math.random() * 10000).toString() + '-' + Math.floor(Math.random() * 10000).toString() + '-';
    
    /** 参数 */
    var newParams = {};
    var funcId = '';

    /** function 参数 */
    if (My_JsBridge_Type.isFunction(params)) {
        funcId = My_JsBridge_callMap_add(randomKey, My_JsBridge_Key_callJsFunctionArg, params);
        newParams[My_JsBridge_Key_callJsFunctionArg] = funcId;
        return newParams;
    }

    newParams = params;
    /** 成功回调 */
    var success = params.success;
    if (success && My_JsBridge_Type.isFunction(success)) {
        funcId = My_JsBridge_callMap_add(randomKey, My_JsBridge_Key_callSuccess, success);
        newParams[My_JsBridge_Key_callSuccess] = funcId;
    }
    /** 失败回调 */
    var fail = params.fail;
    if (fail && My_JsBridge_Type.isFunction(fail)) {
        funcId = My_JsBridge_callMap_add(randomKey, My_JsBridge_Key_callFail, fail);
        newParams[My_JsBridge_Key_callFail] = funcId;
    }
    /** 完成回调 */
    var complete = params.complete;
    if (complete && My_JsBridge_Type.isFunction(complete)) {
        funcId = My_JsBridge_callMap_add(randomKey, My_JsBridge_Key_callComplete, complete);
        newParams[My_JsBridge_Key_callComplete] = funcId;
    }
    return newParams;
};

/** 构造发送参数 */
var My_JsBridge_sendParams = function(apiPrefix, moduleName, methodName, methodSync, params) {
    /** arguments */
    var newParams = params;
    /** 处理参数 */
    var resArgs = [];
    if (Object.prototype.toString.call(newParams) === '[object Arguments]') {
        var argCount = newParams.length;
        for (var argIdx = 0; argIdx < argCount; argIdx++) {
            resArgs.push(My_JsBridge_makeParams(apiPrefix, moduleName, methodName, newParams[argIdx], argIdx));
        }
    }
    return {apiPrefix, moduleName, methodName, methodSync, args: resArgs};
};
var My_JsBridge_sendNativeAsync = function(params) {
    var handler = window.webkit.messageHandlers[My_JsBridge_Key_WebHandler];
    /** 必须这样【JSON.parse(JSON.stringify())】 否则js运行window.webkit.messageHandlers  会报错cannot be cloned */
    handler.postMessage(JSON.parse(JSON.stringify(params)));
};
var My_JsBridge_sendNativeSync = function(params) {
    var res = prompt(JSON.stringify(params));
    if (My_JsBridge_Type.isNull(res)) {
        return undefined;
    }
    if (My_JsBridge_Type.isString(res) && res.length == 0) {
        return null;
    }
    if (!res) return null;
    try {
        res = JSON.parse(res);
        return res.data;
    } catch (error) {
        if (My_JsBridge_Type.isFunction(window.onerror) && Object.prototype.toString.call(error) == '[object Error]') {
            window.onerror.apply(window, [error]);
        }
    }
    return null;
};
/** 当要移除api时 apiMap为{} */
var My_JsBridge_Replace_makeApi = function(apiPrefix, moduleName, apiMap) {
    if (!apiPrefix || !My_JsBridge_Type.isString(apiPrefix) || !My_JsBridge_Type.isObject(apiMap)) {
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
                return My_JsBridge_sendNativeSync(My_JsBridge_sendParams(apiPrefix, moduleName, methodName, My_JsBridge_Key_jsToNativeMethodSync, arguments));
            }) : (function () {
                My_JsBridge_sendNativeAsync(My_JsBridge_sendParams(apiPrefix, moduleName, methodName, My_JsBridge_Key_jsToNativeMethodAsync, arguments));
            });
        })(mapKeys[i]);
    }
    return res;
};
/** 向api中加入module api */
var My_JsBridge_Replace_makeModuleApi = function (apiPrefix, desApi, moduleApiMap) {
    if (!apiPrefix || !My_JsBridge_Type.isString(apiPrefix) || !desApi || !My_JsBridge_Type.isObject(desApi) || !moduleApiMap || !My_JsBridge_Type.isObject(moduleApiMap)) {
        return desApi;
    }
    var resModuleMap = {};
    var mapKeys = Object.keys(moduleApiMap);
    for (var i = 0; i < mapKeys.length; i++) {
        (function(moduleName) {
            resModuleMap[moduleName] = My_JsBridge_Replace_makeApi(apiPrefix, moduleName, moduleApiMap[moduleName]);
        })(mapKeys[i]);
    }

    var modulesKey = 'registerModules';
    var requireModuleKey = 'requireModule';

    desApi[modulesKey] = function() {
        return resModuleMap;
    };
    desApi[requireModuleKey] = function(moduleName) {
        if (!moduleName || !My_JsBridge_Type.isString(moduleName)) {
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
                if (!My_JsBridge_Type.isFunction(moduleFunc)) {
                    return undefined;
                }
                return moduleFunc(moduleName);
            };
        })(mapKeys[j]);
    }
    return desApi;
}
/** ❗️❗️Api配置说明：sync：是否是同步方法 */
/**
生成api：👉 var MyApi = {
    request: function(){}, 
    getJsonSync: function(){}
};👈
var MyApi = My_JsBridge_Replace_makeApi('MyApi', undefined, {
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
var MyApi = My_JsBridge_Replace_makeModuleApi('MyApi', MyApi, {
    voice: {
        play: {
            sync: false
        }
    }
});
 
 
var My_JsBridgeApiReadyEvent = document.createEvent('Event');
My_JsBridgeApiReadyEvent.initEvent('MyEventName');
window.dispatchEvent(My_JsBridgeApiReadyEvent);
 
window.addEventListener('MyEventName', () => {});
*/
