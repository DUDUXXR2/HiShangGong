// MineTab.ets — 我的页（完整复刻 Authenticator-main MePageContent）
// 结构完全照抄：WaterFlow 卡片流 = 头像卡 + 分类操作卡；ImmersionCardSurface 玻璃光感；
// 按压 scale 动画、边框、分隔线、深浅色全部与开源器一致。仅数据源替换为云上商工。
import { ThemeColors } from '../../utils/ThemeColors';
import { PreferenceUtil } from '../../utils/PreferenceUtil';
import { SqgService } from '../../services/SqgService';
import { MaterialConfig } from '../../utils/MaterialConfig';
import { WebPageParam } from '../NavParams';
import { HdsTabs } from '@kit.UIDesignKit';

const TAG = 'MineTab';

// ===== 复刻 Authenticator 常量 =====
const HOME_HORIZONTAL_PADDING: number = 20;
const PAGE_CARD_GAP: number = 10;
const HOME_TITLE_HEIGHT: number = 56;
const HOME_NAV_HEIGHT: number = 52;
const CARD_PRESS_ANIMATION_DURATION: number = 160;
const CARD_PRESSED_SCALE: number = 0.97;
const ME_CARD_RADIUS: number = 15;
const ME_LOGIN_CARD_HEIGHT: number = 75;
const ME_ROW_HEIGHT: number = 60;
const ME_AVATAR_SIZE: number = 48;
const ME_ACTION_TEXT_SIZE: number = 15;
const ME_ACTION_ICON_SIZE: number = 20;
const ME_ACTION_CONTENT_GAP: number = 16;

@Component
export struct MineTab {
  @Consume('pageStack') pageStack: NavPathStack;
  @StorageProp('statusBarHeight') statusBarHeight: number = 0;
  @StorageProp('bottomRectHeight') bottomRectHeight: number = 0;
  @StorageLink('theme_is_dark') themeIsDark: boolean = false;
  @State name: string = '';
  @State account: string = '';
  @State cardBalance: string = '--';
  @State emailCount: string = '--';
  @State bookCount: string = '--';
  @State avatarUrl: string = '';
  @State avatarLoadFailed: boolean = false;
  @State pressedCardId: string = '';
  private meScroller: Scroller = new Scroller();

  aboutToAppear(): void {
    this.account = PreferenceUtil.getString('ids_account');
    this.loadData();
  }

  private async loadData(): Promise<void> {
    const svc = SqgService.getInstance();
    this.avatarUrl = svc.getPortraitUrl();
    this.avatarLoadFailed = false;
    const cachedName: string = PreferenceUtil.getString('mine_name_cached');
    const cachedBal: string = PreferenceUtil.getString('mine_card_balance_cached');
    const cachedBooks: string = PreferenceUtil.getString('mine_book_count_cached');
    const cachedEmail: string = PreferenceUtil.getString('mine_email_count_cached');
    if (cachedName.length > 0) { this.name = cachedName; }
    if (cachedBal.length > 0) { this.cardBalance = cachedBal; }
    if (cachedBooks.length > 0) { this.bookCount = cachedBooks; }
    if (cachedEmail.length > 0) { this.emailCount = cachedEmail; }

    svc.refreshMineData().then(() => {
      const n: string = AppStorage.get<string>('mine_name') ?? '';
      const b: string = AppStorage.get<string>('mine_card_balance') ?? '';
      const bk: string = AppStorage.get<string>('mine_book_count') ?? '';
      const em: string = AppStorage.get<string>('mine_email_count') ?? '';
      if (n.length > 0) { this.name = n; }
      if (b.length > 0) { this.cardBalance = b; }
      if (bk.length > 0) { this.bookCount = bk; }
      if (em.length > 0) { this.emailCount = em; }
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

  // ===== 复刻 Authenticator 颜色/材质支撑 =====

  private isDark(): boolean {
    return this.themeIsDark;
  }

  private pageBackgroundColor(): string {
    return this.themeIsDark ? '#000000' : '#F2F3F5';
  }

  private primaryTextColor(): string {
    return this.themeIsDark ? '#E5E5E5' : '#1A1A1A';
  }

  private secondaryTextColor(): string {
    return this.themeIsDark ? '#999999' : '#666666';
  }

  private dividerColor(): string {
    return this.themeIsDark ? '#444444' : '#E6E6E6';
  }

  private shouldUseCardMaterial(): boolean {
    return MaterialConfig.shouldUseCardMaterial();
  }

  private cardBackgroundColor(): string {
    return this.themeIsDark ? '#191919' : '#FFFFFF';
  }

  private cardSurfaceBaseColor(fallback: ResourceColor): ResourceColor {
    return this.shouldUseCardMaterial() ? Color.Transparent : fallback;
  }

  private immersionBorderColor(): ResourceColor {
    return this.themeIsDark ? '#80FFFFFF' : '#80000000';
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

  // ===== 玻璃光感材质层（复刻 ImmersionMaterialLayer）=====

  @Builder
  ImmersionMaterialContent(cardHeight: number) {
    Stack()
      .width('100%')
      .height(cardHeight)
      .backgroundColor(Color.Transparent)
      .hitTestBehavior(HitTestMode.None)
  }

  @Builder
  ImmersionCardSurface(cardHeight: number, cardRadius: number) {
    Stack({ alignContent: Alignment.Center }) {
      if (this.shouldUseCardMaterial()) {
        HdsTabs() {
          TabContent() {
          }
          .backdropBlur(0)
          .tabBar(this.ImmersionMaterialContent(cardHeight))
          .clip(false)
        }
        .width('100%')
        .height(cardHeight)
        .barWidth('100%')
        .barHeight(cardHeight)
        .barOverlap(true)
        .barPosition(BarPosition.End)
        .barBackgroundStyle({ maskColor: '#00000000' })
        .barBackgroundBlurStyle(BlurStyle.NONE)
        .barFloatingStyle({
          barBottomMargin: 0,
          systemMaterialEffect: {
            materialType: MaterialConfig.configuredMaterialType(),
            materialLevel: MaterialConfig.configuredMaterialLevel()
          },
          gradientMask: { maskColor: '#09999999' }
        })
        .backgroundColor(Color.Transparent)
        .hitTestBehavior(HitTestMode.None)
        .clip(false)
      }
    }
    .width('100%')
    .height(cardHeight)
    .borderRadius(cardRadius)
    .clip(true)
    .backgroundColor(Color.Transparent)
    .hitTestBehavior(HitTestMode.None)
  }

  // ===== 头像卡（复刻 MeLoginCard + MeAvatar）=====

  @Builder
  MeAvatar() {
    if (this.avatarUrl.length > 0) {
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
          .fill(this.themeIsDark ? '#4A4A4A' : '#C7C7C7')
        Circle()
          .width(16)
          .height(16)
          .fill(this.themeIsDark ? '#777777' : '#9F9F9F')
          .position({ x: 16, y: 10 })
        Ellipse()
          .width(34)
          .height(20)
          .fill(this.themeIsDark ? '#777777' : '#9F9F9F')
          .position({ x: 7, y: 26 })
      }
      .width(ME_AVATAR_SIZE)
      .height(ME_AVATAR_SIZE)
    }
  }

  @Builder
  MeLoginCard() {
    Stack({ alignContent: Alignment.Center }) {
      this.ImmersionCardSurface(ME_LOGIN_CARD_HEIGHT, ME_CARD_RADIUS)
      Row({ space: ME_ACTION_CONTENT_GAP }) {
        this.MeAvatar()
        Column({ space: 4 }) {
          Text(this.name.length > 0 ? this.name : '未登录')
            .fontSize(ME_ACTION_TEXT_SIZE)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.primaryTextColor())
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(this.account)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.secondaryTextColor())
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .height(ME_LOGIN_CARD_HEIGHT)
      .padding({ left: 18, right: 20 })
      .alignItems(VerticalAlign.Center)
      .zIndex(2)
      .onClick(() => { this.pageStack.pushPathByName('ProfileCenterPage', undefined); })
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

  // ===== 分类操作卡（复刻 MeActionCard + MeActionRow）=====

  @Builder
  MeCardDivider() {
    Divider()
      .strokeWidth(1)
      .color(this.dividerColor())
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
  MeActionRow(label: string, icon: Resource, onClick: () => void) {
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
    .onClick(onClick)
  }

  @Builder
  MeActionCard(items: Array<ActionItem>, cardId: string) {
    Stack({ alignContent: Alignment.Top }) {
      this.ImmersionCardSurface(items.length * ME_ROW_HEIGHT + items.length - 1, ME_CARD_RADIUS)
      Column() {
        ForEach(items, (item: ActionItem, index: number) => {
          this.MeActionRow(item.label, item.icon, item.onClick)
          if (index < items.length - 1) {
            this.MeCardDivider()
          }
        }, (item: ActionItem) => item.label)
      }
      .width('100%')
      .height(items.length * ME_ROW_HEIGHT + items.length - 1)
      .padding({ left: 20, right: 18 })
      .zIndex(2)
    }
    .width('100%')
    .height(items.length * ME_ROW_HEIGHT + items.length - 1)
    .borderRadius(ME_CARD_RADIUS)
    .clip(true)
    .backgroundColor(this.cardSurfaceBaseColor(this.cardBackgroundColor()))
    .border({ width: this.cardSurfaceBorderWidth(), color: this.immersionBorderColor() })
    .scale({ x: this.appCardScale(cardId), y: this.appCardScale(cardId) })
    .animation({ duration: CARD_PRESS_ANIMATION_DURATION, curve: Curve.Friction })
    .onTouch((event: TouchEvent) => {
      this.handleAppCardTouch(cardId, event.type);
    })
  }

  build() {
    Stack() {
      WaterFlow({ scroller: this.meScroller }) {
        FlowItem() {
          this.MeLoginCard()
        }
        .width('100%')

        FlowItem() {
          this.MeActionCard([
            new ActionItem('一卡通余额', $r('sys.symbol.wallet'), () => {
              this.pageStack.pushPathByName('ProfileCenterPage', undefined);
            }),
            new ActionItem('我的邮箱', $r('sys.symbol.envelope'), () => {
              this.openH5('我的邮箱');
            }),
            new ActionItem('图书借阅', $r('sys.symbol.book'), () => {
              this.openH5('图书借阅');
            })
          ], 'me-cards')
        }
        .width('100%')

        FlowItem() {
          this.MeActionCard([
            new ActionItem('外观与主题', $r('sys.symbol.paintpalette'), () => {
              this.pageStack.pushPathByName('AppearancePage', undefined);
            }),
            new ActionItem('设置', $r('sys.symbol.gearshape'), () => {
              this.pageStack.pushPathByName('SettingsPage', undefined);
            })
          ], 'me-settings')
        }
        .width('100%')
      }
      .width('100%')
      .height('100%')
      .padding({ left: HOME_HORIZONTAL_PADDING, right: HOME_HORIZONTAL_PADDING })
      .contentStartOffset(this.statusBarHeight + HOME_TITLE_HEIGHT + PAGE_CARD_GAP)
      .contentEndOffset(this.naviIndicatorHeight() + HOME_NAV_HEIGHT + PAGE_CARD_GAP)
      .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
      .scrollBar(BarState.Off)
      .clip(false)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.pageBackgroundColor())
  }

  private openH5(title: string): void {
    this.pageStack.pushPathByName('ServiceWebPage', new WebPageParam(title, 'https://i.sqgxy.edu.cn/h5/'));
  }
}

// 分类卡条目
class ActionItem {
  label: string = '';
  icon: Resource = $r('sys.symbol.gearshape');
  onClick: () => void = () => { };

  constructor(label: string, icon: Resource, onClick: () => void) {
    this.label = label;
    this.icon = icon;
    this.onClick = onClick;
  }
}
