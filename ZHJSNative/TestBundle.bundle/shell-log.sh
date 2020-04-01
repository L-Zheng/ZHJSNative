uglifyjs logEvent.js -b beautify=false,quote_style=1 -o min-log.js
perl -p -i -e "s/ZhengReplaceJSIosLogEventHandler/%@/g" min-log.js

#替换掉let const变量  ios9不支持这些变量
# perl -p -i -e "s/const /var /g" min-log.js
# perl -p -i -e "s/let /var /g" min-log.js