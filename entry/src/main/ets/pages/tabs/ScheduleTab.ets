import { calendarManager } from '@kit.CalendarKit';
import { abilityAccessCtrl, bundleManager } from '@kit.AbilityKit';
import { ThemeColors } from '../../utils/ThemeColors';
import { ToastUtil } from '../../utils/ToastUtil';
import { ImmersionSearch } from '@tangs/components';
import { SearchModifier } from '../../components/SearchModifier';
import { MaterialConfig } from '../../utils/MaterialConfig';

const HOME_TITLE_HEIGHT: number = 56;
const HOME_NAV_HEIGHT: number = 52;
const PAGE_CARD_GAP: number = 10;
const HOME_HORIZONTAL_PADDING: number = 20;
const SEARCH_BAR_HEIGHT: number = 44;

class ScheduleEvent {
  id: number = 0;
  title: string = '';
  startTime: number = 0;
  endTime: number = 0;
  location: string = '';
  description: string = '';
}

@Component
export struct ScheduleTab {
  @State events: ScheduleEvent[] = [];
  @State loading: boolean = true;
  @State permissionDenied: boolean = false;
  @State newTitle: string = '';
  @State newHour: number = 10;
  @State newMinute: number = 0;
  @State selectedDate: number = ScheduleTab.startOfToday();
  @StorageProp('statusBarHeight') statusBarHeight: number = 0;
  @StorageProp('bottomRectHeight') bottomRectHeight: number = 0;
  @StorageLink('theme_is_dark') themeIsDark: boolean = false;

  static startOfToday(): number {
    const now: Date = new Date();
    return new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime();
  }

  aboutToAppear(): void {
    this.ensurePermissionAndLoad();
  }

  private async ensurePermissionAndLoad(): Promise<void> {
    this.loading = true;
    this.permissionDenied = false;
    try {
      const has = await this.hasCalendarPermission();
      if (!has) {
        const granted = await this.requestCalendarPermission();
        if (!granted) {
          this.permissionDenied = true;
          this.loading = false;
          return;
        }
      }
      await this.loadEvents();
    } catch (e) {
      this.permissionDenied = true;
      this.loading = false;
    }
  }

  private async hasCalendarPermission(): Promise<boolean> {
    try {
      const atManager = abilityAccessCtrl.createAtManager();
      const bundleInfo = await bundleManager.getBundleInfoForSelf(
        bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
      const status = await atManager.checkAccessToken(
        bundleInfo.appInfo.accessTokenId, 'ohos.permission.READ_CALENDAR');
      return status === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
    } catch (e) {
      return false;
    }
  }

  private async requestCalendarPermission(): Promise<boolean> {
    try {
      const atManager = abilityAccessCtrl.createAtManager();
      const ctx = this.getUIContext().getHostContext();
      if (!ctx) {
        return false;
      }
      const result = await atManager.requestPermissionsFromUser(ctx,
        ['ohos.permission.READ_CALENDAR', 'ohos.permission.WRITE_CALENDAR']);
      return result.authResults.length > 0 && result.authResults[0] === 0;
    } catch (e) {
      return false;
    }
  }

  private async loadEvents(): Promise<void> {
    this.loading = true;
    try {
      const mgr = calendarManager.getCalendarManager(this.getUIContext().getHostContext());
      const calendar = await mgr.getCalendar();
      const start: number = this.selectedDate;
      const end: number = start + 24 * 3600 * 1000;
      const events = await calendar.getEvents(calendarManager.EventFilter.filterByTime(start, end));
      const items: ScheduleEvent[] = [];
      for (let i = 0; i < events.length; i++) {
        const ev = events[i];
        const it: ScheduleEvent = new ScheduleEvent();
        it.id = ev.id ?? 0;
        it.title = ev.title ?? '';
        it.startTime = ev.startTime ?? 0;
        it.endTime = ev.endTime ?? 0;
        it.location = ev.location?.location ?? '';
        it.description = ev.description ?? '';
        if (it.id !== 0) {
          items.push(it);
        }
      }
      items.sort((a: ScheduleEvent, b: ScheduleEvent) => a.startTime - b.startTime);
      this.events = items;
    } catch (e) {
      ToastUtil.show('读取日程失败');
    } finally {
      this.loading = false;
    }
  }

  private showDatePicker(): void {
    const d: Date = new Date(this.selectedDate);
    try {
      this.getUIContext().showDatePickerDialog({
        start: new Date('1970-01-01'),
        end: new Date('2099-12-31'),
        selected: d,
        onDateAccept: (value: Date) => {
          this.selectedDate = new Date(value.getFullYear(), value.getMonth(), value.getDate()).getTime();
          this.loadEvents();
        }
      });
    } catch (e) {
    }
  }

  private goToday(): void {
    this.selectedDate = ScheduleTab.startOfToday();
    this.loadEvents();
  }

  private async addEvent(): Promise<void> {
    const title: string = this.newTitle.trim();
    if (title.length === 0) {
      ToastUtil.show('请输入日程内容');
      return;
    }
    try {
      const mgr = calendarManager.getCalendarManager(this.getUIContext().getHostContext());
      const calendar = await mgr.getCalendar();
      const start: number = this.selectedDate + (this.newHour * 3600 + this.newMinute * 60) * 1000;
      await calendar.addEvent({
        type: 0,
        title: title,
        startTime: start,
        endTime: start + 3600 * 1000
      });
      this.newTitle = '';
      ToastUtil.show('已添加日程');
      this.loadEvents();
    } catch (e) {
      ToastUtil.show('添加日程失败');
    }
  }

  private async deleteEvent(id: number): Promise<void> {
    try {
      const mgr = calendarManager.getCalendarManager(this.getUIContext().getHostContext());
      const calendar = await mgr.getCalendar();
      await calendar.deleteEvent(id);
      ToastUtil.show('已删除日程');
      this.loadEvents();
    } catch (e) {
      ToastUtil.show('删除日程失败');
    }
  }

  private fmtDate(ts: number): string {
    const d: Date = new Date(ts);
    const week: string[] = ['日', '一', '二', '三', '四', '五', '六'];
    return `${d.getFullYear()}年${d.getMonth() + 1}月${d.getDate()}日 周${week[d.getDay()]}`;
  }

  private fmtTime(ts: number): string {
    if (ts <= 0) {
      return '';
    }
    const d: Date = new Date(ts);
    const p = (n: number): string => (n < 10 ? '0' : '') + n.toString();
    return `${p(d.getHours())}:${p(d.getMinutes())}`;
  }

  private isToday(ts: number): boolean {
    return ts === ScheduleTab.startOfToday();
  }

  private fmtNewTime(): string {
    const p = (n: number): string => (n < 10 ? '0' : '') + n.toString();
    return p(this.newHour) + ':' + p(this.newMinute);
  }

  private showTimePicker(): void {
    const d: Date = new Date(this.selectedDate);
    d.setHours(this.newHour, this.newMinute);
    try {
      this.getUIContext().showTimePickerDialog({
        selected: d,
        useMilitaryTime: true,
        onAccept: (value: TimePickerResult) => {
          if (value.hour !== undefined && value.minute !== undefined) {
            this.newHour = value.hour;
            this.newMinute = value.minute;
          }
        }
      });
    } catch (e) {
    }
  }

  @Builder
  SearchBar() {
    ImmersionSearch({
      systemMaterialEffect: MaterialConfig.systemMaterialEffectParams(),
      _height: SEARCH_BAR_HEIGHT,
      options: { placeholder: '添加日程' },
      modifier: new SearchModifier(
        ThemeColors.textPrimary,
        '#90A4AE',
        (value: string): void => { this.newTitle = value; }
      )
    })
    .height(SEARCH_BAR_HEIGHT)
    .width('100%')
    .clip(false)
  }

  @Builder
  EventRow(item: ScheduleEvent) {
    Row() {
      Column() {
        Text(item.title)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(ThemeColors.textPrimary)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.fmtTime(item.startTime) + (item.location.length > 0 ? ' · ' + item.location : ''))
          .fontSize(12)
          .fontColor(ThemeColors.textSecondary)
          .margin({ top: 4 })
      }
      .layoutWeight(1).alignItems(HorizontalAlign.Start)

      Text('删除')
        .fontSize(13)
        .fontColor('#C62828')
        .padding({ left: 8, right: 8, top: 6, bottom: 6 })
        .onClick(() => { this.deleteEvent(item.id); })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .backgroundColor(ThemeColors.bgCard)
    .borderRadius(12)
    .margin({ bottom: PAGE_CARD_GAP })
  }

  build() {
    Stack({ alignContent: Alignment.Top }) {
      Scroll() {
        Column() {
          Column()
            .width('100%')
            .height(this.statusBarHeight + HOME_TITLE_HEIGHT + PAGE_CARD_GAP + SEARCH_BAR_HEIGHT + PAGE_CARD_GAP)

          Row() {
            Text(this.fmtDate(this.selectedDate))
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(ThemeColors.textPrimary)
              .layoutWeight(1)

            if (!this.isToday(this.selectedDate)) {
              Text('今')
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FFFFFF')
                .backgroundColor('#2979FF')
                .borderRadius(15)
                .width(30).height(30)
                .textAlign(TextAlign.Center)
                .onClick(() => { this.goToday(); })
            }
          }
          .width('100%')
          .padding({ left: HOME_HORIZONTAL_PADDING, right: HOME_HORIZONTAL_PADDING })

          Row() {
            Text('选择日期')
              .fontSize(14)
              .fontColor(ThemeColors.textSecondary)
            Blank()
            Text(this.fmtDate(this.selectedDate))
              .fontSize(14)
              .fontColor(ThemeColors.accent)
              .onClick(() => { this.showDatePicker(); })
          }
          .width('100%')
          .padding({ left: HOME_HORIZONTAL_PADDING, right: HOME_HORIZONTAL_PADDING, top: 6, bottom: 10 })
          .height(40)

          if (this.loading) {
            Column() {
              LoadingProgress().width(40).height(40).color('#2979FF')
              Text('加载日程...').fontSize(14).fontColor(ThemeColors.textSecondary).margin({ top: 12 })
            }
            .width('100%').height(200).justifyContent(FlexAlign.Center)
          } else if (this.permissionDenied) {
            Column() {
              Text('需要日历权限才能使用日程功能').fontSize(14).fontColor(ThemeColors.textSecondary)
              Text('点击重新授权')
                .fontSize(14).fontColor('#2979FF').margin({ top: 16 })
                .onClick(() => { this.ensurePermissionAndLoad(); })
            }
            .width('100%').height(200).justifyContent(FlexAlign.Center)
          } else if (this.events.length === 0) {
            Column() {
              Text('当天暂无日程').fontSize(14).fontColor(ThemeColors.textSecondary)
            }
            .width('100%').height(200).justifyContent(FlexAlign.Center)
          } else {
            ForEach(this.events, (item: ScheduleEvent) => {
              this.EventRow(item)
            }, (item: ScheduleEvent) => item.id.toString())
          }

          Blank().height(24)
        }
        .width('100%')
        .padding({ left: HOME_HORIZONTAL_PADDING, right: HOME_HORIZONTAL_PADDING, bottom: 24 })
      }
      .width('100%').height('100%')
      .align(Alignment.Top)
      .contentEndOffset(this.bottomRectHeight + HOME_NAV_HEIGHT + PAGE_CARD_GAP)
      .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
      .scrollBar(BarState.Off)
      .clip(false)

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
