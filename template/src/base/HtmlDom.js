import JSTool from "./JSTool.js"
import HtmlWindow from "./HtmlWindow.js"

class HtmlDom {
    constructor() { }

    //string转Dom
    parseHeadElement(htmlString) {
        return new DOMParser().parseFromString(htmlString, 'text/html').head.childNodes
        // return new DOMParser().parseFromString(htmlString, 'text/html').body
    }
    parseBodyElement(htmlString) {
        return new DOMParser().parseFromString(htmlString, 'text/html').body.childNodes
    }
    appendCSSDom(dom) {
        if (dom.nodeType) {
            const fragment = HtmlWindow.createFragment()
            fragment.appendChild(dom);
            HtmlWindow.queryHeader().appendChild(fragment);
        }
    }
    // csss = ['article/risk-tip.css'];
    appendCSSs(csss) {
        if (csss.length == 0) {
            return
        }
        csss.forEach(el => {
            var link = document.createElement('link');
            link.rel = 'stylesheet'
            link.charset = "UTF-8"
            link.href = el
            this.appendCSSDom(link)
        });
    }

    async appendScriptDom(dom) {
        return new Promise((resolve, reject) => {
            if (dom.nodeType) {
                dom.onload = () => {
                    // console.log('appendScriptDom-onload')
                    resolve();
                };
                dom.onerror = (error) => {
                    // console.log('appendScriptDom-error')
                    // console.log(error)
                    reject();
                };
                HtmlWindow.appendBodyChild(dom)
            } else {
                reject();
            }
        })
    }
    async appendScriptContent(content) {
        var script = document.createElement('script');
        script.type = 'text/javascript'
        script.innerHTML = content
        script.charset = "UTF-8"
        return await this.appendScriptDom(script)
    }
    async appendScriptSrc(src) {
        var script = document.createElement('script');
        script.type = 'text/javascript'
        script.src = src
        script.charset = "UTF-8"
        return await this.appendScriptDom(script)
    }
    async appendChildDom  (sourceNode, domString, domInsertFinish, domRenderFinish) {
        if (!JSTool.isString(domString)) {
            return
        }
    
        let newDomString = domString
    
        //匹配正文中的script、link标签（视频正文带有）
        let scripts = []
        let links = []
    
        let reg = ''
        //匹配link
        reg = new RegExp('(<link.*?/>)', "g");
        newDomString = newDomString.replace(reg, function (word) {
            links.push(word)
            return ''
        });
    
        //匹配script
        reg = new RegExp('(<script.*?</script>)', "g");
        newDomString = newDomString.replace(reg, function (word) {
            scripts.push(word)
            return ''
        });
    
        let nodes = []
        //解析节点
        nodes = this.parseBodyElement(newDomString)
        if (nodes.length == 0) {
            return;
        }
        const el = nodes[0]
    
        // nodes.forEach(el => {
        if (el.nodeType) {
            var observer = new MutationObserver(mutations => {
                if (document.contains(el)) {
                    if (domRenderFinish) {
                        domRenderFinish(el);
                    }
                    observer.disconnect();
                }
            });
            const config = { attributes: false, childList: true, characterData: false, subtree: true };
            observer.observe(document, config);
    
            sourceNode.appendChild(el)
            if (domInsertFinish) {
                await domInsertFinish(links, scripts)
            }
        }
        // });
    }
}
export default new HtmlDom();