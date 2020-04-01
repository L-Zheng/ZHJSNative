uglifyjs socketEvent.js -b beautify=false,quote_style=1 -o min-socket.js
perl -p -i -e "s/ZhengReplaceSocketIosHandler/%@/g" min-socket.js

#替换掉let const变量  ios9不支持这些变量
# perl -p -i -e "s/const /var /g" min-socket.js
# perl -p -i -e "s/let /var /g" min-socket.js