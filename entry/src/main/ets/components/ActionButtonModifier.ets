import { ButtonModifier } from '@ohos.arkui.modifier';

export class ActionButtonModifier implements AttributeModifier<ButtonModifier> {
  private buttonWidth: Length;
  private buttonHeight: number;
  private fillColor: ResourceColor;
  private strokeColor: ResourceColor;

  constructor(buttonWidth: Length, buttonHeight: number, fillColor: ResourceColor, strokeColor: ResourceColor) {
    this.buttonWidth = buttonWidth;
    this.buttonHeight = buttonHeight;
    this.fillColor = fillColor;
    this.strokeColor = strokeColor;
  }

  applyNormalAttribute(instance: ButtonModifier): void {
    instance.width(this.buttonWidth)
      .height(this.buttonHeight)
      .backgroundColor(this.fillColor)
      .border({ width: 0.5, color: this.strokeColor });
  }
}
