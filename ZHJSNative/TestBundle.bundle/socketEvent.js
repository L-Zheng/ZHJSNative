
window.interceptedWebsockets = [];
window.NativeWebsocket = WebSocket;
window.WebSocket = function (url, protocols) {
    var ws = new NativeWebsocket(url, protocols);
    window.interceptedWebsockets.push(ws);

    //1s后监听链接消息  因为刚建立链接时会有消息接收
    setTimeout(() => {
        ws.addEventListener('message', function (event) {
            let data = event.data;
            let formatData = [];
            if (data.length <= 1) {
                formatData = data;
            } else {
                data = JSON.parse(data.substring(1));
                if (Object.prototype.toString.call(data) == '[object Array]' && data.length > 0) {
                    data = JSON.parse(data[0]);
                    formatData.push(data);
                    //通知原生刷新
                    fund.socketDidReceiveMessage(data)
                } else {
                    formatData = data;
                }
            }
            // console.log('Message from server111 ', event, event.data, data, formatData);
            // console.log('Message from server111 ',formatData);
        });
    }, 1000);
    return ws;
}