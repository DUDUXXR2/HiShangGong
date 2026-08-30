import web_webview from '@ohos.web.webview';
import { common } from '@kit.AbilityKit';
import { PreferenceUtil } from '../utils/PreferenceUtil';
import { HttpUtil } from '../utils/HttpUtil';
import { CAS_ARRY } from '../services/SqgConstants';
import { WebPageParam } from './NavParams';
import StatusBarUtil from '../utils/StatusBarUtil';
import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import { ImmersionButton } from '@tangs/components';
import { ActionButtonModifier } from '../components/ImmersionActionButton';
import { MaterialConfig } from '../utils/MaterialConfig';

const TITLE_BAR_HEIGHT: number = 44;
const SIDE_MARGIN: number = 16;
const BTN_SIZE: number = 32;

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
  @State title: string = '';
  @State url: string = '';
  @State isLoading: boolean = true;
  @State loadError: string = '';
  @State currentUrl: string = '';
  @StorageProp('statusBarHeight') statusBarHeight: number = 0;
  private webController: web_webview.WebviewController = new web_webview.WebviewController();
  private bridge: WebBridge = new WebBridge();

  aboutToAppear(): void {
    StatusBarUtil.setStatusBarColor('#00000000', '#000000');
    try {
      const list = this.pageStack.getParamByName('ServiceWebPage') as WebPageParam[];
      if (list !== undefined && list !== null && list.length > 0) {
        const p: WebPageParam = list[0];
        this.title = p.title.length > 0 ? p.title : '';
        this.url = p.url;
        this.currentUrl = p.url;
      }
    } catch (e) {
    }
    setTimeout(() => { this.loadWithAuth(); }, 50);
  }

  aboutToDisappear(): void {
    StatusBarUtil.resetStatusBar();
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
      Column() {
        Row() {
          Stack() {
            ImmersionButton({
              systemMaterialEffect: MaterialConfig.systemMaterialEffectParams(),
              buttonModify: new ActionButtonModifier(BTN_SIZE, BTN_SIZE, Color.Transparent, '#80000000'),
              click: (): void => { this.goBack(); }
            }) {
              SymbolGlyph($r('sys.symbol.chevron_backward'))
                .fontSize(16)
                .fontColor(['#000000'])
                .fontWeight(FontWeight.Medium)
                .renderingStrategy(SymbolRenderingStrategy.SINGLE)
            }
          }
          .width(BTN_SIZE)
          .height(BTN_SIZE)

          Text('返回')
            .fontSize(13)
            .fontColor('#000000')
            .fontWeight(FontWeight.Normal)
            .margin({ left: 4 })
            .onClick(() => { this.goBack(); })

          Text(this.title)
            .fontSize(15)
            .fontWeight(FontWeight.Normal)
            .fontColor('#000000')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
            .textAlign(TextAlign.Center)

          Stack() {
            ImmersionButton({
              systemMaterialEffect: MaterialConfig.systemMaterialEffectParams(),
              buttonModify: new ActionButtonModifier(BTN_SIZE, BTN_SIZE, Color.Transparent, '#80000000'),
              click: (): void => { this.sharePage(); }
            }) {
              SymbolGlyph($r('sys.symbol.share'))
                .fontSize(14)
                .fontColor(['#000000'])
                .fontWeight(FontWeight.Medium)
                .renderingStrategy(SymbolRenderingStrategy.SINGLE)
            }
          }
          .width(BTN_SIZE)
          .height(BTN_SIZE)
        }
        .width('100%')
        .height(TITLE_BAR_HEIGHT)
        .padding({ left: SIDE_MARGIN, right: SIDE_MARGIN })
        .alignItems(VerticalAlign.Center)

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
        .layoutWeight(1)
      }
      .width('100%')
      .padding({ top: this.statusBarHeight })
    }
    .hideTitleBar(true)
    .backgroundColor('#FFFFFF')
    .onBackPressed(() => {
      this.goBack();
      return true;
    })
  }
}
