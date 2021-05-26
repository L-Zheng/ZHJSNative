var ZhengJSToNativeHandlerName='%@';var ZhengJSToNativeMethodSyncKey='%@';var ZhengJSToNativeMethodAsyncKey='%@';var ZhengCallBackSuccessKey='%@';var ZhengCallBackFailKey='%@';var ZhengCallBackCompleteKey='%@';var ZhengJSToNativeFunctionArgKey='%@';var ZhengJSType=function(){var type={};var typeArr=['String','Object','Number','Array','Undefined','Function','Null','Symbol','Boolean'];for(var i=0;i<typeArr.length;i++){(function(name){type['is'+name]=function(obj){return Object.prototype.toString.call(obj)=='[object '+name+']'}})(typeArr[i])}return type}();var ZhengCallBackMap={};var %@=function(params){var funcRes=null;if(!ZhengJSType.isString(params)||!params){return funcRes}var newParams=JSON.parse(decodeURIComponent(params));if(!ZhengJSType.isObject(newParams)){return funcRes}var funcId=newParams.funcId;var resDatas=ZhengJSType.isArray(newParams.data)?newParams.data:[];var alive=newParams.alive;var randomKey='',funcNameKey='';var matchKey=function(key){var matchNumber=funcId.length-key.length;if(matchNumber>=0&&funcId.lastIndexOf(key)==matchNumber){}else{return false}randomKey=funcId.replace(new RegExp(key,'g'),'');funcNameKey=key;return true};var matchRes=matchKey(ZhengCallBackSuccessKey)||matchKey(ZhengCallBackFailKey)||matchKey(ZhengCallBackCompleteKey)||matchKey(ZhengJSToNativeFunctionArgKey);if(!matchRes)return funcRes;var funcMap=ZhengCallBackMap[randomKey];if(!ZhengJSType.isObject(funcMap))return funcRes;var func=funcMap[funcNameKey];if(!ZhengJSType.isFunction(func))return funcRes;try{if(resDatas.length==0){funcRes=func()}else if(resDatas.length==1){funcRes=func(resDatas[0])}else if(resDatas.length==2){funcRes=func(resDatas[0],resDatas[1])}else if(resDatas.length==3){funcRes=func(resDatas[0],resDatas[1],resDatas[2])}else if(resDatas.length==4){funcRes=func(resDatas[0],resDatas[1],resDatas[2],resDatas[3])}else if(resDatas.length==5){funcRes=func(resDatas[0],resDatas[1],resDatas[2],resDatas[3],resDatas[4])}else{funcRes=func(resDatas)}}catch(error){if(ZhengJSType.isFunction(window.onerror)&&Object.prototype.toString.call(error)=='[object Error]'){window.onerror.apply(window,[error])}funcRes=null}if(alive)return funcRes;if(funcNameKey==ZhengCallBackCompleteKey||funcNameKey==ZhengJSToNativeFunctionArgKey){ZhengRemoveCallBack(randomKey)}return funcRes};var ZhengAddCallBack=function(randomKey,funcNameKey,func){var funcMap=ZhengCallBackMap[randomKey];if(!ZhengJSType.isObject(funcMap)){var map={};map[funcNameKey]=func;ZhengCallBackMap[randomKey]=map}else{funcMap[funcNameKey]=func;ZhengCallBackMap[randomKey]=funcMap}return randomKey+funcNameKey};var ZhengRemoveCallBack=function(randomKey){if(!ZhengCallBackMap.hasOwnProperty(randomKey))return;delete ZhengCallBackMap[randomKey]};var ZhengHandleCallBackParams=function(apiPrefix,methodName,params,index){if(!ZhengJSType.isObject(params)&&!ZhengJSType.isFunction(params)){return params}var randomKey='-'+apiPrefix+'-'+methodName+'-'+(new Date).getTime().toString()+'-arg'+index+'-'+Math.floor(Math.random()*1e4).toString()+'-'+Math.floor(Math.random()*1e4).toString()+'-';var newParams={};var funcId='';if(ZhengJSType.isFunction(params)){funcId=ZhengAddCallBack(randomKey,ZhengJSToNativeFunctionArgKey,params);newParams[ZhengJSToNativeFunctionArgKey]=funcId;return newParams}newParams=params;var success=params.success;if(success&&ZhengJSType.isFunction(success)){funcId=ZhengAddCallBack(randomKey,ZhengCallBackSuccessKey,success);newParams[ZhengCallBackSuccessKey]=funcId}var fail=params.fail;if(fail&&ZhengJSType.isFunction(fail)){funcId=ZhengAddCallBack(randomKey,ZhengCallBackFailKey,fail);newParams[ZhengCallBackFailKey]=funcId}var complete=params.complete;if(complete&&ZhengJSType.isFunction(complete)){funcId=ZhengAddCallBack(randomKey,ZhengCallBackCompleteKey,complete);newParams[ZhengCallBackCompleteKey]=funcId}return newParams};var ZhengSendParams=function(apiPrefix,methodName,methodSync,params){var newParams=params;var resArgs=[];if(Object.prototype.toString.call(newParams)==='[object Arguments]'){var argCount=newParams.length;for(var argIdx=0;argIdx<argCount;argIdx++){resArgs.push(ZhengHandleCallBackParams(apiPrefix,methodName,newParams[argIdx],argIdx))}}return{apiPrefix:apiPrefix,methodName:methodName,methodSync:methodSync,args:resArgs}};var ZhengSendNative=function(params){var handler=window.webkit.messageHandlers[ZhengJSToNativeHandlerName];handler.postMessage(JSON.parse(JSON.stringify(params)))};var ZhengSendNativeSync=function(params){var res=prompt(JSON.stringify(params));if(!res)return null;try{res=JSON.parse(res);return res.data}catch(error){if(ZhengJSType.isFunction(window.onerror)&&Object.prototype.toString.call(error)=='[object Error]'){window.onerror.apply(window,[error])}}return null};var %@=function(apiPrefix,apiMap){if(!apiPrefix||!ZhengJSType.isString(apiPrefix)||!ZhengJSType.isObject(apiMap)){return{}}var res={};var mapKeys=Object.keys(apiMap);for(var i=0;i<mapKeys.length;i++){(function(name){var config=apiMap[name];var isSync=config.hasOwnProperty('sync')?config.sync:false;res[name]=isSync?function(){return ZhengSendNativeSync(ZhengSendParams(apiPrefix,name,ZhengJSToNativeMethodSyncKey,arguments))}:function(){ZhengSendNative(ZhengSendParams(apiPrefix,name,ZhengJSToNativeMethodAsyncKey,arguments))}})(mapKeys[i])}return res};