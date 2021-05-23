uglifyjs errorEvent.js -b beautify=false,quote_style=1 -o min-error.js
perl -p -i -e "s/ZhengReplaceJSErrorEventHandler/%@/g" min-error.js

#替换掉let const变量  ios9不支持这些变量
# perl -p -i -e "s/const /var /g" min-error.js
# perl -p -i -e "s/let /var /g" min-error.js