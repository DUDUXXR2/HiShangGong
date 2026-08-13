import { router } from '@kit.ArkUI';
import { ThemeColors } from '../../utils/ThemeColors';
import { PreferenceUtil } from '../../utils/PreferenceUtil';
import { SqgService } from '../../services/SqgService';
import { WebPageParam } from '../NavParams';

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

  build() {
    Column() {
      Row() {
        Stack() {
          if (this.avatarUrl.length > 0) {
            Image(this.avatarUrl)
              .width(64).height(64).borderRadius(32)
              .objectFit(ImageFit.Cover)
              .border({ width: 1, color: '#FFFFFF40' })
              .onError(() => {
                this.avatarLoadFailed = true;
              })
          }
          if (this.avatarUrl.length === 0 || this.avatarLoadFailed) {
            Text(this.name.length > 0 ? this.name.substring(0, 1) : '?')
              .width(64).height(64).borderRadius(32)
              .backgroundColor('#FFFFFF33').fontSize(26).fontColor('#FFFFFF')
              .textAlign(TextAlign.Center)
              .border({ width: 1, color: '#FFFFFF40' })
          }
        }
        .width(64).height(64)
        Column() {
          Text(this.name.length > 0 ? this.name : '未登录').fontSize(18).fontWeight(FontWeight.Bold).fontColor('#FFFFFF')
          Text(this.account).fontSize(13).fontColor('#FFFFFFB3').margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 16 })
        Blank()
        Text('›').fontSize(22).fontColor('#FFFFFFB3')
      }
      .width('100%').padding({ left: 20, right: 20, top: this.statusBarHeight + 28, bottom: 24 })
      .backgroundColor('#2979FF')
      .expandSafeArea([SafeAreaType.SYSTEM, SafeAreaType.CUTOUT], [SafeAreaEdge.TOP])
      .onClick(() => { this.pageStack.pushPathByName('ProfileCenterPage', undefined); })

      Row() {
        this.CardCell($r('app.media.ic_wallet'), '一卡通余额', this.cardBalance, '#E53935')
        this.CardCell($r('app.media.ic_mail'), '我的邮箱', this.emailCount + '封', '#1565C0')
        this.CardCell($r('app.media.ic_library'), '图书借阅', this.bookCount + '本', '#1565C0')
      }
      .width('100%')
      .backgroundColor('#FFFFFF')
      .borderRadius(16)
      .shadow({ radius: 8, color: '#14000000', offsetY: 2 })
      .padding({ left: 8, right: 8 })
      .margin({ left: 12, right: 12, top: -8 })

      Column() {
        this.ListItem($r('app.media.ic_settings'), '设置', () => { this.pageStack.pushPathByName('SettingsPage', undefined); })
        this.ListItem($r('app.media.more_opinion'), '意见反馈', () => { this.openH5('意见反馈'); })
        this.ListItem($r('app.media.ic_ellipsis_bubble'), '关于我们', () => { this.openH5('关于我们'); })
        this.ListItem($r('app.media.ic_lock'), '隐私保护指引摘要', () => { this.openH5('隐私保护'); })
        this.ListItem($r('app.media.ic_face'), '人脸协议隐私政策指引', () => { this.openH5('人脸协议'); })
        this.ListItem($r('app.media.ic_document'), '个人信息收集清单', () => { this.openH5('个人信息收集'); })
        this.ListItem($r('app.media.ic_public_share'), '第三方共享个人信息清单', () => { this.openH5('第三方共享'); })
      }
      .width('100%')
      .backgroundColor('#FFFFFF')
      .borderRadius(16)
      .shadow({ radius: 8, color: '#14000000', offsetY: 2 })
      .margin({ left: 12, right: 12, top: 12 })
      .padding({ top: 4, bottom: 4 })

      Blank()
    }
    .width('100%').height('100%').backgroundColor($r('sys.color.ohos_id_color_background'))
  }
}
