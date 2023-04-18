
['log', 'debug', 'info', 'warn', 'error'].forEach(function (consoleKey) {
    console[consoleKey] = (function (oriFn) {
        return function () {
            /** 发送至 webview 控制台 */
            if (oriFn) {
                oriFn.apply(console, arguments);
            }
            var jsType = (function () {
                var type = {};
                var typeArr = ['String', 'Object', 'Number', 'Array', 'Undefined', 'Function', 'AsyncFunction', 'Null', 'Symbol', 'Boolean', 'Arguments', 'Error', 'Window'];
                for (var i = 0; i < typeArr.length; i++) {
                    (function (name) {
                        type['is' + name] = function (obj) {
                            return Object.prototype.toString.call(obj) == '[object ' + name + ']';
                        };
                    })(typeArr[i]);
                }
                return type;
            })();
            try {
                var params = arguments;
                if (!jsType.isArguments(params)) {
                    return;
                }
                var parseArg = function (arg) {
                    if (jsType.isString(arg) || jsType.isNumber(arg) || jsType.isUndefined(arg) || jsType.isNull(arg) || jsType.isBoolean(arg)) {
                        return arg;
                    }
                    if (jsType.isError(arg)) {
                        var res = {};
                        // 不能直接将 Error 直接赋值给 resErr, JSON.stringify(params[0]) 是一个空 json.
                        ['message', 'sourceURL', 'line', 'column', 'stack'].forEach(function (errKey) {
                            res[errKey] = arg[errKey];
                        });
                        return res;
                    }
                    if (jsType.isArray(arg)) {
                        // 只处理纯数据，js 对象不处理
                        var newArg = [];
                        try {
                            newArg = JSON.parse(JSON.stringify(arg));
                        } catch (error) {
                        };
                        var res = [];
                        for (var i = 0; i < newArg.length; i++) {
                            res.push(parseArg(newArg[i]));
                        }
                        return res;
                    }
                    if (jsType.isArguments(arg)) {
                        var res = [];
                        for (var i = 0; i < arg.length; i++) {
                            res.push(parseArg(arg[i]));
                        }
                        return res;
                    }
                    if (jsType.isObject(arg)) {
                        // 只处理纯数据，js 对象不处理
                        var newArg = {};
                        try {
                            newArg = JSON.parse(JSON.stringify(arg));
                        } catch (error) {
                        }
                        var res = {};
                        Object.keys(newArg).forEach(function (argKey) {
                            res[argKey] = parseArg(newArg[argKey]);
                        });
                        return res;
                    }
                    if (jsType.isSymbol(arg) || jsType.isWindow(arg) || jsType.isFunction(arg) || jsType.isAsyncFunction(arg)) {
                        return undefined;
                    }
                    return undefined;
                };

                var parseRes = [];
                for (var i = 0; i < params.length; i++) {
                    parseRes.push({
                        data: parseArg(params[i]),
                        type: Object.prototype.toString.call(params[i])
                    });
                }
                /*  发送消息name:与iOS原生保持一致 
                JSON.parse(JSON.stringify([undefined])) == [null]
                JSON.parse(JSON.stringify([null])) == [null]

                js 原始数据类型 -> 解析后组装的数据 --JSON.parse(JSON.stringify())--> 原生收到的数据类型
                log(string) -> [string] -> [string]
                log(number) -> [number] -> [number]
                log(undefined) -> [undefined] -> [null]
                log(null) -> [null] -> [null]
                log(function) -> [undefined] -> [null]
                log(Symbol) -> [undefined] -> [null]
                log(false) -> [false] -> [false]
                log(Error) -> [{message, sourceURL, line, column, stack}] -> [{message, sourceURL, line, column, stack}]
                
                纯数据：Array、Object
                log(Array) -> [Array] -> [Array]
                log(Object) -> [Object] -> [Object]
                
                Arguments = [string, window]
                log(Arguments) -> [[string, undefined]] -> [[string, null]]
                log(Window) -> [undefined] -> [null]
                log(this) -> [{}] -> [{}]
                */
                _Replace_ConsoleApi.sendNative(consoleKey, JSON.parse(JSON.stringify(parseRes)));
            } catch (error) {
                // 日志解析失败不需要报错
                // if ((jsType.isFunction(window.onerror) || jsType.isAsyncFunction(window.onerror)) && jsType.isError(error)) {
                //     window.onerror.apply(window, [error]);
                // }
            }
        }
    })(console[consoleKey]);
});