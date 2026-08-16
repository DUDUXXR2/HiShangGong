import { HdsNavigation, HdsNavigationTitleMode, ScrollEffectType, BlurStrategy } from '@kit.UIDesignKit';
import { ThemeColors } from '../utils/ThemeColors';
import { MaterialConfig } from '../utils/MaterialConfig';
import { BackgroundManager, BackgroundLayer } from '../utils/BackgroundManager';
import { GlassCard } from '../components/GlassCard';
import { ImmersionButton } from '@tangs/components';
import { ActionButtonModifier } from '../components/ImmersionActionButton';
import { ThemeConfig } from '../utils/ThemeConfig';

const TAG = 'AppearancePage';

const HOME_HORIZONTAL_PADDING: number = 20;
const PAGE_CARD_GAP: number = 10;
const HOME_TITLE_HEIGHT: number = 56;
const ME_ROW_HEIGHT: number = 60;
const ME_CARD_RADIUS: number = 15;
const BACKGROUND_THUMBNAIL_WIDTH: number = 38;
const BACKGROUND_THUMBNAIL_HEIGHT: number = 56;
const BACKGROUND_PICKER_ROW_HEIGHT: number = 146;
const BACKGROUND_BLUR_ROW_HEIGHT: number = 82;
const BACKGROUND_BRIGHTNESS_ROW_HEIGHT: number = 82;

const MATERIAL_TYPE_OPTIONS: SelectOption[] = [
  { value: '自适应' }, { value: '沉浸' }, { value: '无材质' }
];
const MATERIAL_LEVEL_OPTIONS: SelectOption[] = [
  { value: '自适应' }, { value: '精致' }, { value: '柔和' }, { value: '平滑' }
];
const DARK_MODE_OPTIONS: SelectOption[] = [
  { value: '跟随系统' }, { value: '开启' }, { value: '关闭' }
];
const FONT_SIZE_OPTIONS: SelectOption[] = [
  { value: '跟随系统' }, { value: '小号' }, { value: '标准' }, { value: '大号' }
];

@Component
export struct AppearancePage {
  @Consume('pageStack') pageStack: NavPathStack;
  @StorageProp('statusBarHeight') statusBarHeight: number = 0;
  @StorageLink('theme_is_dark') themeIsDark: boolean = false;
  @StorageProp('bg_selection') bgSelection: string = 'none';
  @StorageProp('bg_custom_uri') bgCustomUri: string = '';
  @StorageProp('bg_blur_percent') bgBlurPercent: number = 0;
  @StorageProp('bg_brightness_percent') bgBrightnessPercent: number = 50;
  @StorageProp('bg_global') bgGlobal: boolean = true;
  @State globalImmersion: boolean = true;
  @State materialType: string = '自适应';
  @State materialLevel: string = '自适应';
  @State darkMode: string = '跟随系统';
  @State fontSize: string = '跟随系统';

  aboutToAppear(): void {
    BackgroundManager.init();
    this.globalImmersion = MaterialConfig.globalImmersionEnabled();
    this.materialType = MaterialConfig.materialTypeName();
    this.materialLevel = MaterialConfig.materialLevelName();
    this.darkMode = ThemeConfig.darkModeName();
    this.fontSize = ThemeConfig.fontSizeName();
  }

  private isDark(): boolean {
    return this.themeIsDark;
  }

  private primaryTextColor(): string {
    return this.isDark() ? '#EEEEEE' : '#1A1A1A';
  }

  private secondaryTextColor(): string {
    if (MaterialConfig.shouldUseCardMaterial()) {
      return this.isDark() ? '#D0D0D0' : '#4A4A4A';
    }
    return this.isDark() ? '#B8B8B8' : '#666666';
  }

  private dividerColor(): string {
    return this.isDark() ? '#444444' : '#E6E6E6';
  }

  private accentColor(): string {
    return ThemeColors.accent;
  }

  private accentColorWithAlpha(alpha: number): string {
    const hex = this.accentColor();
    const a = Math.round(alpha).toString(16).padStart(2, '0');
    return `#${a}${hex.substring(1)}`;
  }

  private primaryActionFillColor(): string {
    return this.accentColorWithAlpha(26);
  }

  private accentContrastColor(): string {
    return ThemeColors.textOnColor(this.accentColor());
  }

  private clamp(value: number, min: number, max: number): number {
    return Math.min(max, Math.max(min, value));
  }

  @Builder
  SwitchRow(label: string, value: boolean, onChange: (v: boolean) => void) {
    Row() {
      Text(label).fontSize(15).fontWeight(FontWeight.Medium)
        .fontColor(this.primaryTextColor()).layoutWeight(1).margin({ left: 16 })
      Toggle({ type: ToggleType.Switch, isOn: value })
        .selectedColor(this.accentColor())
        .switchPointColor(this.isDark() ? '#191919' : '#FFFFFF')
        .margin({ right: 16 })
        .onChange((checked: boolean) => { onChange(checked); })
    }
    .width('100%').height(ME_ROW_HEIGHT).alignItems(VerticalAlign.Center)
  }

  @Builder
  SelectRow(label: string, value: string, options: SelectOption[], onChange: (v: string) => void) {
    Row() {
      Text(label).fontSize(15).fontWeight(FontWeight.Medium)
        .fontColor(this.primaryTextColor()).layoutWeight(1).margin({ left: 16 })
      Select(options)
        .selected(this.optionIndex(options, value))
        .value(value)
        .font({ size: 15, weight: FontWeight.Regular })
        .fontColor(this.secondaryTextColor())
        .selectedOptionFont({ size: 15, weight: FontWeight.Regular })
        .selectedOptionFontColor(this.accentContrastColor())
        .selectedOptionBgColor(this.accentColor())
        .margin({ right: 16 })
        .onSelect((index: number) => {
          if (index >= 0 && index < options.length) {
            onChange(String(options[index].value));
          }
        })
    }
    .width('100%').height(ME_ROW_HEIGHT).alignItems(VerticalAlign.Center)
  }

  private optionIndex(options: SelectOption[], value: string): number {
    for (let i = 0; i < options.length; i++) {
      if (String(options[i].value) === value) {
        return i;
      }
    }
    return 0;
  }

  @Builder
  CardDivider() {
    Divider()
      .strokeWidth(1)
      .color(this.dividerColor())
      .margin({ left: 16, right: 16 })
  }

  @Builder
  SectionTitle(title: string) {
    Text(title)
      .fontSize(15)
      .fontWeight(FontWeight.Medium)
      .fontColor(this.primaryTextColor())
      .padding({ left: 20, top: 10, bottom: 8 })
      .width('100%')
  }

  @Builder
  AppearanceCardContent() {
    Column() {
      this.DarkModeRow()
      this.CardDivider()
      this.FontSizeRow()
    }
    .width('100%')
    .height(ME_ROW_HEIGHT * 2 + 1)
    .padding({ left: 4, right: 2 })
  }

  @Builder
  FontSizeRow() {
    Row() {
      Text('字体大小').fontSize(15).fontWeight(FontWeight.Medium)
        .fontColor(this.primaryTextColor()).layoutWeight(1).margin({ left: 16 })
      Select(FONT_SIZE_OPTIONS)
        .selected(this.optionIndex(FONT_SIZE_OPTIONS, this.fontSize))
        .value(this.fontSize)
        .font({ size: 15, weight: FontWeight.Regular })
        .fontColor(this.secondaryTextColor())
        .selectedOptionFont({ size: 15, weight: FontWeight.Regular })
        .selectedOptionFontColor(this.accentContrastColor())
        .selectedOptionBgColor(this.accentColor())
        .margin({ right: 16 })
        .onSelect((index: number) => {
          if (index >= 0 && index < FONT_SIZE_OPTIONS.length) {
            const v: string = String(FONT_SIZE_OPTIONS[index].value);
            this.fontSize = v;
            const ctx = this.getUIContext().getHostContext();
            if (ctx) {
              ThemeConfig.setFontSize(v, ctx);
            }
          }
        })
    }
    .width('100%').height(ME_ROW_HEIGHT).alignItems(VerticalAlign.Center)
  }

  @Builder
  DarkModeRow() {
    Row() {
      Text('深色模式').fontSize(15).fontWeight(FontWeight.Medium)
        .fontColor(this.primaryTextColor()).layoutWeight(1).margin({ left: 16 })
      if (this.darkMode === '跟随系统') {
        Text(this.themeIsDark ? '开启' : '关闭')
          .fontSize(12)
          .fontColor(this.isDark() ? '#888888' : '#999999')
          .margin({ right: 8 })
      }
      Select(DARK_MODE_OPTIONS)
        .selected(this.optionIndex(DARK_MODE_OPTIONS, this.darkMode))
        .value(this.darkMode)
        .font({ size: 15, weight: FontWeight.Regular })
        .fontColor(this.secondaryTextColor())
        .selectedOptionFont({ size: 15, weight: FontWeight.Regular })
        .selectedOptionFontColor(this.accentContrastColor())
        .selectedOptionBgColor(this.accentColor())
        .margin({ right: 16 })
        .onSelect((index: number) => {
          if (index >= 0 && index < DARK_MODE_OPTIONS.length) {
            const v: string = String(DARK_MODE_OPTIONS[index].value);
            this.darkMode = v;
            const ctx = this.getUIContext().getHostContext();
            if (ctx) {
              ThemeConfig.setDarkMode(v, ctx);
            }
          }
        })
    }
    .width('100%').height(ME_ROW_HEIGHT).alignItems(VerticalAlign.Center)
  }

  @Builder
  MaterialCardContent() {
    Column() {
      this.SwitchRow('全局沉浸光感', this.globalImmersion, (v: boolean) => {
        this.globalImmersion = v;
        MaterialConfig.setGlobalImmersion(v);
      })
      this.CardDivider()
      this.SelectRow('材质类型', this.materialType, MATERIAL_TYPE_OPTIONS, (v: string) => {
        this.materialType = v;
        MaterialConfig.setMaterialType(v);
      })
      this.CardDivider()
      this.SelectRow('材质等级', this.materialLevel, MATERIAL_LEVEL_OPTIONS, (v: string) => {
        this.materialLevel = v;
        MaterialConfig.setMaterialLevel(v);
      })
    }
    .width('100%')
    .height(ME_ROW_HEIGHT * 3 + 2)
    .padding({ left: 4, right: 2 })
  }

  private backgroundCardHeight(): number {
    return BACKGROUND_PICKER_ROW_HEIGHT + BACKGROUND_BLUR_ROW_HEIGHT + BACKGROUND_BRIGHTNESS_ROW_HEIGHT + ME_ROW_HEIGHT + 3;
  }

  @Builder
  BackgroundCardContent() {
    Column() {
      this.BackgroundPickerRow()
      this.CardDivider()
      this.BackgroundBlurRow()
      this.CardDivider()
      this.BackgroundBrightnessRow()
      this.CardDivider()
      this.SwitchRow('背景图是否全局显示', this.bgGlobal, (v: boolean) => {
        BackgroundManager.setGlobalEnabled(v);
      })
    }
    .width('100%')
    .height(this.backgroundCardHeight())
    .padding({ left: 4, right: 2 })
  }

  @Builder
  BackgroundPickerRow() {
    Column({ space: 10 }) {
      Row() {
        Text('背景图选择')
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.primaryTextColor())
          .layoutWeight(1)

        Stack({ alignContent: Alignment.Center }) {
          ImmersionButton({
            systemMaterialEffect: {
              materialType: MaterialConfig.configuredMaterialType(),
              materialLevel: MaterialConfig.configuredMaterialLevel()
            },
            buttonModify: new ActionButtonModifier(110, 34, this.accentColor(), this.accentColor()),
            click: (): void => { this.pickFromGallery(); }
          }) {
            Text('从图库选择')
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.accentContrastColor())
          }
        }
        .width(110)
        .height(34)
        .borderRadius(17)
        .clip(false)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Scroll() {
        Row({ space: 6 }) {
          this.BackgroundOffThumbnail()
          if (this.bgCustomUri.length > 0) {
            this.CustomBackgroundThumbnail()
          }
          this.PresetBackgroundThumbnail('preset_1', $r('app.media.background_preset_1'), $r('app.media.background_preset_1_thumb'))
          this.PresetBackgroundThumbnail('preset_2', $r('app.media.background_preset_2'), $r('app.media.background_preset_2_thumb'))
          this.PresetBackgroundThumbnail('preset_3', $r('app.media.background_preset_3'), $r('app.media.background_preset_3_thumb'))
          this.PresetBackgroundThumbnail('preset_4', $r('app.media.background_preset_4'), $r('app.media.background_preset_4_thumb'))
          this.PresetBackgroundThumbnail('preset_5', $r('app.media.background_preset_5'), $r('app.media.background_preset_5_thumb'))
          this.PresetBackgroundThumbnail('preset_6', $r('app.media.background_preset_6'), $r('app.media.background_preset_6_thumb'))
          this.PresetBackgroundThumbnail('preset_7', $r('app.media.background_preset_7'), $r('app.media.background_preset_7_thumb'))
        }
        .height(BACKGROUND_THUMBNAIL_HEIGHT)
      }
      .width('100%')
      .height(BACKGROUND_THUMBNAIL_HEIGHT)
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height(BACKGROUND_PICKER_ROW_HEIGHT)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  BackgroundOffThumbnail() {
    Stack({ alignContent: Alignment.Center }) {
      Text('关闭')
        .fontSize(10)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.secondaryTextColor())
    }
    .width(BACKGROUND_THUMBNAIL_WIDTH)
    .height(BACKGROUND_THUMBNAIL_HEIGHT)
    .backgroundColor(this.isDark() ? '#0F0F11' : '#F5F5F5')
    .borderRadius(8)
    .border({
      width: this.bgSelection === 'none' ? 3 : 0.5,
      color: this.bgSelection === 'none' ? this.accentColor() : this.dividerColor()
    })
    .onClick(() => {
      BackgroundManager.setSelection('none');
    })
  }

  @Builder
  PresetBackgroundThumbnail(id: string, source: Resource, thumb: Resource) {
    Image(thumb)
      .width(BACKGROUND_THUMBNAIL_WIDTH)
      .height(BACKGROUND_THUMBNAIL_HEIGHT)
      .objectFit(ImageFit.Cover)
      .borderRadius(8)
      .border({
        width: this.bgSelection === id ? 3 : 0.5,
        color: this.bgSelection === id ? this.accentColor() : this.dividerColor()
      })
      .onClick(() => {
        BackgroundManager.setSelection(id);
      })
  }

  @Builder
  CustomBackgroundThumbnail() {
    Image(this.bgCustomUri)
      .width(BACKGROUND_THUMBNAIL_WIDTH)
      .height(BACKGROUND_THUMBNAIL_HEIGHT)
      .objectFit(ImageFit.Cover)
      .borderRadius(8)
      .border({
        width: this.bgSelection === 'custom' ? 3 : 0.5,
        color: this.bgSelection === 'custom' ? this.accentColor() : this.dividerColor()
      })
      .onClick(() => {
        BackgroundManager.setSelection('custom');
      })
  }

  @Builder
  BackgroundBlurRow() {
    Column({ space: 6 }) {
      Row() {
        Text('背景图模糊程度')
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.primaryTextColor())
          .layoutWeight(1)

        Text(Math.round(this.bgBlurPercent).toString() + '%')
          .fontSize(14)
          .fontColor(this.secondaryTextColor())
      }
      .width('100%')

      Slider({ value: this.bgBlurPercent, min: 0, max: 100, step: 1 })
        .width('100%')
        .selectedColor(this.accentColor())
        .trackColor(this.dividerColor())
        .blockColor(this.accentColor())
        .enabled(this.bgSelection !== 'none')
        .opacity(this.bgSelection === 'none' ? 0.4 : 1)
        .onChange((value: number) => {
          BackgroundManager.setBlurPercent(this.clamp(value, 0, 100));
        })
    }
    .width('100%')
    .height(BACKGROUND_BLUR_ROW_HEIGHT)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  BackgroundBrightnessRow() {
    Column({ space: 6 }) {
      Row() {
        Text('背景图亮度')
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.primaryTextColor())
          .layoutWeight(1)

        Text(Math.round(this.bgBrightnessPercent).toString() + '%')
          .fontSize(14)
          .fontColor(this.secondaryTextColor())
      }
      .width('100%')

      Slider({ value: this.bgBrightnessPercent, min: 0, max: 100, step: 1 })
        .width('100%')
        .selectedColor(this.accentColor())
        .trackColor(this.dividerColor())
        .blockColor(this.accentColor())
        .enabled(this.bgSelection !== 'none')
        .opacity(this.bgSelection === 'none' ? 0.4 : 1)
        .onChange((value: number) => {
          BackgroundManager.setBrightnessPercent(this.clamp(value, 0, 100));
        })
    }
    .width('100%')
    .height(BACKGROUND_BRIGHTNESS_ROW_HEIGHT)
    .justifyContent(FlexAlign.Center)
  }

  private async pickFromGallery(): Promise<void> {
    const ctx = this.getUIContext().getHostContext();
    if (!ctx) {
      return;
    }
    const ok: boolean = await BackgroundManager.pickFromGallery(ctx);
    if (!ok) {
      this.getUIContext().getPromptAction().showToast({ message: '选择背景图失败' });
    }
  }

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.Top }) {
        BackgroundLayer()
        HdsNavigation() {
          Scroll() {
            Column() {
              Blank()
                .height(PAGE_CARD_GAP)

              GlassCard({ cardHeight: ME_ROW_HEIGHT * 2 + 1, cardRadius: ME_CARD_RADIUS }) {
                this.AppearanceCardContent()
              }

              this.SectionTitle('高级材质')
              GlassCard({ cardHeight: ME_ROW_HEIGHT * 3 + 2, cardRadius: ME_CARD_RADIUS }) {
                this.MaterialCardContent()
              }

              this.SectionTitle('背景图')
              GlassCard({ cardHeight: this.backgroundCardHeight(), cardRadius: ME_CARD_RADIUS }) {
                this.BackgroundCardContent()
              }

              Blank()
                .height(20)
            }
            .width('100%')
            .padding({
              left: HOME_HORIZONTAL_PADDING,
              right: HOME_HORIZONTAL_PADDING,
              bottom: 20
            })
          }
          .width('100%').height('100%')
          .align(Alignment.Top)
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
          .contentStartOffset(this.statusBarHeight + HOME_TITLE_HEIGHT + PAGE_CARD_GAP)
          .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
          .scrollBar(BarState.Off)
          .clip(false)
        }
        .mode(NavigationMode.Stack)
        .titleBar({
          content: {
            title: { mainTitle: '外观与主题' },
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
