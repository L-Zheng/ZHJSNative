import Common from "@/base/url.js";
import NewsType from "./NewsType.js"
import {
    mFetch,
    mFetchNoExtra,
    mParamToStr,
    mCommonParams
} from "./mFetch.js";

function requestLikeArticle(isLike, params) {
    const Info = fund.getUserInfoSync();
    const userInfo = Info.userInfo;

    let url = `${Common.fundBarDataServer}${
        isLike ? "community/action/likeArticle" : "community/action/cancelLikeArticle"
        }`;
    const newParams = Object.assign(
        {
            product: "EFund",
            passportid: userInfo.passportid,
            userid: userInfo.uid,
            ctoken: userInfo.passportctoken,
            utoken: userInfo.utoken,
            gToken: userInfo.gtoken
        },
        mCommonParams(), params
    );
    return new Promise((resolve, reject) => {
        mFetchNoExtra(url, {}, newParams, "POST")
            .then(res => {
                resolve(res);
            })
            .catch(err => {
                reject(err);
            });
    })

}
function requestKeyWords(params) {
    return new Promise((resolve, reject) => {
        //获取用户信息
        const Info = fund.getUserInfoSync();
        const userInfo = Info.userInfo;
        let domin = fund.getUrlConfigSync({
            remoteKey: 'FundBarApiPro',
            localKey: 'FundBarApiPro'
        })
        domin = domin.endsWith('/') ? domin : `${domin}/`
        //获取互动信息
        // https://dataapi.1234567.com.cn/community/show/batchKeyWords?userid=123&product=EFund&deviceid=123&plat=Iphone&ids=20200312101202052515100_300&ctoken=123&utoken=123&version=6.2.0
        let url = `${domin}community/show/batchKeyWords`;
        const newParams = Object.assign(
            {
                product: "EFund",
                // passportid: userInfo.passportid,
                userid: userInfo.uid,
                ctoken: userInfo.passportctoken,
                utoken: userInfo.utoken
            },
            mCommonParams(), params
        );
        mFetchNoExtra(url, {}, newParams)
            .then(res => {
                resolve(res);
            })
            .catch(err => {
                reject(err);
            });
    })    
}
function requestArticleBriefInfo(params) {
    return new Promise((resolve, reject) => {
        //获取用户信息
        const Info = fund.getUserInfoSync();
        const userInfo = Info.userInfo;
        let domin = fund.getUrlConfigSync({
            remoteKey: 'EastBarGuba',
            localKey: 'EastBarGuba'
        })
        domin = domin.endsWith('/') ? domin : `${domin}/`
        //获取是否可转发
        // http://gbapi.eastmoney.com/abstract/api/PostShort/ArticleBriefInfo?postid=20200313113921366032070&type=1&deviceid=0.3410789631307125&version=100&product=Guba&plat=Web
        let url = `${domin}abstract/api/PostShort/ArticleBriefInfo`;
        const newParams = Object.assign(
            {
                product: "Fund"
            },
            mCommonParams(), params
        );
        mFetchNoExtra(url, {}, newParams)
            .then(res => {
                resolve(res);
            })
            .catch(err => {
                reject(err);
            });
    })
}
function requestInteractInfo(type, params) {
    return new Promise((resolve, reject) => {
        //获取用户信息
        const Info = fund.getUserInfoSync();
        const userInfo = Info.userInfo;
        let domin = fund.getUrlConfigSync({
          remoteKey: 'FundBarApiPro',
          localKey: 'FundBarApiPro'
        })
        domin = domin.endsWith('/') ? domin : `${domin}/`
        //获取互动信息
        // https://dataapi.1234567.com.cn/community/show/articleInteract?serverversion=6.2.0&userid=bad9ef48dfe64776a539a2b6e3c8d311&product=EFund&passportid=2533145336202222&deviceid=7072B970-147D-41C8-8EA4-8C8695B23B6F&plat=Iphone&ctoken=rjn-djf-6f-ejd--dafuh1-jecdaj-jf&utoken=kfjkn1aj8n-8kfdf-andcafrh-r--h68&version=6.2.0&gtoken=E9C0E1C98B0344B0A48B42157F7BA23f&ids=20191113163322831230580_300
        let url = `${domin}community/show/articleInteract`;
        const newParams = Object.assign(
            {
                product: "EFund",
                passportid: userInfo.passportid,
                userid: userInfo.uid,
                ctoken: userInfo.passportctoken,
                utoken: userInfo.utoken
            },
            mCommonParams(), params
        );
        mFetchNoExtra(url, {}, newParams)
            .then(res => {
                resolve(res);
            })
            .catch(err => {
                reject(err);
            });
    })
}
function requestArticleLabels(type, params) {
    //获取用户信息
    const Info = fund.getUserInfoSync();
    const userInfo = Info.userInfo;
    let url = `${Common.fundBarDataServer}community/show/articleLabels`;
    const newParams = Object.assign(
        {
            product: "EFund",
            passportid: userInfo.passportid,
            userid: userInfo.uid,
            ctoken: userInfo.passportctoken,
            utoken: userInfo.utoken,
            type: type,
        },
        mCommonParams(), params
    );
    return new Promise((resolve, reject) => {
        mFetchNoExtra(url, {}, newParams, "POST")
            .then(res => {
                resolve(res);
            })
            .catch(err => {
                reject(err);
            });
    })
}
function requestBatchUserInfo(type, params) {
    return new Promise((resolve, reject) => {
        // https://jijinbaapi.eastmoney.com/FundMCApi/FundMBNew/BatchUserInfos?product=EFund&passportid=2533145336202222&userid=bad9ef48dfe64776a539a2b6e3c8d311&ctoken=6cdh-rffdf-uqdh8er16d8f8ah8qrnfq&utoken=fnjfcaf6jehuan--1h8fr6qae6aquun8&deviceid=FF84EC9B-0268-4143-B6A6-0035BE715C7E&plat=Iphone&serverversion=6.2.5&version=6.2.5&appVersion=6.2.5&rqModel=%5B%7B%22code%22%3A%22cfhpl%22%2C%22pid%22%3A%228216085021619564%22%7D%5D
        if (type == NewsType.Post || type == NewsType.Answer) {
            //获取用户信息
            const Info = fund.getUserInfoSync();
            const userInfo = Info.userInfo;
            let url = `${Common.fundBarServer}FundMCApi/FundMBNew/BatchUserInfos`;
            const newParams = Object.assign(
                {
                    product: "EFund",
                    passportid: userInfo.passportid,
                    userid: userInfo.uid,
                    ctoken: userInfo.passportctoken,
                    utoken: userInfo.utoken,
                },
                mCommonParams(), params
            );
            mFetchNoExtra(url, {}, newParams, "GET")
                .then(res => {
                    resolve(res);
                })
                .catch(err => {
                    reject(err);
                });
        } else {
            reject()
        }
    })
}
function requestArticleMoreInfo(type, params) {
    return new Promise((resolve, reject) => {
        // if (type == NewsType.Post || type == NewsType.Answer) {
            //获取用户信息
            const Info = fund.getUserInfoSync();
            const userInfo = Info.userInfo;

      let domin = fund.getUrlConfigSync({
        remoteKey: 'FundBarApi',
        localKey: 'FundBarApi'
      })
      domin = domin.endsWith('/') ? domin : `${domin}/`

            let url = `${domin}FundMCApi/FundMBNew/BatchArticleMoreInfos`;
            const newParams = Object.assign(
                {
                    product: "EFund",
                    passportid: userInfo.passportid,
                    userid: userInfo.uid,
                    ctoken: userInfo.passportctoken,
                    utoken: userInfo.utoken,
                    type: type,
                },
                mCommonParams(), params
            );
            mFetchNoExtra(url, {}, newParams, "GET")
                .then(res => {
                    resolve(res);
                })
                .catch(err => {
                    reject(err);
                });
        // } else {
        //     reject()
        // }
    })
}
function requestShield(params) {
    //获取用户信息
    const Info = fund.getUserInfoSync();
    const userInfo = Info.userInfo;
    let url = `${Common.fundBarDataServer}community/action/userShieldAction`;
    const newParams = Object.assign(
        {
            product: "EFund",
            passportid: userInfo.passportid,
            userid: userInfo.uid,
            ctoken: userInfo.passportctoken,
            utoken: userInfo.utoken,
        },
        mCommonParams(), params
    );
    return new Promise((resolve, reject) => {
        mFetchNoExtra(url, {}, newParams, "POST")
            .then(res => {
                resolve(res);
            })
            .catch(err => {
                reject(err);
            });
    })
}
function requestTopicDetail(params) {
    //获取用户信息
    const Info = fund.getUserInfoSync();
    const userInfo = Info.userInfo;

    let nativeUrl = fund.getUrlConfigSync({
        remoteKey: "EastBarGuba",
        localKey: "EastBarGuba"
    });
    nativeUrl = nativeUrl.substring(nativeUrl.length - 1) == '/' ? nativeUrl : `${nativeUrl}/`

    let url = `${nativeUrl}fundfocustopic/api/topic/TopicDetailsRead`;
    const newParams = Object.assign(
        {
            product: "Fund",//不能使用EFund
            passportid: userInfo.passportid,
            userid: userInfo.uid,
            ctoken: userInfo.passportctoken,
            utoken: userInfo.utoken,
        },
        mCommonParams(), params
    );
    return new Promise((resolve, reject) => {
        mFetchNoExtra(url, {}, newParams, "POST")
            .then(res => {
                resolve(res);
            })
            .catch(err => {
                reject(err);
            });
    })
}
function requestSetMpDict(params) {
    return new Promise((resolve, reject) => {
        
        //获取互动信息
        let url = `https://mp.1234567.com.cn/wx/api/WxMiniProgram/SetDict`;
        mFetchNoExtra(url, {}, params, "POST")
            .then(res => {
                resolve(res);
            })
            .catch(err => {
                reject(err);
            });
    })    
}
export {
    requestKeyWords,
    requestInteractInfo,//获取互动信息
    requestLikeArticle,//文章点赞
    requestArticleLabels,//请求文章标签
    requestBatchUserInfo,//请求用户附加信息
    requestArticleMoreInfo,//获取文章扩展信息
    requestShield,//屏蔽关键词
    requestTopicDetail,//获取话题详情
    requestArticleBriefInfo,
    requestSetMpDict
};
