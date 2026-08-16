// CloudIcons.ets — 云控图标/快捷按钮存储（单例）
// 首页快捷按钮与服务页图标统一从云控接口 getAppThemeDetail 取：
// - columnType=11 的 columnServices → 首页快捷按钮（cardImage 图标）
// - 全部 columnServices 建立 serviceName → cardImage/iconUrl 映射 → 服务页图标
import { CloudColumnService, SqgService } from '../services/SqgService';

const PORTAL_BASE: string = 'https://i.sqgxy.edu.cn/portal-api/';

export class CloudIconStore {
  private static map: Map<string, CloudColumnService> = new Map();
  private static loaded: boolean = false;
  private static quickList: CloudColumnService[] = [];

  // 加载云控数据（幂等：只加载一次，失败静默）
  static async load(): Promise<void> {
    if (CloudIconStore.loaded) {
      return;
    }
    CloudIconStore.loaded = true;
    try {
      const columns: object[] | null = await SqgService.getInstance().getAppThemeDetail();
      if (columns === null) {
        return;
      }
      for (let i = 0; i < columns.length; i++) {
        const col: Record<string, Object> = columns[i] as Record<string, Object>;
        const type: number = Number(col['columnType'] ?? 0);
        const servicesRaw: Object[] = (col['columnServices'] as Object[]) ?? [];
        for (let s = 0; s < servicesRaw.length; s++) {
          const svc: CloudColumnService = CloudIconStore.parseService(servicesRaw[s]);
          if (svc.serviceName.length > 0) {
            CloudIconStore.map.set(svc.serviceName, svc);
          }
          if (svc.mainTitle.length > 0 && svc.mainTitle !== svc.serviceName) {
            CloudIconStore.map.set(svc.mainTitle, svc);
          }
          if (type === 11 && svc.id.length > 0 && svc.isShow !== '0') {
            CloudIconStore.quickList.push(svc);
          }
        }
      }
    } catch (e) {
      // 静默失败：后续 iconUrlFor/quickActions 返回空，页面走本地兜底
    }
  }

  private static parseService(raw: Object): CloudColumnService {
    const obj: Record<string, Object> = raw as Record<string, Object>;
    const svc: CloudColumnService = new CloudColumnService();
    svc.id = String(obj['id'] ?? '');
    svc.cardImage = String(obj['cardImage'] ?? '');
    svc.iconUrl = String(obj['iconUrl'] ?? '');
    svc.serviceName = String(obj['serviceName'] ?? obj['mainTitle'] ?? '');
    svc.serviceUrl = String(obj['serviceUrl'] ?? '');
    svc.mainTitle = String(obj['mainTitle'] ?? '');
    svc.subTitle = String(obj['subTitle'] ?? '');
    svc.backColor = String(obj['backColor'] ?? '');
    svc.fontColor = String(obj['fontColor'] ?? '');
    svc.orderNumber = Number(obj['orderNumber'] ?? 0);
    svc.isShow = String(obj['isShow'] ?? '');
    svc.tokenAccept = String(obj['tokenAccept'] ?? '');
    svc.serviceId = String(obj['serviceId'] ?? '');
    return svc;
  }

  // 按服务名匹配云控图标 URL（cardImage 优先，其次 iconUrl）；相对路径补域名
  static iconUrlFor(name: string): string {
    const svc: CloudColumnService | undefined = CloudIconStore.map.get(name);
    if (svc === undefined) {
      return '';
    }
    let url: string = svc.cardImage.length > 0 ? svc.cardImage : svc.iconUrl;
    if (url.length > 0 && url.startsWith('/')) {
      url = PORTAL_BASE + url.substring(1);
    }
    return url;
  }

  // 首页快捷按钮（columnType=11，按 orderNumber 排序，最多 8 个）
  static quickActions(): CloudColumnService[] {
    const list: CloudColumnService[] = CloudIconStore.quickList;
    if (list.length > 1) {
      list.sort((a: CloudColumnService, b: CloudColumnService) => a.orderNumber - b.orderNumber);
    }
    return list.slice(0, 8);
  }

  // 按快捷按钮标题精确查找（供首页 handleAction 跳转）
  static findQuick(label: string): CloudColumnService | undefined {
    const svc: CloudColumnService | undefined = CloudIconStore.map.get(label);
    if (svc !== undefined) {
      return svc;
    }
    for (let i = 0; i < CloudIconStore.quickList.length; i++) {
      const it: CloudColumnService = CloudIconStore.quickList[i];
      if (it.serviceName === label || it.mainTitle === label) {
        return it;
      }
    }
    return undefined;
  }
}
