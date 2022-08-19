
window.JsBridge_OriginSocket = WebSocket;
window.WebSocket = function (url, protocols) {
    var ws = new JsBridge_OriginSocket(url, protocols);
    /** 1s后监听链接消息  因为刚建立链接时会有消息接收 */
    setTimeout(function () {
        ws.addEventListener('message', function (event) {
            var data = event.data;
            var formatData = [];
            if (data.length <= 1) {
                formatData = data;
            } else {
                data = JSON.parse(data.substring(1));
                if (Object.prototype.toString.call(data) == '[object Array]' && data.length > 0) {
                    data = JSON.parse(data[0]);
                    formatData.push(data);
                    _Replace_SocketApi.socketDidReceiveMessage(data);
                } else {
                    formatData = data;
                }
            }
        });
    }, 1000);
    return ws;
}
