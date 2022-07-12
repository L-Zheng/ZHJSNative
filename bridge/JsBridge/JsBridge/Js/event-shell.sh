uglifyjs event.js -b beautify=false,quote_style=1 -o event-min.js
perl -p -i -e "s/My_JsBridge_Replace_WebHandler/%@/g" event-min.js
perl -p -i -e "s/My_JsBridge_Replace_jsToNativeMethodSync/%@/g" event-min.js
perl -p -i -e "s/My_JsBridge_Replace_jsToNativeMethodAsync/%@/g" event-min.js
perl -p -i -e "s/My_JsBridge_Replace_callSuccess/%@/g" event-min.js
perl -p -i -e "s/My_JsBridge_Replace_callFail/%@/g" event-min.js
perl -p -i -e "s/My_JsBridge_Replace_callComplete/%@/g" event-min.js
perl -p -i -e "s/My_JsBridge_Replace_callJsFunctionArg/%@/g" event-min.js
perl -p -i -e "s/My_JsBridge_Replace_nativeCallJs/%@/g" event-min.js
perl -p -i -e "s/My_JsBridge_Replace_makeApi/%@/g" event-min.js
perl -p -i -e "s/My_JsBridge_Replace_makeModuleApi/%@/g" event-min.js
# perl -p -i -e "s/const /var /g" event-min.js
# perl -p -i -e "s/let /var /g" event-min.js
