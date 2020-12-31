<template>
  <div class="main-wrap">
    <PullRefresh @refresh="onRefresh">
      <div @click="clickTest" 
      style="width:150px;height:100px;background-color:green;">
      点我测试
      </div>
      <div
      style="width:100px;height:100px;background-color:orange;">
      点我
      </div>
      <div style="word-break:break-all;">
        <a href>@Hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhspfdlk</a>
        加油吧少年
        <a href>@Hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhspfdlk</a>
      </div>
      <div>
        <div v-html="testEmotion"></div>
        <div v-html="testBigEmotion"></div>
      </div>
      <div class="bottom"></div>
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
    PullRefresh
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
  mounted() {},
  methods: {
    clickTest() {
      // fund.commonLinkTo();
      // return
      // fund.commonLinkTo({
      //   ff: 'qqq',
      //   success: (res) => {
      //     console.log('success', 243, 'gdf')
      //     console.log(res)
      //   return '11111q'
      //   },
      //   fail: (res) => {
      //     console.log('fail')
      //     console.log(res)
      //   return '22222q'
      //   },
      //   complete: (res) => {
      //     console.log('complete')
      //     console.log(res)
      //   return '333333q'
      //   }
      // }, {
      //   ff: 'ttt',
      //   success: (res) => {
      //     console.log('success-ttt', 243, 'gdf')
      //     console.log(res)
      //   },
      //   fail: (res) => {
      //     console.log('fail-ttt')
      //     console.log(res)
      //   },
      //   complete: (res) => {
      //     console.log('complete-ttt')
      //     console.log(res)
      //   }
      // }, 
      // 'a string', 
      // ['gf', 555], 
      // 234, 
      // null, 
      // undefined, 
      // false, 
      // true, 
      // function(){console.log('jjjj')});
      // return;
      const res = fund.getJsonSync({
        ff: 'qqq',
        success: (res) => {
          console.log('success-qqq', 243, 'gdf')
          console.log(res)
        return '11111q'
        },
        fail: (res) => {
          console.log('fail-qqq')
          console.log(res)
        return '22222q'
        },
        complete: (res) => {
          console.log('complete-qqq')
          console.log(res)
        return '33333q'
        }
      }, {
        ff: 'ttt',
        success: (res) => {
          console.log('success-ttt', 243, 'gdf')
          console.log(res)
        },
        fail: (res) => {
          console.log('fail-ttt')
          console.log(res)
        },
        complete: (res) => {
          console.log('complete-ttt')
          console.log(res)
        }
      }, 
      'a string', 
      ['gf', 555], 
      234, 
      null, 
      undefined, 
      false, 
      true, 
      function(){console.log('jjjj')});
      console.log(res)
      return;
      console.log('sdfdg')
      console.log(sdfg)
      return;
      fund.request({
            url: 'https://dataapineice.1234567.com.cn/community/show/article?serverversion=6.2.5&userid=43fe14e102644bd5b0edcd8fc3306e80&product=EFund&passportid=1010285265217684&deviceid=F0DD802F-6164-439E-9ACB-85763AAE813F&plat=Iphone&ids=20191128154557877210040_300&ctoken=afqqc6c6afacj-q6f1qk-8kjrnej-d1-&utoken=ndecnj-fjne1krck8816q68fkcnfkcnu&version=6.3.0&gtoken=85D646FD659449F7A3E646530A51F372',
            method: 'GET',
            success: function (res) {
                console.log('test-reqyessfdwd')
                console.log(Object.prototype.toString.call(res))
                console.log(res)
                // console.log(Object.prototype.toString.call(res.sd))
                // console.log(res.sd)
            },
            fail: function() {
            },
            complete: function() {
                console.log('completecompletecomplete')
            }
        })
      return;
      window.localStorage.setItem('ffffff', 'xxsdfgd')
      console.log(window.localStorage.getItem('ffffff'))

      // HtmlStorage.setLocalStorage('ffffff', 'xx')
      // console.log('getLocalStoragegetLocalStorage')
      // console.log(HtmlStorage.getLocalStorage('ffffff'))
    },
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
      window.loadPage = (path, params) => {
        const newSrc = decodeURIComponent(path);
        let script = document.createElement("script");
        script.src = newSrc;
        script.onload = function() {
          window.render(params)
          // console.log('loaded', newSrc);
          // callback && window[callback](true);
        };
        script.onerror = function() {};
        document.body.append(script);
      };
      //渲染  ❌此处不要使用async方法  ios原生会报错：JavaScript execution returned a result of an unsupported type
      //但可以在方法里面使用async方法
      window.render = parmas => {
        const json = JSON.parse(decodeURIComponent(parmas));
        console.log(json);
        this.aaaa().then(res => {
          console.log(res);
        });
        this.prepareRender();
      };
      window.addApiTest = () => {
        ZhengExtra.commonLinkTo1122({lll: 'fundxxxxxxxxxxx1122'})
        ZhengExtra.commonLinkTo1133({dddd: 'fundxxxxxxxxxxx1133'})
      };
    },
    async aaaa() {
      return new Promise((resolve, reject) => {
        resolve({ sss: "ssss" });
      });
    },
    prepareRender() {
      try {
        //检查fund api
        // ❌不能使用 if(fund)来判断 如果fund没有 js直接报错 代码不再向下运行
        console.log(fund);
        console.log("window.fund");
        console.log(window.fund);
        this.render();
      } catch (error) {
        HtmlWindow.addListener("fundJSBridgeReady", () => {
          this.render();
        });
      }
    },
    render() {
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
.bottom {
  position: fixed;
  left: 0;
  bottom: 0;
  width: 100%;
  height: 50px;
  background-color: orange;
}
</style>
