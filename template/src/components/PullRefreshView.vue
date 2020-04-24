<template>
  <div
    :class="['pull-refresh', `''`]"
    :style="{
      'margin-top': moveDistance - limitH + 'px',
      transition: transitionDuration + 'ms',
      }"
    @touchstart="touchStart"
    @touchmove="touchMove"
    @touchend="touchEnd"
  >
    <div class="pull-refreshing-box"
    :style="{
      height: limitH + 'px',
      }"
    >
      <div v-if="moveState < 2">{{ moveState === 0 ? '下拉即可刷新...' : '释放即可刷新...' }}</div>
      <div v-else>
        <i class="weui-loading" /> 加载中...
      </div>
    </div>
    <div>
      <slot />
    </div>
  </div>
</template>

<script>
export default {
  props: {},
  data() {
    return {
      limitH: 50,
      startY: '',
      moveDistance: 0,
      moveState: 0, // 0:下拉即可刷新 1:释放即可刷新 2:加载中
      transitionDuration: 0, // 动画时间
    };
  },
  watch: {
  },
  computed: {
  },
  methods: {
    touchStart(e) {
      this.moveDistance = 0;
      this.startY = e.targetTouches[0].clientY;
    },
    touchMove(e) {
      const scrollTop = document.documentElement.scrollTop || document.body.scrollTop;

      // 向上有偏移量 不能下拉刷新
      if (scrollTop > 0) return;

      const move = e.targetTouches[0].clientY - this.startY;
      if (move > 0) {
        // 阻止默认事件，在微信浏览器中有用，。
        e.preventDefault();
        // 增加滑动阻力
        // eslint-disable-next-line no-restricted-properties
        this.moveDistance = Math.pow(move, 0.8);
        this.moveState = this.moveDistance > this.limitH ? 1 : 0;
      }
    },
    touchEnd(e) {
      console.log(e);
      if (this.moveDistance > this.limitH) {
        this.moveState = 2;
        this.animation(this.limitH);

        this.$emit('refresh', () => {
          this.moveState = 0;
          this.animation(0);
        });
      } else {
        this.animation(0);
      }
    },
    animation(y, duration = 300) {
      this.moveDistance = y;
      this.transitionDuration = duration;
      setTimeout(() => {
        this.transitionDuration = 0;
      }, duration);
    },
  },
};
</script>
<style scoped lang="scss">
.pull-refresh {
  height: 100%;
  width: 100%;
  .pull-refreshing-box {
    display: flex;
    flex-direction: column;
    justify-content: center;
    background-color: cyan;
    font-size: 14px;
    color: rgba(69, 90, 100, 0.6);
    text-align: center;
  }
}
</style>
