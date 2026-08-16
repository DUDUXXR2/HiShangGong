# 云上商工 · UI 设计规范与开发文档

> 适用：HarmonyOS NEXT 原生 App，ArkTS + ArkUI，API 26（targetSdkVersion 26.0.0）。
> 设计语言：**沉浸光感（Immersive Light）**，移植自 Authenticator-main 开源项目，HDS（Huawei Design System）组件体系。
> 工程位置：`E:\YSSG`。本文档结合项目真实源码，给出可直接复用的组件与页面模式。

---

## 目录

1. [设计规范总览](#1-设计规范总览)
2. [颜色与主题](#2-颜色与主题)
3. [沉浸光感材质](#3-沉浸光感材质)
4. [玻璃卡片](#4-玻璃卡片)
5. [悬浮搜索框（页面模式）](#5-悬浮搜索框页面模式)
6. [沉浸式二级页导航（返回按钮）](#6-沉浸式二级页导航返回按钮)
7. [首页快捷操作网格](#7-首页快捷操作网格)
8. [沉浸按钮（ImmersionButton）](#8-沉浸按钮immersionbutton)
9. [Tab 架构（主页面）](#9-tab-架构主页面)
10. [消息页（公告列表）](#10-消息页公告列表)
11. [日程页（系统日历）](#11-日程页系统日历)
12. [背景系统（背景图管理）](#12-背景系统背景图管理)
13. [网络层与登录态](#13-网络层与登录态)
14. [开发规范与最佳实践](#14-开发规范与最佳实践)

---

## 1. 设计规范总览

### 1.1 设计原则

| 原则 | 说明 |
|---|---|
| **沉浸光感** | 所有卡片/导航栏默认使用系统材质（`systemMaterialEffect`），关闭时回退纯色 |
| **深浅色自适应** | 所有颜色经 `ThemeColors` 读取，随系统/手动主题切换 |
| **悬浮优先** | 搜索框、返回按钮等导航元素悬浮于内容之上，内容滚动从其下方穿过（毛玻璃透出） |
| **按压反馈** | 可点击卡片统一 `scale(0.92~0.97)` + `Curve.Friction` 按压动画 |
| **玻璃光感** | 卡片背景在沉浸材质开启时透明、带 `0.5` 边框；关闭时纯色 |

### 1.2 关键常量

```ts
// 布局常量（各页面统一）
const HOME_TITLE_HEIGHT: number = 56;        // 标题栏高度
const HOME_NAV_HEIGHT: number = 52;          // 底部导航高度
const PAGE_CARD_GAP: number = 10;            // 卡片间距
const HOME_HORIZONTAL_PADDING: number = 20;  // 页面水平内边距
const SEARCH_BAR_HEIGHT: number = 44;        // 搜索框高度

// 交互常量（按压动画）
const CARD_PRESS_ANIMATION_DURATION: number = 160;   // 按压动画时长 ms
const CARD_PRESSED_SCALE: number = 0.97;             // 按压缩放比例（卡片级）
```

### 1.3 页面结构约定

```
NavDestination / Tab
└── Stack(alignContent: Alignment.Top)
    ├── BackgroundLayer()          // 全局背景层（可选，放最底）
    ├── 内容滚动区（全屏，clip(false)）// 从悬浮元素下方穿过
    └── 悬浮元素（.position() + .zIndex(12)）// 搜索框/返回按钮
```

---

## 2. 颜色与主题

### 2.1 ThemeColors（主题色表）

所有颜色统一走 `utils/ThemeColors.ets`，读取 `_isDark`（来自 `@StorageLink('theme_is_dark')`），随系统/手动模式切换：

```ts
export class ThemeColors {
  static get isDark(): boolean { return _isDark; }

  static get bgPage(): string        { return _isDark ? '#0F0F11' : '#F5F5F5'; }
  static get bgCard(): string        { return _isDark ? '#1C1C1E' : '#FFFFFF'; }
  static get bgInput(): string       { return _isDark ? '#2C2C2E' : '#F0F0F0'; }
  static get border(): string        { return _isDark ? '#38383A' : '#E8E8E8'; }
  static get textPrimary(): string   { return _isDark ? '#E5E5E5' : '#1A1A1A'; }
  static get textSecondary(): string { return _isDark ? '#999999' : '#666666'; }
  static get textHint(): string      { return _isDark ? '#666666' : '#999999'; }
  static get accent(): string        { return (AppStorage.get('accent_color') as string) ?? '#2979FF'; }
  static get success(): string       { return _isDark ? '#81C784' : '#2E7D32'; }
  static get error(): string         { return _isDark ? '#EF9A9A' : '#C62828'; }
  static get warning(): string       { return _isDark ? '#FFB74D' : '#BF4D00'; }
  static get tabBar(): string        { return _isDark ? '#2C2C2EDD' : '#FFFFFFFF'; }
  static get overlay(): string       { return _isDark ? '#80000000' : '#40000000'; }

  /** 根据背景色亮度返回合适前景色 */
  static textOnColor(hex: string): string {
    if (hex.length < 7) return '#FFFFFF';
    const r = parseInt(hex.substring(1, 3), 16);
    const g = parseInt(hex.substring(3, 5), 16);
    const b = parseInt(hex.substring(5, 7), 16);
    const lum = (0.299 * r + 0.587 * g + 0.114 * b) / 255;
    return lum > 0.6 ? '#1A1A1A' : '#FFFFFF';
  }
}
```

### 2.2 使用规范

- **禁止硬编码颜色**，一律 `ThemeColors.textPrimary` / `ThemeColors.bgCard` 等。
- 强调色用 `ThemeColors.accent`（默认 `#2979FF`，可在设置里改）。
- 文字置于强调色上时用 `ThemeColors.textOnColor(accent)` 计算黑/白。

### 2.3 主题初始化（EntryAbility/Index）

在 `Index.aboutToAppear` 调用：

```ts
ThemeColors.init(savedMode, getContext(this));
```

切换主题：

```ts
// 手动浅色/深色
ThemeColors.applyManual(ConfigurationConstant.ColorMode.COLOR_MODE_DARK, ctx);
// 跟随系统
ThemeColors.applyFollowSystem(ctx);
```

---

## 3. 沉浸光感材质

### 3.1 MaterialConfig（全局材质配置）

`utils/MaterialConfig.ets` 统一管理沉浸光感开关、材质类型/等级，状态存 AppStorage，供设置页与全局组件读写：

```ts
import { hdsMaterial, SystemMaterialParams } from '@kit.UIDesignKit';

export class MaterialConfig {
  // 全局沉浸光感开关（默认开）
  static globalImmersionEnabled(): boolean {
    return AppStorage.get<boolean>('ui_global_immersion') ?? true;
  }

  // 材质类型 → 枚举（自适应/沉浸/无材质）
  static configuredMaterialType(): hdsMaterial.MaterialType {
    const name: string = MaterialConfig.materialTypeName();
    if (name === '沉浸') return hdsMaterial.MaterialType.IMMERSIVE;
    if (name === '无材质') return hdsMaterial.MaterialType.NONE;
    return hdsMaterial.MaterialType.ADAPTIVE;
  }

  // 材质等级 → 枚举（自适应/精致/柔和/平滑）
  static configuredMaterialLevel(): hdsMaterial.MaterialLevel {
    const name: string = MaterialConfig.materialLevelName();
    if (name === '精致') return hdsMaterial.MaterialLevel.EXQUISITE;
    if (name === '柔和') return hdsMaterial.MaterialLevel.GENTLE;
    if (name === '平滑') return hdsMaterial.MaterialLevel.SMOOTH;
    return hdsMaterial.MaterialLevel.ADAPTIVE;
  }

  // 卡片是否使用玻璃（光感材质）
  static shouldUseCardMaterial(): boolean {
    return MaterialConfig.globalImmersionEnabled() &&
      MaterialConfig.configuredMaterialType() !== hdsMaterial.MaterialType.NONE;
  }

  // 系统组件（返回按钮/导航栏）材质参数：沉浸关闭时回退无材质
  static systemMaterialEffectParams(): SystemMaterialParams {
    return {
      materialType: MaterialConfig.shouldUseCardMaterial()
        ? MaterialConfig.configuredMaterialType()
        : hdsMaterial.MaterialType.NONE,
      materialLevel: MaterialConfig.configuredMaterialLevel()
    };
  }
}
```

### 3.2 systemMaterialEffect 用法

设置页"外观与主题 → 高级材质"可调：
- **全局沉浸光感**：开关
- **材质类型**：自适应 / 沉浸 / 无材质
- **材质等级**：自适应 / 精致 / 柔和 / 平滑

所有使用材质的组件统一传入 `MaterialConfig.systemMaterialEffectParams()` 或 `configuredMaterialType()/configuredMaterialLevel()`。

---

## 4. 玻璃卡片

### 4.1 GlassCard（通用玻璃容器）

`components/GlassCard.ets` — 复刻 MineTab 的 `ImmersionCardSurface`，带内容区：

```ts
// GlassCard.ets
import { HdsTabs, hdsMaterial } from '@kit.UIDesignKit';
import { ThemeColors } from '../utils/ThemeColors';
import { MaterialConfig } from '../utils/MaterialConfig';

@Component
export struct GlassCard {
  @Prop cardHeight: number = 60;
  @Prop cardRadius: number = 15;
  @BuilderParam content: () => void = this.defaultContent;

  @Builder defaultContent() { Column().width('100%') }

  private isDark(): boolean { return ThemeColors.isDark; }
  private cardBackgroundColor(): string { return this.isDark() ? '#191919' : '#FFFFFF'; }
  private cardSurfaceBaseColor(fallback: ResourceColor): ResourceColor {
    return MaterialConfig.shouldUseCardMaterial() ? Color.Transparent : fallback;
  }
  private cardSurfaceBorderWidth(): number {
    return MaterialConfig.shouldUseCardMaterial() ? 0.5 : 0;
  }
  private immersionBorderColor(): ResourceColor {
    return this.isDark() ? '#80FFFFFF' : '#80000000';
  }

  // 光感材质层（HdsTabs 的 barFloatingStyle 实现毛玻璃 + 沉浸光感）
  @Builder
  MaterialLayer(cardHeight: number, cardRadius: number) {
    Stack({ alignContent: Alignment.Center }) {
      HdsTabs() {
        TabContent() {}.backdropBlur(0).tabBar(this.MaterialContent(cardHeight)).clip(false)
      }
      .width(600 + cardHeight * 2).height(cardHeight)
      .barWidth(600 + cardHeight * 2).barHeight(cardHeight)
      .barOverlap(true).barPosition(BarPosition.End)
      .barBackgroundStyle({ maskColor: '#00000000' })
      .barBackgroundBlurStyle(BlurStyle.NONE)
      .barFloatingStyle({
        barBottomMargin: 0,
        systemMaterialEffect: {
          materialType: MaterialConfig.configuredMaterialType(),
          materialLevel: MaterialConfig.configuredMaterialLevel()
        },
        gradientMask: { maskColor: '#09999999' }
      })
      .backgroundColor(Color.Transparent).hitTestBehavior(HitTestMode.None).clip(false)
    }
    .width('100%').height(cardHeight).borderRadius(cardRadius).clip(true)
    .backgroundColor(Color.Transparent).hitTestBehavior(HitTestMode.None).zIndex(1)
  }

  build() {
    Stack({ alignContent: Alignment.Top }) {
      this.MaterialLayer(this.cardHeight, this.cardRadius)
      Stack() { this.content() }
        .width('100%').height(this.cardHeight).alignContent(Alignment.Top).zIndex(2)
    }
    .width('100%').height(this.cardHeight).borderRadius(this.cardRadius).clip(true)
    .backgroundColor(this.cardSurfaceBaseColor(this.cardBackgroundColor()))
    .border({ width: this.cardSurfaceBorderWidth(), color: this.immersionBorderColor() })
  }
}
```

**用法**：

```ts
GlassCard({ cardHeight: 84, cardRadius: 16 }) {
  // 卡片内容（图标按钮等）
  Column() {
    Image($r('app.media.ic_bolt')).width(30).height(30)
    Text('缴电费').fontSize(11).margin({ top: 8 })
  }
  .width('100%').alignItems(HorizontalAlign.Center)
}
```

### 4.2 按压动画（可点击卡片）

可点击卡片统一加按压反馈（来自 MineTab/SettingRowCard）：

```ts
@State pressed: boolean = false;

private handleTouch(type: TouchType): void {
  if (type === TouchType.Down) this.pressed = true;
  else if (type === TouchType.Up || type === TouchType.Cancel) this.pressed = false;
}

// build 里
Stack() { /* 卡片内容 */ }
  .scale({ x: this.pressed ? CARD_PRESSED_SCALE : 1, y: this.pressed ? CARD_PRESSED_SCALE : 1 })
  .animation({ duration: CARD_PRESS_ANIMATION_DURATION, curve: Curve.Friction })
  .onTouch((e: TouchEvent) => { this.handleTouch(e.type); })
  .onClick(() => { this.action(); })
```

---

## 5. 悬浮搜索框（页面模式）

### 5.1 原理

参考 Authenticator-main：**Stack 容器**内，内容全屏滚动、搜索框用 `.position()` 绝对定位 + `.zIndex(12)` 悬浮。内容滚动从搜索框下方穿过，透过毛玻璃隐约可见。

### 5.2 完整源码（HomeTab 模式）

```ts
// 常量
const HOME_TITLE_HEIGHT: number = 56;
const PAGE_CARD_GAP: number = 10;
const HOME_HORIZONTAL_PADDING: number = 20;
const SEARCH_BAR_HEIGHT: number = 44;
const HOME_NAV_HEIGHT: number = 52;

@Builder
SearchBar() {
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
  .width('100%').height(SEARCH_BAR_HEIGHT)
  .borderRadius(SEARCH_BAR_HEIGHT / 2)
  .padding({ left: 16, right: 16 })
  .systemMaterial(new uiMaterial.ImmersiveMaterial({
    style: uiMaterial.ImmersiveStyle.THIN,
    interactive: true,
    lightEffect: { color: undefined }
  }))
}

build() {
  Stack({ alignContent: Alignment.Top }) {
    // 内容滚动区（全屏，clip(false) 让内容从搜索框下方穿过）
    Scroll() {
      Column() {
        // 内容（快捷卡片 / 列表）
      }
      .width('100%')
      .padding({ left: HOME_HORIZONTAL_PADDING, right: HOME_HORIZONTAL_PADDING, bottom: 24 })
    }
    .width('100%').height('100%')
    .align(Alignment.Top)   // 关键：内容顶端对齐，否则被垂直居中
    .padding({
      top: this.statusBarHeight + HOME_TITLE_HEIGHT + PAGE_CARD_GAP + SEARCH_BAR_HEIGHT + PAGE_CARD_GAP
    })
    .contentEndOffset(this.bottomRectHeight + HOME_NAV_HEIGHT + PAGE_CARD_GAP)
    .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
    .scrollBar(BarState.Off)
    .clip(false)            // 关键：不裁剪，内容可穿到悬浮搜索框下方

    // 悬浮搜索框
    Row() { this.SearchBar() }
      .width('100%')
      .padding({ left: HOME_HORIZONTAL_PADDING, right: HOME_HORIZONTAL_PADDING })
      .position({ x: 0, y: this.statusBarHeight + HOME_TITLE_HEIGHT + PAGE_CARD_GAP })
      .zIndex(12)           // 关键：悬浮在内容之上
  }
  .width('100%').height('100%')
  .backgroundColor(Color.Transparent)
}
```

### 5.3 关键点

| 要素 | 作用 |
|---|---|
| `.align(Alignment.Top)` | 内容顶端对齐，避免矮内容被垂直居中 |
| `.clip(false)` | 内容溢出可穿过悬浮元素下方（毛玻璃透出） |
| `.position()` + `.zIndex(12)` | 搜索框悬浮于内容之上 |
| 顶部 `.padding` | 内容初始避让搜索框高度，从搜索框下方开始 |

---

## 6. 沉浸式二级页导航（返回按钮）

### 6.1 HdsNavigation MINI 模式

二级页（设置/账号安全/外观/个人中心/H5 网页）用 **NavDestination 内嵌 `HdsNavigation()`**，MINI 模式渲染圆形悬浮返回按钮 + 标题，支持毛玻璃 + 按压发光：

```ts
import { HdsNavigation, HdsNavigationTitleMode, ScrollEffectType, BlurStrategy } from '@kit.UIDesignKit';

build() {
  NavDestination() {
    Stack({ alignContent: Alignment.Top }) {
      BackgroundLayer()
      HdsNavigation() {
        // 页面内容（Scroll/WaterFlow/Web）
        Scroll() { /* ... */ }
          .width('100%').height('100%')
          .align(Alignment.Top)
          .scrollBar(BarState.Off)
          .contentStartOffset(this.statusBarHeight + HOME_TITLE_HEIGHT + PAGE_CARD_GAP)
      }
      .mode(NavigationMode.Stack)
      .titleBar({
        content: {
          title: { mainTitle: '页面标题' },
          backIcon: { action: (): void => { this.pageStack.pop(); } }   // 自定义返回
        },
        style: {
          scrollEffectOpts: {
            enableScrollEffect: false,
            scrollEffectType: ScrollEffectType.GRADIENT_BLUR
          },
          blurStrategy: BlurStrategy.ADAPTIVE,
          originalStyle: { backgroundStyle: { backgroundColor: '#00ffffff' } },
          scrollEffectStyle: { backgroundStyle: { backgroundColor: '#00ffffff' } },
          systemMaterialEffect: MaterialConfig.systemMaterialEffectParams()   // 沉浸光感
        },
        avoidLayoutSafeArea: true,
        enableComponentSafeArea: false
      })
      .hideBackButton(false)
      .titleMode(HdsNavigationTitleMode.MINI)
      .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP])
      .width('100%').height('100%')
    }
    .width('100%').height('100%')
  }
  .hideTitleBar(true)
  .backgroundColor(BackgroundManager.pageBackgroundColor(this.themeIsDark))
}
```

### 6.2 关键点

- `titleMode(HdsNavigationTitleMode.MINI)`：圆形悬浮返回按钮 + 标题，无传统长条导航栏。
- `backIcon.action`：自定义返回逻辑（如 H5 网页先退 Web 历史再 pop）。
- `systemMaterialEffect`：毛玻璃 + 按压发光，由设置页"全局沉浸光感"控制。
- 内容用 `.contentStartOffset(statusBarHeight + HOME_TITLE_HEIGHT + PAGE_CARD_GAP)` 避让悬浮标题栏。

### 6.3 H5 网页返回（Web 后退优先）

```ts
private goBack(): void {
  try {
    if (this.webController.accessBackward()) {
      this.webController.backward();   // Web 内有历史先退
      return;
    }
  } catch (e) {}
  this.pageStack.pop();                // 无历史再退出页面
}
```

`NavDestination.onBackPressed` 拦截系统返回手势：

```ts
.onBackPressed(() => { this.goBack(); return true; })
```

---

## 7. 首页快捷操作网格

### 7.1 QuickActionGrid（图标按钮网格）

`components/QuickActionGrid.ets` — 两行玻璃卡片，每行若干图标按钮：

```ts
export class QuickActionItem {
  label: string = '';
  icon: Resource = $r('app.media.ic_public_more');
  iconUrl: string = '';   // 服务列表下发的真实图标（与服务页一致）
}

@Component
export struct QuickActionGrid {
  @Prop row1: QuickActionItem[] = [];
  @Prop row2: QuickActionItem[] = [];
  onAction: (label: string) => void = () => {};

  @Builder
  ActionRow(items: QuickActionItem[]) {
    Row() {
      ForEach(items, (item: QuickActionItem, idx: number) => {
        Column() {
          if (item.iconUrl.length > 0) {
            Image(item.iconUrl).width(30).height(30).objectFit(ImageFit.Contain)
          } else {
            Image(item.icon).width(30).height(30).fillColor('#2979FF').objectFit(ImageFit.Contain)
          }
          Text(item.label)
            .fontSize(11).fontColor(ThemeColors.textPrimary)
            .margin({ top: 8 }).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width('100%').layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
        .padding({ top: 12, bottom: 12 })
        .onClick(() => { this.onAction(item.label); })
      }, (item: QuickActionItem, idx: number) => item.label + '_' + idx.toString())
    }
    .width('100%').alignItems(VerticalAlign.Center)
  }

  build() {
    Column({ space: 10 }) {
      GlassCard({ cardHeight: 84, cardRadius: 16 }) { this.ActionRow(this.row1) }
      GlassCard({ cardHeight: 84, cardRadius: 16 }) { this.ActionRow(this.row2) }
    }
    .width('100%')
  }
}
```

### 7.2 按钮动作分发

```ts
private handleAction(label: string): void {
  if (label === '扫一扫') { this.openScanner(); return; }
  if (label === '更多') {
    // 切到服务 Tab（AppStorage 信号，由 MainPage 主线程切换，避免控制器空指针崩溃）
    AppStorage.setOrCreate<number>('home_switch_tab_signal', 1);
    return;
  }
  if (label === '学生课表查询' || label === '教室课表查询') {
    this.pageStack.pushPathByName('ClassTablePage', undefined);
    return;
  }
  const svc = this.findService(label);          // 从服务列表按名字匹配真实地址
  if (svc !== undefined) { this.openService(svc); return; }
  this.openH5(label);                            // 兜底打开 H5 首页
}
```

### 7.3 Tab 切换（避免控制器崩溃）

**不要**把 `HdsTabsController` 通过 `@Provide/@Consume` 传给子组件调用 `changeIndex()`（会原生空指针崩溃）。改用 **AppStorage 信号 + @Watch**：

```ts
// HomeTab 发信号
AppStorage.setOrCreate<number>('home_switch_tab_signal', 1);

// MainPage 收信号（控制器绑定处调用）
@StorageProp('home_switch_tab_signal') @Watch('onHomeSwitchTabSignal') homeSwitchTabSignal: number = 0;
private hdsTabsController: HdsTabsController = new HdsTabsController();

private onHomeSwitchTabSignal(): void {
  const target: number = this.homeSwitchTabSignal;
  if (target <= 0) return;
  try { this.hdsTabsController.changeIndex(target); } catch (e) {}
  AppStorage.setOrCreate<number>('home_switch_tab_signal', 0);
}
```

---

## 8. 沉浸按钮（ImmersionButton）

来自 `@tangs/components`，配合 `ActionButtonModifier` 实现沉浸光感按钮：

```ts
import { ImmersionButton } from '@tangs/components';
import { ActionButtonModifier } from '../components/ImmersionActionButton';
import { MaterialConfig } from '../utils/MaterialConfig';

Stack({ alignContent: Alignment.Center }) {
  ImmersionButton({
    systemMaterialEffect: {
      materialType: MaterialConfig.configuredMaterialType(),
      materialLevel: MaterialConfig.configuredMaterialLevel()
    },
    buttonModify: new ActionButtonModifier('100%', 48, '#2979FF', '#2979FF'),
    click: (): void => { this.doLogin(); }
  }) {
    Text('登录').fontSize(16).fontWeight(FontWeight.Medium).fontColor('#FFFFFF')
  }
}
.width('100%').height(48).borderRadius(24).clip(false)
```

`ActionButtonModifier`：

```ts
// components/ActionButtonModifier.ets
import { ButtonModifier } from '@ohos.arkui.modifier';

export class ActionButtonModifier implements AttributeModifier<ButtonModifier> {
  constructor(
    private buttonWidth: Length,
    private buttonHeight: number,
    private fillColor: ResourceColor,
    private strokeColor: ResourceColor
  ) {}

  applyNormalAttribute(instance: ButtonModifier): void {
    instance.width(this.buttonWidth).height(this.buttonHeight)
      .backgroundColor(this.fillColor).border({ width: 0.5, color: this.strokeColor });
  }
}
```

---

## 9. Tab 架构（主页面）

### 9.1 MainPage（根容器）

```ts
@Entry
@Component
struct MainPage {
  @Provide('pageStack') pageStack: NavPathStack = new NavPathStack();
  @State currentIndex: number = 0;
  @State serviceTabFocus: number = 0;
  @StorageLink('theme_is_dark') themeIsDark: boolean = false;
  @StorageProp('statusBarHeight') statusBarHeight: number = 0;
  private hdsTabsController: HdsTabsController = new HdsTabsController();

  build() {
    Stack() {
      BackgroundLayer()
      HdsNavigation(this.pageStack) {
        HdsTabs({ controller: this.hdsTabsController }) {
          TabContent() { HomeTab() }
            .tabBar(new BottomTabBarStyle({ normal: TAB_CONFIG[0].normal, selected: TAB_CONFIG[0].selected }, TAB_CONFIG[0].label))
          TabContent() { ServiceTab({ searchFocusSignal: this.serviceTabFocus }) }
            .tabBar(new BottomTabBarStyle({ normal: TAB_CONFIG[1].normal, selected: TAB_CONFIG[1].selected }, TAB_CONFIG[1].label))
          TabContent() { MessageTab() }
            .tabBar(new BottomTabBarStyle({ normal: TAB_CONFIG[2].normal, selected: TAB_CONFIG[2].selected }, TAB_CONFIG[2].label))
          TabContent() { ScheduleTab() }
            .tabBar(new BottomTabBarStyle({ normal: TAB_CONFIG[3].normal, selected: TAB_CONFIG[3].selected }, TAB_CONFIG[3].label))
          TabContent() { MineTab() }
            .tabBar(new BottomTabBarStyle({ normal: TAB_CONFIG[4].normal, selected: TAB_CONFIG[4].selected }, TAB_CONFIG[4].label))
        }
        .barOverlap(true).vertical(false).barPosition(BarPosition.End).scrollable(false)
        .barFloatingStyle({
          barBottomMargin: 16, adaptToHandedness: true,
          systemMaterialEffect: {
            materialType: this.configuredMaterialType(),
            materialLevel: this.configuredMaterialLevel()
          }
        })
        .onChange((index: number) => { this.currentIndex = index; })
        .backgroundColor(Color.Transparent).width('100%').height('100%')
      }
      .mode(NavigationMode.Stack)
      .titleBar({
        content: {
          title: { mainTitle: this.currentHomeTitle() },
          menu: { value: [], maxCount: 0 }
        },
        style: {
          scrollEffectOpts: { enableScrollEffect: false, scrollEffectType: ScrollEffectType.GRADIENT_BLUR },
          blurStrategy: BlurStrategy.ADAPTIVE,
          originalStyle: { backgroundStyle: { backgroundColor: '#00ffffff' } },
          scrollEffectStyle: { backgroundStyle: { backgroundColor: '#00ffffff' } },
          systemMaterialEffect: {
            materialType: this.configuredMaterialType(),
            materialLevel: this.configuredMaterialLevel()
          }
        },
        avoidLayoutSafeArea: true, enableComponentSafeArea: false
      })
      .navDestination(this.PageMap)
      .hideBackButton(true)
      .titleMode(HdsNavigationTitleMode.MINI)
      .width('100%').height('100%')
    }
    .width('100%').height('100%').backgroundColor(Color.Transparent)
  }
}
```

### 9.2 二级页路由映射

```ts
@Builder
PageMap(name: string, param: object) {
  if (name === 'SettingsPage') { SettingsPage() }
  else if (name === 'AccountSecurityPage') { AccountSecurityPage() }
  else if (name === 'ServiceWebPage') { ServiceWebPage() }
  else if (name === 'ClassTablePage') { ClassTablePage() }
  else if (name === 'ProfileCenterPage') { ProfileCenterPage() }
  else if (name === 'AppearancePage') { AppearancePage() }
}
```

跳转：

```ts
this.pageStack.pushPathByName('ServiceWebPage', new WebPageParam('校园卡', url));
this.pageStack.pushPathByName('SettingsPage', undefined);
```

---

## 10. 消息页（公告列表）

复用 `SqgService.getAnnouncements()` 真实接口（CMS 公告），布局与主页一致的悬浮搜索框：

```ts
class Announcement {
  title: string = '';
  publishTime: string = '';
  content: string = '';
}

// 加载
private async loadAnnouncements(): Promise<void> {
  try {
    const list = await SqgService.getInstance().getAnnouncements(1, 20);
    const items: Announcement[] = [];
    if (list) {
      for (let i = 0; i < list.length; i++) {
        const it = this.parseAnnouncement(list[i]);
        if (it.title.length > 0) items.push(it);
      }
    }
    this.announcements = items;
  } catch (e) { this.loadError = String(e); }
}

// 解析字段（title / publishTime / summary）
private parseAnnouncement(raw: object): Announcement {
  const obj = raw as Record<string, Object>;
  const it = new Announcement();
  const title = obj['title'] ?? obj['contentTitle'];
  const time = obj['publishTime'] ?? obj['createTime'] ?? obj['time'];
  const content = obj['summary'] ?? obj['contentSummary'] ?? obj['content'];
  it.title = title === undefined ? '' : String(title);
  it.publishTime = time === undefined ? '' : this.formatTime(String(time));
  it.content = content === undefined ? '' : String(content);
  return it;
}
```

列表项用 `ThemeColors.bgCard` 玻璃卡片：标题（最多2行）+ 摘要 + 时间。

---

## 11. 日程页（系统日历）

接入 `@kit.CalendarKit` 系统日历，支持读取/添加/删除。权限已在 `module.json5` 声明（READ/WRITE_CALENDAR，带 reason/usedScene）。

```ts
import { calendarManager } from '@kit.CalendarKit';
import { abilityAccessCtrl, bundleManager } from '@kit.AbilityKit';

// 检查权限
private async hasCalendarPermission(): Promise<boolean> {
  const atManager = abilityAccessCtrl.createAtManager();
  const bundleInfo = await bundleManager.getBundleInfoForSelf(
    bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
  const status = await atManager.checkAccessToken(
    bundleInfo.appInfo.accessTokenId, 'ohos.permission.READ_CALENDAR');
  return status === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
}

// 申请权限
private async requestCalendarPermission(): Promise<boolean> {
  const atManager = abilityAccessCtrl.createAtManager();
  const ctx = this.getUIContext().getHostContext();
  const result = await atManager.requestPermissionsFromUser(ctx,
    ['ohos.permission.READ_CALENDAR', 'ohos.permission.WRITE_CALENDAR']);
  return result.authResults.length > 0 && result.authResults[0] === 0;
}

// 读取系统日程
private async loadEvents(): Promise<void> {
  const mgr = calendarManager.getCalendarManager(this.getUIContext().getHostContext());
  const calendar = await mgr.getCalendar();
  const events = await calendar.getEvents();
  // 映射为本地 ScheduleEvent 数组，按 startTime 排序
}

// 添加日程（明天 10:00 开始 1 小时）
private async addEvent(): Promise<void> {
  const mgr = calendarManager.getCalendarManager(this.getUIContext().getHostContext());
  const calendar = await mgr.getCalendar();
  const start = Date.now() + 24 * 3600 * 1000;
  await calendar.addEvent({
    type: 0,                       // EventType.NORMAL
    title: title,
    startTime: start,
    endTime: start + 3600 * 1000
  });
}

// 删除日程
private async deleteEvent(id: number): Promise<void> {
  const mgr = calendarManager.getCalendarManager(this.getUIContext().getHostContext());
  const calendar = await mgr.getCalendar();
  await calendar.deleteEvent(id);
}
```

> 注意：`calendarManager` 需要真机支持系统日历；模拟器可能无系统日历服务。

---

## 12. 背景系统（背景图管理）

### 12.1 BackgroundManager（状态管理）

`utils/BackgroundManager.ets` 管理背景选择/模糊/亮度，状态存 AppStorage，可持久化：

```ts
export class BackgroundManager {
  static selection(): string { return AppStorage.get<string>('bg_selection') ?? 'none'; }
  static blurPercent(): number { return AppStorage.get<number>('bg_blur_percent') ?? 0; }
  static brightnessPercent(): number { return AppStorage.get<number>('bg_brightness_percent') ?? 50; }
  static globalEnabled(): boolean { return AppStorage.get<boolean>('bg_global') ?? true; }

  static isEnabled(): boolean {
    return BackgroundManager.globalEnabled() && BackgroundManager.selection() !== 'none';
  }

  // 页面背景色：背景开启时透明（露背景层），否则用正常底色
  static pageBackgroundColor(dark: boolean): string {
    return BackgroundManager.isEnabled() ? '#00000000' : (dark ? '#0F0F11' : '#F5F5F5');
  }
}
```

### 12.2 BackgroundLayer（渲染层）

放在页面根 Stack 最底层，`@StorageProp` 响应式：

```ts
@Component
export struct BackgroundLayer {
  @StorageProp('bg_selection') bgSelection: string = 'none';
  @StorageProp('bg_custom_uri') bgCustomUri: string = '';
  @StorageProp('bg_blur_percent') bgBlurPercent: number = 0;
  @StorageProp('bg_brightness_percent') bgBrightnessPercent: number = 50;
  @StorageProp('bg_global') bgGlobal: boolean = true;

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      if (this.isEnabled()) {
        this.SelectedBackgroundImage('100%', 0)   // 图片 + blur + scale
      }
    }
    .width('100%').height('100%')
    .position({ x: 0, y: 0 })
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .clip(true)
    .renderGroup(this.isEnabled())
    .brightness(this.bgBrightnessPercent / 50)    // 亮度映射：50 → 1.0
    .hitTestBehavior(HitTestMode.None)
  }
}
```

用法：

```ts
Stack() {
  BackgroundLayer()      // 最底
  // 页面内容
}
```

> 亮度默认 **50**（`bg_brightness_percent` 默认 50 → `brightness(1.0)` 无变化）。

---

## 13. 网络层与登录态

### 13.1 HttpUtil（带 Cookie 持久化 HTTP 客户端）

`utils/HttpUtil.ets` — 封装 `@kit.NetworkKit` http，支持：
- Cookie 持久化（`PreferenceUtil`）
- 302 拦截（`getNoRedirect/postNoRedirect`）
- `getArrayBuffer`（验证码图片）

```ts
const resp = await HttpUtil.getInstance().get(url, headers);
if (resp.isOk) { const data = resp.json<MyType>(); }
```

### 13.2 SqgService（业务接口）

`services/SqgService.ets` — 统一封装登录、首页、公告、服务列表、课表等。Base URL 在 `SqgConstants.ets`：

```ts
export const APPLET_BASE: string = 'https://cas.sqgxy.edu.cn/token/';
export const PORTAL_BASE: string = 'https://i.sqgxy.edu.cn/portal-api/';
export const PERSONAL_BASE: string = 'https://authx-service.sqgxy.edu.cn/personal/';
export const MESSAGE_BASE: string = 'https://message-service.sqgxy.edu.cn/center/';
export const CAS_ARRY: string[] = ['https://i.sqgxy.edu.cn/'];
```

### 13.3 登录

```ts
// 密码登录：保存 id_token / is_logged_in
await SqgService.getInstance().login(username, password);
// 判断登录态
SqgService.getInstance().isLoggedIn();   // PreferenceUtil.getBool('is_logged_in') && token.length > 0
```

---

## 14. 开发规范与最佳实践

### 14.1 页面布局

- 页面根用 `Stack` + `BackgroundLayer()`。
- 有悬浮元素（搜索框/返回按钮）时：内容 `clip(false)` + 顶部 padding 避让；悬浮元素 `.position()` + `.zIndex(12)`。
- 内容区 `Scroll`/`WaterFlow` 记得 `.align(Alignment.Top)`（否则矮内容垂直居中）。

### 14.2 材质

- 所有材质相关组件统一走 `MaterialConfig`，**不写死** `hdsMaterial.MaterialType`。
- 沉浸光感开关要能同时控制返回按钮：用 `MaterialConfig.systemMaterialEffectParams()`。

### 14.3 深浅色

- 颜色一律 `ThemeColors.*`，禁止硬编码。
- 深浅色判断用 `ThemeColors.isDark` 或 `@StorageLink('theme_is_dark')`。

### 14.4 导航

- 二级页用 `NavDestination` 内嵌 `HdsNavigation()`（MINI 模式）。
- 自定义返回用 `backIcon.action`；系统返回手势用 `onBackPressed`。
- **不要**把 `HdsTabsController` 传给子组件调用；用 AppStorage 信号 + @Watch（避免空指针崩溃）。

### 14.5 图标

- 本地图标全部用 svg（`$r('app.media.ic_xxx')`），服务页图标优先用服务列表下发的真实 `iconUrl`。
- App 图标统一 `icon.png`（各 density 目录也要同步，否则旧图标会覆盖）。

### 14.6 性能

- 列表用 `ForEach`（小数据）或 `LazyForEach`（大数据）。
- 避免在 `build()` 里做副作用，数据加载放 `aboutToAppear`。
- 卡片按压动画用 transform（`scale`），避免触发 re-layout。

---

## 附录：组件/文件索引

| 文件 | 用途 |
|---|---|
| `utils/ThemeColors.ets` | 主题色表 |
| `utils/MaterialConfig.ets` | 沉浸光感配置 |
| `utils/BackgroundManager.ets` | 背景管理 + 渲染层 |
| `utils/HttpUtil.ets` | HTTP 客户端（Cookie 持久化） |
| `components/GlassCard.ets` | 玻璃卡片容器 |
| `components/GlassPanel.ets` | 空白玻璃容器 |
| `components/SettingRowCard.ets` | 设置行卡片（图标+文字+右箭头/值） |
| `components/QuickActionGrid.ets` | 首页快捷按钮网格 |
| `components/ImmersionActionButton.ets` | 沉浸按钮（@tangs/components） |
| `pages/tabs/HomeTab.ets` | 首页（悬浮搜索框 + 快捷卡片） |
| `pages/tabs/ServiceTab.ets` | 服务页（悬浮搜索框 + 分类条） |
| `pages/tabs/MessageTab.ets` | 消息页（公告列表） |
| `pages/tabs/ScheduleTab.ets` | 日程页（系统日历） |
| `pages/MainPage.ets` | 主页面（HdsNavigation + HdsTabs） |
