import web_webview from '@ohos.web.webview';
import { window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { ThemeColors } from '../utils/ThemeColors';
import { PreferenceUtil } from '../utils/PreferenceUtil';
import { HttpUtil } from '../utils/HttpUtil';
import { CAS_ARRY } from '../services/SqgConstants';
import { WebPageParam } from './NavParams';
import StatusBarUtil from '../utils/StatusBarUtil';

class WebHeader {
  headerKey: string = '';
  headerValue: string = '';

  constructor(key: string, value: string) {
    this.headerKey = key;
    this.headerValue = value;
  }
}

export class WebBridge {
  updateStatusBar(barColor: string, textColor: string): void {
    StatusBarUtil.setStatusBarColor(barColor, textColor);
  }
}

@Component
export struct ServiceWebPage {
  @Consume('pageStack') pageStack: NavPathStack;
  @State title: string = '服务';
  @State url: string = '';
  @State isLoading: boolean = true;
  @State loadError: string = '';
  private webController: web_webview.WebviewController = new web_webview.WebviewController();
  private bridge: WebBridge = new WebBridge();
  private scrollTimer: number = -1;

  aboutToAppear(): void {
    try {
      const list = this.pageStack.getParamByName('ServiceWebPage') as WebPageParam[];
      if (list !== undefined && list !== null && list.length > 0) {
        const p: WebPageParam = list[0];
        this.title = p.title.length > 0 ? p.title : '服务';
        this.url = p.url;
      }
    } catch (e) {
    }
    StatusBarUtil.resetStatusBar();
    setTimeout(() => { this.loadWithAuth(); }, 50);
  }

  aboutToDisappear(): void {
    StatusBarUtil.resetStatusBar();
    if (this.scrollTimer >= 0) {
      clearTimeout(this.scrollTimer);
      this.scrollTimer = -1;
    }
  }

  private loadWithAuth(): void {
    const target: string = this.url;
    if (target.length === 0) {
      return;
    }
    const token: string = PreferenceUtil.getString('id_token');
    const isTrustedDomain: boolean = this.isInCasArry(target);
    const headers: WebHeader[] = [];
    if (isTrustedDomain && token.length > 0) {
      headers.push(new WebHeader('X-Id-Token', token));
      headers.push(new WebHeader('idToken', token));
    }
    headers.push(new WebHeader('X-Terminal-Info', 'app'));
    headers.push(new WebHeader('Accept', 'application/json'));

    try {
      const domain: string = this.hostOf(target);
      if (domain.length > 0) {
        const cookies: string = HttpUtil.getInstance().getCookiesForDomain(domain);
        if (cookies.length > 0) {
          web_webview.WebCookieManager.setCookie('https://' + domain, cookies + '; Path=/');
        }
        if (isTrustedDomain && token.length > 0) {
          web_webview.WebCookieManager.setCookie('https://' + domain, 'X-Id-Token=' + token + '; Path=/');
        }
      }
    } catch (e) {
    }

    try {
      this.webController.loadUrl(target, headers);
    } catch (e) {
      this.loadError = '加载失败：' + String(e);
    }
  }

  private isInCasArry(url: string): boolean {
    for (let i = 0; i < CAS_ARRY.length; i++) {
      if (url.startsWith(CAS_ARRY[i])) {
        return true;
      }
    }
    return false;
  }

  private hostOf(url: string): string {
    const m: RegExpMatchArray | null = url.match(/^https?:\/\/([^/]+)/);
    return m ? m[1] : '';
  }

  private goBack(): void {
    try {
      if (this.webController.accessBackward()) {
        this.webController.backward();
        return;
      }
    } catch (e) {
    }
    this.pageStack.pop();
  }

  build() {
    NavDestination() {
      Stack() {
        if (this.url.length > 0) {
          Web({ src: '', controller: this.webController })
            .width('100%').height('100%')
            .javaScriptAccess(true)
            .domStorageAccess(true)
            .javaScriptProxy({
              object: this.bridge,
              methodList: ['updateStatusBar'],
              name: 'etsBridge',
              controller: this.webController
            })
            .onPageBegin(() => {
              this.isLoading = true;
            })
            .onPageEnd(() => {
              this.isLoading = false;
              this.pullTopColor();
            })
            .onScroll(() => {
              if (this.scrollTimer >= 0) {
                clearTimeout(this.scrollTimer);
              }
              this.scrollTimer = setTimeout(() => {
                this.pullTopColor();
                this.scrollTimer = -1;
              }, 50);
            })
            .onErrorReceive(() => {
              this.isLoading = false;
              this.loadError = '页面加载失败';
            })
        } else {
          Column() {
            Text('未提供网页地址').fontSize(14).fontColor(ThemeColors.textSecondary)
          }
          .width('100%').height('100%').justifyContent(FlexAlign.Center)
        }

        if (this.isLoading) {
          LoadingProgress().width(36).height(36).color('#2979FF')
        }

        if (this.loadError.length > 0) {
          Column() {
            Text(this.loadError).fontSize(13).fontColor('#C62828').padding(12)
            Button('重试').fontSize(13).onClick(() => { this.loadWithAuth(); })
          }
          .width('100%')
        }
      }
      .width('100%').height('100%')
    }
    .title(this.title)
    .hideTitleBar(false)
    .backgroundColor($r('sys.color.ohos_id_color_background'))
  }

  private pullTopColor(): void {
    try {
      const script: string =
        '(function(){' +
        '  var el = document.body || document.documentElement;' +
        '  var bg = "";' +
        '  if (el) {' +
        '    bg = window.getComputedStyle(el).backgroundColor;' +
        '    if (!bg || bg === "rgba(0, 0, 0, 0)" || bg === "transparent") {' +
        '      var html = document.documentElement;' +
        '      bg = window.getComputedStyle(html).backgroundColor;' +
        '    }' +
        '  }' +
        '  if (!bg || bg === "rgba(0, 0, 0, 0)" || bg === "transparent") bg = "rgb(255,255,255)";' +
        '  return bg;' +
        '})()';
      this.webController.runJavaScript(script, (err: Error, result: string) => {
        if (err || !result) {
          return;
        }
        const c = StatusBarUtil.rgbToHex(result);
        if (c.length > 0) {
          const textColor: string = StatusBarUtil.textColorForBg(c);
          StatusBarUtil.setStatusBarColor(c, textColor);
        }
      });
    } catch (e) {
    }
  }
}
