import web_webview from '@ohos.web.webview';
import { common } from '@kit.AbilityKit';
import { HdsNavigation, HdsNavigationTitleMode, ScrollEffectType, BlurStrategy, hdsMaterial } from '@kit.UIDesignKit';
import { SqgService } from '../services/SqgService';
import { CAS_ARRY } from '../services/SqgConstants';
import { HttpUtil } from '../utils/HttpUtil';
import { PreferenceUtil } from '../utils/PreferenceUtil';
import StatusBarUtil from '../utils/StatusBarUtil';
import { ThemeColors } from '../utils/ThemeColors';
import { ImmersionButton } from '@tangs/components';
import { ActionButtonModifier } from '../components/ImmersionActionButton';
import { MaterialConfig } from '../utils/MaterialConfig';

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

export class ClassTableBridge {
  updateStatusBar(barColor: string, textColor: string): void {
    StatusBarUtil.setStatusBarColor(barColor, textColor);
  }
}

@Component
export struct ClassTablePage {
  @Consume('pageStack') pageStack: NavPathStack;
  @State url: string = '';
  @State isLoading: boolean = true;
  @State loadError: string = '';
  @StorageProp('statusBarHeight') statusBarHeight: number = 0;
  private webController: web_webview.WebviewController = new web_webview.WebviewController();
  private bridge: ClassTableBridge = new ClassTableBridge();
  private scrollTimer: number = -1;

  aboutToAppear(): void {
    StatusBarUtil.resetStatusBar();
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
      // 追加 idToken 参数（命中 i.sqgxy.edu.cn 白名单时），与 ServiceWebPage 保持一致
      this.url = SqgService.getInstance().buildServiceUrl(h5, '');
      // 延迟到 Web 组件挂载后再 loadUrl（控制器未就绪时调用会抛错）
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

  build() {
    NavDestination() {
      Stack() {
        HdsNavigation() {
          Column() {
            // 内容从标题栏下方开始（Web 是原生渲染，padding 不会下移网页内容，必须用布局占位）
            Blank()
              .width('100%')
              .height(this.statusBarHeight + HOME_TITLE_HEIGHT + PAGE_CARD_GAP)
            if (this.url.length > 0) {
              Web({ src: '', controller: this.webController })
                .width('100%')
                .layoutWeight(1)
                .javaScriptAccess(true)
                .domStorageAccess(true)
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
            } else if (this.loadError.length > 0) {
              Column() {
                Text('加载失败：' + this.loadError).fontSize(14).fontColor('#C62828')
                  .textAlign(TextAlign.Center).padding(20)
                Stack({ alignContent: Alignment.Center }) {
                  ImmersionButton({
                    systemMaterialEffect: {
                      materialType: MaterialConfig.configuredMaterialType(),
                      materialLevel: MaterialConfig.configuredMaterialLevel()
                  },
                  buttonModify: new ActionButtonModifier(80, 36, ThemeColors.bgInput, ThemeColors.border),
                  click: (): void => { this.loadH5(); }
                }) {
                  Text('重试')
                    .fontSize(14)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(ThemeColors.textPrimary)
                }
              }
              .width(80)
              .height(36)
              .borderRadius(18)
              .clip(false)
              .margin({ top: 16 })
            }
            .width('100%')
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)
          }
          }
        }
        .mode(NavigationMode.Stack)
        .titleBar({
          content: {
            title: { mainTitle: '课表' },
            backIcon: { action: (): void => { this.goBack(); } }
          },
          style: {
            scrollEffectOpts: {
              enableScrollEffect: false,
              scrollEffectType: ScrollEffectType.GRADIENT_BLUR
            },
            blurStrategy: BlurStrategy.DISABLE,
            originalStyle: { backgroundStyle: { backgroundColor: $r('app.color.page_secondary_bg') } },
            scrollEffectStyle: { backgroundStyle: { backgroundColor: $r('app.color.page_secondary_bg') } },
            systemMaterialEffect: {
              materialType: hdsMaterial.MaterialType.NONE,
              materialLevel: MaterialConfig.configuredMaterialLevel()
            }
          },
          avoidLayoutSafeArea: true,
          enableComponentSafeArea: false
        })
        .hideBackButton(false)
        .titleMode(HdsNavigationTitleMode.MINI)
        .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP])
        .width('100%').height('100%')

        if (this.isLoading && this.url.length > 0) {
          LoadingProgress().width(36).height(36).color('#2979FF')
        }
      }
      .width('100%').height('100%')
      .backgroundColor($r('app.color.page_secondary_bg'))
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    }
    .hideTitleBar(true)
    .backgroundColor($r('app.color.page_secondary_bg'))
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
          const textColor: string = StatusBarUtil.textColorForBg(c);
          StatusBarUtil.setStatusBarColor(c, textColor);
        }
      });
    } catch (e) {
    }
  }
}
