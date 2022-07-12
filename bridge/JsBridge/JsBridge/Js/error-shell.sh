uglifyjs error.js -b beautify=false,quote_style=1 -o error-min.js
perl -p -i -e "s/My_JsBridge_Error_Replace_Api/%@/g" error-min.js

#替换掉let const变量  ios9不支持这些变量
# perl -p -i -e "s/const /var /g" error-min.js
# perl -p -i -e "s/let /var /g" error-min.js
