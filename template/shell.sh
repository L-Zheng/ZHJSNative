

CUR_DIR=$(cd "$(dirname "$0")"; pwd)
echo '\n👉当前运行目录：'$CUR_DIR'\n'

echo '👉编译\n'
yarn build

BundleDir=${CUR_DIR}'/../ZHJSNative/TestBundle.bundle/release'
if [ -e "${BundleDir}" ]
then
    echo '\n👉删除iOS项目 EFNewsHtmlBundle文件\n'
    rm -rf "${BundleDir}"/*

    echo '👉拷贝 新建EFNewsHtmlBundle文件\n'
    SourceDir=${CUR_DIR}'/release'
    if [ -e "${SourceDir}" ]
    then
        cp -R "${SourceDir}/" "${BundleDir}/"
    fi    
fi


