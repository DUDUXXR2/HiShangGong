// MainPage.ets — 云上商工 主页（HDS 悬浮底栏）
// Tab: 首页 / 服务 / 消息 / 日程 / 我的
// 二级页（设置/账号安全等）用 Navigation 原生导航
import { HdsTabs, HdsTabsController, hdsMaterial } from '@kit.UIDesignKit';
import { SymbolGlyphModifier } from '@kit.ArkUI';
import { router } from '@kit.ArkUI';
import { ThemeColors } from '../utils/ThemeColors';
import { PreferenceUtil } from '../utils/PreferenceUtil';
import { SqgService } from '../services/SqgService';
import { HomeTab } from './tabs/HomeTab';
import { ServiceTab } from './tabs/ServiceTab';
import { MineTab } from './tabs/MineTab';
import { SettingsPage } from './SettingsPage';
import { AccountSecurityPage } from './AccountSecurityPage';
import { ServiceWebPage } from './ServiceWebPage';
import { ClassTablePage } from './ClassTablePage';
import { ProfileCenterPage } from './ProfileCenterPage';

const TAG = 'MainPage';

interface TabItem {
  normal: SymbolGlyphModifier;
  selected: SymbolGlyphModifier;
  label: string;
}

const TAB_CONFIG: TabItem[] = [
  {
    normal: new SymbolGlyphModifier($r('sys.symbol.house_fill'))
      .fontColor([$r('sys.color.ohos_id_color_bottom_tab_icon_off')]),
    selected: new SymbolGlyphModifier($r('sys.symbol.house_fill'))
      .fontColor([$r('sys.color.ohos_id_color_activated')]),
    label: '首页'
  },
  {
    normal: new SymbolGlyphModifier($r('sys.symbol.square_grid_2x2'))
      .fontColor([$r('sys.color.ohos_id_color_bottom_tab_icon_off')]),
    selected: new SymbolGlyphModifier($r('sys.symbol.square_grid_2x2'))
      .fontColor([$r('sys.color.ohos_id_color_activated')]),
    label: '服务'
  },
  {
    normal: new SymbolGlyphModifier($r('sys.symbol.message_fill'))
      .fontColor([$r('sys.color.ohos_id_color_bottom_tab_icon_off')]),
    selected: new SymbolGlyphModifier($r('sys.symbol.message_fill'))
      .fontColor([$r('sys.color.ohos_id_color_activated')]),
    label: '消息'
  },
  {
    normal: new SymbolGlyphModifier($r('sys.symbol.calendar'))
      .fontColor([$r('sys.color.ohos_id_color_bottom_tab_icon_off')]),
    selected: new SymbolGlyphModifier($r('sys.symbol.calendar'))
      .fontColor([$r('sys.color.ohos_id_color_activated')]),
    label: '日程'
  },
  {
    normal: new SymbolGlyphModifier($r('sys.symbol.person_fill'))
      .fontColor([$r('sys.color.ohos_id_color_bottom_tab_icon_off')]),
    selected: new SymbolGlyphModifier($r('sys.symbol.person_fill'))
      .fontColor([$r('sys.color.ohos_id_color_activated')]),
    label: '我的'
  }
]

@Entry
@Component
struct MainPage {
  @Provide('pageStack') pageStack: NavPathStack = new NavPathStack();
  @State currentIndex: number = 0;
  @State serviceTabFocus: number = 0;
  @StorageLink('theme_is_dark') themeIsDark: boolean = false;
  @StorageProp('statusBarHeight') statusBarHeight: number = 0;
  private hdsTabsController: HdsTabsController = new HdsTabsController();

  aboutToAppear(): void {
    if (!SqgService.getInstance().isLoggedIn()) {
      router.replaceUrl({ url: 'pages/login/LoginPage' });
      return;
    }
    SqgService.getInstance().refreshMineData().catch(() => {
    });
  }

  private logout(): void {
    SqgService.getInstance().clearUserData().catch(() => {
    });
    PreferenceUtil.putBool('is_logged_in', false);
    router.replaceUrl({ url: 'pages/login/LoginPage' });
  }

  // Navigation 二级页路由映射
  @Builder
  PageMap(name: string, param: object) {
    if (name === 'SettingsPage') {
      SettingsPage()
    } else if (name === 'AccountSecurityPage') {
      AccountSecurityPage()
    } else if (name === 'ServiceWebPage') {
      ServiceWebPage()
    } else if (name === 'ClassTablePage') {
      ClassTablePage()
    } else if (name === 'ProfileCenterPage') {
      ProfileCenterPage()
    }
  }

  @Builder
  PlaceholderTab(text: string) {
    Column() {
      Text(text).fontSize(16).fontColor(ThemeColors.textSecondary)
    }
    .width('100%').height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor(ThemeColors.bgPage)
  }

  build() {
    Navigation(this.pageStack) {
      Stack() {
        HdsTabs({ controller: this.hdsTabsController }) {
          TabContent() {
            HomeTab({ onMoreClick: (): void => {
              this.currentIndex = 1;
              this.hdsTabsController.changeIndex(1);
            }, onBellClick: (): void => {
              this.currentIndex = 2;
              this.hdsTabsController.changeIndex(2);
            } })
          }
          .tabBar(new BottomTabBarStyle({ normal: TAB_CONFIG[0].normal, selected: TAB_CONFIG[0].selected }, TAB_CONFIG[0].label))

          TabContent() {
            ServiceTab({ searchFocusSignal: this.serviceTabFocus })
          }
          .tabBar(new BottomTabBarStyle({ normal: TAB_CONFIG[1].normal, selected: TAB_CONFIG[1].selected }, TAB_CONFIG[1].label))

          TabContent() {
            this.PlaceholderTab('消息')
          }
          .tabBar(new BottomTabBarStyle({ normal: TAB_CONFIG[2].normal, selected: TAB_CONFIG[2].selected }, TAB_CONFIG[2].label))

          TabContent() {
            this.PlaceholderTab('日程')
          }
          .tabBar(new BottomTabBarStyle({ normal: TAB_CONFIG[3].normal, selected: TAB_CONFIG[3].selected }, TAB_CONFIG[3].label))

          TabContent() {
            MineTab()
          }
          .tabBar(new BottomTabBarStyle({ normal: TAB_CONFIG[4].normal, selected: TAB_CONFIG[4].selected }, TAB_CONFIG[4].label))
        }
        .barOverlap(true)
        .vertical(false)
        .barPosition(BarPosition.End)
        .barFloatingStyle({
          barBottomMargin: 16,
          adaptToHandedness: true,
          systemMaterialEffect: {
            materialType: hdsMaterial.MaterialType.ADAPTIVE,
            materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
          }
        })
        .onChange((index: number) => {
          this.currentIndex = index;
        })
        .expandSafeArea([SafeAreaType.SYSTEM, SafeAreaType.CUTOUT], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
        .backgroundColor(Color.Transparent)
        .width('100%')
        .height('100%')
      }
      .width('100%')
      .height('100%')
    }
    .navDestination(this.PageMap)
    .mode(NavigationMode.Stack)
    .hideTitleBar(true)
    .width('100%')
    .height('100%')
  }
}
