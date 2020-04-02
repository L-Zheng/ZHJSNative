module.exports = {
  productionSourceMap: false,
  chainWebpack: config => config.optimization.minimize(false),
  publicPath: './'
}