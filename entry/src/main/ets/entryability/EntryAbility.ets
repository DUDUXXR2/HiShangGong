import { AbilityConstant, Configuration, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { PreferenceUtil } from '../utils/PreferenceUtil';
import { ThemeColors } from '../utils/ThemeColors';

export default class EntryAbility extends UIAbility {
  private routerPath: string = '';

  async onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): Promise<void> {
    await PreferenceUtil.init(this.context);
    if (want?.parameters?.router) {
      this.routerPath = want.parameters.router.toString();
    }
  }

  onNewWant(want: Want): void {
    if (want?.parameters?.router) {
      this.routerPath = want.parameters.router.toString();
      this.context.eventHub.emit('cardNavigate', this.routerPath);
    }
  }

  onConfigurationUpdate(newConfig: Configuration): void {
    const cm = newConfig.colorMode;
    if (cm === undefined) return;
    const isDark: boolean = (cm === ConfigurationConstant.ColorMode.COLOR_MODE_DARK);

    if (ThemeColors.currentPref === ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET) {
      ThemeColors.onSystemConfig(isDark);
    }
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    const sysColorMode = this.context.config.colorMode;
    const sysDark = (sysColorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK);
    AppStorage.setOrCreate('theme_is_dark', sysDark);

    windowStage.loadContent('pages/Index', (err: BusinessError) => {
      if (err.code) {
        return;
      }
      const win: window.Window = windowStage.getMainWindowSync();

      // 1. 窗口全屏沉浸式布局
      win.setWindowLayoutFullScreen(true).catch((e: BusinessError) => {
        console.error('setWindowLayoutFullScreen failed: ' + e.message);
      });

      // 2. 获取状态栏高度：存 px（topRectHeight）供 px2vp 转换 + 存 vp（statusBarHeight）兼容现有页面
      const sysAvoid = win.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
      AppStorage.setOrCreate<number>('topRectHeight', sysAvoid.topRect.height);
      AppStorage.setOrCreate<number>('statusBarHeight', px2vp(sysAvoid.topRect.height));

      // 3. 获取导航条高度（px）
      const navAvoid = win.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
      AppStorage.setOrCreate<number>('bottomRectHeight', navAvoid.bottomRect.height);

      // 4. 监听避让区变化（折叠屏/横竖屏切换时动态更新）
      win.on('avoidAreaChange', (data: window.AvoidAreaOptions) => {
        if (data.type === window.AvoidAreaType.TYPE_SYSTEM) {
          AppStorage.setOrCreate<number>('topRectHeight', data.area.topRect.height);
          AppStorage.setOrCreate<number>('statusBarHeight', px2vp(data.area.topRect.height));
        } else if (data.type === window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR) {
          AppStorage.setOrCreate<number>('bottomRectHeight', data.area.bottomRect.height);
        }
      });

      // 缓存窗口对象，供 H5 沉浸式页设置状态栏颜色
      AppStorage.setOrCreate('windowClass', win);

      if (this.routerPath) {
        this.context.eventHub.emit('cardNavigate', this.routerPath);
      }
    });
  }
}
