uglifyjs logEvent.js -b beautify=false,quote_style=1 -o min-log.js
perl -p -i -e "s/ZhengReplaceJSIosLogEventHandler/%@/g" min-log.js