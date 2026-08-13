// AccountSecurityPage.ets — 账号与安全：修改密码 / 退出登录
// NavDestination 子页：系统标题栏自动处理状态栏安全区，原生返回键（单箭头无字）
import { router } from '@kit.ArkUI';
import { ThemeColors } from '../utils/ThemeColors';
import { PreferenceUtil } from '../utils/PreferenceUtil';
import { SqgService } from '../services/SqgService';
import { WebPageParam } from './NavParams';

const TAG = 'AccountSecurityPage';

@Component
export struct AccountSecurityPage {
  @Consume('pageStack') pageStack: NavPathStack;
  @State account: string = '';

  aboutToAppear(): void {
    this.account = PreferenceUtil.getString('ids_account');
  }

  private logout(): void {
    SqgService.getInstance().clearUserData().catch(() => {
    });
    PreferenceUtil.putBool('is_logged_in', false);
    router.replaceUrl({ url: 'pages/login/LoginPage' });
  }

  // 修改密码：用 WebView 打开原 H5（自带登录态）
  private openChangePwd(): void {
    this.pageStack.pushPathByName('ServiceWebPage',
      new WebPageParam('修改密码', 'https://i.sqgxy.edu.cn/h5/'));
  }

  @Builder
  InfoRow(label: string, value: string) {
    Row() {
      Text(label).fontSize(15).fontColor(ThemeColors.textPrimary).margin({ left: 16 })
      Blank()
      Text(value).fontSize(14).fontColor(ThemeColors.textSecondary).margin({ right: 16 })
    }
    .width('100%').height(52).alignItems(VerticalAlign.Center)
  }

  @Builder
  ActionRow(icon: Resource, label: string, onClick: () => void) {
    Row() {
      Image(icon)
        .width(20).height(20).fillColor(ThemeColors.textPrimary).objectFit(ImageFit.Contain)
        .margin({ left: 16, right: 14 })
      Text(label).fontSize(15).fontColor(ThemeColors.textPrimary).layoutWeight(1)
      Text('›').fontSize(18).fontColor(ThemeColors.textSecondary).margin({ right: 16 })
    }
    .width('100%').height(52).alignItems(VerticalAlign.Center)
    .onClick(onClick)
  }

  build() {
    NavDestination() {
      Column() {
        // 账号信息
        Column() {
          this.InfoRow('当前账号', this.account)
        }
        .width('100%').backgroundColor(ThemeColors.bgCard).borderRadius(16)
        .margin({ top: 12, left: 12, right: 12 })
        .padding({ top: 4, bottom: 4 })

        // 操作
        Column() {
          this.ActionRow($r('app.media.ic_public_edit'), '修改密码', () => { this.openChangePwd(); })
          this.ActionRow($r('app.media.ic_lock'), '退出登录', () => { this.logout(); })
        }
        .width('100%').backgroundColor(ThemeColors.bgCard).borderRadius(16)
        .margin({ top: 12, left: 12, right: 12 })
        .padding({ top: 4, bottom: 4 })
      }
      .width('100%').height('100%').backgroundColor(ThemeColors.bgPage)
    }
    .title('账号与安全')
    .backgroundColor(ThemeColors.bgPage)
    .hideTitleBar(false)
  }
}
