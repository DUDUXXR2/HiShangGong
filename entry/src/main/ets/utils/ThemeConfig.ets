import { ConfigurationConstant, common } from '@kit.AbilityKit';
import { PreferenceUtil } from '../utils/PreferenceUtil';
import { ThemeColors } from '../utils/ThemeColors';

const PREF_DARK_MODE = 'theme_color_mode';
const PREF_FONT_SIZE = 'theme_font_size';

export class ThemeConfig {
  static darkModeName(): string {
    const mode: number = PreferenceUtil.getNumber(PREF_DARK_MODE,
      ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    if (mode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK) {
      return '开启';
    }
    if (mode === ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT) {
      return '关闭';
    }
    return '跟随系统';
  }

  static setDarkMode(name: string, ctx: Object): void {
    let mode: number = ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET;
    if (name === '开启') {
      mode = ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
    } else if (name === '关闭') {
      mode = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
    }
    PreferenceUtil.putNumber(PREF_DARK_MODE, mode);
    if (mode === ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET) {
      ThemeColors.applyFollowSystem(ctx);
    } else {
      ThemeColors.applyManual(mode, ctx);
    }
  }

  static fontSizeName(): string {
    return PreferenceUtil.getString(PREF_FONT_SIZE, '跟随系统');
  }

  static setFontSize(name: string, ctx: Object): void {
    PreferenceUtil.putString(PREF_FONT_SIZE, name);
    const scale: number = ThemeConfig.fontSizeScale();
    const abilityCtx: common.UIAbilityContext = ctx as common.UIAbilityContext;
    abilityCtx.getApplicationContext().setFontSizeScale(scale);
    AppStorage.setOrCreate<number>('font_size_scale', scale);
  }

  static fontSizeScale(): number {
    const name: string = ThemeConfig.fontSizeName();
    if (name === '小号') {
      return 0.85;
    }
    if (name === '大号') {
      return 1.25;
    }
    return 1.0;
  }

  static init(): void {
    const mode: number = PreferenceUtil.getNumber(PREF_DARK_MODE,
      ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    PreferenceUtil.putNumber(PREF_DARK_MODE, mode);
  }
}
