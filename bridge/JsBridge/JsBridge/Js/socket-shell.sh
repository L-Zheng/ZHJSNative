uglifyjs socket.js -b beautify=false,quote_style=1 -o socket-min.js
perl -p -i -e "s/My_JsBridge_Socket_Replace_Api/%@/g" socket-min.js

#替换掉let const变量  ios9不支持这些变量
# perl -p -i -e "s/const /var /g" socket-min.js
# perl -p -i -e "s/let /var /g" socket-min.js
