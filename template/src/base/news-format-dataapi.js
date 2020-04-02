import JS from "./JSTool.js"
import NewsType from "./NewsType.js"

// 处理该域名下的数据  620线上版 资讯与财富号
// https://dataapi.1234567.com.cn/community/show/article?serverversion=6.2.5&userid=&product=EFund&passportid=&deviceid=F0DD802F-6164-439E-9ACB-85763AAE813F&plat=Iphone&ids=202001141355870036_100&ctoken=&utoken=&version=6.3.0&gtoken=85D646FD659449F7A3E646530A51F372
class NewsFormatDataapi {
    convertBody(news){
        return JS.fetchString(news, 'content');
    }
    formatWealth(article){
        const news = article.data
        const authorModel = JS.fetchJson(news, 'authorModel')
        const shareModel = JS.fetchJson(news, 'shareModel')
        return {
            Id: article.Id,
            type: article.type,
            body: this.convertBody(news),
            htmlBody: article.htmlData,
            rawData: news,//接口原始数据
            barOutCode: JS.fetchString(JS.fetchJson(news, 'barModel'), 'barCode'),
            title: JS.fetchString(news, 'title'),
            summary: JS.fetchString(news, 'summary'),
            showTime: JS.fetchString(news, 'showTime'),
            source: JS.fetchString(news, 'source'),
            user: {
                userId: JS.fetchString(authorModel, 'pid'),
                userName: JS.fetchString(authorModel, 'nickName'),
                vType: JS.fetchNumber(authorModel, 'vType'),
                introduce: JS.fetchString(authorModel, 'introduce'),
                mgrId: JS.fetchString(authorModel, 'mgrId'),
                cfhId: JS.fetchString(authorModel, 'cfhId'),
                cfhtype: JS.fetchNumber(authorModel, 'cfhtype'),
            },
            shareUrl: JS.fetchString(shareModel, 'shareUrl'),
            repostState: JS.fetchNumber(news, 'repostState')
        }
    }
    formatNews(article) {
        const news = article.data
        const authorModel = JS.fetchJson(news, 'authorModel')
        return {
            Id: article.Id,
            type: article.type,
            body: this.convertBody(news),
            htmlBody: article.htmlData,
            rawData: news,//接口原始数据
            barType: '',
            barOutCode: JS.fetchString(JS.fetchJson(news, 'barModel'), 'barCode'),
            title: JS.fetchString(news, 'title'),
            summary: JS.fetchString(news, 'summary'),            
            showTime: JS.fetchString(news, 'showTime'),
            source: JS.fetchString(news, 'source'),
            user: {
                userId: JS.fetchString(authorModel, 'pid'),
                userName: JS.fetchString(authorModel, 'nickName')
            },
            repostState: JS.fetchNumber(news, 'repostState')
        }
    }
}
export default new NewsFormatDataapi();