
import Vue from 'vue';
import JSTool from "./JSTool.js";
import HtmlWindow from "./HtmlWindow.js"

class HtmlStorage {
    static KeyMap = (function () {
        const map = {
            scrollOffSetY: 'scrollOffSetY'
        }
        const appIdentifier = 'com.eastmoney.ttjj-newsweb-'
        let res = {}
        for (const key in map) {
            if (map.hasOwnProperty(key)) {
                const el = map[key];
                res[key] = `${appIdentifier}${el}`
            }
        }
        return res
    }())
    offSetYKey(Id){
        if (!JSTool.isString(Id) || !Id) {
            return null
        }
        return `${HtmlStorage.KeyMap.scrollOffSetY}-${Id}`
    }
    setScrollOffSetYStorage(Id) {
        const offY = HtmlWindow.pageYOffset();
        this.setLocalStorage(this.offSetYKey(Id), offY)
    }
    getScrollOffSetYStorage(Id) {
        const res = this.getLocalStorage(this.offSetYKey(Id))
        return JSTool.isNumber(res) ? res : 0;
    }

    setLocalStorage(key, value, timeOut = 0) {
        if (!JSTool.isString(key) || !key || !value) {
            return
        }
        //当前时间
        const curTime = new Date().getTime();
        let newTimeOut = timeOut
        //默认时效一天
        if (newTimeOut == 0) {
            newTimeOut = 24 * 60 * 60 * 1000
        }
        //截止日期
        const limitTime = curTime + newTimeOut

        let newValue = {
            data: value,
            timeOut: limitTime
        };
        //存储
        HtmlWindow.localStorage().setItem(key, JSON.stringify(newValue));
    }
    getLocalStorage(key) {
        if (!JSTool.isString(key) || !key) {
            return null
        }
        const fetchData = HtmlWindow.localStorage().getItem(key)
        if (!JSTool.isString(fetchData)) {
            return null
        }
        let value = JSON.parse(fetchData);

        const timeOut = value.timeOut

        //数据超时 无效
        if (timeOut < new Date().getTime()) {
            return null
        }
        return value.data
    }
}
export default new HtmlStorage();