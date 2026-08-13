import { scanCore, scanBarcode } from '@kit.ScanKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { uiMaterial } from '@kit.ArkUI';
import { ThemeColors } from '../../utils/ThemeColors';
import { PreferenceUtil } from '../../utils/PreferenceUtil';
import { SqgService } from '../../services/SqgService';
import { WebPageParam } from '../NavParams';

const TAG = 'HomeTab';

class ServiceItem {
  name: string = '';
  iconUrl: string = '';
  url: string = '';
  tokenAccept: string = '';
}

class QuickItem {
  name: string = '';
  icon: Resource = $r('app.media.ic_public_more');
  color: string = '';
  pure: boolean = false;
  serverIconUrl: string = '';
}

const QUICK_ITEMS_ROW1: QuickItem[] = [
  { name: '扫一扫', icon: $r('app.media.ic_public_scan_filled'), color: '#2979FF', pure: true, serverIconUrl: '' },
  { name: '日程', icon: $r('app.media.ic_public_calendar'), color: '#FF7043', pure: true, serverIconUrl: '' },
  { name: '缴电费', icon: $r('app.media.ic_bolt'), color: '#FFB300', pure: false, serverIconUrl: '' },
  { name: '校园卡', icon: $r('app.media.ic_card'), color: '#26A69A', pure: false, serverIconUrl: '' }
];

const QUICK_ITEMS_ROW2: QuickItem[] = [
  { name: '影吧预约', icon: $r('app.media.ic_movie'), color: '#7E57C2', pure: false, serverIconUrl: '' },
  { name: '学生课表查询', icon: $r('app.media.ic_book'), color: '#EC407A', pure: false, serverIconUrl: '' },
  { name: '日常劳动上报', icon: $r('app.media.ic_broom'), color: '#29B6F6', pure: false, serverIconUrl: '' },
  { name: '人脸采集', icon: $r('app.media.ic_face'), color: '#8D6E63', pure: false, serverIconUrl: '' }
];

@Component
export struct HomeTab {
  @Consume('pageStack') pageStack: NavPathStack;
  @State username: string = '';
  @State userInfoText: string = '';
  @State services: ServiceItem[] = [];
  @State loading: boolean = false;
  @State loadError: string = '';
  @State isSearching: boolean = false;
  @State searchText: string = '';
  @State searchResults: ServiceItem[] = [];
  private searchInputController: TextInputController = new TextInputController();
  @StorageProp('statusBarHeight') statusBarHeight: number = 0;
  @StorageLink('theme_is_dark') themeIsDark: boolean = false;

  aboutToAppear(): void {
    this.username = PreferenceUtil.getString('ids_account');
    this.loadHome();
  }

  private flattenServices(raw: object[] | null, out: ServiceItem[]): void {
    if (raw === null || raw === undefined) {
      return;
    }
    for (let i = 0; i < raw.length; i++) {
      const obj: Record<string, Object> = raw[i] as Record<string, Object>;
      const servicesRaw: Object | undefined = obj['services'];
      if (servicesRaw !== undefined) {
        const services: Object[] = servicesRaw as Object[];
        this.flattenServices(services, out);
        continue;
      }
      const item: ServiceItem = new ServiceItem();
      const name: Object | undefined = obj['serviceName'] ?? obj['name'];
      const iconUrl: Object | undefined = obj['iconUrl'] ?? obj['imgUrl'];
      const url: Object | undefined = obj['serviceUrl'] ?? obj['url'];
      const tokenAccept: Object | undefined = obj['tokenAccept'];
      item.name = name === undefined ? '' : String(name);
      item.iconUrl = iconUrl === undefined ? '' : String(iconUrl);
      item.url = url === undefined ? '' : String(url);
      item.tokenAccept = tokenAccept === undefined ? '' : String(tokenAccept);
      if (item.name.length > 0) {
        out.push(item);
      }
    }
  }

  private async loadHome(): Promise<void> {
    this.loading = true;
    this.loadError = '';
    try {
      const svc = SqgService.getInstance();
      let name: string = '';
      try {
        name = svc.getAccountName();
      } catch (_e) {
      }
      if (name.length === 0) {
        name = PreferenceUtil.getString('mine_name_cached');
      }
      if (name.length > 0) {
        this.userInfoText = '你好，' + name;
      } else {
        try {
          const info = await svc.getUserInfo() as Record<string, Object> | null;
          if (info !== null && info !== undefined) {
            const attrs: Object | undefined = info['attributes'];
            const src: Record<string, Object> = (attrs !== undefined && attrs !== null) ?
              (attrs as Record<string, Object>) : info;
            const nameObj: Object | undefined = src['name'] ?? src['userName'] ?? src['realName'];
            const resolved: string = nameObj !== undefined ? String(nameObj) : this.username;
            this.userInfoText = '你好，' + resolved;
          } else {
            this.userInfoText = '你好，' + this.username;
          }
        } catch (_e) {
          this.userInfoText = '你好，' + this.username;
        }
      }
      try {
        const list = await svc.getServiceList();
        const items: ServiceItem[] = [];
        this.flattenServices(list, items);
        this.services = items;
        this.fillQuickServerIcons();
      } catch (e) {
        this.loadError = String(e);
      }
    } catch (e) {
      this.loadError = String(e);
    } finally {
      this.loading = false;
    }
  }

  private findService(name: string): ServiceItem | undefined {
    for (let i = 0; i < this.services.length; i++) {
      if (this.services[i].name === name) {
        return this.services[i];
      }
    }
    return undefined;
  }

  private fillQuickServerIcons(): void {
    for (let r = 0; r < QUICK_ITEMS_ROW1.length; r++) {
      const svc = this.findService(QUICK_ITEMS_ROW1[r].name);
      if (svc !== undefined) {
        QUICK_ITEMS_ROW1[r].serverIconUrl = svc.iconUrl;
      }
    }
    for (let r = 0; r < QUICK_ITEMS_ROW2.length; r++) {
      const svc = this.findService(QUICK_ITEMS_ROW2[r].name);
      if (svc !== undefined) {
        QUICK_ITEMS_ROW2[r].serverIconUrl = svc.iconUrl;
      }
    }
  }

  private openSearch(): void {
    this.isSearching = true;
    setTimeout(() => {
      try {
        this.searchInputController.caretPosition(this.searchText.length);
      } catch (e) {
      }
    }, 100);
  }

  private onSearchChange(value: string): void {
    this.searchText = value;
    const kw: string = value.trim();
    this.searchResults = [];
    if (kw.length === 0) {
      return;
    }
    const low: string = kw.toLowerCase();
    for (let i = 0; i < this.services.length; i++) {
      const it: ServiceItem = this.services[i];
      if (it.name.toLowerCase().indexOf(low) >= 0 || it.url.toLowerCase().indexOf(low) >= 0) {
        this.searchResults.push(it);
      }
    }
  }

  private closeSearch(): void {
    this.isSearching = false;
    this.searchText = '';
    this.searchResults = [];
  }

  private openQuick(item: QuickItem): void {
    if (item.name === '扫一扫') {
      this.startScan();
      return;
    }
    const svc = this.findService(item.name);
    if (svc !== undefined) {
      this.openService(svc);
      return;
    }
    this.pageStack.pushPathByName('ServiceWebPage', new WebPageParam(item.name, 'https://i.sqgxy.edu.cn/h5/'));
  }

  private startScan(): void {
    try {
      const options: scanBarcode.ScanOptions = {
        scanTypes: [scanCore.ScanType.ALL],
        enableMultiMode: true,
        enableAlbum: true
      };
      scanBarcode.startScanForResult(getContext(this), options).then((result: scanBarcode.ScanResult) => {
        const value: string = result.originalValue;
        if (value.length === 0) {
          return;
        }
        this.getUIContext().getPromptAction().showToast({
          duration: 2000,
          message: '扫码结果：' + value
        });
      }).catch((err: BusinessError) => {
        this.getUIContext().getPromptAction().showToast({
          duration: 2000,
          message: '扫码失败：' + err.message
        });
      });
    } catch (e) {
      this.getUIContext().getPromptAction().showToast({
        duration: 2000,
        message: '扫码不可用'
      });
    }
  }

  onMoreClick: () => void = () => { };
  onSearchClick: () => void = () => { };
  onBellClick: () => void = () => { };

  private openService(item: ServiceItem): void {
    let target: string = item.url;
    if (target.length === 0) {
      return;
    }
    if (target.startsWith('/')) {
      target = 'https://i.sqgxy.edu.cn' + target;
    }
    const finalUrl: string = SqgService.getInstance().buildServiceUrl(target, item.tokenAccept);
    this.pageStack.pushPathByName('ServiceWebPage', new WebPageParam(item.name, finalUrl));
  }

  private openClassTable(): void {
    this.pageStack.pushPathByName('ClassTablePage', undefined);
  }

  @Builder
  BlueHeader() {
    Column() {
      Row() {
        Row() {
          Image($r('app.media.ic_search'))
            .width(16).height(16).fillColor('#90A4AE').objectFit(ImageFit.Contain)
          if (this.isSearching) {
            TextInput({ text: this.searchText, placeholder: '搜索服务', controller: this.searchInputController })
              .fontSize(14)
              .fontColor(ThemeColors.textPrimary)
              .placeholderColor('#90A4AE')
              .backgroundColor(Color.Transparent)
              .layoutWeight(1)
              .margin({ left: 8 })
              .onChange((v: string) => { this.onSearchChange(v); })
            if (this.searchText.length > 0) {
              Image($r('app.media.ic_public_close'))
                .width(16).height(16).fillColor('#90A4AE').objectFit(ImageFit.Contain)
                .onClick(() => { this.closeSearch(); })
            }
          } else {
            Text('搜索服务、待办、资讯').fontSize(14).fontColor('#90A4AE').margin({ left: 8 })
          }
          Blank()
        }
        .layoutWeight(1).height(40)
        .borderRadius(20)
        .padding({ left: 16, right: 16 })
        .systemMaterial(new uiMaterial.ImmersiveMaterial({
          style: uiMaterial.ImmersiveStyle.THIN,
          interactive: true,
          lightEffect: { color: undefined }
        }))
        .onClick(() => { this.openSearch(); })

        Image($r('app.media.ic_notify'))
          .width(22).height(22).fillColor(this.themeIsDark ? '#FFFFFF' : '#1A1A1A')
          .margin({ left: 12, right: 12 })
          .onClick(() => { this.onBellClick(); })
      }
      .width('100%').padding({ left: 16, right: 16, top: this.statusBarHeight + 56, bottom: 12 })
    }
    .width('100%')
    .backgroundColor(Color.Transparent)
  }

  @Builder
  QuickIcon(item: QuickItem, iconColor: string) {
    if (item.pure) {
      Image(item.icon)
        .width(28).height(28)
        .fillColor(this.themeIsDark ? '#FFFFFF' : '#1A1A1A')
        .objectFit(ImageFit.Contain)
    } else if (item.serverIconUrl.length > 0) {
      Image(item.serverIconUrl).width(30).height(30).objectFit(ImageFit.Contain)
    } else {
      Image(item.icon)
        .width(28).height(28)
        .fillColor(iconColor)
        .objectFit(ImageFit.Contain)
    }
  }

  @Builder
  QuickRow() {
    Column() {
      Row() {
        ForEach(QUICK_ITEMS_ROW1, (item: QuickItem, index: number) => {
          Column() {
            this.QuickIcon(item, item.color)
            Text(item.name).fontSize(11).fontColor(ThemeColors.textPrimary).margin({ top: 6 })
          }
          .layoutWeight(1)
          .padding({ top: 12, bottom: 12 })
          .alignItems(HorizontalAlign.Center)
          .onClick(() => { this.openQuick(item); })
        }, (item: QuickItem, index: number) => String(index))
      }
      .width('100%')

      Row() {
        ForEach(QUICK_ITEMS_ROW2, (item: QuickItem, index: number) => {
          Column() {
            this.QuickIcon(item, item.color)
            Text(item.name).fontSize(11).fontColor(ThemeColors.textPrimary).margin({ top: 6 })
          }
          .layoutWeight(1)
          .padding({ top: 8, bottom: 12 })
          .alignItems(HorizontalAlign.Center)
          .onClick(() => { this.openQuick(item); })
        }, (item: QuickItem, index: number) => String(index))

        Column() {
          this.QuickIcon(new QuickItem(), ThemeColors.textSecondary)
          Text('更多').fontSize(11).fontColor(ThemeColors.textPrimary).margin({ top: 6 })
        }
        .layoutWeight(1)
        .padding({ top: 8, bottom: 12 })
        .alignItems(HorizontalAlign.Center)
        .onClick(() => { this.onMoreClick(); })
      }
      .width('100%')
    }
    .width('100%')
    .backgroundColor(ThemeColors.bgCard)
    .borderRadius(16)
    .shadow({ radius: 8, color: '#14000000', offsetY: 2 })
    .margin({ left: 12, right: 12, top: 12 })
  }

  build() {
    Column() {
      if (this.loading && this.services.length === 0) {
        Column() {
          LoadingProgress().width(40).height(40).color('#2979FF')
          Text('加载中...').fontSize(14).fontColor(ThemeColors.textSecondary).margin({ top: 12 })
        }
        .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else if (this.isSearching) {
        this.BlueHeader()
        Scroll() {
          Column() {
            if (this.searchResults.length === 0) {
              Text(this.searchText.length > 0 ? '未找到相关服务' : '输入关键词搜索服务')
                .fontSize(14).fontColor(ThemeColors.textSecondary).margin({ top: 40 })
                .width('100%').textAlign(TextAlign.Center)
            } else {
              ForEach(this.searchResults, (item: ServiceItem, index: number) => {
                this.SearchResultRow(item, index)
              }, (item: ServiceItem, index: number) => 'hsr_' + index + '_' + item.name)
            }
          }
          .width('100%').padding({ bottom: 20 })
        }
        .width('100%').layoutWeight(1)
        .backgroundColor(ThemeColors.bgPage)
      } else {
        this.BlueHeader()
        Scroll() {
          Column() {
            this.QuickRow()
          }
          .width('100%')
        }
        .width('100%').layoutWeight(1)
        .scrollBar(BarState.Off)
        .backgroundColor(ThemeColors.bgPage)
      }
    }
    .width('100%').height('100%')
  }

  @Builder
  SearchResultRow(item: ServiceItem, index: number) {
    Row() {
      if (item.iconUrl.length > 0) {
        Image(item.iconUrl).width(40).height(40).objectFit(ImageFit.Contain)
      } else {
        Text(item.name.substring(0, Math.min(1, item.name.length)))
          .width(40).height(40).fontSize(18).fontColor('#FFFFFF').textAlign(TextAlign.Center)
          .backgroundColor('#2979FF').borderRadius(10)
      }
      Text(item.name).fontSize(15).fontColor(ThemeColors.textPrimary)
        .margin({ left: 12 }).layoutWeight(1).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
      Text('›').fontSize(18).fontColor(ThemeColors.textSecondary).margin({ left: 10, right: 16 })
    }
    .width('100%').height(56).alignItems(VerticalAlign.Center)
    .padding({ left: 12 })
    .backgroundColor(ThemeColors.bgCard)
    .margin({ top: 1 })
    .onClick(() => { this.openService(item); })
  }
}
