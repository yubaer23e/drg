import { router } from '@kit.ArkUI';
import { AppSession } from '../service/AppSession';
import { AppConstants } from '../common/constants/AppConstants';
import { AppPrimaryButton, AppGhostButton } from '../common/components/AppWidgets';
import { PasswordGenerator } from '../service/PasswordGenerator';

@Entry
@Component
struct OnboardingPage {
  @State step: number = 0;
  @State lockChoice: string = 'device';
  @State master: string = '';
  @State master2: string = '';
  @State error: string = '';

  build() {
    Column() {
      Column({ space: 16 }) {
        Text('0号保险库')
          .fontSize($r('app.float.title_page'))
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.ink'))
          .width('100%')

        if (this.step === 0) {
          this.pageCard('零联网，本地保管',
            '本应用不申请网络权限，也不包含云同步、账号或统计。密码、日记和备份口令不会离开这台设备。')
        } else if (this.step === 1) {
          this.pageCard('硬件加密始终开启',
            '条目在设备上以加密形式保存。应用锁、生物认证和防截屏都可以按你的需要打开或关闭，底层加密不会因此停止。')
        } else if (this.step === 2) {
          this.pageCard('请先想好如何找回',
            '忘记应用内置密码时，可用双重设备验证或你自己写的私密问题重置。系统指纹或锁屏密码忘了，需要在系统设置里处理。请尽快做一份加密备份。')
        } else if (this.step === 3) {
          this.lockPane()
        } else {
          this.masterPane()
        }
      }
      .layoutWeight(1)
      .width('100%')

      if (this.error.length > 0) {
        Text(this.error)
          .fontSize($r('app.float.caption'))
          .fontColor($r('app.color.danger'))
          .width('100%')
          .margin({ bottom: 8 })
      }

      AppPrimaryButton({
        label: this.step < 4 ? '继续' : '开始使用',
        onTap: () => {
          this.advance();
        }
      })
      if (this.step === 3) {
        AppGhostButton({
          label: '暂不设置应用锁',
          onTap: () => {
            this.finish(true);
          }
        })
      }
    }
    .padding({ left: 24, right: 24, top: 48, bottom: 24 })
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_bg'))
  }

  @Builder
  pageCard(title: string, body: string) {
    Column({ space: 12 }) {
      Text(title)
        .fontSize($r('app.float.title_card'))
        .fontColor($r('app.color.ink'))
        .width('100%')
      Text(body)
        .fontSize($r('app.float.body'))
        .fontColor($r('app.color.ink_secondary'))
        .lineHeight(24)
        .width('100%')
    }
    .padding(20)
    .backgroundColor($r('app.color.surface'))
    .borderRadius($r('app.float.radius_md'))
    .width('100%')
  }

  @Builder
  lockPane() {
    Column({ space: 12 }) {
      Text('选择打开方式')
        .fontSize($r('app.float.title_card'))
        .fontColor($r('app.color.ink'))
        .width('100%')
      Text('你可以稍后再开。即使关掉应用锁，数据仍会加密存放。')
        .fontSize($r('app.float.caption'))
        .fontColor($r('app.color.ink_secondary'))
        .width('100%')
      this.choice('device', '使用设备认证（指纹、人脸或锁屏密码）')
      this.choice('master', '设置应用内置密码')
      this.choice('none', '不额外加锁')
    }
    .width('100%')
  }

  @Builder
  choice(id: string, label: string) {
    Row() {
      Text(label)
        .fontSize($r('app.float.body'))
        .fontColor($r('app.color.ink'))
        .layoutWeight(1)
    }
    .width('100%')
    .padding(16)
    .borderRadius(12)
    .backgroundColor(this.lockChoice === id ? $r('app.color.accent_soft') : $r('app.color.surface'))
    .onClick(() => {
      this.lockChoice = id;
    })
  }

  @Builder
  masterPane() {
    Column({ space: 12 }) {
      Text('设置内置密码')
        .fontSize($r('app.float.title_card'))
        .fontColor($r('app.color.ink'))
        .width('100%')
      Text('至少 10 位，请使用你能记住且足够独特的口令。')
        .fontSize($r('app.float.caption'))
        .fontColor($r('app.color.ink_secondary'))
        .width('100%')
      TextInput({ placeholder: '内置密码', text: this.master })
        .type(InputType.Password)
        .onChange((v: string) => {
          this.master = v;
        })
      TextInput({ placeholder: '再次输入', text: this.master2 })
        .type(InputType.Password)
        .onChange((v: string) => {
          this.master2 = v;
        })
      Text('强度：' + PasswordGenerator.strengthLabel(this.master.length * 4))
        .fontSize($r('app.float.hint'))
        .fontColor($r('app.color.ink_tertiary'))
    }
    .width('100%')
  }

  private advance(): void {
    this.error = '';
    if (this.step < 3) {
      this.step += 1;
      return;
    }
    if (this.step === 3) {
      if (this.lockChoice === 'master') {
        this.step = 4;
        return;
      }
      this.finish(this.lockChoice === 'none');
      return;
    }
    if (this.master.length < AppConstants.MASTER_MIN_LEN) {
      this.error = '内置密码至少 10 位';
      return;
    }
    if (this.master !== this.master2) {
      this.error = '两次输入不一致';
      return;
    }
    this.finish(false);
  }

  private async finish(skipLock: boolean): Promise<void> {
    const method = this.lockChoice === 'none' ? 'none' : this.lockChoice;
    await AppSession.initializeVault(method, this.lockChoice === 'master' ? this.master : '', skipLock);
    AppStorage.setOrCreate('isLocked', false);
    router.replaceUrl({ url: 'pages/ShellPage' });
  }
}
