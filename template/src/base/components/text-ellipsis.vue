
<template>
  <!-- <span class="text-ellipsis-wrap"> -->
    <span class="text-ellipsis-desc"
    ref="sssssss"
    :style="{'line-clamp': lines, 
    '-webkit-line-clamp': lines,
    'line-height': lineHeight + 'px'}"
    >啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊啊
     <span v-if="isShowMore" class="flag-wrap">...啦啦</span> 
     </span>
</template>

<style lang="scss" scoped>
.text-ellipsis-desc {
  padding: 0px;
  position: relative;
  display: -webkit-box;
  overflow: hidden;
  text-overflow: ellipsis;
  -ms-text-overflow: ellipsis;
//   line-clamp: 1;
//   -webkit-line-clamp: 1;
  -webkit-box-orient: vertical;
//   text-align: justify;
}
.flag-wrap {
    background-color: green;
  position: absolute;
  right: 0;
  bottom: 0;
  color: blue;
}
</style>


<script>
import JSTool from "../JSTool.js";
import HtmlWindow from "../HtmlWindow.js";
export default {
  props: {
    lineHeight: {
      type: Number,
      required: true,
      default: function() {
        return 18;
      }
    },
    lines: {
      type: Number,
      required: true,
      default: function() {
        return 0;
      }
    }
  },
  data() {
    return {
      showHeightPx: "auto",
      isShowMore: false
    };
  },
  watch: {
    lineHeight: function(val, oldVal) {
      this.handle();
    },
    lines: function(val, oldVal) {
      this.handle();
    }
  },
  created() {
    this.handle();
  },
  mounted() {},
  methods: {
    handle() {
      //高度
      if (this.lines == 0) return;
      const height = this.lines * this.lineHeight;

        const textDom = document.querySelector(".text-ellipsis-desc");
        console.log("sfdgfewefwe");
console.log(this.$refs.sssssss)
        console.log(textDom);
        const dis = textDom.scrollHeight - textDom.clientHeight;
        console.log(textDom.scrollHeight);
        console.log(textDom.clientHeight);
        // this.isShowMore = dis > 0;
    },
    clickWrap() {
      this.$emit("click");
    }
  }
};
</script>