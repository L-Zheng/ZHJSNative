import JSTool from "./JSTool.js"

let UrlConfig = {
    // 数组配置：[正式、公测、内侧]
    urlInfo: {
        marketServer: [
            'https://fundmobapi.eastmoney.com',//正式
            'https://fundmobapitest11.eastmoney.com',//公测
            'https://fundmobapitest222.eastmoney.com'//内侧
        ],
        newsServer: [
            'https://appnews.1234567.com.cn/api/AppService/',
            'https://appnewstest.1234567.com.cn/api/AppService/',
            'https://appnewstest.1234567.com.cn/api/AppService/'
        ],
        gubaNewsServer: [
            'https://fundmobapitest2.eastmoney.com/'
        ],
        fundBarDataServer: [
            'https://dataapi.1234567.com.cn/', //正式
            "https://dataapi.1234567.com.cn/", //公测
            "https://dataapineice.1234567.com.cn/" //内侧
        ],
        fundBarServer: [
            "https://jijinbaapi.eastmoney.com/",
            "https://fundmobapitest.eastmoney.com/",
            "https://fundmobapitest.eastmoney.com/"
        ],
        avatorServer: [
            'http://avator.eastmoney.com/qface/'
        ],
        gbaServer: [
            'https://gbapi.eastmoney.com/',
            'https://gbapi-test.eastmoney.com/',
            'https://gbapi-test.eastmoney.com/'
        ],
        cfhServer: [
            "https://fundcfhapi.1234567.com.cn/",  //正式
            "https://fundmobapitest.eastmoney.com/", //公测
            "https://fundmobapitest.eastmoney.com/cfhneice/" //内侧
        ],
        articleCommentListServer: [
            "http://gbapi-test.eastmoney.com/",//评论列表
            "http://gbapi-test.eastmoney.com/",//评论列表
            "http://gbapi-test.eastmoney.com/"//评论列表
        ],
        fundPersonalConfig: [
            "https://appactive.1234567.com.cn/", //个性化配置接口
            "https://appactivetest.1234567.com.cn/",
            "https://appactiveneice.1234567.com.cn/"
        ]
    },
    // 正式: publish  公测: publicTest   内测: internalTest
    envArr: ['publish', 'publicTest', 'internalTest'],
    //当前环境 正式: 0  公测: 1   内测: 2
    urlMap: {}
}

function urlInit() {
    const envArr = UrlConfig.envArr;
    const currentEnv = JSTool.fetchNumber(fund.getSystemInfoSync(), 'appEnvironment');
    const serverList = (() => {
        const infoArr = [];
        const urlInfo = UrlConfig.urlInfo;
        for (const key in urlInfo) {
            if (urlInfo.hasOwnProperty(key)) {
                const urls = urlInfo[key];
                urls.forEach((url, index) => {
                    if (index >= infoArr.length) {
                        infoArr.push({})
                    }
                    infoArr[index][key] = url;
                });
            }
        }
        const res = {};
        envArr.forEach((key, index) => {
            res[key] = (index >= infoArr.length ? {} : infoArr[index])
        });
        console.log(res)
        return res;
    })();
    Object.assign(UrlConfig.urlMap ,serverList[envArr[currentEnv]]);
}

export default UrlConfig.urlMap;

export {
    urlInit
}