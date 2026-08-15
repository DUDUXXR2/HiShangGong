// BackgroundManager.ets — 全局背景图管理
// BackgroundManager：状态读写/持久化/图库选图
// BackgroundLayer：渲染层（@StorageProp 响应式），供各页面根 Stack 作为第一个子元素调用
import { fileIo, fileUri } from '@kit.CoreFileKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { common } from '@kit.AbilityKit';
import { PreferenceUtil } from './PreferenceUtil';

const TAG = 'BackgroundManager';

// AppStorage 键（供各页面通过 @StorageProp/@StorageLink 响应式读取）
export const BG_SELECTION_KEY: string = 'bg_selection';
export const BG_CUSTOM_URI_KEY: string = 'bg_custom_uri';
export const BG_BLUR_PERCENT_KEY: string = 'bg_blur_percent';
export const BG_BRIGHTNESS_PERCENT_KEY: string = 'bg_brightness_percent';
export const BG_GLOBAL_KEY: string = 'bg_global';

// PreferenceUtil 持久化键
const PREF_SELECTION: string = 'bg_selection';
const PREF_CUSTOM_URI: string = 'bg_custom_uri';
const PREF_BLUR: string = 'bg_blur_percent';
const PREF_BRIGHTNESS: string = 'bg_brightness_percent';
const PREF_GLOBAL: string = 'bg_global';

const BACKGROUND_BLUR_MAX_RADIUS: number = 50;

export class BackgroundManager {
  // ===== 读写 AppStorage 状态（响应式，供页面 UI 绑定）=====

  static selection(): string {
    return AppStorage.get<string>(BG_SELECTION_KEY) ?? 'none';
  }

  static customUri(): string {
    return AppStorage.get<string>(BG_CUSTOM_URI_KEY) ?? '';
  }

  static blurPercent(): number {
    return AppStorage.get<number>(BG_BLUR_PERCENT_KEY) ?? 0;
  }

  static brightnessPercent(): number {
    return AppStorage.get<number>(BG_BRIGHTNESS_PERCENT_KEY) ?? 50;
  }

  static globalEnabled(): boolean {
    return AppStorage.get<boolean>(BG_GLOBAL_KEY) ?? true;
  }

  // 是否实际显示背景
  static isEnabled(): boolean {
    return BackgroundManager.globalEnabled() && BackgroundManager.selection() !== 'none';
  }

  // 页面背景色：背景开启时透明（露出背景层），否则用正常页面底色
  static pageBackgroundColor(dark: boolean): string {
    return BackgroundManager.isEnabled() ? '#00000000' : (dark ? '#0F0F11' : '#F5F5F5');
  }

  // ===== 初始化（启动/页面 aboutToAppear 调用）=====

  static init(): void {
    BackgroundManager.setSelection(PreferenceUtil.getString(PREF_SELECTION, 'none'));
    BackgroundManager.setCustomUri(PreferenceUtil.getString(PREF_CUSTOM_URI));
    BackgroundManager.setBlurPercent(PreferenceUtil.getNumber(PREF_BLUR, 0));
    BackgroundManager.setBrightnessPercent(PreferenceUtil.getNumber(PREF_BRIGHTNESS, 50));
    BackgroundManager.setGlobalEnabled(PreferenceUtil.getBool(PREF_GLOBAL, true));
  }

  // ===== 修改并持久化 =====

  static setSelection(value: string): void {
    AppStorage.setOrCreate(BG_SELECTION_KEY, value);
    PreferenceUtil.putString(PREF_SELECTION, value);
  }

  static setCustomUri(value: string): void {
    AppStorage.setOrCreate(BG_CUSTOM_URI_KEY, value);
    PreferenceUtil.putString(PREF_CUSTOM_URI, value);
  }

  static setBlurPercent(value: number): void {
    AppStorage.setOrCreate(BG_BLUR_PERCENT_KEY, value);
    PreferenceUtil.putNumber(PREF_BLUR, value);
  }

  static setBrightnessPercent(value: number): void {
    AppStorage.setOrCreate(BG_BRIGHTNESS_PERCENT_KEY, value);
    PreferenceUtil.putNumber(PREF_BRIGHTNESS, value);
  }

  static setGlobalEnabled(value: boolean): void {
    AppStorage.setOrCreate(BG_GLOBAL_KEY, value);
    PreferenceUtil.putBool(PREF_GLOBAL, value);
  }

  // ===== 从图库选择背景图（PhotoViewPicker 系统选择器，无需权限声明）=====

  static async pickFromGallery(context: Object): Promise<boolean> {
    try {
      const options = new photoAccessHelper.PhotoSelectOptions();
      options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
      options.maxSelectNumber = 1;
      options.isEditSupported = true;
      const photoPicker = new photoAccessHelper.PhotoViewPicker();
      const result = await photoPicker.select(options);
      if (!result.photoUris || result.photoUris.length === 0) {
        return false;
      }
      const pickedUri = result.photoUris[0];
      const ctx = context as common.UIAbilityContext;
      const materializedUri = await BackgroundManager.persistPicked(ctx, pickedUri);
      if (materializedUri.length === 0) {
        return false;
      }
      BackgroundManager.setCustomUri(materializedUri);
      BackgroundManager.setSelection('custom');
      return true;
    } catch (error) {
      console.error(TAG + ' pickFromGallery failed: ' + JSON.stringify(error));
      return false;
    }
  }

  private static async persistPicked(context: common.UIAbilityContext, uri: string): Promise<string> {
    const targetPath = context.filesDir + '/background_' + Date.now().toString() + '.jpg';
    let sourceFile: fileIo.File | undefined = undefined;
    try {
      sourceFile = fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY);
      await fileIo.copyFile(sourceFile.fd, targetPath);
      return fileUri.getUriFromPath(targetPath);
    } catch (error) {
      console.error(TAG + ' persistPicked failed: ' + JSON.stringify(error));
      return '';
    } finally {
      if (sourceFile !== undefined) {
        fileIo.closeSync(sourceFile);
      }
    }
  }
}

// ===== 渲染层（放在页面根 Stack 最底部，@StorageProp 响应式）=====

@Component
export struct BackgroundLayer {
  @StorageProp(BG_SELECTION_KEY) bgSelection: string = 'none';
  @StorageProp(BG_CUSTOM_URI_KEY) bgCustomUri: string = '';
  @StorageProp(BG_BLUR_PERCENT_KEY) bgBlurPercent: number = 0;
  @StorageProp(BG_BRIGHTNESS_PERCENT_KEY) bgBrightnessPercent: number = 50;
  @StorageProp(BG_GLOBAL_KEY) bgGlobal: boolean = true;

  private isEnabled(): boolean {
    return this.bgGlobal && this.bgSelection !== 'none';
  }

  private blurRadius(): number {
    return this.bgBlurPercent / 100 * BACKGROUND_BLUR_MAX_RADIUS;
  }

  private imageScale(): number {
    return 1 + this.bgBlurPercent / 100 * 0.12;
  }

  @Builder
  PresetBackgroundImageLayer(source: Resource, height: Length, radius: number) {
    Image(source)
      .width('100%')
      .height(height)
      .syncLoad(true)
      .objectFit(ImageFit.Cover)
      .borderRadius(radius)
      .blur(this.blurRadius())
      .scale({ x: this.imageScale(), y: this.imageScale() })
      .zIndex(0)
      .hitTestBehavior(HitTestMode.None)
  }

  @Builder
  SelectedBackgroundImage(height: Length, radius: number) {
    if (this.bgSelection === 'custom' && this.bgCustomUri.length > 0) {
      Image(this.bgCustomUri)
        .width('100%')
        .height(height)
        .syncLoad(true)
        .objectFit(ImageFit.Cover)
        .borderRadius(radius)
        .blur(this.blurRadius())
        .scale({ x: this.imageScale(), y: this.imageScale() })
        .zIndex(0)
        .hitTestBehavior(HitTestMode.None)
    } else if (this.bgSelection === 'preset_2') {
      this.PresetBackgroundImageLayer($r('app.media.background_preset_2'), height, radius)
    } else if (this.bgSelection === 'preset_3') {
      this.PresetBackgroundImageLayer($r('app.media.background_preset_3'), height, radius)
    } else if (this.bgSelection === 'preset_4') {
      this.PresetBackgroundImageLayer($r('app.media.background_preset_4'), height, radius)
    } else if (this.bgSelection === 'preset_5') {
      this.PresetBackgroundImageLayer($r('app.media.background_preset_5'), height, radius)
    } else if (this.bgSelection === 'preset_6') {
      this.PresetBackgroundImageLayer($r('app.media.background_preset_6'), height, radius)
    } else if (this.bgSelection === 'preset_7') {
      this.PresetBackgroundImageLayer($r('app.media.background_preset_7'), height, radius)
    } else {
      this.PresetBackgroundImageLayer($r('app.media.background_preset_1'), height, radius)
    }
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      if (this.isEnabled()) {
        this.SelectedBackgroundImage('100%', 0)
      }
    }
    .width('100%')
    .height('100%')
    .position({ x: 0, y: 0 })
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .renderGroup(this.isEnabled())
    .brightness(this.bgBrightnessPercent / 50)
    .hitTestBehavior(HitTestMode.None)
  }
}
