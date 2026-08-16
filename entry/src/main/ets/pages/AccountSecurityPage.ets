import { router } from '@kit.ArkUI';
import { HdsNavigation, HdsNavigationTitleMode, ScrollEffectType, BlurStrategy } from '@kit.UIDesignKit';
import { ThemeColors } from '../utils/ThemeColors';
import { PreferenceUtil } from '../utils/PreferenceUtil';
import { SqgService } from '../services/SqgService';
import { WebPageParam } from './NavParams';
import { BackgroundManager, BackgroundLayer } from '../utils/BackgroundManager';
import { MaterialConfig } from '../utils/MaterialConfig';
import { SettingRowCard } from '../components/SettingRowCard';

const TAG = 'AccountSecurityPage';

const HOME_TITLE_HEIGHT: number = 56;
const PAGE_CARD_GAP: number = 10;

@Component
export struct AccountSecurityPage {
  @Consume('pageStack') pageStack: NavPathStack;
  @StorageLink('theme_is_dark') themeIsDark: boolean = false;
  @StorageProp('statusBarHeight') statusBarHeight: number = 0;
  @State account: string = '';

  aboutToAppear(): void {
    this.account = PreferenceUtil.getString('ids_account');
  }

  private async logout(): Promise<void> {
    try {
      await SqgService.getInstance().logout();
    } catch (e) {
    }
    try {
      router.replaceUrl({ url: 'pages/login/LoginPage' });
    } catch (e) {
    }
  }

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

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.Top }) {
        BackgroundLayer()
        HdsNavigation() {
          Scroll() {
            Column() {
              SettingRowCard({
                icon: $r('app.media.ic_lock'),
                label: '当前账号',
                value: this.account,
                action: () => { }
              })

              SettingRowCard({
                icon: $r('app.media.ic_public_edit'),
                label: '修改密码',
                action: () => { this.openChangePwd(); }
              })
              .margin({ top: PAGE_CARD_GAP })

              SettingRowCard({
                icon: $r('app.media.ic_public_delete'),
                label: '退出登录',
                action: () => { this.logout(); }
              })
              .margin({ top: PAGE_CARD_GAP })
            }
            .width('100%')
            .padding({ left: 20, right: 20, top: PAGE_CARD_GAP, bottom: 24 })
            .align(Alignment.Top)
          }
          .width('100%').height('100%')
          .align(Alignment.Top)
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
          .contentStartOffset(this.statusBarHeight + HOME_TITLE_HEIGHT + PAGE_CARD_GAP)
        }
        .mode(NavigationMode.Stack)
        .titleBar({
          content: {
            title: { mainTitle: '账号与安全' },
            backIcon: { action: (): void => { this.pageStack.pop(); } }
          },
          style: {
            scrollEffectOpts: {
              enableScrollEffect: false,
              scrollEffectType: ScrollEffectType.GRADIENT_BLUR
            },
            blurStrategy: BlurStrategy.ADAPTIVE,
            originalStyle: { backgroundStyle: { backgroundColor: '#00ffffff' } },
            scrollEffectStyle: { backgroundStyle: { backgroundColor: '#00ffffff' } },
            systemMaterialEffect: MaterialConfig.systemMaterialEffectParams()
          },
          avoidLayoutSafeArea: true,
          enableComponentSafeArea: false
        })
        .hideBackButton(false)
        .titleMode(HdsNavigationTitleMode.MINI)
        .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP])
        .width('100%').height('100%')
      }
      .width('100%').height('100%')
    }
    .hideTitleBar(true)
    .backgroundColor(BackgroundManager.pageBackgroundColor(this.themeIsDark))
  }
}
