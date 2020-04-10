<template>
<div>
  <div style="width:100px;height:100px;background-color:orange;">
  </div>
  <div>
    <div v-html="testEmotion"></div>
    <div v-html="testBigEmotion"></div>
  </div>
</div>
</template>

<script>
import Vue from "vue";
import NewsNoti from "./base/NewsNoti.js";
import NativeMsg from "./base/NativeMsg.js";
import NewsUtil from "./base/NewsUtil.js";
import NewsType from "./base/NewsType.js";
import LinkMap from "./base/LinkMap.js";
import HtmlStorage from "./base/HtmlStorage.js";
import HtmlWindow from "./base/HtmlWindow.js";
import CommonData from "./base/CommonData.js";
import JSTool from "./base/JSTool.js";
import Emotion from "./base/Emotion.js";
import {
  requestKeyWords,
  requestInteractInfo,
  requestArticleLabels,
  requestBatchUserInfo,
  requestArticleMoreInfo,
  requestArticleBriefInfo
} from "./base/news-request.js";
import { urlInit } from "./base/url.js";

import eventBus from "@/base/eventBus";
function preventDefault(e) {
  e.preventDefault();
}

var vm = {
  name: "app",
  components: {
  },
  data() {
    return {
      testEmotion: '',
      testBigEmotion: ''
    };
  },
  created() {
    this.configVue();
    this.addWindowFunc();
  },
  computed: {},
  mounted() {
    const emotionMap = fund.getEmotionResourceSync()
    const bigEmotionMap = fund.getBigEmotionResourceSync()
    this.testEmotion = Emotion.getEmotionText(emotionMap, bigEmotionMap, '[微笑][大笑]')
    this.testBigEmotion = Emotion.getEmotionText(emotionMap, bigEmotionMap, '[厉害了]', 100)
  },
  methods: {
    configVue() {
      Vue.config.errorHandler = (oriFunc => {
        return function(err, vm, info) {
          /**发送至Vue*/
          if (oriFunc) oriFunc.call(null, err, vm, info);
          /**发送至WebView*/
          if (window.onerror) window.onerror.call(null, err);
        };
      })(Vue.config.errorHandler);
    },
    addWindowFunc() {
      //配置事件
      HtmlWindow.configWindowEvent();
      //接受原生消息
      window.receiveNativeMessage = parmas => {
        NativeMsg.post(parmas);
      };
      //渲染
      window.render = () => {
        this.prepareRender()
      };
    },
    prepareRender(){
      try {
        //检查fund api
        console.log(fund);
        this.render();
      } catch (error) {
        HtmlWindow.addListener("fundJSBridgeReady", () => {
          this.render();
        });
      }
    }
  }
};
export default vm;
</script>


<style lang="scss" scoped>
html {
  overflow-x: hidden !important;
  -webkit-tap-highlight-color: transparent;
}
.main-wrap {
  /* fallback */
  /* -webkit-overflow-scrolling: touch;  此句代码会导致webview的scroll的bounds【滑动bounds】会遮盖住fix定位的元素 */
  height: 100%;
  /* height: 100vh; 此句代码打开会导致window.onsroll事件不调用，iOS原生点击状态栏webview不会滚动  如果注释会影响评论弹窗的拖拽 */
  overflow: auto;
  position: relative;
  overflow-x: hidden !important;
}
.comment-filter-anchor {
  position: relative;
  z-index: 199;
  width: 100%;
  height: 47px;
}
.comment-filter {
  position: relative;
  z-index: 199;
  width: 100%;
  top: 0;
  left: 0;
}
.popup-wrap {
  -webkit-overflow-scrolling: touch;
  width: 100%;
  position: fixed;
  top: 0;
  bottom: 0;
  z-index: 200;
  overflow: auto;
  overflow-x: hidden !important;
}
.place-holder {
  height: 49px;
}
.article-wrap {
  overflow-x: hidden;
}
.all-comment {
  background: #ffffff;
  padding: 0 15px;
  border-bottom: 1px solid #eeeeee99;
  line-height: 40px;
  font-size: 14px;
  -webkit-box-sizing: border-box;
  box-sizing: border-box;
  color: #000000;
}
</style>
