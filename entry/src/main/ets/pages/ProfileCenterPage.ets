// ProfileCenterPage.ets — 个人中心：头像 / 姓名 / 账号 / 账号身份
// NavDestination 子页：系统标题栏（顶栏「个人中心」），原生返回键
import { ThemeColors } from '../utils/ThemeColors';
import { PreferenceUtil } from '../utils/PreferenceUtil';
import { SqgService } from '../services/SqgService';

const TAG = 'ProfileCenterPage';

@Component
export struct ProfileCenterPage {
  @Consume('pageStack') pageStack: NavPathStack;
  @State name: string = '';
  @State account: string = '';
  @State identity: string = '';
  @State avatarUrl: string = '';
  @State avatarLoadFailed: boolean = false;

  aboutToAppear(): void {
    this.account = PreferenceUtil.getString('ids_account');
    const svc = SqgService.getInstance();
    this.name = svc.getAccountName();
    if (this.name.length === 0) {
      this.name = PreferenceUtil.getString('mine_name_cached');
    }
    this.avatarUrl = svc.getPortraitUrl();
  }

  @Builder
  RowItem(label: string, value: string) {
    Row() {
      Text(label).fontSize(15).fontColor(ThemeColors.textPrimary).margin({ left: 16 })
      Blank()
      Text(value.length > 0 ? value : '--').fontSize(14).fontColor(ThemeColors.textSecondary).margin({ right: 16 })
    }
    .width('100%').height(56).alignItems(VerticalAlign.Center)
  }

  build() {
    NavDestination() {
      Column() {
        // 头像行（右侧显示头像）
        Row() {
          Text('头像').fontSize(15).fontColor(ThemeColors.textPrimary).margin({ left: 16 })
          Blank()
          Stack() {
            if (this.avatarUrl.length > 0) {
              Image(this.avatarUrl)
                .width(56).height(56).borderRadius(28)
                .objectFit(ImageFit.Cover)
                .onError(() => {
                  this.avatarLoadFailed = true;
                })
            }
            if (this.avatarUrl.length === 0 || this.avatarLoadFailed) {
              Text(this.name.length > 0 ? this.name.substring(0, 1) : '?')
                .width(56).height(56).borderRadius(28)
                .backgroundColor('#E3F2FD').fontSize(24).fontColor('#1565C0')
                .textAlign(TextAlign.Center)
            }
          }
          .width(56).height(56)
          .margin({ right: 16 })
        }
        .width('100%').height(72).alignItems(VerticalAlign.Center)

        Divider().color('#F0F0F0').strokeWidth(0.5).margin({ left: 16, right: 16 })

        this.RowItem('姓名', this.name)
        Divider().color('#F0F0F0').strokeWidth(0.5).margin({ left: 16, right: 16 })
        this.RowItem('账号', this.account)
        Divider().color('#F0F0F0').strokeWidth(0.5).margin({ left: 16, right: 16 })
        this.RowItem('账号身份', this.identity)
      }
      .width('100%').height('100%').backgroundColor('#F5F7FA')
    }
    .title('个人中心')
    .backgroundColor('#F5F7FA')
    .hideTitleBar(false)
  }
}
