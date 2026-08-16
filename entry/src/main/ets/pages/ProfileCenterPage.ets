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
const HOME_HORIZONTAL_PADDING: number = 20;

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
  AvatarContent() {
    Row() {
      Stack() {
        if (this.avatarUrl.length > 0 && !this.avatarLoadFailed) {
          Image(this.avatarUrl)
            .width(48).height(48).borderRadius(24)
            .objectFit(ImageFit.Cover)
            .onError(() => {
              this.avatarLoadFailed = true;
            })
        }
        if (this.avatarUrl.length === 0 || this.avatarLoadFailed) {
          Text(this.name.length > 0 ? this.name.substring(0, 1) : '?')
            .width(48).height(48).borderRadius(24)
            .backgroundColor('#E3F2FD').fontSize(22).fontColor('#1565C0')
            .textAlign(TextAlign.Center)
        }
      }
      .width(48).height(48)
      Column({ space: 4 }) {
        Text(this.name.length > 0 ? this.name : '未登录')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(ThemeColors.textPrimary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.account)
          .fontSize(13)
          .fontColor(ThemeColors.textSecondary)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 14 })
    }
    .width('100%')
    .height(72)
    .padding({ left: 18, right: 20 })
    .alignItems(VerticalAlign.Center)
  }

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.Top }) {
        BackgroundLayer()
        HdsNavigation() {
          Scroll() {
            Column({ space: PAGE_CARD_GAP }) {
              GlassCard({ cardHeight: 72, cardRadius: 15 }) {
                this.AvatarContent()
              }

              Column({ space: 2 }) {
                SettingRowCard({
                  icon: $r('app.media.ic_public_more'),
                  label: '姓名',
                  value: this.name.length > 0 ? this.name : '--'
                })
                SettingRowCard({
                  icon: $r('app.media.ic_public_more'),
                  label: '账号',
                  value: this.account.length > 0 ? this.account : '--'
                })
                SettingRowCard({
                  icon: $r('app.media.ic_public_more'),
                  label: '账号身份',
                  value: this.identity.length > 0 ? this.identity : '--'
                })
              }
            }
            .width('100%')
            .padding({ left: HOME_HORIZONTAL_PADDING, right: HOME_HORIZONTAL_PADDING, top: PAGE_CARD_GAP, bottom: 24 })
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
