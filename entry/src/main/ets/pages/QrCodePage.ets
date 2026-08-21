import { router } from '@kit.ArkUI';
import { image } from '@kit.ImageKit';
import { AppSession } from '../service/AppSession';
import { QrCodeService, QrProbeState } from '../service/QrCodeService';
import { QuickQrPayload, WifiQrPayload } from '../format/WifiQrPayload';
import { AppPrimaryButton } from '../common/components/AppWidgets';
import { VaultEntry } from '../model/VaultEntry';

@Entry
@Component
struct QrCodePage {
  @State kind: string = 'text';
  @State content: string = '';
  @State extra: string = '';
  @State error: string = '';
  @State emu: boolean = false;
  @State pixel?: image.PixelMap = undefined;
  @State confirmPw: boolean = false;

  async aboutToAppear(): Promise<void> {
    QrCodeService.resetCancel();
    const preset = AppStorage.get('qrPreset') as string;
    if (preset && preset.indexOf('wifi:') === 0) {
      const id = preset.substring(5);
      const e = AppSession.vault.byId(id);
      if (e) {
        this.kind = 'wifi';
        this.content = e.wifiSsid;
        this.extra = e.password;
      }
    }
    const ok = await QrCodeService.probe();
    this.emu = !ok || QrProbeState.unsupported;
  }

  aboutToDisappear(): void {
    this.release();
    QrCodeService.cancel();
  }

  build() {
    Column({ space: 12 }) {
      Row() {
        SymbolGlyph($r('sys.symbol.chevron_left')).fontSize(22).onClick(() => {
          router.back();
        })
        Blank()
        Text('快速二维码').fontSize(18).fontWeight(FontWeight.Medium)
        Blank()
      }
      .width('100%')

      Scroll() {
        Row({ space: 8 }) {
          ForEach([['text', '文本'], ['url', '网址'], ['wifi', 'WiFi'], ['phone', '电话'],
            ['sms', '短信'], ['email', '电子邮件'], ['vcard', '联系人']], (p: string[]) => {
            Text(p[1])
              .fontSize(12)
              .padding({ left: 10, right: 10, top: 6, bottom: 6 })
              .borderRadius(12)
              .backgroundColor(this.kind === p[0] ? $r('app.color.accent') : $r('app.color.surface_muted'))
              .fontColor(this.kind === p[0] ? Color.White : $r('app.color.ink'))
              .onClick(() => {
                this.kind = p[0];
              })
          }, (p: string[]) => p[0])
        }
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)

      TextInput({ text: this.content, placeholder: this.placeholder() })
        .onChange((v: string) => {
          this.content = v;
        })
      if (this.kind === 'wifi' || this.kind === 'sms' || this.kind === 'email' || this.kind === 'vcard') {
        TextInput({ text: this.extra, placeholder: this.kind === 'wifi' ? '密码' : '附加内容' })
          .onChange((v: string) => {
            this.extra = v;
          })
      }

      if (this.emu) {
        Column({ space: 8 }) {
          Text('当前无法生成二维码')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .width('100%')
          Text(QrCodeService.EMULATOR_DIALOG)
            .fontSize(14)
            .fontColor($r('app.color.ink_secondary'))
            .width('100%')
          Text('仍可编辑和复制内容')
            .fontSize(12)
            .fontColor($r('app.color.ink_tertiary'))
            .width('100%')
          Button('知道了').onClick(() => {
          })
        }
        .padding(16)
        .borderRadius(16)
        .backgroundColor($r('app.color.surface'))
        .width('100%')
      }

      if (this.pixel) {
        Image(this.pixel)
          .width(220)
          .height(220)
          .borderRadius(12)
      }

      if (this.error.length > 0) {
        Text(this.error).fontSize(14).fontColor($r('app.color.danger')).width('100%')
      }

      AppPrimaryButton({
        label: '生成',
        enabled: !this.emu,
        onTap: () => {
          this.make();
        }
      })
      Button('复制内容', { type: ButtonType.Normal })
        .width('100%')
        .backgroundColor($r('app.color.surface_muted'))
        .fontColor($r('app.color.ink'))
        .onClick(() => {
          ClipboardGuard.copy(this.payload(), 0, true);
        })
      Blank()
    }
    .padding(20)
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_bg'))
  }

  private placeholder(): string {
    if (this.kind === 'wifi') {
      return '网络名称';
    }
    if (this.kind === 'url') {
      return 'https://';
    }
    return '内容';
  }

  private payload(): string {
    if (this.kind === 'wifi') {
      return WifiQrPayload.build('WPA', this.content, this.extra, false);
    }
    if (this.kind === 'phone') {
      return QuickQrPayload.phone(this.content);
    }
    if (this.kind === 'sms') {
      return QuickQrPayload.sms(this.content, this.extra);
    }
    if (this.kind === 'email') {
      return QuickQrPayload.email(this.content, '', this.extra);
    }
    if (this.kind === 'vcard') {
      return QuickQrPayload.vcard(this.content, this.extra, '');
    }
    return this.content;
  }

  private async make(): Promise<void> {
    this.error = '';
    this.release();
    const data = this.payload();
    if (data.length === 0) {
      this.error = '请先填写内容';
      return;
    }
    if (this.kind === 'wifi' && this.extra.length > 0 && !this.confirmPw) {
      this.getUIContext().showAlertDialog({
        title: '确认写入密码',
        message: '密码会写入二维码，附近的人扫码即可看到。确定继续？',
        primaryButton: {
          value: '取消',
          action: () => {
          }
        },
        secondaryButton: {
          value: '继续',
          action: () => {
            this.confirmPw = true;
            this.make();
          }
        }
      });
      return;
    }
    try {
      this.pixel = await QrCodeService.generate(data, 480, 0x1C1B19, 0xFFFCF7);
    } catch (e) {
      const err = e as Error;
      if (err.message === 'emulator') {
        this.emu = true;
        this.error = '';
      } else if (err.message === 'too_long') {
        this.error = '内容过长，请缩短后再生成';
      } else if (err.message === 'contrast') {
        this.error = '前景和背景对比不足，难以扫描';
      } else if (err.message === 'empty') {
        this.error = '请先填写内容';
      } else {
        this.error = '二维码生成失败，请调整内容后重试';
      }
    }
  }

  private release(): void {
    if (this.pixel) {
      try {
        this.pixel.release();
      } catch (_e) {
      }
      this.pixel = undefined;
    }
  }
}
