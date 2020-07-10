module.exports = {
  productionSourceMap: false,
  pages: {
    index: {
      entry: './src/main.js',
      template: './public/index.html',
    }
  },
  chainWebpack: config => config.optimization.minimize(false),
  publicPath: './'
}