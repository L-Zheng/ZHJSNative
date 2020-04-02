import commonUrl from "@/base/url.js";

//公共参数
function mCommonParams() {
    const Info = fund.getUserInfoSync();
    const userInfo = Info.userInfo;
    return {
        deviceid: userInfo.deviceid,
        plat: userInfo.plat,
        serverversion: userInfo.serverversion,
        version: userInfo.appv,
        appVersion: userInfo.appv,
    }
}
//json参数转换string
function mParamToStr(params) {
    if (Object.prototype.toString.call(params) == '[object Object]') {
        const arr = [];
        for (const key in params) {
            const el = params[key];
            arr.push(`${key}=${el}`)
        }
        if (arr.length == 0) {
            return ''
        }
        return arr.join('&');
    }
    return params;
}
//需要公共参数的请求
function mFetch(url, header, data, method = 'GET') {
    let newData = Object.assign(data, mCommonParams())
    return mFetchInternal(url, header, newData, method, true)
}
//不需要公共参数的请求
function mFetchNoExtra(url, header, data, method = 'GET') {
    return mFetchInternal(url, header, data, method)
}
function mFetchInternal(url, header, data, method = 'GET') {
    return new Promise((resolve, reject) => {
        fund.request({
            url, //仅为示例，并非真实接口地址。
            method,
            header,
            data,
            success: (res) => {
                resolve(res);
            },
            fail: () => {
                reject();
            }
        });
    })
}

function fetchNews(data) {
    const Info = fund.getUserInfoSync();
    let userInfo = Info.userInfo;
    if (typeof userInfo == "string") {
        userInfo = JSON.parse(userInfo);
    }
    var fundversion = userInfo.appv,
        fundversion = fundversion.replace(/\./g, '');
    const nativeUrl = fund.getUrlConfigSync({
        remoteKey: "EastBarGuba",
        localKey: "EastBarGuba"
    });
    let url = nativeUrl + "reply/api/Reply/FundArticleReplyList";
    if (!data.showAllComment) {
        url = nativeUrl + "reply/api/Reply/ArticleNewAuthorOnly";
    }
    let method = "POST";
    let header = {
        "content-type": "application/x-www-form-urlencoded",
    };
    const common = {
        DeviceId: userInfo.deviceid,
        UserId: userInfo.uid,
        Plat: userInfo.plat,
        key: 'a8eb1746-1375-8def-b5e8-fe369ee73d68',
        uToken: userInfo.passportutokentrue,
        cToken: userInfo.passportctokentrue,
        gToken: userInfo.gtoken,
        OSVersion: userInfo.osv,
        appVersion: userInfo.appv,
        MarketChannel: userInfo.marketchannel,
        passportId: userInfo.passportid,
        MobileKey: userInfo.deviceid,
        product: 'Fund',
        version: fundversion
    }
    let newData = data;
    for (const key in common) {
        const el = common[key];
        newData[key] = el;
    }
    return new Promise((resolve, reject) => {
        fund.request({
            url, //仅为示例，并非真实接口地址。
            method,
            header,
            data: newData,
            success: (res) => {
                resolve(res);
            },
            fail: () => {
                reject();
            }
        });
    })
}
function likeComment(data) {
    const Info = fund.getUserInfoSync();
    let userInfo = Info.userInfo;
    if (typeof userInfo == "string") {
        userInfo = JSON.parse(userInfo);
    }
    let likeStatus = data.likeStatus;
    const nativeUrl = fund.getUrlConfigSync({
        remoteKey: "FundBarApiPro",
        localKey: "FundBarApiPro"
    });
    let url = nativeUrl + "community/action/LikeArticleReply";
    if (likeStatus) {
        //取消点赞
        url = nativeUrl + "community/action/cancellikearticlereply"
    }
    let method = "POST";
    let header = {
        "content-type": "application/x-www-form-urlencoded",
    };
    const common = {
        deviceid: userInfo.deviceid,
        userid: userInfo.uid,
        plat: userInfo.plat,
        key: 'a8eb1746-1375-8def-b5e8-fe369ee73d68',
        utoken: userInfo.utoken,
        ctoken: userInfo.ctoken,
        gtoken: userInfo.gtoken,
        osversion: userInfo.osv,
        appversion: userInfo.appv,
        marketchannel: userInfo.marketchannel,
        passportid: userInfo.passportid,
        mobileKey: userInfo.deviceid,
        product: 'EFund',
        version: userInfo.appv
    }
    let newData = data;
    for (const key in common) {
        const el = common[key];
        newData[key] = el;
    }
    return new Promise((resolve, reject) => {
        fund.request({
            url, //仅为示例，并非真实接口地址。
            method,
            header,
            data: newData,
            success: (res) => {
                resolve(res);
            },
            fail: () => {
                reject();
            }
        });
    })
}
function deleteCommentRequest(data, postUserId) {
    const Info = fund.getUserInfoSync();
    let userInfo = Info.userInfo;
    if (typeof userInfo == "string") {
        userInfo = JSON.parse(userInfo);
    }
    var fundversion = userInfo.appv,
        fundversion = fundversion.replace(/\./g, '');
    const nativeUrl = fund.getUrlConfigSync({
        remoteKey: "EastBarGuba",
        localKey: "EastBarGuba"
    });
    //非帖子作者删除自己的评论
    let url = nativeUrl + "replyopt/api/Reply/DeleteUserReply";
    if (postUserId == userInfo.passportid) {
        //帖子作者删除自己帖子下面的评论
        url = nativeUrl + "replyopt/api/Reply/DeletePostReply";
    }
    console.log('测试删除' + url);
    let method = "POST";
    let header = {
        "content-type": "application/x-www-form-urlencoded",
    };
    const common = {
        DeviceId: userInfo.deviceid,
        UserId: userInfo.uid,
        Plat: userInfo.plat,
        key: 'a8eb1746-1375-8def-b5e8-fe369ee73d68',
        uToken: userInfo.passportutokentrue,
        cToken: userInfo.passportctokentrue,
        gToken: userInfo.gtoken,
        OSVersion: userInfo.osv,
        appVersion: userInfo.appv,
        MarketChannel: userInfo.marketchannel,
        passportId: userInfo.passportid,
        MobileKey: userInfo.deviceid,
        product: 'Fund',
        version: fundversion
    }
    let newData = data;
    for (const key in common) {
        const el = common[key];
        newData[key] = el;
    }
    return new Promise((resolve, reject) => {
        fund.request({
            url,
            method,
            header,
            data: newData,
            success: (res) => {
                resolve(res);
            },
            fail: () => {
                reject();
            }
        });
    })
}
function commentDetailRequest(data) {
    const Info = fund.getUserInfoSync();
    let userInfo = Info.userInfo;
    if (typeof userInfo == "string") {
        userInfo = JSON.parse(userInfo);
    }
    const nativeUrl = fund.getUrlConfigSync({
        remoteKey: "EastBarGuba",
        localKey: "EastBarGuba"
    });
    var fundversion = userInfo.appv,
        fundversion = fundversion.replace(/\./g, '');
    let url = nativeUrl + "reply/api/Reply/ArticleReplyDetail";
    let method = "POST";
    let header = {
        "content-type": "application/x-www-form-urlencoded",
    };
    const common = {
        DeviceId: userInfo.deviceid,
        UserId: userInfo.uid,
        Plat: userInfo.plat,
        key: 'a8eb1746-1375-8def-b5e8-fe369ee73d68',
        uToken: userInfo.passportutokentrue,
        cToken: userInfo.passportctokentrue,
        gToken: userInfo.gtoken,
        OSVersion: userInfo.osv,
        appVersion: userInfo.appv,
        MarketChannel: userInfo.marketchannel,
        passportId: userInfo.passportid,
        MobileKey: userInfo.deviceid,
        product: 'Fund',
        version: fundversion
    }
    let newData = data;
    for (const key in common) {
        const el = common[key];
        newData[key] = el;
    }
    return new Promise((resolve, reject) => {
        fund.request({
            url, //仅为示例，并非真实接口地址。
            method,
            header,
            data: newData,
            success: (res) => {
                resolve(res);
            },
            fail: () => {
                reject();
            }
        });
    })
}
function commentKeyWord(data) {
    //评论列表关键词
    const Info = fund.getUserInfoSync();
    let userInfo = Info.userInfo;
    if (typeof userInfo == "string") {
        userInfo = JSON.parse(userInfo);
    }
    const nativeUrl = fund.getUrlConfigSync({
        remoteKey: "FundBarApiPro",
        localKey: "FundBarApiPro"
    });
    let url = nativeUrl + "community/show/batchKeyWords";
    let method = "POST";
    let header = {
        "content-type": "application/x-www-form-urlencoded",
    };
    const common = {
        deviceid: userInfo.deviceid,
        userid: userInfo.uid,
        plat: userInfo.plat,
        key: 'a8eb1746-1375-8def-b5e8-fe369ee73d68',
        utoken: userInfo.utoken,
        ctoken: userInfo.ctoken,
        gtoken: userInfo.gtoken,
        osversion: userInfo.osv,
        appversion: userInfo.appv,
        marketchannel: userInfo.marketchannel,
        passportid: userInfo.passportid,
        mobileKey: userInfo.deviceid,
        product: 'EFund',
        version: userInfo.appv
    }
    let newData = data;
    for (const key in common) {
        const el = common[key];
        newData[key] = el;
    }
    return new Promise((resolve, reject) => {
        fund.request({
            url, //仅为示例，并非真实接口地址。
            method,
            header,
            data: newData,
            success: (res) => {
                resolve(res);
            },
            fail: () => {
                reject();
            }
        });
    })
}
export {
    mFetch,
    mFetchNoExtra,//不需要公共参数
    mParamToStr,//参数json转string
    mCommonParams,//获取公共参数
    fetchNews,
    likeComment, //点赞评论，取消点赞评论
    deleteCommentRequest,//删除评论
    commentDetailRequest,//评论详情页
    commentKeyWord//评论列表关键词
};
