// GlassPanel.ets — 空白沉浸光感容器（全新组件，无任何内容）
import { HdsTabs, hdsMaterial } from '@kit.UIDesignKit';
import { ThemeColors } from '../utils/ThemeColors';
import { MaterialConfig } from '../utils/MaterialConfig';

@Component
export struct GlassPanel {
  @Prop panelHeight: number = 96;
  @Prop panelRadius: number = 16;
  @State panelWidth: number = 0;

  private isDark(): boolean {
    return ThemeColors.isDark;
  }

  private panelBackground(): string {
    return this.isDark() ? '#191919' : '#FFFFFF';
  }

  private panelBaseColor(fallback: ResourceColor): ResourceColor {
    return MaterialConfig.shouldUseCardMaterial() ? Color.Transparent : fallback;
  }

  private panelBorderWidth(): number {
    return MaterialConfig.shouldUseCardMaterial() ? 0.5 : 0;
  }

  private panelBorderColor(): ResourceColor {
    return this.isDark() ? '#80FFFFFF' : '#80000000';
  }

  private configuredMaterialType(): hdsMaterial.MaterialType {
    return MaterialConfig.configuredMaterialType();
  }

  private configuredMaterialLevel(): hdsMaterial.MaterialLevel {
    return MaterialConfig.configuredMaterialLevel();
  }

  private expandedWidth(): number {
    return Math.max(this.panelWidth, 480) + this.panelHeight * 2;
  }

  @Builder
  MaterialContent() {
    Stack()
      .width(this.expandedWidth())
      .height(this.panelHeight)
      .backgroundColor(Color.Transparent)
      .hitTestBehavior(HitTestMode.None)
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      HdsTabs() {
        TabContent() {
        }
        .backdropBlur(0)
        .tabBar(this.MaterialContent())
        .clip(false)
      }
      .width(this.expandedWidth())
      .height(this.panelHeight)
      .barWidth(this.expandedWidth())
      .barHeight(this.panelHeight)
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
    .height(this.panelHeight)
    .borderRadius(this.panelRadius)
    .clip(true)
    .backgroundColor(this.panelBaseColor(this.panelBackground()))
    .border({ width: this.panelBorderWidth(), color: this.panelBorderColor() })
    .onAreaChange((oldValue: Area, newValue: Area) => {
      const w = newValue.width as number;
      if (w > 0 && Math.abs(w - this.panelWidth) > 1) {
        this.panelWidth = w;
      }
    })
  }
}
