
<template>
  <!--  用户身份等级头像组件
    用法
            <ImgIconLevel 
            :iconSrc="''"
            :size="34"
            :userLevel="2"/>

    参数  userLevel: 0 不显示
                    1 机构vip
                    2 个人vip
  -->
  <div
    class="wrap"
    @click="clickWrap"
    :style="{
      'width': size + 2+'px', 
      'height': size + 2+'px'}"
  >
    <ImgHolder
      :style="{
      'border-radius': size * 0.5 + 'px', 'border-width': '1px','border-color': borderColor ,'border-style':'solid'}"
      :iconHolderSrc="holderSrc"
      :iconSrc="iconSrc"
      :width="size"
      :height="size"
    />
    <img v-if="userLevelShow" class="icon-flag" :src="userLevelSrc" alt />
  </div>
</template>

<script>
import ImgHolder from "./img-holder.vue";
import HolderSrc from "@/assets/article/header-placholder.png";
import vip_organization from "@/assets/article/vip_organization.png";
import vip_personal from "@/assets/article/vip_personal.png";
export default {
  props: {
    iconSrc: {
      type: String,
      required: true,
      default: function() {
        return "";
      }
    },
    size: {
      type: Number,
      required: true,
      default: function() {
        return 0;
      }
    },
    UserGender: {
      type: Number,
      required: true,
      default: function() {
        return 0;
      }
    },
    userLevel: {
      type: Number,
      required: true,
      default: function() {
        return 0;
      }
    }
  },
  components: {
    ImgHolder
  },
  data() {
    return {
      holderSrc: HolderSrc,
      userLevelShow: false,
      userLevelSrc: "",
      borderColor: "#ffffff"
    };
  },
  watch: {
    userLevel: function(val, oldVal) {
      this.handleLevelSrc();
    },
    UserGender: function(val, oldVal) {
      this.handleGender();
    },
  },
  created() {
    this.handleLevelSrc();
  },
  mounted() {},
  methods: {
    handleLevelSrc() {
      const level = parseInt(this.userLevel);
      let res = "";
      if (level == 1) {
        res = vip_organization;
      } else if (level == 2) {
        res = vip_personal;
      }

      this.userLevelShow = level != 0;
      this.userLevelSrc = res;
      // console.log("handleLevelSrc "+ this.userLevelSrc);
    },
    handleGender() {
 
      if(this.UserGender == 1)
      this.borderColor = "#388CFF"
      else if(this.UserGender == 2)
      this.borderColor = "#FF386F"
      // console.log("handleGender  "+ this.UserGender) 
    },
    clickWrap() {
        this.$emit("click");
    }
  }
};
</script>

<style lang="scss" scoped>
.wrap {
  display: inline-block;
  overflow: hidden;
  flex-shrink: 0;
  position: relative;
}
.icon-flag {
  position: absolute;
  bottom: 0;
  right: 0;
  display: block;
  width: 14px;
  height: 14px;
  border-radius: 7px;
  border: 1px solid #ffffff;
}
</style>
