import JS from "./JSTool.js"

//格式化转发正文所需的内容   现阶段发帖原生页面 需要自己处理生成富文本 暂时将此步放到原生完成
class NewsFormatPostContent {

    // getPostContent(articleData) {
    //     const data = articleData;
        
    //     var shareContent = data.post_content;
    //     if(articleData.source_post_id == 0 || shareContent == '') {
    //         return '';
    //     }
    //     var replyKeyWordsBeanList = [];
    //     if (
    //         data != null &&
    //         data.extend != null &&
    //         data.extend.FundTags != null &&
    //         data.extend.FundTags.ContentTags &&
    //         data.extend.FundTags.ContentTags.length > 0
    //     ) {
    //         const contentKeyWordsList = data.extend.FundTags.ContentTags;
    //         for (var i = 0; i < contentKeyWordsList.length; i++) {
    //             const contentKeyWord = contentKeyWordsList[i];
    //             var replyKeyWordsBean = {};
    //             if (
    //                 contentKeyWord.Name != null &&
    //                 !contentKeyWord.Name.startsWith("<img")
    //             ) {
    //                 replyKeyWordsBean = Object.assign(replyKeyWordsBean, {
    //                     Label: contentKeyWord.Name,
    //                     Text: contentKeyWord.Name,
    //                     AppUrl: contentKeyWord.AppUrl,
    //                     picUrl: ""
    //                 });
    //                 replyKeyWordsBeanList.push(replyKeyWordsBean);
    //             } else if (
    //                 contentKeyWord.Name != null &&
    //                 contentKeyWord.Name.startsWith("<img")
    //             ) {
    //                 shareContent = shareContent.replace(contentKeyWord.Name, "");
    //             }
    //         }
    //     }

    //     //6.2.0 股吧返回的a标签替换掉 直接显示@用户名
    //     shareContent = this.handleGubaATag(shareContent);

    //     //6.2.0 股吧返回的img标签替换为 查看图片
    //     if (data.post_pic_url2 != null && data.post_pic_url2.length > 0) {
    //         shareContent = this.handleGuBaImageText(shareContent, data.post_pic_url2);
    //     }

    //     //股吧620 转发帖 需要将用户添加图片显示为 查看图片 富文本
    //     if (data.post_pic_url != null && data.post_pic_url.length > 0) {
    //         if (data.source_post_id != 0) {
    //             var list = data.post_pic_url;
    //             const pic_url = list[0];
    //             shareContent += "查看图片";
    //         }
    //     }

    //     shareContent = this.handleFundBarReplyKeywords(shareContent, replyKeyWordsBeanList);

    //     //转发时添加用户名信息
    //     const nickName = this.formatArticle.user.userName;
    //     if (nickName != null && nickName != '') {
    //         shareContent = "//@" + nickName + "：" + shareContent;
    //     }

    // }
    getPostContent(formatArticle) {
        
        var shareContent = formatArticle.content;
        if(formatArticle.sourcePost.Id == '' || shareContent == '') {
            return '';
        }
        var replyKeyWordsBeanList = [];
        if (
            formatArticle != null &&
            formatArticle.fundTags &&
            formatArticle.fundTags.length > 0
        ) {
            const contentKeyWordsList = formatArticle.fundTags;
            for (var i = 0; i < contentKeyWordsList.length; i++) {
                const contentKeyWord = contentKeyWordsList[i];
                var replyKeyWordsBean = {};
                if (
                    contentKeyWord.name != null &&
                    !contentKeyWord.name.startsWith("<img")
                ) {
                    replyKeyWordsBean = Object.assign(replyKeyWordsBean, {
                        Label: contentKeyWord.name,
                        Text: contentKeyWord.name,
                        AppUrl: contentKeyWord.appUrl,
                        picUrl: ""
                    });
                    replyKeyWordsBeanList.push(replyKeyWordsBean);
                    // console.log("getPostContent replyKeyWordsBeanList: "+ JSON.stringify(replyKeyWordsBeanList));
                } else if (
                    contentKeyWord.name != null &&
                    contentKeyWord.name.startsWith("<img")
                ) {
                    shareContent = shareContent.replace(contentKeyWord.name, "");
                }
            }
        }
        // console.log("getPostContent step1"+ shareContent);
        //6.2.0 股吧返回的a标签替换掉 直接显示@用户名
        shareContent = this.handleGubaATag(shareContent);
        // console.log("getPostContent step2"+shareContent);
        //6.2.0 股吧返回的img标签替换为 查看图片
        if (formatArticle.picUrl2 != null && formatArticle.picUrl2.length > 0) {
            shareContent = this.handleGuBaImageText(shareContent, formatArticle.picUrl2);
        }
        // console.log("getPostContent step3"+shareContent);
        //股吧620 转发帖 需要将用户添加图片显示为 查看图片 富文本
        if (formatArticle.picUrl != null && formatArticle.picUrl.length > 0) {
            if (formatArticle.sourcePost.Id != '') {
                var list = formatArticle.picUrl;
                const pic_url = list[0];
                shareContent += "查看图片";
            }
        }
        // console.log("getPostContent step4"+shareContent);
        shareContent = this.handleFundBarReplyKeywords(shareContent, replyKeyWordsBeanList);
        // console.log("getPostContent step5"+shareContent);
        //转发时添加用户名信息
        const nickName = formatArticle.user.userName;
        if (nickName != null && nickName != '') {
            shareContent = "//@" + nickName + "：" + shareContent;
        }
        // console.log("getPostContent step6"+shareContent);
        return shareContent;
    }    
    handleGubaATag(content) {
        let atagRegex = new RegExp(
            "<a .*?href=['\"](.*?)['\"].*?>(.*?)</a>",
            "g"
        );

        content.replace(atagRegex, function (
            match,
            group,
            group2,
            offset,
            string
        ) {
            // console.log("handleGubaATag   match:"+match+" group:"+ group+ " group2:"+ group2+ " offset:"+ offset+ " string:"+ string);
            content = content.replace(match, group2);
        });

        return content;
    }
    handleGuBaImageText(content, list) {
        let imageTagRegex = new RegExp("<img src=['\"](.*?)['\"].*?>", "g");

        content = content.replace(imageTagRegex, "查看图片");
        return content;
    }
    handleFundBarReplyKeywords(content, list) {
        for (var i = 0; i < list.length; i++) {
            const keyWord = list[i];
            const regex = keyWord.Label;
            const replaceStr = keyWord.Text;
            content = content.replace(regex, replaceStr);
        }
        return content;
    }
}

export default new NewsFormatPostContent();