// SettingRowCard.ets — 设置类页面统一行卡片（复刻 Mine 页 MeActionCard 样式）
// 玻璃卡片内一行：[图标 文字 Blank 右箭头]，点击按压 scale 动画
// 用法：
//   SettingRowCard({ icon: $r('app.media.ic_lock'), label: '账号与安全', onClick: () => {} })
// 也可传入子内容（多行时用 RowItems 复用）。
import { HdsTabs, hdsMaterial } from '@kit.UIDesignKit';
import { ThemeColors } from '../utils/ThemeColors';
import { MaterialConfig } from '../utils/MaterialConfig';

const CARD_PRESS_ANIMATION_DURATION: number = 160;
const CARD_PRESSED_SCALE: number = 0.97;
const ROW_HEIGHT: number = 60;
const CARD_RADIUS: number = 15;

@Component
export struct SettingRowCard {
  @Prop icon: Resource = $r('app.media.ic_settings');
  @Prop label: string = '';
  @Prop value: string = '';
  @State pressed: boolean = false;
  @State cardWidth: number = 0;
  action: () => void = () => {
  };

  private isDark(): boolean {
    return ThemeColors.isDark;
  }

  private cardBackgroundColor(): string {
    return this.isDark() ? '#191919' : '#FFFFFF';
  }

  private primaryTextColor(): string {
    return this.isDark() ? '#EEEEEE' : '#1A1A1A';
  }

  private secondaryTextColor(): string {
    if (this.shouldUseCardMaterial()) {
      return this.isDark() ? '#D0D0D0' : '#4A4A4A';
    }
    return this.isDark() ? '#B8B8B8' : '#666666';
  }

  private cardSurfaceBaseColor(fallback: ResourceColor): ResourceColor {
    return this.shouldUseCardMaterial() ? Color.Transparent : fallback;
  }

  private immersionBorderColor(): ResourceColor {
    return this.isDark() ? '#80FFFFFF' : '#80000000';
  }

  private cardSurfaceBorderWidth(): number {
    return this.shouldUseCardMaterial() ? 0.5 : 0;
  }

  private shouldUseCardMaterial(): boolean {
    return MaterialConfig.shouldUseCardMaterial();
  }

  private configuredMaterialType(): hdsMaterial.MaterialType {
    return MaterialConfig.configuredMaterialType();
  }

  private configuredMaterialLevel(): hdsMaterial.MaterialLevel {
    return MaterialConfig.configuredMaterialLevel();
  }

  private appCardScale(): number {
    return this.pressed ? CARD_PRESSED_SCALE : 1;
  }

  private handleTouch(type: TouchType): void {
    if (type === TouchType.Down) {
      this.pressed = true;
    } else if (type === TouchType.Up || type === TouchType.Cancel) {
      this.pressed = false;
    }
  }

  private expandedWidth(): number {
    return Math.max(this.cardWidth, 480) + ROW_HEIGHT * 2;
  }

  @Builder
  MaterialContent() {
    Stack()
      .width(this.expandedWidth())
      .height(ROW_HEIGHT)
      .backgroundColor(Color.Transparent)
      .hitTestBehavior(HitTestMode.None)
  }

  @Builder
  ImmersionCardSurface() {
    Stack({ alignContent: Alignment.Center }) {
      HdsTabs() {
        TabContent() {
        }
        .backdropBlur(0)
        .tabBar(this.MaterialContent())
        .clip(false)
      }
      .width(this.expandedWidth())
      .height(ROW_HEIGHT)
      .barWidth(this.expandedWidth())
      .barHeight(ROW_HEIGHT)
      .barOverlap(true)
      .barPosition(BarPosition.End)
      .barBackgroundStyle({ maskColor: '#00000000' })
      .barBackgroundBlurStyle(BlurStyle.NONE)
      .barFloatingStyle({
        barBottomMargin: 0,
        systemMaterialEffect: {
          materialType: this.configuredMaterialType(),
          materialLevel: this.configuredMaterialLevel()
        },
        gradientMask: { maskColor: '#09999999' }
      })
      .backgroundColor(Color.Transparent)
      .hitTestBehavior(HitTestMode.None)
      .clip(false)
    }
    .width('100%')
    .height(ROW_HEIGHT)
    .borderRadius(CARD_RADIUS)
    .clip(true)
    .backgroundColor(Color.Transparent)
    .hitTestBehavior(HitTestMode.None)
    .zIndex(1)
  }

  build() {
    Stack({ alignContent: Alignment.Top }) {
      this.ImmersionCardSurface()
      Row({ space: 16 }) {
        Image(this.icon)
          .width(20)
          .height(20)
          .fillColor(this.primaryTextColor())
          .objectFit(ImageFit.Contain)
        Text(this.label)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.primaryTextColor())
          .layoutWeight(1)
        if (this.value.length > 0) {
          Text(this.value)
            .fontSize(14)
            .fontColor(this.secondaryTextColor())
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        } else {
          SymbolGlyph($r('sys.symbol.chevron_right'))
            .fontSize(20)
            .fontColor([this.secondaryTextColor()])
            .fontWeight(FontWeight.Medium)
            .renderingStrategy(SymbolRenderingStrategy.SINGLE)
        }
      }
      .width('100%')
      .height(ROW_HEIGHT)
      .padding({ left: 20, right: 18 })
      .alignItems(VerticalAlign.Center)
      .zIndex(2)
    }
    .width('100%')
    .height(ROW_HEIGHT)
    .borderRadius(CARD_RADIUS)
    .clip(true)
    .backgroundColor(this.cardSurfaceBaseColor(this.cardBackgroundColor()))
    .border({ width: this.cardSurfaceBorderWidth(), color: this.immersionBorderColor() })
    .scale({ x: this.appCardScale(), y: this.appCardScale() })
    .animation({ duration: CARD_PRESS_ANIMATION_DURATION, curve: Curve.Friction })
    .onTouch((event: TouchEvent) => {
      this.handleTouch(event.type);
    })
    .onAreaChange((oldValue: Area, newValue: Area) => {
      const w = newValue.width as number;
      if (w > 0 && Math.abs(w - this.cardWidth) > 1) {
        this.cardWidth = w;
      }
    })
    .onClick(() => {
      this.action();
    })
  }
}
