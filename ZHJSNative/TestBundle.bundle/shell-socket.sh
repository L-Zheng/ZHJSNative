uglifyjs socketEvent.js -b beautify=false,quote_style=1 -o min-socket.js
perl -p -i -e "s/ZhengReplaceSocketIosHandler/%@/g" min-socket.js