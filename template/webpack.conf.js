const path = require('path');
// 配置文件使用commonjs规范
module.exports = {
    mode: "production",
    // 入口，是一个对象
    entry: {
        'article-parse-pre': './src/article/article-parse-pre.js'
    },
    // 输出
    output: {
      path: __dirname + '/release', // string
      // path: path.resolve(__dirname, "release"), // string
      // 带五位hash值的js
    //   filename: '[name].[hash:5].js'
      filename: '[name].js'
    },
    //优化配置
    optimization: {
      minimize: false
    },
 
    // 指定loader
    module: {
      // rules中的每一项是一个规则
      rules:[
        {
          test: /\.js$/, // 值一个正则，符合这些正则的资源会用一个loade来处理
          use: {
            loader: 'babel-loader', // 使用bable-loader来处理
            options: { // 指定参数
            //   presets: [
            //     ['babel-preset-env', {
            //       targets: {
            //         browsers: ['> 1%', 'last 2 version'] //具体可以去babel-preset里面查看
            //       } 
            //     }]
                 
            //   ] // 指定哪些语法编译
            }
          },
          exclude: '/node_module/' // 排除在外
        }
      ]
    }
  }