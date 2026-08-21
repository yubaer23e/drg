@Component
export struct AppPrimaryButton {
  label: string = '';
  enabled: boolean = true;
  onTap: () => void = () => {};

  build() {
    Button(this.label)
      .width('100%')
      .height(48)
      .borderRadius($r('app.float.radius_md'))
      .fontSize($r('app.float.body'))
      .fontColor(Color.White)
      .backgroundColor($r('app.color.accent'))
      .enabled(this.enabled)
      .onClick(() => {
        this.onTap();
      })
  }
}

@Component
export struct AppGhostButton {
  label: string = '';
  onTap: () => void = () => {};

  build() {
    Button(this.label, { type: ButtonType.Normal })
      .width('100%')
      .height(48)
      .borderRadius($r('app.float.radius_md'))
      .fontSize($r('app.float.body'))
      .fontColor($r('app.color.ink'))
      .backgroundColor($r('app.color.surface_muted'))
      .onClick(() => {
        this.onTap();
      })
  }
}

@Component
export struct EmptyState {
  title: string = '';
  body: string = '';
  action: string = '';
  onAction: () => void = () => {};

  build() {
    Column({ space: 12 }) {
      Text(this.title)
        .fontSize($r('app.float.title_card'))
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.ink'))
      Text(this.body)
        .fontSize($r('app.float.caption'))
        .fontColor($r('app.color.ink_secondary'))
        .lineHeight(22)
        .textAlign(TextAlign.Center)
      if (this.action.length > 0) {
        Button(this.action)
          .height(40)
          .borderRadius(12)
          .backgroundColor($r('app.color.accent'))
          .fontColor(Color.White)
          .onClick(() => {
            this.onAction();
          })
      }
    }
    .width('100%')
    .padding({ left: 32, right: 32, top: 48, bottom: 48 })
    .alignItems(HorizontalAlign.Center)
  }
}

@Component
export struct SettingRow {
  title: string = '';
  desc: string = '';
  checked: boolean = false;
  onChange: (v: boolean) => void = (_v: boolean) => {};

  build() {
    Row() {
      Column({ space: 4 }) {
        Text(this.title)
          .fontSize($r('app.float.body'))
          .fontColor($r('app.color.ink'))
        if (this.desc.length > 0) {
          Text(this.desc)
            .fontSize($r('app.float.hint'))
            .fontColor($r('app.color.ink_secondary'))
            .lineHeight(18)
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Toggle({ type: ToggleType.Switch, isOn: this.checked })
        .selectedColor($r('app.color.accent'))
        .onChange((v: boolean) => {
          this.onChange(v);
        })
    }
    .width('100%')
    .padding({ top: 14, bottom: 14 })
    .alignItems(VerticalAlign.Center)
  }
}
