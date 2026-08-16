import { ThemeColors } from '../utils/ThemeColors';
import { SettingRowCard } from './SettingRowCard';
import { ImmersionButton } from '@tangs/components';
import { ActionButtonModifier } from './ImmersionActionButton';
import { MaterialConfig } from '../utils/MaterialConfig';

@Component
export struct SettingsPanel {
  @StorageLink('theme_is_dark') themeIsDark: boolean = false;
  onAccountClick: () => void = () => {
  };
  onDeclarationClick: () => void = () => {
  };
  onLogoutClick: () => void = () => {
  };

  private accentColor(): string {
    return ThemeColors.accent;
  }

  private primaryActionFillColor(): string {
    const hex = this.accentColor();
    return '#1A' + hex.substring(1);
  }

  @Builder
  LogoutButton() {
    Stack({ alignContent: Alignment.Center }) {
      ImmersionButton({
        systemMaterialEffect: {
          materialType: MaterialConfig.configuredMaterialType(),
          materialLevel: MaterialConfig.configuredMaterialLevel()
        },
        buttonModify: new ActionButtonModifier('100%', 48, this.primaryActionFillColor(), this.accentColor()),
        click: (): void => { this.onLogoutClick(); }
      }) {
        Text('退出登录')
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.accentColor())
      }
    }
    .width('100%')
    .height(48)
    .borderRadius(24)
    .clip(false)
  }

  build() {
    Column() {
      SettingRowCard({
        icon: $r('app.media.ic_lock'),
        label: '账号与安全',
        action: () => { this.onAccountClick(); }
      })

      Blank().height(24)

      SettingRowCard({
        icon: $r('app.media.ic_document'),
        label: '软件声明',
        action: () => { this.onDeclarationClick(); }
      })

      Blank().height(24)

      this.LogoutButton()
    }
    .width('100%')
    .justifyContent(FlexAlign.Start)
  }
}
