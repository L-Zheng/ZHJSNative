#包装成小程序
echo '\n👉：包装成小程序\n'
rm -rf 'release'
mkdir -p 'release'
cp -R 'dist/' 'release/'
cp -R 'pages.json' 'release/pages.json'
rm -rf 'release/favicon.ico'

cp -R 'static' 'dist/static'
cp -R 'static' 'release/static'
