// SqgConstants.ets — 云上商工（商丘工学院）平台常量
// 域名来源：云上商工 APK 内 app-service.js 逆向提取，见 docs/接口交接文档.md

// 登录 / token 服务（appletBase）
export const APPLET_BASE: string = 'https://cas.sqgxy.edu.cn/token/';
// CAS
export const CAS_BASE: string = 'https://cas.sqgxy.edu.cn/cas/';
// 门户 / CMS
export const PORTAL_BASE: string = 'https://i.sqgxy.edu.cn/portal-api/';
// 个人中心
export const PERSONAL_BASE: string = 'https://authx-service.sqgxy.edu.cn/personal/';
// 事务中心
export const TASK_BASE: string = 'https://transaction.sqgxy.edu.cn/ttc/';
// 消息中心
export const MESSAGE_BASE: string = 'https://message-service.sqgxy.edu.cn/center/';

// 原 App casArry：跳转服务时，仅对命中此前缀的 URL 追加 idToken 参数
// （复刻 wgt 内 serviceUrl 模块 moduleSet.casArry = ["https://i.sqgxy.edu.cn/"]）
export const CAS_ARRY: string[] = ['https://i.sqgxy.edu.cn/'];

// 登录参数：appId = 原 APK 的 uni-app 应用标识（plus.runtime.appid）。
// ⚠️ 若服务器校验该值需精确匹配，抓包确认后在此替换。
export const APP_ID: string = '__UNI__AA068AD';
// 终端类型（原 JS 恒为 "app"）
export const TERMINAL_TYPE: string = 'app';
// 版本号（原 JS 用 plus.runtime.version，此处给个稳定值，抓包后可对齐）
export const APP_VERSION: string = '1.0.0';

// 请求超时（毫秒）
export const REQUEST_TIMEOUT: number = 15000;
