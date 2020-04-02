import JS from "./JSTool.js"
import NewsType from "./NewsType.js"


// 处理该域名下的数据  财富号
// http://caifuhaoapi-zptest.eastmoney.com/api/v1/fund/Article/GetArticleByCode?artcode=20200109170930113913270&pagesize=10&pageindex=1&client_source=fund_app&client_os=com.eastmoney.app.dfcf_8.1.1&client_drive=ememem&callback=mycallback
class NewsFormatCaifuhaoapi {
    convertBody(news){
        return JS.fetchString(news, 'Content');
    }
    getCfhType(OrganizationType) {
        if(OrganizationType.startsWith("001")) {//001 开头为个人财富号
            return 1;
        } else {//机构
            return 2;
        }
    }
    getVType(BigVip, accreditationType) {
        if(BigVip == 1) {//加v
            if(accreditationType == "002") {//002 为个人
                return 2;
            } else {//机构
                return 1;
            }     
        } else {
            return 0;
        }
    }
    format(article) {
        const news = article.data
        const author = JS.fetchJson(news, 'authorInfo')
        const OrganizationType = JS.fetchString(author, 'OrganizationType')
        const BigVip = JS.fetchNumber(author, 'BigVip')
        const accreditationType = JS.fetchNumber(author, 'accreditationType')
        const vType = this.getVType(BigVip,accreditationType);
        const cfhtype = this.getCfhType(OrganizationType);
        return {
            Id: article.Id,
            type: article.type,
            body: this.convertBody(news),
            htmlBody: article.htmlData,
            rawData: news,//接口原始数据
            title: JS.fetchString(news, 'Title'),
            summary: JS.fetchString(news, 'DigestAuto'),
            showTime: JS.fetchString(news, 'Showtime'),
            source: '❌接口没有该字段',
            user: {
                userId: JS.fetchString(author, 'RelatedUid'),
                userName: JS.fetchString(author, 'NickName'),
                vType: vType,
                introduce: JS.fetchString(author, 'Summary'),
                mgrId: JS.fetchString(author, 'mgrId'),//❌接口没有该字段
                cfhId: JS.fetchString(author, 'Account_Id'),
                cfhtype: cfhtype,
            },
            repostState: 0
        }
    }
}
export default new NewsFormatCaifuhaoapi();