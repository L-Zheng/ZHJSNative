uglifyjs console.js -b beautify=false,quote_style=1 -o console-min.js
perl -p -i -e "s/_Replace_ConsoleApi/%@/g" console-min.js

#替换掉let const变量  ios9不支持这些变量
# perl -p -i -e "s/const /var /g" console-min.js
# perl -p -i -e "s/let /var /g" console-min.js
