import { router } from '@kit.ArkUI';
import { AppSession } from '../service/AppSession';
import { AppPrimaryButton, AppGhostButton } from '../common/components/AppWidgets';

@Entry
@Component
struct UnlockPage {
  @State master: string = '';
  @State error: string = '';
  @State busy: boolean = false;

  build() {
    Column({ space: 20 }) {
      Blank().height(48)
      Text('解锁 0号保险库')
        .fontSize($r('app.float.title_page'))
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.ink'))
        .width('100%')
      Text('数据仍在本机加密保存。')
        .fontSize($r('app.float.caption'))
        .fontColor($r('app.color.ink_secondary'))
        .width('100%')

      if (AppSession.settings.hasMaster) {
        TextInput({ placeholder: '输入内置密码', text: this.master })
          .type(InputType.Password)
          .onChange((v: string) => {
            this.master = v;
          })
        AppPrimaryButton({
          label: '用内置密码解锁',
          enabled: !this.busy,
          onTap: () => {
            this.withMaster();
          }
        })
      }

      if (AppSession.settings.lockMethod !== 'master') {
        AppPrimaryButton({
          label: '使用设备认证',
          enabled: !this.busy,
          onTap: () => {
            this.withDevice();
          }
        })
      }

      AppGhostButton({
        label: '忘记内置密码',
        onTap: () => {
          router.pushUrl({ url: 'pages/RecoverPage' });
        }
      })

      if (this.error.length > 0) {
        Text(this.error)
          .fontSize($r('app.float.caption'))
          .fontColor($r('app.color.danger'))
          .width('100%')
      }
      Blank()
    }
    .padding(24)
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_bg'))
  }

  private async withDevice(): Promise<void> {
    this.busy = true;
    this.error = '';
    const ok = await AppSession.unlockWithDevice();
    this.busy = false;
    if (ok) {
      AppStorage.setOrCreate('isLocked', false);
      router.replaceUrl({ url: 'pages/ShellPage' });
    } else {
      this.error = '认证未通过';
    }
  }

  private async withMaster(): Promise<void> {
    this.busy = true;
    this.error = '';
    const ok = await AppSession.unlockWithMaster(this.master);
    this.busy = false;
    if (ok) {
      AppStorage.setOrCreate('isLocked', false);
      router.replaceUrl({ url: 'pages/ShellPage' });
    } else {
      this.error = '认证未通过';
    }
  }
}
