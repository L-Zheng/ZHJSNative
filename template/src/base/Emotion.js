
import JSTool from "./JSTool.js";

class Emotion {
  constructor() { }
  // 表情资源
  // const emojiResource = fund.getEmotionResourceSync();
  // const bigEmotionResource = fund.getBigEmotionResourceSync();

  getEmotionText(emojiResource, bigEmojiResource,text, size = 18) {
    let emojiText = text ? text : "";
    // emojiText = emojiText +  "啊[微笑]as按法律[为什么]法律我法律我[拜神]放到了[大笑]safsf啊都是V型d[鼓掌]你";
    //匹配表情
    let reg = new RegExp("\\[[\u4E00-\u9FA5_a-zA-Z]*\\]", "g");
    emojiText = emojiText.replace(reg, function (word) {
      // const key = word.substring(1, word.length - 1);
      const key = word;
      let imgSource = JSTool.fetchString(emojiResource, key);
      if(!imgSource){
        imgSource = JSTool.fetchString(bigEmojiResource, key);
      }
      if (imgSource){
        // console.log("匹配表情");
        // console.log(key); //微笑
        // console.log(imgSource); //EFEmoji.bundle/images/common_ef_emot01.png
        // return `<span style="width: 18px;height: 18px;background: url('${imgSource}') no-repeat 0 0;background-size: 18px 18px;">&emsp;</span>`
        return `<img src="${imgSource}" style="display:inline-block;width:${parseFloat(size)}px;height:${parseFloat(size)}px;margin: 0;background: #ffffff00;" alt />`;
      }
      return word;
    });

    return emojiText;
  }
}
export default new Emotion();