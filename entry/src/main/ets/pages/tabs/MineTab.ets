import { ThemeColors } from '../../utils/ThemeColors';
import { PreferenceUtil } from '../../utils/PreferenceUtil';
import { SqgService } from '../../services/SqgService';
import { MaterialConfig } from '../../utils/MaterialConfig';
import { WebPageParam } from '../NavParams';
import { HdsTabs } from '@kit.UIDesignKit';

const TAG = 'MineTab';

@Component
export struct MineTab {
  @Consume('pageStack') pageStack: NavPathStack;
  @State name: string = '';
  @State account: string = '';
  @State cardBalance: string = '--';
  @State emailCount: string = '--';
  @State bookCount: string = '--';
  @State avatarUrl: string = '';
  @State avatarLoadFailed: boolean = false;
  @StorageProp('statusBarHeight') statusBarHeight: number = 0;

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

  private openH5(title: string): void {
    this.pageStack.pushPathByName('ServiceWebPage', new WebPageParam(title, 'https://i.sqgxy.edu.cn/h5/'));
  }

  @Builder
  CardCell(icon: Resource, label: string, value: string, color: string) {
    Column() {
      Image(icon)
        .width(28).height(28).fillColor(color).objectFit(ImageFit.Contain)
      Text(label).fontSize(12).fontColor(ThemeColors.textSecondary).margin({ top: 8 })
      Text(value).fontSize(15).fontWeight(FontWeight.Bold).fontColor(color).margin({ top: 4 })
    }
    .layoutWeight(1).padding({ top: 16, bottom: 16 })
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  ListItem(icon: Resource, label: string, onClick: () => void = () => { }) {
    Row() {
      Image(icon)
        .width(20).height(20).fillColor(ThemeColors.textPrimary).objectFit(ImageFit.Contain)
        .margin({ left: 16, right: 14 })
      Text(label).fontSize(15).fontColor(ThemeColors.textPrimary).layoutWeight(1)
      Text('›').fontSize(18).fontColor(ThemeColors.textSecondary).margin({ right: 16 })
    }
    .width('100%').height(50).alignItems(VerticalAlign.Center)
    .onClick(onClick)
  }

  // 头像模块（复刻 Authenticator MeLoginCard 风格：圆形头像 + 姓名 + 学号）
  @Builder
  AvatarModule() {
    Row() {
      Stack() {
        if (this.avatarUrl.length > 0) {
          Image(this.avatarUrl)
            .width(64).height(64).borderRadius(32)
            .objectFit(ImageFit.Cover)
            .onError(() => {
              this.avatarLoadFailed = true;
            })
        }
        if (this.avatarUrl.length === 0 || this.avatarLoadFailed) {
          Stack() {
            Circle()
              .width(64).height(64).fill(this.themeIsDark() ? '#4A4A4A' : '#C7C7C7')
            Circle()
              .width(16).height(16).fill(this.themeIsDark() ? '#777777' : '#9F9F9F')
              .position({ x: 24, y: 10 })
            Ellipse()
              .width(34).height(20).fill(this.themeIsDark() ? '#777777' : '#9F9F9F')
              .position({ x: 15, y: 30 })
          }
          .width(64).height(64)
        }
      }
      .width(64).height(64)
      Column() {
        Text(this.name.length > 0 ? this.name : '未登录')
          .fontSize(18).fontWeight(FontWeight.Bold).fontColor(ThemeColors.textPrimary)
        Text(this.account)
          .fontSize(13).fontColor(ThemeColors.textSecondary).margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 16 })
      .layoutWeight(1)
      Text('›').fontSize(22).fontColor(ThemeColors.textSecondary)
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 20, bottom: 20 })
    .backgroundColor(MaterialConfig.shouldUseCardMaterial() ? Color.Transparent : ThemeColors.bgCard)
    .borderRadius(16)
    .onClick(() => { this.pageStack.pushPathByName('ProfileCenterPage', undefined); })
  }

  private themeIsDark(): boolean {
    return AppStorage.get<boolean>('theme_is_dark') === true;
  }

  // 玻璃光感卡片容器：开启沉浸时用系统材质层，否则纯色卡片
  @Builder
  MaterialBar() {
    Stack()
      .width('100%')
      .height(100)
      .backgroundColor(Color.Transparent)
      .hitTestBehavior(HitTestMode.None)
  }

  @Builder
  ImmersionCard(cardHeight: Length, radius: number) {
    Stack({ alignContent: Alignment.Top }) {
      if (MaterialConfig.shouldUseCardMaterial()) {
        HdsTabs() {
          TabContent() {
          }
          .backdropBlur(0)
          .tabBar(this.MaterialBar())
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
    .borderRadius(radius)
    .clip(true)
    .backgroundColor(MaterialConfig.shouldUseCardMaterial() ? Color.Transparent : ThemeColors.bgCard)
    .hitTestBehavior(HitTestMode.None)
  }

  build() {
    Scroll() {
      Column({ space: 12 }) {
        // 头像模块（玻璃卡片）
        Stack({ alignContent: Alignment.Top }) {
          this.ImmersionCard(104, 16)
          this.AvatarModule()
        }
        .width('100%')

        // 一卡通/邮箱/图书 模块（玻璃卡片）
        Stack({ alignContent: Alignment.Top }) {
          this.ImmersionCard(92, 16)
          Row() {
            this.CardCell($r('app.media.ic_wallet'), '一卡通余额', this.cardBalance, '#E53935')
            this.CardCell($r('app.media.ic_mail'), '我的邮箱', this.emailCount + '封', '#1565C0')
            this.CardCell($r('app.media.ic_library'), '图书借阅', this.bookCount + '本', '#1565C0')
          }
          .width('100%')
          .padding({ left: 8, right: 8 })
        }
        .width('100%')

        // 设置模块（玻璃卡片）
        Stack({ alignContent: Alignment.Top }) {
          this.ImmersionCard(58, 16)
          Column() {
            this.ListItem($r('app.media.ic_settings'), '设置', () => { this.pageStack.pushPathByName('SettingsPage', undefined); })
          }
          .width('100%')
          .padding({ top: 4, bottom: 4 })
        }
        .width('100%')
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: this.statusBarHeight + 56, bottom: 24 })
    }
    .width('100%').height('100%')
    .scrollBar(BarState.Off)
    .backgroundColor($r('sys.color.ohos_id_color_background'))
  }
}
