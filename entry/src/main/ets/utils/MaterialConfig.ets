// MaterialConfig.ets — 外观与主题：全局沉浸光感 + 材质类型/等级 配置管理
// 状态存 AppStorage，供 MainPage（导航栏/卡片材质）与设置页读写
import { hdsMaterial, SystemMaterialParams } from '@kit.UIDesignKit';

const TAG = 'MaterialConfig';
const KEY_IMMERSION = 'ui_global_immersion';      // 全局沉浸光感开关
const KEY_MATERIAL_TYPE = 'ui_material_type';      // 材质类型：自适应/沉浸/无材质
const KEY_MATERIAL_LEVEL = 'ui_material_level';    // 材质等级：自适应/精致/柔和/平滑
const KEY_MATERIAL_VERSION = 'ui_material_version'; // 版本号：改动后组件响应式刷新

export class MaterialConfig {
  // 读取全局沉浸光感开关（默认开）
  static globalImmersionEnabled(): boolean {
    const v = AppStorage.get<boolean>(KEY_IMMERSION);
    return v === undefined ? true : v;
  }

  static setGlobalImmersion(enabled: boolean): void {
    AppStorage.setOrCreate<boolean>(KEY_IMMERSION, enabled);
    MaterialConfig.bumpVersion();
  }

  // 材质类型（存中文字符串）
  static materialTypeName(): string {
    return AppStorage.get<string>(KEY_MATERIAL_TYPE) ?? '自适应';
  }

  static setMaterialType(name: string): void {
    AppStorage.setOrCreate<string>(KEY_MATERIAL_TYPE, name);
    MaterialConfig.bumpVersion();
  }

  static materialLevelName(): string {
    return AppStorage.get<string>(KEY_MATERIAL_LEVEL) ?? '自适应';
  }

  static setMaterialLevel(name: string): void {
    AppStorage.setOrCreate<string>(KEY_MATERIAL_LEVEL, name);
    MaterialConfig.bumpVersion();
  }

  // 材质版本号：设置改动时 +1，触发绑定组件响应式刷新
  static materialVersion(): number {
    return AppStorage.get<number>(KEY_MATERIAL_VERSION) ?? 0;
  }

  private static bumpVersion(): void {
    const v = MaterialConfig.materialVersion() + 1;
    AppStorage.setOrCreate<number>(KEY_MATERIAL_VERSION, v);
  }

  // 字符串 → MaterialType 枚举
  static configuredMaterialType(): hdsMaterial.MaterialType {
    const name: string = MaterialConfig.materialTypeName();
    if (name === '沉浸') {
      return hdsMaterial.MaterialType.IMMERSIVE;
    }
    if (name === '无材质') {
      return hdsMaterial.MaterialType.NONE;
    }
    return hdsMaterial.MaterialType.ADAPTIVE;
  }

  // 字符串 → MaterialLevel 枚举
  static configuredMaterialLevel(): hdsMaterial.MaterialLevel {
    const name: string = MaterialConfig.materialLevelName();
    if (name === '精致') {
      return hdsMaterial.MaterialLevel.EXQUISITE;
    }
    if (name === '柔和') {
      return hdsMaterial.MaterialLevel.GENTLE;
    }
    if (name === '平滑') {
      return hdsMaterial.MaterialLevel.SMOOTH;
    }
    return hdsMaterial.MaterialLevel.ADAPTIVE;
  }

  // 卡片是否使用玻璃（光感材质）效果
  static shouldUseCardMaterial(): boolean {
    return MaterialConfig.globalImmersionEnabled() &&
      MaterialConfig.configuredMaterialType() !== hdsMaterial.MaterialType.NONE;
  }

  // 返回按钮/导航栏等系统组件的材质参数：全局沉浸光感关闭时回退为无材质（失去毛玻璃+按压发光）
  static systemMaterialEffectParams(): SystemMaterialParams {
    return {
      materialType: MaterialConfig.shouldUseCardMaterial()
        ? MaterialConfig.configuredMaterialType()
        : hdsMaterial.MaterialType.NONE,
      materialLevel: MaterialConfig.configuredMaterialLevel()
    };
  }
}
