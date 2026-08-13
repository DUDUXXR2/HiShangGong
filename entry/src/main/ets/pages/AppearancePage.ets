// AppearancePage.ets — 外观与主题：全局沉浸光感 + 材质类型/等级 自定义
// 独立页面（复刻 Authenticator 的 appearanceSettings）
import { ThemeColors } from '../utils/ThemeColors';
import { MaterialConfig } from '../utils/MaterialConfig';

const TAG = 'AppearancePage';

const MATERIAL_TYPE_OPTIONS: SelectOption[] = [
  { value: '自适应' }, { value: '沉浸' }, { value: '无材质' }
];
const MATERIAL_LEVEL_OPTIONS: SelectOption[] = [
  { value: '自适应' }, { value: '精致' }, { value: '柔和' }, { value: '平滑' }
];

@Component
export struct AppearancePage {
  @Consume('pageStack') pageStack: NavPathStack;
  @State globalImmersion: boolean = true;
  @State materialType: string = '自适应';
  @State materialLevel: string = '自适应';

  aboutToAppear(): void {
    this.globalImmersion = MaterialConfig.globalImmersionEnabled();
    this.materialType = MaterialConfig.materialTypeName();
    this.materialLevel = MaterialConfig.materialLevelName();
  }

  @Builder
  SwitchRow(label: string, value: boolean, onChange: (v: boolean) => void) {
    Row() {
      Text(label).fontSize(15).fontWeight(FontWeight.Medium)
        .fontColor(ThemeColors.textPrimary).layoutWeight(1).margin({ left: 16 })
      Toggle({ type: ToggleType.Switch, isOn: value })
        .selectedColor('#2979FF')
        .switchPointColor('#FFFFFF')
        .margin({ right: 16 })
        .onChange((checked: boolean) => { onChange(checked); })
    }
    .width('100%').height(52).alignItems(VerticalAlign.Center)
  }

  @Builder
  SelectRow(label: string, value: string, options: SelectOption[], onChange: (v: string) => void) {
    Row() {
      Text(label).fontSize(15).fontWeight(FontWeight.Medium)
        .fontColor(ThemeColors.textPrimary).layoutWeight(1).margin({ left: 16 })
      Select(options)
        .selected(options.findIndex((o: SelectOption) => String(o.value) === value))
        .value(value)
        .font({ size: 15, weight: FontWeight.Regular })
        .fontColor(ThemeColors.textSecondary)
        .selectedOptionFont({ size: 15, weight: FontWeight.Regular })
        .optionFont({ size: 15, weight: FontWeight.Regular })
        .margin({ right: 16 })
        .onSelect((index: number) => {
          if (index >= 0 && index < options.length) {
            onChange(String(options[index].value));
          }
        })
    }
    .width('100%').height(52).alignItems(VerticalAlign.Center)
  }

  @Builder
  DividerLine() {
    Divider().color('#20000000').strokeWidth(0.5).margin({ left: 16, right: 16 })
  }

  build() {
    NavDestination() {
      Scroll() {
        Column() {
          Column() {
            this.SwitchRow('全局沉浸光感', this.globalImmersion, (v: boolean) => {
              this.globalImmersion = v;
              MaterialConfig.setGlobalImmersion(v);
            })
            this.DividerLine()
            this.SelectRow('材质类型', this.materialType, MATERIAL_TYPE_OPTIONS, (v: string) => {
              this.materialType = v;
              MaterialConfig.setMaterialType(v);
            })
            this.DividerLine()
            this.SelectRow('材质等级', this.materialLevel, MATERIAL_LEVEL_OPTIONS, (v: string) => {
              this.materialLevel = v;
              MaterialConfig.setMaterialLevel(v);
            })
          }
          .width('100%').backgroundColor(ThemeColors.bgCard).borderRadius(16)
          .margin({ top: 12, left: 12, right: 12 })
          .padding({ top: 4, bottom: 4 })
        }
        .width('100%')
      }
      .width('100%').height('100%')
      .scrollBar(BarState.Off)
      .backgroundColor(ThemeColors.bgPage)
    }
    .title('外观与主题')
    .backgroundColor(ThemeColors.bgPage)
    .hideTitleBar(false)
  }
}
