// HomeTab.ets — 首页
// 布局：搜索框固定不动（标题栏下方），下方滚动区域放两个快捷操作卡片（QuickActionGrid）
// 卡片为设置页风格玻璃卡片（表面不可点、可滑动），图标优先匹配服务页真实图标，其余匹配本地 svg
import { scanCore, scanBarcode } from '@kit.ScanKit';
import { common } from '@kit.AbilityKit';
import { ThemeColors } from '../../utils/ThemeColors';
import { SqgService } from '../../services/SqgService';
import { WebPageParam, isJwServiceName } from '../NavParams';
import { ToastUtil } from '../../utils/ToastUtil';
import { QuickActionGrid, QuickActionItem } from '../../components/QuickActionGrid';
import { localIconRes, isColoredIcon } from '../../utils/ServiceIcons';
import { CloudIconStore } from '../../utils/CloudIcons';
import { CloudColumnService } from '../../services/SqgService';
import { GlassCard } from '../../components/GlassCard';
import { ImmersionSearch } from '@tangs/components';
import { SearchModifier } from '../../components/SearchModifier';
import { MaterialConfig } from '../../utils/MaterialConfig';

const TAG = 'HomeTab';

const HOME_TITLE_HEIGHT: number = 56;
const HOME_NAV_HEIGHT: number = 52;
const PAGE_CARD_GAP: number = 10;
const HOME_HORIZONTAL_PADDING: number = 20;
const SEARCH_BAR_HEIGHT: number = 44;

class ServiceItem {
  name: string = '';
  iconUrl: string = '';
  url: string = '';
  tokenAccept: string = '';
}

@Component
export struct HomeTab {
  @Consume('pageStack') pageStack: NavPathStack;
  @State services: ServiceItem[] = [];
  @State searchText: string = '';
  @State searchResults: ServiceItem[] = [];
  @StorageProp('statusBarHeight') statusBarHeight: number = 0;
  @StorageProp('bottomRectHeight') bottomRectHeight: number = 0;
  @StorageLink('theme_is_dark') themeIsDark: boolean = false;

  // 缴电费/校园卡/扫一扫/日程/更多 用黑白图标（跟随系统深浅色）；其余彩色按钮（PNG）不染色
  private iconFillColor(label: string): ResourceColor {
    if (label === '扫一扫' || label === '日程' || label === '更多' ||
      label === '缴电费' || label === '校园卡') {
      return this.themeIsDark ? '#E5E5E5' : '#1A1A1A';
    }
    return '#2979FF';
  }

  // 首页按钮图标统一用本地资源：单色 SVG 按主题染色，彩色 PNG 不染色（colored）
  private makeLocalItem(label: string): QuickActionItem {
    const it: QuickActionItem = new QuickActionItem();
    it.label = label;
    const li = localIconRes(label);
    it.icon = li === undefined ? $r('app.media.ic_public_more') : li;
    it.fillColor = this.iconFillColor(label);
    it.colored = isColoredIcon(label);
    return it;
  }

  // 固定两行快捷按钮（第二行顺序按用户指定）
  private buildQuickRows(): QuickActionItem[][] {
    const row1Labels: string[] = ['扫一扫', '日程', '缴电费', '校园卡'];
    const row2Labels: string[] = ['影吧预约', '学生成绩查询', '学生课表查询', '日常劳动上报', '更多'];
    const row1: QuickActionItem[] = [];
    const row2: QuickActionItem[] = [];
    for (let i = 0; i < row1Labels.length; i++) {
      row1.push(this.makeLocalItem(row1Labels[i]));
    }
    for (let i = 0; i < row2Labels.length; i++) {
      row2.push(this.makeLocalItem(row2Labels[i]));
    }
    return [row1, row2];
  }

  private row1Actions(): QuickActionItem[] {
    return this.buildQuickRows()[0];
  }

  private row2Actions(): QuickActionItem[] {
    return this.buildQuickRows()[1];
  }

  aboutToAppear(): void {
    this.loadServices();
    CloudIconStore.load().catch(() => {
    });
  }

  private flattenServices(raw: object[] | null, out: ServiceItem[]): void {
    if (raw === null || raw === undefined) {
      return;
    }
    for (let i = 0; i < raw.length; i++) {
      const obj: Record<string, Object> = raw[i] as Record<string, Object>;
      const servicesRaw: Object | undefined = obj['services'];
      if (servicesRaw !== undefined) {
        const services: Object[] = servicesRaw as Object[];
        this.flattenServices(services, out);
        continue;
      }
      const item: ServiceItem = new ServiceItem();
      const name: Object | undefined = obj['serviceName'] ?? obj['name'];
      const iconUrl: Object | undefined = obj['iconUrl'] ?? obj['imgUrl'];
      const url: Object | undefined = obj['serviceUrl'] ?? obj['url'];
      const tokenAccept: Object | undefined = obj['tokenAccept'];
      item.name = name === undefined ? '' : String(name);
      item.iconUrl = iconUrl === undefined ? '' : String(iconUrl);
      item.url = url === undefined ? '' : String(url);
      item.tokenAccept = tokenAccept === undefined ? '' : String(tokenAccept);
      if (item.name.length > 0) {
        out.push(item);
      }
    }
  }

  private async loadServices(): Promise<void> {
    try {
      const list = await SqgService.getInstance().getServiceList();
      const items: ServiceItem[] = [];
      this.flattenServices(list, items);
      this.services = items;
    } catch (e) {
    }
  }

  private findService(name: string): ServiceItem | undefined {
    for (let i = 0; i < this.services.length; i++) {
      if (this.services[i].name === name) {
        return this.services[i];
      }
    }
    // 名称近似匹配（服务列表名称可能与按钮不同）
    for (let i = 0; i < this.services.length; i++) {
      if (this.services[i].name.indexOf(name) >= 0 || name.indexOf(this.services[i].name) >= 0) {
        return this.services[i];
      }
    }
    return undefined;
  }

  private openService(item: ServiceItem): void {
    let target: string = item.url;
    if (target.length === 0) {
      return;
    }
    if (target.startsWith('/')) {
      target = 'https://i.sqgxy.edu.cn' + target;
    }
    const finalUrl: string = SqgService.getInstance().buildServiceUrl(target, item.tokenAccept);
    if (isJwServiceName(item.name)) {
      this.pageStack.pushPathByName('JwWebPage', new WebPageParam(item.name, finalUrl));
    } else {
      this.pageStack.pushPathByName('ServiceWebPage', new WebPageParam(item.name, finalUrl));
    }
  }

  private openH5(title: string): void {
    this.pageStack.pushPathByName('ServiceWebPage', new WebPageParam(title, 'https://i.sqgxy.edu.cn/h5/'));
  }

  // 按钮动作分发
  private handleAction(label: string): void {
    if (label === '扫一扫') {
      this.openScanner();
      return;
    }
    if (label === '日程') {
      // 跳转到日程页 Tab（index 3）
      AppStorage.setOrCreate<number>('home_switch_tab_signal', 3);
      return;
    }
    if (label === '更多') {
      // 跳转到服务页 Tab（通过 AppStorage 信号，由 MainPage 在主线程切换）
      AppStorage.setOrCreate<number>('home_switch_tab_signal', 1);
      return;
    }
    if (label === '学生课表查询' || label === '教师课表查询') {
      this.openClassTable();
      return;
    }
    // 其余按钮：优先从服务列表取真实地址
    const svc = this.findService(label);
    if (svc !== undefined) {
      this.openService(svc);
      return;
    }
    // 云控快捷按钮：按标题匹配 serviceUrl/tokenAccept
    const cloud = CloudIconStore.findQuick(label);
    if (cloud !== undefined && cloud.serviceUrl.length > 0) {
      this.openCloudService(cloud);
      return;
    }
    this.openH5(label);
  }

  // 打开云控快捷按钮（serviceUrl/tokenAccept 来自云控接口）
  private openCloudService(item: CloudColumnService): void {
    let target: string = item.serviceUrl;
    if (target.length === 0) {
      return;
    }
    if (target.startsWith('/')) {
      target = 'https://i.sqgxy.edu.cn' + target;
    }
    const finalUrl: string = SqgService.getInstance().buildServiceUrl(target, item.tokenAccept);
    const title: string = item.serviceName.length > 0 ? item.serviceName : item.mainTitle;
    if (isJwServiceName(title)) {
      this.pageStack.pushPathByName('JwWebPage', new WebPageParam(title, finalUrl));
    } else {
      this.pageStack.pushPathByName('ServiceWebPage', new WebPageParam(title, finalUrl));
    }
  }

  // 原生扫一扫（Scan Kit 默认扫码 UI，无需摄像头权限）
  // 扫码后跳转逻辑（对应安卓 handleUrlForSysScan）：
  // - 结果是 http URL → 直接进 ServiceWebPage 打开
  // - 非 URL（校园码/付款码）→ 调 getScanInfo 解析出跳转地址
  private openScanner(): void {
    try {
      const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
      if (!ctx) {
        return;
      }
      const options: scanBarcode.ScanOptions = {
        scanTypes: [scanCore.ScanType.ALL],
        enableAlbum: true
      };
      scanBarcode.startScanForResult(ctx, options).then((result: scanBarcode.ScanResult) => {
        const raw: string = result.originalValue ?? '';
        if (raw.length === 0) {
          return;
        }
        if (raw.startsWith('http://') || raw.startsWith('https://')) {
          // http URL：直接打开网页
          this.pageStack.pushPathByName('ServiceWebPage', new WebPageParam('扫码结果', raw));
        } else {
          // 非 URL：调 getScanInfo 解析跳转地址
          SqgService.getInstance().getScanInfo(raw).then((target: string) => {
            if (target.length > 0) {
              this.pageStack.pushPathByName('ServiceWebPage', new WebPageParam('扫码结果', target));
            } else {
              this.getUIContext().getPromptAction().showToast({ message: '识别结果：' + raw });
            }
          });
        }
      }).catch(() => {
      });
    } catch (e) {
      ToastUtil.show('当前环境不支持扫码');
    }
  }

  // 课表查询：学生/教室课表都用现有课表 H5 页（ClassTablePage）
  private openClassTable(): void {
    this.pageStack.pushPathByName('ClassTablePage', undefined);
  }

  private onSearchChange(value: string): void {
    this.searchText = value;
    const kw: string = value.trim();
    this.searchResults = [];
    if (kw.length === 0) {
      return;
    }
    const low: string = kw.toLowerCase();
    for (let i = 0; i < this.services.length; i++) {
      const it: ServiceItem = this.services[i];
      if (it.name.toLowerCase().indexOf(low) >= 0) {
        this.searchResults.push(it);
      }
    }
  }

  private clearSearch(): void {
    this.searchText = '';
    this.searchResults = [];
  }

  private openSearchService(item: ServiceItem): void {
    let target: string = item.url;
    if (target.length === 0) {
      return;
    }
    if (target.startsWith('/')) {
      target = 'https://i.sqgxy.edu.cn' + target;
    }
    const finalUrl: string = SqgService.getInstance().buildServiceUrl(target, item.tokenAccept);
    if (isJwServiceName(item.name)) {
      this.pageStack.pushPathByName('JwWebPage', new WebPageParam(item.name, finalUrl));
    } else {
      this.pageStack.pushPathByName('ServiceWebPage', new WebPageParam(item.name, finalUrl));
    }
  }

  @Builder
  SearchBar() {
    ImmersionSearch({
      systemMaterialEffect: MaterialConfig.systemMaterialEffectParams(),
      _height: SEARCH_BAR_HEIGHT,
      options: { placeholder: '搜索服务' },
      modifier: new SearchModifier(
        ThemeColors.textPrimary,
        '#90A4AE',
        (value: string): void => { this.onSearchChange(value); }
      )
    })
    .height(SEARCH_BAR_HEIGHT)
    .width('100%')
    .clip(false)
  }

  @Builder
  SearchResultRow(item: ServiceItem) {
    Column() {
      GlassCard({ cardHeight: 56, cardRadius: 12 }) {
        Row() {
          if (item.iconUrl.length > 0) {
            Image(item.iconUrl).width(40).height(40).objectFit(ImageFit.Contain)
          } else {
            Text(item.name.substring(0, Math.min(1, item.name.length)))
              .width(40).height(40).fontSize(18).fontColor('#FFFFFF').textAlign(TextAlign.Center)
              .backgroundColor('#2979FF').borderRadius(10)
          }
          Text(item.name).fontSize(15).fontColor(ThemeColors.textPrimary)
            .margin({ left: 12 }).layoutWeight(1).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
          Text('›').fontSize(18).fontColor(ThemeColors.textSecondary).margin({ left: 10, right: 16 })
        }
        .width('100%').height(56).alignItems(VerticalAlign.Center)
        .padding({ left: 12 })
      }
    }
    .width('100%')
    .margin({ bottom: PAGE_CARD_GAP })
    .onClick(() => { this.openSearchService(item); })
  }

  build() {
    Stack({ alignContent: Alignment.Top }) {
      // 滚动内容（全屏，内容从悬浮搜索框下方穿过，透过毛玻璃可见）
      if (this.searchResults.length === 0) {
        Scroll() {
          Column() {
            QuickActionGrid({
              row1: this.row1Actions(),
              row2: this.row2Actions(),
              onAction: (label: string) => { this.handleAction(label); }
            })
            .width('100%')
          }
          .width('100%')
          .padding({ left: HOME_HORIZONTAL_PADDING, right: HOME_HORIZONTAL_PADDING, bottom: 24 })
        }
        .width('100%')
        .height('100%')
        .align(Alignment.Top)
        .padding({
          top: this.statusBarHeight + HOME_TITLE_HEIGHT + PAGE_CARD_GAP + SEARCH_BAR_HEIGHT + PAGE_CARD_GAP
        })
        .contentEndOffset(this.bottomRectHeight + HOME_NAV_HEIGHT + PAGE_CARD_GAP)
        .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
        .scrollBar(BarState.Off)
        .clip(false)
      } else {
        Scroll() {
          Column() {
            ForEach(this.searchResults, (item: ServiceItem, index: number) => {
              this.SearchResultRow(item)
            }, (item: ServiceItem, index: number) => 'hsr_' + index + '_' + item.name)
          }
          .width('100%')
          .padding({ left: HOME_HORIZONTAL_PADDING, right: HOME_HORIZONTAL_PADDING, bottom: 24 })
        }
        .width('100%')
        .height('100%')
        .align(Alignment.Top)
        .padding({
          top: this.statusBarHeight + HOME_TITLE_HEIGHT + PAGE_CARD_GAP + SEARCH_BAR_HEIGHT + PAGE_CARD_GAP
        })
        .contentEndOffset(this.bottomRectHeight + HOME_NAV_HEIGHT + PAGE_CARD_GAP)
        .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
        .scrollBar(BarState.Off)
        .clip(false)
      }

      // 悬浮搜索框（毛玻璃，定位在内容之上，内容滚动从其下方穿过）
      Row() {
        this.SearchBar()
      }
      .width('100%')
      .padding({ left: HOME_HORIZONTAL_PADDING, right: HOME_HORIZONTAL_PADDING })
      .position({ x: 0, y: this.statusBarHeight + HOME_TITLE_HEIGHT + PAGE_CARD_GAP })
      .zIndex(12)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Transparent)
  }
}
