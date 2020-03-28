uglifyjs errorEvent.js -b beautify=false,quote_style=1 -o min-error.js
perl -p -i -e "s/ZhengReplaceJSErrorEventHandler/%@/g" min-error.js