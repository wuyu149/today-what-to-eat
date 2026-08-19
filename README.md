# 今天吃什么

一个无需安装、断网可用的单顿随机菜谱工具，同时提供本地网页和原生微信小程序工程。内置 30 道一人份菜谱，只使用电饭煲、电磁炉、铁锅及常见配套厨具。

## 功能

- 每次只生成当天一顿正餐，不安排周计划。
- 支持有肉/不吃肉、米饭/面食和用时筛选。
- 换菜时避免连续重复，候选足够时优先避开最近 5 道。
- 菜谱包含用量、备菜、火力、时间、熟成判断和失败补救。
- 所有数据内置，本地选择菜谱时不请求网络。
- 每道菜登记固定来源文件、commit、许可证和改写说明。

## 使用离线网页

直接双击根目录的 `index.html`。页面、样式和 30 道菜谱均保存在本地；只有主动点击“菜谱来源”时才会打开 GitHub 原文。

浏览器会通过 `localStorage` 保存最近 5 次结果。数据只留在当前设备，可以随时在浏览器中清除。

## 使用微信小程序工程

1. 在微信开发者工具中导入 `wechat-mini` 目录。
2. 仅本地查看时可保留配置中的 `touristappid`。
3. 需要手机预览或上传体验版时，改用账号所有者的真实 AppID。
4. 上传体验版后，由管理员在微信公众平台配置体验成员。

小程序包含“今天吃什么”“最近吃过”和“关于”三个页面。数据与历史只保存在微信本地存储，不使用登录、云开发、网络接口或 `web-view`。仓库目前只完成源码与静态验证；尚未完成的开发者工具/真机验证见 `BLOCKED.md`。

## 项目结构

```text
.
├─ index.html / styles.css / app.js   离线网页
├─ recipes.json                       唯一菜谱数据源
├─ recipes.js                         网页生成数据，禁止手改
├─ sources.json                       逐道来源与食品安全补证
├─ build-recipes.ps1                  生成网页数据
├─ tests.ps1                          网页与菜谱测试
├─ build-miniprogram.ps1              生成小程序数据
├─ tests-miniprogram.ps1              小程序静态测试
├─ wechat-mini/                       原生微信小程序工程
├─ THIRD_PARTY_NOTICES.md             第三方来源与许可
├─ PROGRESS.md                        实施与验证记录
└─ BLOCKED.md                         尚未完成的环境验证
```

## 构建与验证

项目不依赖 npm、Python、数据库或本地服务器。在 Windows PowerShell 中运行：

```powershell
powershell -ExecutionPolicy Bypass -File .\build-recipes.ps1
powershell -ExecutionPolicy Bypass -File .\build-miniprogram.ps1
powershell -ExecutionPolicy Bypass -File .\tests.ps1
powershell -ExecutionPolicy Bypass -File .\tests-miniprogram.ps1
```

修改 `recipes.json` 后，必须重新运行两个构建脚本，再执行两套测试。生成文件首行记录源 JSON 的 SHA256，用于检查数据是否同步。

## 菜谱来源与许可

菜谱优先改写自 [Anduin2017/HowToCook](https://github.com/Anduin2017/HowToCook) 的固定 commit `0477799945082b72d6ac5c86a9752fddccf086e4`，该来源采用 Unlicense。完整的逐道来源、固定链接、改写范围和食品安全补证见 `sources.json` 与 `THIRD_PARTY_NOTICES.md`。
