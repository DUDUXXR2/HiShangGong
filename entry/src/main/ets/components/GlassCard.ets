// GlassCard.ets — 液态玻璃卡片（复刻 MineTab 的 ImmersionCardSurface）
// 用法：
//   GlassCard({ cardHeight: 120 }) {
//     // 卡片内容
//   }
import { HdsTabs, hdsMaterial } from '@kit.UIDesignKit';
import { ThemeColors } from '../utils/ThemeColors';
import { MaterialConfig } from '../utils/MaterialConfig';

@Component
export struct GlassCard {
  @Prop cardHeight: number = 60;
  @Prop cardRadius: number = 15;
  @BuilderParam content: () => void = this.defaultContent;
  @State cardWidth: number = 0;
  // 材质设置变更时触发重新渲染（全局即时生效）
  @StorageProp('ui_material_version') materialVersion: number = 0;

  @Builder defaultContent() {
    Column().width('100%')
  }

  private isDark(): boolean {
    return ThemeColors.isDark;
  }

  private cardBackgroundColor(): string {
    return this.isDark() ? '#191919' : '#FFFFFF';
  }

  private cardSurfaceBaseColor(fallback: ResourceColor): ResourceColor {
    return MaterialConfig.shouldUseCardMaterial() ? Color.Transparent : fallback;
  }

  private cardSurfaceBorderWidth(): number {
    return MaterialConfig.shouldUseCardMaterial() ? 0.5 : 0;
  }

  private immersionBorderColor(): ResourceColor {
    return this.isDark() ? '#80FFFFFF' : '#80000000';
  }

  private configuredMaterialType(): hdsMaterial.MaterialType {
    return MaterialConfig.configuredMaterialType();
  }

  private configuredMaterialLevel(): hdsMaterial.MaterialLevel {
    return MaterialConfig.configuredMaterialLevel();
  }

  private expandedWidth(cardHeight: number): number {
    return Math.max(this.cardWidth, 480) + cardHeight * 2;
  }

  @Builder
  MaterialContent(cardHeight: number) {
    Stack()
      .width(this.expandedWidth(cardHeight))
      .height(cardHeight)
      .backgroundColor(Color.Transparent)
      .hitTestBehavior(HitTestMode.None)
  }

  @Builder
  MaterialLayer(cardHeight: number, cardRadius: number) {
    Stack({ alignContent: Alignment.Center }) {
      HdsTabs() {
        TabContent() {
        }
        .backdropBlur(0)
        .tabBar(this.MaterialContent(cardHeight))
        .clip(false)
      }
      .width(this.expandedWidth(cardHeight))
      .height(cardHeight)
      .barWidth(this.expandedWidth(cardHeight))
      .barHeight(cardHeight)
      .barOverlap(true)
      .barPosition(BarPosition.End)
      .barBackgroundStyle({ maskColor: '#00000000' })
      .barBackgroundBlurStyle(BlurStyle.NONE)
      .barFloatingStyle({
        barBottomMargin: 0,
        systemMaterialEffect: {
          materialType: this.configuredMaterialType(),
          materialLevel: this.configuredMaterialLevel()
        }
      })
      .backgroundColor(Color.Transparent)
      .hitTestBehavior(HitTestMode.None)
      .clip(false)
    }
    .width('100%')
    .height(cardHeight)
    .borderRadius(cardRadius)
    .clip(true)
    .backgroundColor(Color.Transparent)
    .hitTestBehavior(HitTestMode.None)
    .zIndex(1)
  }

  build() {
    Stack({ alignContent: Alignment.Top }) {
      this.MaterialLayer(this.cardHeight, this.cardRadius)
      Stack() {
        this.content()
      }
      .width('100%')
      .height(this.cardHeight)
      .alignContent(Alignment.Top)
      .zIndex(2)
    }
    .width('100%')
    .height(this.cardHeight)
    .borderRadius(this.cardRadius)
    .clip(true)
    .backgroundColor(this.cardSurfaceBaseColor(this.cardBackgroundColor()))
    .border({ width: this.cardSurfaceBorderWidth(), color: this.immersionBorderColor() })
    .onAreaChange((oldValue: Area, newValue: Area) => {
      const w = newValue.width as number;
      if (w > 0 && Math.abs(w - this.cardWidth) > 1) {
        this.cardWidth = w;
      }
    })
  }
}
