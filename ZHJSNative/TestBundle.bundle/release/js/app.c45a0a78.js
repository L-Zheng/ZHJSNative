/******/ (function(modules) { // webpackBootstrap
/******/ 	// install a JSONP callback for chunk loading
/******/ 	function webpackJsonpCallback(data) {
/******/ 		var chunkIds = data[0];
/******/ 		var moreModules = data[1];
/******/ 		var executeModules = data[2];
/******/
/******/ 		// add "moreModules" to the modules object,
/******/ 		// then flag all "chunkIds" as loaded and fire callback
/******/ 		var moduleId, chunkId, i = 0, resolves = [];
/******/ 		for(;i < chunkIds.length; i++) {
/******/ 			chunkId = chunkIds[i];
/******/ 			if(Object.prototype.hasOwnProperty.call(installedChunks, chunkId) && installedChunks[chunkId]) {
/******/ 				resolves.push(installedChunks[chunkId][0]);
/******/ 			}
/******/ 			installedChunks[chunkId] = 0;
/******/ 		}
/******/ 		for(moduleId in moreModules) {
/******/ 			if(Object.prototype.hasOwnProperty.call(moreModules, moduleId)) {
/******/ 				modules[moduleId] = moreModules[moduleId];
/******/ 			}
/******/ 		}
/******/ 		if(parentJsonpFunction) parentJsonpFunction(data);
/******/
/******/ 		while(resolves.length) {
/******/ 			resolves.shift()();
/******/ 		}
/******/
/******/ 		// add entry modules from loaded chunk to deferred list
/******/ 		deferredModules.push.apply(deferredModules, executeModules || []);
/******/
/******/ 		// run deferred modules when all chunks ready
/******/ 		return checkDeferredModules();
/******/ 	};
/******/ 	function checkDeferredModules() {
/******/ 		var result;
/******/ 		for(var i = 0; i < deferredModules.length; i++) {
/******/ 			var deferredModule = deferredModules[i];
/******/ 			var fulfilled = true;
/******/ 			for(var j = 1; j < deferredModule.length; j++) {
/******/ 				var depId = deferredModule[j];
/******/ 				if(installedChunks[depId] !== 0) fulfilled = false;
/******/ 			}
/******/ 			if(fulfilled) {
/******/ 				deferredModules.splice(i--, 1);
/******/ 				result = __webpack_require__(__webpack_require__.s = deferredModule[0]);
/******/ 			}
/******/ 		}
/******/
/******/ 		return result;
/******/ 	}
/******/
/******/ 	// The module cache
/******/ 	var installedModules = {};
/******/
/******/ 	// object to store loaded and loading chunks
/******/ 	// undefined = chunk not loaded, null = chunk preloaded/prefetched
/******/ 	// Promise = chunk loading, 0 = chunk loaded
/******/ 	var installedChunks = {
/******/ 		"app": 0
/******/ 	};
/******/
/******/ 	var deferredModules = [];
/******/
/******/ 	// The require function
/******/ 	function __webpack_require__(moduleId) {
/******/
/******/ 		// Check if module is in cache
/******/ 		if(installedModules[moduleId]) {
/******/ 			return installedModules[moduleId].exports;
/******/ 		}
/******/ 		// Create a new module (and put it into the cache)
/******/ 		var module = installedModules[moduleId] = {
/******/ 			i: moduleId,
/******/ 			l: false,
/******/ 			exports: {}
/******/ 		};
/******/
/******/ 		// Execute the module function
/******/ 		modules[moduleId].call(module.exports, module, module.exports, __webpack_require__);
/******/
/******/ 		// Flag the module as loaded
/******/ 		module.l = true;
/******/
/******/ 		// Return the exports of the module
/******/ 		return module.exports;
/******/ 	}
/******/
/******/
/******/ 	// expose the modules object (__webpack_modules__)
/******/ 	__webpack_require__.m = modules;
/******/
/******/ 	// expose the module cache
/******/ 	__webpack_require__.c = installedModules;
/******/
/******/ 	// define getter function for harmony exports
/******/ 	__webpack_require__.d = function(exports, name, getter) {
/******/ 		if(!__webpack_require__.o(exports, name)) {
/******/ 			Object.defineProperty(exports, name, { enumerable: true, get: getter });
/******/ 		}
/******/ 	};
/******/
/******/ 	// define __esModule on exports
/******/ 	__webpack_require__.r = function(exports) {
/******/ 		if(typeof Symbol !== 'undefined' && Symbol.toStringTag) {
/******/ 			Object.defineProperty(exports, Symbol.toStringTag, { value: 'Module' });
/******/ 		}
/******/ 		Object.defineProperty(exports, '__esModule', { value: true });
/******/ 	};
/******/
/******/ 	// create a fake namespace object
/******/ 	// mode & 1: value is a module id, require it
/******/ 	// mode & 2: merge all properties of value into the ns
/******/ 	// mode & 4: return value when already ns object
/******/ 	// mode & 8|1: behave like require
/******/ 	__webpack_require__.t = function(value, mode) {
/******/ 		if(mode & 1) value = __webpack_require__(value);
/******/ 		if(mode & 8) return value;
/******/ 		if((mode & 4) && typeof value === 'object' && value && value.__esModule) return value;
/******/ 		var ns = Object.create(null);
/******/ 		__webpack_require__.r(ns);
/******/ 		Object.defineProperty(ns, 'default', { enumerable: true, value: value });
/******/ 		if(mode & 2 && typeof value != 'string') for(var key in value) __webpack_require__.d(ns, key, function(key) { return value[key]; }.bind(null, key));
/******/ 		return ns;
/******/ 	};
/******/
/******/ 	// getDefaultExport function for compatibility with non-harmony modules
/******/ 	__webpack_require__.n = function(module) {
/******/ 		var getter = module && module.__esModule ?
/******/ 			function getDefault() { return module['default']; } :
/******/ 			function getModuleExports() { return module; };
/******/ 		__webpack_require__.d(getter, 'a', getter);
/******/ 		return getter;
/******/ 	};
/******/
/******/ 	// Object.prototype.hasOwnProperty.call
/******/ 	__webpack_require__.o = function(object, property) { return Object.prototype.hasOwnProperty.call(object, property); };
/******/
/******/ 	// __webpack_public_path__
/******/ 	__webpack_require__.p = "";
/******/
/******/ 	var jsonpArray = window["webpackJsonp"] = window["webpackJsonp"] || [];
/******/ 	var oldJsonpFunction = jsonpArray.push.bind(jsonpArray);
/******/ 	jsonpArray.push = webpackJsonpCallback;
/******/ 	jsonpArray = jsonpArray.slice();
/******/ 	for(var i = 0; i < jsonpArray.length; i++) webpackJsonpCallback(jsonpArray[i]);
/******/ 	var parentJsonpFunction = oldJsonpFunction;
/******/
/******/
/******/ 	// add entry module to deferred list
/******/ 	deferredModules.push([0,"chunk-vendors"]);
/******/ 	// run deferred modules when ready
/******/ 	return checkDeferredModules();
/******/ })
/************************************************************************/
/******/ ({

/***/ 0:
/***/ (function(module, exports, __webpack_require__) {

module.exports = __webpack_require__("56d7");


/***/ }),

/***/ "33b4":
/***/ (function(module, exports, __webpack_require__) {

// extracted by mini-css-extract-plugin

/***/ }),

/***/ "56d7":
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);

// EXTERNAL MODULE: ./node_modules/core-js/modules/es.array.iterator.js
var es_array_iterator = __webpack_require__("e260");

// EXTERNAL MODULE: ./node_modules/core-js/modules/es.promise.js
var es_promise = __webpack_require__("e6cf");

// EXTERNAL MODULE: ./node_modules/core-js/modules/es.object.assign.js
var es_object_assign = __webpack_require__("cca6");

// EXTERNAL MODULE: ./node_modules/core-js/modules/es.promise.finally.js
var es_promise_finally = __webpack_require__("a79d");

// EXTERNAL MODULE: ./node_modules/vue/dist/vue.runtime.esm.js
var vue_runtime_esm = __webpack_require__("2b0e");

// CONCATENATED MODULE: ./node_modules/@vue/cli-service/node_modules/cache-loader/dist/cjs.js?{"cacheDirectory":"node_modules/.cache/vue-loader","cacheIdentifier":"7f5afa36-vue-loader-template"}!./node_modules/@vue/cli-service/node_modules/vue-loader/lib/loaders/templateLoader.js??vue-loader-options!./node_modules/@vue/cli-service/node_modules/cache-loader/dist/cjs.js??ref--0-0!./node_modules/@vue/cli-service/node_modules/vue-loader/lib??vue-loader-options!./src/App.vue?vue&type=template&id=31e25cbe&scoped=true&
var Appvue_type_template_id_31e25cbe_scoped_true_render = function () {var _vm=this;var _h=_vm.$createElement;var _c=_vm._self._c||_h;return _c('div',[_c('div',[_c('div',{domProps:{"innerHTML":_vm._s(_vm.testEmotion)}}),_c('div',{domProps:{"innerHTML":_vm._s(_vm.testBigEmotion)}})])])}
var staticRenderFns = []


// CONCATENATED MODULE: ./src/App.vue?vue&type=template&id=31e25cbe&scoped=true&

// EXTERNAL MODULE: ./node_modules/core-js/modules/es.array.for-each.js
var es_array_for_each = __webpack_require__("4160");

// EXTERNAL MODULE: ./node_modules/core-js/modules/es.array.index-of.js
var es_array_index_of = __webpack_require__("c975");

// EXTERNAL MODULE: ./node_modules/core-js/modules/es.array.splice.js
var es_array_splice = __webpack_require__("a434");

// EXTERNAL MODULE: ./node_modules/core-js/modules/es.object.keys.js
var es_object_keys = __webpack_require__("b64b");

// EXTERNAL MODULE: ./node_modules/core-js/modules/web.dom-collections.for-each.js
var web_dom_collections_for_each = __webpack_require__("159b");

// EXTERNAL MODULE: ./node_modules/@babel/runtime/helpers/esm/classCallCheck.js
var classCallCheck = __webpack_require__("d4ec");

// EXTERNAL MODULE: ./node_modules/@babel/runtime/helpers/esm/createClass.js
var createClass = __webpack_require__("bee2");

// EXTERNAL MODULE: ./node_modules/@babel/runtime/helpers/esm/defineProperty.js
var defineProperty = __webpack_require__("ade3");

// EXTERNAL MODULE: ./node_modules/core-js/modules/es.object.to-string.js
var es_object_to_string = __webpack_require__("d3b7");

// EXTERNAL MODULE: ./node_modules/core-js/modules/es.regexp.to-string.js
var es_regexp_to_string = __webpack_require__("25f0");

// CONCATENATED MODULE: ./src/base/JSTool.js






var JSTool_JSTool = /*#__PURE__*/function () {
  function JSTool() {
    Object(classCallCheck["a" /* default */])(this, JSTool);
  }

  Object(createClass["a" /* default */])(JSTool, [{
    key: "dataType",
    value: function dataType(data) {
      return Object.prototype.toString.call(data);
    }
  }, {
    key: "isFunction",
    value: function isFunction(myFunc) {
      return JSTool.Type.isFunction(myFunc);
    }
  }, {
    key: "isArray",
    value: function isArray(value) {
      return JSTool.Type.isArray(value);
    }
  }, {
    key: "isObject",
    value: function isObject(value) {
      return JSTool.Type.isObject(value);
    }
  }, {
    key: "isJson",
    value: function isJson(value) {
      return JSTool.Type.isObject(value);
    }
  }, {
    key: "isString",
    value: function isString(value) {
      return JSTool.Type.isString(value);
    }
  }, {
    key: "isNumber",
    value: function isNumber(value) {
      return JSTool.Type.isNumber(value);
    }
  }, {
    key: "isBoolean",
    value: function isBoolean(value) {
      return JSTool.Type.isBoolean(value);
    }
  }, {
    key: "isUndefined",
    value: function isUndefined(value) {
      return JSTool.Type.isUndefined(value);
    }
  }, {
    key: "isSymbol",
    value: function isSymbol(value) {
      return JSTool.Type.isSymbol(value);
    }
  }, {
    key: "isNull",
    value: function isNull(value) {
      return JSTool.Type.isNull(value);
    }
  }, {
    key: "isArguments",
    value: function isArguments(value) {
      return JSTool.Type.isArguments(value);
    }
  }, {
    key: "isError",
    value: function isError(value) {
      return JSTool.Type.isError(value);
    }
  }, {
    key: "fetchData",
    value: function fetchData(json, key, type) {
      var emptyData = function emptyData(type) {
        if (type == 'Object') return {};
        if (type == 'Array') return [];
        if (type == 'String') return '';
        if (type == 'Number') return 0;
        if (type == 'Boolean') return false;
        return '';
      };

      if (!json || !JSTool.Type.isObject(json) || !JSTool.Type.isString(key)) {
        return emptyData(type);
      }

      if (!key || key.length == 0) {
        return emptyData(type);
      }

      var res = null;

      for (var k in json) {
        if (json.hasOwnProperty(k)) {
          if (k.toLowerCase() == key.toLowerCase()) {
            res = json[k];
            break;
          }
        }
      }

      if (JSTool.Type.isNull(res)) return emptyData(type);
      if (type == 'Object' && JSTool.Type.isObject(res)) return res;
      if (type == 'Array' && JSTool.Type.isArray(res)) return res;

      if (type == 'String') {
        if (JSTool.Type.isString(res)) return res;
        if (JSTool.Type.isNumber(res)) return res.toString();
      }

      if (type == 'Number') {
        if (JSTool.Type.isNumber(res)) return res;
        if (JSTool.Type.isString(res)) return parseFloat(res);
      }

      if (type == 'Boolean') {
        if (JSTool.Type.isBoolean(res)) {
          return res;
        }

        if (JSTool.Type.isNumber(res)) {
          return res == 0 ? false : true;
        }

        if (JSTool.Type.isString(res)) {
          return parseFloat(res) == 0 ? false : true;
        }
      }

      return emptyData(type);
    } //json取值 可防止js报错 or  数据异常

  }, {
    key: "fetchArray",
    value: function fetchArray(json, key) {
      return this.fetchData(json, key, 'Array');
    }
  }, {
    key: "fetchJson",
    value: function fetchJson(json, key) {
      return this.fetchData(json, key, 'Object');
    }
  }, {
    key: "fetchString",
    value: function fetchString(json, key) {
      return this.fetchData(json, key, 'String');
    }
  }, {
    key: "fetchNumber",
    value: function fetchNumber(json, key) {
      return this.fetchData(json, key, 'Number');
    }
  }, {
    key: "fetchBoolean",
    value: function fetchBoolean(json, key) {
      return this.fetchData(json, key, 'Boolean');
    }
  }, {
    key: "insertJsonValue",
    value: function insertJsonValue(json, key, value) {
      if (!json || !JSTool.Type.isObject(json) || !JSTool.Type.isString(key)) {
        return json;
      }

      if (!key || key.length == 0) {
        return json;
      }

      var isHave = false;
      var haveKey = '';

      for (var k in json) {
        if (json.hasOwnProperty(k)) {
          if (k.toLowerCase() == key.toLowerCase()) {
            haveKey = k;
            isHave = true;
            break;
          }
        }
      }

      if (isHave) {
        json[haveKey] = value;
        return json;
      }

      json[key] = value;
      return json;
    }
  }]);

  return JSTool;
}();

Object(defineProperty["a" /* default */])(JSTool_JSTool, "Type", function () {
  var type = {};
  var typeArr = ['String', 'Object', 'Number', 'Array', 'Undefined', 'Function', 'Null', 'Symbol', 'Boolean', 'Arguments', 'Error'];

  for (var i = 0; i < typeArr.length; i++) {
    (function (name) {
      type['is' + name] = function (obj) {
        return Object.prototype.toString.call(obj) == '[object ' + name + ']';
      };
    })(typeArr[i]);
  }

  return type;
}());

/* harmony default export */ var base_JSTool = (new JSTool_JSTool());
// CONCATENATED MODULE: ./src/base/NewsNoti.js











var NewsNoti_NewsNoti = /*#__PURE__*/function () {
  function NewsNoti() {
    Object(classCallCheck["a" /* default */])(this, NewsNoti);
  }

  Object(createClass["a" /* default */])(NewsNoti, [{
    key: "reg",
    //   static eventBus = new Vue();
    //   // eventBus.$emit
    // // eventBus.$on
    value: function reg(key, action) {
      //容错
      if (!key || !base_JSTool.isString(key)) {
        return false;
      }

      if (!base_JSTool.isFunction(action)) {
        return false;
      }

      var map = NewsNoti.notiMap;
      var actions = [];
      var keys = Object.keys(map);

      if (keys.indexOf(key) == -1) {
        actions = [action];
      } else {
        actions = map[key];
        actions.push(action);
      }

      map[key] = actions;
      NewsNoti.notiMap = map;
    }
  }, {
    key: "remove",
    value: function remove(key, action) {
      //容错
      if (!key || !base_JSTool.isString(key)) {
        return false;
      }

      if (!base_JSTool.isFunction(action)) {
        return false;
      }

      var map = NewsNoti.notiMap;
      var keys = Object.keys(map);
      if (keys.indexOf(key) == -1) return;
      var actions = map[key];
      var targetIndex = actions.indexOf(action);
      if (targetIndex == -1) return;
      actions.splice(targetIndex, 1);
      map[key] = actions;
      NewsNoti.notiMap = map;
    }
  }, {
    key: "post",
    value: function post(key, parmas) {
      //容错
      if (!key || !base_JSTool.isString(key)) {
        return false;
      }

      var map = NewsNoti.notiMap;
      var keys = Object.keys(map);

      if (keys.indexOf(key) == -1) {
        return;
      }

      var actions = map[key];
      actions.forEach(function (el) {
        if (base_JSTool.isFunction(el)) {
          try {
            el(parmas);
          } catch (error) {
            console.log(error);
          }
        }
      });
    }
  }]);

  return NewsNoti;
}();

Object(defineProperty["a" /* default */])(NewsNoti_NewsNoti, "notiMap", {});

/* harmony default export */ var base_NewsNoti = (new NewsNoti_NewsNoti());
// CONCATENATED MODULE: ./src/base/NativeMsg.js










var NativeMsg_NativeMsg = /*#__PURE__*/function () {
  function NativeMsg() {
    Object(classCallCheck["a" /* default */])(this, NativeMsg);
  }

  Object(createClass["a" /* default */])(NativeMsg, [{
    key: "reg",
    value: function reg(key, action) {
      //容错
      if (!key || !base_JSTool.isString(key)) {
        return false;
      }

      if (!base_JSTool.isFunction(action)) {
        return false;
      }

      var map = NativeMsg.msgMap;
      var actions = [];
      var keys = Object.keys(map);

      if (keys.indexOf(key) == -1) {
        actions = [action];
      } else {
        actions = map[key];
        actions.push(action);
      }

      map[key] = actions;
      NativeMsg.msgMap = map;
    }
  }, {
    key: "post",
    value: function post(parmas) {
      var jsonData = decodeURIComponent(parmas);

      if (base_JSTool.isString(jsonData)) {
        jsonData = JSON.parse(jsonData);
      }

      if (!base_JSTool.isObject(jsonData)) {
        jsonData = {};
      }

      var key = base_JSTool.fetchString(jsonData, "key");
      var value = jsonData.value; //容错

      if (!key || !base_JSTool.isString(key)) {
        return false;
      }

      var map = NativeMsg.msgMap;
      var keys = Object.keys(map);

      if (keys.indexOf(key) == -1) {
        return;
      }

      var actions = map[key];
      actions.forEach(function (el) {
        if (base_JSTool.isFunction(el)) {
          try {
            el(value);
          } catch (error) {
            console.log(error);
          }
        }
      });
    }
  }]);

  return NativeMsg;
}();

Object(defineProperty["a" /* default */])(NativeMsg_NativeMsg, "msgMap", {});

/* harmony default export */ var base_NativeMsg = (new NativeMsg_NativeMsg());
// EXTERNAL MODULE: ./node_modules/core-js/modules/es.array.concat.js
var es_array_concat = __webpack_require__("99af");

// EXTERNAL MODULE: ./node_modules/core-js/modules/es.number.to-fixed.js
var es_number_to_fixed = __webpack_require__("b680");

// EXTERNAL MODULE: ./node_modules/core-js/modules/es.regexp.constructor.js
var es_regexp_constructor = __webpack_require__("4d63");

// EXTERNAL MODULE: ./node_modules/core-js/modules/es.regexp.exec.js
var es_regexp_exec = __webpack_require__("ac1f");

// EXTERNAL MODULE: ./node_modules/core-js/modules/es.string.replace.js
var es_string_replace = __webpack_require__("5319");

// EXTERNAL MODULE: ./node_modules/core-js/modules/es.string.split.js
var es_string_split = __webpack_require__("1276");

// CONCATENATED MODULE: ./src/base/NewsType.js



var NewsType_NewsType = function NewsType() {
  Object(classCallCheck["a" /* default */])(this, NewsType);
} //资讯100、帖子200、回答202、财富号300正文
;

Object(defineProperty["a" /* default */])(NewsType_NewsType, "Type", {
  News: 100,
  Post: 200,
  Answer: 202,
  Wealth: 300
});

/* harmony default export */ var base_NewsType = (NewsType_NewsType.Type);
// CONCATENATED MODULE: ./src/base/news-format-dataapi.js



 // 处理该域名下的数据  620线上版 资讯与财富号
// https://dataapi.1234567.com.cn/community/show/article?serverversion=6.2.5&userid=&product=EFund&passportid=&deviceid=F0DD802F-6164-439E-9ACB-85763AAE813F&plat=Iphone&ids=202001141355870036_100&ctoken=&utoken=&version=6.3.0&gtoken=85D646FD659449F7A3E646530A51F372

var news_format_dataapi_NewsFormatDataapi = /*#__PURE__*/function () {
  function NewsFormatDataapi() {
    Object(classCallCheck["a" /* default */])(this, NewsFormatDataapi);
  }

  Object(createClass["a" /* default */])(NewsFormatDataapi, [{
    key: "convertBody",
    value: function convertBody(news) {
      return base_JSTool.fetchString(news, 'content');
    }
  }, {
    key: "formatWealth",
    value: function formatWealth(article) {
      var news = article.data;
      var authorModel = base_JSTool.fetchJson(news, 'authorModel');
      var shareModel = base_JSTool.fetchJson(news, 'shareModel');
      return {
        Id: article.Id,
        type: article.type,
        body: this.convertBody(news),
        htmlBody: article.htmlData,
        rawData: news,
        //接口原始数据
        barOutCode: base_JSTool.fetchString(base_JSTool.fetchJson(news, 'barModel'), 'barCode'),
        title: base_JSTool.fetchString(news, 'title'),
        summary: base_JSTool.fetchString(news, 'summary'),
        showTime: base_JSTool.fetchString(news, 'showTime'),
        source: base_JSTool.fetchString(news, 'source'),
        user: {
          userId: base_JSTool.fetchString(authorModel, 'pid'),
          userName: base_JSTool.fetchString(authorModel, 'nickName'),
          vType: base_JSTool.fetchNumber(authorModel, 'vType'),
          introduce: base_JSTool.fetchString(authorModel, 'introduce'),
          mgrId: base_JSTool.fetchString(authorModel, 'mgrId'),
          cfhId: base_JSTool.fetchString(authorModel, 'cfhId'),
          cfhtype: base_JSTool.fetchNumber(authorModel, 'cfhtype')
        },
        shareUrl: base_JSTool.fetchString(shareModel, 'shareUrl'),
        repostState: base_JSTool.fetchNumber(news, 'repostState')
      };
    }
  }, {
    key: "formatNews",
    value: function formatNews(article) {
      var news = article.data;
      var authorModel = base_JSTool.fetchJson(news, 'authorModel');
      return {
        Id: article.Id,
        type: article.type,
        body: this.convertBody(news),
        htmlBody: article.htmlData,
        rawData: news,
        //接口原始数据
        barType: '',
        barOutCode: base_JSTool.fetchString(base_JSTool.fetchJson(news, 'barModel'), 'barCode'),
        title: base_JSTool.fetchString(news, 'title'),
        summary: base_JSTool.fetchString(news, 'summary'),
        showTime: base_JSTool.fetchString(news, 'showTime'),
        source: base_JSTool.fetchString(news, 'source'),
        user: {
          userId: base_JSTool.fetchString(authorModel, 'pid'),
          userName: base_JSTool.fetchString(authorModel, 'nickName')
        },
        repostState: base_JSTool.fetchNumber(news, 'repostState')
      };
    }
  }]);

  return NewsFormatDataapi;
}();

/* harmony default export */ var news_format_dataapi = (new news_format_dataapi_NewsFormatDataapi());
// CONCATENATED MODULE: ./src/base/news-format-gbapi.js









 // 处理该域名下的数据  620线上版 问答与帖子
// https://gbapi.eastmoney.com/content/api/Post/FundArticleContent?postid=904847818&gtoken=85D646FD659449F7A3E646530A51F372&userid=&deviceid=F0DD802F-6164-439E-9ACB-85763AAE813F&product=Fund&serverversion=6.2.5&plat=Iphone&passportid=&version=630

var news_format_gbapi_NewsFormatGbapi = /*#__PURE__*/function () {
  function NewsFormatGbapi() {
    Object(classCallCheck["a" /* default */])(this, NewsFormatGbapi);
  }

  Object(createClass["a" /* default */])(NewsFormatGbapi, [{
    key: "getBarType",
    value: function getBarType(articleData) {
      var barType = 0;
      var code_name = articleData.code_name;

      if (code_name.indexOf("jjcl") != -1) {
        barType = 48;
      }

      if (code_name.indexOf("jjsp") != -1) {
        barType = 43;
      }

      return barType;
    }
  }, {
    key: "getBarOutCode",
    value: function getBarOutCode(articleData) {
      var barType = this.getBarType(articleData);
      var barOutCode = "";
      var post_guba = base_JSTool.fetchJson(articleData, 'post_guba');
      var barName = post_guba.stockbar_name;
      barOutCode = base_JSTool.fetchString(post_guba, 'stockbar_inner_code');

      if (barType == 43 || barType == 48) {
        var extend = articleData.extend; //实盘吧和策略吧从基金给股吧的扩展信息里面取

        barOutCode = base_JSTool.fetchString(extend, 'code');
      } else {
        if (barOutCode.length > 6) {
          if (barOutCode.indexOf("gd") != -1) {
            //包含高端理财
            barOutCode = barOutCode.substring(2);
          }

          if (barOutCode.indexOf("_") != -1 && barOutCode.length > 2) {
            var codeList = barOutCode.split("_");

            if (codeList.length > 0) {
              barOutCode = codeList[0];
            }
          }
        } else {
          if (barOutCode.indexOf("_1") != -1 && barOutCode.length > 2) {
            barOutCode = barOutCode.substring(0, barOutCode.length - 2);
          }
        }
      }

      console.log("barOutCode  " + barOutCode);
      return barOutCode;
    }
  }, {
    key: "getQuestion",
    value: function getQuestion(extend) {
      var question = base_JSTool.fetchJson(extend, "GuBa_FundQuestion");
      return {
        article_id: base_JSTool.fetchString(question, "article_id"),
        question_id: base_JSTool.fetchString(question, "question_id"),
        title: base_JSTool.fetchString(question, "question_title"),
        pay_type: base_JSTool.fetchNumber(question, "pay_type"),
        amount: base_JSTool.fetchString(question, "amount"),
        createdtime: base_JSTool.fetchString(question, "createdtime"),
        endtime: base_JSTool.fetchString(question, "endtime"),
        answer_num: base_JSTool.fetchNumber(question, "answer_num"),
        question_userid: base_JSTool.fetchNumber(question, "question_userid"),
        question_title: base_JSTool.fetchNumber(question, "question_title"),
        isEnd: base_JSTool.fetchNumber(question, "isEnd")
      };
    }
  }, {
    key: "getAnswer",
    value: function getAnswer(extend) {
      var answer = base_JSTool.fetchJson(extend, "GuBa_FundAnswer");
      return {
        qid: base_JSTool.fetchString(answer, "QID"),
        aid: base_JSTool.fetchString(answer, "AID"),
        IsAdopted: base_JSTool.fetchString(answer, "IsAdopted"),
        userId: base_JSTool.fetchString(answer, "CreatorID")
      };
    }
  }, {
    key: "getFundExtTags",
    value: function getFundExtTags(ContentExtTags) {
      var fundExtTags = [];
      ContentExtTags.forEach(function (el) {
        fundExtTags.push({
          busType: base_JSTool.fetchNumber(el, "BusType"),
          code: base_JSTool.fetchArray(el, "Code"),
          name: base_JSTool.fetchString(el, "Name"),
          remark: base_JSTool.fetchString(el, "Remark"),
          imgUrl: base_JSTool.fetchString(el, "ImgUrl"),
          appUrl: function () {
            var link = base_JSTool.fetchJson(el, "AppUrl");
            return {
              linkType: base_JSTool.fetchNumber(link, 'LinkType'),
              adId: base_JSTool.fetchNumber(link, 'AdId'),
              linkTo: base_JSTool.fetchString(link, 'LinkTo')
            };
          }()
        });
      });
      return fundExtTags;
    }
  }, {
    key: "getFundTags",
    value: function getFundTags(ContentTags) {
      var fundTags = [];
      ContentTags.forEach(function (el) {
        fundTags.push({
          busType: base_JSTool.fetchNumber(el, "BusType"),
          code: base_JSTool.fetchArray(el, "Code"),
          name: base_JSTool.fetchString(el, "Name"),
          remark: base_JSTool.fetchString(el, "Remark"),
          imgUrl: base_JSTool.fetchString(el, "ImgUrl"),
          // delete 
          label: base_JSTool.fetchString(el, "Label"),
          text: base_JSTool.fetchArray(el, "Text"),
          appUrl: function () {
            var link = base_JSTool.fetchJson(el, "AppUrl");

            if (Object.keys(link).length == 0) {
              link = base_JSTool.fetchJson(el, "appLink");
            }

            if (Object.keys(link).length == 0) return {};
            return {
              linkType: base_JSTool.fetchNumber(link, 'LinkType'),
              linkTo: base_JSTool.fetchString(link, 'LinkTo')
            };
          }()
        });
      });
      return fundTags;
    }
  }, {
    key: "format",
    value: function format(article) {
      var news = article.data; //帖子所在股吧信息
      //基础股吧字段 http://gubadoc.eastmoney.com/gubaapi/index.php?s=/2&page_id=193

      var post_guba = base_JSTool.fetchJson(news, 'post_guba'); //发帖人信息
      //基础用户字段 http://gubadoc.eastmoney.com/gubaapi/index.php?s=/2&page_id=194

      var user = base_JSTool.fetchJson(news, 'post_user'); //特殊帖子的附加信息
      //特殊帖子扩展模板 http://gubadoc.eastmoney.com/gubaapi/index.php?s=/4&page_id=473

      var extend = base_JSTool.fetchJson(news, "extend"); //源帖特殊帖子的附加信息 特殊帖子扩展模板

      var source_extend = base_JSTool.fetchJson(news, "source_extend"); //关键字信息

      var ContentTags = base_JSTool.fetchArray(base_JSTool.fetchJson(extend, "FundTags"), "ContentTags"); //扩展信息

      var ContentExtTags = base_JSTool.fetchArray(base_JSTool.fetchJson(extend, "FundTags"), "ContentExtTags"); //话题扩展信息

      var FundTopicPost = base_JSTool.fetchArray(extend, "FundTopicPost");
      var FundShowTitle = base_JSTool.fetchNumber(extend, "FundShowTitle");
      return {
        Id: article.Id,
        type: article.type,
        htmlBody: article.htmlData,
        rawData: news,
        //接口原始数据
        barType: this.getBarType(news),
        barOutCode: this.getBarOutCode(news),
        title: base_JSTool.fetchString(news, 'post_title'),
        showTitle: FundShowTitle,
        content: base_JSTool.fetchString(news, 'post_content'),
        summary: base_JSTool.fetchString(news, 'post_abstract'),
        publishTime: base_JSTool.fetchString(news, 'post_publish_time'),
        likeCount: base_JSTool.fetchString(news, 'post_like_count'),
        commentCount: base_JSTool.fetchString(news, 'post_comment_count'),
        //转发资讯
        sourcePost: {
          Id: function () {
            var id = base_JSTool.fetchString(news, 'source_post_id');
            return parseInt(id) == 0 ? "" : id;
          }(),
          type: base_JSTool.fetchNumber(news, 'source_post_type'),
          sourceId: base_JSTool.fetchString(news, "source_post_source_id"),
          userId: base_JSTool.fetchString(news, "source_post_user_id"),
          userName: base_JSTool.fetchString(news, "source_post_user_nickname"),
          title: base_JSTool.fetchString(news, "source_post_title"),
          content: base_JSTool.fetchString(news, "source_post_content"),
          picUrl: base_JSTool.fetchArray(news, "source_post_pic_url"),
          question: this.getQuestion(source_extend),
          answer: this.getAnswer(source_extend),
          fundTags: this.getFundTags(base_JSTool.fetchArray(base_JSTool.fetchJson(source_extend, "FundTags"), "ContentTags")),
          fundExtTags: this.getFundExtTags(base_JSTool.fetchArray(base_JSTool.fetchJson(source_extend, "FundTags"), "ContentExtTags"))
        },
        fundTags: this.getFundTags(ContentTags),
        fundExtTags: this.getFundExtTags(ContentExtTags),
        postGuba: {
          name: base_JSTool.fetchString(post_guba, 'stockbar_name')
        },
        user: {
          userId: base_JSTool.fetchString(user, 'user_id'),
          userName: base_JSTool.fetchString(user, 'user_nickname'),
          introduce: base_JSTool.fetchString(user, 'user_introduce')
        },
        question: this.getQuestion(extend),
        answer: this.getAnswer(extend),
        picUrl: base_JSTool.fetchArray(news, 'post_pic_url'),
        picUrl2: base_JSTool.fetchArray(news, 'post_pic_url2'),
        fundTopicPost: FundTopicPost,
        atUser: base_JSTool.fetchArray(news, 'post_atuser'),
        codeName: base_JSTool.fetchString(news, 'code_name'),
        repostState: base_JSTool.fetchNumber(news, 'repost_state')
      };
    }
  }]);

  return NewsFormatGbapi;
}();

/* harmony default export */ var news_format_gbapi = (new news_format_gbapi_NewsFormatGbapi());
// CONCATENATED MODULE: ./src/base/news-format-newsinfo.js









 // 处理该域名下的数据  资讯
// http://newsinfo.eastmoney.com/kuaixun/v2/api/content/getnews?newsid=202001141355870036&newstype=1&source=app&sys=andorid&version=600000001&guid=appzxzw954ca1c5-94c2-2dec-70e8-0322af5658e9

var news_format_newsinfo_NewsFormatNewsinfo = /*#__PURE__*/function () {
  function NewsFormatNewsinfo() {
    Object(classCallCheck["a" /* default */])(this, NewsFormatNewsinfo);
  }

  Object(createClass["a" /* default */])(NewsFormatNewsinfo, [{
    key: "convertBody",
    value: function convertBody(news) {
      var body = base_JSTool.fetchString(news, 'body');
      if (!body) return '';
      return body; //保征：新资讯接口会处理基金关键词，不需要走何亮接口，直接返回

      var reg = ''; //替换<strong></strong>为<b></b>

      reg = new RegExp('(<strong>)', "g");
      body = body.replace(reg, function (word) {
        return '<b>';
      });
      reg = new RegExp('(</strong>)', "g");
      body = body.replace(reg, function (word) {
        return '</b>';
      }); //替换  &gt;&gt;&gt; 为  >>>
      // reg = new RegExp('(<strong>.*?</strong>)', "g");

      reg = new RegExp('(&gt;)', "g");
      body = body.replace(reg, function (word) {
        return '>';
      }); //替换

      console.log('convertBodyconvertBody');
      var domin1 = 'http://quote.eastmoney.com/unify/r/';
      var tDomin1 = 'https://emwap.eastmoney.com/quota/hq/stock?';
      reg = new RegExp("(".concat(domin1, ".*)"), "g");
      body = body.replace(reg, function (word) {
        console.log(word);
        var paramsStr = word.replace(new RegExp(domin1), '');

        if (paramsStr && base_JSTool.isString(paramsStr)) {
          var paramsArr = paramsStr.split('.');

          if (paramsArr.length == 2) {
            return "".concat(tDomin1, "id=").concat(paramsArr[1], "&mk=").concat(paramsArr[0]);
          }
        }

        return word;
      }); //  http://quote.eastmoney.com/unify/r/133.USDCNH
      //  转换👇
      //  https://emwap.eastmoney.com/quota/hq/stock?id=USDCNH&mk=133

      console.log(body);
      return body;
    }
  }, {
    key: "format",
    value: function format(article) {
      var articleData = article.data;
      console.log(JSON.stringify(article.type));
      var news = base_JSTool.fetchJson(articleData, 'news');
      console.log('ssss' + articleData);
      return {
        Id: article.Id,
        type: article.type,
        body: this.convertBody(news),
        htmlBody: article.htmlData,
        rawData: articleData,
        //接口原始数据
        title: base_JSTool.fetchString(news, 'title'),
        summary: base_JSTool.fetchString(news, 'simdigest'),
        showTime: base_JSTool.fetchString(news, 'showtime'),
        source: base_JSTool.fetchString(news, 'source'),
        shareUrl: base_JSTool.fetchString(articleData, 'shareUrl'),
        newsType: 1,
        user: {
          userId: '',
          userName: ''
        },
        repostState: 0
      };
    }
  }]);

  return NewsFormatNewsinfo;
}();

/* harmony default export */ var news_format_newsinfo = (new news_format_newsinfo_NewsFormatNewsinfo());
// EXTERNAL MODULE: ./node_modules/core-js/modules/es.string.starts-with.js
var es_string_starts_with = __webpack_require__("2ca0");

// CONCATENATED MODULE: ./src/base/news-format-caifuhaoapi.js




 // 处理该域名下的数据  财富号
// http://caifuhaoapi-zptest.eastmoney.com/api/v1/fund/Article/GetArticleByCode?artcode=20200109170930113913270&pagesize=10&pageindex=1&client_source=fund_app&client_os=com.eastmoney.app.dfcf_8.1.1&client_drive=ememem&callback=mycallback

var news_format_caifuhaoapi_NewsFormatCaifuhaoapi = /*#__PURE__*/function () {
  function NewsFormatCaifuhaoapi() {
    Object(classCallCheck["a" /* default */])(this, NewsFormatCaifuhaoapi);
  }

  Object(createClass["a" /* default */])(NewsFormatCaifuhaoapi, [{
    key: "convertBody",
    value: function convertBody(news) {
      return base_JSTool.fetchString(news, 'Content');
    }
  }, {
    key: "getCfhType",
    value: function getCfhType(OrganizationType) {
      if (OrganizationType.startsWith("001")) {
        //001 开头为个人财富号
        return 1;
      } else {
        //机构
        return 2;
      }
    }
  }, {
    key: "getVType",
    value: function getVType(BigVip, accreditationType) {
      if (BigVip == 1) {
        //加v
        if (accreditationType == "002") {
          //002 为个人
          return 2;
        } else {
          //机构
          return 1;
        }
      } else {
        return 0;
      }
    }
  }, {
    key: "format",
    value: function format(article) {
      var news = article.data;
      var author = base_JSTool.fetchJson(news, 'authorInfo');
      var OrganizationType = base_JSTool.fetchString(author, 'OrganizationType');
      var BigVip = base_JSTool.fetchNumber(author, 'BigVip');
      var accreditationType = base_JSTool.fetchNumber(author, 'accreditationType');
      var vType = this.getVType(BigVip, accreditationType);
      var cfhtype = this.getCfhType(OrganizationType);
      return {
        Id: article.Id,
        type: article.type,
        body: this.convertBody(news),
        htmlBody: article.htmlData,
        rawData: news,
        //接口原始数据
        title: base_JSTool.fetchString(news, 'Title'),
        summary: base_JSTool.fetchString(news, 'DigestAuto'),
        showTime: base_JSTool.fetchString(news, 'Showtime'),
        source: '❌接口没有该字段',
        user: {
          userId: base_JSTool.fetchString(author, 'RelatedUid'),
          userName: base_JSTool.fetchString(author, 'NickName'),
          vType: vType,
          introduce: base_JSTool.fetchString(author, 'Summary'),
          mgrId: base_JSTool.fetchString(author, 'mgrId'),
          //❌接口没有该字段
          cfhId: base_JSTool.fetchString(author, 'Account_Id'),
          cfhtype: cfhtype
        },
        repostState: 0
      };
    }
  }]);

  return NewsFormatCaifuhaoapi;
}();

/* harmony default export */ var news_format_caifuhaoapi = (new news_format_caifuhaoapi_NewsFormatCaifuhaoapi());
// CONCATENATED MODULE: ./src/base/NewsUtil.js



















var NewsUtil_NewsUtil = /*#__PURE__*/function () {
  function NewsUtil() {
    Object(classCallCheck["a" /* default */])(this, NewsUtil);
  }

  Object(createClass["a" /* default */])(NewsUtil, [{
    key: "newApiEnable",
    value: function newApiEnable() {
      return NewsUtil.NewsUtilNewApiEnable;
    } //个位数补零

  }, {
    key: "prefixZero",
    value: function prefixZero(num) {
      var newNum = 0;

      if (base_JSTool.isNumber(num)) {
        newNum = num;
      } else if (base_JSTool.isString(num)) {
        newNum = parseInt(num);
      } else {
        return num;
      }

      if (newNum >= 10 || newNum <= -10) {
        return "".concat(newNum);
      }

      return "".concat(newNum >= 0 ? '' : '-', "0").concat(newNum);
    } //时间处理
    // 2019-12-23 10:14:00

  }, {
    key: "dateFromString",
    value: function dateFromString(timeStr) {
      if (!base_JSTool.isString(timeStr) || !timeStr) return null;
      var newTimeStr = timeStr;

      if (newTimeStr.indexOf('T') != -1) {
        newTimeStr = newTimeStr.replace(new RegExp("T", "g"), " ");
      }

      if (newTimeStr.length > 19) {
        newTimeStr = newTimeStr.substring(0, 19);
      }

      var timeArr = newTimeStr.split(" ");
      var d = timeArr[0].split("-");
      var t = timeArr[1].split(":");
      var date = new Date(d[0], d[1] - 1, d[2], t[0], t[1], t[2]);
      return date; //     var year = date.getFullYear();//年
      // 　　var month = date.getMonth();//月
      // 　　var day = date.getDate();//日
      // 　　var hours = date.getHours();//时
      // 　　var min = date.getMinutes();//分
      // 　　var second = date.getSeconds();//秒
    }
  }, {
    key: "dateFormat",
    value: function dateFormat(str) {
      try {
        var date = new Date(str);
        var month = this.prefixZero(date.getMonth() + 1);
        var day = this.prefixZero(date.getDate());
        var hour = this.prefixZero(date.getHours());
        var min = this.prefixZero(date.getMinutes());
        return month + '-' + day + ' ' + hour + ':' + min;
      } catch (e) {
        return '--';
      }
    }
  }, {
    key: "formatTimeString",
    value: function formatTimeString(timeString) {
      var _this = this;

      var date = this.dateFromString(timeString);
      if (!date) return '';
      var resTime = ''; //当前日期

      var cDate = new Date();
      var cYear = cDate.getFullYear();
      var cMonth = cDate.getMonth() + 1;
      var cDay = cDate.getDate(); //当天开始日期

      var cStartDate = new Date(cYear, cMonth - 1, cDay, '0', '0', '0'); //毫秒差

      var num = cDate.getTime() - date.getTime(); //将来的时间

      if (num <= 0) {
        return '刚刚';
      }

      var year = date.getFullYear(); //年

      var month = date.getMonth() + 1; //月

      var day = date.getDate(); //日

      var hours = date.getHours(); //时

      var min = date.getMinutes(); //分

      var Zero = function Zero(num) {
        return _this.prefixZero(num);
      }; //当年


      if (year == cYear) {
        //当月
        if (month == cMonth) {
          //当天
          if (day == cDay) {
            if (num < 1000 * 60) {
              //0~60秒
              resTime = (num / 1000).toFixed(0).toString() + "秒前";
            } else if (num < 1000 * 60 * 60) {
              //0~60分钟
              var _min = num / (1000 * 60);

              resTime = _min.toFixed(0).toString() + "分钟前";
            } else if (num <= 1000 * 60 * 60 * 24) {
              //0~24小时
              var hour = num / (1000 * 60 * 60);
              resTime = hour.toFixed(0).toString() + "小时前";
            }
          } else {
            //距离当天开始时间的时间差
            var startNum = cStartDate.getTime() - date.getTime();

            if (num <= 1000 * 60 * 60 * 24) {
              //0~24小时  昨天
              resTime = "\u6628\u5929 ".concat(Zero(hours), ":").concat(Zero(min));
            } else if (num <= 1000 * 60 * 60 * 48) {
              //24~48小时  前天
              resTime = "\u524D\u5929 ".concat(Zero(hours), ":").concat(Zero(min));
            } else {
              resTime = "".concat(Zero(month), "-").concat(Zero(day), " ").concat(Zero(hours), ":").concat(Zero(min));
            }
          }
        } else {
          resTime = "".concat(Zero(month), "-").concat(Zero(day), " ").concat(Zero(hours), ":").concat(Zero(min));
        }
      } else {
        resTime = "".concat(year, "-").concat(Zero(month), "-").concat(Zero(day), " ").concat(Zero(hours), ":").concat(Zero(min));
      }

      return resTime;
    }
  }, {
    key: "formatArticle",
    value: function formatArticle(article) {
      var type = article.type;
      console.log('ddddd' + type);
      var isNewApi = NewsUtil.NewsUtilNewApiEnable;

      try {
        if (type == base_NewsType.News) {
          return isNewApi ? news_format_newsinfo.format(article) : news_format_dataapi.formatNews(article);
        } else if (type == base_NewsType.Wealth) {
          return isNewApi ? news_format_caifuhaoapi.format(article) : news_format_dataapi.formatWealth(article);
        } else if (type == base_NewsType.Answer || type == base_NewsType.Post) {
          return news_format_gbapi.format(article);
        }

        return {};
      } catch (error) {
        console.log(error);
      }
    }
  }, {
    key: "debounce",
    value: function debounce(fn) {
      var wait = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : 200;
      //防止抖动
      // 通过闭包缓存一个定时器 id
      var timer = null; // 将 debounce 处理结果当作函数返回
      // 触发事件回调时执行这个返回函数

      return function () {
        var _this2 = this;

        for (var _len = arguments.length, args = new Array(_len), _key = 0; _key < _len; _key++) {
          args[_key] = arguments[_key];
        }

        // 如果已经设定过定时器就清空上一次的定时器
        if (timer) clearTimeout(timer); // 开始设定一个新的定时器，定时器结束后执行传入的函数 fn

        timer = setTimeout(function () {
          fn.apply(_this2, args);
        }, wait);
      };
    }
  }]);

  return NewsUtil;
}();

Object(defineProperty["a" /* default */])(NewsUtil_NewsUtil, "NewsUtilNewApiEnable", true);

/* harmony default export */ var base_NewsUtil = (new NewsUtil_NewsUtil());
// EXTERNAL MODULE: ./node_modules/core-js/modules/es.array.map.js
var es_array_map = __webpack_require__("d81d");

// CONCATENATED MODULE: ./src/base/LinkMap.js




var LinkMap_LinkMap = function LinkMap() {
  Object(classCallCheck["a" /* default */])(this, LinkMap);
};

Object(defineProperty["a" /* default */])(LinkMap_LinkMap, "map", {
  link: 'emfundapp:ttjj-linkto',
  postLink: 'emfundapp:postlink',
  previewImage: 'emfundapp:newsimagepreview',
  lookImage: 'emfundapp:chakantupian',
  //正文点击图片预览事件【原来走短链 为了图片浏览定位动画体验 改用click事件】
  previewImageClick: 'fundPreviewImageHandler',
  newsDeatil: 'fund://page/newsdetail',
  fbArticleDetail: 'fund://page/fbarticledetail',
  barQuestionDetail: 'fund://page/barquestiondetail',
  personHome: 'fund://page/personalhome',
  fundDetail: 'fund://page/funddetail'
});

/* harmony default export */ var base_LinkMap = (LinkMap_LinkMap.map);
// EXTERNAL MODULE: ./node_modules/smoothscroll-polyfill/dist/smoothscroll.js
var smoothscroll = __webpack_require__("7707");
var smoothscroll_default = /*#__PURE__*/__webpack_require__.n(smoothscroll);

// CONCATENATED MODULE: ./src/base/HtmlWindow.js












 // kick off the polyfill!

smoothscroll_default.a.polyfill();
/**
 clientTop: 容器内部相对于容器本身的top偏移，== border-top-width
 clientWidth: 容器的窗口宽度【padding-left + width + padding-right】

 scrollTop、scrollLeft: 滚动容器 滚动的偏移量[真实内容超出padding外层的部分]
 scrollWidth：滚动容器【padding-left + 滚动内容width + padding-right】

 offsetTop: 该元素的boder外层 到 父元素的boder内层
 offsetWidth: 【border-left-width + padding-left + width + padding-right + border-right-width】
 */
// 为html注入全局方法

var HtmlWindow_HtmlWindow = /*#__PURE__*/function () {
  function HtmlWindow() {
    Object(classCallCheck["a" /* default */])(this, HtmlWindow);
  }

  Object(createClass["a" /* default */])(HtmlWindow, [{
    key: "configWindowEvent",
    value: function configWindowEvent() {
      //监听滚动事件
      window.onscroll = function (e) {
        var scrollEvents = HtmlWindow.scrollEvents;

        try {
          scrollEvents.forEach(function (el) {
            if (el) el(e);
          });
        } catch (error) {
          console.log('postScrollEvents-error');
          console.log(error);
        }
      };
    }
  }, {
    key: "registerScrollEvent",
    value: function registerScrollEvent(func) {
      if (!base_JSTool.isFunction(func)) {
        return false;
      }

      HtmlWindow.scrollEvents.push(func);
    }
  }, {
    key: "getElementById",
    value: function getElementById(Id) {
      if (!base_JSTool.isString(Id) || !Id) return null;
      return window.document.getElementById(Id);
    }
  }, {
    key: "queryHeader",
    value: function queryHeader() {
      return this.querySelector('head');
    }
  }, {
    key: "querySelector",
    value: function querySelector(Id) {
      if (!base_JSTool.isString(Id) || !Id) return null;
      return window.document.querySelector(Id);
    }
  }, {
    key: "appendBodyChild",
    value: function appendBodyChild(dom) {
      window.document.body.appendChild(dom);
    }
  }, {
    key: "createFragment",
    value: function createFragment() {
      return window.document.createDocumentFragment();
    }
  }, {
    key: "localStorage",
    value: function localStorage() {
      return window.localStorage;
    }
  }, {
    key: "addListener",
    value: function addListener(event, func) {
      window.addEventListener(event, func);
    } //获取style

  }, {
    key: "getStyle",
    value: function getStyle(dom) {
      return window.getComputedStyle(dom, null);
    }
  }, {
    key: "getPropertyValue",
    value: function getPropertyValue(dom, key) {
      return this.getStyle(dom).getPropertyValue(key);
    } //元素大小相关

  }, {
    key: "pageYOffset",
    value: function pageYOffset() {
      return window.pageYOffset;
    } //元素相对body的原点的位置

  }, {
    key: "pointInBody",
    value: function pointInBody(dom) {
      var l = 0,
          t = 0;

      while (dom) {
        l = l + dom.offsetLeft + dom.clientLeft;
        t = t + dom.offsetTop + dom.clientTop;
        dom = dom.offsetParent;
      }

      return {
        left: l,
        top: t
      };
    } //元素相对当前窗口的位置

  }, {
    key: "clientRect",
    value: function clientRect(dom) {
      // top 包含 margin 不包含 border padding
      // left 包含 margin 不包含 border padding
      // width 不包含 margin 包含 border padding
      // height 不包含 margin 包含 border padding
      return dom.getBoundingClientRect();
    }
  }, {
    key: "clientRealRect",
    value: function clientRealRect(dom) {
      var _this = this;

      var removePx = function removePx(num) {
        var res = num.toString();

        if (res.indexOf('px') != -1) {
          res = res.replace(/px/g, '');
        }

        return parseFloat(res);
      };

      var styleValue = function styleValue(key) {
        return removePx(_this.getPropertyValue(dom, key));
      };

      var domRect = this.clientRect(dom);
      return {
        top: domRect.top + styleValue('border-top-width') + styleValue('padding-top'),
        bottom: domRect.bottom + styleValue('border-bottom-width') + styleValue('padding-bottom'),
        left: domRect.left + styleValue('border-left-width') + styleValue('padding-left'),
        right: domRect.right - styleValue('border-right-width') + styleValue('padding-right'),
        width: domRect.width - styleValue('border-left-width') - styleValue('border-right-width') - styleValue('padding-left') - styleValue('padding-right'),
        height: domRect.height - styleValue('border-top-width') - styleValue('border-bottom-width') - styleValue('padding-top') - styleValue('padding-bottom')
      };
    } //window body 的宽高

  }, {
    key: "client",
    value: function client() {
      // ie9 +  最新浏览器
      if (window.innerWidth != null) {
        return {
          width: window.innerWidth,
          height: window.innerHeight
        };
      } // 标准浏览器
      else if (document.compatMode === "CSS1Compat") {
          return {
            width: document.documentElement.clientWidth,
            height: document.documentElement.clientHeight
          };
        } // 怪异模式


      return {
        width: document.body.clientWidth,
        height: document.body.clientHeight
      };
    } //滚动相关

  }, {
    key: "scrollToOffsetY",
    value: function scrollToOffsetY(y) {
      var animate = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : false;
      window.scroll({
        top: y,
        behavior: animate ? 'smooth' : 'auto'
      }); // window.document.body.scrollTop = y;
    } // https://blog.csdn.net/qq_35366269/article/details/97236793
    //滚动元素到顶部

  }, {
    key: "scrollDomToTopById",
    value: function scrollDomToTopById(domId) {
      var animate = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : true;
      this.scrollDomById(domId, 'start', 'nearest', animate);
    } //滚动元素到底部

  }, {
    key: "scrollDomToBottomById",
    value: function scrollDomToBottomById(domId) {
      var animate = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : true;
      this.scrollDomById(domId, 'end', 'nearest', animate);
    }
  }, {
    key: "scrollDomById",
    value: function scrollDomById(domId) {
      var verticalAlign = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : "start";
      var horizontalAlign = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : "nearest";
      var animate = arguments.length > 3 && arguments[3] !== undefined ? arguments[3] : true;
      if (!base_JSTool.isString(domId) || !domId) return;
      var dom = this.getElementById(domId);
      if (!dom) return; // verticalAlign : "start", "center", "end", "nearest"[默认值]
      // horizontalAlign : "start", "center", "end", "nearest"[默认值]

      dom.scrollIntoView({
        block: verticalAlign,
        behavior: animate ? "smooth" : "auto",
        //"instant"
        inline: horizontalAlign
      });
    }
  }]);

  return HtmlWindow;
}();

Object(defineProperty["a" /* default */])(HtmlWindow_HtmlWindow, "scrollEvents", []);

/* harmony default export */ var base_HtmlWindow = (new HtmlWindow_HtmlWindow());
// CONCATENATED MODULE: ./src/base/HtmlStorage.js








var HtmlStorage_HtmlStorage = /*#__PURE__*/function () {
  function HtmlStorage() {
    Object(classCallCheck["a" /* default */])(this, HtmlStorage);
  }

  Object(createClass["a" /* default */])(HtmlStorage, [{
    key: "offSetYKey",
    value: function offSetYKey(Id) {
      if (!base_JSTool.isString(Id) || !Id) {
        return null;
      }

      return "".concat(HtmlStorage.KeyMap.scrollOffSetY, "-").concat(Id);
    }
  }, {
    key: "setScrollOffSetYStorage",
    value: function setScrollOffSetYStorage(Id) {
      var offY = base_HtmlWindow.pageYOffset();
      this.setLocalStorage(this.offSetYKey(Id), offY);
    }
  }, {
    key: "getScrollOffSetYStorage",
    value: function getScrollOffSetYStorage(Id) {
      var res = this.getLocalStorage(this.offSetYKey(Id));
      return base_JSTool.isNumber(res) ? res : 0;
    }
  }, {
    key: "setLocalStorage",
    value: function setLocalStorage(key, value) {
      var timeOut = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : 0;

      if (!base_JSTool.isString(key) || !key || !value) {
        return;
      } //当前时间


      var curTime = new Date().getTime();
      var newTimeOut = timeOut; //默认时效一天

      if (newTimeOut == 0) {
        newTimeOut = 24 * 60 * 60 * 1000;
      } //截止日期


      var limitTime = curTime + newTimeOut;
      var newValue = {
        data: value,
        timeOut: limitTime
      }; //存储

      base_HtmlWindow.localStorage().setItem(key, JSON.stringify(newValue));
    }
  }, {
    key: "getLocalStorage",
    value: function getLocalStorage(key) {
      if (!base_JSTool.isString(key) || !key) {
        return null;
      }

      var fetchData = base_HtmlWindow.localStorage().getItem(key);

      if (!base_JSTool.isString(fetchData)) {
        return null;
      }

      var value = JSON.parse(fetchData);
      var timeOut = value.timeOut; //数据超时 无效

      if (timeOut < new Date().getTime()) {
        return null;
      }

      return value.data;
    }
  }]);

  return HtmlStorage;
}();

Object(defineProperty["a" /* default */])(HtmlStorage_HtmlStorage, "KeyMap", function () {
  var map = {
    scrollOffSetY: 'scrollOffSetY'
  };
  var appIdentifier = 'com.eastmoney.ttjj-newsweb-';
  var res = {};

  for (var key in map) {
    if (map.hasOwnProperty(key)) {
      var el = map[key];
      res[key] = "".concat(appIdentifier).concat(el);
    }
  }

  return res;
}());

/* harmony default export */ var base_HtmlStorage = (new HtmlStorage_HtmlStorage());
// CONCATENATED MODULE: ./src/base/CommonData.js



var CommonData_CommonData = function CommonData() {
  Object(classCallCheck["a" /* default */])(this, CommonData);
};

Object(defineProperty["a" /* default */])(CommonData_CommonData, "data", {
  articleLimitHeight: 800,
  isShowAllArticle: false,
  newsId: ''
});

/* harmony default export */ var base_CommonData = (CommonData_CommonData.data);
// CONCATENATED MODULE: ./src/base/Emotion.js









var Emotion_Emotion = /*#__PURE__*/function () {
  function Emotion() {
    Object(classCallCheck["a" /* default */])(this, Emotion);
  } // 表情资源
  // const emojiResource = fund.getEmotionResourceSync();
  // const bigEmotionResource = fund.getBigEmotionResourceSync();


  Object(createClass["a" /* default */])(Emotion, [{
    key: "getEmotionText",
    value: function getEmotionText(emojiResource, bigEmojiResource, text) {
      var size = arguments.length > 3 && arguments[3] !== undefined ? arguments[3] : 18;
      var emojiText = text ? text : ""; // emojiText = emojiText +  "啊[微笑]as按法律[为什么]法律我法律我[拜神]放到了[大笑]safsf啊都是V型d[鼓掌]你";
      //匹配表情

      var reg = new RegExp("\\[[\u4E00-\u9FA5_a-zA-Z]*\\]", "g");
      emojiText = emojiText.replace(reg, function (word) {
        // const key = word.substring(1, word.length - 1);
        var key = word;
        var imgSource = base_JSTool.fetchString(emojiResource, key);

        if (!imgSource) {
          imgSource = base_JSTool.fetchString(bigEmojiResource, key);
        }

        if (imgSource) {
          // console.log("匹配表情");
          // console.log(key); //微笑
          // console.log(imgSource); //EFEmoji.bundle/images/common_ef_emot01.png
          // return `<span style="width: 18px;height: 18px;background: url('${imgSource}') no-repeat 0 0;background-size: 18px 18px;">&emsp;</span>`
          return "<img src=\"".concat(imgSource, "\" style=\"display:inline-block;width:").concat(parseFloat(size), "px;height:").concat(parseFloat(size), "px;margin: 0;background: #ffffff00;\" alt />");
        }

        return word;
      });
      return emojiText;
    }
  }]);

  return Emotion;
}();

/* harmony default export */ var base_Emotion = (new Emotion_Emotion());
// EXTERNAL MODULE: ./node_modules/core-js/modules/es.string.ends-with.js
var es_string_ends_with = __webpack_require__("8a79");

// CONCATENATED MODULE: ./src/base/url.js



var UrlConfig = {
  // 数组配置：[正式、公测、内侧]
  urlInfo: {
    marketServer: ['https://fundmobapi.eastmoney.com', //正式
    'https://fundmobapitest11.eastmoney.com', //公测
    'https://fundmobapitest222.eastmoney.com' //内侧
    ],
    newsServer: ['https://appnews.1234567.com.cn/api/AppService/', 'https://appnewstest.1234567.com.cn/api/AppService/', 'https://appnewstest.1234567.com.cn/api/AppService/'],
    gubaNewsServer: ['https://fundmobapitest2.eastmoney.com/'],
    fundBarDataServer: ['https://dataapi.1234567.com.cn/', //正式
    "https://dataapi.1234567.com.cn/", //公测
    "https://dataapineice.1234567.com.cn/" //内侧
    ],
    fundBarServer: ["https://jijinbaapi.eastmoney.com/", "https://fundmobapitest.eastmoney.com/", "https://fundmobapitest.eastmoney.com/"],
    avatorServer: ['http://avator.eastmoney.com/qface/'],
    gbaServer: ['https://gbapi.eastmoney.com/', 'https://gbapi-test.eastmoney.com/', 'https://gbapi-test.eastmoney.com/'],
    cfhServer: ["https://fundcfhapi.1234567.com.cn/", //正式
    "https://fundmobapitest.eastmoney.com/", //公测
    "https://fundmobapitest.eastmoney.com/cfhneice/" //内侧
    ],
    articleCommentListServer: ["http://gbapi-test.eastmoney.com/", //评论列表
    "http://gbapi-test.eastmoney.com/", //评论列表
    "http://gbapi-test.eastmoney.com/" //评论列表
    ],
    fundPersonalConfig: ["https://appactive.1234567.com.cn/", //个性化配置接口
    "https://appactivetest.1234567.com.cn/", "https://appactiveneice.1234567.com.cn/"]
  },
  // 正式: publish  公测: publicTest   内测: internalTest
  envArr: ['publish', 'publicTest', 'internalTest'],
  //当前环境 正式: 0  公测: 1   内测: 2
  urlMap: {}
};

function urlInit() {
  var envArr = UrlConfig.envArr;
  var currentEnv = base_JSTool.fetchNumber(fund.getSystemInfoSync(), 'appEnvironment');

  var serverList = function () {
    var infoArr = [];
    var urlInfo = UrlConfig.urlInfo;

    var _loop = function _loop(key) {
      if (urlInfo.hasOwnProperty(key)) {
        var urls = urlInfo[key];
        urls.forEach(function (url, index) {
          if (index >= infoArr.length) {
            infoArr.push({});
          }

          infoArr[index][key] = url;
        });
      }
    };

    for (var key in urlInfo) {
      _loop(key);
    }

    var res = {};
    envArr.forEach(function (key, index) {
      res[key] = index >= infoArr.length ? {} : infoArr[index];
    });
    console.log(res);
    return res;
  }();

  Object.assign(UrlConfig.urlMap, serverList[envArr[currentEnv]]);
}

/* harmony default export */ var base_url = (UrlConfig.urlMap);

// EXTERNAL MODULE: ./node_modules/core-js/modules/es.array.join.js
var es_array_join = __webpack_require__("a15b");

// CONCATENATED MODULE: ./src/base/mFetch.js






 //公共参数

function mCommonParams() {
  var Info = fund.getUserInfoSync();
  var userInfo = Info.userInfo;
  return {
    deviceid: userInfo.deviceid,
    plat: userInfo.plat,
    serverversion: userInfo.serverversion,
    version: userInfo.appv,
    appVersion: userInfo.appv
  };
} //json参数转换string


function mParamToStr(params) {
  if (Object.prototype.toString.call(params) == '[object Object]') {
    var arr = [];

    for (var key in params) {
      var el = params[key];
      arr.push("".concat(key, "=").concat(el));
    }

    if (arr.length == 0) {
      return '';
    }

    return arr.join('&');
  }

  return params;
} //需要公共参数的请求


function mFetch(url, header, data) {
  var method = arguments.length > 3 && arguments[3] !== undefined ? arguments[3] : 'GET';
  var newData = Object.assign(data, mCommonParams());
  return mFetchInternal(url, header, newData, method, true);
} //不需要公共参数的请求


function mFetchNoExtra(url, header, data) {
  var method = arguments.length > 3 && arguments[3] !== undefined ? arguments[3] : 'GET';
  return mFetchInternal(url, header, data, method);
}

function mFetchInternal(url, header, data) {
  var method = arguments.length > 3 && arguments[3] !== undefined ? arguments[3] : 'GET';
  return new Promise(function (resolve, reject) {
    fund.request({
      url: url,
      //仅为示例，并非真实接口地址。
      method: method,
      header: header,
      data: data,
      success: function success(res) {
        resolve(res);
      },
      fail: function fail() {
        reject();
      }
    });
  });
}

function fetchNews(data) {
  var Info = fund.getUserInfoSync();
  var userInfo = Info.userInfo;

  if (typeof userInfo == "string") {
    userInfo = JSON.parse(userInfo);
  }

  var fundversion = userInfo.appv,
      fundversion = fundversion.replace(/\./g, '');
  var nativeUrl = fund.getUrlConfigSync({
    remoteKey: "EastBarGuba",
    localKey: "EastBarGuba"
  });
  var url = nativeUrl + "reply/api/Reply/FundArticleReplyList";

  if (!data.showAllComment) {
    url = nativeUrl + "reply/api/Reply/ArticleNewAuthorOnly";
  }

  var method = "POST";
  var header = {
    "content-type": "application/x-www-form-urlencoded"
  };
  var common = {
    DeviceId: userInfo.deviceid,
    UserId: userInfo.uid,
    Plat: userInfo.plat,
    key: 'a8eb1746-1375-8def-b5e8-fe369ee73d68',
    uToken: userInfo.passportutokentrue,
    cToken: userInfo.passportctokentrue,
    gToken: userInfo.gtoken,
    OSVersion: userInfo.osv,
    appVersion: userInfo.appv,
    MarketChannel: userInfo.marketchannel,
    passportId: userInfo.passportid,
    MobileKey: userInfo.deviceid,
    product: 'Fund',
    version: fundversion
  };
  var newData = data;

  for (var key in common) {
    var el = common[key];
    newData[key] = el;
  }

  return new Promise(function (resolve, reject) {
    fund.request({
      url: url,
      //仅为示例，并非真实接口地址。
      method: method,
      header: header,
      data: newData,
      success: function success(res) {
        resolve(res);
      },
      fail: function fail() {
        reject();
      }
    });
  });
}

function likeComment(data) {
  var Info = fund.getUserInfoSync();
  var userInfo = Info.userInfo;

  if (typeof userInfo == "string") {
    userInfo = JSON.parse(userInfo);
  }

  var likeStatus = data.likeStatus;
  var nativeUrl = fund.getUrlConfigSync({
    remoteKey: "FundBarApiPro",
    localKey: "FundBarApiPro"
  });
  var url = nativeUrl + "community/action/LikeArticleReply";

  if (likeStatus) {
    //取消点赞
    url = nativeUrl + "community/action/cancellikearticlereply";
  }

  var method = "POST";
  var header = {
    "content-type": "application/x-www-form-urlencoded"
  };
  var common = {
    deviceid: userInfo.deviceid,
    userid: userInfo.uid,
    plat: userInfo.plat,
    key: 'a8eb1746-1375-8def-b5e8-fe369ee73d68',
    utoken: userInfo.utoken,
    ctoken: userInfo.ctoken,
    gtoken: userInfo.gtoken,
    osversion: userInfo.osv,
    appversion: userInfo.appv,
    marketchannel: userInfo.marketchannel,
    passportid: userInfo.passportid,
    mobileKey: userInfo.deviceid,
    product: 'EFund',
    version: userInfo.appv
  };
  var newData = data;

  for (var key in common) {
    var el = common[key];
    newData[key] = el;
  }

  return new Promise(function (resolve, reject) {
    fund.request({
      url: url,
      //仅为示例，并非真实接口地址。
      method: method,
      header: header,
      data: newData,
      success: function success(res) {
        resolve(res);
      },
      fail: function fail() {
        reject();
      }
    });
  });
}

function deleteCommentRequest(data, postUserId) {
  var Info = fund.getUserInfoSync();
  var userInfo = Info.userInfo;

  if (typeof userInfo == "string") {
    userInfo = JSON.parse(userInfo);
  }

  var fundversion = userInfo.appv,
      fundversion = fundversion.replace(/\./g, '');
  var nativeUrl = fund.getUrlConfigSync({
    remoteKey: "EastBarGuba",
    localKey: "EastBarGuba"
  }); //非帖子作者删除自己的评论

  var url = nativeUrl + "replyopt/api/Reply/DeleteUserReply";

  if (postUserId == userInfo.passportid) {
    //帖子作者删除自己帖子下面的评论
    url = nativeUrl + "replyopt/api/Reply/DeletePostReply";
  }

  console.log('测试删除' + url);
  var method = "POST";
  var header = {
    "content-type": "application/x-www-form-urlencoded"
  };
  var common = {
    DeviceId: userInfo.deviceid,
    UserId: userInfo.uid,
    Plat: userInfo.plat,
    key: 'a8eb1746-1375-8def-b5e8-fe369ee73d68',
    uToken: userInfo.passportutokentrue,
    cToken: userInfo.passportctokentrue,
    gToken: userInfo.gtoken,
    OSVersion: userInfo.osv,
    appVersion: userInfo.appv,
    MarketChannel: userInfo.marketchannel,
    passportId: userInfo.passportid,
    MobileKey: userInfo.deviceid,
    product: 'Fund',
    version: fundversion
  };
  var newData = data;

  for (var key in common) {
    var el = common[key];
    newData[key] = el;
  }

  return new Promise(function (resolve, reject) {
    fund.request({
      url: url,
      method: method,
      header: header,
      data: newData,
      success: function success(res) {
        resolve(res);
      },
      fail: function fail() {
        reject();
      }
    });
  });
}

function commentDetailRequest(data) {
  var Info = fund.getUserInfoSync();
  var userInfo = Info.userInfo;

  if (typeof userInfo == "string") {
    userInfo = JSON.parse(userInfo);
  }

  var nativeUrl = fund.getUrlConfigSync({
    remoteKey: "EastBarGuba",
    localKey: "EastBarGuba"
  });
  var fundversion = userInfo.appv,
      fundversion = fundversion.replace(/\./g, '');
  var url = nativeUrl + "reply/api/Reply/ArticleReplyDetail";
  var method = "POST";
  var header = {
    "content-type": "application/x-www-form-urlencoded"
  };
  var common = {
    DeviceId: userInfo.deviceid,
    UserId: userInfo.uid,
    Plat: userInfo.plat,
    key: 'a8eb1746-1375-8def-b5e8-fe369ee73d68',
    uToken: userInfo.passportutokentrue,
    cToken: userInfo.passportctokentrue,
    gToken: userInfo.gtoken,
    OSVersion: userInfo.osv,
    appVersion: userInfo.appv,
    MarketChannel: userInfo.marketchannel,
    passportId: userInfo.passportid,
    MobileKey: userInfo.deviceid,
    product: 'Fund',
    version: fundversion
  };
  var newData = data;

  for (var key in common) {
    var el = common[key];
    newData[key] = el;
  }

  return new Promise(function (resolve, reject) {
    fund.request({
      url: url,
      //仅为示例，并非真实接口地址。
      method: method,
      header: header,
      data: newData,
      success: function success(res) {
        resolve(res);
      },
      fail: function fail() {
        reject();
      }
    });
  });
}

function commentKeyWord(data) {
  //评论列表关键词
  var Info = fund.getUserInfoSync();
  var userInfo = Info.userInfo;

  if (typeof userInfo == "string") {
    userInfo = JSON.parse(userInfo);
  }

  var nativeUrl = fund.getUrlConfigSync({
    remoteKey: "FundBarApiPro",
    localKey: "FundBarApiPro"
  });
  var url = nativeUrl + "community/show/batchKeyWords";
  var method = "POST";
  var header = {
    "content-type": "application/x-www-form-urlencoded"
  };
  var common = {
    deviceid: userInfo.deviceid,
    userid: userInfo.uid,
    plat: userInfo.plat,
    key: 'a8eb1746-1375-8def-b5e8-fe369ee73d68',
    utoken: userInfo.utoken,
    ctoken: userInfo.ctoken,
    gtoken: userInfo.gtoken,
    osversion: userInfo.osv,
    appversion: userInfo.appv,
    marketchannel: userInfo.marketchannel,
    passportid: userInfo.passportid,
    mobileKey: userInfo.deviceid,
    product: 'EFund',
    version: userInfo.appv
  };
  var newData = data;

  for (var key in common) {
    var el = common[key];
    newData[key] = el;
  }

  return new Promise(function (resolve, reject) {
    fund.request({
      url: url,
      //仅为示例，并非真实接口地址。
      method: method,
      header: header,
      data: newData,
      success: function success(res) {
        resolve(res);
      },
      fail: function fail() {
        reject();
      }
    });
  });
}


// CONCATENATED MODULE: ./src/base/news-request.js







function requestLikeArticle(isLike, params) {
  var Info = fund.getUserInfoSync();
  var userInfo = Info.userInfo;
  var url = "".concat(base_url.fundBarDataServer).concat(isLike ? "community/action/likeArticle" : "community/action/cancelLikeArticle");
  var newParams = Object.assign({
    product: "EFund",
    passportid: userInfo.passportid,
    userid: userInfo.uid,
    ctoken: userInfo.passportctoken,
    utoken: userInfo.utoken,
    gToken: userInfo.gtoken
  }, mCommonParams(), params);
  return new Promise(function (resolve, reject) {
    mFetchNoExtra(url, {}, newParams, "POST").then(function (res) {
      resolve(res);
    }).catch(function (err) {
      reject(err);
    });
  });
}

function requestKeyWords(params) {
  return new Promise(function (resolve, reject) {
    //获取用户信息
    var Info = fund.getUserInfoSync();
    var userInfo = Info.userInfo;
    var domin = fund.getUrlConfigSync({
      remoteKey: 'FundBarApiPro',
      localKey: 'FundBarApiPro'
    });
    domin = domin.endsWith('/') ? domin : "".concat(domin, "/"); //获取互动信息
    // https://dataapi.1234567.com.cn/community/show/batchKeyWords?userid=123&product=EFund&deviceid=123&plat=Iphone&ids=20200312101202052515100_300&ctoken=123&utoken=123&version=6.2.0

    var url = "".concat(domin, "community/show/batchKeyWords");
    var newParams = Object.assign({
      product: "EFund",
      // passportid: userInfo.passportid,
      userid: userInfo.uid,
      ctoken: userInfo.passportctoken,
      utoken: userInfo.utoken
    }, mCommonParams(), params);
    mFetchNoExtra(url, {}, newParams).then(function (res) {
      resolve(res);
    }).catch(function (err) {
      reject(err);
    });
  });
}

function requestArticleBriefInfo(params) {
  return new Promise(function (resolve, reject) {
    //获取用户信息
    var Info = fund.getUserInfoSync();
    var userInfo = Info.userInfo;
    var domin = fund.getUrlConfigSync({
      remoteKey: 'EastBarGuba',
      localKey: 'EastBarGuba'
    });
    domin = domin.endsWith('/') ? domin : "".concat(domin, "/"); //获取是否可转发
    // http://gbapi.eastmoney.com/abstract/api/PostShort/ArticleBriefInfo?postid=20200313113921366032070&type=1&deviceid=0.3410789631307125&version=100&product=Guba&plat=Web

    var url = "".concat(domin, "abstract/api/PostShort/ArticleBriefInfo");
    var newParams = Object.assign({
      product: "Fund"
    }, mCommonParams(), params);
    mFetchNoExtra(url, {}, newParams).then(function (res) {
      resolve(res);
    }).catch(function (err) {
      reject(err);
    });
  });
}

function requestInteractInfo(type, params) {
  return new Promise(function (resolve, reject) {
    //获取用户信息
    var Info = fund.getUserInfoSync();
    var userInfo = Info.userInfo;
    var domin = fund.getUrlConfigSync({
      remoteKey: 'FundBarApiPro',
      localKey: 'FundBarApiPro'
    });
    domin = domin.endsWith('/') ? domin : "".concat(domin, "/"); //获取互动信息
    // https://dataapi.1234567.com.cn/community/show/articleInteract?serverversion=6.2.0&userid=bad9ef48dfe64776a539a2b6e3c8d311&product=EFund&passportid=2533145336202222&deviceid=7072B970-147D-41C8-8EA4-8C8695B23B6F&plat=Iphone&ctoken=rjn-djf-6f-ejd--dafuh1-jecdaj-jf&utoken=kfjkn1aj8n-8kfdf-andcafrh-r--h68&version=6.2.0&gtoken=E9C0E1C98B0344B0A48B42157F7BA23f&ids=20191113163322831230580_300

    var url = "".concat(domin, "community/show/articleInteract");
    var newParams = Object.assign({
      product: "EFund",
      passportid: userInfo.passportid,
      userid: userInfo.uid,
      ctoken: userInfo.passportctoken,
      utoken: userInfo.utoken
    }, mCommonParams(), params);
    mFetchNoExtra(url, {}, newParams).then(function (res) {
      resolve(res);
    }).catch(function (err) {
      reject(err);
    });
  });
}

function requestArticleLabels(type, params) {
  //获取用户信息
  var Info = fund.getUserInfoSync();
  var userInfo = Info.userInfo;
  var url = "".concat(base_url.fundBarDataServer, "community/show/articleLabels");
  var newParams = Object.assign({
    product: "EFund",
    passportid: userInfo.passportid,
    userid: userInfo.uid,
    ctoken: userInfo.passportctoken,
    utoken: userInfo.utoken,
    type: type
  }, mCommonParams(), params);
  return new Promise(function (resolve, reject) {
    mFetchNoExtra(url, {}, newParams, "POST").then(function (res) {
      resolve(res);
    }).catch(function (err) {
      reject(err);
    });
  });
}

function requestBatchUserInfo(type, params) {
  return new Promise(function (resolve, reject) {
    // https://jijinbaapi.eastmoney.com/FundMCApi/FundMBNew/BatchUserInfos?product=EFund&passportid=2533145336202222&userid=bad9ef48dfe64776a539a2b6e3c8d311&ctoken=6cdh-rffdf-uqdh8er16d8f8ah8qrnfq&utoken=fnjfcaf6jehuan--1h8fr6qae6aquun8&deviceid=FF84EC9B-0268-4143-B6A6-0035BE715C7E&plat=Iphone&serverversion=6.2.5&version=6.2.5&appVersion=6.2.5&rqModel=%5B%7B%22code%22%3A%22cfhpl%22%2C%22pid%22%3A%228216085021619564%22%7D%5D
    if (type == base_NewsType.Post || type == base_NewsType.Answer) {
      //获取用户信息
      var Info = fund.getUserInfoSync();
      var userInfo = Info.userInfo;
      var url = "".concat(base_url.fundBarServer, "FundMCApi/FundMBNew/BatchUserInfos");
      var newParams = Object.assign({
        product: "EFund",
        passportid: userInfo.passportid,
        userid: userInfo.uid,
        ctoken: userInfo.passportctoken,
        utoken: userInfo.utoken
      }, mCommonParams(), params);
      mFetchNoExtra(url, {}, newParams, "GET").then(function (res) {
        resolve(res);
      }).catch(function (err) {
        reject(err);
      });
    } else {
      reject();
    }
  });
}

function requestArticleMoreInfo(type, params) {
  return new Promise(function (resolve, reject) {
    // if (type == NewsType.Post || type == NewsType.Answer) {
    //获取用户信息
    var Info = fund.getUserInfoSync();
    var userInfo = Info.userInfo;
    var domin = fund.getUrlConfigSync({
      remoteKey: 'FundBarApi',
      localKey: 'FundBarApi'
    });
    domin = domin.endsWith('/') ? domin : "".concat(domin, "/");
    var url = "".concat(domin, "FundMCApi/FundMBNew/BatchArticleMoreInfos");
    var newParams = Object.assign({
      product: "EFund",
      passportid: userInfo.passportid,
      userid: userInfo.uid,
      ctoken: userInfo.passportctoken,
      utoken: userInfo.utoken,
      type: type
    }, mCommonParams(), params);
    mFetchNoExtra(url, {}, newParams, "GET").then(function (res) {
      resolve(res);
    }).catch(function (err) {
      reject(err);
    }); // } else {
    //     reject()
    // }
  });
}

function requestShield(params) {
  //获取用户信息
  var Info = fund.getUserInfoSync();
  var userInfo = Info.userInfo;
  var url = "".concat(base_url.fundBarDataServer, "community/action/userShieldAction");
  var newParams = Object.assign({
    product: "EFund",
    passportid: userInfo.passportid,
    userid: userInfo.uid,
    ctoken: userInfo.passportctoken,
    utoken: userInfo.utoken
  }, mCommonParams(), params);
  return new Promise(function (resolve, reject) {
    mFetchNoExtra(url, {}, newParams, "POST").then(function (res) {
      resolve(res);
    }).catch(function (err) {
      reject(err);
    });
  });
}

function requestTopicDetail(params) {
  //获取用户信息
  var Info = fund.getUserInfoSync();
  var userInfo = Info.userInfo;
  var nativeUrl = fund.getUrlConfigSync({
    remoteKey: "EastBarGuba",
    localKey: "EastBarGuba"
  });
  nativeUrl = nativeUrl.substring(nativeUrl.length - 1) == '/' ? nativeUrl : "".concat(nativeUrl, "/");
  var url = "".concat(nativeUrl, "fundfocustopic/api/topic/TopicDetailsRead");
  var newParams = Object.assign({
    product: "Fund",
    //不能使用EFund
    passportid: userInfo.passportid,
    userid: userInfo.uid,
    ctoken: userInfo.passportctoken,
    utoken: userInfo.utoken
  }, mCommonParams(), params);
  return new Promise(function (resolve, reject) {
    mFetchNoExtra(url, {}, newParams, "POST").then(function (res) {
      resolve(res);
    }).catch(function (err) {
      reject(err);
    });
  });
}

function requestSetMpDict(params) {
  return new Promise(function (resolve, reject) {
    //获取互动信息
    var url = "https://mp.1234567.com.cn/wx/api/WxMiniProgram/SetDict";
    mFetchNoExtra(url, {}, params, "POST").then(function (res) {
      resolve(res);
    }).catch(function (err) {
      reject(err);
    });
  });
}


// CONCATENATED MODULE: ./src/base/eventBus.js

var eventBus = new vue_runtime_esm["a" /* default */]();
/* harmony default export */ var base_eventBus = (eventBus); // eventBus.$emit
// eventBus.$on
// CONCATENATED MODULE: ./node_modules/@vue/cli-plugin-babel/node_modules/cache-loader/dist/cjs.js??ref--12-0!./node_modules/@vue/cli-plugin-babel/node_modules/thread-loader/dist/cjs.js!./node_modules/babel-loader/lib!./node_modules/@vue/cli-service/node_modules/cache-loader/dist/cjs.js??ref--0-0!./node_modules/@vue/cli-service/node_modules/vue-loader/lib??vue-loader-options!./src/App.vue?vue&type=script&lang=js&
//
//
//
//
//
//
//
//
//
//
//















function preventDefault(e) {
  e.preventDefault();
}

var vm = {
  name: "app",
  components: {},
  data: function data() {
    return {
      testEmotion: '',
      testBigEmotion: ''
    };
  },
  created: function created() {
    this.configVue();
    this.addWindowFunc();
  },
  computed: {},
  mounted: function mounted() {
    var emotionMap = fund.getEmotionResourceSync();
    var bigEmotionMap = fund.getBigEmotionResourceSync();
    this.testEmotion = base_Emotion.getEmotionText(emotionMap, bigEmotionMap, '[微笑][大笑]');
    this.testBigEmotion = base_Emotion.getEmotionText(emotionMap, bigEmotionMap, '[厉害了]', 100);
  },
  methods: {
    configVue: function configVue() {
      vue_runtime_esm["a" /* default */].config.errorHandler = function (oriFunc) {
        return function (err, vm, info) {
          /**发送至Vue*/
          if (oriFunc) oriFunc.call(null, err, vm, info);
          /**发送至WebView*/

          if (window.onerror) window.onerror.call(null, err);
        };
      }(vue_runtime_esm["a" /* default */].config.errorHandler);
    },
    addWindowFunc: function addWindowFunc() {
      var _this = this;

      //配置事件
      base_HtmlWindow.configWindowEvent(); //接受原生消息

      window.receiveNativeMessage = function (parmas) {
        base_NativeMsg.post(parmas);
      }; //渲染


      window.render = function () {
        _this.prepareRender();
      };
    },
    prepareRender: function prepareRender() {
      var _this2 = this;

      try {
        //检查fund api
        console.log(fund);
        this.render();
      } catch (error) {
        base_HtmlWindow.addListener("fundJSBridgeReady", function () {
          _this2.render();
        });
      }
    }
  }
};
/* harmony default export */ var Appvue_type_script_lang_js_ = (vm);
// CONCATENATED MODULE: ./src/App.vue?vue&type=script&lang=js&
 /* harmony default export */ var src_Appvue_type_script_lang_js_ = (Appvue_type_script_lang_js_); 
// EXTERNAL MODULE: ./src/App.vue?vue&type=style&index=0&id=31e25cbe&lang=scss&scoped=true&
var Appvue_type_style_index_0_id_31e25cbe_lang_scss_scoped_true_ = __webpack_require__("f339");

// EXTERNAL MODULE: ./node_modules/@vue/cli-service/node_modules/vue-loader/lib/runtime/componentNormalizer.js
var componentNormalizer = __webpack_require__("0c7c");

// CONCATENATED MODULE: ./src/App.vue






/* normalize component */

var component = Object(componentNormalizer["a" /* default */])(
  src_Appvue_type_script_lang_js_,
  Appvue_type_template_id_31e25cbe_scoped_true_render,
  staticRenderFns,
  false,
  null,
  "31e25cbe",
  null
  
)

/* harmony default export */ var App = (component.exports);
// EXTERNAL MODULE: ./node_modules/js-md5/src/md5.js
var md5 = __webpack_require__("8237");
var md5_default = /*#__PURE__*/__webpack_require__.n(md5);

// CONCATENATED MODULE: ./src/main.js





 // import store from './store'


vue_runtime_esm["a" /* default */].prototype.$md5 = md5_default.a;
vue_runtime_esm["a" /* default */].config.productionTip = false;
new vue_runtime_esm["a" /* default */]({
  render: function render(h) {
    return h(App);
  }
}).$mount('#app');

/***/ }),

/***/ "f339":
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
/* harmony import */ var _node_modules_vue_cli_service_node_modules_mini_css_extract_plugin_dist_loader_js_ref_8_oneOf_1_0_node_modules_vue_cli_service_node_modules_css_loader_dist_cjs_js_ref_8_oneOf_1_1_node_modules_vue_cli_service_node_modules_vue_loader_lib_loaders_stylePostLoader_js_node_modules_postcss_loader_src_index_js_ref_8_oneOf_1_2_node_modules_sass_loader_dist_cjs_js_ref_8_oneOf_1_3_node_modules_vue_cli_service_node_modules_cache_loader_dist_cjs_js_ref_0_0_node_modules_vue_cli_service_node_modules_vue_loader_lib_index_js_vue_loader_options_App_vue_vue_type_style_index_0_id_31e25cbe_lang_scss_scoped_true___WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__("33b4");
/* harmony import */ var _node_modules_vue_cli_service_node_modules_mini_css_extract_plugin_dist_loader_js_ref_8_oneOf_1_0_node_modules_vue_cli_service_node_modules_css_loader_dist_cjs_js_ref_8_oneOf_1_1_node_modules_vue_cli_service_node_modules_vue_loader_lib_loaders_stylePostLoader_js_node_modules_postcss_loader_src_index_js_ref_8_oneOf_1_2_node_modules_sass_loader_dist_cjs_js_ref_8_oneOf_1_3_node_modules_vue_cli_service_node_modules_cache_loader_dist_cjs_js_ref_0_0_node_modules_vue_cli_service_node_modules_vue_loader_lib_index_js_vue_loader_options_App_vue_vue_type_style_index_0_id_31e25cbe_lang_scss_scoped_true___WEBPACK_IMPORTED_MODULE_0___default = /*#__PURE__*/__webpack_require__.n(_node_modules_vue_cli_service_node_modules_mini_css_extract_plugin_dist_loader_js_ref_8_oneOf_1_0_node_modules_vue_cli_service_node_modules_css_loader_dist_cjs_js_ref_8_oneOf_1_1_node_modules_vue_cli_service_node_modules_vue_loader_lib_loaders_stylePostLoader_js_node_modules_postcss_loader_src_index_js_ref_8_oneOf_1_2_node_modules_sass_loader_dist_cjs_js_ref_8_oneOf_1_3_node_modules_vue_cli_service_node_modules_cache_loader_dist_cjs_js_ref_0_0_node_modules_vue_cli_service_node_modules_vue_loader_lib_index_js_vue_loader_options_App_vue_vue_type_style_index_0_id_31e25cbe_lang_scss_scoped_true___WEBPACK_IMPORTED_MODULE_0__);
/* unused harmony reexport * */
 /* unused harmony default export */ var _unused_webpack_default_export = (_node_modules_vue_cli_service_node_modules_mini_css_extract_plugin_dist_loader_js_ref_8_oneOf_1_0_node_modules_vue_cli_service_node_modules_css_loader_dist_cjs_js_ref_8_oneOf_1_1_node_modules_vue_cli_service_node_modules_vue_loader_lib_loaders_stylePostLoader_js_node_modules_postcss_loader_src_index_js_ref_8_oneOf_1_2_node_modules_sass_loader_dist_cjs_js_ref_8_oneOf_1_3_node_modules_vue_cli_service_node_modules_cache_loader_dist_cjs_js_ref_0_0_node_modules_vue_cli_service_node_modules_vue_loader_lib_index_js_vue_loader_options_App_vue_vue_type_style_index_0_id_31e25cbe_lang_scss_scoped_true___WEBPACK_IMPORTED_MODULE_0___default.a); 

/***/ })

/******/ });