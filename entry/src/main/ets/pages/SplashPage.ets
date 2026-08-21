import { router } from '@kit.ArkUI';
import { AppSession } from '../service/AppSession';

@Entry
@Component
struct SplashPage {
  @StorageLink('sessionReady') sessionReady: boolean = false;
  private routed: boolean = false;

  @Watch('sessionReady')
  onSessionReady(): void {
    this.tryRoute();
  }

  aboutToAppear(): void {
    this.tryRoute();
  }

  onPageShow(): void {
    this.tryRoute();
  }

  private async tryRoute(): Promise<void> {
    if (!this.sessionReady || this.routed) {
      return;
    }
    this.routed = true;
    if (!AppSession.settings.initialized) {
      router.replaceUrl({ url: 'pages/OnboardingPage' });
      return;
    }
    if (AppSession.settings.appLockEnabled) {
      AppSession.lock();
      router.replaceUrl({ url: 'pages/UnlockPage' });
      return;
    }
    const opened = await AppSession.unlockWithDevice();
    if (opened) {
      AppStorage.setOrCreate('isLocked', false);
      router.replaceUrl({ url: 'pages/ShellPage' });
    } else {
      router.replaceUrl({ url: 'pages/UnlockPage' });
    }
  }

  build() {
    Column() {
      Column({ space: 12 }) {
        Text('0号保险库')
          .fontSize($r('app.float.title_display'))
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.ink'))
        Text('秘密只留在你自己的设备里')
          .fontSize($r('app.float.caption'))
          .fontColor($r('app.color.ink_secondary'))
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor($r('app.color.page_bg'))
    .onAppear(() => {
      this.tryRoute();
    })
  }
}
