
// fund.commonLinkTo();
// return
// fund.commonLinkTo({
//     ff: 'qqq',
//     success: function (res) {
//         console.log('success-qqq')
//         console.log(res)
//     },
//     fail: function (res) {
//         console.log('fail-qqq')
//         console.log(res)
//     },
//     complete: function (res) {
//         console.log('complete-qqq')
//         console.log(res)
//     }
// }, {
//     ff: 'ttt',
//     success: (res) => {
//       console.log('success-ttt')
//       console.log(res)
//     },
//     fail: (res) => {
//       console.log('fail-ttt')
//       console.log(res)
//     },
//     complete: (res) => {
//       console.log('complete-ttt')
//       console.log(res)
//     }
//   }, 'a string', ['gf', 555], 234, null, undefined, false, true, function () { console.log('jjjj') });
// return;
const resa = fund.getJsonSync(function(resfff, resttt){
  console.log('13245623--uuuu', 243, 'gdf')
  console.log(resfff)
  console.log(resttt)
  return 'wwwwwwq--' + resfff
},{
    ff: 'qqq',
    success: function (res, res1) {
        console.log('success-qqq')
        console.log(res)
        console.log(res1)
        console.log(Object.prototype.toString.call(res))
        console.log(Object.prototype.toString.call(res1))
        return '11111q--' + res;
    },
    fail: function (res) {
        console.log('fail-qqq')
        console.log(res)
        return '22222q'
    },
    complete: function (res) {
        console.log('complete-qqq')
        console.log(res)
        return '333333q'
    }
}, {
    ff: 'ttt',
    success: (res) => {
      console.log('success-ttt')
      console.log(res)
    },
    fail: (res) => {
      console.log('fail-ttt')
      console.log(res)
    },
    complete: (res) => {
      console.log('complete-ttt')
      console.log(res)
    }
  }, 'a string', ['gf', 555], 234, null, undefined, false, true, function () { console.log('jjjj') });
console.log(resa);
// return;

// const sss = []
// // const dd = sss.b
// // console.log(dd)
// console.log({
//     fff: false,
//     ddd: true,
//     qqq: {
//         ppp: 'lll'
//     },
//     rrr: null,
//     eee: 5452,
//     www: 'ttttt',
//     yyy: [null, undefined],
//     uuu: sss.v
// })
// console.log(this)


// function addApiTest() {
//     ZhengExtra.commonLinkTo1122({lll: 'fundxxxxxxxxxxx1122'})
//     ZhengExtra.commonLinkTo1133({dddd: 'fundxxxxxxxxxxx1133'})
// }

// // const aaa = [] 
// //         aaa.forEach(el, index => { });

// // ZhengInternal.commonLinkTo(123)
// // fund.commonLinkTo(123)
// // fund1.commonLinkTo(123)
// // ZhengSocket.socketDidReceiveMessage({'sd': '11'})

// // console.log('sdfgdsfd')

// // fund.request({
// //     url: 'https://dataapineice.1234567.com.cn/community/show/article?serverversion=6.2.5&userid=43fe14e102644bd5b0edcd8fc3306e80&product=EFund&passportid=1010285265217684&deviceid=F0DD802F-6164-439E-9ACB-85763AAE813F&plat=Iphone&ids=20191128154557877210040_300&ctoken=afqqc6c6afacj-q6f1qk-8kjrnej-d1-&utoken=ndecnj-fjne1krck8816q68fkcnfkcnu&version=6.3.0&gtoken=85D646FD659449F7A3E646530A51F372',
// //     method: 'GET',
// //     success: (res) => {
// //         console.log('test-reqyessfdwd')
// //         console.log(Object.prototype.toString.call(res))
// //         console.log(res)
// //         // console.log(Object.prototype.toString.call(res.ss))
// //         // console.log(res.ss)
// //     },
// //     fail: () => {
// //     },
// //     complete: () => {
// //         console.log('completecompletecompletecomplete')
// //     }
// // })

// // let res = fund.getBoolSync({
// //     title: 'sdfdwefd3ew324refg'
// // })
// // console.log('sfggadsff')
// // console.log(Object.prototype.toString.call(res))
// // console.log(res)

// // let res = fund.getJsonSync({})
// // console.log('sfggadsff')
// // console.log(Object.prototype.toString.call(res))
// // console.log(res)
// // console.log(Object.prototype.toString.call(res.sf))
// // console.log(res.sf)