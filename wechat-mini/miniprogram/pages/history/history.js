'use strict'

const { recipes } = require('../../data/recipes')
const storage = require('../../utils/storage')

Page({
  data: {
    history: []
  },

  onShow() {
    const recipeMap = {}
    recipes.forEach((recipe) => {
      recipeMap[recipe.id] = recipe
    })

    const history = storage.getHistory()
      .map((id) => recipeMap[id])
      .filter(Boolean)
      .map((recipe) => ({
        id: recipe.id,
        name: recipe.name,
        staple: recipe.staple,
        totalMinutes: recipe.totalMinutes,
        difficulty: recipe.difficulty,
        tagsText: Array.isArray(recipe.tags) ? recipe.tags.join(' · ') : ''
      }))

    this.setData({ history })
  },

  viewAgain(event) {
    const id = event.currentTarget.dataset.id
    if (!id) return

    storage.safeSet(storage.keys.selectedHistory, id)
    storage.safeSet(storage.keys.current, id)

    const pages = getCurrentPages()
    if (pages.length > 1) {
      wx.navigateBack()
      return
    }

    wx.reLaunch({ url: '/pages/index/index' })
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
