// MainPage.ets — Hi商工 主页（HdsNavigation 沉浸导航 + HdsTabs 底部导航）
// 沉浸式 UI：HdsNavigation 标题栏（系统材质+渐变模糊+深浅色）
import {
  HdsNavigation,
  HdsNavigationMenuContentOptions,
  HdsNavigationTitleMode,
  HdsTabs,
  HdsTabsController,
  ScrollEffectType,
  BlurStrategy,
  hdsMaterial
} from '@kit.UIDesignKit';
import { SymbolGlyphModifier } from '@kit.ArkUI';
import { router } from '@kit.ArkUI';
import { PreferenceUtil } from '../utils/PreferenceUtil';
import { SqgService } from '../services/SqgService';
import { MaterialConfig } from '../utils/MaterialConfig';
import { BackgroundManager, BackgroundLayer } from '../utils/BackgroundManager';
import { HomeTab } from './tabs/HomeTab';
import { ServiceTab } from './tabs/ServiceTab';
import { MessageTab } from './tabs/MessageTab';
import { ScheduleTab } from './tabs/ScheduleTab';
import { MineTab } from './tabs/MineTab';
import { SettingsPage } from './SettingsPage';
import { AccountSecurityPage } from './AccountSecurityPage';
import { ServiceWebPage } from './ServiceWebPage';
import { ClassTablePage } from './ClassTablePage';
import { ProfileCenterPage } from './ProfileCenterPage';
import { AppearancePage } from './AppearancePage';
import { DeclarationPage } from './DeclarationPage';

const TAG = 'MainPage';

const HOME_TITLE_HEIGHT: number = 56;

interface TabItem {
  normal: SymbolGlyphModifier;
  selected: SymbolGlyphModifier;
  label: string;
}

interface TabSymbolItem {
  symbol: Resource;
  label: string;
}

const TAB_ITEMS: TabSymbolItem[] = [
  { symbol: $r('sys.symbol.house'), label: '首页' },
  { symbol: $r('sys.symbol.square_grid_2x2'), label: '服务' },
  { symbol: $r('sys.symbol.message'), label: '消息' },
  { symbol: $r('sys.symbol.calendar'), label: '日程' },
  { symbol: $r('sys.symbol.person'), label: '我的' }
]

@Entry
@Component
struct MainPage {
  @Provide('pageStack') pageStack: NavPathStack = new NavPathStack();
  @State currentIndex: number = 0;
  @State serviceTabFocus: number = 0;
  @StorageLink('theme_is_dark') themeIsDark: boolean = false;
  @StorageProp('statusBarHeight') statusBarHeight: number = 0;
  @StorageProp('home_switch_tab_signal') @Watch('onHomeSwitchTabSignal') homeSwitchTabSignal: number = 0;
  @StorageProp('ui_material_version') materialVersion: number = 0;
  private hdsTabsController: HdsTabsController = new HdsTabsController();

  // 首页"更多"按钮发来信号：切到对应 Tab（index 1 = 服务）
  private onHomeSwitchTabSignal(): void {
    const target: number = this.homeSwitchTabSignal;
    if (target <= 0) {
      return;
    }
    try {
      this.hdsTabsController.changeIndex(target);
    } catch (e) {
    }
    AppStorage.setOrCreate<number>('home_switch_tab_signal', 0);
  }

  // 按当前 tab 返回标题栏标题（"我的"页显示"我的"）
  private currentHomeTitle(): string {
    const titles: string[] = ['Hi商工', '服务', '消息', '日程', '我的'];
    return titles[this.currentIndex];
  }

  // 移除右上角设置菜单
  private homeMenu(): HdsNavigationMenuContentOptions {
    return { value: [], maxCount: 0 };
  }

  // 底栏图标颜色：浅色模式未选中用纯黑（原灰色看不清），选中用系统强调色；深色模式用系统色
  private tabItems(): TabItem[] {
    const items: TabItem[] = [];
    for (let i = 0; i < TAB_ITEMS.length; i++) {
      const normalColor: ResourceColor = this.themeIsDark
        ? '#FFFFFF'
        : '#000000';
      const normal = new SymbolGlyphModifier(TAB_ITEMS[i].symbol).fontColor([normalColor]);
      const selected = new SymbolGlyphModifier(TAB_ITEMS[i].symbol)
        .fontColor([$r('sys.color.ohos_id_color_activated')]);
      const item: TabItem = { normal: normal, selected: selected, label: TAB_ITEMS[i].label };
      items.push(item);
    }
    return items;
  }

  private configuredMaterialType(): hdsMaterial.MaterialType {
    return MaterialConfig.configuredMaterialType();
  }

  private configuredMaterialLevel(): hdsMaterial.MaterialLevel {
    return MaterialConfig.configuredMaterialLevel();
  }

  aboutToAppear(): void {
    if (!SqgService.getInstance().isLoggedIn()) {
      router.replaceUrl({ url: 'pages/login/LoginPage' });
      return;
    }
    SqgService.getInstance().refreshMineData().catch(() => {
    });
  }

  private async logout(): Promise<void> {
    await SqgService.getInstance().logout();
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
    } else if (name === 'AppearancePage') {
      AppearancePage()
    } else if (name === 'DeclarationPage') {
      DeclarationPage()
    }
  }

  @Builder
  build() {
    Stack() {
      BackgroundLayer()
      HdsNavigation(this.pageStack) {
        HdsTabs({ controller: this.hdsTabsController }) {
          TabContent() {
            HomeTab()
          }
          .tabBar(new BottomTabBarStyle({ normal: this.tabItems()[0].normal, selected: this.tabItems()[0].selected }, this.tabItems()[0].label))

          TabContent() {
            ServiceTab({ searchFocusSignal: this.serviceTabFocus })
          }
          .tabBar(new BottomTabBarStyle({ normal: this.tabItems()[1].normal, selected: this.tabItems()[1].selected }, this.tabItems()[1].label))

          TabContent() {
            MessageTab()
          }
          .tabBar(new BottomTabBarStyle({ normal: this.tabItems()[2].normal, selected: this.tabItems()[2].selected }, this.tabItems()[2].label))

          TabContent() {
            ScheduleTab()
          }
          .tabBar(new BottomTabBarStyle({ normal: this.tabItems()[3].normal, selected: this.tabItems()[3].selected }, this.tabItems()[3].label))

          TabContent() {
            MineTab()
          }
          .tabBar(new BottomTabBarStyle({ normal: this.tabItems()[4].normal, selected: this.tabItems()[4].selected }, this.tabItems()[4].label))
        }
        .barOverlap(true)
        .vertical(false)
        .barPosition(BarPosition.End)
        .scrollable(false)
        .barBackgroundStyle({ maskColor: '#00000000' })
        .barBackgroundBlurStyle(BlurStyle.NONE)
        .barFloatingStyle({
          barBottomMargin: 24,
          adaptToHandedness: true,
          systemMaterialEffect: {
            materialType: this.configuredMaterialType(),
            materialLevel: this.configuredMaterialLevel()
          }
        })
        .onChange((index: number) => {
          this.currentIndex = index;
        })
        .backgroundColor(Color.Transparent)
        .width('100%')
        .height('100%')
      }
      .mode(NavigationMode.Stack)
      .titleBar({
        content: {
          title: {
            mainTitle: this.currentHomeTitle()
          },
          menu: this.homeMenu()
        },
        style: {
          scrollEffectOpts: {
            enableScrollEffect: false,
            scrollEffectType: ScrollEffectType.GRADIENT_BLUR
          },
          blurStrategy: BlurStrategy.ADAPTIVE,
          originalStyle: { backgroundStyle: { backgroundColor: '#00ffffff' } },
          scrollEffectStyle: { backgroundStyle: { backgroundColor: '#00ffffff' } },
          systemMaterialEffect: {
            materialType: this.configuredMaterialType(),
            materialLevel: this.configuredMaterialLevel()
          }
        },
        avoidLayoutSafeArea: true,
        enableComponentSafeArea: false
      })
      .navDestination(this.PageMap)
      .hideBackButton(true)
      .titleMode(HdsNavigationTitleMode.MINI)
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Transparent)
  }
}
