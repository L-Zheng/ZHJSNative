var ZhengJSToNativeLogHandlerName='%@';console.log=function(oriLogFunc){return function(){oriLogFunc.call(console,arguments);var errorRes=[];var parseData=function(data){var res=null;var type=Object.prototype.toString.call(data);if(type=='[object Null]'||type=='[object String]'||type=='[object Number]'){res=data}else if(type=='[object Function]'){res=data.toString()}else if(type=='[object Undefined]'){res='Undefined'}else if(type=='[object Boolean]'){res=data?'true':'false'}else if(type=='[object Object]'){res={};var mapKeys=Object.keys(data);for(var i=0;i<mapKeys.length;i++){(function(key){res[key]=parseData(data[key])})(mapKeys[i])}}else if(type=='[object Array]'){res=[];data.forEach(function(el){res.push(parseData(el))})}else if(type=='[object Error]'){res=data;errorRes.push(res)}else if(type=='[object Window]'){res=data.toString()}else{res=data}return res};var params=arguments;var type=Object.prototype.toString.call(params);var argCount=params.length;if(type!='[object Arguments]')return;var iosRes=[];var fetchVaule=function(idx){return argCount>idx?params[idx]:'无此参数'};if(argCount==0)return;if(argCount==1){iosRes=parseData(fetchVaule(0))}else{for(var idx=0;idx<argCount;idx++){iosRes.push(parseData(fetchVaule(idx)))}}try{var handler=window.webkit.messageHandlers[ZhengJSToNativeLogHandlerName];handler.postMessage(JSON.parse(JSON.stringify(iosRes)))}catch(error){}return;if(errorRes.length==0)return;if(!window.onerror)return;try{errorRes.forEach(function(el){window.onerror(el)})}catch(error){}}}(console.log);