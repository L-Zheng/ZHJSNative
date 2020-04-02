import JS from "./JSTool.js"
import NewsType from "./NewsType.js"
// 处理该域名下的数据  620线上版 问答与帖子
// https://gbapi.eastmoney.com/content/api/Post/FundArticleContent?postid=904847818&gtoken=85D646FD659449F7A3E646530A51F372&userid=&deviceid=F0DD802F-6164-439E-9ACB-85763AAE813F&product=Fund&serverversion=6.2.5&plat=Iphone&passportid=&version=630
class NewsFormatGbapi {
    getBarType(articleData) {
      let barType = 0;
      const code_name = articleData.code_name;
      if (code_name.indexOf("jjcl") != -1) {
        barType = 48;
      }
      if (code_name.indexOf("jjsp") != -1) {
        barType = 43;
      }
      return barType
    }
    getBarOutCode(articleData) {
      let barType = this.getBarType(articleData);
  
      let barOutCode = "";
      const post_guba = JS.fetchJson(articleData, 'post_guba');
      const barName = post_guba.stockbar_name;
      barOutCode = JS.fetchString(post_guba, 'stockbar_inner_code');
      if (barType == 43 || barType == 48) {
        const extend = articleData.extend;
        //实盘吧和策略吧从基金给股吧的扩展信息里面取
        barOutCode = JS.fetchString(extend, 'code')
      } else {
        if (barOutCode.length > 6) {
          if (barOutCode.indexOf("gd") != -1) {
            //包含高端理财
            barOutCode = barOutCode.substring(2);
          }
          if (barOutCode.indexOf("_") != -1 && barOutCode.length > 2) {
            const codeList = barOutCode.split("_");
            if (codeList.length > 0) {
              barOutCode = codeList[0];
            }
          }
        } else {
          if (barOutCode.indexOf("_1") != -1 && barOutCode.length > 2) {
            barOutCode = barOutCode.substring(0, barOutCode.length - 2);
          }
        }
      }
      console.log("barOutCode  "+barOutCode)
      return barOutCode
    }
    getQuestion(extend){
      const question = JS.fetchJson(extend, "GuBa_FundQuestion");
      return {
        article_id: JS.fetchString(question, "article_id"),
        question_id: JS.fetchString(question, "question_id"),
        title: JS.fetchString(question, "question_title"),
        pay_type: JS.fetchNumber(question, "pay_type"),
        amount: JS.fetchString(question, "amount"),
        createdtime: JS.fetchString(question, "createdtime"),
        endtime: JS.fetchString(question, "endtime"),
        answer_num: JS.fetchNumber(question, "answer_num"),
        question_userid: JS.fetchNumber(question, "question_userid"),
        question_title: JS.fetchNumber(question, "question_title"),
        isEnd: JS.fetchNumber(question, "isEnd")
      };
    }
    getAnswer(extend){
      const answer = JS.fetchJson(extend, "GuBa_FundAnswer");
      return {
        qid: JS.fetchString(answer, "QID"),
        aid: JS.fetchString(answer, "AID"),
        IsAdopted: JS.fetchString(answer, "IsAdopted"),
        userId: JS.fetchString(answer, "CreatorID")
      }
    }
    getFundExtTags(ContentExtTags){
      let fundExtTags = []
      ContentExtTags.forEach(el => {
        fundExtTags.push({
          busType: JS.fetchNumber(el, "BusType"),
          code: JS.fetchArray(el, "Code"),
          name: JS.fetchString(el, "Name"),
          remark: JS.fetchString(el, "Remark"),
          imgUrl: JS.fetchString(el, "ImgUrl"),
          appUrl: (() => {
            const link = JS.fetchJson(el, "AppUrl")
            return{
              linkType: JS.fetchNumber(link, 'LinkType'),
              adId: JS.fetchNumber(link, 'AdId'),
              linkTo: JS.fetchString(link, 'LinkTo')
            }
          })()
        })
     });
     return fundExtTags;
    }
    getFundTags(ContentTags){
      let fundTags = []
      ContentTags.forEach(el => {
        fundTags.push({
          busType: JS.fetchNumber(el, "BusType"),
          code: JS.fetchArray(el, "Code"),
          name: JS.fetchString(el, "Name"),
          remark: JS.fetchString(el, "Remark"),
          imgUrl: JS.fetchString(el, "ImgUrl"),
          // delete 
          label: JS.fetchString(el, "Label"),
          text: JS.fetchArray(el, "Text"),

          appUrl: (() => {
            let link = JS.fetchJson(el, "AppUrl")
            if (Object.keys(link).length == 0) {
              link = JS.fetchJson(el, "appLink");
            }
            if (Object.keys(link).length == 0) return {};
            return{
              linkType: JS.fetchNumber(link, 'LinkType'),
              linkTo: JS.fetchString(link, 'LinkTo')
            }
          })()
        })
     });
     return fundTags;
    }
    format(article) {
      const news = article.data  
      //帖子所在股吧信息
      //基础股吧字段 http://gubadoc.eastmoney.com/gubaapi/index.php?s=/2&page_id=193
      const post_guba = JS.fetchJson(news, 'post_guba');
      //发帖人信息
      //基础用户字段 http://gubadoc.eastmoney.com/gubaapi/index.php?s=/2&page_id=194
      const user = JS.fetchJson(news, 'post_user')
      //特殊帖子的附加信息
      //特殊帖子扩展模板 http://gubadoc.eastmoney.com/gubaapi/index.php?s=/4&page_id=473
      const extend = JS.fetchJson(news, "extend");
      //源帖特殊帖子的附加信息 特殊帖子扩展模板
      const source_extend = JS.fetchJson(news, "source_extend");
      //关键字信息
      const ContentTags = JS.fetchArray(JS.fetchJson(extend, "FundTags"), "ContentTags");
      //扩展信息
      const ContentExtTags = JS.fetchArray(JS.fetchJson(extend, "FundTags"), "ContentExtTags");
      //话题扩展信息
      const FundTopicPost = JS.fetchArray(extend, "FundTopicPost");
      const FundShowTitle = JS.fetchNumber(extend, "FundShowTitle");
      return {
        Id: article.Id,
        type: article.type,
        htmlBody: article.htmlData,
        rawData: news,//接口原始数据
        barType: this.getBarType(news),
        barOutCode: this.getBarOutCode(news),
        title: JS.fetchString(news, 'post_title'),
        showTitle: FundShowTitle,
        content: JS.fetchString(news, 'post_content'),
        summary: JS.fetchString(news, 'post_abstract'),
        publishTime: JS.fetchString(news, 'post_publish_time'),
        likeCount: JS.fetchString(news, 'post_like_count'),
        commentCount: JS.fetchString(news, 'post_comment_count'),
        //转发资讯
        sourcePost: {
          Id: (() => {
            const id = JS.fetchString(news, 'source_post_id')
            return parseInt(id) == 0 ? "" : id
          })(),
          type: JS.fetchNumber(news, 'source_post_type'),
          sourceId: JS.fetchString(news, "source_post_source_id"),
          userId: JS.fetchString(news, "source_post_user_id"),
          userName: JS.fetchString(news, "source_post_user_nickname"),
          title: JS.fetchString(news, "source_post_title"),
          content: JS.fetchString(news, "source_post_content"),
          picUrl: JS.fetchArray(news, "source_post_pic_url"),
          question: this.getQuestion(source_extend),
          answer: this.getAnswer(source_extend),
          fundTags: this.getFundTags(JS.fetchArray(JS.fetchJson(source_extend, "FundTags"), "ContentTags")),
          fundExtTags: this.getFundExtTags(JS.fetchArray(JS.fetchJson(source_extend, "FundTags"), "ContentExtTags")),
        },
        fundTags: this.getFundTags(ContentTags),
        fundExtTags: this.getFundExtTags(ContentExtTags),
        postGuba: {
          name: JS.fetchString(post_guba, 'stockbar_name')
        },
        user: {
          userId: JS.fetchString(user, 'user_id'),
          userName: JS.fetchString(user, 'user_nickname'),
          introduce: JS.fetchString(user, 'user_introduce'),
        },
        question: this.getQuestion(extend),
        answer: this.getAnswer(extend),

        picUrl: JS.fetchArray(news, 'post_pic_url'),
        picUrl2: JS.fetchArray(news, 'post_pic_url2'),
        fundTopicPost: FundTopicPost,
        atUser: JS.fetchArray(news, 'post_atuser'),
        codeName: JS.fetchString(news, 'code_name'),
        repostState: JS.fetchNumber(news, 'repost_state')
      }
    }
}
export default new NewsFormatGbapi();