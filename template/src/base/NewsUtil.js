import JSTool from "./JSTool.js"
import NewsType from "./NewsType.js"
import NewsFormatDataapi from "./news-format-dataapi.js"
import NewsFormatGbapi from "./news-format-gbapi.js"
import NewsFormatNewsinfo from "./news-format-newsinfo.js"
import NewsFormatCaifuhaoapi from "./news-format-caifuhaoapi.js"

class NewsUtil {
  constructor() { }

  static NewsUtilNewApiEnable = true;

  newApiEnable(){
    return NewsUtil.NewsUtilNewApiEnable
  }

  //个位数补零
  prefixZero(num) {
    let newNum = 0;
    if (JSTool.isNumber(num)) {
      newNum = num
    } else if (JSTool.isString(num)) {
      newNum = parseInt(num)
    } else {
      return num;
    }
    if (newNum >= 10 || newNum <= -10) {
      return `${newNum}`;
    }
    return `${newNum >= 0 ? '' : '-'}0${newNum}`
  }
  //时间处理
  // 2019-12-23 10:14:00
  dateFromString(timeStr) {
    if (!JSTool.isString(timeStr) || !timeStr) return null

    let newTimeStr = timeStr;
    if (newTimeStr.indexOf('T') != -1) {
      newTimeStr = newTimeStr.replace(new RegExp("T", "g"), " ")
    }
    if (newTimeStr.length > 19) {
      newTimeStr = newTimeStr.substring(0, 19)
    }

    var timeArr = newTimeStr.split(" ")
    var d = timeArr[0].split("-")
    var t = timeArr[1].split(":")
    const date = new Date(d[0], d[1] - 1, d[2], t[0], t[1], t[2])
    return date
    //     var year = date.getFullYear();//年
    // 　　var month = date.getMonth();//月
    // 　　var day = date.getDate();//日
    // 　　var hours = date.getHours();//时
    // 　　var min = date.getMinutes();//分
    // 　　var second = date.getSeconds();//秒
  }
  dateFormat(str) {
    try {
      var date = new Date(str);
      var month = this.prefixZero(date.getMonth() + 1);
      var day = this.prefixZero(date.getDate());
      var hour = this.prefixZero(date.getHours());
      var min = this.prefixZero(date.getMinutes());
      return month + '-' + day + ' ' + hour + ':' + min;
    } catch(e) {
      return '--'
    }
}
  formatTimeString(timeString) {
    const date = this.dateFromString(timeString)
    if (!date) return ''
    let resTime = ''

    //当前日期
    const cDate = new Date();
    var cYear = cDate.getFullYear();
    var cMonth = cDate.getMonth() + 1;
    var cDay = cDate.getDate();
    //当天开始日期
    const cStartDate = new Date(cYear, cMonth - 1, cDay, '0', '0', '0');

    //毫秒差
    const num = cDate.getTime() - date.getTime();

    //将来的时间
    if (num <= 0) {
      return '刚刚';
    }

    var year = date.getFullYear();//年
    var month = date.getMonth() + 1;//月
    var day = date.getDate();//日
    var hours = date.getHours();//时
    var min = date.getMinutes();//分

    const Zero = (num) => {
      return this.prefixZero(num)
    }

    //当年
    if (year == cYear) {
      //当月
      if (month == cMonth) {
        //当天
        if (day == cDay) {
          if (num < 1000 * 60) {//0~60秒
            resTime = (num / 1000).toFixed(0).toString() + "秒前";
          } else if (num < 1000 * 60 * 60) {//0~60分钟
            const min = num / (1000 * 60);
            resTime = min.toFixed(0).toString() + "分钟前";
          } else if (num <= 1000 * 60 * 60 * 24) {//0~24小时
            const hour = num / (1000 * 60 * 60);
            resTime = hour.toFixed(0).toString() + "小时前";
          }
        } else {
          //距离当天开始时间的时间差
          const startNum = cStartDate.getTime() - date.getTime();
          if (num <= 1000 * 60 * 60 * 24) {//0~24小时  昨天
            resTime = `昨天 ${Zero(hours)}:${Zero(min)}`
          } else if (num <= 1000 * 60 * 60 * 48) {//24~48小时  前天
            resTime = `前天 ${Zero(hours)}:${Zero(min)}`
          } else {
            resTime = `${Zero(month)}-${Zero(day)} ${Zero(hours)}:${Zero(min)}`
          }
        }
      } else {
        resTime = `${Zero(month)}-${Zero(day)} ${Zero(hours)}:${Zero(min)}`
      }
    } else {
      resTime = `${year}-${Zero(month)}-${Zero(day)} ${Zero(hours)}:${Zero(min)}`
    }
    return resTime
  }

  formatArticle(article) {
    const type = article.type;
    console.log('ddddd' + type);
    const isNewApi = NewsUtil.NewsUtilNewApiEnable
    try {
      if (type == NewsType.News) {
        return isNewApi ? NewsFormatNewsinfo.format(article) : NewsFormatDataapi.formatNews(article);
      } else if (type == NewsType.Wealth) {
        return isNewApi ? NewsFormatCaifuhaoapi.format(article) : NewsFormatDataapi.formatWealth(article);
      } else if (type == NewsType.Answer || type == NewsType.Post) {
        return NewsFormatGbapi.format(article)
      }
      return {}
    } catch (error) {
      console.log(error);
    }
   
  }

  debounce(fn, wait = 200) {//防止抖动
    // 通过闭包缓存一个定时器 id
    let timer = null
    // 将 debounce 处理结果当作函数返回
    // 触发事件回调时执行这个返回函数
    return function (...args) {
      // 如果已经设定过定时器就清空上一次的定时器
      if (timer) clearTimeout(timer)
      // 开始设定一个新的定时器，定时器结束后执行传入的函数 fn
      timer = setTimeout(() => {
        fn.apply(this, args)
      }, wait)
    }
  }
}
export default new NewsUtil();