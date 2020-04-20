<template>
  <div class="main-wrap">
    <div style="width:100px;height:100px;background-color:orange;"></div>
    <div style="word-break:break-all;">
      <a href="" >@Hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhspfdlk</a>
      加油吧少年
      <a href="">@Hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhspfdlk</a>
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
  components: {},
  data() {
    return {
      testEmotion: "",
      testBigEmotion: ""
    };
  },
  created() {
    this.configVue();
    this.addWindowFunc();
  },
  computed: {},
  mounted() {
    const emotionMap = fund.getEmotionResourceSync();
    const bigEmotionMap = fund.getBigEmotionResourceSync();
    this.testEmotion = Emotion.getEmotionText(
      emotionMap,
      bigEmotionMap,
      "[微笑][大笑]"
    );
    this.testBigEmotion = Emotion.getEmotionText(
      emotionMap,
      bigEmotionMap,
      "[厉害了]",
      100
    );
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
      //渲染  ❌此处不要使用async方法  ios原生会报错：JavaScript execution returned a result of an unsupported type
      window.render = (parmas) => {
        const json = JSON.parse(decodeURIComponent(parmas));
        console.log('✅1111够oooowero1234sdffg')
        console.log(json)
        this.prepareRender();
        return 'sdddd';
      };
    },
    prepareRender() {
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
.main-wrap {
  width: 100%;
  /* fallback */
  /* -webkit-overflow-scrolling: touch;  此句代码会导致webview的scroll的bounds【滑动bounds】会遮盖住fix定位的元素 */
  height: 100%;
  /* height: 100vh; 此句代码打开会导致window.onsroll事件不调用，iOS原生点击状态栏webview不会滚动  如果注释会影响评论弹窗的拖拽 */
  overflow: auto;
  position: relative;
  overflow-x: hidden !important;
}
</style>
