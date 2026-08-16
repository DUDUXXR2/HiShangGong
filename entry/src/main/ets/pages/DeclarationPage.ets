import { HdsNavigation, HdsNavigationTitleMode, ScrollEffectType, BlurStrategy } from '@kit.UIDesignKit';
import { ThemeColors } from '../utils/ThemeColors';
import { BackgroundManager, BackgroundLayer } from '../utils/BackgroundManager';
import { MaterialConfig } from '../utils/MaterialConfig';

const TAG = 'DeclarationPage';

const HOME_TITLE_HEIGHT: number = 56;
const PAGE_CARD_GAP: number = 10;
const HOME_HORIZONTAL_PADDING: number = 20;

@Component
export struct DeclarationPage {
  @Consume('pageStack') pageStack: NavPathStack;
  @StorageLink('theme_is_dark') themeIsDark: boolean = false;
  @StorageProp('statusBarHeight') statusBarHeight: number = 0;

  @Builder
  SectionTitle(title: string) {
    Text(title)
      .fontSize(15)
      .fontWeight(FontWeight.Bold)
      .fontColor(ThemeColors.textPrimary)
      .width('100%')
      .margin({ top: 18, bottom: 8 })
  }

  @Builder
  SectionBody(text: string) {
    Text(text)
      .fontSize(14)
      .fontColor(ThemeColors.textSecondary)
      .width('100%')
      .lineHeight(22)
      .margin({ bottom: 4 })
  }

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.Top }) {
        BackgroundLayer()
        HdsNavigation() {
          Scroll() {
            Column() {
              this.SectionTitle('一、应用性质')
              this.SectionBody('本应用「Hi商工」是个人开发者制作的第三方校园工具，从安卓版移植到鸿蒙系统，非学校官方出品，与学校无任何隶属或授权关系。')

              this.SectionTitle('二、开发说明')
              this.SectionBody('本应用由个人开发者基于安卓版逆向移植开发，开发过程中使用了 DeepSeek v4、GLM-5.1 与 Claude Code 等 AI 工具辅助编码。')

              this.SectionTitle('三、支付说明')
              this.SectionBody('应用内涉及的缴费、充值等操作（如校园卡、缴电费）均为跳转至学校官方页面完成支付，本应用不直接收款，也不存储任何支付账号与支付信息。')

              this.SectionTitle('四、数据与隐私')
              this.SectionBody('1. 您的账号密码仅用于校内统一身份认证，不会上传至任何第三方服务器。')
              this.SectionBody('2. 应用内展示的课表、成绩、消息等数据均来自学校官方接口，本应用不采集、不存储您的个人数据到开发者服务器。')
              this.SectionBody('3. 本地缓存（如登录状态、已读记录、背景图设置等）仅保存在您的设备本地，卸载应用后即清除。')
              this.SectionBody('4. 消息推送等能力均经由学校官方渠道，本应用不接入任何第三方推送服务。')

              Blank()
                .height(24)
            }
            .width('100%')
            .padding({
              left: HOME_HORIZONTAL_PADDING,
              right: HOME_HORIZONTAL_PADDING,
              bottom: 24
            })
            .align(Alignment.Top)
          }
          .width('100%').height('100%')
          .align(Alignment.Top)
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
          .contentStartOffset(this.statusBarHeight + HOME_TITLE_HEIGHT + PAGE_CARD_GAP)
          .backgroundBlurStyle(BlurStyle.COMPONENT_THICK)
        }
        .mode(NavigationMode.Stack)
        .titleBar({
          content: {
            title: { mainTitle: '软件声明' },
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
