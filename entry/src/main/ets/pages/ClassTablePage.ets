import web_webview from '@ohos.web.webview';
import { BusinessError } from '@kit.BasicServicesKit';
import { ThemeColors } from '../utils/ThemeColors';
import { SqgService } from '../services/SqgService';
import StatusBarUtil from '../utils/StatusBarUtil';

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
      this.url = h5;
    } catch (e) {
      this.loadError = '获取课表地址失败：' + String(e);
      this.url = '';
    } finally {
      this.isLoading = false;
    }
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
          Web({ src: this.url, controller: this.webController })
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
        } else if (this.loadError.length > 0) {
          Column() {
            Text('加载失败：' + this.loadError).fontSize(14).fontColor('#C62828')
              .textAlign(TextAlign.Center).padding(20)
            Button('重试').fontSize(14).margin({ top: 16 })
              .onClick(() => { this.loadH5(); })
          }
          .width('100%').height('100%').justifyContent(FlexAlign.Center)
        }

        if (this.isLoading && this.url.length > 0) {
          LoadingProgress().width(36).height(36).color('#2979FF')
        }
      }
      .width('100%').height('100%')
    }
    .title('课表')
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
