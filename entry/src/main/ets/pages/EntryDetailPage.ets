import { router } from '@kit.ArkUI';
import { AppSession } from '../service/AppSession';
import { VaultEntry } from '../model/VaultEntry';
import { EntryKind, EntryKindUtil } from '../model/EntryKind';
import { ClipboardGuard } from '../service/ClipboardGuard';
import { AuthService } from '../service/AuthService';
import { TotpEngine } from '../format/TotpEngine';
import { EntryHistory } from '../model/VaultEntry';

@Entry
@Component
struct EntryDetailPage {
  @State entry: VaultEntry = new VaultEntry();
  @State show: boolean = false;
  @State totp: string = '';
  @State remain: number = 0;
  private timer: number = -1;

  aboutToAppear(): void {
    const id = AppStorage.get('detailEntryId') as string;
    const found = AppSession.vault.byId(id);
    if (found) {
      this.entry = found.clone();
      AppSession.vault.markUsed(found.id, AppSession.settings.statsEnabled);
    }
    this.refreshTotp();
    this.timer = setInterval(() => {
      this.refreshTotp();
    }, 500);
  }

  aboutToDisappear(): void {
    if (this.timer >= 0) {
      clearInterval(this.timer);
    }
  }

  build() {
    Column() {
      Row() {
        SymbolGlyph($r('sys.symbol.chevron_left'))
          .fontSize(22)
          .onClick(() => {
            router.back();
          })
        Blank()
        Text('详情').fontSize(18).fontWeight(FontWeight.Medium)
        Blank()
        Text('编辑')
          .fontColor($r('app.color.accent'))
          .onClick(() => {
            AppStorage.setOrCreate('editEntryId', this.entry.id);
            router.pushUrl({ url: 'pages/EntryEditPage' });
          })
      }
      .padding(16)
      .width('100%')

      Scroll() {
        Column({ space: 12 }) {
          Text(this.entry.displayTitle())
            .fontSize(24)
            .fontWeight(FontWeight.Medium)
            .width('100%')
          Text(EntryKindUtil.label(this.entry.kind) + ' · ' + this.entry.colorName)
            .fontSize(12)
            .fontColor($r('app.color.ink_tertiary'))
            .width('100%')
          this.row('用户名', this.entry.username, false)
          this.row('密码', this.entry.password, true)
          this.row('网址', this.entry.url, false)
          this.row('网络名称', this.entry.wifiSsid, false)
          this.row('卡号', this.entry.cardNumber, true)
          this.row('证件号码', this.entry.idNumber, true)
          this.row('主机', this.entry.host, false)
          this.row('备注', this.entry.notes, false)
          if (this.entry.kind === EntryKind.TOTP || this.entry.totpSecret.length > 0) {
            Column({ space: 6 }) {
              Text('验证码').fontSize(12).fontColor($r('app.color.ink_tertiary')).width('100%')
              Text(this.totp)
                .fontSize(32)
                .fontFamily('monospace')
                .fontColor($r('app.color.ink'))
              Text('剩余 ' + this.remain + ' 秒')
                .fontSize(12)
                .fontColor($r('app.color.ink_tertiary'))
              Button('复制验证码').onClick(() => {
                ClipboardGuard.copy(this.totp, AppSession.settings.clipboardSec, true);
              })
            }
            .padding(16)
            .backgroundColor($r('app.color.surface'))
            .borderRadius(16)
            .width('100%')
          }
          Text('创建 ' + this.ts(this.entry.createdAt) + ' · 修改 ' + this.ts(this.entry.modifiedAt))
            .fontSize(12)
            .fontColor($r('app.color.ink_tertiary'))
            .width('100%')
          Text('使用次数 ' + this.entry.useCount)
            .fontSize(12)
            .fontColor($r('app.color.ink_tertiary'))
            .width('100%')
          if (this.history().length > 0) {
            Text('修改历史').fontSize(14).fontWeight(FontWeight.Medium).width('100%')
            ForEach(this.history(), (h: EntryHistory) => {
              Text(this.ts(h.createdAt))
                .fontSize(12)
                .fontColor($r('app.color.ink_secondary'))
                .onClick(() => {
                  const old = VaultEntry.fromJson(h.snapshot);
                  this.entry = old;
                })
            }, (h: EntryHistory) => h.id)
          }
          Row({ space: 8 }) {
            if (this.entry.kind === EntryKind.WIFI) {
              Button('WiFi 二维码').onClick(() => {
                AppStorage.setOrCreate('qrPreset', 'wifi:' + this.entry.id);
                router.pushUrl({ url: 'pages/QrCodePage' });
              })
            }
            Button('移入回收站', { type: ButtonType.Normal })
              .backgroundColor($r('app.color.surface_muted'))
              .fontColor($r('app.color.danger'))
              .onClick(() => {
                AppSession.vault.softDelete(this.entry.id, AppSession.settings.recycleEnabled);
                AppSession.persist();
                router.back();
              })
          }
        }
        .padding(20)
        .constraintSize({ maxWidth: 640 })
        .width('100%')
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_bg'))
  }

  @Builder
  row(label: string, value: string, secret: boolean) {
    if (value.length === 0) {
      Column() {}
    } else {
      Row() {
        Column({ space: 4 }) {
          Text(label).fontSize(12).fontColor($r('app.color.ink_tertiary')).width('100%')
          Text(secret && !this.show ? '••••••••' : value)
            .fontSize(16)
            .fontColor($r('app.color.ink'))
            .width('100%')
        }
        .layoutWeight(1)
        Button('复制', { type: ButtonType.Normal })
          .height(32)
          .backgroundColor($r('app.color.surface_muted'))
          .fontColor($r('app.color.ink'))
          .onClick(() => {
            this.copy(value, secret);
          })
      }
      .padding(14)
      .borderRadius(16)
      .backgroundColor($r('app.color.surface'))
      .width('100%')
    }
  }

  private async copy(value: string, secret: boolean): Promise<void> {
    if (secret && AppSession.settings.copyAuth) {
      const ok = await AuthService.deviceUnlock();
      if (!ok) {
        return;
      }
    }
    await ClipboardGuard.copy(value, AppSession.settings.clipboardSec, AppSession.settings.clipboardLocal);
  }

  private refreshTotp(): void {
    if (this.entry.totpSecret.length === 0) {
      return;
    }
    const now = Math.floor(Date.now() / 1000);
    this.remain = TotpEngine.remaining(now, this.entry.totpPeriod);
    try {
      this.totp = TotpEngine.generate(this.entry.totpSecret, now, this.entry.totpDigits, this.entry.totpPeriod,
        this.entry.totpAlgo);
    } catch (_e) {
      this.totp = '------';
    }
  }

  private ts(n: number): string {
    if (n <= 0) {
      return '-';
    }
    const d = new Date(n);
    return (d.getMonth() + 1) + '月' + d.getDate() + '日';
  }

  private history(): EntryHistory[] {
    return AppSession.vault.historyOf(this.entry.id);
  }
}
