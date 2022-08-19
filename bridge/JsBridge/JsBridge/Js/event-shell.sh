uglifyjs event.js -b beautify=false,quote_style=1 -o event-min.js
perl -p -i -e "s/_Replace_msgHandlerName/%@/g" event-min.js
perl -p -i -e "s/_Replace_bridgeSyncIdentifier/%@/g" event-min.js
perl -p -i -e "s/_Replace_bridgeAsyncIdentifier/%@/g" event-min.js
perl -p -i -e "s/_Replace_callSuccessKey/%@/g" event-min.js
perl -p -i -e "s/_Replace_callFailKey/%@/g" event-min.js
perl -p -i -e "s/_Replace_callCompleteKey/%@/g" event-min.js
perl -p -i -e "s/_Replace_callJsFuncArgKey/%@/g" event-min.js
perl -p -i -e "s/_Replace_receviceNativeCall/%@/g" event-min.js
perl -p -i -e "s/_Replace_makeApi/%@/g" event-min.js
perl -p -i -e "s/_Replace_makeModuleApi/%@/g" event-min.js
# perl -p -i -e "s/const /var /g" event-min.js
# perl -p -i -e "s/let /var /g" event-min.js
