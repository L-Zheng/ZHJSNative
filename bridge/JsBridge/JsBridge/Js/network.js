;var My_NetworkMockXHR = function() {
    /* 
    https://developer.mozilla.org/zh-CN/docs/Web/JavaScript/Reference/Global_Objects/Reflect
    https://developer.mozilla.org/zh-CN/docs/Web/JavaScript/Reference/Global_Objects/Proxy/Proxy/get
    Reflect Proxy >= 
      desktop chrome 49(2016-3-2)  
      android chrome 49(2016-3-9)  
      safari 10(2016-9-13)

    https://developer.mozilla.org/zh-CN/docs/Web/JavaScript/Reference/Functions/Arrow_functions
    箭头函数 >= 
      chrome 49(2015-9-1) safari 10(2016-9-13)

    https://developer.mozilla.org/zh-CN/docs/Web/JavaScript/Reference/Operators/Spread_syntax
    展开语法 >=
      chrome 46(2015-10-13) safari 8(2014-9-17)

    const let 改为 var
    forof 改为 for
    */
    if (typeof XMLHttpRequest !== 'function' || typeof Proxy !== 'function' || typeof Reflect !== 'object') {
        return;
    }
    window.XMLHttpRequest = new Proxy(XMLHttpRequest, {
        construct(ctor) {
            var XMLReq = new ctor();
            return new Proxy(XMLReq, new function (XMLReq) {
                var that = this
                this.XMLReq = XMLReq;
                this.XMLReq.onreadystatechange = function () { that.onReadyStateChange() };
                this.XMLReq.onabort = function () { that.onAbort() };
                this.XMLReq.ontimeout = function () { that.onTimeout() };
                this.item = {};
                this.item.requestHeader = {};
                this.postData = null

                this.get = function (target, key) {
                    switch (key) {
                        case 'open':
                            return that.getOpen(target);
                        case 'send':
                            return that.getSend(target);
                        case 'setRequestHeader':
                            return that.getSetRequestHeader(target);
                        default:
                            var value = Reflect.get(target, key);
                            if (typeof value === 'function') {
                                return value.bind(target);
                            } else {
                                return value;
                            }
                    }
                }
                this.set = function (target, key, value) {
                    switch (key) {
                        case 'onreadystatechange':
                            return that.setOnReadyStateChange(target, key, value);
                        case 'onabort':
                            return that.setOnAbort(target, key, value);
                        case 'ontimeout':
                            return that.setOnTimeout(target, key, value);
                        default:
                        // do nothing
                    }
                    return Reflect.set(target, key, value);
                }

                this.getOpen = function (target) {
                    var targetFunction = Reflect.get(target, 'open');
                    return function () {
                        var args = arguments;
                        var method = args[0];
                        var url = args[1];
                        that.item.method = method ? method.toUpperCase() : 'GET';
                        that.item.url = url || '';
                        return targetFunction.apply(target, args);
                    };
                }
                this.getSend = function (target) {
                    var targetFunction = Reflect.get(target, 'send');
                    return function () {
                        var args = arguments;
                        var data = args[0];
                        that.item.postData = data;
                        return targetFunction.apply(target, args);
                    };
                }
                this.getSetRequestHeader = function (target) {
                    var targetFunction = Reflect.get(target, 'setRequestHeader');
                    return function () {
                        var args = arguments;
                        that.item.requestHeader[args[0]] = args[1];
                        return targetFunction.apply(target, args);
                    };
                }

                this.setOnReadyStateChange = function (target, key, value) {
                    return Reflect.set(target, key, function () {
                        var args = arguments;
                        that.onReadyStateChange();
                        value.apply(target, args);
                    });
                }
                this.setOnAbort = function (target, key, value) {
                    return Reflect.set(target, key, function () {
                        var args = arguments;
                        that.onAbort();
                        value.apply(target, args);
                    });
                }
                this.setOnTimeout = function (target, key, value) {
                    return Reflect.set(target, key, function () {
                        var args = arguments;
                        that.onTimeout();
                        value.apply(target, args);
                    });
                }

                this.onReadyStateChange = function () {
                    that.item.readyState = that.XMLReq.readyState;
                    that.item.responseType = that.XMLReq.responseType;
                    switch (that.XMLReq.readyState) {
                        case 0: // UNSENT
                        case 1: // OPENED
                            that.item.status = 0;
                            that.item.statusText = 'Pending';
                            if (!that.item.startTime) {
                                that.item.startTime = Date.now();
                            }
                            break;
                        case 2: // HEADERS_RECEIVED
                            that.item.status = that.XMLReq.status;
                            that.item.statusText = 'Loading';
                            that.item.responseHeader = {};
                            var responseHeader = that.XMLReq.getAllResponseHeaders() || ''
                            if (1) {
                                that.item.responseHeader = responseHeader
                            } else {
                                /*
                                // 编译后写入到 ios 代码中，需使用 '\\r\\n'
                                var headerArr = responseHeader.split('\r\n');
                                // extract plain text to key-value format
                                for (let i = 0; i < headerArr.length; i++) {
                                    var line = headerArr[i];
                                    if (!line) { continue; }
                                    var arr = line.split(': ');
                                    var key = arr[0];
                                    var value = arr.slice(1).join(': ');
                                    that.item.responseHeader[key] = value;
                                }
                                */
                            }
                            break;
                        case 3: // LOADING
                            that.item.status = that.XMLReq.status;
                            that.item.statusText = 'Loading';
                            if (!!that.XMLReq.response && that.XMLReq.response.length) {
                                that.item.responseSize = that.XMLReq.response.length;
                            }
                            break;
                        case 4: // DONE
                            // `XMLReq.abort()` will change `status` from 200 to 0, so use previous value in this case
                            that.item.status = that.XMLReq.status || that.item.status || 0;
                            that.item.statusText = String(that.item.status); // show status code when request completed
                            that.item.endTime = Date.now();
                            that.item.costTime = that.item.endTime - (that.item.startTime || that.item.endTime);
                            that.item.response = that.XMLReq.response;

                            if (!!that.XMLReq.response && that.XMLReq.response.length) {
                                that.item.responseSize = that.XMLReq.response.length;
                            }
                            that.triggerUpdate()
                            break;
                        default:
                            that.item.status = that.XMLReq.status;
                            that.item.statusText = 'Unknown';
                            that.triggerUpdate()
                            break;
                    }
                }
                this.onAbort = function () {
                    that.item.cancelState = 1;
                    that.item.statusText = 'Abort';
                    that.triggerUpdate()
                }
                this.onTimeout = function () {
                    that.item.cancelState = 3;
                    that.item.statusText = 'Timeout';
                    that.triggerUpdate()
                }

                this.triggerUpdate = function () {
                    var data = that.item;
                    try {
                        _Replace_NetworkApi.sendNative(JSON.parse(JSON.stringify(data)));
                    } catch (error) {
                    }
                }
            }(XMLReq));
        }
    });
};
My_NetworkMockXHR();