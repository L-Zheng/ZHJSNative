
class LinkMap {
    constructor() { }
    static map = {
        link: 'emfundapp:ttjj-linkto',
        postLink: 'emfundapp:postlink',
        previewImage: 'emfundapp:newsimagepreview',
        lookImage: 'emfundapp:chakantupian',

        //正文点击图片预览事件【原来走短链 为了图片浏览定位动画体验 改用click事件】
        previewImageClick: 'fundPreviewImageHandler',

        newsDeatil: 'fund://page/newsdetail',
        fbArticleDetail: 'fund://page/fbarticledetail',
        barQuestionDetail: 'fund://page/barquestiondetail',
        personHome: 'fund://page/personalhome',
        fundDetail:'fund://page/funddetail'
    }
}

export default LinkMap.map;