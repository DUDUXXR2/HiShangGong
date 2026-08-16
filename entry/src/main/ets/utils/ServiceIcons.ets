// ServiceIcons.ets — 服务图标映射（首页快捷按钮与服务页共用，保证图标完全一致）
// 图标优先级与服务页一致：服务列表下发的 iconUrl（网络）> 本地 svg 兜底 > 文字块
export class ServiceLocalIcon {
  icon: Resource = $r('app.media.ic_public_more');
  colored: boolean = false;

  constructor(icon: Resource, colored: boolean) {
    this.icon = icon;
    this.colored = colored;
  }
}

// 按服务名匹配本地 svg 兜底图标（与 ServiceTab.localIconFor 完全一致）
export function localIconFor(name: string): ServiceLocalIcon | undefined {
  const map: Record<string, ServiceLocalIcon> = {
    '节假日离返校': new ServiceLocalIcon($r('app.media.holiday'), true),
    '节假日': new ServiceLocalIcon($r('app.media.holiday'), true),
    '离返校': new ServiceLocalIcon($r('app.media.holiday'), true),
    '扫一扫': new ServiceLocalIcon($r('app.media.ic_public_scan_filled'), false),
    '日程': new ServiceLocalIcon($r('app.media.ic_public_calendar'), false),
    '缴电费': new ServiceLocalIcon($r('app.media.ic_bolt'), false),
    '校园卡': new ServiceLocalIcon($r('app.media.ic_card'), false),
    '影吧预约': new ServiceLocalIcon($r('app.media.film'), true),
    '影院预约': new ServiceLocalIcon($r('app.media.film'), true),
    '学生成绩查询': new ServiceLocalIcon($r('app.media.scoreselect'), true),
    '学生课表查询': new ServiceLocalIcon($r('app.media.stucourseselect'), true),
    '教师课表查询': new ServiceLocalIcon($r('app.media.stucourseselect'), true),
    '教室课表查询': new ServiceLocalIcon($r('app.media.stucourseselect'), true),
    '日常劳动上报': new ServiceLocalIcon($r('app.media.laborrreporting'), true),
    '人脸采集': new ServiceLocalIcon($r('app.media.ic_face'), false)
  };
  for (const key of Object.keys(map)) {
    if (name.indexOf(key) >= 0) {
      return map[key];
    }
  }
  return undefined;
}

export function localIconRes(name: string): Resource | undefined {
  const li = localIconFor(name);
  return li === undefined ? undefined : li.icon;
}

export function isColoredIcon(name: string): boolean {
  const li = localIconFor(name);
  return li !== undefined && li.colored;
}
