
import Vue from 'vue';
import JSTool from "./JSTool.js";
import smoothscroll from 'smoothscroll-polyfill';
// kick off the polyfill!
smoothscroll.polyfill();

/**
 clientTop: 容器内部相对于容器本身的top偏移，== border-top-width
 clientWidth: 容器的窗口宽度【padding-left + width + padding-right】

 scrollTop、scrollLeft: 滚动容器 滚动的偏移量[真实内容超出padding外层的部分]
 scrollWidth：滚动容器【padding-left + 滚动内容width + padding-right】

 offsetTop: 该元素的boder外层 到 父元素的boder内层
 offsetWidth: 【border-left-width + padding-left + width + padding-right + border-right-width】
 */

// 为html注入全局方法
class HtmlWindow {
    static scrollEvents = []

    configWindowEvent() {
        //监听滚动事件
        window.onscroll = e => {
            const scrollEvents = HtmlWindow.scrollEvents;
            try {
                scrollEvents.forEach(el => {
                    if (el) el(e)
                });
            } catch (error) {
                console.log('postScrollEvents-error')
                console.log(error)
            }
        };
    }
    registerScrollEvent(func) {
        if (!JSTool.isFunction(func)) {
            return false
        }
        HtmlWindow.scrollEvents.push(func)
    }


    getElementById(Id) {
        if (!JSTool.isString(Id) || !Id) return null;
        return window.document.getElementById(Id)
    }
    queryHeader() {
        return this.querySelector('head')
    }
    querySelector(Id) {
        if (!JSTool.isString(Id) || !Id) return null;
        return window.document.querySelector(Id)
    }
    appendBodyChild(dom) {
        window.document.body.appendChild(dom)
    }
    createFragment() {
        return window.document.createDocumentFragment()
    }
    localStorage() {
        return window.localStorage
    }
    addListener(event, func) {
        window.addEventListener(event, func);
    }

    //获取style
    getStyle(dom) {
        return window.getComputedStyle(dom, null);
    }
    getPropertyValue(dom, key) {
        return this.getStyle(dom).getPropertyValue(key)
    }

    //元素大小相关
    pageYOffset() {
        return window.pageYOffset
    }
    //元素相对body的原点的位置
    pointInBody(dom) {
        let l = 0, t = 0;
        while (dom) {
            l = l + dom.offsetLeft + dom.clientLeft;
            t = t + dom.offsetTop + dom.clientTop;
            dom = dom.offsetParent;
        }
        return { left: l, top: t };
    }
    //元素相对当前窗口的位置
    clientRect(dom) {
        // top 包含 margin 不包含 border padding
        // left 包含 margin 不包含 border padding
        // width 不包含 margin 包含 border padding
        // height 不包含 margin 包含 border padding
        return dom.getBoundingClientRect()
    }
    clientRealRect(dom) {
        const removePx = (num) => {
            let res = num.toString();
            if (res.indexOf('px') != -1) {
                res = res.replace(/px/g, '')
            }
            return parseFloat(res)
        }
        const styleValue = (key) => {
            return removePx(this.getPropertyValue(dom, key))
        }
        const domRect = this.clientRect(dom);
        return {
            top: domRect.top + styleValue('border-top-width') + styleValue('padding-top'),
            bottom: domRect.bottom + styleValue('border-bottom-width') + styleValue('padding-bottom'),
            left: domRect.left + styleValue('border-left-width') + styleValue('padding-left'),
            right: domRect.right - styleValue('border-right-width') + styleValue('padding-right'),
            width: domRect.width - styleValue('border-left-width') - styleValue('border-right-width') - styleValue('padding-left') - styleValue('padding-right'),
            height: domRect.height - styleValue('border-top-width') - styleValue('border-bottom-width') - styleValue('padding-top') - styleValue('padding-bottom')
        }
    }
    //window body 的宽高
    client() {
        // ie9 +  最新浏览器
        if (window.innerWidth != null) {
            return {
                width: window.innerWidth,
                height: window.innerHeight
            }
        }
        // 标准浏览器
        else if (document.compatMode === "CSS1Compat") {
            return {
                width: document.documentElement.clientWidth,
                height: document.documentElement.clientHeight
            }
        }
        // 怪异模式
        return {
            width: document.body.clientWidth,
            height: document.body.clientHeight
        }
    }

    //滚动相关
    scrollToOffsetY(y, animate = false) {
        window.scroll({ top: y, behavior: animate ? 'smooth' : 'auto' })
        // window.document.body.scrollTop = y;
    }
    // https://blog.csdn.net/qq_35366269/article/details/97236793
    //滚动元素到顶部
    scrollDomToTopById(domId, animate = true) {
        this.scrollDomById(domId, 'start', 'nearest', animate)
    }
    //滚动元素到底部
    scrollDomToBottomById(domId, animate = true) {
        this.scrollDomById(domId, 'end', 'nearest', animate)
    }
    scrollDomById(domId, verticalAlign = "start", horizontalAlign = "nearest", animate = true) {
        if (!JSTool.isString(domId) || !domId) return;
        const dom = this.getElementById(domId)
        if (!dom) return;
        // verticalAlign : "start", "center", "end", "nearest"[默认值]
        // horizontalAlign : "start", "center", "end", "nearest"[默认值]
        dom.scrollIntoView({
            block: verticalAlign,
            behavior: animate ? "smooth" : "auto", //"instant"
            inline: horizontalAlign
        })
    }
}
export default new HtmlWindow();