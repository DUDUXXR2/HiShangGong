import web_webview from '@ohos.web.webview';
import { common } from '@kit.AbilityKit';
import { SqgService } from '../services/SqgService';
import { CAS_ARRY } from '../services/SqgConstants';
import { HttpUtil } from '../utils/HttpUtil';
import { PreferenceUtil } from '../utils/PreferenceUtil';
import StatusBarUtil from '../utils/StatusBarUtil';
import { BackgroundManager, BackgroundLayer } from '../utils/BackgroundManager';

const FLOATING_BTN_SIZE: number = 36;
const FLOATING_BTN_MARGIN: number = 16;

class WebHeader {
  headerKey: string = '';
  headerValue: string = '';

  constructor(key: string, value: string) {
    this.headerKey = key;
    this.headerValue = value;
  }
}

export class ClassTableBridge {
  updateStatusBar(barColor: string, textColor: string): void {
    StatusBarUtil.setStatusBarColor(barColor, textColor);
  }
}

@Component
export struct ClassTablePage {
  @Consume('pageStack') pageStack: NavPathStack;
  @State title: string = '课表';
  @State url: string = '';
  @State isLoading: boolean = true;
  @State loadError: string = '';
  @State currentUrl: string = '';
  @StorageProp('statusBarHeight') statusBarHeight: number = 0;
  @StorageLink('theme_is_dark') themeIsDark: boolean = false;
  private webController: web_webview.WebviewController = new web_webview.WebviewController();
  private bridge: ClassTableBridge = new ClassTableBridge();
  private scrollTimer: number = -1;

  aboutToAppear(): void {
    StatusBarUtil.setStatusBarColor('#00000000', '#FFFFFF');
    this.loadH5();
  }

  aboutToDisappear(): void {
    StatusBarUtil.resetStatusBar();
    if (this.scrollTimer >= 0) {
      clearTimeout(this.scrollTimer);
      this.scrollTimer = -1;
    }
  }

  private async loadH5(): Promise<void> {
    this.isLoading = true;
    this.loadError = '';
    try {
      const h5 = await SqgService.getInstance().getCourseTableH5Url();
      this.url = SqgService.getInstance().buildServiceUrl(h5, '');
      setTimeout(() => { this.loadWithAuth(); }, 50);
    } catch (e) {
      this.loadError = '获取课表地址失败：' + String(e);
      this.url = '';
    } finally {
      this.isLoading = false;
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
    for (let i: number = 0; i < CAS_ARRY.length; i++) {
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

  private interceptExternalScheme(url: string): boolean {
    if (url.startsWith('alipays://') || url.startsWith('alipay://') ||
      url.startsWith('weixin://') || url.startsWith('wechat://')) {
      try {
        const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
        if (ctx) {
          ctx.openLink(url).catch(() => {
          });
        }
      } catch (e) {
      }
      return true;
    }
    return false;
  }

  private updateStatusBarFromPage(): void {
    try {
      const script: string =
        '(function(){' +
        '  var pick = function(el) {' +
        '    if (!el) return "";' +
        '    var bg = window.getComputedStyle(el).backgroundColor;' +
        '    if (!bg || bg === "rgba(0, 0, 0, 0)" || bg === "transparent") return "";' +
        '    return bg;' +
        '  };' +
        '  var bg = "";' +
        '  bg = pick(document.body) || pick(document.documentElement);' +
        '  if (!bg) {' +
        '    var top = document.elementFromPoint(window.innerWidth / 2, 2);' +
        '    bg = pick(top);' +
        '  }' +
        '  if (!bg) bg = "rgb(255,255,255)";' +
        '  return bg;' +
        '})()';
      this.webController.runJavaScript(script, (err: Error, result: string) => {
        if (err || !result) {
          return;
        }
        const c = StatusBarUtil.rgbToHex(result);
        if (c.length > 0) {
          const textColor: string = StatusBarUtil.textColorForBg(c);
          StatusBarUtil.setStatusBarColor('#00000000', textColor);
        }
      });
    } catch (e) {
    }
  }

  private injectSafePadding(): void {
    try {
      const topPx: number = this.statusBarHeight + 8 + FLOATING_BTN_SIZE + 8;
      const script: string =
        '(function(){' +
        '  var s = document.createElement("style");' +
        '  s.textContent = "body{padding-top:' + topPx.toString() + 'px !important;}";' +
        '  document.head.appendChild(s);' +
        '})()';
      this.webController.runJavaScript(script);
    } catch (e) {
    }
  }

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.TopStart }) {
        BackgroundLayer()

        Web({ src: '', controller: this.webController })
          .width('100%')
          .height('100%')
          .javaScriptAccess(true)
          .domStorageAccess(true)
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
          .onLoadIntercept((event) => {
            let url: string = '';
            try {
              url = event.data.getRequestUrl();
            } catch (e) {
            }
            return this.interceptExternalScheme(url);
          })
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
            try {
              this.currentUrl = this.webController.getUrl();
            } catch (e) {
            }
            this.updateStatusBarFromPage();
            this.injectSafePadding();
          })
          .onTitleReceive((event) => {
            if (event.title.length > 0) {
              this.title = event.title;
            }
          })
          .onScroll(() => {
            if (this.scrollTimer >= 0) {
              clearTimeout(this.scrollTimer);
            }
            this.scrollTimer = setTimeout(() => {
              this.updateStatusBarFromPage();
              this.scrollTimer = -1;
            }, 50);
          })
          .onErrorReceive(() => {
            this.isLoading = false;
            this.loadError = '页面加载失败';
          })

        Row() {
          Stack({ alignContent: Alignment.Center }) {
            SymbolGlyph($r('sys.symbol.chevron_backward'))
              .fontSize(18)
              .fontColor(['#FFFFFF'])
              .fontWeight(FontWeight.Medium)
              .renderingStrategy(SymbolRenderingStrategy.SINGLE)
          }
          .width(FLOATING_BTN_SIZE)
          .height(FLOATING_BTN_SIZE)
          .borderRadius(FLOATING_BTN_SIZE / 2)
          .backgroundColor('#66000000')
          .backdropBlur(20)
          .onClick(() => { this.goBack(); })

          Blank()
        }
        .width('100%')
        .padding({
          left: FLOATING_BTN_MARGIN,
          right: FLOATING_BTN_MARGIN,
          top: this.statusBarHeight + 8
        })
        .height(FLOATING_BTN_SIZE)
        .zIndex(10)

        if (this.isLoading && this.url.length > 0) {
          Column() {
            LoadingProgress().width(36).height(36).color('#2979FF')
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .backgroundColor('#33000000')
          .zIndex(5)
        }

        if (this.loadError.length > 0) {
          Column() {
            Text(this.loadError).fontSize(13).fontColor('#C62828').padding(12)
            Text('重试')
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .fontColor('#2979FF')
              .padding({ left: 20, right: 20, top: 8, bottom: 8 })
              .borderRadius(16)
              .backgroundColor('#FFFFFF')
              .margin({ top: 12 })
              .onClick(() => { this.loadH5(); })
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .zIndex(6)
        }
      }
      .width('100%').height('100%')
      .backgroundColor(BackgroundManager.pageBackgroundColor(this.themeIsDark))
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    }
    .hideTitleBar(true)
    .backgroundColor(BackgroundManager.pageBackgroundColor(this.themeIsDark))
    .onBackPressed(() => {
      this.goBack();
      return true;
    })
  }
}
