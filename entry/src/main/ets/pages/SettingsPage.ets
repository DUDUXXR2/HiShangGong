// SettingsPage.ets — 设置页：账号与安全 / 退出登录
// NavDestination 子页：系统标题栏自动处理状态栏安全区，原生返回键（单箭头无字）
import { router } from '@kit.ArkUI';
import { ThemeColors } from '../utils/ThemeColors';
import { PreferenceUtil } from '../utils/PreferenceUtil';
import { SqgService } from '../services/SqgService';

const TAG = 'SettingsPage';

@Component
export struct SettingsPage {
  @Consume('pageStack') pageStack: NavPathStack;

  private logout(): void {
    SqgService.getInstance().clearUserData().catch(() => {
    });
    PreferenceUtil.putBool('is_logged_in', false);
    router.replaceUrl({ url: 'pages/login/LoginPage' });
  }

  private openAccountSecurity(): void {
    this.pageStack.pushPathByName('AccountSecurityPage', undefined);
  }

  @Builder
  ListItem(icon: Resource, label: string, onClick: () => void) {
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
        Column() {
          this.ListItem($r('app.media.ic_lock'), '账号与安全', () => { this.openAccountSecurity(); })
        }
        .width('100%').backgroundColor(ThemeColors.bgCard).borderRadius(16)
        .margin({ top: 12, left: 12, right: 12 })
        .padding({ top: 4, bottom: 4 })

        Blank()
        Button('退出登录')
          .fontSize(14).fontColor('#E53935')
          .width('88%').height(46)
          .backgroundColor(ThemeColors.bgCard).borderRadius(23)
          .margin({ bottom: 24 })
          .onClick(() => this.logout())
      }
      .width('100%').height('100%').backgroundColor(ThemeColors.bgPage)
    }
    .title('设置')
    .backgroundColor(ThemeColors.bgPage)
    .hideTitleBar(false)
  }
}
