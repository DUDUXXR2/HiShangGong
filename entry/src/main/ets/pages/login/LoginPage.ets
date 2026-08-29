import { router } from '@kit.ArkUI';
import { ThemeColors } from '../../utils/ThemeColors';
import { PreferenceUtil } from '../../utils/PreferenceUtil';
import { SqgService } from '../../services/SqgService';
import { ImmersionButton } from '@tangs/components';
import { ActionButtonModifier } from '../../components/ImmersionActionButton';
import { MaterialConfig } from '../../utils/MaterialConfig';

const TAG = 'LoginPage';

@Entry
@Component
struct LoginPage {
  @State username: string = '';
  @State password: string = '';
  @State passwordVisible: boolean = false;
  @State statusText: string = '';
  @State isSubmitting: boolean = false;
  @StorageLink('theme_is_dark') themeIsDark: boolean = false;
  @StorageProp('statusBarHeight') statusBarHeight: number = 0;

  aboutToAppear(): void {
    this.username = PreferenceUtil.getString('ids_account');
    this.password = PreferenceUtil.getString('login_password');
  }

  async doLogin(): Promise<void> {
    const uname: string = this.username.trim();
    if (uname.length === 0) { this.statusText = '请输入学号/工号'; return; }
    if (this.password.length === 0) { this.statusText = '请输入密码'; return; }
    this.statusText = '';
    this.isSubmitting = true;

    try {
      await SqgService.getInstance().login(uname, this.password);
      this.statusText = '登录成功！';
      setTimeout(() => {
      this.getUIContext().getRouter().replaceUrl({ url: 'pages/MainPage' });
      }, 300);
    } catch (e) {
      this.statusText = '登录失败：' + String(e);
    } finally {
      this.isSubmitting = false;
    }
  }

  build() {
    Column() {
      Row() {
        Text('登录').fontSize(20).fontWeight(FontWeight.Bold).fontColor(ThemeColors.textPrimary)
        Blank()
        if (this.isSubmitting) {
          LoadingProgress().width(24).height(24).color('#2979FF')
        }
      }
      .width('100%').height(56 + this.statusBarHeight)
      .padding({ left: 16, right: 16, top: this.statusBarHeight })
      .backgroundColor(ThemeColors.bgCard)
      .shadow({ radius: 2, color: '#00000010', offsetY: 1 })
      .expandSafeArea([SafeAreaType.SYSTEM, SafeAreaType.CUTOUT], [SafeAreaEdge.TOP])

      Column() {
        Image($r('app.media.icon'))
          .width(96).height(96).borderRadius(20).objectFit(ImageFit.Contain)
          .margin({ bottom: 24 })
          .alignSelf(ItemAlign.Center)
          .shadow({ radius: 12, color: '#0000001A', offsetY: 4 })
        Column() {
          Text('Hi商工').fontSize(24).fontWeight(FontWeight.Bold).fontColor(ThemeColors.textPrimary)
            .margin({ bottom: 8 })
          Text('输入学号和密码进行登录').fontSize(14).fontColor(ThemeColors.textSecondary)
            .margin({ bottom: 32 })
        }
        .width('100%').alignItems(HorizontalAlign.Start)

        Row() {
          TextInput({ placeholder: '请输入学号/工号', text: this.username })
            .width('100%').height(48).fontSize(16)
            .type(InputType.Normal)
            .placeholderColor(ThemeColors.textSecondary)
            .backgroundColor(ThemeColors.bgInput).borderRadius(8)
            .padding({ left: 16, right: 16 })
            .onChange((value: string) => { this.username = value; })
        }.width('100%')

        Row() {
          TextInput({ placeholder: '请输入密码', text: this.password })
            .width('100%').height(48).fontSize(16)
            .type(InputType.Password)
            .placeholderColor(ThemeColors.textSecondary)
            .backgroundColor(ThemeColors.bgInput).borderRadius(8)
            .padding({ left: 16, right: 16 })
            .onChange((value: string) => { this.password = value; })
        }
        .width('100%').margin({ top: 16 })

        Stack({ alignContent: Alignment.Center }) {
          ImmersionButton({
            systemMaterialEffect: {
              materialType: MaterialConfig.configuredMaterialType(),
              materialLevel: MaterialConfig.configuredMaterialLevel()
            },
            buttonModify: new ActionButtonModifier('100%', 48,
              this.isSubmitting ? '#90CAF9' : '#2979FF',
              this.isSubmitting ? '#90CAF9' : '#2979FF'),
            click: (): void => { this.doLogin(); }
          }) {
            if (this.isSubmitting) {
              LoadingProgress().width(20).height(20).color('#FFFFFF')
            } else {
              Text('登录')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor('#FFFFFF')
            }
          }
        }
        .width('100%')
        .height(48)
        .borderRadius(24)
        .clip(false)
        .margin({ top: 32 })
        .opacity(this.isSubmitting ? 0.7 : 1)

        if (this.statusText.length > 0) {
          Text(this.statusText)
            .fontSize(13)
            .fontColor(this.statusText.indexOf('失败') >= 0 ? '#C62828' : '#666666')
            .margin({ top: 16 })
        }

        Text('账号密码仅保存在本设备').fontSize(12).fontColor(ThemeColors.textSecondary)
          .margin({ top: 24 })
      }
      .width('100%').layoutWeight(1)
      .padding({ left: 32, right: 32, top: 48 })
      .alignItems(HorizontalAlign.Start)
      .backgroundColor(ThemeColors.bgCard)
    }
    .width('100%').height('100%').backgroundColor(ThemeColors.bgCard)
  }
}
