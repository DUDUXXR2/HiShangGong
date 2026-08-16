import { router } from '@kit.ArkUI';
import { HdsNavigation, HdsNavigationTitleMode, ScrollEffectType, BlurStrategy } from '@kit.UIDesignKit';
import { SqgService } from '../services/SqgService';
import { ThemeColors } from '../utils/ThemeColors';
import { BackgroundManager, BackgroundLayer } from '../utils/BackgroundManager';
import { MaterialConfig } from '../utils/MaterialConfig';
import { SettingRowCard } from '../components/SettingRowCard';
import { GlassCard } from '../components/GlassCard';

const TAG = 'SettingsPage';

const HOME_TITLE_HEIGHT: number = 56;
const PAGE_CARD_GAP: number = 10;
const HOME_HORIZONTAL_PADDING: number = 20;

@Component
export struct SettingsPage {
  @Consume('pageStack') pageStack: NavPathStack;
  @StorageLink('theme_is_dark') themeIsDark: boolean = false;
  @StorageProp('statusBarHeight') statusBarHeight: number = 0;

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

  private openAccountSecurity(): void {
    this.pageStack.pushPathByName('AccountSecurityPage', undefined);
  }

  private openDeclaration(): void {
    this.pageStack.pushPathByName('DeclarationPage', undefined);
  }

  @Builder
  LogoutCardContent() {
    Row() {
      Text('退出登录')
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(ThemeColors.accent)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .height(48)
    .alignItems(VerticalAlign.Center)
    .justifyContent(FlexAlign.Center)
    .onClick(() => { this.logout(); })
  }

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.Top }) {
        BackgroundLayer()
        HdsNavigation() {
          Scroll() {
            Column({ space: PAGE_CARD_GAP }) {
              SettingRowCard({
                icon: $r('app.media.ic_lock'),
                label: '账号与安全',
                action: () => { this.openAccountSecurity(); }
              })

              SettingRowCard({
                icon: $r('app.media.ic_document'),
                label: '软件声明',
                action: () => { this.openDeclaration(); }
              })

              GlassCard({ cardHeight: 48, cardRadius: 24 }) {
                this.LogoutCardContent()
              }
            }
            .width('100%')
            .padding({ left: HOME_HORIZONTAL_PADDING, right: HOME_HORIZONTAL_PADDING, top: PAGE_CARD_GAP })
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
            title: { mainTitle: '设置' },
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
