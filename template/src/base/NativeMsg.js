
import Vue from 'vue';
import JSTool from "./JSTool.js";

class NativeMsg {
  static msgMap = {
  }
  reg(key, action) {
    //容错
    if (!key || !JSTool.isString(key)) {
      return false
    }
    if (!JSTool.isFunction(action)) {
      return false
    }

    let map = NativeMsg.msgMap
    let actions = []

    const keys = Object.keys(map)
    if (keys.indexOf(key) == -1) {
      actions = [action]
    } else {
      actions = map[key]
      actions.push(action)
    }
    map[key] = actions
    NativeMsg.msgMap = map
  }
  post(parmas) {
    let jsonData = decodeURIComponent(parmas);
    if (JSTool.isString(jsonData)) {
      jsonData = JSON.parse(jsonData);
    }
    if (!JSTool.isObject(jsonData)) {
      jsonData = {};
    }
    const key = JSTool.fetchString(jsonData, "key");
    const value = jsonData.value;

    //容错
    if (!key || !JSTool.isString(key)) {
      return false
    }

    let map = NativeMsg.msgMap
    const keys = Object.keys(map)
    if (keys.indexOf(key) == -1) {
      return
    }
    const actions = map[key]
    actions.forEach(el => {
      if (JSTool.isFunction(el)) {
        try {
          el(value)
        } catch (error) {
          console.log(error)
        }
      }
    });
  }
}
export default new NativeMsg();