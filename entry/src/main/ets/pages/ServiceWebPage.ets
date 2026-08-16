import web_webview from '@ohos.web.webview';
import { common } from '@kit.AbilityKit';
import { systemShare } from '@kit.ShareKit';
import { ThemeColors } from '../utils/ThemeColors';
import { PreferenceUtil } from '../utils/PreferenceUtil';
import { HttpUtil } from '../utils/HttpUtil';
import { CAS_ARRY } from '../services/SqgConstants';
import { WebPageParam } from './NavParams';
import StatusBarUtil from '../utils/StatusBarUtil';
import { ImmersionButton } from '@tangs/components';
import { ActionButtonModifier } from '../components/ImmersionActionButton';
import { MaterialConfig } from '../utils/MaterialConfig';
import { BackgroundManager } from '../utils/BackgroundManager';

const HOME_TITLE_HEIGHT: number = 56;
const PAGE_CARD_GAP: number = 10;

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
  @StorageProp('statusBarHeight') statusBarHeight: number = 0;
  @StorageLink('theme_is_dark') themeIsDark: boolean = false;
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

  // 影吧预约保留原模糊沉浸标题栏；其余功能页改为纯白/纯黑（跟随系统）
  private isMovieBar(): boolean {
    return this.title === '影吧预约' || this.title.indexOf('影吧') >= 0;
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

  // 拦截 Web 里非 http(s) 的自定义 scheme（支付宝/微信支付唤起），转交系统打开外部 App
  // 否则 Web 组件会把 alipays:// 当普通 URL 加载失败
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

  // 右上角分享：调用系统分享面板，分享当前网页链接
  private async shareCurrentPage(): Promise<void> {
    const target: string = this.url;
    if (target.length === 0) {
      return;
    }
    try {
      const record: systemShare.SharedRecord = {
        utd: 'general.url',
        content: target,
        title: this.title
      };
      const data: systemShare.SharedData = new systemShare.SharedData(record);
      const controller = new systemShare.ShareController(data);
      const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
      if (ctx) {
        await controller.show(ctx, {});
      }
    } catch (e) {
      // 用户取消或系统分享失败时忽略
    }
  }

  build() {
    NavDestination() {
      Stack() {
        // Web 全屏沉浸（底层，内容延伸到状态栏下方）
        if (this.url.length > 0) {
          Web({ src: "", controller: this.webController })
            .width("100%").height("100%")
            .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
            .javaScriptAccess(true)
            .domStorageAccess(true)
            .onLoadIntercept((event) => {
              let url: string = "";
              try {
                url = event.data.getRequestUrl();
              } catch (e) {
              }
              return this.interceptExternalScheme(url);
            })
            .javaScriptProxy({
              object: this.bridge,
              methodList: ["updateStatusBar"],
              name: "etsBridge",
              controller: this.webController
            })
            .onPageBegin(() => {
              this.isLoading = true;
            })
            .onPageEnd(() => {
              this.isLoading = false;
              this.pullTopColor();
            })
            .onTitleReceive((event) => {
              try {
                const t: string = event.title;
                if (t.length > 0) {
                  this.title = t;
                }
              } catch (e) {
              }
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
              this.loadError = "页面加载失败";
            })
        } else {
          Column() {
            Text("未提供网页地址").fontSize(14).fontColor(ThemeColors.textSecondary)
          }
          .width("100%").height("100%")
          .justifyContent(FlexAlign.Center)
        }

        // 悬浮按钮栏（顶层，避开状态栏，沉浸光感）
        Row() {
          Stack({ alignContent: Alignment.Center }) {
            Image($r("app.media.ic_public_arrow_left"))
              .width(18).height(18)
              .fillColor("#FFFFFF")
              .objectFit(ImageFit.Contain)
          }
          .width(40).height(40)
          .borderRadius(20)
          .backgroundColor("#66000000")
          .backdropBlur(12)
          .onClick(() => { this.goBack(); })

          Blank()

          Stack({ alignContent: Alignment.Center }) {
            Image($r("app.media.ic_public_share"))
              .width(18).height(18)
              .fillColor("#FFFFFF")
              .objectFit(ImageFit.Contain)
          }
          .width(40).height(40)
          .borderRadius(20)
          .backgroundColor("#66000000")
          .backdropBlur(12)
          .onClick(() => { this.shareCurrentPage(); })
        }
        .width("100%")
        .padding({ top: this.statusBarHeight + 8, left: 12, right: 12 })
        .position({ x: 0, y: 0 })
        .zIndex(20)

        if (this.isLoading) {
          LoadingProgress().width(36).height(36).color("#2979FF")
        }

        if (this.loadError.length > 0) {
          Column() {
            Text(this.loadError).fontSize(13).fontColor("#C62828").padding(12)
            Stack({ alignContent: Alignment.Center }) {
              ImmersionButton({
                systemMaterialEffect: {
                  materialType: MaterialConfig.configuredMaterialType(),
                  materialLevel: MaterialConfig.configuredMaterialLevel()
                },
                buttonModify: new ActionButtonModifier(80, 36, ThemeColors.bgInput, ThemeColors.border),
                click: (): void => { this.loadWithAuth(); }
              }) {
                Text("重试")
                  .fontSize(13)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(ThemeColors.textPrimary)
              }
            }
            .width(80)
            .height(36)
            .borderRadius(18)
            .clip(false)
          }
          .width("100%")
        }
      }
      .width("100%").height("100%")
      .backgroundColor(this.isMovieBar() ? Color.Transparent : $r("app.color.page_secondary_bg"))
    }
    .hideTitleBar(true)
    .backgroundColor(this.isMovieBar()
      ? BackgroundManager.pageBackgroundColor(this.themeIsDark)
      : $r("app.color.page_secondary_bg"))
    .onBackPressed(() => {
      this.goBack();
      return true;
    })
  }

  private pullTopColor(): void {
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
          // 状态栏透明（网页内容透出，取页面顶端色彩）+ 按顶端亮度自适应文字颜色
          const textColor: string = StatusBarUtil.textColorForBg(c);
          StatusBarUtil.setStatusBarColor('#00000000', textColor);
        }
      });
    } catch (e) {
    }
  }
}
