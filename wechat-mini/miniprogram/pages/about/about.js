'use strict'

const { recipes, sourceSha256 } = require('../../data/recipes')

const REPOSITORY_URL = 'https://github.com/Anduin2017/HowToCook'

Page({
  data: {
    recipeCount: recipes.length,
    repositoryUrl: REPOSITORY_URL,
    commitSha: recipes.length ? recipes[0].commitSha : '',
    sourceSha256,
    equipment: [
      '电饭煲', '电磁炉', '铁锅', '锅盖', '锅铲', '洗锅工具',
      '砧板', '菜刀', '菜板菜刀支架', '调料盒', '碗', '筷子'
    ],
    seasonings: ['食用油', '味精', '盐', '生抽']
  },

  copyRepository() {
    wx.setClipboardData({
      data: REPOSITORY_URL,
      success() {
        wx.showToast({ title: '仓库链接已复制', icon: 'success' })
      }
    })
  },

  goBack() {
    const pages = getCurrentPages()
    if (pages.length > 1) {
      wx.navigateBack()
      return
    }
    wx.reLaunch({ url: '/pages/index/index' })
  }
})
