uglifyjs event.js -b beautify=false,quote_style=1 -o min-event.js
perl -p -i -e "s/ZhengReplaceJSEventHandler/%@/g" min-event.js
perl -p -i -e "s/ZhengReplaceCallBackSuccessKey/%@/g" min-event.js
perl -p -i -e "s/ZhengReplaceCallBackFailKey/%@/g" min-event.js
perl -p -i -e "s/ZhengReplaceCallBackCompleteKey/%@/g" min-event.js
perl -p -i -e "s/ZhengReplaceIosCallBack/%@/g" min-event.js
perl -p -i -e "s/ZhengReplaceGeneratorAPI/%@/g" min-event.js

perl -p -i -e "s/const /var /g" min-event.js
perl -p -i -e "s/let /var /g" min-event.js
