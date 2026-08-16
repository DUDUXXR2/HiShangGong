import { hdsMaterial, SystemMaterialParams } from '@kit.UIDesignKit';
import { PreferenceUtil } from '../utils/PreferenceUtil';

const TAG = 'MaterialConfig';
const KEY_IMMERSION = 'ui_global_immersion';
const KEY_MATERIAL_TYPE = 'ui_material_type';
const KEY_MATERIAL_LEVEL = 'ui_material_level';

const PREF_IMMERSION = 'material_immersion';
const PREF_MATERIAL_TYPE = 'material_type';
const PREF_MATERIAL_LEVEL = 'material_level';

export class MaterialConfig {
  static init(): void {
    const savedImmersion: boolean = PreferenceUtil.getBool(PREF_IMMERSION, true);
    AppStorage.setOrCreate<boolean>(KEY_IMMERSION, savedImmersion);

    const savedType: string = PreferenceUtil.getString(PREF_MATERIAL_TYPE, '自适应');
    AppStorage.setOrCreate<string>(KEY_MATERIAL_TYPE, savedType);

    const savedLevel: string = PreferenceUtil.getString(PREF_MATERIAL_LEVEL, '自适应');
    AppStorage.setOrCreate<string>(KEY_MATERIAL_LEVEL, savedLevel);
  }

  static globalImmersionEnabled(): boolean {
    const v = AppStorage.get<boolean>(KEY_IMMERSION);
    return v === undefined ? true : v;
  }

  static setGlobalImmersion(enabled: boolean): void {
    AppStorage.setOrCreate<boolean>(KEY_IMMERSION, enabled);
    PreferenceUtil.putBool(PREF_IMMERSION, enabled);
  }

  static materialTypeName(): string {
    return AppStorage.get<string>(KEY_MATERIAL_TYPE) ?? '自适应';
  }

  static setMaterialType(name: string): void {
    AppStorage.setOrCreate<string>(KEY_MATERIAL_TYPE, name);
    PreferenceUtil.putString(PREF_MATERIAL_TYPE, name);
  }

  static materialLevelName(): string {
    return AppStorage.get<string>(KEY_MATERIAL_LEVEL) ?? '自适应';
  }

  static setMaterialLevel(name: string): void {
    AppStorage.setOrCreate<string>(KEY_MATERIAL_LEVEL, name);
    PreferenceUtil.putString(PREF_MATERIAL_LEVEL, name);
  }

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

  static shouldUseCardMaterial(): boolean {
    return MaterialConfig.globalImmersionEnabled() &&
      MaterialConfig.configuredMaterialType() !== hdsMaterial.MaterialType.NONE;
  }

  static systemMaterialEffectParams(): SystemMaterialParams {
    return {
      materialType: MaterialConfig.shouldUseCardMaterial()
        ? MaterialConfig.configuredMaterialType()
        : hdsMaterial.MaterialType.NONE,
      materialLevel: MaterialConfig.configuredMaterialLevel()
    };
  }
}
