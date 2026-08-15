// ProfileCenterPage.ets — 个人中心：头像 / 姓名 / 账号 / 账号身份
// 沉浸式二级页：内嵌 HdsNavigation（渐变模糊标题栏 + 状态栏避让）
// 行样式统一为 Mine 页格式（图标+文字+右箭头，玻璃卡片）
import { HdsNavigation, HdsNavigationTitleMode, ScrollEffectType, BlurStrategy } from '@kit.UIDesignKit';
import { ThemeColors } from '../utils/ThemeColors';
import { PreferenceUtil } from '../utils/PreferenceUtil';
import { SqgService } from '../services/SqgService';
import { BackgroundManager, BackgroundLayer } from '../utils/BackgroundManager';
import { MaterialConfig } from '../utils/MaterialConfig';

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

  @Builder
  RowItem(label: string, value: string) {
    Row() {
      Text(label).fontSize(15).fontColor(ThemeColors.textPrimary).margin({ left: 20 })
      Blank()
      Text(value.length > 0 ? value : '--').fontSize(14).fontColor(ThemeColors.textSecondary).margin({ right: 18 })
    }
    .width('100%').height(56).alignItems(VerticalAlign.Center)
  }

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.Top }) {
        BackgroundLayer()
        HdsNavigation() {
          Scroll() {
            Column() {
              // 头像行（右侧显示头像）
              Row() {
                Text('头像').fontSize(15).fontColor(ThemeColors.textPrimary).margin({ left: 20 })
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
                .margin({ right: 18 })
              }
              .width('100%').height(72).alignItems(VerticalAlign.Center)

              Divider().color(this.dividerColor()).strokeWidth(0.5).margin({ left: 20, right: 20 })

              this.RowItem('姓名', this.name)
              Divider().color(this.dividerColor()).strokeWidth(0.5).margin({ left: 20, right: 20 })
              this.RowItem('账号', this.account)
              Divider().color(this.dividerColor()).strokeWidth(0.5).margin({ left: 20, right: 20 })
              this.RowItem('账号身份', this.identity)
            }
            .width('100%')
            .padding({ left: 0, right: 0, top: PAGE_CARD_GAP, bottom: 24 })
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

  private dividerColor(): string {
    return this.themeIsDark ? '#444444' : '#E6E6E6';
  }
}
