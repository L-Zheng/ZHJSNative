import JS from "./JSTool.js"
import NewsType from "./NewsType.js"


// 处理该域名下的数据  资讯
// http://newsinfo.eastmoney.com/kuaixun/v2/api/content/getnews?newsid=202001141355870036&newstype=1&source=app&sys=andorid&version=600000001&guid=appzxzw954ca1c5-94c2-2dec-70e8-0322af5658e9
class NewsFormatNewsinfo {
    convertBody(news){
        let body = JS.fetchString(news, 'body')
        if (!body) return ''
        return body;
        //保征：新资讯接口会处理基金关键词，不需要走何亮接口，直接返回
        let reg = ''
        //替换<strong></strong>为<b></b>
        reg = new RegExp('(<strong>)', "g")
        body = body.replace(reg, function (word) {
            return '<b>'
        })
        reg = new RegExp('(</strong>)', "g")
        body = body.replace(reg, function (word) {
            return '</b>'
        })
        //替换  &gt;&gt;&gt; 为  >>>
        // reg = new RegExp('(<strong>.*?</strong>)', "g");
        reg = new RegExp('(&gt;)', "g")
        body = body.replace(reg, function (word) {
            return '>'
        })
        //替换
        console.log('convertBodyconvertBody')
        const domin1 = 'http://quote.eastmoney.com/unify/r/'
        const tDomin1 = 'https://emwap.eastmoney.com/quota/hq/stock?'
        reg = new RegExp(`(${domin1}.*)`, "g")
        body = body.replace(reg, function (word) {
            console.log(word)
            const paramsStr = word.replace(new RegExp(domin1), '')
            if (paramsStr && JS.isString(paramsStr)) {
                const paramsArr = paramsStr.split('.')
                if (paramsArr.length == 2) {
                    return `${tDomin1}id=${paramsArr[1]}&mk=${paramsArr[0]}`
                }
            }
            return word
        })
        


//  http://quote.eastmoney.com/unify/r/133.USDCNH
//  转换👇
//  https://emwap.eastmoney.com/quota/hq/stock?id=USDCNH&mk=133
 
        console.log(body)
        return body;
    }
    format(article) {
        const articleData = article.data;
        console.log(JSON.stringify(article.type));
        const news = JS.fetchJson(articleData, 'news');
        console.log('ssss' + articleData);
        return {
            Id: article.Id,
            type: article.type,
            body: this.convertBody(news),
            htmlBody: article.htmlData,
            rawData: articleData,//接口原始数据
            title: JS.fetchString(news, 'title'),
            summary: JS.fetchString(news, 'simdigest'),              
            showTime: JS.fetchString(news, 'showtime'),
            source: JS.fetchString(news, 'source'),
            shareUrl: JS.fetchString(articleData, 'shareUrl'),
            newsType:1,
            user: {
                userId: '',
                userName: ''
            },
            repostState: 0
        }
    }
}
export default new NewsFormatNewsinfo();