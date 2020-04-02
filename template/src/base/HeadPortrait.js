
class HeadPortrait {
    constructor() { }
    fetch(remoteKey, localKey, userId) {
        const nativeUrl = fund.getUrlConfigSync({
            remoteKey,
            localKey
        });
        return `${nativeUrl}${userId}/120`
    }
}
export default new HeadPortrait();


