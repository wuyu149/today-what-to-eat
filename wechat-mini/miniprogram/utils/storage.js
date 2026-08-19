const HISTORY_KEY = 'todayMealHistoryV2'
const CURRENT_KEY = 'todayMealCurrentV2'
const FILTER_KEY = 'todayMealFiltersV2'
const SELECTED_HISTORY_KEY = 'todayMealSelectedHistoryV2'

function safeGet(key, fallback) {
  try {
    const value = wx.getStorageSync(key)
    return value === '' || value === undefined || value === null ? fallback : value
  } catch (error) {
    return fallback
  }
}

function safeSet(key, value) {
  try {
    wx.setStorageSync(key, value)
    return true
  } catch (error) {
    return false
  }
}

function getHistory() {
  const history = safeGet(HISTORY_KEY, [])
  return Array.isArray(history) ? history.slice(0, 5) : []
}

function rememberRecipe(recipeId) {
  const next = [recipeId].concat(getHistory().filter((id) => id !== recipeId)).slice(0, 5)
  safeSet(HISTORY_KEY, next)
  safeSet(CURRENT_KEY, recipeId)
  return next
}

module.exports = {
  keys: {
    history: HISTORY_KEY,
    current: CURRENT_KEY,
    filters: FILTER_KEY,
    selectedHistory: SELECTED_HISTORY_KEY
  },
  getHistory,
  rememberRecipe,
  safeGet,
  safeSet
}
