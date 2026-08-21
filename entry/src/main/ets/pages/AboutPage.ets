import { router } from '@kit.ArkUI';
import { CredentialProviderAdapter } from '../service/CredentialProviderAdapter';

@Entry
@Component
struct AboutPage {
  build() {
    Column({ space: 16 }) {
      Row() {
        SymbolGlyph($r('sys.symbol.chevron_left')).fontSize(22).onClick(() => {
          router.back();
        })
        Blank()
        Text('关于').fontSize(18).fontWeight(FontWeight.Medium)
        Blank()
      }
      .width('100%')

      Text('0号保险库')
        .fontSize(28)
        .fontWeight(FontWeight.Medium)
        .width('100%')
      Text('版本 1.0.0')
        .fontSize(14)
        .fontColor($r('app.color.ink_secondary'))
        .width('100%')

      Text('隐私说明')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .width('100%')
      Text('本应用不声明网络权限，也没有云同步、账号系统或远程上报。密码、日记和备份口令只存放在这台设备。忘记系统锁屏密码时，请在系统设置中处理；本应用无法代劳。')
        .fontSize(14)
        .fontColor($r('app.color.ink_secondary'))
        .lineHeight(22)
        .width('100%')

      Text('本地数据说明')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .width('100%')
      Text('条目使用随机数据主密钥加密。主密钥由设备硬件密钥、可选内置密码、可选私密问题和导出文件分别包裹。清空应用即销毁钥匙，密文不可恢复。')
        .fontSize(14)
        .fontColor($r('app.color.ink_secondary'))
        .lineHeight(22)
        .width('100%')

      Text('自动填充')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .width('100%')
      Text(CredentialProviderAdapter.REASON)
        .fontSize(14)
        .fontColor($r('app.color.ink_secondary'))
        .lineHeight(22)
        .width('100%')

      Text('如需保管普通文件，请使用系统自带的文件保险箱。')
        .fontSize(14)
        .fontColor($r('app.color.ink_secondary'))
        .lineHeight(22)
        .width('100%')
      Blank()
    }
    .padding(20)
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_bg'))
  }
}
