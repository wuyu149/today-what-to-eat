const { recipes, sourceSha256 } = require('../../data/recipes')
const selector = require('../../utils/selector')
const storage = require('../../utils/storage')

const DEFAULT_FILTERS = {
  diet: 'all',
  staple: 'all',
  time: 'all'
}

Page({
  data: {
    recipesCount: recipes.length,
    sourceSha: sourceSha256.slice(0, 7),
    filters: DEFAULT_FILTERS,
    dietOptions: [
      { value: 'all', label: '都行' },
      { value: 'meat', label: '有肉' },
      { value: 'no-meat', label: '不吃肉' }
    ],
    stapleOptions: [
      { value: 'all', label: '都行' },
      { value: 'rice', label: '米饭' },
      { value: 'noodle', label: '面食' }
    ],
    timeOptions: [
      { value: 'all', label: '不限' },
      { value: '30', label: '30分钟内' }
    ],
    current: null,
    historyCount: 0
  },

  onLoad() {
    const storedFilters = storage.safeGet(storage.keys.filters, DEFAULT_FILTERS)
    const filters = Object.assign({}, DEFAULT_FILTERS, storedFilters)
    const currentId = storage.safeGet(storage.keys.current, '')
    const current = recipes.find((recipe) => recipe.id === currentId)
    this.setData({
      filters,
      current: current ? this.prepareRecipe(current) : null,
      historyCount: storage.getHistory().length
    })
  },

  onShow() {
    const selectedId = storage.safeGet(storage.keys.selectedHistory, '')
    if (selectedId) {
      const selected = recipes.find((recipe) => recipe.id === selectedId)
      storage.safeSet(storage.keys.selectedHistory, '')
      if (selected) {
        storage.rememberRecipe(selected.id)
        this.setData({
          current: this.prepareRecipe(selected),
          historyCount: storage.getHistory().length
        })
      }
    } else {
      this.setData({ historyCount: storage.getHistory().length })
    }
  },

  prepareRecipe(recipe) {
    return Object.assign({}, recipe, {
      shopping: recipe.ingredients.filter((ingredient) => !ingredient.owned),
      difficultyDots: '●'.repeat(recipe.difficulty) + '○'.repeat(Math.max(0, 3 - recipe.difficulty)),
      extraSeasoningText: recipe.extraSeasonings.length
        ? recipe.extraSeasonings.join('、')
        : '无需另买调料'
    })
  },

  changeFilter(event) {
    const group = event.currentTarget.dataset.group
    const value = event.currentTarget.dataset.value
    const filters = Object.assign({}, this.data.filters, { [group]: value })
    if (!selector.filterRecipes(recipes, filters).length) {
      wx.showToast({
        title: '这个组合暂无菜，请换一个条件',
        icon: 'none'
      })
      return
    }
    storage.safeSet(storage.keys.filters, filters)
    this.setData({ filters })
  },

  generateMeal() {
    const currentId = this.data.current ? this.data.current.id : ''
    const history = storage.getHistory().filter((id) => recipes.some((recipe) => recipe.id === id))
    const selected = selector.selectRecipe(recipes, this.data.filters, currentId, history)

    if (!selected) {
      wx.showToast({
        title: '这个组合暂时没有菜',
        icon: 'none'
      })
      return
    }

    storage.rememberRecipe(selected.id)
    this.setData({
      current: this.prepareRecipe(selected),
      historyCount: storage.getHistory().length
    }, () => {
      wx.pageScrollTo({ selector: '#result-card', duration: 260 })
    })
  },

  openHistory() {
    wx.navigateTo({ url: '/pages/history/history' })
  },

  openAbout() {
    wx.navigateTo({ url: '/pages/about/about' })
  },

  copySource() {
    if (!this.data.current) return
    wx.setClipboardData({
      data: this.data.current.sourceUrl,
      success() {
        wx.showToast({ title: '来源链接已复制', icon: 'success' })
      }
    })
  },

  onShareAppMessage() {
    return {
      title: this.data.current ? `今天吃：${this.data.current.name}` : '今天吃什么',
      path: '/pages/index/index'
    }
  }
})
