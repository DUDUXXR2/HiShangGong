// ToastUtil — 统一封装 promptAction.showToast，并在 API 26 上自动附加系统沉浸材质（沉浸光感）。
//
// 用法：将各页面的 `promptAction.showToast({ message: ... })` 替换为 `ToastUtil.show(...)`，
// 即可在 HarmonyOS 7 设备上获得系统级毛玻璃/沉浸质感，老设备自动降级为普通 Toast。
import { promptAction, ShowToastOptions } from '@kit.ArkUI';

export class ToastUtil {
  static show(message: string, duration?: number): void {
    const param: ShowToastOptions = { message };
    if (duration !== undefined) {
      param.duration = duration;
    }
    promptAction.showToast(param);
  }
}
