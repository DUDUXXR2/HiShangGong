import web_webview from '@ohos.web.webview';
import { common } from '@kit.AbilityKit';
import { CAS_ARRY } from '../services/SqgConstants';
import { HttpUtil } from '../utils/HttpUtil';
import { PreferenceUtil } from '../utils/PreferenceUtil';
import { WebPageParam } from './NavParams';
import StatusBarUtil from '../utils/StatusBarUtil';
import { BackgroundManager, BackgroundLayer } from '../utils/BackgroundManager';
import { ImmersionButton } from '@tangs/components';
import { ActionButtonModifier } from '../components/ImmersionActionButton';
import { MaterialConfig } from '../utils/MaterialConfig';

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

export class JwBridge {
  updateStatusBar(barColor: string, textColor: string): void {
    StatusBarUtil.setStatusBarColor(barColor, textColor);
  }
}

@Component
export struct JwWebPage {
  @Consume('pageStack') pageStack: NavPathStack;
  @State title: string = '教务';
  @State url: string = '';
  @State isLoading: boolean = true;
  @State loadError: string = '';
  @State currentUrl: string = '';
  @StorageProp('statusBarHeight') statusBarHeight: number = 0;
  @StorageLink('theme_is_dark') themeIsDark: boolean = false;
  private webController: web_webview.WebviewController = new web_webview.WebviewController();
  private bridge: JwBridge = new JwBridge();
  private scrollTimer: number = -1;

  aboutToAppear(): void {
    try {
      const list = this.pageStack.getParamByName('JwWebPage') as WebPageParam[];
      if (list !== undefined && list !== null && list.length > 0) {
        const p: WebPageParam = list[0];
        this.title = p.title.length > 0 ? p.title : '教务';
        this.url = p.url;
        this.currentUrl = p.url;
      }
    } catch (e) {
    }
    StatusBarUtil.setStatusBarColor('#00000000', '#FFFFFF');
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
          web_webview.WebCookieManager.configCookieSync('https://' + domain, cookies + '; Path=/', false, true);
          web_webview.WebCookieManager.saveCookieAsync();
        }
        if (isTrustedDomain && token.length > 0) {
          web_webview.WebCookieManager.configCookieSync('https://' + domain, 'X-Id-Token=' + token + '; Path=/', false, true);
          web_webview.WebCookieManager.saveCookieAsync();
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
            try {
              const domain: string = this.hostOf(this.currentUrl.length > 0 ? this.currentUrl : this.url);
              if (domain.length > 0) {
                const cookies: string = HttpUtil.getInstance().getCookiesForDomain(domain);
                if (cookies.length > 0) {
                  web_webview.WebCookieManager.configCookieSync('https://' + domain, cookies + '; Path=/', false, true);
                }
                const token: string = PreferenceUtil.getString('id_token');
                const isTrusted: boolean = this.isInCasArry(this.currentUrl.length > 0 ? this.currentUrl : this.url);
                if (isTrusted && token.length > 0) {
                  web_webview.WebCookieManager.configCookieSync('https://' + domain, 'X-Id-Token=' + token + '; Path=/', false, true);
                }
                web_webview.WebCookieManager.saveCookieAsync();
              }
            } catch (e) {
            }
          })
          .onPageEnd(() => {
            this.isLoading = false;
            try {
              this.currentUrl = this.webController.getUrl();
            } catch (e) {
            }
            this.updateStatusBarFromPage();
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
          Stack() {
            ImmersionButton({
              systemMaterialEffect: MaterialConfig.systemMaterialEffectParams(),
              buttonModify: new ActionButtonModifier(FLOATING_BTN_SIZE, FLOATING_BTN_SIZE, Color.Transparent, '#80FFFFFF'),
              click: (): void => { this.goBack(); }
            }) {
              SymbolGlyph($r('sys.symbol.chevron_backward'))
                .fontSize(18)
                .fontColor(['#FFFFFF'])
                .fontWeight(FontWeight.Medium)
                .renderingStrategy(SymbolRenderingStrategy.SINGLE)
            }
          }
          .width(FLOATING_BTN_SIZE)
          .height(FLOATING_BTN_SIZE)

          Row().hitTestBehavior(HitTestMode.Transparent).layoutWeight(1).height(1)
        }
        .width('100%')
        .padding({
          left: FLOATING_BTN_MARGIN,
          right: FLOATING_BTN_MARGIN,
          top: this.statusBarHeight + 8
        })
        .zIndex(10)

        if (this.isLoading) {
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
              .onClick(() => { this.loadWithAuth(); })
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
