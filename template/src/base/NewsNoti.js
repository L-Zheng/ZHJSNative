
import Vue from 'vue';
import JSTool from "./JSTool.js";

class NewsNoti {
  static notiMap = {
  }
  //   static eventBus = new Vue();
  //   // eventBus.$emit
  // // eventBus.$on

  reg(key, action) {
    //容错
    if (!key || !JSTool.isString(key)) {
      return false
    }
    if (!JSTool.isFunction(action)) {
      return false
    }

    let map = NewsNoti.notiMap
    let actions = []

    const keys = Object.keys(map)
    if (keys.indexOf(key) == -1) {
      actions = [action]
    } else {
      actions = map[key]
      actions.push(action)
    }
    map[key] = actions
    NewsNoti.notiMap = map
  }
  remove(key, action) {
    //容错
    if (!key || !JSTool.isString(key)) {
      return false
    }
    if (!JSTool.isFunction(action)) {
      return false
    }

    let map = NewsNoti.notiMap

    const keys = Object.keys(map)
    if (keys.indexOf(key) == -1) return;

    let actions = map[key];
    const targetIndex = actions.indexOf(action);
    if (targetIndex == -1) return;
    actions.splice(targetIndex, 1)

    map[key] = actions
    NewsNoti.notiMap = map
  }
  post(key, parmas) {
    //容错
    if (!key || !JSTool.isString(key)) {
      return false
    }

    let map = NewsNoti.notiMap
    const keys = Object.keys(map)
    if (keys.indexOf(key) == -1) {
      return
    }
    const actions = map[key]
    actions.forEach(el => {
      if (JSTool.isFunction(el)) {
        try {
          el(parmas)
        } catch (error) {
          console.log(error)
        }
      }
    });
  }
}
export default new NewsNoti();