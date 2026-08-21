import { router } from '@kit.ArkUI';
import { AppSession } from '../service/AppSession';
import { AppConstants } from '../common/constants/AppConstants';
import { AppPrimaryButton, AppGhostButton } from '../common/components/AppWidgets';
import { AuthService } from '../service/AuthService';

@Entry
@Component
struct RecoverPage {
  @State mode: string = 'menu';
  @State answer: string = '';
  @State master: string = '';
  @State master2: string = '';
  @State phrase: string = '';
  @State error: string = '';
  @State info: string = '';

  build() {
    Column({ space: 16 }) {
      Row({ space: 8 }) {
        SymbolGlyph($r('sys.symbol.chevron_left'))
          .fontSize(22)
          .fontColor($r('app.color.ink'))
          .onClick(() => {
            router.back();
          })
        Text('重置内置密码')
          .fontSize($r('app.float.title_page'))
          .fontColor($r('app.color.ink'))
      }
      .width('100%')

      if (this.mode === 'menu') {
        this.menu()
      } else if (this.mode === 'dual' || this.mode === 'question') {
        this.newMaster()
      } else {
        this.wipePane()
      }

      if (this.error.length > 0) {
        Text(this.error).fontSize(14).fontColor($r('app.color.danger')).width('100%')
      }
      if (this.info.length > 0) {
        Text(this.info).fontSize(14).fontColor($r('app.color.ink_secondary')).width('100%')
      }
      Blank()
    }
    .padding(24)
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_bg'))
  }

  @Builder
  menu() {
    Column({ space: 12 }) {
      Text('需要连续通过两种不同的系统认证，例如指纹和锁屏密码。只通过一种不能重置。')
        .fontSize($r('app.float.caption'))
        .fontColor($r('app.color.ink_secondary'))
        .width('100%')
      AppPrimaryButton({
        label: '双重设备验证',
        enabled: AuthService.query().dualReady(),
        onTap: () => {
          this.doDual();
        }
      })
      if (AppSession.settings.resetQuestion) {
        TextInput({ placeholder: '私密问题答案', text: this.answer })
          .onChange((v: string) => {
            this.answer = v;
          })
        AppGhostButton({
          label: '用私密问题重置',
          onTap: () => {
            this.doQuestion();
          }
        })
      }
      AppGhostButton({
        label: '从加密备份恢复',
        onTap: () => {
          router.pushUrl({ url: 'pages/BackupPage' });
        }
      })
      AppGhostButton({
        label: '清空并重新初始化',
        onTap: () => {
          this.mode = 'wipe';
        }
      })
    }
  }

  @Builder
  newMaster() {
    Column({ space: 12 }) {
      Text('设置新的内置密码')
        .fontSize($r('app.float.body'))
        .width('100%')
      TextInput({ placeholder: '新内置密码', text: this.master })
        .type(InputType.Password)
        .onChange((v: string) => {
          this.master = v;
        })
      TextInput({ placeholder: '再次输入', text: this.master2 })
        .type(InputType.Password)
        .onChange((v: string) => {
          this.master2 = v;
        })
      AppPrimaryButton({
        label: '保存新密码',
        onTap: () => {
          this.saveMaster();
        }
      })
    }
  }

  @Builder
  wipePane() {
    Column({ space: 12 }) {
      Text('这将销毁本机全部密文和钥匙副本。没有备份就无法找回。')
        .fontSize($r('app.float.body'))
        .fontColor($r('app.color.danger'))
        .width('100%')
      Text('请输入：我了解数据将无法恢复')
        .fontSize($r('app.float.caption'))
        .width('100%')
      TextInput({ placeholder: AppConstants.WIPE_PHRASE, text: this.phrase })
        .onChange((v: string) => {
          this.phrase = v;
        })
      AppPrimaryButton({
        label: '确认清空',
        onTap: () => {
          this.wipe();
        }
      })
    }
  }

  private async doDual(): Promise<void> {
    this.error = '';
    const ok = await AppSession.resetMasterDual('pending');
    if (!ok) {
      this.error = '认证未通过，或设备没有两种可用因子。';
      return;
    }
    this.mode = 'dual';
  }

  private async doQuestion(): Promise<void> {
    const ok = await AppSession.unlockWithQuestion(this.answer);
    if (!ok) {
      this.error = '答案不正确，请稍后再试。';
      return;
    }
    this.mode = 'question';
  }

  private async saveMaster(): Promise<void> {
    if (this.master.length < AppConstants.MASTER_MIN_LEN || this.master !== this.master2) {
      this.error = '密码过短或两次不一致';
      return;
    }
    await AppSession.persistWraps(AppSession.vault.dek, this.master, '');
    AppSession.settings.hasMaster = true;
    await AppSession.persist();
    AppStorage.setOrCreate('isLocked', false);
    router.replaceUrl({ url: 'pages/ShellPage' });
  }

  private async wipe(): Promise<void> {
    const ok = await AppSession.factoryReset(this.phrase);
    if (!ok) {
      this.error = '确认短语不正确';
      return;
    }
    router.replaceUrl({ url: 'pages/OnboardingPage' });
  }
}
