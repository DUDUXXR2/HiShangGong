# 云上商工 · HarmonyOS 原生版

> 商丘工学院「云上商工」校园 App 的 HarmonyOS NEXT 移植版。

## 项目说明

本工程基于 [HiXD](https://github.com/PollenWang6/HiXD)（西安电子科技大学第三方鸿蒙校园应用，MIT License）改造而来，
复用其 HTTP/Cookie 会话层、ArkUI 页面骨架与主题系统，业务服务层与接口替换为**商丘工学院**智慧校园平台。

> 声明：本应用为个人学习/日用用途的第三方工具，数据均来自学校官方平台（i.sqgxy.edu.cn / cas.sqgxy.edu.cn），
> 与学校无官方授权关系，仅限本人账号使用。

## 功能

- 登录：账号密码 → `cas.sqgxy.edu.cn/token/password/passwordLogin`，保存 `X-Id-Token`
- 首页：用户信息、校园公告（CMS）、横幅
- 门户 / 课表 / 成绩 / 事务 / 消息（接口已逆向整理，见 `docs/接口交接文档.md`，逐步接入中）

## 技术栈

- HarmonyOS NEXT（API 23），ArkTS / ArkUI
- 网络：`@ohos.net.http` + Cookie 会话层（复用自 HiXD 的 `HttpUtil`）
- 存储：`@ohos.data.preferences`

## 目录结构

```
AppScope/           应用配置（bundleName: com.yssg.harmony）
entry/src/main/ets/
  services/         业务服务（SqgService 登录/门户，SqgConstants 域名）
  utils/            HttpUtil（Cookie HTTP）、PreferenceUtil、ThemeColors
  pages/            Index(隐私门禁) / login/LoginPage / MainPage(主页)
docs/接口交接文档.md  逆向整理的接口清单
```

## 构建

用 DevEco Studio（26.x）打开本目录，SDK 组件缺失时按提示安装（HarmonyOS NEXT / API 23），
连接真机或模拟器后运行。

## 待办 / 已知限制

- `appId`（X-Device-Infos 的 packagename）目前取 `__UNI__AA068AD`，若服务器校验需抓包原 APK 对齐
- `deviceId` 用本地 UUID，可能与原 App 规则不同
- 教务域名（课表/成绩/考试）需通过 `getResources` 动态下发后接入
- 校园卡/电费/事务等子系统接口按文档逐步接入

## 开源许可

- 本工程主体框架与基础工具层：MIT License（原 HiXD 作者 [王继磊](https://github.com/PollenWang6)）
- 云上商工业务服务层与页面：个人移植，仅供个人学习使用
