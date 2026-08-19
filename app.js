(() => {
  'use strict';

  const HISTORY_KEY = 'todayMealHistoryV1';
  const CURRENT_KEY = 'todayMealCurrentV1';
  const recipes = Array.isArray(window.RECIPES) ? window.RECIPES : [];
  const recipeById = new Map(recipes.map((recipe) => [recipe.id, recipe]));

  const elements = {
    generator: document.getElementById('generator'),
    utilityPanels: document.getElementById('utilityPanels'),
    generateButton: document.getElementById('generateButton'),
    result: document.getElementById('result'),
    changeButton: document.getElementById('changeButton'),
    mealTitle: document.getElementById('mealTitle'),
    staple: document.getElementById('staple'),
    totalTime: document.getElementById('totalTime'),
    difficulty: document.getElementById('difficulty'),
    shoppingList: document.getElementById('shoppingList'),
    seasoningNote: document.getElementById('seasoningNote'),
    prepList: document.getElementById('prepList'),
    stepsList: document.getElementById('stepsList'),
    heatList: document.getElementById('heatList'),
    timingList: document.getElementById('timingList'),
    doneness: document.getElementById('doneness'),
    rescue: document.getElementById('rescue'),
    sourceLink: document.getElementById('sourceLink'),
    sourceMeta: document.getElementById('sourceMeta'),
    historyList: document.getElementById('historyList'),
    emptyHistory: document.getElementById('emptyHistory'),
    errorMessage: document.getElementById('errorMessage')
  };

  function readStorage(key, fallback) {
    try {
      const value = localStorage.getItem(key);
      return value === null ? fallback : JSON.parse(value);
    } catch (_error) {
      return fallback;
    }
  }

  function writeStorage(key, value) {
    try {
      localStorage.setItem(key, JSON.stringify(value));
    } catch (_error) {
      // 文件模式或隐私设置可能禁用存储；随机功能仍可继续使用。
    }
  }

  function getHistory() {
    const stored = readStorage(HISTORY_KEY, []);
    if (!Array.isArray(stored)) return [];
    return stored.filter((id) => recipeById.has(id)).slice(0, 5);
  }

  function randomIndex(max) {
    if (window.crypto && typeof window.crypto.getRandomValues === 'function') {
      const value = new Uint32Array(1);
      window.crypto.getRandomValues(value);
      return value[0] % max;
    }
    return Math.floor(Math.random() * max);
  }

  function chooseRecipe(currentId) {
    const history = getHistory();
    let pool = recipes.filter((recipe) => recipe.id !== currentId && !history.includes(recipe.id));
    if (pool.length === 0) {
      pool = recipes.filter((recipe) => recipe.id !== currentId);
    }
    if (pool.length === 0) return null;
    return pool[randomIndex(pool.length)];
  }

  function replaceList(listElement, items) {
    listElement.replaceChildren();
    items.forEach((text) => {
      const item = document.createElement('li');
      item.textContent = text;
      listElement.appendChild(item);
    });
  }

  function renderHistory() {
    const history = getHistory();
    elements.historyList.replaceChildren();
    history.forEach((id) => {
      const item = document.createElement('li');
      item.textContent = recipeById.get(id).name;
      elements.historyList.appendChild(item);
    });
    elements.emptyHistory.hidden = history.length > 0;
  }

  function remember(recipeId) {
    const nextHistory = [recipeId, ...getHistory().filter((id) => id !== recipeId)].slice(0, 5);
    writeStorage(HISTORY_KEY, nextHistory);
    writeStorage(CURRENT_KEY, recipeId);
    renderHistory();
  }

  function renderRecipe(recipe, shouldRemember) {
    elements.mealTitle.textContent = recipe.name;
    elements.staple.textContent = `搭配：${recipe.staple}`;
    elements.totalTime.textContent = `约 ${recipe.totalMinutes} 分钟`;
    elements.difficulty.textContent = `${'●'.repeat(recipe.difficulty)}${'○'.repeat(Math.max(0, 3 - recipe.difficulty))}`;

    const shopping = recipe.ingredients
      .filter((ingredient) => !ingredient.owned)
      .map((ingredient) => `${ingredient.item} · ${ingredient.amount}`);
    replaceList(elements.shoppingList, shopping.length ? shopping : ['本次无需另买']);
    elements.seasoningNote.textContent = recipe.extraSeasonings.length
      ? `需另买调料：${recipe.extraSeasonings.join('、')}`
      : '无需另买调料；使用已有食用油、味精、盐或生抽。';

    replaceList(elements.prepList, recipe.prep);
    replaceList(elements.stepsList, recipe.steps);
    replaceList(elements.heatList, recipe.heat);
    replaceList(elements.timingList, recipe.timings);
    elements.doneness.textContent = recipe.doneness;
    elements.rescue.textContent = recipe.rescue;
    elements.sourceLink.href = recipe.sourceUrl;
    elements.sourceLink.setAttribute('aria-label', `查看${recipe.name}的原始菜谱`);
    elements.sourceMeta.textContent = `HowToCook · ${recipe.license} · ${recipe.commitSha.slice(0, 7)}`;

    elements.generator.hidden = true;
    elements.utilityPanels.hidden = false;
    elements.result.hidden = false;
    elements.errorMessage.hidden = true;
    if (shouldRemember) remember(recipe.id);
  }

  function generate() {
    const currentId = readStorage(CURRENT_KEY, null);
    const recipe = chooseRecipe(typeof currentId === 'string' ? currentId : null);
    if (!recipe) {
      elements.errorMessage.textContent = '菜谱数据未能加载，请确认 recipes.js 与 index.html 在同一目录。';
      elements.errorMessage.hidden = false;
      return;
    }
    renderRecipe(recipe, true);
  }

  elements.generateButton.addEventListener('click', generate);
  elements.changeButton.addEventListener('click', () => {
    const currentId = readStorage(CURRENT_KEY, null);
    const recipe = chooseRecipe(typeof currentId === 'string' ? currentId : null);
    if (recipe) renderRecipe(recipe, true);
  });

  renderHistory();
  const currentId = readStorage(CURRENT_KEY, null);
  if (typeof currentId === 'string' && recipeById.has(currentId)) {
    renderRecipe(recipeById.get(currentId), false);
  }

  if (recipes.length === 0) {
    elements.generateButton.disabled = true;
    elements.errorMessage.textContent = '菜谱数据为空，请确认 recipes.js 已生成。';
    elements.errorMessage.hidden = false;
  }
})();
