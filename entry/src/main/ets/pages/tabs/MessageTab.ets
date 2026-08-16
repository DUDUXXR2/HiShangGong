// MessageTab.ets — 消息页（站内信）
// 数据源：GET {message-service}/api/v1/instantMessage/appGroupByTag
// 返回 list 按 tags.tags 标签分组（固定 待办/其他 分组），每条消息含 appName(标题)/content(内容)/editTime(时间)/num(未读数)
import { uiMaterial } from '@kit.ArkUI';
import { ThemeColors } from '../../utils/ThemeColors';
import { SqgService } from '../../services/SqgService';
import { WebPageParam } from '../NavParams';
import { immersiveMaterialSupported } from '../../utils/MaterialKit';

const HOME_TITLE_HEIGHT: number = 56;
const HOME_NAV_HEIGHT: number = 52;
const PAGE_CARD_GAP: number = 10;
const HOME_HORIZONTAL_PADDING: number = 20;
const SEARCH_BAR_HEIGHT: number = 44;

class AppMessage {
  appName: string = '';
  content: string = '';
  time: string = '';
  num: number = 0;
  url: string = '';
  mobileUrl: string = '';
  logo: string = '';
  type: string = '';
  appId: string = '';
  topTime: boolean = false;
  tags: string[] = [];
}

class MessageGroup {
  tagName: string = '';
  messages: AppMessage[] = [];
}

@Component
export struct MessageTab {
  @Consume('pageStack') pageStack: NavPathStack;
  @State groups: MessageGroup[] = [];
  @State loading: boolean = true;
  @State searchText: string = '';
  @State searchResults: AppMessage[] = [];
  private searchInputController: TextInputController = new TextInputController();
  @StorageProp('statusBarHeight') statusBarHeight: number = 0;
  @StorageProp('bottomRectHeight') bottomRectHeight: number = 0;
  @StorageLink('theme_is_dark') themeIsDark: boolean = false;

  aboutToAppear(): void {
    this.loadMessages();
  }

  private async loadMessages(): Promise<void> {
    this.loading = true;
    try {
      const list = await SqgService.getInstance().getAppMessages();
      console.info('[YS] tab list=' + (list === null ? 'null' : list.length.toString()));
      if (list === null) {
        this.groups = [];
        return;
      }
      // 最朴素的数组分组：待办 / 其他 / 各标签组（避免 Map 闭包潜在问题）
      const groups: MessageGroup[] = [];
      const findGroup = (tag: string): MessageGroup => {
        for (let g = 0; g < groups.length; g++) {
          if (groups[g].tagName === tag) {
            return groups[g];
          }
        }
        const ng: MessageGroup = new MessageGroup();
        ng.tagName = tag;
        groups.push(ng);
        return ng;
      };
      for (let i = 0; i < list.length; i++) {
        let msg: AppMessage | null = null;
        try {
          msg = this.parseMessage(list[i]);
        } catch (pe) {
          console.error('[YS] parse err at ' + i + ': ' + String(pe));
          continue;
        }
        if (msg === null) {
          continue;
        }
        if (msg.topTime) {
          findGroup('待办').messages.push(msg);
        } else if (msg.tags.length === 0) {
          findGroup('其他').messages.push(msg);
        } else {
          for (let t = 0; t < msg.tags.length; t++) {
            findGroup(msg.tags[t]).messages.push(msg);
          }
        }
      }
      // 去掉空分组
      const nonEmpty: MessageGroup[] = [];
      for (let i = 0; i < groups.length; i++) {
        if (groups[i].messages.length > 0) {
          nonEmpty.push(groups[i]);
        }
      }
      this.groups = nonEmpty;
      console.info('[YS] tab groups=' + this.groups.length.toString());
    } catch (e) {
      console.error('[YS] tab err=' + String(e));
      this.groups = [];
    } finally {
      this.loading = false;
    }
  }

  private parseMessage(raw: object): AppMessage {
    const msg: AppMessage = new AppMessage();
    if (raw === null || raw === undefined) {
      return msg;
    }
    const obj: Record<string, Object> = raw as Record<string, Object>;
    msg.appName = String(obj['appName'] ?? obj['title'] ?? obj['name'] ?? '');
    msg.content = this.stripHtml(String(obj['content'] ?? obj['summary'] ?? obj['text'] ?? ''));
    msg.time = this.formatTime(String(obj['editTime'] ?? obj['time'] ?? ''));
    msg.num = Number(obj['num'] ?? 0);
    msg.url = String(obj['url'] ?? '');
    msg.mobileUrl = String(obj['mobileUrl'] ?? '');
    msg.logo = String(obj['logo'] ?? '');
    msg.type = String(obj['type'] ?? '');
    msg.appId = String(obj['appId'] ?? '');
    const topRaw: Object | undefined = obj['topTime'];
    msg.topTime = topRaw !== undefined && topRaw !== null && topRaw !== 0;
    // 标签：v.tags.tags 是逗号分隔字符串
    msg.tags = [];
    const tagsObj: Object | undefined = obj['tags'];
    if (tagsObj !== undefined && tagsObj !== null) {
      let tagsStr: string = '';
      if (typeof tagsObj === 'string') {
        tagsStr = String(tagsObj);
      } else {
        const tagsRec: Record<string, Object> = tagsObj as Record<string, Object>;
        tagsStr = String(tagsRec['tags'] ?? '');
      }
      if (tagsStr.length > 0) {
        const parts: string[] = tagsStr.split(',');
        for (let i = 0; i < parts.length; i++) {
          const t: string = parts[i].trim();
          if (t.length > 0) {
            msg.tags.push(t);
          }
        }
      }
    }
    return msg;
  }

  // 剥离 content 里的 HTML 标签（服务端返回 <p>标题:xxx</p> 这类富文本）
  private stripHtml(raw: string): string {
    return raw.replace(/<[^>]*>/g, '').replace(/&nbsp;/g, ' ').trim();
  }

  private formatTime(raw: string): string {
    if (raw.length <= 10) {
      return raw;
    }
    // 时间戳（毫秒/秒）
    if (/^\d{10,13}$/.test(raw)) {
      const ts: number = raw.length === 13 ? Number(raw) : Number(raw) * 1000;
      const d: Date = new Date(ts);
      const p = (n: number): string => (n < 10 ? '0' : '') + n.toString();
      return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}`;
    }
    return raw.replace('T', ' ').substring(0, 10);
  }

  private allMessages(): AppMessage[] {
    const out: AppMessage[] = [];
    for (let g = 0; g < this.groups.length; g++) {
      const grp: MessageGroup = this.groups[g];
      for (let m = 0; m < grp.messages.length; m++) {
        out.push(grp.messages[m]);
      }
    }
    return out;
  }

  private onSearchChange(value: string): void {
    this.searchText = value;
    const kw: string = value.trim();
    this.searchResults = [];
    if (kw.length === 0) {
      return;
    }
    const low: string = kw.toLowerCase();
    const all: AppMessage[] = this.allMessages();
    for (let i = 0; i < all.length; i++) {
      const it: AppMessage = all[i];
      if (it.appName.toLowerCase().indexOf(low) >= 0 || it.content.toLowerCase().indexOf(low) >= 0) {
        this.searchResults.push(it);
      }
    }
  }

  private clearSearch(): void {
    this.searchText = '';
    this.searchResults = [];
  }

  @Builder
  SearchBar() {
    if (immersiveMaterialSupported()) {
      Row() { this.SearchBarInner() }
        .width('100%').height(SEARCH_BAR_HEIGHT)
        .borderRadius(SEARCH_BAR_HEIGHT / 2)
        .padding({ left: 16, right: 16 })
        .systemMaterial(new uiMaterial.ImmersiveMaterial({
          style: uiMaterial.ImmersiveStyle.THIN,
          interactive: true,
          lightEffect: { color: undefined }
        }))
    } else {
      Row() { this.SearchBarInner() }
        .width('100%').height(SEARCH_BAR_HEIGHT)
        .borderRadius(SEARCH_BAR_HEIGHT / 2)
        .padding({ left: 16, right: 16 })
        .backgroundColor(ThemeColors.bgInput)
    }
  }

  @Builder
  SearchBarInner() {
    Image($r('app.media.ic_search'))
      .width(16).height(16).fillColor('#90A4AE').objectFit(ImageFit.Contain)
    TextInput({ text: this.searchText, placeholder: '搜索消息', controller: this.searchInputController })
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

  @Builder
  MessageRow(item: AppMessage) {
    Row() {
      // 消息头像：logo（网络）优先，无则用本地标签 SVG 兜底（对应安卓 /static/biaoqian.png）
      if (item.logo.length > 0) {
        Image(item.logo)
          .width(40).height(40)
          .borderRadius(20)
          .objectFit(ImageFit.Cover)
      } else {
        Image($r('app.media.ic_msg_tag'))
          .width(40).height(40)
          .fillColor('#2979FF')
          .objectFit(ImageFit.Contain)
      }

      Column() {
        // 标题行：左侧 appName，右侧时间 + 未读数（与标题同一行）
        Row() {
          Text(item.appName)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(ThemeColors.textPrimary)
            .layoutWeight(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          if (item.num > 0) {
            Text(item.num > 99 ? '99+' : item.num.toString())
              .fontSize(10)
              .fontColor(Color.White)
              .backgroundColor('#E53935')
              .borderRadius(9)
              .height(18)
              .width(item.num > 99 ? 36 : 18)
              .padding({ left: 5, right: 5 })
              .textAlign(TextAlign.Center)
              .margin({ left: 6 })
          }
          if (item.time.length > 0) {
            Text(item.time)
              .fontSize(11)
              .fontColor(ThemeColors.textHint)
              .margin({ left: 10 })
          }
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        if (item.content.length > 0) {
          Text(item.content)
            .fontSize(13)
            .fontColor(ThemeColors.textSecondary)
            .width('100%')
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 4 })
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12 })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .alignItems(VerticalAlign.Center)
    .backgroundColor(ThemeColors.bgCard)
    .borderRadius(12)
    .margin({ bottom: PAGE_CARD_GAP })
    .onClick(() => {
      this.openMessage(item);
    })
  }

  // 点击消息：打开详情（对应安卓 jumpTo）
  // 优先打开 mobileUrl/url 网页；没有链接时弹出内容对话框查看完整消息
  private openMessage(item: AppMessage): void {
    let target: string = item.mobileUrl.length > 0 ? item.mobileUrl : item.url;
    if (target.length > 0) {
      if (target.startsWith('/')) {
        target = 'https://i.sqgxy.edu.cn' + target;
      }
      const title: string = item.appName.length > 0 ? item.appName : '消息详情';
      this.pageStack.pushPathByName('ServiceWebPage', new WebPageParam(title, target));
      return;
    }
    // 无跳转链接：显示完整内容
    const titleText: string = item.appName.length > 0 ? item.appName : '消息详情';
    const bodyText: string = item.content.length > 0 ? item.content : '暂无内容';
    AlertDialog.show({
      title: titleText,
      message: bodyText,
      confirm: {
        value: '关闭',
        fontColor: '#2979FF',
        action: () => {
        }
      }
    });
  }

  @Builder
  SearchResultRow(item: AppMessage) {
    Row() {
      Column() {
        Text(item.appName)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(ThemeColors.textPrimary)
          .width('100%')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        if (item.content.length > 0) {
          Text(item.content)
            .fontSize(13)
            .fontColor(ThemeColors.textSecondary)
            .width('100%')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 4 })
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .alignItems(VerticalAlign.Center)
    .backgroundColor(ThemeColors.bgCard)
    .borderRadius(12)
    .margin({ bottom: 1 })
  }

  build() {
    Stack({ alignContent: Alignment.Top }) {
      if (this.loading && this.groups.length === 0) {
        Column() {
          LoadingProgress().width(40).height(40).color('#2979FF')
          Text('加载消息...').fontSize(14).fontColor(ThemeColors.textSecondary).margin({ top: 12 })
        }
        .width('100%').height('100%').justifyContent(FlexAlign.Center)
      } else if (this.searchResults.length > 0) {
        Scroll() {
          Column() {
            ForEach(this.searchResults, (item: AppMessage) => {
              this.SearchResultRow(item)
            }, (item: AppMessage) => item.appName + item.time)
          }
          .width('100%')
          .padding({ left: HOME_HORIZONTAL_PADDING, right: HOME_HORIZONTAL_PADDING, bottom: 24 })
        }
        .width('100%').height('100%')
        .align(Alignment.Top)
        .padding({ top: this.statusBarHeight + HOME_TITLE_HEIGHT + PAGE_CARD_GAP + SEARCH_BAR_HEIGHT + PAGE_CARD_GAP })
        .contentEndOffset(this.bottomRectHeight + HOME_NAV_HEIGHT + PAGE_CARD_GAP)
        .scrollBar(BarState.Off)
        .clip(false)
      } else if (this.groups.length === 0) {
        Column() {
          Text('暂无消息')
            .fontSize(14).fontColor(ThemeColors.textSecondary)
            .width('100%').textAlign(TextAlign.Center).margin({ top: 40 })
        }
        .width('100%').height('100%').justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column() {
            ForEach(this.groups, (group: MessageGroup, gIndex: number) => {
              Column() {
                Row() {
                  Row().width(4).height(16).backgroundColor('#E53935').borderRadius(2)
                  Text(group.tagName)
                    .fontSize(15).fontWeight(FontWeight.Bold).fontColor(ThemeColors.textPrimary)
                    .margin({ left: 8 })
                  Blank()
                }
                .width('100%').padding({ left: 4, right: 4, top: 14, bottom: 10 })

                ForEach(group.messages, (item: AppMessage, mIndex: number) => {
                  this.MessageRow(item)
                }, (item: AppMessage, mIndex: number) => group.tagName + '_' + mIndex + '_' + item.appName + item.time)

                if (group.messages.length === 0) {
                  Text('暂无新待办')
                    .fontSize(13).fontColor(ThemeColors.textSecondary)
                    .width('100%').textAlign(TextAlign.Center)
                    .padding({ top: 16, bottom: 16 })
                    .backgroundColor(ThemeColors.bgCard)
                    .borderRadius(12)
                }
              }
              .width('100%')
              .alignItems(HorizontalAlign.Start)
            }, (group: MessageGroup, gIndex: number) => 'msg_grp_' + gIndex + '_' + group.tagName)
            Blank().height(24)
          }
          .width('100%')
          .padding({ left: HOME_HORIZONTAL_PADDING, right: HOME_HORIZONTAL_PADDING, bottom: 24 })
        }
        .width('100%').height('100%')
        .align(Alignment.Top)
        .padding({ top: this.statusBarHeight + HOME_TITLE_HEIGHT + PAGE_CARD_GAP + SEARCH_BAR_HEIGHT + PAGE_CARD_GAP })
        .contentEndOffset(this.bottomRectHeight + HOME_NAV_HEIGHT + PAGE_CARD_GAP)
        .scrollBar(BarState.Off)
        .clip(false)
      }

      // 悬浮搜索框
      Row() {
        this.SearchBar()
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
