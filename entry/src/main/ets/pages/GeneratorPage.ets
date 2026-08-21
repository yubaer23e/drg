import { router } from '@kit.ArkUI';
import { AppSession } from '../service/AppSession';
import { GeneratorOptions, PasswordGenerator } from '../service/PasswordGenerator';
import { ClipboardGuard } from '../service/ClipboardGuard';
import { AppPrimaryButton } from '../common/components/AppWidgets';

@Entry
@Component
struct GeneratorPage {
  @State opt: GeneratorOptions = new GeneratorOptions();
  @State result: string = '';
  @State bits: number = 0;

  aboutToAppear(): void {
    this.roll();
  }

  build() {
    Column({ space: 16 }) {
      Row() {
        SymbolGlyph($r('sys.symbol.chevron_left')).fontSize(22).onClick(() => {
          router.back();
        })
        Blank()
        Text('密码生成器').fontSize(18).fontWeight(FontWeight.Medium)
        Blank()
      }
      .width('100%')

      Text(this.result.length > 0 ? this.result : '点击生成')
        .fontSize(20)
        .fontFamily('monospace')
        .fontColor($r('app.color.ink'))
        .width('100%')
        .padding(16)
        .borderRadius(16)
        .backgroundColor($r('app.color.surface'))

      Text('估计熵 ' + this.bits + ' 比特 · ' + PasswordGenerator.strengthLabel(this.bits))
        .fontSize(12)
        .fontColor($r('app.color.ink_secondary'))
        .width('100%')

      Text('长度 ' + this.opt.length).fontSize(14).width('100%')
      Slider({ value: this.opt.length, min: 8, max: 128, step: 1 })
        .onChange((v: number) => {
          this.opt.length = Math.floor(v);
          this.roll();
        })

      this.toggle('大写字母', this.opt.upper, (v: boolean) => {
        this.opt.upper = v;
        this.roll();
      })
      this.toggle('小写字母', this.opt.lower, (v: boolean) => {
        this.opt.lower = v;
        this.roll();
      })
      this.toggle('数字', this.opt.digit, (v: boolean) => {
        this.opt.digit = v;
        this.roll();
      })
      this.toggle('特殊字符', this.opt.symbol, (v: boolean) => {
        this.opt.symbol = v;
        this.roll();
      })
      this.toggle('排除相似字符', this.opt.excludeSimilar, (v: boolean) => {
        this.opt.excludeSimilar = v;
        this.roll();
      })
      this.toggle('易读口令', this.opt.pronounceable, (v: boolean) => {
        this.opt.pronounceable = v;
        this.roll();
      })

      AppPrimaryButton({
        label: '重新生成',
        onTap: () => {
          this.roll();
        }
      })
      Button('复制生成结果', { type: ButtonType.Normal })
        .width('100%')
        .backgroundColor($r('app.color.surface_muted'))
        .fontColor($r('app.color.ink'))
        .onClick(() => {
          ClipboardGuard.copy(this.result, AppSession.settings.clipboardSec, true);
        })
      Text('生成结果默认不会自动复制。随机数来自系统安全随机源，不使用普通伪随机。')
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

  @Builder
  toggle(label: string, on: boolean, change: (v: boolean) => void) {
    Row() {
      Text(label).fontSize(16).layoutWeight(1)
      Toggle({ type: ToggleType.Switch, isOn: on }).onChange(change)
    }
    .width('100%')
  }

  private roll(): void {
    try {
      this.result = PasswordGenerator.generate(this.opt, AppSession.random);
      this.bits = PasswordGenerator.entropyBits(this.opt, this.result);
    } catch (_e) {
      this.result = '';
      this.bits = 0;
    }
  }
}
