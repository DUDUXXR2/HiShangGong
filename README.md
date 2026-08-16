# Hi商工 · HarmonyOS 原生版

> 商丘工学院「Hi商工」校园 App 的 **HarmonyOS NEXT 原生移植版**，非官方应用。

一个用 ArkTS / ArkUI 从零实现的鸿蒙原生校园客户端，覆盖登录、首页、服务、消息、日程、我的等核心模块，并针对手机 / 平板 / 2in1 / PC 做了断点自适应布局。

## 声明

- 本应用为**个人开发者制作的第三方校园工具**，从安卓版（uni-app）逆向移植到鸿蒙系统，**非学校官方出品**，与学校无任何隶属、合作或授权关系。
- 数据均来自**学校官方平台**（`i.sqgxy.edu.cn` / `cas.sqgxy.edu.cn` 等），本应用**不采集、不存储**任何个人数据到开发者服务器；账号密码仅用于校内统一身份认证，本地缓存仅保存在设备本地。
- 应用内缴费、充值等操作均为**跳转学校官方页面**完成支付，本应用不直接收款，也不存储支付信息。

## 功能

| 模块 | 说明 |
|---|---|
| 登录 | 学号/密码 → 商丘工学院统一身份认证（CAS），保存 `X-Id-Token` |
| 首页 | 云控快捷按钮（标题/图标/跳转由服务端下发）、本地 SVG/PNG 图标兜底、服务搜索 |
| 服务 | 分组服务列表，**断点自适应列数**（手机 5 / 平板 7 / 2in1 10 / 大屏 12），云端图标 + 本地兜底 |
| 消息 | 站内信（`message-service`），按标签分组，未读数角标，点击查看详情 |
| 日程 | 日程 Tab |
| 我的 | 头像/姓名/账号/身份（JWT 解码）、一卡通余额/邮箱/图书、外观与主题、设置、软件声明 |
| 二级功能页 | 课表、校园卡、缴电费等 H5 功能页，支持唤起支付宝/微信 App 支付 |
| 隐私门禁 | 首启隐私弹窗（官方 privacy_consent_dialog 组件），启动即征得同意 |

## 技术栈

- **HarmonyOS NEXT**（API 23+），ArkTS / ArkUI
- UI：HdsNavigation / HdsTabs（UIDesignKit）、`@tangs/components`（玻璃卡片）
- 网络：`@ohos.net.http` + Cookie 会话层
- 存储：`@ohos.data.preferences` + 本地文件缓存
- 扫码：Scan Kit（原生扫码 UI）
- 隐私弹窗：`privacy_consent_dialog`（华为官方 HAR，Apache-2.0）

## 目录结构

```
AppScope/               应用配置（bundleName: com.yssg.sqgxy）
entry/src/main/ets/
  services/             SqgService（登录/门户/消息/云控）、SqgConstants（域名）
  utils/                HttpUtil（Cookie）、PreferenceUtil、ThemeColors、
                        BackgroundManager（背景图）、MaterialConfig（材质）、CloudIcons（云控图标）
  pages/
    tabs/               HomeTab / ServiceTab / MessageTab / ScheduleTab / MineTab
    login/              登录页
    DeclarationPage     软件声明
    ServiceWebPage      二级 H5 功能页（含支付 scheme 唤起）
    ClassTablePage      课表页
docs/接口交接文档.md      逆向整理的接口清单（商丘工学院智慧校园平台）
privacy_consent_dialog/ 隐私同意弹窗组件（华为官方 HAR）
```

## 构建 / 运行

1. 用 **DevEco Studio**（HarmonyOS SDK 6.1+，API 23 或更高）打开本目录，缺失组件按提示安装。
2. **配置签名**：`build-profile.json5` 中签名信息为占位符（开源仓库不含真实凭据），在
   `File → Project Structure → Signing Configs` 中配置你自己的签名，或替换对应字段。
3. 连接真机 / 模拟器后运行；登录需真实学号密码（商丘工学院）。

## 下载 / 安装

- **最新 Release**：[查看 Releases](https://github.com/DUDUXXR2/HiShangGong/releases) 下载签名 HAP。
  > 该包使用调试证书签名，直接安装需设备已授权；普通安装请按上方「构建 / 运行」自行配置签名编译，或通过华为 AGC 邀请测试安装。
- **AGC 邀请测试**：正式测试版本通过华为应用市场测试分发（审核通过后提供测试链接）。

## 已知问题

部分 H5 功能页（如**成绩查询**、**课表查询**）由学校教务系统独立维护会话，与本应用的登录态相互独立，因此：

- **每次登录后，首次进入这类页面时需在页面内重新登录一次**（校园统一身份认证）；同一账号本次会话仅需这一次，之后访问无需重复登录。
- 缴电费、校园卡等其余功能页不受影响，登录后可直接使用。

## 开发说明

本项目由个人开发者基于安卓版逆向移植开发，开发过程中使用了 **DeepSeek v4、GLM-5.1 与 Claude Code** 等 AI 工具辅助编码。

## 免责声明

本软件按现状提供，不附带任何明示或暗示的担保。开发者不对因使用本软件而产生的任何直接或间接损失负责。请遵守学校相关管理规定，仅将本工具用于个人日常学习与生活。

## 开源许可

- 本工程主体与业务层：**MIT License**（详见 [LICENSE](./LICENSE)）
- 网络层/主题系统部分源自 [HiXD](https://github.com/PollenWang6/HiXD)（MIT，© 2026），保留原作者署名与许可声明
- UI 风格参考了 [Authenticator](https://gitcode.com/mroble/Authenticator)（均使用官方 ArkUI 组件，仅借鉴视觉风格，无代码依赖）
- `privacy_consent_dialog`：Apache-2.0（华为官方组件）
