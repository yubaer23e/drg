import { router } from '@kit.ArkUI';
import { scanBarcode, scanCore } from '@kit.ScanKit';
import { common } from '@kit.AbilityKit';
import { AppSession } from '../service/AppSession';
import { TotpEngine } from '../format/TotpEngine';
import { OtpAuthParser } from '../format/OtpAuthParser';
import { EntryKind } from '../model/EntryKind';
import { ClipboardGuard } from '../service/ClipboardGuard';
import { AppPrimaryButton } from '../common/components/AppWidgets';

@Entry
@Component
struct TotpPage {
  @State secret: string = '';
  @State issuer: string = '';
  @State account: string = '';
  @State code: string = '';
  @State remain: number = 30;
  @State error: string = '';
  private timer: number = -1;

  aboutToAppear(): void {
    this.timer = setInterval(() => {
      this.tick();
    }, 500);
  }

  aboutToDisappear(): void {
    if (this.timer >= 0) {
      clearInterval(this.timer);
    }
  }

  build() {
    Column({ space: 14 }) {
      Row() {
        SymbolGlyph($r('sys.symbol.chevron_left')).fontSize(22).onClick(() => {
          router.back();
        })
        Blank()
        Text('验证码').fontSize(18).fontWeight(FontWeight.Medium)
        Blank()
      }
      .width('100%')

      TextInput({ text: this.issuer, placeholder: '发行方' }).onChange((v: string) => {
        this.issuer = v;
      })
      TextInput({ text: this.account, placeholder: '账号' }).onChange((v: string) => {
        this.account = v;
      })
      TextInput({ text: this.secret, placeholder: 'Base32 密钥' }).onChange((v: string) => {
        this.secret = v.replace(/\s+/g, '');
        this.tick();
      })

      Text(this.code.length > 0 ? this.code : '------')
        .fontSize(36)
        .fontFamily('monospace')
        .fontColor($r('app.color.ink'))
      Text('剩余 ' + this.remain + ' 秒')
        .fontSize(12)
        .fontColor($r('app.color.ink_tertiary'))

      AppPrimaryButton({
        label: '扫描二维码',
        onTap: () => {
          this.scan();
        }
      })
      Button('复制当前验证码', { type: ButtonType.Normal })
        .width('100%')
        .backgroundColor($r('app.color.surface_muted'))
        .fontColor($r('app.color.ink'))
        .onClick(() => {
          ClipboardGuard.copy(this.code, AppSession.settings.clipboardSec, true);
        })
      Button('保存到保险库', { type: ButtonType.Normal })
        .width('100%')
        .backgroundColor($r('app.color.surface_muted'))
        .fontColor($r('app.color.ink'))
        .onClick(() => {
          this.save();
        })
      if (this.error.length > 0) {
        Text(this.error).fontColor($r('app.color.danger'))
      }
      Text('密钥默认不明文展示在列表中。设备时间不准时验证码可能无效。')
        .fontSize(12)
        .fontColor($r('app.color.ink_tertiary'))
        .width('100%')
      Blank()
    }
    .padding(20)
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_bg'))
  }

  private tick(): void {
    if (this.secret.length < 8) {
      this.code = '';
      return;
    }
    const now = Math.floor(Date.now() / 1000);
    this.remain = TotpEngine.remaining(now, 30);
    try {
      this.code = TotpEngine.generate(this.secret, now, 6, 30, 'SHA1');
    } catch (_e) {
      this.code = '------';
    }
  }

  private async scan(): Promise<void> {
    try {
      const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const results = await scanBarcode.startScanForResult(ctx, { scanTypes: [scanCore.ScanType.QR_CODE] });
      if (results && results.length > 0) {
        const raw = results[0].originalValue;
        const parsed = OtpAuthParser.parse(raw);
        this.secret = parsed['secret'];
        this.issuer = parsed['issuer'] ? parsed['issuer'] : this.issuer;
        this.account = parsed['account'] ? parsed['account'] : this.account;
        this.tick();
      }
    } catch (e) {
      this.error = '无法扫码，请改为手工输入密钥。';
    }
  }

  private save(): void {
    const e = AppSession.newEntry(EntryKind.TOTP);
    e.title = this.issuer.length > 0 ? this.issuer : this.account;
    e.totpIssuer = this.issuer;
    e.totpAccount = this.account;
    e.totpSecret = this.secret;
    AppSession.vault.upsert(e, AppSession.random, false);
    AppSession.persist();
    router.back();
  }
}
