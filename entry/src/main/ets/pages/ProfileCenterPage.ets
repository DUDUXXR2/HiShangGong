// ProfileCenterPage.ets — 个人中心：头像 / 姓名 / 账号 / 账号身份
// 沉浸式二级页：内嵌 HdsNavigation（渐变模糊标题栏 + 状态栏避让）
// 行样式统一为 Mine 页格式（图标+文字+右箭头，玻璃卡片）
import { HdsNavigation, HdsNavigationTitleMode, ScrollEffectType, BlurStrategy } from '@kit.UIDesignKit';
import { ThemeColors } from '../utils/ThemeColors';
import { PreferenceUtil } from '../utils/PreferenceUtil';
import { SqgService } from '../services/SqgService';
import { BackgroundManager, BackgroundLayer } from '../utils/BackgroundManager';
import { MaterialConfig } from '../utils/MaterialConfig';
import { GlassCard } from '../components/GlassCard';
import { SettingRowCard } from '../components/SettingRowCard';

const TAG = 'ProfileCenterPage';

const HOME_TITLE_HEIGHT: number = 56;
const PAGE_CARD_GAP: number = 10;

@Component
export struct ProfileCenterPage {
  @Consume('pageStack') pageStack: NavPathStack;
  @StorageLink('theme_is_dark') themeIsDark: boolean = false;
  @StorageProp('statusBarHeight') statusBarHeight: number = 0;
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
    this.identity = svc.getIdentityName();
    this.avatarUrl = svc.getPortraitUrl();
  }

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.Top }) {
        BackgroundLayer()
        HdsNavigation() {
          Scroll() {
            Column() {
              // 头像卡（玻璃卡片）
              GlassCard({ cardHeight: 72, cardRadius: 14 }) {
                Row() {
                  Text('头像').fontSize(15).fontColor(ThemeColors.textPrimary)
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
                }
                .width('100%').height(72).alignItems(VerticalAlign.Center)
                .padding({ left: 16, right: 16 })
              }

              Blank().height(24)

              SettingRowCard({
                icon: $r('app.media.ic_face'),
                label: '姓名',
                value: this.name.length > 0 ? this.name : '--'
              })

              Blank().height(24)

              SettingRowCard({
                icon: $r('app.media.ic_lock'),
                label: '账号',
                value: this.account.length > 0 ? this.account : '--'
              })

              Blank().height(24)

              SettingRowCard({
                icon: $r('app.media.ic_document'),
                label: '账号身份',
                value: this.identity.length > 0 ? this.identity : '--'
              })

              Blank().height(24)
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
            title: { mainTitle: '个人中心' },
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
