import { commentKeyWord } from "@/base/mFetch";

function commentKeyWordAction(commentList, lastCommentList) {
    var tempLastCommentList = lastCommentList;
    var requestCommentIds = "";
    for (let index = 0; index < commentList.length; index++) {
        const commentItemData = commentList[index];
        let commentId = commentItemData.reply_id + "_1000";
        if (requestCommentIds.length > 0) {
            requestCommentIds = requestCommentIds + "," + commentId;
        } else {
            requestCommentIds = commentId;
        }
    }
    let params = {
        ids: requestCommentIds
    };
    commentKeyWord(params)
        .then(res => {
            //处理关键词，三个for循环遍历，需要优化
            if (res.data.success) {
                const allDataList = res.data.data;
                if (allDataList) {

                    for (let index = 0; index < allDataList.length; index++) {
                        const element = allDataList[index];
                        const keyWordList = element.keyWordModels;
                        const keyCommentid = element.id;
                        if (keyWordList) {
                            const tempLit = JSON.parse(JSON.stringify(lastCommentList))
                            for (let i = 0; i < tempLit.length; i++) {
                                const commentData = tempLit[i];
                                const commentid = commentData.reply_id;
                                if (keyCommentid == commentid) {
                                    for (let j = 0; j < keyWordList.length; j++) {
                                        const keyModels = keyWordList[j];
                                        const repText = keyModels.text;
                                        const degest = `${LinkMap.fundDetail}?fundcode=${keyModels.code}`;
                                        const totRep =
                                            '<a onclick="(function(e) {e.stopPropagation();})(event)" style="color:#4c618f" href=' +
                                            degest +
                                            ">" +
                                            repText +
                                            "</a>";
                                        const newText = commentData.reply_text;
                                        if (commentData.reply_text.indexOf(repText) >= 0) {
                                            let repTeTempxt = repText.replace(/(\$|\[|\])/g, '\\$1');

                                            const allRepText = newText.replace(
                                                new RegExp(repTeTempxt, "g"),
                                                totRep
                                            );
                                            commentData.reply_text = allRepText;
                                        }
                                    }
                                }
                                tempLastCommentList.splice(i, 1, commentData);
                                tempLastCommentList = JSON.parse(JSON.stringify(tempLastCommentList))
                            }
                        }
                    }
                }
            }
            return tempLastCommentList;
        })
        .catch(error => {

         });
}
export {
    commentKeyWordAction//评论列表关键词
};