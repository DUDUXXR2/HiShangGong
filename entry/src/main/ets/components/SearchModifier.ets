export class SearchModifier implements AttributeModifier<SearchAttribute> {
  private textColor: ResourceColor;
  private hintColor: ResourceColor;
  private change: (value: string) => void;

  constructor(textColor: ResourceColor, hintColor: ResourceColor, change: (value: string) => void) {
    this.textColor = textColor;
    this.hintColor = hintColor;
    this.change = change;
  }

  applyNormalAttribute(instance: SearchAttribute): void {
    instance.fontColor(this.textColor)
      .placeholderColor(this.hintColor)
      .onWillChange((value: EditableTextChangeValue): boolean => {
        this.change(value.content);
        return true;
      });
  }
}
