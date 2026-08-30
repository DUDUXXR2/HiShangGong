import web_webview from '@ohos.web.webview';
import { common } from '@kit.AbilityKit';
import { PreferenceUtil } from '../utils/PreferenceUtil';
import { HttpUtil } from '../utils/HttpUtil';
import { CAS_ARRY } from '../services/SqgConstants';
import { WebPageParam } from './NavParams';
import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import { SymbolGlyphModifier } from '@kit.ArkUI';

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
  }
}

@Component
export struct ServiceWebPage {
  @Consume('pageStack') pageStack: NavPathStack;
  @State title: string = '服务';
  @State url: string = '';
  @State isLoading: boolean = true;
  @State loadError: string = '';
  @State currentUrl: string = '';
  private webController: web_webview.WebviewController = new web_webview.WebviewController();
  private bridge: WebBridge = new WebBridge();

  aboutToAppear(): void {
    try {
      const list = this.pageStack.getParamByName('ServiceWebPage') as WebPageParam[];
      if (list !== undefined && list !== null && list.length > 0) {
        const p: WebPageParam = list[0];
        this.title = p.title.length > 0 ? p.title : '服务';
        this.url = p.url;
        this.currentUrl = p.url;
      }
    } catch (e) {
    }
    setTimeout(() => { this.loadWithAuth(); }, 50);
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

  private sharePage(): void {
    try {
      const shareData: systemShare.SharedData = new systemShare.SharedData({
        utd: utd.UniformDataType.HYPERLINK,
        content: this.currentUrl,
        title: this.title
      });
      const controller: systemShare.ShareController = new systemShare.ShareController(shareData);
      const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
      if (ctx) {
        controller.show(ctx, {
          selectionMode: systemShare.SelectionMode.SINGLE,
          previewMode: systemShare.SharePreviewMode.DEFAULT
        }).catch((err: BusinessError) => {
          console.error('ShareController show error: ' + err.message);
        });
      }
    } catch (e) {
      console.error('sharePage error: ' + String(e));
    }
  }

  build() {
    NavDestination() {
      Stack() {
        Web({ src: '', controller: this.webController })
          .width('100%')
          .height('100%')
          .javaScriptAccess(true)
          .domStorageAccess(true)
          .backgroundColor('#FFFFFF')
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
          })
          .onTitleReceive((event) => {
            if (event.title.length > 0) {
              this.title = event.title;
            }
          })
          .onErrorReceive(() => {
            this.isLoading = false;
            this.loadError = '页面加载失败';
          })

        if (this.isLoading) {
          Column() {
            LoadingProgress().width(36).height(36).color('#2979FF')
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .backgroundColor('#FFFFFF')
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
          .backgroundColor('#FFFFFF')
        }
      }
      .width('100%').height('100%')
    }
    .title(this.title)
    .backgroundColor('#FFFFFF')
    .menus([
      {
        value: '分享',
        symbolIcon: new SymbolGlyphModifier($r('sys.symbol.share')),
        action: () => { this.sharePage(); }
      }
    ])
    .onBackPressed(() => {
      this.goBack();
      return true;
    })
  }
}
