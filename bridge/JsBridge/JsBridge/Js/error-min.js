window.onerror=function(oriFunc){return function(){try{if(oriFunc){oriFunc.apply(window,arguments)}var params=arguments;if(Object.prototype.toString.call(params)!='[object Arguments]'){return}var argCount=params.length;if(argCount==0){return}var resErr={};var keys=['message','sourceURL','line','column','stack'];if(Object.prototype.toString.call(params[0])=='[object Error]'){keys.forEach(function(el){resErr[el]=params[0][el]})}else{if(argCount>4&&Object.prototype.toString.call(params[4])=='[object Error]'){keys.forEach(function(el){resErr[el]=params[4][el]})}else{var minCount=Math.min(keys.length,argCount);for(let i=0;i<minCount;i++){resErr[keys[i]]=params[i]}}}%@.sendNative(JSON.parse(JSON.stringify(resErr)))}catch(error){}}}(window.onerror);