
<template>
  <!--  通用占位图img组件
  用法
        <ImgHolder 
        :iconHolderSrc="defaultImgUrl"
        :iconSrc="`https://gbres.dfcfw.com/Files/picture/20191226/6CAFBFD7729827B6AD486664F2CCA563_w720h1280.jpg`"
        :width="100" 
        :height="100"/>
  -->
  <div class="wrap"
    @click="clickWrap">
    <!-- 'background-size': `${width}px${' '}${height}px` -->
    <img
      class="icon"
      :style="{
      'background-color': '#ffffff00',
      'width': realWidth, 
      'height': realHeight,
      'background-repeat': 'no-repeat',
      'background-position': 'center center',
      'background-image': `url(${iconHolderSrc ? iconHolderSrc : defaultImgUrl})`,
      'background-size': `100%`}"
      :src="`${iconSrc ? iconSrc : (iconHolderSrc ? iconHolderSrc : defaultImgUrl)}`"
      alt
    />
    <!-- 默认图情况下也要设置src 否则浏览器检测到img src为空时 自动为img标签加上边框 -->
  </div>
</template>

<script>
import defaultImgUrl from "../../assets/article/header-placholder.png";
import JSTool from "../JSTool.js";
export default {
  props: {
    iconSrc: {
      type: String,
      required: true,
      default: function() {
        return "";
      }
    },
    iconHolderSrc: {
      type: String,
      required: true,
      default: function() {
        return defaultImgUrl;
      }
    },
    width: {
      type: Number,
      required: true,
      default: function() {
        return null;
      }
    },
    height: {
      type: Number,
      required: true,
      default: function() {
        return null;
      }
    }
  },
  data() {
    return {
      defaultImgUrl: defaultImgUrl,
      realWidth: 0,
      realHeight: 0
    };
  },
  watch: {
    width: function(val, oldVal) {
      this.handleSize();
    },
    height: function(val, oldVal) {
      this.handleSize();
    }
  },
  created() {
    this.handleSize();
  },
  mounted() {},
  methods: {
    handleWH(wh) {
      const isPercent = JSTool.isString(wh) && wh && wh.indexOf("%") != -1;
      const isNumber = JSTool.isNumber(wh);
      return isPercent ? wh : isNumber ? wh + "px" : "0px";
    },
    handleSize() {
      const width = this.width;
      const height = this.height;

      const isWidthNull = JSTool.isNull(width)
      const isHeightNull = JSTool.isNull(height)

      this.realWidth = isWidthNull ? (isHeightNull ? "100%" : "auto") : this.handleWH(width);
      this.realHeight = isHeightNull ? "auto" : this.handleWH(height);

      // if (isWidthNull && isHeightNull) {
      //   this.realWidth = "100%";
      //   this.realHeight = "auto";
      //   return;
      // }
      // if (isWidthNull && !isHeightNull) {
      //   this.realWidth = "auto";
      //   this.realHeight = this.handleWH(height);
      //   return;
      // }
      // if (!isWidthNull && isHeightNull) {
      //   this.realWidth = this.handleWH(width);
      //   this.realHeight = "auto";
      //   return;
      // }
      // if (!isWidthNull && !isHeightNull) {
      //   this.realWidth = this.handleWH(width);
      //   this.realHeight = this.handleWH(height);;
      // }
    },
    clickWrap() {
        this.$emit("click");
    }
  }
};
</script>

<style lang="scss" scoped>
.wrap {
  // display: inline-block;
  overflow: hidden;
  flex-shrink: 0;
}
.icon {
  // img是一种类似text的元素，在结束的时候，会在末尾加上一个空白符，所以就会多出3px
  // 解决：设置vertical-align: middle   or  设置 display: block
  vertical-align: middle;
}
</style>
