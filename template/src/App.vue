<template>
  <div class="main-wrap">
    <PullRefresh @refresh="onRefresh">
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
      <div class="bottom">
      </div>
    </PullRefresh>
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
import PullRefresh from "./components/PullRefreshView.vue";

import eventBus from "@/base/eventBus";
function preventDefault(e) {
  e.preventDefault();
}

var vm = {
  name: "app",
  components: {
    PullRefresh,
  },
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

    // setTimeout(() => {
    //   fund1.commonLinkTo11({lll: 'llll'})
    //   fund1.commonLinkTo22({dddd: 'dddd'})
    // }, 3000);

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
      //但可以在方法里面使用async方法
      window.render = (parmas) => {
        const json = JSON.parse(decodeURIComponent(parmas));
        console.log(json)
        this.aaaa().then(res => {
          console.log(res)
        })
        this.prepareRender();
      };
    },
    async aaaa() {
      return new Promise((resolve, reject) => {
          resolve({sss:'ssss'});
        })
    },
    prepareRender() {
      try {
        //检查fund api  
        // ❌不能使用 if(fund)来判断 如果fund没有 js直接报错 代码不再向下运行
        console.log(fund);
        this.render();
      } catch (error) {
        HtmlWindow.addListener("fundJSBridgeReady", () => {
          this.render();
        });
      }
    },
    render(){

    },
    onRefresh(done) {
      setTimeout(() => {  
          done(); //我就想说这里，把状态归0
      }, 2000);
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
.bottom{
  position: fixed;
  left: 0;
  bottom: 0;
  width: 100%;
  height: 50px;
  background-color: orange;
}
</style>
