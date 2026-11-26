# i短剧 (iDuanJu)

> **本项目完全免费、开源，禁止任何形式的付费分发 / 售卖。**
> 本项目以 **GPL-3.0** 协议发布：任何使用、修改、衍生本项目代码的作品，都必须同样以 GPL-3.0 开源并公开完整源代码。
> 如果你是花钱买到本 App 或本代码的，你被骗了，请举报卖家。

## 这是什么

**i短剧** 是一款面向 **iOS / iPadOS（16.0+）** 与 **Android（8.0+ / 平板）** 的跨端**播放与阅读框架**。

> [!IMPORTANT]
> **App 本身只是一个空壳，不内置任何片源、书源、漫画源或频道，也不附带任何插件。**
> 首次打开只有「首页」「我的」两个页面；只有当你自行导入对应的插件、订阅或配置后，相应的板块和功能才会出现。

| 你导入的内容 | 出现的功能 |
| --- | --- |
| 视频 / 短剧插件（`.idjplugin`）、苹果 CMS 采集站 | 首页对应站点板块、搜索来源、详情页与播放器 |
| 漫画插件（`.idjplugin`） | 首页「漫画」板块、条漫阅读 |
| TVBox 配置（单仓 / 多仓） | 底栏「TVBox」页（点播 + 直播） |
| 本地 `TXT` / `EPUB`、阅读（Legado）书源 | 首页「小说」板块、听书与视频书 |
| Telegram 公开频道 | 首页「频道」板块 |

## 核心能力

- **插件系统（idj1）**
  - 单文件 JS 插件，运行在 QuickJS 沙箱中：只能访问 manifest 声明的域名，禁止内网 / IP 直连，脚本安装时固定 SHA-256，可选 Ed25519 作者签名。
  - 支持 `video` / `shortdrama` / `comic` / `live` 四类插件，支持订阅列表、手动粘贴、链接导入与 M3U 频道列表转换。
  - 插件规范见 [`docs/plugins/SPEC_ZH.md`](docs/plugins/SPEC_ZH.md)。
- **TVBox 配置**：CMS、T4、JS（drpy / CatVod）、Python、JAR 站点，解析、嗅探、弹幕、字幕、直播与 EPG / 回看；点播与直播共用统一的详情页和播放器。JAR 在 Android 本机运行，iOS 通过局域网桥接已配对的 Android 设备（详见 [`docs/unified-player-tvbox.md`](docs/unified-player-tvbox.md)）。
- **小说与有声阅读**：本地 `TXT` / `EPUB` 导入与阅读书源规则，仿真 / 平滑翻页、滚动阅读、字体与主题切换、离线缓存、听书朗读与视频书播放。
- **漫画阅读**：条漫沉浸阅读、横向翻页、章节连续加载、阅读进度与收藏。
- **精细化播放体验**
  - **手势与交互**：单击显隐控制栏、双击快进 / 快退、长按临时倍速、左右侧滑动调节亮度与音量、双指捏合切换适应 / 铺满。
  - **实用工具**：系统画中画（PiP）、自动连播、倍速与画面比例记忆、定时关闭、弹幕样式调节、音轨与字幕切换、收藏与断点续播。
  - **GPU 画质增强**：实时锐化（关闭 / 标准 / 强效）。
- **多设备与外观适配**：原生适配 iPhone / iPad 与 Android 手机 / 平板（大屏双栏、横屏侧边选集抽屉），深色 / 浅色自适应。

## 播放内核

- **iOS / iPadOS（16.0+）**：按片源格式自动选择 **AVPlayer**（HLS、MP4 等）或 **MPVKit**（LGPL，`libmpv` + `FFmpeg` + `libdovi` + `libplacebo` + `libass`；FLV、MKV、TS、RTMP 等），失败时自动切换内核，也可在设置中固定；支持 VideoToolbox 硬解、Dolby Vision / HDR10 / HLG、DTS / TrueHD / AC3 / E-AC3 与 ASS 字幕。
- **Android（8.0+）**：**Media3 ExoPlayer** + FFmpeg 音频扩展解码器 + OpenGL ES CAS 实时锐化着色器。
- 第三方开源组件许可全文见 App 内「开源许可」及 [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md)。

## 下载

请前往 [Releases 页面](https://github.com/my-name-is-alan/iDuanJu/releases) 下载（iOS 提供未签名 IPA，需自签或巨魔安装；Android 提供已签名 APK）。

安装后请在「我的 → 插件 / TVBox 配置 / 小说 / Telegram 频道」中导入你自己的内容。**本仓库与 Releases 均不提供任何插件或源。**

## 交流群

使用问题、反馈与新版本通知：[Telegram 交流群](https://t.me/iduanjuapp)

## 免责声明

- 本项目是一个通用的播放与阅读框架，仅供个人学习与技术研究使用，**不内置、不提供、不存储、不分发**任何视频、音频、图片、小说、漫画内容，也不提供任何插件、片源或书源。
- 通过插件、订阅或配置导入的一切内容均由使用者自行选择和负责，与本项目及作者无关。
- 所有内容版权归原站点和权利人所有。使用时请遵守相关服务条款及你所在地的法律法规，由此产生的一切后果由使用者自行承担。
- 如有权利人认为项目存在侵权问题，请提 Issue 联系处理。

## 许可证

[GPL-3.0](LICENSE)。第三方组件及其许可见 [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md)。

**禁止付费分发**：本项目是免费软件，作者不授权任何人以收费方式出售、分发本 App 或其代码。任何衍生作品都必须以 GPL-3.0 公开源代码。
