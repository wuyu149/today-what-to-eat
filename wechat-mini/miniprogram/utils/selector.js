const MEAT_TAGS = ['猪肉', '牛肉', '虾', '肉末', '肉丝', '火腿']

function isMeatRecipe(recipe) {
  return recipe.tags.some((tag) => MEAT_TAGS.indexOf(tag) >= 0)
}

function matchesFilters(recipe, filters) {
  if (filters.diet === 'meat' && !isMeatRecipe(recipe)) return false
  if (filters.diet === 'no-meat' && isMeatRecipe(recipe)) return false
  if (filters.staple === 'rice' && !/米饭|盖饭|炒饭/.test(recipe.staple)) return false
  if (filters.staple === 'noodle' && !/面/.test(recipe.staple)) return false
  if (filters.time === '30' && recipe.totalMinutes > 30) return false
  return true
}

function filterRecipes(recipes, filters) {
  return recipes.filter((recipe) => matchesFilters(recipe, filters))
}

function selectRecipe(recipes, filters, currentId, historyIds, randomFn) {
  const random = randomFn || Math.random
  const matched = filterRecipes(recipes, filters)
  let pool = matched.filter((recipe) => recipe.id !== currentId && historyIds.indexOf(recipe.id) < 0)

  if (!pool.length) {
    pool = matched.filter((recipe) => recipe.id !== currentId)
  }
  if (!pool.length) return null

  const index = Math.floor(random() * pool.length)
  return pool[Math.min(index, pool.length - 1)]
}

module.exports = {
  filterRecipes,
  isMeatRecipe,
  matchesFilters,
  selectRecipe
}
