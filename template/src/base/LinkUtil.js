import JSTool from "./JSTool.js"
import LinkMap from "./LinkMap.js"

class LinkUtil {
    constructor() { }
    getLinkFromParams(adId, linkTo, linkType, other) {
        const newAdId = (JSTool.isString(adId) || JSTool.isNumber(adId)) ? adId : ''
        const newLinkTo = JSTool.isString(linkTo) ? linkTo : ''
        const newLinkType = (JSTool.isString(linkType) || JSTool.isNumber(linkType)) ? linkType : ''

        let otherLink = ''
        if (JSTool.isObject(other)) {
            otherLink += ','
            for (const key in other) {
                if (other.hasOwnProperty(key)) {
                    const element = other[key];
                    //编码  防止出现空格
                    otherLink += `"${key}":"${encodeURIComponent(element)}"`
                }
            }
        }
        //link内容放在 a标签的href里面  以下代码不可换行  不可有空格
        const res = `${LinkMap.link}({"AdId":"${newAdId}","LinkTo":"${newLinkTo}","LinkType":"${newLinkType}"${otherLink}})`
        return res
    }
    getLinkFromJson(linkInfo, other) {
        let adId = JSTool.fetchNumber(linkInfo, 'adId');
        let linkTo = JSTool.fetchString(linkInfo, 'linkTo');
        let linkType = JSTool.fetchNumber(linkInfo, 'linkType');
        return this.getLinkFromParams(adId, linkTo, linkType, other)
    }
    getPostLink(linkText, linkType, linkTo) {
        const newLinkText = JSTool.isString(linkText) ? linkText : ''
        const newLinkTo = JSTool.isString(linkTo) ? linkTo : ''
        const newLinkType = (JSTool.isString(linkType) || JSTool.isNumber(linkType)) ? linkType : ''

        return `${LinkMap.postLink}({"linkText":"${newLinkText}","linkInfo":{"LinkType":"${newLinkType}","LinkTo":"${newLinkTo}"}})`;
    }
    getPreviewImageLink(index, images) {
        let newIndex = index
        if (!JSTool.isNumber(index)) {
            newIndex = 0
        }
        let newImages = images
        if (!JSTool.isArray(newImages)) {
            newImages = []
        }
        const res = `${LinkMap.previewImage}({"url":"Key","index":"${newIndex}","images":"${newImages}"})`
        return res
    }
    getLookImageLink(index, images) {
        let newIndex = index
        if (!JSTool.isNumber(index)) {
            newIndex = 0
        }
        let newImages = images
        if (!JSType.isArray(newImages)) {
            newImages = []
        }
        const res = `${LinkMap.lookImage}({"index":"${newIndex}","images":"${newImages}"})`
        return res
    }
    getTopicLink(text, topicList) {
        var newText = text
        let newTopicList = topicList
        if(!newTopicList){
            return;
        }
        if(topicList){
            for (let index = 0; index < topicList.length; index++) {
              const topicData = topicList[index];
              const topicName = '#'+topicData.name +'#';
              const newTopicName = '<a href=fund://mp.1234567.com.cn/weex/d865c137f22841119dd7f23994a910b6/pages/HotTopicDetailPage?topicId='+topicData.htid+'>'+topicName+'</a>';
              if(newText.indexOf(topicName) >= 0){
                newText = newText.replace(new RegExp(topicName, "g"), newTopicName);
              }
            }
          }
        return newText
    }
}

export default new LinkUtil();