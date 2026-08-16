// QuickActionGrid.ets — 首页快捷操作网格（设置页风格：玻璃卡片 + 图标按钮，卡片表面不可点、页面可滑动）
// 两行卡片：row1 / row2，每个按钮 = 图标 + 文字，点击回调 onAction(label)
// 图标优先用服务列表下发的真实图标（iconUrl，与服务页一致），否则回退本地 svg（icon）
import { GlassCard } from './GlassCard';
import { ThemeColors } from '../utils/ThemeColors';

export class QuickActionItem {
  label: string = '';
  icon: Resource = $r('app.media.ic_public_more');
  iconUrl: string = '';
  fillColor: ResourceColor = '#2979FF';
  colored: boolean = false;
  url: string = '';
  tokenAccept: string = '';
}

const QUICK_CARD_HEIGHT: number = 84;
const QUICK_CARD_RADIUS: number = 16;
const QUICK_CARD_GAP: number = 10;

@Component
export struct QuickActionGrid {
  @Prop row1: QuickActionItem[] = [];
  @Prop row2: QuickActionItem[] = [];
  @State failedIconUrls: string[] = [];
  onAction: (label: string) => void = () => {
  };

  private markIconFailed(url: string): void {
    if (url.length > 0 && this.failedIconUrls.indexOf(url) < 0) {
      this.failedIconUrls = this.failedIconUrls.concat(url);
    }
  }

  private showLocalIcon(item: QuickActionItem): boolean {
    return item.iconUrl.length === 0 || this.failedIconUrls.indexOf(item.iconUrl) >= 0;
  }

  @Builder
  ActionRow(items: QuickActionItem[]) {
    Row() {
      ForEach(items, (item: QuickActionItem, idx: number) => {
        if (item.label.length === 0) {
          Column()
            .width('100%')
            .layoutWeight(1)
            .height(QUICK_CARD_HEIGHT)
        } else {
          Column() {
            if (!this.showLocalIcon(item)) {
              Image(item.iconUrl)
                .width(30).height(30)
                .objectFit(ImageFit.Contain)
                .onError(() => { this.markIconFailed(item.iconUrl); })
            } else if (item.colored) {
              Image(item.icon)
                .width(30).height(30)
                .objectFit(ImageFit.Contain)
            } else {
              Image(item.icon)
                .width(30).height(30)
                .fillColor(item.fillColor)
                .objectFit(ImageFit.Contain)
            }
            Text(item.label)
              .fontSize(11)
              .fontColor(ThemeColors.textPrimary)
              .margin({ top: 8 })
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width('100%')
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
          .padding({ top: 12, bottom: 12 })
          .onClick(() => { this.onAction(item.label); })
        }
      }, (item: QuickActionItem, idx: number) => item.label + '_' + idx.toString())
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  build() {
    Column({ space: QUICK_CARD_GAP }) {
      GlassCard({ cardHeight: QUICK_CARD_HEIGHT, cardRadius: QUICK_CARD_RADIUS }) {
        this.ActionRow(this.row1)
      }
      GlassCard({ cardHeight: QUICK_CARD_HEIGHT, cardRadius: QUICK_CARD_RADIUS }) {
        this.ActionRow(this.row2)
      }
    }
    .width('100%')
  }
}
