// SqgService.ets — 云上商工（商丘工学院）核心服务
// 登录 + 请求头封装 + 门户/首页/公告/课表等接口
// 接口来源：APK 内 app-service.js 逆向提取，见 docs/接口交接文档.md
import { deviceInfo } from '@kit.BasicServicesKit';
import { util } from '@kit.ArkTS';
import { common } from '@kit.AbilityKit';
import { fileIo } from '@kit.CoreFileKit';
import { HttpUtil, HttpResponse } from '../utils/HttpUtil';
import { PreferenceUtil } from '../utils/PreferenceUtil';
import {
  APPLET_BASE, PORTAL_BASE, PERSONAL_BASE, MESSAGE_BASE,
  APP_ID, TERMINAL_TYPE, APP_VERSION, REQUEST_TIMEOUT,
  CAS_ARRY
} from './SqgConstants';

const TAG = 'SqgService';

// ===== 通用响应模型 =====
export class SqgResult<T> {
  code: number = -1;
  msg: string = '';
  data: T | null = null;
}

// 登录成功后需要保存的会话数据
export class LoginSession {
  idToken: string = '';       // X-Id-Token (JWT)
  accounts: AccountInfo[] = [];
}

export class AccountInfo {
  accountName: string = '';
  userId: string = '';
}

/**
 * 云上商工服务单例：
 * 1. getHeaders() —— 复刻原 App 的请求头（X-Device-Info / X-Device-Infos / X-Terminal-Info / X-Id-Token）
 * 2. login() —— 密码登录，保存 X-Id-Token
 * 3. 门户/首页/公告/课表接口
 */
export class SqgService {
  private static instance: SqgService;
  private http: HttpUtil = HttpUtil.getInstance();

  private constructor() {
  }

  static getInstance(): SqgService {
    if (!SqgService.instance) {
      SqgService.instance = new SqgService();
    }
    return SqgService.instance;
  }

  // ===== 设备信息 =====
  private deviceInfo1(): string {
    // 原 JS: uni.getSystemInfoSync().brand
    return deviceInfo.brand ?? '';
  }

  private deviceInfo2(): string {
    // 原 JS: uni.getSystemInfoSync().model —— HarmonyOS 对应 productModel
    return deviceInfo.productModel ?? '';
  }

  private deviceInfo3(): string {
    // 原 JS: uni.getSystemInfoSync().version —— HarmonyOS 对应 sdkApiVersion
    return String(deviceInfo.sdkApiVersion ?? '');
  }

  // ===== 请求头（复刻 getHeaders）=====
  private buildDeviceInfos(): string {
    const info: string = '{"packagename":"' + APP_ID +
      '","version":"' + APP_VERSION +
      '","system":"' + (deviceInfo.osFullName ?? '') + '"}';
    return info;
  }

  private token(): string {
    return PreferenceUtil.getString('id_token');
  }

  async getHeaders(): Promise<Record<string, string>> {
    const header: Record<string, string> = {};
    header['X-Device-Info'] = this.deviceInfo1() + this.deviceInfo2() + this.deviceInfo3();
    header['X-Device-Infos'] = this.buildDeviceInfos();
    header['X-Terminal-Info'] = TERMINAL_TYPE;
    header['X-Id-Token'] = this.token();
    header['content-type'] = 'application/x-www-form-urlencoded';
    header['Accept'] = 'application/json';
    return header;
  }

  // ===== 登录 =====
  /**
   * 密码登录（原 App asyncLogin）
   * POST {appletBase}/password/passwordLogin?username=..&password=..&appId=..&deviceId=..&osType=..&geo=..
   * 登录成功时返回 { code:0, data:{ idToken:<JWT>, ... } }，token 从响应体 data.idToken 取。
   */
  async login(username: string, password: string): Promise<LoginSession> {
    const deviceId: string = this.genDeviceId();
    const url: string = APPLET_BASE + 'password/passwordLogin' +
      '?username=' + encodeURIComponent(username) +
      '&password=' + encodeURIComponent(password) +
      '&appId=' + encodeURIComponent(APP_ID) +
      '&deviceId=' + encodeURIComponent(deviceId) +
      '&osType=' + encodeURIComponent('android') +
      '&geo=' + encodeURIComponent('');

    const headers: Record<string, string> = await this.getHeaders();
    // 用 postEmpty 发无 body 的 POST：HarmonyOS 网络栈对 POST 空串 extraData 会报 401 Parameter error，
    // 且本接口参数全在 URL query 中，不需要 body。
    const resp: HttpResponse = await this.http.postEmpty(url, headers);

    if (resp.statusCode >= 200 && resp.statusCode < 300 && resp.body.length > 0) {
      const obj: Record<string, Object> = JSON.parse(resp.body) as Record<string, Object>;
      const code: number = Number(obj['code'] ?? -1);
      if (code === 0) {
        const data: Record<string, Object> = (obj['data'] as Record<string, Object>) ?? {};
        // JWT 在 data.idToken
        const idToken: string = String(data['idToken'] ?? '');
        const accounts: AccountInfo[] = [];
        const accountsRaw: Object[] = (data['accounts'] as Object[]) ?? [];
        for (let i = 0; i < accountsRaw.length; i++) {
          const acc: Record<string, Object> = accountsRaw[i] as Record<string, Object>;
          const ai: AccountInfo = new AccountInfo();
          ai.accountName = String(acc['accountName'] ?? '');
          ai.userId = String(acc['userId'] ?? '');
          accounts.push(ai);
        }
        await PreferenceUtil.putString('id_token', idToken);
        await PreferenceUtil.putString('ids_account', username);
        await PreferenceUtil.putString('login_password', password);
        await PreferenceUtil.putBool('is_logged_in', true);
        const session: LoginSession = new LoginSession();
        session.idToken = idToken;
        session.accounts = accounts;
        return session;
      }
      // 服务器返回了业务错误码：把 code/msg/原始响应体都带出来，便于定位
      const rawBody: string = resp.body.length > 300 ? resp.body.substring(0, 300) : resp.body;
      const msg: string = String(obj['msg'] ?? '');
      throw new Error('登录失败 code=' + code + ' msg=' + msg + ' | ' + rawBody);
    }

    // 非 2xx：把状态码 + 响应体一起抛出，便于定位是网络栈问题还是服务器拒绝
    const bodyPreview: string = resp.body.length > 0 ? resp.body.substring(0, 300) : '(空)';
    throw new Error('登录失败（HTTP ' + resp.statusCode + '）: ' + bodyPreview);
  }

  // 本地设备唯一标识（简单实现：UUID 持久化）
  private genDeviceId(): string {
    let id: string = PreferenceUtil.getString('device_id');
    if (id.length === 0) {
      id = util.generateRandomUUID().replace(/-/g, '').toUpperCase();
      PreferenceUtil.putString('device_id', id);
    }
    return id;
  }

  // 是否已登录
  isLoggedIn(): boolean {
    return PreferenceUtil.getBool('is_logged_in', false) && this.token().length > 0;
  }

  // ===== 通用请求封装 =====
  private async requestWithToken(
    method: 'GET' | 'POST',
    baseUrl: string,
    path: string,
    query?: Record<string, string>,
    form?: Record<string, string>
  ): Promise<HttpResponse> {
    let base: string = baseUrl;
    if (base.length > 0 && !base.endsWith('/')) {
      base = base + '/';
    }
    let pathClean: string = path;
    if (pathClean.length > 0 && pathClean.startsWith('/')) {
      pathClean = pathClean.substring(1);
    }
    let url: string = base + pathClean;
    if (query && Object.keys(query).length > 0) {
      const qs: string[] = [];
      for (const key of Object.keys(query)) {
        qs.push(encodeURIComponent(key) + '=' + encodeURIComponent(query[key]));
      }
      url = url + '?' + qs.join('&');
    }
    const headers: Record<string, string> = await this.getHeaders();
    if (method === 'GET') {
      return this.http.get(url, headers);
    }
    const body: string = form ? this.encodeForm(form) : '';
    return this.http.postRaw(url, body, 'application/x-www-form-urlencoded', headers);
  }

  private encodeForm(data: Record<string, string>): string {
    const parts: string[] = [];
    for (const key of Object.keys(data)) {
      parts.push(encodeURIComponent(key) + '=' + encodeURIComponent(data[key]));
    }
    return parts.join('&');
  }

  // 统一解析 {code, msg|message, data}
  private parseSqg<T>(resp: HttpResponse): SqgResult<T> {
    try {
      const obj: Record<string, Object> = JSON.parse(resp.body) as Record<string, Object>;
      const code: number = Number(obj['code'] ?? -1);
      const msgObj: Object | undefined = obj['msg'];
      const messageObj: Object | undefined = obj['message'];
      const msg: string = msgObj !== undefined ? String(msgObj) : (messageObj !== undefined ? String(messageObj) : '');
      const data: T | null = obj['data'] as T ?? null;
      const r: SqgResult<T> = new SqgResult<T>();
      r.code = code;
      r.msg = msg;
      r.data = data;
      return r;
    } catch (e) {
      // 未登录时服务器可能返回登录页 HTML
      if (resp.body.trimStart().startsWith('<')) {
        throw new Error('会话已过期，请重新登录');
      }
      throw new Error('响应解析失败: ' + resp.body.substring(0, 200));
    }
  }

  // ===== 门户 / 首页 =====
  // 获取资源列表（应用/服务入口）
  async getResources(): Promise<object[] | null> {
    const resp: HttpResponse = await this.requestWithToken('GET', PORTAL_BASE, 'api/rest/mobile/v2/system/getResources');
    const r: SqgResult<object[]> = this.parseSqg<object[]>(resp);
    if (r.code === 0) {
      return r.data;
    }
    throw new Error(r.msg || '获取资源失败');
  }

  // 首页公告列表（CMS）
  // 原 App 调用参数：{ pageIndex, pageSize, columnCode:'gonggao' }，返回 data.allContents
  async getAnnouncements(pageIndex: number = 1, pageSize: number = 5): Promise<object[] | null> {
    const query: Record<string, string> = {};
    query['pageIndex'] = String(pageIndex);
    query['pageSize'] = String(pageSize);
    query['columnCode'] = 'gonggao';
    const resp: HttpResponse = await this.requestWithToken('POST', PORTAL_BASE,
      'api/proxy/cms/api/rest/mobile/v2/content/list',
      undefined,
      query);
    const r: SqgResult<object> = this.parseSqg<object>(resp);
    if (r.code === 0 && r.data !== null) {
      const dataObj: Record<string, Object> = r.data as Record<string, Object>;
      const allContents: Object[] = (dataObj['allContents'] as Object[]) ?? [];
      return allContents;
    }
    throw new Error(r.msg || '获取公告失败');
  }

  // 首页服务列表（原 App getAllServices：POST {NewBaseUrl}/v1/service/list，body '{}' JSON）
  // 实测：不带 token 返回 code:0 + 分组结构(services 空)；带有效 token 返回有内容的服务
  // 注意：postRaw 会用参数里的 contentType 设 Content-Type，传入的 headers 不能含 content-type，否则覆盖
  async getServiceList(): Promise<object[] | null> {
    // 先带 token 请求（能拿到用户有权限的服务）—— headers 不含 content-type，避免覆盖 JSON
    const full: Record<string, string> = await this.getHeaders();
    const headers: Record<string, string> = {
      'X-Device-Info': full['X-Device-Info'] ?? '',
      'X-Device-Infos': full['X-Device-Infos'] ?? '',
      'X-Terminal-Info': full['X-Terminal-Info'] ?? '',
      'X-Id-Token': full['X-Id-Token'] ?? '',
      'Accept': 'application/json'
    };
    let resp: HttpResponse = await this.http.postRaw(
      PORTAL_BASE + 'v1/service/list',
      '{}',
      'application/json',
      headers
    );
    let r: SqgResult<object[]> = this.parseSqg<object[]>(resp);

    // 若 token 无效（服务器拒绝），回退为不带 token 的公开请求
    if (r.code !== 0 && (r.code === -1001 || r.msg.indexOf('token') >= 0 || r.msg.indexOf('Token') >= 0)) {
      const pubHeaders: Record<string, string> = {
        'X-Device-Info': full['X-Device-Info'] ?? '',
        'X-Device-Infos': full['X-Device-Infos'] ?? '',
        'X-Terminal-Info': full['X-Terminal-Info'] ?? '',
        'Accept': 'application/json'
      };
      resp = await this.http.postRaw(
        PORTAL_BASE + 'v1/service/list',
        '{}',
        'application/json',
        pubHeaders
      );
      r = this.parseSqg<object[]>(resp);
    }

    if (r.code === 0) {
      // 调试：打印服务列表里的 url 字段，便于确认课表服务真实地址
      const dataArr: object[] = r.data ?? [];
      for (let i = 0; i < dataArr.length; i++) {
        const it: Record<string, Object> = dataArr[i] as Record<string, Object>;
        const nm: Object | undefined = it['serviceName'] ?? it['name'];
        const url: Object | undefined = it['serviceUrl'] ?? it['url'];
        if (nm !== undefined && url !== undefined) {
          console.info('[YS] service name=' + String(nm) + ' url=' + String(url));
        }
      }
      return r.data;
    }
    const body: string = resp.body.length > 300 ? resp.body.substring(0, 300) : resp.body;
    throw new Error('获取服务列表失败 code=' + r.code + ' msg=' + r.msg + ' | ' + body);
  }

  // 横幅
  async getBanners(): Promise<object[] | null> {
    const resp: HttpResponse = await this.requestWithToken('POST', PORTAL_BASE,
      'v2/cms/marqueeList/get');
    const r: SqgResult<object[]> = this.parseSqg<object[]>(resp);
    if (r.code === 0) {
      return r.data;
    }
    return null;
  }

  // ===== 用户信息 =====
  async getUserInfo(): Promise<object | null> {
    const resp: HttpResponse = await this.requestWithToken('GET', PERSONAL_BASE, 'api/v1/personal/me/user');
    const r: SqgResult<object> = this.parseSqg<object>(resp);
    if (r.code === 0) {
      return r.data;
    }
    throw new Error(r.msg || '获取用户信息失败');
  }

  // 从本地 id_token (JWT) 解码用户姓名。
  // 姓名在 payload 的 ATTR_userName（个别环境 ATTR_name）；ATTR_accountName 是学号/工号，不能当姓名用。
  getAccountName(): string {
    try {
      const token: string = this.token();
      if (token.length === 0) {
        return '';
      }
      const parts: string[] = token.split('.');
      if (parts.length < 2) {
        return '';
      }
      // base64url 解码 payload（第二部分），补全 padding
      let b64: string = parts[1];
      b64 = b64.replace(/-/g, '+').replace(/_/g, '/');
      while (b64.length % 4 !== 0) {
        b64 = b64 + '=';
      }
      const base64Helper: util.Base64Helper = new util.Base64Helper();
      const bytes: Uint8Array = base64Helper.decodeSync(b64);
      const decoder: util.TextDecoder = util.TextDecoder.create('utf-8');
      const decoded: string = decoder.decodeToString(bytes);
      const obj: Record<string, Object> = JSON.parse(decoded) as Record<string, Object>;
      const nameObj: Object | undefined = obj['ATTR_userName'] ?? obj['ATTR_name'] ?? obj['name'];
      return nameObj === undefined ? '' : String(nameObj);
    } catch (e) {
      return '';
    }
  }

  // 我的页头像 URL（复刻原 App my.js setAvatar）
  // 接口：{PERSONAL_BASE}/api/v1/personal/me/portrait?idToken={JWT}&imageUrl={可选}
  getPortraitUrl(): string {
    const token: string = this.token();
    const base: string = PERSONAL_BASE;
    const url: string = base + 'api/v1/personal/me/portrait?idToken=' + token;
    return url;
  }

  // 退出登录/切换账号时清除全部业务缓存（防止旧账号数据残留到新账号）
  // 清空：业务缓存键、AppStorage 我的页数据、Cookie、课表落盘文件
  async clearUserData(): Promise<void> {
    // 业务缓存键
    const cacheKeys: string[] = [
      'id_token',
      'ids_account',
      'login_password',
      'cache_courseUrl',
      'cache_courseH5Url',
      'mine_name_cached',
      'mine_card_balance_cached',
      'mine_book_count_cached',
      'mine_email_count_cached',
      'http_cookies'
    ];
    for (let i = 0; i < cacheKeys.length; i++) {
      try {
        await PreferenceUtil.delete(cacheKeys[i]);
      } catch (e) {
      }
    }
    // AppStorage 我的页数据
    try {
      AppStorage.setOrCreate('mine_name', '');
      AppStorage.setOrCreate('mine_card_balance', '--');
      AppStorage.setOrCreate('mine_book_count', '--');
      AppStorage.setOrCreate('mine_email_count', '--');
    } catch (e) {
    }
    // 清空 HTTP Cookie（含 WebView 会话）
    try {
      await HttpUtil.getInstance().clearCookies();
    } catch (e) {
    }
    // 课表落盘文件
    try {
      const context = getContext(this) as common.UIAbilityContext;
      const filesDir: string = context.filesDir;
      const delFiles: string[] = [];
      try {
        const dir: string[] = fileIo.listFileSync(filesDir);
        for (let i = 0; i < dir.length; i++) {
          if (dir[i].startsWith('class_table_') && dir[i].endsWith('.json')) {
            delFiles.push(filesDir + '/' + dir[i]);
          }
        }
      } catch (e) {
      }
      for (let i = 0; i < delFiles.length; i++) {
        try {
          fileIo.unlinkSync(delFiles[i]);
        } catch (e) {
        }
      }
    } catch (e) {
    }
  }

  // 根据服务的 tokenAccept 生成带认证的跳转 URL（复刻原 App handleUrl）
  // tokenAccept 形如 '[{"tokenType":"cas","tokenKey":"https://xxx/cas"}]'
  // 处理顺序（与原 App app-service.js 一致）：
  //   ① URL 含 {idToken} 占位符 → 直接替换为门户 JWT
  //   ② tokenAccept 非空：
  //      - tokenType=cas → 拼 CAS 登录链接: {tokenKey}/login?service={url}&idToken={JWT}
  //      - tokenType=url  → 往 URL 追加 tokenKey 命名的参数
  //   ③ 若 ①/② 都未处理，且 URL 前缀命中 casArry 白名单 → 追加 idToken 参数
  //   ④ 其余（如 hub.17wanxiao.com 等第三方域名）不加任何 token —— 原 App 亦然，
  //      这类页面凭原生 SDK cookie 会话登录，URL 传门户 JWT 反而报"三方唯一标识token为空"
  buildServiceUrl(url: string, tokenAccept: string): string {
    let result: string = url;
    if (url.length === 0) {
      return result;
    }
    const token: string = this.token();

    // ① {idToken} 占位符
    if (result.indexOf('{idToken}') >= 0) {
      result = result.replace(/\{idToken\}/g, token);
    }

    // ② tokenAccept
    let handled: boolean = false;
    if (tokenAccept.length > 0) {
      try {
        const list: Object[] = JSON.parse(tokenAccept) as Object[];
        for (let i = 0; i < list.length; i++) {
          const item: Record<string, Object> = list[i] as Record<string, Object>;
          const typeObj: Object | undefined = item['tokenType'];
          const keyObj: Object | undefined = item['tokenKey'];
          if (typeObj === undefined || keyObj === undefined) {
            continue;
          }
          const tokenType: string = String(typeObj).toLowerCase();
          const tokenKey: string = String(keyObj);
          if (tokenType === 'cas' && !result.startsWith(tokenKey)) {
            // CAS 登录跳转：{casUrl}/login?service={encodeURIComponent(url)}&idToken={token}
            handled = true;
            const casBase: string = tokenKey.endsWith('/') ? tokenKey : tokenKey + '/';
            const serviceEncoded: string = encodeURIComponent(result);
            result = casBase + 'login?service=' + serviceEncoded + '&idToken=' + token;
          } else if (token.length > 0) {
            // url 认证：加 tokenKey 参数（原 App addTokenForUrl 语义：已有同名参数则更新，不重复追加）
            handled = true;
            result = this.appendUrlParam(result, tokenKey, token);
          }
        }
      } catch (e) {
      }
    }

    // ③ casArry 兜底：仅当上面未处理且前缀命中白名单才加 idToken
    if (!handled && CAS_ARRY.length > 0) {
      for (let i = 0; i < CAS_ARRY.length; i++) {
        if (result.startsWith(CAS_ARRY[i])) {
          result = this.appendUrlParam(result, 'idToken', token);
          break;
        }
      }
    }
    return result;
  }

  // 往 URL 追加/更新查询参数（正确处理 # / ? 位置；已有同名参数则替换，避免重复）
  private appendUrlParam(url: string, key: string, value: string): string {
    const sharpPos: number = url.indexOf('#');
    let head: string = url;
    let fragment: string = '';
    if (sharpPos >= 0) {
      head = url.substring(0, sharpPos);
      fragment = url.substring(sharpPos);
    }
    // 若 head 已含同名参数（如服务列表下发的 URL 已带 idToken），原位替换而非追加
    const re: RegExp = new RegExp('([?&])' + key + '=[^&]*');
    if (re.test(head)) {
      return head.replace(re, '$1' + key + '=' + encodeURIComponent(value)) + fragment;
    }
    const sep: string = head.indexOf('?') >= 0 ? '&' : '?';
    return head + sep + key + '=' + encodeURIComponent(value) + fragment;
  }

  // ===== 我的页面数据 =====
  // 一卡通余额
  async getMyECard(): Promise<object | null> {
    const resp: HttpResponse = await this.requestJsonGet(PORTAL_BASE, 'v2/personalData/getMyECard');
    const r: SqgResult<object> = this.parseSqg<object>(resp);
    if (r.code === 0) {
      return r.data;
    }
    throw new Error(r.msg || '获取一卡通失败');
  }

  // 图书借阅
  async getMyBooks(): Promise<object | null> {
    const resp: HttpResponse = await this.requestJsonGet(PORTAL_BASE, 'v2/personalData/getMyBooks');
    const r: SqgResult<object> = this.parseSqg<object>(resp);
    if (r.code === 0) {
      return r.data;
    }
    throw new Error(r.msg || '获取图书失败');
  }

  // 邮箱未读
  async getMyEmail(): Promise<object | null> {
    const resp: HttpResponse = await this.requestJsonGet(PORTAL_BASE, 'v2/personalData/getMailbox');
    const r: SqgResult<object> = this.parseSqg<object>(resp);
    if (r.code === 0) {
      return r.data;
    }
    throw new Error(r.msg || '获取邮箱失败');
  }

  // ===== 我的页数据聚合（进入 App 后台拉取一次，写入缓存供 MineTab/HomeTab 读取）=====

  // 从返回对象里取值，兼容 {attributes:{...}} / 顶层字段两种结构
  private pickField(obj: Record<string, Object> | null | undefined, names: string[]): string {
    if (obj === null || obj === undefined) {
      return '';
    }
    let target: Record<string, Object> = obj;
    const attrs: Object | undefined = obj['attributes'];
    if (attrs !== undefined) {
      const attrsObj: Record<string, Object> = attrs as Record<string, Object>;
      if (attrsObj !== null) {
        target = attrsObj;
      }
    }
    for (let i = 0; i < names.length; i++) {
      const v: Object | undefined = target[names[i]];
      if (v !== undefined && v !== null) {
        return String(v);
      }
    }
    return '';
  }

  /**
   * 后台刷新「我的」页数据：姓名、一卡通余额、借书数、未读邮件。
   * 逐项 try/catch，单项失败不影响其它；结果写入 AppStorage + PreferenceUtil 缓存。
   * 调用方（MainPage 等）无需等待、无需 catch。
   */
  async refreshMineData(): Promise<void> {
    // 姓名：JWT ATTR_accountName 为准（原 App 做法），接口字段兜底
    const jwtName: string = this.getAccountName();
    let name: string = jwtName;
    if (name.length === 0) {
      try {
        const info = await this.getUserInfo() as Record<string, Object> | null;
        name = this.pickField(info, ['name', 'userName', 'realName', 'accountName']);
      } catch (e) {
      }
    }
    if (name.length > 0) {
      AppStorage.setOrCreate('mine_name', name);
      await PreferenceUtil.putString('mine_name_cached', name);
    }

    // 一卡通余额
    try {
      const card = await this.getMyECard() as Record<string, Object> | null;
      const bal: string = this.pickField(card, ['balance', 'amount', 'cardBalance', 'ecardBalance', 'totalMoney']);
      if (bal.length > 0) {
        AppStorage.setOrCreate('mine_card_balance', bal);
        await PreferenceUtil.putString('mine_card_balance_cached', bal);
      }
    } catch (e) {
    }

    // 借书数量
    try {
      const books = await this.getMyBooks() as Record<string, Object> | null;
      const cnt: string = this.pickField(books, ['count', 'borrowCount', 'total', 'totalCount', 'borrowNum']);
      if (cnt.length > 0) {
        AppStorage.setOrCreate('mine_book_count', cnt);
        await PreferenceUtil.putString('mine_book_count_cached', cnt);
      }
    } catch (e) {
    }

    // 未读邮件
    try {
      const email = await this.getMyEmail() as Record<string, Object> | null;
      const cnt: string = this.pickField(email, ['unReadCount', 'count', 'unread', 'total']);
      if (cnt.length > 0) {
        AppStorage.setOrCreate('mine_email_count', cnt);
        await PreferenceUtil.putString('mine_email_count_cached', cnt);
      }
    } catch (e) {
    }
  }

  // JSON GET（content-type application/json，避免 form 编码）
  private async requestJsonGet(baseUrl: string, path: string): Promise<HttpResponse> {
    const full: Record<string, string> = await this.getHeaders();
    const headers: Record<string, string> = {
      'X-Device-Info': full['X-Device-Info'] ?? '',
      'X-Device-Infos': full['X-Device-Infos'] ?? '',
      'X-Terminal-Info': full['X-Terminal-Info'] ?? '',
      'X-Id-Token': full['X-Id-Token'] ?? '',
      'Accept': 'application/json'
    };
    let base: string = baseUrl;
    if (base.length > 0 && !base.endsWith('/')) {
      base = base + '/';
    }
    let pathClean: string = path;
    if (pathClean.length > 0 && pathClean.startsWith('/')) {
      pathClean = pathClean.substring(1);
    }
    return this.http.get(base + pathClean, headers);
  }

  // ===== 课表 =====
  // 课表 base url 藏在服务列表分组结构里：data 是 [{label, services:[{serviceName, serviceUrl,...}]}]
  // 找名字含"课表"的服务项，取其 serviceUrl 的根地址（去掉 /h5/... 和 /api/... 路径）
  async findCourseTableUrl(): Promise<string> {
    // 优先用已缓存的
    const cached: string = PreferenceUtil.getString('cache_courseUrl');
    if (cached.length > 0) {
      return cached;
    }
    const list = await this.getServiceList();
    const base: string = this.findCourseTableIn(list);
    if (base.length > 0) {
      await PreferenceUtil.putString('cache_courseUrl', base);
      return base;
    }
    throw new Error('未找到课表服务');
  }

  // 课表 H5 地址：找到服务列表里课表服务的完整 serviceUrl（直接 WebView 打开）
  async getCourseTableH5Url(): Promise<string> {
    const cached: string = PreferenceUtil.getString('cache_courseH5Url');
    if (cached.length > 0) {
      return cached;
    }
    const list = await this.getServiceList();
    const h5: string = this.findCourseTableH5In(list);
    if (h5.length > 0) {
      await PreferenceUtil.putString('cache_courseH5Url', h5);
      return h5;
    }
    // 兜底：常见 H5 地址
    const fallback: string = 'https://i.sqgxy.edu.cn/h5/#/pages/courseTable/courseTable';
    return fallback;
  }

  // 递归查找课表服务的 H5 url（优先含 /h5/ 或 courseTable 的完整地址）
  private findCourseTableH5In(list: object[] | null): string {
    if (list === null || list === undefined) {
      return '';
    }
    for (let i = 0; i < list.length; i++) {
      const obj: Record<string, Object> = list[i] as Record<string, Object>;
      const servicesRaw: Object | undefined = obj['services'];
      if (servicesRaw !== undefined) {
        const services: Object[] = servicesRaw as Object[];
        const sub: string = this.findCourseTableH5In(services);
        if (sub.length > 0) {
          return sub;
        }
      }
      const url: Object | undefined = obj['serviceUrl'] ?? obj['url'];
      const name: Object | undefined = obj['serviceName'] ?? obj['name'];
      if (url !== undefined) {
        const u: string = String(url);
        const n: string = name === undefined ? '' : String(name);
        if (n.includes('课表') || u.includes('courseTable') || u.includes('/h5/')) {
          return u;
        }
      }
    }
    return '';
  }

  // 递归查找课表服务 url 根地址
  private findCourseTableIn(list: object[] | null): string {
    if (list === null || list === undefined) {
      return '';
    }
    for (let i = 0; i < list.length; i++) {
      const obj: Record<string, Object> = list[i] as Record<string, Object>;
      // 分组结构：{label, services:[...]}
      const servicesRaw: Object | undefined = obj['services'];
      if (servicesRaw !== undefined) {
        const services: Object[] = servicesRaw as Object[];
        const sub: string = this.findCourseTableIn(services);
        if (sub.length > 0) {
          return sub;
        }
      }
      const url: Object | undefined = obj['serviceUrl'] ?? obj['url'];
      const name: Object | undefined = obj['serviceName'] ?? obj['name'];
      if (url !== undefined) {
        const u: string = String(url);
        const n: string = name === undefined ? '' : String(name);
        if (n.includes('课表') || u.includes('/api/semester') || u.includes('courseTable') || u.includes('schedule')) {
          const base: string = this.stripServicePath(u);
          if (base.length > 0) {
            return base;
          }
        }
      }
    }
    return '';
  }

  // 从服务 url 提取课表 base：保留到 /token/（课表 API 挂在 cas.sqgxy.edu.cn/token/ 下），否则取 host
  private stripServicePath(url: string): string {
    const tokenIdx: number = url.indexOf('/token/');
    if (tokenIdx > 0) {
      return url.substring(0, tokenIdx + '/token/'.length);
    }
    const m: RegExpMatchArray | null = url.match(/^(https?:\/\/[^/]+)/);
    return m ? m[1] : url;
  }

  // 学期列表
  async getSemesters(courseUrl: string): Promise<object[]> {
    const resp: HttpResponse = await this.requestWithToken('GET', courseUrl, 'api/semester/list');
    const r: SqgResult<object[]> = this.parseSqg<object[]>(resp);
    if (r.code === 0 && r.data !== null) {
      return r.data;
    }
    throw new Error(r.msg || '获取学期失败');
  }

  // 当前周次信息
  async getCurrentWeek(courseUrl: string): Promise<object | null> {
    const resp: HttpResponse = await this.requestWithToken('GET', courseUrl, 'api/semester/currentWeek');
    const r: SqgResult<object> = this.parseSqg<object>(resp);
    if (r.code === 0) {
      return r.data;
    }
    throw new Error(r.msg || '获取周次失败');
  }

  // 按日课表（date 格式 YYYY-MM-DD）→ data.courseMap
  async getCourseTableByDay(courseUrl: string, date: string): Promise<object[] | null> {
    const query: Record<string, string> = {};
    query['date'] = date;
    const resp: HttpResponse = await this.requestWithToken('GET', courseUrl, 'api/courseTable/day', query);
    const r: SqgResult<object> = this.parseSqg<object>(resp);
    if (r.code === 0 && r.data !== null) {
      const dataObj: Record<string, Object> = r.data as Record<string, Object>;
      // courseMap 形如 { "1": [课程...], "2": [...] }，转成按星期索引的数组（1-7）
      const rawMap: Object | undefined = dataObj['courseMap'];
      let mapObj: Record<string, Object> = new Object() as Record<string, Object>;
      if (rawMap !== undefined) {
        mapObj = rawMap as Record<string, Object>;
      }
      const result: object[] = [];
      for (let d = 1; d <= 7; d++) {
        const key: string = String(d);
        const day: Object | undefined = mapObj[key];
        if (day !== undefined) {
          result.push(day);
        }
      }
      return result;
    }
    throw new Error(r.msg || '获取课表失败');
  }
}
