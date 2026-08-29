import { router } from '@kit.ArkUI';
import { common, ConfigurationConstant } from '@kit.AbilityKit';
import { ThemeColors } from '../utils/ThemeColors';
import { AccentColors } from '../utils/AccentColors';
import { PreferenceUtil } from '../utils/PreferenceUtil';
import { BackgroundManager } from '../utils/BackgroundManager';
import { MaterialConfig } from '../utils/MaterialConfig';
import { ThemeConfig } from '../utils/ThemeConfig';

@Entry
@Component
struct Index {
  @StorageLink('theme_is_dark') themeIsDark: boolean = false;
  private accentColor: string = '#2979FF';

  aboutToAppear(): void {
    const savedMode: number = PreferenceUtil.getNumber('theme_color_mode',
      ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    ThemeColors.init(savedMode, getContext(this));
    AccentColors.init();
    BackgroundManager.init();
    MaterialConfig.init();
    const fontScale: number = ThemeConfig.fontSizeScale();
    AppStorage.setOrCreate<number>('font_size_scale', fontScale);
    const abilityCtx: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
    abilityCtx.getApplicationContext().setFontSizeScale(fontScale);
    this.accentColor = (AppStorage.get('accent_color') as string) ?? '#2979FF';
    setTimeout(() => { this.getUIContext().getRouter().replaceUrl({ url: 'pages/MainPage' }); }, 50);
  }

  build() {
    Column() {
      LoadingProgress().width(48).height(48).color(this.accentColor)
      Text('Hi商工').fontSize(24).fontWeight(FontWeight.Bold).fontColor(this.accentColor).margin({ top: 16 })
    }
    .width('100%').height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor(ThemeColors.bgCard)
  }
}
