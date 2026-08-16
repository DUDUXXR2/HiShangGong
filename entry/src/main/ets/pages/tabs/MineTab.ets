// MineTab.ets — 我的页
// 头像卡 + 三列数据卡（一卡通余额/我的邮箱/图书借阅）+ 外观与主题/设置
// ImmersionCardSurface 玻璃光感 / 按压 scale 动画 / 深浅色 / 边框
import { HdsTabs, hdsMaterial } from '@kit.UIDesignKit';
import { router } from '@kit.ArkUI';
import { ThemeColors } from '../../utils/ThemeColors';
import { PreferenceUtil } from '../../utils/PreferenceUtil';
import { SqgService } from '../../services/SqgService';
import { MaterialConfig } from '../../utils/MaterialConfig';
import { WebPageParam } from '../NavParams';

const TAG = 'MineTab';

// ===== 常量 =====
const HOME_HORIZONTAL_PADDING: number = 20;
const PAGE_CARD_GAP: number = 10;
const HOME_TITLE_HEIGHT: number = 56;
const HOME_NAV_HEIGHT: number = 52;
const CARD_PRESS_ANIMATION_DURATION: number = 160;
const CARD_PRESSED_SCALE: number = 0.97;
const RESPONSIVE_CARD_MAX_WIDTH: number = 480;
const ME_CARD_RADIUS: number = 15;
const ME_LOGIN_CARD_HEIGHT: number = 75;
const ME_ROW_HEIGHT: number = 60;
const ME_AVATAR_SIZE: number = 48;
const ME_TEXT_SIZE: number = 18;
const ME_ACTION_TEXT_SIZE: number = 15;
const ME_ACTION_ICON_SIZE: number = 20;
const ME_ACTION_CONTENT_GAP: number = 16;
const ME_STATS_CARD_HEIGHT: number = 120;
const ME_STATS_ICON_SIZE: number = 26;
const ME_STATS_NAME_SIZE: number = 13;
const ME_STATS_VALUE_SIZE: number = 17;
const ME_STATS_UNIT_SIZE: number = 12;

class ServiceItem {
  name: string = '';
  iconUrl: string = '';
  url: string = '';
  tokenAccept: string = '';
}

class StatsItem {
  label: string = '';
  icon: Resource = $r('app.media.ic_wallet');
  value: string = '0';
  unit: string = '';
  onClick: () => void = () => {
  };

  constructor(label: string, icon: Resource, value: string, unit: string, onClick: () => void) {
    this.label = label;
    this.icon = icon;
    this.value = value;
    this.unit = unit;
    this.onClick = onClick;
  }
}

@Component
export struct MineTab {
  @Consume('pageStack') pageStack: NavPathStack;
  @StorageProp('statusBarHeight') statusBarHeight: number = 0;
  @StorageProp('bottomRectHeight') bottomRectHeight: number = 0;
  @StorageProp('ui_material_version') materialVersion: number = 0;
  @StorageLink('theme_is_dark') themeIsDark: boolean = false;
  @State name: string = '';
  @State account: string = '';
  @State avatarUrl: string = '';
  @State avatarLoadFailed: boolean = false;
  @State loggedIn: boolean = true;
  @State pressedCardId: string = '';
  @State pageWidth: number = 0;
  // 三列数据
  @State balance: string = '0.00';
  @State emailCount: string = '0';
  @State bookCount: string = '0';
  @State services: ServiceItem[] = [];
  private meScroller: Scroller = new Scroller();

  aboutToAppear(): void {
    this.account = PreferenceUtil.getString('ids_account');
    this.loggedIn = SqgService.getInstance().isLoggedIn();
    this.loadData();
    this.loadServices();
  }

  private async loadData(): Promise<void> {
    const svc = SqgService.getInstance();
    this.avatarUrl = svc.getPortraitUrl();
    this.avatarLoadFailed = false;
    const cachedName: string = PreferenceUtil.getString('mine_name_cached');
    if (cachedName.length > 0) {
      this.name = cachedName;
    }
    this.applyCachedStats();
    svc.refreshMineData().then(() => {
      const n: string = AppStorage.get<string>('mine_name') ?? '';
      if (n.length > 0) {
        this.name = n;
      }
      this.applyCachedStats();
    }).catch(() => {
    });
    if (this.name.length === 0) {
      try {
        const jwtName: string = svc.getAccountName();
        if (jwtName.length > 0) {
          this.name = jwtName;
        }
      } catch (e) {
      }
    }
  }

  // 从 AppStorage/缓存读取三列数值（无值或空则默认 0）
  private applyCachedStats(): void {
    this.balance = this.formatBalance(AppStorage.get<string>('mine_card_balance') ?? PreferenceUtil.getString('mine_card_balance_cached'));
    this.emailCount = this.formatCount(AppStorage.get<string>('mine_email_count') ?? PreferenceUtil.getString('mine_email_count_cached'));
    this.bookCount = this.formatCount(AppStorage.get<string>('mine_book_count') ?? PreferenceUtil.getString('mine_book_count_cached'));
  }

  private formatBalance(raw: string): string {
    const num: number = Number(raw);
    if (raw.length === 0 || isNaN(num)) {
      return '0.00';
    }
    return num.toFixed(2);
  }

  private formatCount(raw: string): string {
    const num: number = Number(raw);
    if (raw.length === 0 || isNaN(num)) {
      return '0';
    }
    return String(Math.round(num));
  }

  // ===== 校园卡跳转（复用主页 openQuick('校园卡') 逻辑）=====

  private async loadServices(): Promise<void> {
    try {
      const list = await SqgService.getInstance().getServiceList();
      const items: ServiceItem[] = [];
      this.flattenServices(list, items);
      this.services = items;
    } catch (e) {
    }
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

  private findService(name: string): ServiceItem | undefined {
    for (let i = 0; i < this.services.length; i++) {
      if (this.services[i].name === name) {
        return this.services[i];
      }
    }
    return undefined;
  }

  private openCampusCard(): void {
    const svc = this.findService('校园卡');
    if (svc !== undefined) {
      this.openService(svc);
      return;
    }
    this.pageStack.pushPathByName('ServiceWebPage',
      new WebPageParam('校园卡', 'https://i.sqgxy.edu.cn/h5/'));
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
    this.pageStack.pushPathByName('ServiceWebPage', new WebPageParam(item.name, finalUrl));
  }

  private openH5(title: string): void {
    this.pageStack.pushPathByName('ServiceWebPage', new WebPageParam(title, 'https://i.sqgxy.edu.cn/h5/'));
  }

  // ===== 颜色/主题支撑 =====

  private isDark(): boolean {
    return this.themeIsDark;
  }

  private pageBackgroundColor(): string {
    return this.isDark() ? '#000000' : '#F2F3F5';
  }

  private primaryTextColor(): string {
    return this.isDark() ? '#EEEEEE' : '#1A1A1A';
  }

  private secondaryTextColor(): string {
    if (this.shouldUseCardMaterial()) {
      return this.isDark() ? '#D0D0D0' : '#4A4A4A';
    }
    return this.isDark() ? '#B8B8B8' : '#666666';
  }

  private dividerColor(): string {
    return this.isDark() ? '#444444' : '#E6E6E6';
  }

  private cardBackgroundColor(): string {
    return this.isDark() ? '#191919' : '#FFFFFF';
  }

  private accentColor(): string {
    return ThemeColors.accent;
  }

  private shouldUseCardMaterial(): boolean {
    return MaterialConfig.shouldUseCardMaterial();
  }

  private configuredMaterialType(): hdsMaterial.MaterialType {
    return MaterialConfig.configuredMaterialType();
  }

  private configuredMaterialLevel(): hdsMaterial.MaterialLevel {
    return MaterialConfig.configuredMaterialLevel();
  }

  private cardSurfaceBaseColor(fallback: ResourceColor): ResourceColor {
    return this.shouldUseCardMaterial() ? Color.Transparent : fallback;
  }

  private immersionBorderColor(): ResourceColor {
    return this.isDark() ? '#80FFFFFF' : '#80000000';
  }

  private cardSurfaceBorderWidth(): number {
    return this.shouldUseCardMaterial() ? 0.5 : 0;
  }

  private naviIndicatorHeight(): number {
    return this.bottomRectHeight;
  }

  private appCardScale(cardId: string): number {
    return this.pressedCardId === cardId ? CARD_PRESSED_SCALE : 1;
  }

  private handleAppCardTouch(cardId: string, type: TouchType): void {
    if (type === TouchType.Down) {
      this.pressedCardId = cardId;
    } else if ((type === TouchType.Up || type === TouchType.Cancel) && this.pressedCardId === cardId) {
      this.pressedCardId = '';
    }
  }

  // ===== 玻璃光感材质层 =====

  private immersionExpandedWidth(cardHeight: number): number {
    return Math.max(this.pageWidth, RESPONSIVE_CARD_MAX_WIDTH) + this.immersionMaterialBarHeight(cardHeight) * 2;
  }

  private immersionMaterialBarHeight(cardHeight: number): number {
    return cardHeight;
  }

  @Builder
  ImmersionMaterialContent(cardHeight: number) {
    Stack()
      .width(this.immersionExpandedWidth(cardHeight))
      .height(this.immersionMaterialBarHeight(cardHeight))
      .backgroundColor(Color.Transparent)
      .hitTestBehavior(HitTestMode.None)
  }

  @Builder
  ImmersionMaterialLayer(cardHeight: number, cardRadius: number) {
    Stack({ alignContent: Alignment.Center }) {
      HdsTabs() {
        TabContent() {
        }
        .backdropBlur(0)
        .tabBar(this.ImmersionMaterialContent(cardHeight))
        .clip(false)
      }
      .width(this.immersionExpandedWidth(cardHeight))
      .height(cardHeight)
      .barWidth(this.immersionExpandedWidth(cardHeight))
      .barHeight(this.immersionMaterialBarHeight(cardHeight))
      .barOverlap(true)
      .barPosition(BarPosition.End)
      .barBackgroundStyle({ maskColor: '#00000000' })
      .barBackgroundBlurStyle(BlurStyle.NONE)
      .barFloatingStyle({
        barBottomMargin: 0,
        systemMaterialEffect: {
          materialType: this.configuredMaterialType(),
          materialLevel: this.configuredMaterialLevel()
        }
      })
      .backgroundColor(Color.Transparent)
      .hitTestBehavior(HitTestMode.None)
      .clip(false)
    }
    .width('100%')
    .height(cardHeight)
    .borderRadius(cardRadius)
    .clip(true)
    .backgroundColor(Color.Transparent)
    .hitTestBehavior(HitTestMode.None)
    .zIndex(1)
  }

  @Builder
  ImmersionCardSurface(cardHeight: number, cardRadius: number) {
    this.ImmersionMaterialLayer(cardHeight, cardRadius)
  }

  // ===== 头像卡 =====

  @Builder
  MeAvatar() {
    if (this.avatarUrl.length > 0 && !this.avatarLoadFailed) {
      Image(this.avatarUrl)
        .width(ME_AVATAR_SIZE)
        .height(ME_AVATAR_SIZE)
        .borderRadius(ME_AVATAR_SIZE / 2)
        .objectFit(ImageFit.Cover)
        .onError(() => {
          this.avatarLoadFailed = true;
        })
    } else {
      Stack() {
        Circle()
          .width(ME_AVATAR_SIZE)
          .height(ME_AVATAR_SIZE)
          .fill(this.isDark() ? '#4A4A4A' : '#C7C7C7')
        Circle()
          .width(16)
          .height(16)
          .fill(this.isDark() ? '#777777' : '#9F9F9F')
          .position({ x: 16, y: 10 })
        Ellipse()
          .width(34)
          .height(20)
          .fill(this.isDark() ? '#777777' : '#9F9F9F')
          .position({ x: 7, y: 26 })
      }
      .width(ME_AVATAR_SIZE)
      .height(ME_AVATAR_SIZE)
    }
  }

  @Builder
  MeLoginCardContent() {
    Row({ space: ME_ACTION_CONTENT_GAP }) {
      this.MeAvatar()
      Column({ space: 4 }) {
        Text(this.name.length > 0 ? this.name : '未登录')
          .fontSize(ME_TEXT_SIZE)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.primaryTextColor())
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        if (this.loggedIn) {
          Text(this.account)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.secondaryTextColor())
        } else {
          Text('点击登录')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.secondaryTextColor())
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height(ME_LOGIN_CARD_HEIGHT)
    .padding({ left: 18, right: 20 })
    .alignItems(VerticalAlign.Center)
    .zIndex(2)
    .onClick(() => {
      if (this.loggedIn) {
        this.pageStack.pushPathByName('ProfileCenterPage', undefined);
      } else {
        router.replaceUrl({ url: 'pages/login/LoginPage' });
      }
    })
  }

  @Builder
  MeLoginCard() {
    Stack({ alignContent: Alignment.Center }) {
      this.ImmersionCardSurface(ME_LOGIN_CARD_HEIGHT, ME_CARD_RADIUS)
      this.MeLoginCardContent()
    }
    .width('100%')
    .height(ME_LOGIN_CARD_HEIGHT)
    .borderRadius(ME_CARD_RADIUS)
    .clip(true)
    .backgroundColor(this.cardSurfaceBaseColor(this.cardBackgroundColor()))
    .border({ width: this.cardSurfaceBorderWidth(), color: this.immersionBorderColor() })
    .scale({ x: this.appCardScale('me-login'), y: this.appCardScale('me-login') })
    .animation({ duration: CARD_PRESS_ANIMATION_DURATION, curve: Curve.Friction })
    .onTouch((event: TouchEvent) => {
      this.handleAppCardTouch('me-login', event.type);
    })
  }

  // ===== 三列数据卡（一卡通余额 / 我的邮箱 / 图书借阅）=====

  @Builder
  MeStatsItem(item: StatsItem) {
    Column({ space: 6 }) {
      Image(item.icon)
        .width(ME_STATS_ICON_SIZE)
        .height(ME_STATS_ICON_SIZE)
        .fillColor(this.accentColor())
        .objectFit(ImageFit.Contain)
      Text(item.label)
        .fontSize(ME_STATS_NAME_SIZE)
        .fontColor(this.secondaryTextColor())
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      Row({ space: 2 }) {
        Text(item.value)
          .fontSize(ME_STATS_VALUE_SIZE)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.primaryTextColor())
        Text(item.unit)
          .fontSize(ME_STATS_UNIT_SIZE)
          .fontColor(this.secondaryTextColor())
      }
      .alignItems(VerticalAlign.Bottom)
    }
    .layoutWeight(1)
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .onClick(item.onClick)
  }

  @Builder
  MeStatsCard() {
    Stack({ alignContent: Alignment.Top }) {
      this.ImmersionCardSurface(ME_STATS_CARD_HEIGHT, ME_CARD_RADIUS)
      Row() {
        this.MeStatsItem(new StatsItem('一卡通余额', $r('app.media.ic_wallet'), this.balance, '元', () => {
          this.openCampusCard();
        }))
        this.MeStatsItem(new StatsItem('我的邮箱', $r('app.media.ic_mail'), this.emailCount, '封', () => {
          this.openH5('我的邮箱');
        }))
        this.MeStatsItem(new StatsItem('图书借阅', $r('app.media.ic_book'), this.bookCount, '本', () => {
          this.openH5('图书借阅');
        }))
      }
      .width('100%')
      .height(ME_STATS_CARD_HEIGHT)
      .padding({ left: 8, right: 8 })
      .alignItems(VerticalAlign.Center)
      .zIndex(2)
    }
    .width('100%')
    .height(ME_STATS_CARD_HEIGHT)
    .borderRadius(ME_CARD_RADIUS)
    .clip(true)
    .backgroundColor(this.cardSurfaceBaseColor(this.cardBackgroundColor()))
    .border({ width: this.cardSurfaceBorderWidth(), color: this.immersionBorderColor() })
    .scale({ x: this.appCardScale('me-stats'), y: this.appCardScale('me-stats') })
    .animation({ duration: CARD_PRESS_ANIMATION_DURATION, curve: Curve.Friction })
    .onTouch((event: TouchEvent) => {
      this.handleAppCardTouch('me-stats', event.type);
    })
  }

  // ===== 分类操作卡 =====

  @Builder
  MeActionCardDivider() {
    Divider()
      .strokeWidth(1)
      .color(this.dividerColor())
      .margin({ left: ME_ACTION_ICON_SIZE + ME_ACTION_CONTENT_GAP })
  }

  @Builder
  TrailingArrowSymbol() {
    SymbolGlyph($r('sys.symbol.chevron_right'))
      .fontSize(ME_ACTION_ICON_SIZE)
      .fontColor([this.secondaryTextColor()])
      .fontWeight(FontWeight.Medium)
      .renderingStrategy(SymbolRenderingStrategy.SINGLE)
  }

  @Builder
  MeActionRow(label: string, icon: Resource, action: () => void) {
    Row({ space: 16 }) {
      SymbolGlyph(icon)
        .fontSize(ME_ACTION_ICON_SIZE)
        .fontColor([this.primaryTextColor()])
        .renderingStrategy(SymbolRenderingStrategy.SINGLE)
      Text(label)
        .fontSize(ME_ACTION_TEXT_SIZE)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.primaryTextColor())
        .layoutWeight(1)
      this.TrailingArrowSymbol()
    }
    .width('100%')
    .height(ME_ROW_HEIGHT)
    .alignItems(VerticalAlign.Center)
    .onClick(action)
  }

  @Builder
  MeActionCardContent(items: Array<[string, Resource]>, group: number) {
    Column() {
      ForEach(items, (item: [string, Resource], index: number) => {
        this.MeActionRow(item[0], item[1], () => {
          this.handleMeAction(group, index);
        })
        if (index < items.length - 1) {
          this.MeActionCardDivider()
        }
      }, (item: [string, Resource]) => item[0])
    }
    .width('100%')
    .height(items.length * ME_ROW_HEIGHT + items.length - 1)
    .padding({ left: 20, right: 18 })
    .zIndex(2)
  }

  @Builder
  MeActionCard(items: Array<[string, Resource]>, group: number) {
    Stack({ alignContent: Alignment.Top }) {
      this.ImmersionCardSurface(items.length * ME_ROW_HEIGHT + items.length - 1, ME_CARD_RADIUS)
      this.MeActionCardContent(items, group)
    }
    .width('100%')
    .height(items.length * ME_ROW_HEIGHT + items.length - 1)
    .borderRadius(ME_CARD_RADIUS)
    .clip(true)
    .backgroundColor(this.cardSurfaceBaseColor(this.cardBackgroundColor()))
    .border({ width: this.cardSurfaceBorderWidth(), color: this.immersionBorderColor() })
    .scale({ x: this.appCardScale('me-action-' + group.toString()),
      y: this.appCardScale('me-action-' + group.toString()) })
    .animation({ duration: CARD_PRESS_ANIMATION_DURATION, curve: Curve.Friction })
    .onTouch((event: TouchEvent) => {
      this.handleAppCardTouch('me-action-' + group.toString(), event.type);
    })
  }

  // ===== Action 分发 =====

  private handleMeAction(group: number, index: number): void {
    if (group === 0) {
      if (index === 0) {
        this.pageStack.pushPathByName('AppearancePage', undefined);
      } else {
        this.pageStack.pushPathByName('SettingsPage', undefined);
      }
      return;
    }
  }

  build() {
    Stack() {
      WaterFlow({ scroller: this.meScroller }) {
        FlowItem() {
          Column() {
            Blank()
              .height(this.statusBarHeight + HOME_TITLE_HEIGHT + PAGE_CARD_GAP)
          }
          .width('100%')
        }
        .width('100%')

        FlowItem() {
          this.MeLoginCard()
        }
        .width('100%')

        FlowItem() {
          this.MeStatsCard()
        }
        .width('100%')

        FlowItem() {
          this.MeActionCard([
            ['外观与主题', $r('sys.symbol.paintpalette')],
            ['设置', $r('sys.symbol.gearshape')]
          ], 0)
        }
        .width('100%')
      }
      .width('100%')
      .height('100%')
      .padding({ left: HOME_HORIZONTAL_PADDING, right: HOME_HORIZONTAL_PADDING })
      .rowsGap(PAGE_CARD_GAP)
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
      .contentEndOffset(this.naviIndicatorHeight() + HOME_NAV_HEIGHT + PAGE_CARD_GAP)
      .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
      .scrollBar(BarState.Off)
      .clip(false)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Transparent)
    .onAreaChange((oldValue: Area, newValue: Area) => {
      const w: number = Math.round(newValue.width as number);
      if (w > 0 && Math.abs(w - this.pageWidth) > 1) {
        this.pageWidth = w;
      }
    })
  }
}
