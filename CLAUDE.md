# 项目规则

## 目标与边界

- 本项目同时维护：断网可用的本地网页，以及用于微信开发版/体验版的“今天吃什么”原生小程序。
- 页面每次只展示 1 名成年人当日一顿正餐，不生成周计划或未来菜单。
- 只使用电饭煲、电磁炉、铁锅及既有配套厨具；食品安全优先于便利和丰富度。
- 不删除文件，不安装依赖，不修改系统设置；允许为版本管理执行本地 Git 初始化、暂存和提交，但远程建仓、`git push`、微信开发者工具安装和小程序发布必须另行获得明确授权。

## 目录结构与白名单

- 根目录继续保存网页、唯一菜谱数据、来源、构建、测试和项目记录。
- `wechat-mini/` 只保存微信小程序工程；不得在其中复制手改的第二份菜谱数据。
- `wechat-mini/miniprogram/pages/index/`：随机筛选与单顿结果页。
- `wechat-mini/miniprogram/pages/history/`：最近 5 次记录页。
- `wechat-mini/miniprogram/pages/about/`：已有厨具、调料、来源和许可说明页。
- `wechat-mini/miniprogram/data/recipes.js`：由根目录 `recipes.json` 确定性生成，禁止手改。
- `wechat-mini/miniprogram/utils/`：无界面、无网络请求的选择与存储逻辑。
- 除原有文件外，只允许新增或修改：`.gitignore`、`build-miniprogram.ps1`、`tests-miniprogram.ps1`、`wechat-mini/project.config.json`，以及上述 `wechat-mini/miniprogram/` 中明确列出的应用、页面、数据和工具文件。

## 文件用途

- `CLAUDE.md`：项目规则，实践变化前先更新本文件。
- `.gitignore`：排除系统文件、编辑器配置、微信开发者工具私有配置、日志和临时产物。
- `README.md`：面向使用者的离线打开与使用说明。
- `PROGRESS.md`：断点续作记录；每完成一项立即更新，记录验证证据与合理替换。
- `BLOCKED.md`：无法确认或外部条件造成的阻塞；不影响其余工作继续。
- `THIRD_PARTY_NOTICES.md`：第三方仓库、作者、版本、许可证及使用范围。
- `sources.json`：逐道菜谱的可追溯来源登记。
- `recipes.json`：唯一菜谱数据源，UTF-8 JSON，数组顶层。
- `recipes.js`：由构建脚本确定性生成的浏览器数据文件，禁止手改。
- `build-recipes.ps1`：由 `recipes.json` 生成 `recipes.js` 并嵌入源文件 SHA256。
- `index.html`、`styles.css`、`app.js`：离线网页结构、样式与交互。
- `tests.ps1`：数据、构建产物和随机逻辑的自动验证。
- `build-miniprogram.ps1`：由 `recipes.json` 生成小程序 `data/recipes.js`，写入源 SHA256。
- `tests-miniprogram.ps1`：检查工程结构、配置、数据一致性、过滤结果和随机逻辑。
- `wechat-mini/project.config.json`：微信开发者工具项目配置；默认使用 `touristappid`，真实 AppID 不作为密钥处理但需由账号所有者填入。

## 数据与命名

- 文件名严格采用任务书给定名称；代码标识符使用英文，界面文案使用中文。
- 菜谱 ID 使用稳定的 ASCII kebab-case，改名不得生成重复 ID。
- `recipes.json` 每道菜必须包含：`id`、`name`、`staple`、`ingredients`、`extraSeasonings`、`prep`、`steps`、`heat`、`timings`、`doneness`、`rescue`、`totalMinutes`、`difficulty`、`tags`、`sourceRepo`、`sourceFile`、`commitSha`、`sourceUrl`、`license`、`adaptation`。
- 用量统一为 1 人份并保留可操作单位；步骤、火力、时间、熟成判断和补救不得为空。
- `recipes.js` 只由 `build-recipes.ps1` 生成，首行写入 `recipes.json` 的 SHA256；相同输入必须产生字节一致的输出。
- 小程序数据仍以根目录 `recipes.json` 为唯一数据源；生成文件首行必须写入同一 SHA256。
- 小程序使用原生 WXML、WXSS 和 JavaScript，不引入 npm、框架、云开发或服务端接口。
- 最近 5 次、当前结果和筛选偏好只存放在微信本地存储；不得收集用户身份、位置、通讯录或行为数据。
- 个人类型小程序不使用 `web-view` 打开 GitHub；来源采用页面展示加“复制原始链接”。

## 来源登记

- 优先采用 `Anduin2017/HowToCook` 的指定 commit；只读取上游 Markdown、README、LICENSE 等文本，不执行上游代码。
- 每道菜记录仓库 URL、具体 commit SHA、来源文件、固定到 commit 的原始链接、许可证和改写说明。
- 食品安全补充只采用政府、疾控或官方产品说明，并记录实际打开的 URL 与访问日期。
- 禁止编造来源；无法重新打开、许可证不明或无法可靠换算为 1 人份的菜谱不得收录。

## 验证规则

- 每次修改 `recipes.json` 后运行 `build-recipes.ps1`，再运行 `tests.ps1`。
- 自动测试必须覆盖：不少于 30 道、ID/菜名唯一、字段完整、来源完整、禁用设备关键词为 0、JSON 与 JS SHA256 一致、随机 1000 次无空值和连续重复。
- 必须做一次反向验证：临时移除测试副本的必填字段，确认测试失败；恢复后重新生成并全量通过，不得削弱测试。
- 最终用浏览器分别按桌面和手机宽度检查，至少点击 30 次，并验证单卡、来源、历史持久化及控制台错误为 0。
- 小程序测试必须覆盖：三个页面和配置齐全、30 道数据与根数据 SHA256 一致、无网络请求/`web-view`、全部筛选组合不产生非法空值、随机 1000 次无连续重复。
- 微信开发者工具存在时，必须用 CLI 或真机预览验证；不存在时不得伪造结果，写入 `BLOCKED.md` 并完成不依赖工具的静态验证。

## Git 与 GitHub

- 默认分支使用 `main`；提交信息使用简洁、可追溯的英文 Conventional Commits 格式。
- 提交前必须运行 `tests.ps1` 与 `tests-miniprogram.ps1`，并检查 `git diff --check`、暂存清单和敏感信息扫描。
- 只提交源码、确定性生成数据、项目说明和测试脚本；不得提交微信开发者工具私有配置、二维码、日志、缓存或账号信息。
- GitHub 默认仓库名为 `today-what-to-eat`；仓库可见性、远程创建和首次 `git push` 由用户明确授权后执行。
- 第三方菜谱的来源、固定 commit 与许可证继续以 `sources.json` 和 `THIRD_PARTY_NOTICES.md` 为准，不因上传 GitHub 而改变。

## 清理规则

- 不创建白名单外的临时文件；测试临时数据仅放系统临时目录并在测试进程内清理。
- 不删除项目文件；若产生不合规文件，记录到 `BLOCKED.md` 等待人工处理。
- 不保留下载缓存、构建中间物或上游代码副本；项目内只保留规范化数据、来源登记与成品。
- `wechat-mini/` 不保存二维码、上传包、日志、缓存或账号私有配置；体验版二维码和真实 AppID 不写入公共说明文件。
