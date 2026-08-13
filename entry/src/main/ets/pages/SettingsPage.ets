// SettingsPage.ets — 设置页：外观与主题 / 账号与安全 / 退出登录
// NavDestination 子页：系统标题栏自动处理状态栏安全区，原生返回键（单箭头无字）
import { router } from '@kit.ArkUI';
import { ThemeColors } from '../utils/ThemeColors';
import { PreferenceUtil } from '../utils/PreferenceUtil';
import { SqgService } from '../services/SqgService';
import { MaterialConfig } from '../utils/MaterialConfig';

const TAG = 'SettingsPage';

const MATERIAL_TYPE_OPTIONS: SelectOption[] = [
  { value: '自适应' }, { value: '沉浸' }, { value: '无材质' }
];
const MATERIAL_LEVEL_OPTIONS: SelectOption[] = [
  { value: '自适应' }, { value: '精致' }, { value: '柔和' }, { value: '平滑' }
];

@Component
export struct SettingsPage {
  @Consume('pageStack') pageStack: NavPathStack;
  @State globalImmersion: boolean = true;
  @State materialType: string = '自适应';
  @State materialLevel: string = '自适应';

  aboutToAppear(): void {
    this.globalImmersion = MaterialConfig.globalImmersionEnabled();
    this.materialType = MaterialConfig.materialTypeName();
    this.materialLevel = MaterialConfig.materialLevelName();
  }

  private logout(): void {
    SqgService.getInstance().clearUserData().catch(() => {
    });
    PreferenceUtil.putBool('is_logged_in', false);
    router.replaceUrl({ url: 'pages/login/LoginPage' });
  }

  private openAccountSecurity(): void {
    this.pageStack.pushPathByName('AccountSecurityPage', undefined);
  }

  @Builder
  ListItem(icon: Resource, label: string, onClick: () => void) {
    Row() {
      Image(icon)
        .width(20).height(20).fillColor(ThemeColors.textPrimary).objectFit(ImageFit.Contain)
        .margin({ left: 16, right: 14 })
      Text(label).fontSize(15).fontColor(ThemeColors.textPrimary).layoutWeight(1)
      Text('›').fontSize(18).fontColor(ThemeColors.textSecondary).margin({ right: 16 })
    }
    .width('100%').height(52).alignItems(VerticalAlign.Center)
    .onClick(onClick)
  }

  // 开关行（全局沉浸光感）
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

  // 选择行（材质类型/等级）
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
          // 外观与主题模块
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

          // 账号与安全模块
          Column() {
            this.ListItem($r('app.media.ic_lock'), '账号与安全', () => { this.openAccountSecurity(); })
          }
          .width('100%').backgroundColor(ThemeColors.bgCard).borderRadius(16)
          .margin({ top: 12, left: 12, right: 12 })
          .padding({ top: 4, bottom: 4 })

          Blank().height(24)
          Button('退出登录')
            .fontSize(14).fontColor('#E53935')
            .width('88%').height(46)
            .backgroundColor(ThemeColors.bgCard).borderRadius(23)
            .margin({ bottom: 24 })
            .onClick(() => this.logout())
        }
        .width('100%')
      }
      .width('100%').height('100%')
      .scrollBar(BarState.Off)
      .backgroundColor(ThemeColors.bgPage)
    }
    .title('设置')
    .backgroundColor(ThemeColors.bgPage)
    .hideTitleBar(false)
  }
}
