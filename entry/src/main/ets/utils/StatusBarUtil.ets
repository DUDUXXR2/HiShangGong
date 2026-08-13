import { window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';

class StatusBarUtil {
  static setStatusBarColor(bgColor: string, contentColor: string): void {
    const win = AppStorage.get<window.Window>('windowClass');
    if (win === undefined || win === null) {
      return;
    }
    const props: window.SystemBarProperties = {
      statusBarColor: bgColor,
      statusBarContentColor: contentColor
    };
    win.setWindowSystemBarProperties(props).catch((err: BusinessError) => {
      console.error('StatusBarUtil setStatusBarColor failed: ' + err.message);
    });
  }

  static resetStatusBar(): void {
    StatusBarUtil.setStatusBarColor('#00000000', '#000000');
  }

  static textColorForBg(hex: string): string {
    if (hex.length < 7) {
      return '#FFFFFF';
    }
    const r: number = parseInt(hex.substring(1, 3), 16);
    const g: number = parseInt(hex.substring(3, 5), 16);
    const b: number = parseInt(hex.substring(5, 7), 16);
    const lum: number = (0.299 * r + 0.587 * g + 0.114 * b);
    return lum >= 140 ? '#000000' : '#FFFFFF';
  }

  static rgbToHex(input: string): string {
    let s: string = input.trim();
    if (s.startsWith('#')) {
      if (s.length === 7) {
        return s;
      }
      if (s.length === 4) {
        return '#' + s[1] + s[1] + s[2] + s[2] + s[3] + s[3];
      }
      return '';
    }
    const m = s.match(/rgba?\(([\d.]+)[,\s]+([\d.]+)[,\s]+([\d.]+)/);
    if (m) {
      const rv = Math.max(0, Math.min(255, Math.round(parseFloat(m[1]))));
      const gv = Math.max(0, Math.min(255, Math.round(parseFloat(m[2]))));
      const bv = Math.max(0, Math.min(255, Math.round(parseFloat(m[3]))));
      return '#' + StatusBarUtil.toHex(rv) + StatusBarUtil.toHex(gv) + StatusBarUtil.toHex(bv);
    }
    return '';
  }

  static toHex(n: number): string {
    const h: string = n.toString(16);
    return h.length === 1 ? '0' + h : h;
  }
}

export default StatusBarUtil;
