import Vue from 'vue'
import App from './App.vue'
// import store from './store'
import md5 from 'js-md5';
Vue.prototype.$md5 = md5;
Vue.config.productionTip = false

new Vue({
  render: h => h(App),
}).$mount('#app')
