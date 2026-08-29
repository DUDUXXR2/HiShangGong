import { ThemeColors } from '../../utils/ThemeColors';
import { SqgService } from '../../services/SqgService';
import { WebPageParam, isJwServiceName } from '../NavParams';
import { localIconRes, isColoredIcon } from '../../utils/ServiceIcons';
import { CloudIconStore } from '../../utils/CloudIcons';
import { GlassCard } from '../../components/GlassCard';
import { ImmersionSearch } from '@tangs/components';
import { SearchModifier } from '../../components/SearchModifier';
import { MaterialConfig } from '../../utils/MaterialConfig';

const TAG = 'ServiceTab';

const HOME_TITLE_HEIGHT: number = 56;
const PAGE_CARD_GAP: number = 10;
const HOME_HORIZONTAL_PADDING: number = 20;
const SEARCH_BAR_HEIGHT: number = 44;
const HOME_NAV_HEIGHT: number = 52;

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
  @State gridCols: number = 5;
  @State failedIconUrls: string[] = [];
  @StorageProp('statusBarHeight') statusBarHeight: number = 0;
  @StorageProp('bottomRectHeight') bottomRectHeight: number = 0;
  @Prop @Watch('onFocusSignalChange') searchFocusSignal: number = 0;
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
      await CloudIconStore.load();
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
      if (it.name.toLowerCase().indexOf(low) >= 0) {
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
    if (isJwServiceName(item.name)) {
      this.pageStack.pushPathByName('JwWebPage', new WebPageParam(item.name, finalUrl));
    } else {
      this.pageStack.pushPathByName('ServiceWebPage', new WebPageParam(item.name, finalUrl));
    }
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

  // 断点自适应列数：手机 5 / 平板 7 / 2in1 10 / 大屏 12
  private colsForWidth(width: number): number {
    if (width < 600) {
      return 5;
    }
    if (width < 840) {
      return 7;
    }
    if (width < 1280) {
      return 10;
    }
    return 12;
  }

  private gridTemplate(cols: number): string {
    let tpl: string = '';
    for (let i = 0; i < cols; i++) {
      tpl += '1fr ';
    }
    return tpl.trim();
  }

  // 云端图标加载失败时记录，下次渲染回退本地 SVG
  private markCloudIconFailed(url: string): void {
    if (url.length > 0 && this.failedIconUrls.indexOf(url) < 0) {
      this.failedIconUrls = this.failedIconUrls.concat(url);
    }
  }

  private cloudIconBroken(url: string): boolean {
    return url.length > 0 && this.failedIconUrls.indexOf(url) >= 0;
  }

  @Builder
  TopBar() {
    ImmersionSearch({
      systemMaterialEffect: MaterialConfig.systemMaterialEffectParams(),
      _height: SEARCH_BAR_HEIGHT,
      options: { placeholder: '搜索服务' },
      modifier: new SearchModifier(
        ThemeColors.textPrimary,
        '#90A4AE',
        (value: string): void => { this.onSearchChange(value); }
      )
    })
    .height(SEARCH_BAR_HEIGHT)
    .width('100%')
    .clip(false)
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
                // 本地已有彩色图标（节假日/影吧/成绩查询等）优先用本地，避免网络加载慢/失败导致空白
                if (localIconRes(item.name) !== undefined && isColoredIcon(item.name)) {
                  Image(localIconRes(item.name) as Resource)
                    .width(36).height(36).objectFit(ImageFit.Contain)
                } else if (item.iconUrl.length > 0 && !this.cloudIconBroken(item.iconUrl)) {
                  Image(item.iconUrl).width(36).height(36).objectFit(ImageFit.Contain)
                    .onError(() => { this.markCloudIconFailed(item.iconUrl); })
                } else if (CloudIconStore.iconUrlFor(item.name).length > 0 &&
                  !this.cloudIconBroken(CloudIconStore.iconUrlFor(item.name))) {
                  Image(CloudIconStore.iconUrlFor(item.name))
                    .width(36).height(36).objectFit(ImageFit.Contain)
                    .onError(() => { this.markCloudIconFailed(CloudIconStore.iconUrlFor(item.name)); })
                } else if (localIconRes(item.name) !== undefined) {
                  Image(localIconRes(item.name) as Resource)
                    .width(36).height(36).fillColor('#2979FF').objectFit(ImageFit.Contain)
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
      .columnsTemplate(this.gridTemplate(this.gridCols))
      .columnsGap(4).rowsGap(4)
      .width('100%').padding({ left: 8, right: 8, bottom: 12 })
    }
    .width('100%')
    .onAreaChange((_old: Area, newArea: Area) => {
      const w: number = newArea.width as number;
      if (w > 0) {
        const cols: number = this.colsForWidth(w);
        if (cols !== this.gridCols) {
          this.gridCols = cols;
        }
      }
    })
  }

  @Builder
  SearchResultRow(item: ServiceItem, index: number) {
    Column() {
      GlassCard({ cardHeight: 56, cardRadius: 12 }) {
        Row() {
          if (item.iconUrl.length > 0 && !this.cloudIconBroken(item.iconUrl)) {
            Image(item.iconUrl).width(40).height(40).objectFit(ImageFit.Contain)
              .onError(() => { this.markCloudIconFailed(item.iconUrl); })
          } else if (CloudIconStore.iconUrlFor(item.name).length > 0 &&
            !this.cloudIconBroken(CloudIconStore.iconUrlFor(item.name))) {
            Image(CloudIconStore.iconUrlFor(item.name)).width(40).height(40).objectFit(ImageFit.Contain)
              .onError(() => { this.markCloudIconFailed(CloudIconStore.iconUrlFor(item.name)); })
          } else if (localIconRes(item.name) !== undefined) {
            if (isColoredIcon(item.name)) {
              Image(localIconRes(item.name) as Resource).width(40).height(40).objectFit(ImageFit.Contain)
            } else {
              Image(localIconRes(item.name) as Resource)
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
      }
    }
    .width('100%')
    .margin({ bottom: PAGE_CARD_GAP })
    .onClick(() => { this.openService(item); })
  }

  build() {
    Stack({ alignContent: Alignment.Top }) {
      // 内容滚动区（全屏，从悬浮搜索框/分类条下方穿过）
      if (this.loading && this.groups.length === 0) {
        Column() {
          LoadingProgress().width(40).height(40).color('#2979FF')
          Text('加载服务...').fontSize(14).fontColor(ThemeColors.textSecondary).margin({ top: 12 })
        }
        .width('100%').height('100%').justifyContent(FlexAlign.Center)
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
        .width('100%').height('100%')
        .align(Alignment.Top)
        .padding({ top: this.statusBarHeight + HOME_TITLE_HEIGHT + PAGE_CARD_GAP + SEARCH_BAR_HEIGHT + PAGE_CARD_GAP })
        .contentEndOffset(this.bottomRectHeight + HOME_NAV_HEIGHT + PAGE_CARD_GAP)
        .scrollBar(BarState.Off)
        .clip(false)
        .backgroundBlurStyle(BlurStyle.COMPONENT_THICK)
      } else if (this.groups.length === 0) {
        Column() {
          Text(this.loadError.length > 0 ? ('加载失败：' + this.loadError) : '暂无服务')
            .fontSize(14).fontColor(ThemeColors.textSecondary)
            .width('100%').textAlign(TextAlign.Center).margin({ top: 40 })
        }
        .width('100%').height('100%').justifyContent(FlexAlign.Center)
      } else {
        // 分类条（多选按钮，随滚动隐藏）+ 主内容
        Scroll(this.scroller) {
          Column() {
            // 顶部占位（避让悬浮搜索框 + 分类条）
            Column()
              .width('100%')
              .height(this.statusBarHeight + HOME_TITLE_HEIGHT + PAGE_CARD_GAP + SEARCH_BAR_HEIGHT + PAGE_CARD_GAP)

            // 分类条（横向多选按钮）
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

            // 分组内容
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
          .width('100%')
        }
        .width('100%').height('100%')
        .align(Alignment.Top)
        .contentEndOffset(this.bottomRectHeight + HOME_NAV_HEIGHT + PAGE_CARD_GAP)
        .scrollBar(BarState.Off)
        .backgroundColor(Color.Transparent)
        .clip(false)
        .backgroundBlurStyle(BlurStyle.COMPONENT_THICK)
      }

      // 悬浮搜索框（毛玻璃，位置与主页一致）
      Row() {
        this.TopBar()
      }
      .width('100%')
      .padding({ left: HOME_HORIZONTAL_PADDING, right: HOME_HORIZONTAL_PADDING })
      .position({ x: 0, y: this.statusBarHeight + HOME_TITLE_HEIGHT + PAGE_CARD_GAP })
      .zIndex(12)
    }
    .width('100%').height('100%')
    .backgroundColor(Color.Transparent)
  }
}
