uglifyjs network.js -b beautify=false,quote_style=1 -o network-min.js
perl -p -i -e "s/_Replace_NetworkApi/%@/g" network-min.js

