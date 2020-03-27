const FNCommonAPI={request:{sync:false},getJsonSync:{sync:true},getNumberSync:{sync:true},getBoolSync:{sync:true},getStringSync:{sync:true},commonLinkTo:{sync:false}};const FNZhengInternalAPI={};const FNJSToNativeHandlerName='ZHJSEventHandler';const FNCallBackSuccessKey='ZHCallBackSuccessKey';const FNCallBackFailKey='ZHCallBackFailKey';const FNCallBackCompleteKey='ZHCallBackCompleteKey';const FNJSType=(()=>{let type={};const typeArr=['String','Object','Number','Array','Undefined','Function','Null','Symbol','Boolean'];for(let i=0;i<typeArr.length;i++){(name=>{type['is'+name]=(obj=>{return Object.prototype.toString.call(obj)=='[object '+name+']'})})(typeArr[i])}return type})();const FNCallBackMap={};const FNCallBack=params=>{if(!FNJSType.isString(params)||!params){return}const newParams=JSON.parse(decodeURIComponent(params));if(!FNJSType.isObject(newParams)){return}const funcId=newParams.funcId;const res=newParams.data;const alive=newParams.alive;let randomKey='',funcNameKey='';const matchKey=key=>{if(!funcId.endsWith(key))return false;randomKey=funcId.replace(new RegExp(key,'g'),'');funcNameKey=key;return true};const matchRes=matchKey(FNCallBackSuccessKey)||matchKey(FNCallBackFailKey)||matchKey(FNCallBackCompleteKey);if(!matchRes)return;let funcMap=FNCallBackMap[randomKey];if(!FNJSType.isObject(funcMap))return;const func=funcMap[funcNameKey];if(!FNJSType.isFunction(func))return;try{func(res)}catch(error){console.log('CallBack-error');console.log(error)}if(alive)return;if(funcNameKey==FNCallBackCompleteKey){FNRemoveCallBack(randomKey)}};const FNAddCallBack=(randomKey,funcNameKey,func)=>{let funcMap=FNCallBackMap[randomKey];if(!FNJSType.isObject(funcMap)){const map={};map[funcNameKey]=func;FNCallBackMap[randomKey]=map;return}if(funcMap.hasOwnProperty(funcNameKey))return;funcMap[funcNameKey]=func;FNCallBackMap[randomKey]=funcMap};const FNRemoveCallBack=randomKey=>{if(!FNCallBackMap.hasOwnProperty(randomKey))return;delete FNCallBackMap[randomKey]};const FNHandleCallBackParams=(methodName,params)=>{if(!FNJSType.isObject(params)){return params}const randomKey=`-${methodName}-${(new Date).getTime()}-${Math.floor(Math.random()*1e4)}-`;let newParams=params;const success=params.success;if(success&&FNJSType.isFunction(success)){const funcId=randomKey+FNCallBackSuccessKey;FNAddCallBack(randomKey,FNCallBackSuccessKey,success);newParams[FNCallBackSuccessKey]=funcId}const fail=params.fail;if(fail&&FNJSType.isFunction(fail)){const funcId=randomKey+FNCallBackFailKey;FNAddCallBack(randomKey,FNCallBackFailKey,fail);newParams[FNCallBackFailKey]=funcId}const complete=params.complete;if(complete&&FNJSType.isFunction(complete)){const funcId=randomKey+FNCallBackCompleteKey;FNAddCallBack(randomKey,FNCallBackCompleteKey,complete);newParams[FNCallBackCompleteKey]=funcId}return newParams};const FNSendParams=(apiPrefix,methodName,params,sync=false)=>{let newParams=params;let res={};if(!sync){newParams=FNHandleCallBackParams(methodName,params)}const haveParms=!(FNJSType.isNull(newParams)||FNJSType.isUndefined(newParams));res=haveParms?{methodName:methodName,apiPrefix:apiPrefix,params:newParams}:{methodName:methodName,apiPrefix:apiPrefix};return sync?res:JSON.parse(JSON.stringify(res))};const FNSendParamsSync=(apiPrefix,methodName,params)=>{return FNSendParams(apiPrefix,methodName,params,true)};const FNSendNative=params=>{const handler=window.webkit.messageHandlers[FNJSToNativeHandlerName];handler.postMessage(params)};const FNSendNativeSync=params=>{let res=prompt(JSON.stringify(params));try{res=JSON.parse(res);return res.data}catch(error){console.log('❌SendNativeSync--error');console.log(error)}return null};const FNGeneratorAPI=(apiPrefix,apiMap)=>{let res={};for(const key in apiMap){if(!apiMap.hasOwnProperty(key)){continue}const config=apiMap[key];const isSync=config.hasOwnProperty('sync')?config.sync:false;const func=isSync?params=>{return FNSendNativeSync(FNSendParamsSync(apiPrefix,key,params))}:params=>{FNSendNative(FNSendParams(apiPrefix,key,params))};res[key]=func}return res};const fund=FNGeneratorAPI('fund',FNCommonAPI);const zheng=FNGeneratorAPI('zheng',FNZhengInternalAPI);