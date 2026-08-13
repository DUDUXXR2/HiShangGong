import { uiMaterial } from '@kit.ArkUI';
import { ThemeColors } from '../../utils/ThemeColors';
import { SqgService } from '../../services/SqgService';
import { WebPageParam } from '../NavParams';

const TAG = 'ServiceTab';

class ServiceItem {
  name: string = '';
  iconUrl: string = '';
  url: string = '';
  tokenAccept: string = '';
  recommend: boolean = false;
}

class ServiceGroup {
  label: string = '';
  services: ServiceItem[] = [];
}

class LocalIcon {
  icon: Resource = $r('app.media.ic_public_more');
  colored: boolean = false;

  constructor(icon: Resource, colored: boolean) {
    this.icon = icon;
    this.colored = colored;
  }
}

@Component
export struct ServiceTab {
  @Consume('pageStack') pageStack: NavPathStack;
  @State groups: ServiceGroup[] = [];
  @State loading: boolean = true;
  @State loadError: string = '';
  @State activeTab: number = 0;
  @State searchText: string = '';
  @State searchResults: ServiceItem[] = [];
  @State isSearching: boolean = false;
  @StorageProp('statusBarHeight') statusBarHeight: number = 0;
  @Prop @Watch('onFocusSignalChange') searchFocusSignal: number = 0;
  private searchInputController: TextInputController = new TextInputController();
  private scroller: Scroller = new Scroller();
  private groupOffsets: number[] = [];

  onFocusSignalChange(): void {
    if (this.searchFocusSignal > 0) {
      this.focusSearch();
    }
  }

  aboutToAppear(): void {
    this.loadServices();
  }

  focusSearch(): void {
    try {
      this.searchInputController.caretPosition(this.searchText.length);
    } catch (e) {
    }
  }

  private parseGroups(raw: object[] | null): ServiceGroup[] {
    const list: ServiceGroup[] = [];
    if (raw === null || raw === undefined) {
      return list;
    }
    for (let i = 0; i < raw.length; i++) {
      const obj: Record<string, Object> = raw[i] as Record<string, Object>;
      const label: Object | undefined = obj['label'];
      const servicesRaw: Object | undefined = obj['services'];
      if (label === undefined || servicesRaw === undefined) {
        continue;
      }
      const group: ServiceGroup = new ServiceGroup();
      group.label = String(label);
      const services: Object[] = servicesRaw as Object[];
      for (let s = 0; s < services.length; s++) {
        const so: Record<string, Object> = services[s] as Record<string, Object>;
        const item: ServiceItem = new ServiceItem();
        const nm: Object | undefined = so['serviceName'] ?? so['name'];
        const icon: Object | undefined = so['iconUrl'] ?? so['imgUrl'];
        const url: Object | undefined = so['serviceUrl'] ?? so['url'];
        const tokenAccept: Object | undefined = so['tokenAccept'];
        item.name = nm === undefined ? '' : String(nm);
        item.iconUrl = icon === undefined ? '' : String(icon);
        item.url = url === undefined ? '' : String(url);
        item.tokenAccept = tokenAccept === undefined ? '' : String(tokenAccept);
        item.recommend = this.isRecommended(item.name);
        if (item.name.length > 0) {
          group.services.push(item);
        }
      }
      if (group.services.length > 0) {
        list.push(group);
      }
    }
    return list;
  }

  private isRecommended(name: string): boolean {
    const hot: string[] = ['学生课表查询', '体测系统', '学生成绩查询', '校园卡', '缴电费'];
    for (let i = 0; i < hot.length; i++) {
      if (name.indexOf(hot[i]) >= 0) {
        return true;
      }
    }
    return false;
  }

  private async loadServices(): Promise<void> {
    this.loading = true;
    this.loadError = '';
    try {
      const list = await SqgService.getInstance().getServiceList();
      this.groups = this.parseGroups(list);
    } catch (e) {
      this.loadError = String(e);
    } finally {
      this.loading = false;
    }
  }

  private allServices(): ServiceItem[] {
    const out: ServiceItem[] = [];
    for (let g = 0; g < this.groups.length; g++) {
      const grp: ServiceGroup = this.groups[g];
      for (let s = 0; s < grp.services.length; s++) {
        out.push(grp.services[s]);
      }
    }
    return out;
  }

  private onSearchChange(value: string): void {
    this.searchText = value;
    const kw: string = value.trim();
    if (kw.length === 0) {
      this.isSearching = false;
      this.searchResults = [];
      return;
    }
    this.isSearching = true;
    const all: ServiceItem[] = this.allServices();
    const hits: ServiceItem[] = [];
    const low: string = kw.toLowerCase();
    for (let i = 0; i < all.length; i++) {
      const it: ServiceItem = all[i];
      if (it.name.toLowerCase().indexOf(low) >= 0 || it.url.toLowerCase().indexOf(low) >= 0) {
        hits.push(it);
      }
    }
    this.searchResults = hits;
  }

  private clearSearch(): void {
    this.searchText = '';
    this.isSearching = false;
    this.searchResults = [];
  }

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

  private onTabClick(gIndex: number): void {
    this.activeTab = gIndex;
    try {
      if (this.groupOffsets.length > gIndex) {
        this.scroller.scrollTo({ xOffset: 0, yOffset: this.groupOffsets[gIndex], animation: { duration: 250, curve: Curve.EaseOut } });
      }
    } catch (e) {
    }
  }

  private onGroupAreaChange(gIndex: number, area: Area): void {
    let top: number = 0;
    try {
      const y: Length = area.position?.y ?? 0;
      top = typeof y === 'number' ? y : parseFloat(String(y)) || 0;
    } catch (e) {
      top = 0;
    }
    this.groupOffsets[gIndex] = top;
  }

  private iconColor(index: number): string {
    const colors: string[] = ['#2979FF', '#FF7043', '#26A69A', '#FFB300', '#7E57C2', '#EC407A', '#29B6F6', '#8D6E63'];
    return colors[index % colors.length];
  }

  private localIconFor(name: string): LocalIcon | undefined {
    const map: Record<string, LocalIcon> = {
      '节假日离返校': new LocalIcon($r('app.media.holiday'), true),
      '节假日': new LocalIcon($r('app.media.holiday'), true),
      '离返校': new LocalIcon($r('app.media.holiday'), true),
      '扫一扫': new LocalIcon($r('app.media.ic_public_scan_filled'), false),
      '日程': new LocalIcon($r('app.media.ic_public_calendar'), false),
      '缴电费': new LocalIcon($r('app.media.ic_bolt'), false),
      '校园卡': new LocalIcon($r('app.media.ic_card'), false),
      '影吧预约': new LocalIcon($r('app.media.ic_movie'), false),
      '学生课表查询': new LocalIcon($r('app.media.ic_book'), false),
      '日常劳动上报': new LocalIcon($r('app.media.ic_broom'), false),
      '人脸采集': new LocalIcon($r('app.media.ic_face'), false)
    };
    for (const key of Object.keys(map)) {
      if (name.indexOf(key) >= 0) {
        return map[key];
      }
    }
    return undefined;
  }

  private localIconRes(name: string): Resource | undefined {
    const li = this.localIconFor(name);
    return li === undefined ? undefined : li.icon;
  }

  private isColoredIcon(name: string): boolean {
    const li = this.localIconFor(name);
    return li !== undefined && li.colored;
  }

  @Builder
  TopBar() {
    Column() {
      Row() {
        Row() {
          Image($r('app.media.ic_search'))
            .width(16).height(16).fillColor('#90A4AE').objectFit(ImageFit.Contain)
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
              .onClick(() => { this.clearSearch(); })
          }
        }
        .layoutWeight(1).height(40)
        .borderRadius(20)
        .padding({ left: 16, right: 16 })
        .systemMaterial(new uiMaterial.ImmersiveMaterial({
          style: uiMaterial.ImmersiveStyle.THIN,
          interactive: true,
          lightEffect: { color: undefined }
        }))

        Text('管理').fontSize(14).fontColor('#2979FF')
          .margin({ left: 12 })
      }
      .width('100%').padding({ left: 16, right: 16, top: this.statusBarHeight + 56, bottom: 8 })
    }
    .width('100%')
    .backgroundColor(ThemeColors.bgPage)
    .expandSafeArea([SafeAreaType.SYSTEM, SafeAreaType.CUTOUT], [SafeAreaEdge.TOP])
  }

  @Builder
  GroupBlock(group: ServiceGroup, gIndex: number) {
    Column() {
      Row() {
        Row().width(4).height(16).backgroundColor('#E53935').borderRadius(2)
        Text(group.label).fontSize(15).fontWeight(FontWeight.Bold).fontColor(ThemeColors.textPrimary)
          .margin({ left: 8 })
        Blank()
      }.width('100%').padding({ left: 16, right: 16, top: 16, bottom: 10 })

      Grid() {
        ForEach(group.services, (item: ServiceItem, sIndex: number) => {
          GridItem() {
            Stack({ alignContent: Alignment.TopEnd }) {
              Column() {
                if (item.iconUrl.length > 0) {
                  Image(item.iconUrl).width(36).height(36).objectFit(ImageFit.Contain)
                } else if (this.localIconRes(item.name) !== undefined) {
                  if (this.isColoredIcon(item.name)) {
                    Image(this.localIconRes(item.name) as Resource)
                      .width(36).height(36).objectFit(ImageFit.Contain)
                  } else {
                    Image(this.localIconRes(item.name) as Resource)
                      .width(36).height(36).fillColor('#2979FF').objectFit(ImageFit.Contain)
                  }
                } else {
                  Text(item.name.substring(0, Math.min(1, item.name.length)))
                    .width(36).height(36).fontSize(16).fontColor('#FFFFFF').textAlign(TextAlign.Center)
                    .backgroundColor('#2979FF').borderRadius(9)
                }
                Text(item.name).fontSize(10).fontColor(ThemeColors.textPrimary)
                  .margin({ top: 4 }).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .width('100%').padding({ top: 8, bottom: 8 })
              .alignItems(HorizontalAlign.Center)

              if (item.recommend) {
                Text('荐').fontSize(8).fontColor('#FFFFFF').fontWeight(FontWeight.Bold)
                  .backgroundColor('#E53935').borderRadius(6)
                  .width(16).height(14).textAlign(TextAlign.Center)
                  .margin({ right: 10, top: 2 })
              }
            }
            .width('100%')
            .onClick(() => { this.openService(item); })
          }
        }, (item: ServiceItem, sIndex: number) => String(gIndex) + '_' + String(sIndex))
      }
      .columnsTemplate('1fr 1fr 1fr 1fr 1fr')
      .columnsGap(4).rowsGap(4)
      .width('100%').padding({ left: 8, right: 8, bottom: 12 })
    }
    .width('100%')
  }

  @Builder
  SearchResultRow(item: ServiceItem, index: number) {
    Row() {
      if (item.iconUrl.length > 0) {
        Image(item.iconUrl).width(40).height(40).objectFit(ImageFit.Contain)
      } else if (this.localIconRes(item.name) !== undefined) {
        if (this.isColoredIcon(item.name)) {
          Image(this.localIconRes(item.name) as Resource).width(40).height(40).objectFit(ImageFit.Contain)
        } else {
          Image(this.localIconRes(item.name) as Resource)
            .width(40).height(40).fillColor('#2979FF').objectFit(ImageFit.Contain)
        }
      } else {
        Text(item.name.substring(0, Math.min(1, item.name.length)))
          .width(40).height(40).fontSize(18).fontColor('#FFFFFF').textAlign(TextAlign.Center)
          .backgroundColor(this.iconColor(index)).borderRadius(10)
      }
      Text(item.name).fontSize(15).fontColor(ThemeColors.textPrimary)
        .margin({ left: 12 }).layoutWeight(1).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
      if (item.recommend) {
        Text('荐').fontSize(9).fontColor('#FFFFFF').fontWeight(FontWeight.Bold)
          .backgroundColor('#E53935').borderRadius(6)
          .width(18).height(16).textAlign(TextAlign.Center)
      }
      Text('›').fontSize(18).fontColor(ThemeColors.textSecondary).margin({ left: 10, right: 16 })
    }
    .width('100%').height(56).alignItems(VerticalAlign.Center)
    .padding({ left: 12 })
    .backgroundColor(ThemeColors.bgCard)
    .onClick(() => { this.openService(item); })
  }

  build() {
    Stack() {
      Column() {
        this.TopBar()

        if (this.loading && this.groups.length === 0) {
          Column() {
            LoadingProgress().width(40).height(40).color('#2979FF')
            Text('加载服务...').fontSize(14).fontColor(ThemeColors.textSecondary).margin({ top: 12 })
          }
          .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
        } else if (this.isSearching) {
          Scroll() {
            Column() {
              if (this.searchResults.length === 0) {
                Text('未找到相关服务').fontSize(14).fontColor(ThemeColors.textSecondary).margin({ top: 40 })
                  .width('100%').textAlign(TextAlign.Center)
              } else {
                ForEach(this.searchResults, (item: ServiceItem, index: number) => {
                  this.SearchResultRow(item, index)
                }, (item: ServiceItem, index: number) => 'sr_' + index + '_' + item.name)
              }
            }
            .width('100%').padding({ bottom: 20 })
          }
          .layoutWeight(1)
          .backgroundColor($r('sys.color.ohos_id_color_background'))
        } else if (this.groups.length === 0) {
          Column() {
            Text(this.loadError.length > 0 ? ('加载失败：' + this.loadError) : '暂无服务')
              .fontSize(14).fontColor(ThemeColors.textSecondary)
              .width('100%').textAlign(TextAlign.Center).margin({ top: 40 })
          }
          .layoutWeight(1)
        } else {
          Column() {
            Scroll() {
              Row() {
                ForEach(this.groups, (group: ServiceGroup, gIndex: number) => {
                  Text(group.label)
                    .fontSize(14)
                    .fontColor(this.activeTab === gIndex ? '#2979FF' : ThemeColors.textSecondary)
                    .fontWeight(this.activeTab === gIndex ? FontWeight.Bold : FontWeight.Normal)
                    .padding({ left: 14, right: 14, top: 8, bottom: 8 })
                    .borderRadius(16)
                    .backgroundColor(this.activeTab === gIndex ? '#E3F2FD' : Color.Transparent)
                    .onClick(() => { this.onTabClick(gIndex); })
                }, (group: ServiceGroup, gIndex: number) => String(gIndex))
              }
              .padding({ left: 8, right: 8 })
            }
            .scrollable(ScrollDirection.Horizontal)
            .scrollBar(BarState.Off)
            .width('100%').height(44)
            .backgroundColor(ThemeColors.bgPage)

            Scroll(this.scroller) {
              Column() {
                ForEach(this.groups, (group: ServiceGroup, gIndex: number) => {
                  Column() {
                    this.GroupBlock(group, gIndex)
                  }
                  .width('100%')
                  .id('group_' + gIndex)
                  .onAreaChange((_old: Area, newArea: Area) => {
                    this.onGroupAreaChange(gIndex, newArea);
                  })
                }, (group: ServiceGroup, gIndex: number) => 'g_' + gIndex)
                Blank().height(24)
              }
              .width('100%')
            }
            .layoutWeight(1)
            .scrollBar(BarState.Off)
            .backgroundColor(ThemeColors.bgPage)
          }
          .width('100%').layoutWeight(1)
        }
      }
      .width('100%').height('100%')
    }
    .width('100%').height('100%')
  }
}
