import JS from "./JSTool.js"

//格式化转发正文所需的关键词
class NewsFormatPostKeyWords {

    // getPostKeyWords(articleData) {
    //     var postKeyWordList = [];
    //     const data = articleData;
    //     if (
    //         data != null &&
    //         data.extend != null &&
    //         data.extend.FundTags != null &&
    //         data.extend.FundTags.ContentTags &&
    //         data.extend.FundTags.ContentTags.length > 0
    //     ) {
    //         for (var i = 0; i < data.extend.FundTags.ContentTags.length; i++) {
    //             const contentTag = data.extend.FundTags.ContentTags[i];
    //             var postKeyWord = {};
    //             let { Code, BusType, Name, AppUrl } = contentTag;
    //             postKeyWord = Object.assign(postKeyWord, {
    //                 code: contentTag.Code[0],
    //                 type: contentTag.BusType,
    //                 name: contentTag.Name,
    //                 picUrl: ""
    //             });
    //             //多次转发时需要包装关键字
    //             if (postKeyWord.type == 100) {
    //                 //100、查看图片
    //                 if (contentTag.AppUrl != null && contentTag.AppUrl.LinkTo != null) {
    //                     const linkto = contentTag.AppUrl.LinkTo;
    //                     const picUrl = this.getParamFromUrl(linkto, "src");
    //                     if (picUrl.length > 0) {
    //                         postKeyWord.picUrl = picUrl;
    //                     }
    //                 }
    //             }
    //             postKeyWordList.push(postKeyWord);
    //         }
    //     }
    //     console.log("getPostKeyWords step1");
    //     //6.2.0 股吧接口对应字段转换为人名关键字
    //     if (data.post_atuser != null) {
    //         var gubaUserKeyWords = this.handleGubaUserKeyWord(
    //             data.post_content,
    //             data.post_atuser
    //         );
    //         postKeyWordList = postKeyWordList.concat(gubaUserKeyWords);
    //     }
    //     console.log("getPostKeyWords step2");
    //     //6.2.0 股吧接口对应字段转换为话题关键字
    //     if (data.extend != null && data.extend.FundTopicPost != null) {
    //         var gubaTopicKeyWords = this.handleGubaTopicKeyWord(
    //             data.post_content,
    //             data.extend.FundTopicPost
    //         );
    //         postKeyWordList = postKeyWordList.concat(gubaTopicKeyWords);
    //     }
    //     console.log("getPostKeyWords step3");
    //     //6.2.0 股吧接口 图片关键字
    //     if (data.post_pic_url2 != null && data.post_pic_url2.length > 0) {
    //         var gubaImageWords = this.handleGubaImageKeyWord(
    //             data.post_content,
    //             data.post_pic_url2
    //         );
    //         postKeyWordList = postKeyWordList.concat(gubaImageWords);
    //     }
    //     console.log("getPostKeyWords step4");
    //     //股吧620 转发帖 需要将用户添加图片 转换为对应关键字
    //     if (data.post_pic_url != null && data.post_pic_url.length > 0) {
    //         if (data.source_post_id != 0) {
    //             const pic_url = data.post_pic_url[0];
    //             var postKeyWord = {};
    //             postKeyWord = Object.assign(postKeyWord, {
    //                 picUrl: pic_url,
    //                 type: 100, //100、查看图片
    //                 name: "查看图片"
    //             });
    //             postKeyWordList.push(postKeyWord);
    //         }
    //     }
    //     console.log("getPostKeyWords step5");
    //     //转发时添加用户名信息对应的关键字
    //     if (
    //         data.source_post_id != 0 &&
    //         data.post_user != null &&
    //         data.post_user.user_id != null &&
    //         data.post_user.user_nickname != null
    //     ) {
    //         //添加用户关键词
    //         var postKeyWord = {};
    //         postKeyWord = Object.assign(postKeyWord, {
    //             code: data.post_user.user_id,
    //             type: 19, //19为用户
    //             name: "@" + data.post_user.user_nickname
    //         });
    //         postKeyWordList.push(postKeyWord);
    //     }
    //     console.log("getPostKeyWords step6");
    //     return postKeyWordList;
    // }
    foramtSourceKeyWord(formatArticle) {
        var sourceKeyWordList = [];

        if (
            formatArticle != null &&
            formatArticle.sourcePost.fundTags &&
            formatArticle.sourcePost.fundTags.length > 0
        ) {
            for (var i = 0; i < formatArticle.sourcePost.fundTags.length; i++) {
                const contentTag = formatArticle.sourcePost.fundTags[i];
                var postKeyWord = {};
                postKeyWord = Object.assign(postKeyWord, {
                    code: contentTag.code[0],
                    type: contentTag.busType,
                    name: contentTag.name,
                    picUrl: ""
                });
                sourceKeyWordList.push(postKeyWord);
            }
        }
        return sourceKeyWordList;
    }
    getPostKeyWords(formatArticle) {
        var postKeyWordList = [];

        if (
            formatArticle != null &&
            formatArticle.fundTags &&
            formatArticle.fundTags.length > 0
        ) {
            for (var i = 0; i < formatArticle.fundTags.length; i++) {
                const contentTag = formatArticle.fundTags[i];
                var postKeyWord = {};
                postKeyWord = Object.assign(postKeyWord, {
                    code: contentTag.code[0],
                    type: contentTag.busType,
                    name: contentTag.name,
                    picUrl: ""
                });
                //多次转发时需要包装关键字
                if (postKeyWord.type == 100) {
                    //100、查看图片
                    if (contentTag.appUrl != null && contentTag.appUrl.linkTo != null) {
                        const linkto = contentTag.appUrl.linkTo;
                        const picUrl = this.getParamFromUrl(linkto, "src");
                        if (picUrl.length > 0) {
                            postKeyWord.picUrl = picUrl;
                        }
                    }
                }
                postKeyWordList.push(postKeyWord);
            }
        }
        // console.log("getPostKeyWords step1");
        //6.2.0 股吧接口对应字段转换为人名关键字
        if (formatArticle.atUser != null) {
            var gubaUserKeyWords = this.handleGubaUserKeyWord(
                formatArticle.content,
                formatArticle.atUser
            );
            postKeyWordList = postKeyWordList.concat(gubaUserKeyWords);
        }
        // console.log("getPostKeyWords step2");
        //6.2.0 股吧接口对应字段转换为话题关键字
        if (formatArticle.extend != null && formatArticle.fundTopicPost != null) {
            var gubaTopicKeyWords = this.handleGubaTopicKeyWord(
                formatArticle.content,
                formatArticle.fundTopicPost
            );
            postKeyWordList = postKeyWordList.concat(gubaTopicKeyWords);
        }
        // console.log("getPostKeyWords step3");
        //6.2.0 股吧接口 图片关键字
        if (formatArticle.picUrl2 != null && formatArticle.picUrl2.length > 0) {
            var gubaImageWords = this.handleGubaImageKeyWord(
                formatArticle.content,
                formatArticle.picUrl2
            );
            postKeyWordList = postKeyWordList.concat(gubaImageWords);
        }
        // console.log("getPostKeyWords step4");
        //股吧620 转发帖 需要将用户添加图片 转换为对应关键字
        if (formatArticle.picUrl != null && formatArticle.picUrl.length > 0) {
            if (formatArticle.sourcePost.Id != '') {
                const pic_url = formatArticle.picUrl[0];
                var postKeyWord = {};
                postKeyWord = Object.assign(postKeyWord, {
                    picUrl: pic_url,
                    type: 100, //100、查看图片
                    name: "查看图片"
                });
                postKeyWordList.push(postKeyWord);
            }
        }
        // console.log("getPostKeyWords step5");
        //转发时添加用户名信息对应的关键字
        if (
            formatArticle.sourcePost.Id != '' &&
            formatArticle.user != null &&
            formatArticle.user.userId != null &&
            formatArticle.user.userName != null
        ) {
            //添加用户关键词
            var postKeyWord = {};
            postKeyWord = Object.assign(postKeyWord, {
                code: formatArticle.user.userId,
                type: 19, //19为用户
                name: "@" + formatArticle.user.userName
            });
            postKeyWordList.push(postKeyWord);
        }
        // console.log("getPostKeyWords step6");
        return postKeyWordList;
    }
    getParamFromUrl(url, name) {
        var param = "";
        const splits = url.split("\\&");
        if (splits.length > 0) {
            for (var j = 0; j < splits.length; j++) {
                const paramStr = splits[j];
                if (paramStr.indexOf(name + "=") != -1) {
                    param = paramStr.substring(
                        paramStr.indexOf(name) + name.length + 1
                    );
                }
            }
        }
        return param;
    }
    handleGubaUserKeyWord(content, list) {
        var postKeyWordList = [];
        let atagUserRegex = new RegExp(
            '<a href="fund://page/personalhome?(.*?)[\'"]>(.*?)</a>',
            "g"
        );

        content.replace(atagUserRegex, function (match, group, offset, string) {
            for (var i = 0; i < list.length; i++) {
                const postAtuser = list[i];
                if (group != null) {
                    const arr = group.split("=");
                    if (arr[1] != null) {
                        if (arr[1] == postAtuser.user_id) {
                            var postKeyWord = {};
                            postKeyWord = Object.assign(postKeyWord, {
                                code: postAtuser.user_id,
                                type: 19, //19为用户
                                name: "@" + postAtuser.user_nickname
                            });
                            postKeyWordList.push(postKeyWord);
                        }
                    }
                }
            }
        });
        return postKeyWordList;
    }
    handleGubaTopicKeyWord(content, list) {
        var postKeyWordList = [];
        let atagTopicRegex = new RegExp(
            "<a href=.*?HotTopicDetailPage?(.*?)['\"].*?>(.*?)</a>",
            "g"
        );

        content.replace(atagTopicRegex, function (match, group, offset, string) {
            for (var i = 0; i < list.length; i++) {
                const fundTopic = list[i];
                if (group != null) {
                    const arr = group.split("=");
                    if (arr[1] != null) {
                        if (arr[1] == fundTopic.htid) {
                            var postKeyWord = {};
                            postKeyWord = Object.assign(postKeyWord, {
                                code: fundTopic.htid,
                                type: 18, //18、话题
                                name: "#" + fundTopic.name + "#"
                            });
                            postKeyWordList.push(postKeyWord);
                        }
                    }
                }
            }
        });
        return postKeyWordList;
    }
    handleGubaImageKeyWord(content, list) {
        var postKeyWordList = [];
        let atagImageRegex = new RegExp("<img src=['\"](.*?)['\"].*?>", "g");

        content.replace(atagImageRegex, function (match, group, offset, string) {
            for (var i = 0; i < list.length; i++) {
                const picUrl = list[i];
                if (group != null) {
                    if (group == picUrl) {
                        var postKeyWord = {};
                        postKeyWord = Object.assign(postKeyWord, {
                            picUrl: picUrl,
                            type: 100, //100、查看图片
                            name: "查看图片"
                        });
                        postKeyWordList.push(postKeyWord);
                    }
                }
            }
        });
        return postKeyWordList;
    }
}

export default new NewsFormatPostKeyWords();