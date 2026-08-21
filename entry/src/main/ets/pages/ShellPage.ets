import { router } from '@kit.ArkUI';
import { AppSession } from '../service/AppSession';
import { VaultEntry } from '../model/VaultEntry';
import { EntryKind, EntryKindUtil } from '../model/EntryKind';
import { DiaryBook, DiaryEntry } from '../model/DiaryModels';
import { CheckIssue } from '../service/SecurityChecker';
import { EmptyState, SettingRow } from '../common/components/AppWidgets';
import { AppConstants } from '../common/constants/AppConstants';
import { DateGroupUtil } from '../common/utils/DateGroupUtil';
import { SearchUtil } from '../common/utils/SearchUtil';
import { IdUtil } from '../common/utils/IdUtil';
import { ClipboardGuard } from '../service/ClipboardGuard';
import { AuthService } from '../service/AuthService';
import { GroupBucket } from '../model/GroupBucket';

@Entry
@Component
struct ShellPage {
  @StorageLink('windowWidthVp') widthVp: number = 400;
  @StorageLink('showMask') showMask: boolean = false;
  @StorageLink('isLocked') isLocked: boolean = false;
  @State tab: string = 'vault';
  @State kind: string = 'all';
  @State query: string = '';
  @State sortMode: string = 'modified';
  @State selectedId: string = '';
  @State tick: number = 0;
  @State showAdd: boolean = false;
  @State showSecret: boolean = false;
  @State clipboardLeft: number = 0;
  @State decoyPw: string = '';
  @State question: string = '';
  @State answer: string = '';

  private bp(): string {
    if (this.widthVp < AppConstants.SM) {
      return 'sm';
    }
    if (this.widthVp < AppConstants.LG) {
      return 'md';
    }
    return 'lg';
  }

  aboutToAppear(): void {
    if (this.isLocked || !AppSession.unlocked) {
      router.replaceUrl({ url: 'pages/UnlockPage' });
    }
  }

  private items(): VaultEntry[] {
    return AppSession.vault.list(this.kind, this.query, this.sortMode, Date.now());
  }

  private selected(): VaultEntry | undefined {
    return AppSession.vault.byId(this.selectedId);
  }

  build() {
    Stack() {
      Column() {
        if (this.bp() === 'sm') {
          this.phoneShell()
        } else {
          this.wideShell()
        }
      }
      .width('100%')
      .height('100%')

      if (this.showAdd) {
        this.addSheet()
      }
      if (this.showMask) {
        Column() {
          Text('0号保险库')
            .fontSize(20)
            .fontColor($r('app.color.ink_secondary'))
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .backgroundColor($r('app.color.mask'))
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_bg'))
    .onKeyEvent((e: KeyEvent) => {
      this.handleKey(e);
    })
  }

  private handleKey(e: KeyEvent): void {
    if (e.type !== KeyType.Down) {
      return;
    }
    if (e.ctrl && e.keyCode === 2038) {
      this.showAdd = true;
    }
    if (e.ctrl && e.keyCode === 2036) {
      this.tab = 'vault';
    }
    if (e.ctrl && e.keyCode === 2037) {
      AppSession.lock();
      AppStorage.setOrCreate('isLocked', true);
      router.replaceUrl({ url: 'pages/UnlockPage' });
    }
  }

  @Builder
  phoneShell() {
    Column() {
      this.topBar()
      Tabs({ barPosition: BarPosition.End, index: this.tabIndex() }) {
        TabContent() {
          this.vaultPane(true)
        }
        .tabBar(this.bar('保险库', $r('sys.symbol.house')))

        TabContent() {
          this.diaryPane()
        }
        .tabBar(this.bar('日记', $r('sys.symbol.book')))

        TabContent() {
          this.checkPane()
        }
        .tabBar(this.bar('检查', $r('sys.symbol.checkmark_shield')))

        TabContent() {
          this.settingsPane()
        }
        .tabBar(this.bar('设置', $r('sys.symbol.gearshape')))
      }
      .layoutWeight(1)
      .barBackgroundColor($r('app.color.surface'))
      .onChange((i: number) => {
        const names = ['vault', 'diary', 'check', 'settings'];
        this.tab = names[i];
      })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  wideShell() {
    Row() {
      Column({ space: 8 }) {
        Text('0')
          .fontSize(22)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.accent'))
          .margin({ top: 16, bottom: 12 })
        this.sideBtn('vault', '保险库', $r('sys.symbol.house'))
        this.sideBtn('diary', '日记', $r('sys.symbol.book'))
        this.sideBtn('check', '检查', $r('sys.symbol.checkmark_shield'))
        this.sideBtn('settings', '设置', $r('sys.symbol.gearshape'))
        Blank()
        this.iconBtn($r('sys.symbol.qrcode'), () => {
          router.pushUrl({ url: 'pages/QrCodePage' });
        })
        this.iconBtn($r('sys.symbol.lock'), () => {
          AppSession.lock();
          AppStorage.setOrCreate('isLocked', true);
          router.replaceUrl({ url: 'pages/UnlockPage' });
        })
      }
      .width(72)
      .height('100%')
      .backgroundColor($r('app.color.surface'))
      .padding({ bottom: 16 })

      if (this.tab === 'vault') {
        this.vaultPane(false)
      } else if (this.tab === 'diary') {
        this.diaryPane()
      } else if (this.tab === 'check') {
        this.checkPane()
      } else {
        this.settingsPane()
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  sideBtn(id: string, label: string, icon: Resource) {
    Column({ space: 4 }) {
      SymbolGlyph(icon)
        .fontSize(22)
        .fontColor(this.tab === id ? $r('app.color.accent') : $r('app.color.ink_secondary'))
      Text(label)
        .fontSize(10)
        .fontColor(this.tab === id ? $r('app.color.accent') : $r('app.color.ink_tertiary'))
    }
    .width('100%')
    .padding({ top: 10, bottom: 10 })
    .onClick(() => {
      this.tab = id;
    })
  }

  @Builder
  iconBtn(icon: Resource, tap: () => void) {
    SymbolGlyph(icon)
      .fontSize(22)
      .fontColor($r('app.color.ink'))
      .padding(12)
      .onClick(tap)
  }

  @Builder
  bar(label: string, icon: Resource) {
    Column({ space: 2 }) {
      SymbolGlyph(icon).fontSize(20).fontColor($r('app.color.ink'))
      Text(label).fontSize(10).fontColor($r('app.color.ink_secondary'))
    }
  }

  private tabIndex(): number {
    if (this.tab === 'diary') {
      return 1;
    }
    if (this.tab === 'check') {
      return 2;
    }
    if (this.tab === 'settings') {
      return 3;
    }
    return 0;
  }

  @Builder
  topBar() {
    Row() {
      Text('0号保险库')
        .fontSize($r('app.float.title_card'))
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.ink'))
      Blank()
      SymbolGlyph($r('sys.symbol.qrcode'))
        .fontSize(22)
        .onClick(() => {
          router.pushUrl({ url: 'pages/QrCodePage' });
        })
      SymbolGlyph($r('sys.symbol.lock'))
        .fontSize(22)
        .margin({ left: 16 })
        .onClick(() => {
          AppSession.lock();
          AppStorage.setOrCreate('isLocked', true);
          router.replaceUrl({ url: 'pages/UnlockPage' });
        })
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 12, bottom: 8 })
  }

  @Builder
  vaultPane(phone: boolean) {
    Row() {
      Column() {
        Search({ value: this.query, placeholder: '搜索名称、用户名、网址或标签' })
          .onChange((v: string) => {
            this.query = v;
          })
          .margin({ left: 16, right: 16, top: 8, bottom: 8 })

        Scroll() {
          Row({ space: 8 }) {
            ForEach(this.filters(), (f: string[]) => {
              Text(f[1])
                .fontSize(12)
                .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                .borderRadius(14)
                .backgroundColor(this.kind === f[0] ? $r('app.color.accent') : $r('app.color.surface_muted'))
                .fontColor(this.kind === f[0] ? Color.White : $r('app.color.ink'))
                .onClick(() => {
                  this.kind = f[0];
                })
            }, (f: string[]) => f[0])
          }
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .padding({ left: 16, right: 16 })

        Row() {
          Text(this.sortLabel())
            .fontSize(12)
            .fontColor($r('app.color.ink_tertiary'))
            .onClick(() => {
              this.cycleSort();
            })
          Blank()
          Button('新建')
            .height(36)
            .borderRadius(12)
            .backgroundColor($r('app.color.accent'))
            .onClick(() => {
              this.showAdd = true;
            })
        }
        .padding({ left: 20, right: 16, top: 8, bottom: 8 })
        .width('100%')

        if (this.items().length === 0) {
          EmptyState({
            title: this.query.length > 0 ? '没有匹配结果' : '还没有条目',
            body: this.query.length > 0 ? '试试更短的关键词。密码正文不会出现在搜索里。' :
              '保存第一组账号、WiFi 或笔记。内容只存放在本机。',
            action: this.query.length > 0 ? '' : '新建条目',
            onAction: () => {
              this.showAdd = true;
            }
          })
        } else {
          List({ space: 8 }) {
            ForEach(this.grouped(), (g: GroupBucket) => {
              ListItemGroup({ header: this.groupHeader(g.label) }) {
                ForEach(g.items, (e: VaultEntry) => {
                  ListItem() {
                    this.entryRow(e)
                  }
                }, (e: VaultEntry) => e.id)
              }
            }, (g: GroupBucket) => g.key)
          }
          .layoutWeight(1)
          .padding({ left: 12, right: 12, bottom: 12 })
        }
      }
      .layoutWeight(this.bp() === 'lg' && !phone ? 1 : 1)
      .height('100%')

      if (this.bp() === 'lg' && !phone) {
        Divider().vertical(true).color($r('app.color.line'))
        this.detailPane()
      }
    }
    .width('100%')
    .layoutWeight(1)
  }

  @Builder
  groupHeader(label: string) {
    Text(label)
      .fontSize(12)
      .fontColor($r('app.color.ink_tertiary'))
      .padding({ left: 8, top: 10, bottom: 6 })
  }

  @Builder
  entryRow(e: VaultEntry) {
    Row({ space: 12 }) {
      Column() {
        Text(EntryKindUtil.label(e.kind).substring(0, 1))
          .fontSize(14)
          .fontColor($r('app.color.accent'))
      }
      .width(40)
      .height(40)
      .borderRadius(12)
      .backgroundColor($r('app.color.accent_soft'))
      .justifyContent(FlexAlign.Center)

      Column({ space: 4 }) {
        Text(e.displayTitle())
          .fontSize(16)
          .fontColor($r('app.color.ink'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(e.displaySub().length > 0 ? e.displaySub() : EntryKindUtil.label(e.kind))
          .fontSize(12)
          .fontColor($r('app.color.ink_tertiary'))
          .maxLines(1)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      if (e.favorite) {
        Text('收藏').fontSize(10).fontColor($r('app.color.warning'))
      }
    }
    .width('100%')
    .height(72)
    .padding({ left: 12, right: 12 })
    .borderRadius(16)
    .backgroundColor(this.selectedId === e.id ? $r('app.color.accent_soft') : $r('app.color.surface'))
    .onClick(() => {
      this.openEntry(e);
    })
    .gesture(
      LongPressGesture().onAction(() => {
        AppStorage.setOrCreate('editEntryId', e.id);
        router.pushUrl({ url: 'pages/EntryEditPage' });
      })
    )
  }

  @Builder
  detailPane() {
    Column() {
      if (!this.selected()) {
        EmptyState({ title: '选择一条目', body: '从左侧列表打开详情。三栏布局适合电脑与平板横屏。' })
      } else {
        this.detailBody(this.selected() as VaultEntry)
      }
    }
    .width(360)
    .height('100%')
    .padding(16)
    .backgroundColor($r('app.color.surface'))
  }

  @Builder
  detailBody(e: VaultEntry) {
    Scroll() {
      Column({ space: 12 }) {
        Text(e.displayTitle())
          .fontSize(22)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.ink'))
          .width('100%')
        Text(EntryKindUtil.label(e.kind) + ' · ' + e.colorName)
          .fontSize(12)
          .fontColor($r('app.color.ink_tertiary'))
          .width('100%')
        this.field('用户名', e.username, false)
        this.field('密码', e.password, true)
        this.field('网址', e.url, false)
        this.field('网络名称', e.wifiSsid, false)
        this.field('备注', e.notes, false)
        Text('使用 ' + e.useCount + ' 次')
          .fontSize(12)
          .fontColor($r('app.color.ink_tertiary'))
        Row({ space: 8 }) {
          Button('编辑').onClick(() => {
            AppStorage.setOrCreate('editEntryId', e.id);
            router.pushUrl({ url: 'pages/EntryEditPage' });
          })
          Button('复制密码').onClick(() => {
            this.copySecret(e);
          })
          if (e.kind === EntryKind.WIFI) {
            Button('二维码').onClick(() => {
              AppStorage.setOrCreate('qrPreset', 'wifi:' + e.id);
              router.pushUrl({ url: 'pages/QrCodePage' });
            })
          }
          Button(this.kind === 'recycle' ? '恢复' : '删除').onClick(() => {
            if (this.kind === 'recycle') {
              AppSession.vault.restore(e.id);
            } else {
              AppSession.vault.softDelete(e.id, AppSession.settings.recycleEnabled);
            }
            AppSession.persist();
            this.tick++;
          })
        }
      }
    }
    .width('100%')
  }

  @Builder
  field(label: string, value: string, secret: boolean) {
    if (value.length === 0) {
      Column() {}
    } else {
      Column({ space: 4 }) {
        Text(label).fontSize(12).fontColor($r('app.color.ink_tertiary')).width('100%')
        Row() {
          Text(secret && !this.showSecret ? '••••••••' : value)
            .fontSize(16)
            .fontColor($r('app.color.ink'))
            .fontFamily(secret ? 'monospace' : '')
            .layoutWeight(1)
          if (secret) {
            Text(this.showSecret ? '隐藏' : '显示')
              .fontSize(12)
              .fontColor($r('app.color.accent'))
              .onClick(() => {
                this.showSecret = !this.showSecret;
              })
          }
        }
        .width('100%')
      }
      .padding(12)
      .backgroundColor($r('app.color.page_bg'))
      .borderRadius(12)
      .width('100%')
    }
  }

  @Builder
  addSheet() {
    Column() {
      Column({ space: 8 }) {
        Text('选择类型')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .width('100%')
        ForEach(EntryKindUtil.all(), (k: EntryKind) => {
          Row() {
            Text(EntryKindUtil.label(k)).fontSize(16).fontColor($r('app.color.ink'))
          }
          .width('100%')
          .height(56)
          .padding({ left: 8 })
          .onClick(() => {
            const e = AppSession.newEntry(k);
            AppSession.vault.upsert(e, AppSession.random, false);
            AppSession.persist();
            this.showAdd = false;
            AppStorage.setOrCreate('editEntryId', e.id);
            router.pushUrl({ url: 'pages/EntryEditPage' });
          })
        }, (k: EntryKind) => '' + k)
        Button('取消', { type: ButtonType.Normal })
          .backgroundColor($r('app.color.surface_muted'))
          .fontColor($r('app.color.ink'))
          .onClick(() => {
            this.showAdd = false;
          })
      }
      .padding(20)
      .backgroundColor($r('app.color.surface'))
      .borderRadius(20)
      .width('100%')
      .constraintSize({ maxWidth: 420 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.End)
    .padding(16)
    .backgroundColor('#66000000')
    .onClick(() => {
      this.showAdd = false;
    })
  }

  @Builder
  diaryPane() {
    Column() {
      Row() {
        Text('日记本').fontSize(20).fontWeight(FontWeight.Medium)
        Blank()
        Button('写一篇').onClick(() => {
          this.newDiary();
        })
      }
      .padding(16)
      .width('100%')

      if (AppSession.vault.snapshot.diary.filter((d: DiaryEntry) => d.deletedAt <= 0).length === 0) {
        EmptyState({
          title: '还没有日记',
          body: '写下今天的事情。正文、录音和配图都会加密保存。',
          action: '写一篇',
          onAction: () => {
            this.newDiary();
          }
        })
      } else {
        List({ space: 8 }) {
          ForEach(this.diaryItems(), (d: DiaryEntry) => {
            ListItem() {
              Column({ space: 6 }) {
                Text(this.dayLabel(d.day))
                  .fontSize(18)
                  .fontWeight(FontWeight.Medium)
                  .fontColor($r('app.color.ink'))
                  .width('100%')
                Text(d.title.length > 0 ? d.title : d.body.substring(0, 48))
                  .fontSize(14)
                  .fontColor($r('app.color.ink_secondary'))
                  .maxLines(2)
                  .width('100%')
              }
              .padding(16)
              .borderRadius(16)
              .backgroundColor($r('app.color.surface'))
              .width('100%')
              .onClick(() => {
                AppStorage.setOrCreate('diaryId', d.id);
                router.pushUrl({ url: 'pages/DiaryEditPage' });
              })
            }
          }, (d: DiaryEntry) => d.id)
        }
        .padding(12)
        .layoutWeight(1)
      }
    }
    .width('100%')
    .layoutWeight(1)
  }

  @Builder
  checkPane() {
    Column({ space: 12 }) {
      Text('安全检查')
        .fontSize(20)
        .fontWeight(FontWeight.Medium)
        .padding({ left: 20, top: 16 })
        .width('100%')
      Text('检查只在本机进行，不会查询任何在线泄露库。')
        .fontSize(12)
        .fontColor($r('app.color.ink_tertiary'))
        .padding({ left: 20, right: 20 })
        .width('100%')
      if (this.issues().length === 0) {
        EmptyState({ title: '没有需要处理的问题', body: '当前没有弱密码、重复密码或已过期证件。' })
      } else {
        List({ space: 8 }) {
          ForEach(this.issues(), (i: CheckIssue) => {
            ListItem() {
              Column({ space: 4 }) {
                Text(i.title).fontSize(16).fontColor($r('app.color.ink')).width('100%')
                Text(this.issueKind(i.kind) + ' · ' + i.detail)
                  .fontSize(12)
                  .fontColor($r('app.color.danger'))
                  .width('100%')
              }
              .padding(16)
              .borderRadius(16)
              .backgroundColor($r('app.color.surface'))
              .width('100%')
              .onClick(() => {
                this.kind = 'all';
                this.tab = 'vault';
                const e = AppSession.vault.byId(i.entryId);
                if (e) {
                  this.openEntry(e);
                }
              })
            }
          }, (i: CheckIssue) => i.entryId + i.kind)
        }
        .padding(12)
        .layoutWeight(1)
      }
    }
    .width('100%')
    .layoutWeight(1)
  }

  @Builder
  settingsPane() {
    Scroll() {
      Column() {
        Text('设置').fontSize(20).fontWeight(FontWeight.Medium).width('100%').margin({ bottom: 12 })
        this.section('安全设置')
        SettingRow({
          title: '应用锁',
          desc: '打开后，进入应用需要设备认证或内置密码。关闭后任何人拿起已解锁的手机都能看到条目列表。',
          checked: AppSession.settings.appLockEnabled,
          onChange: (v: boolean) => {
            AppSession.settings.appLockEnabled = v;
            AppSession.persist();
          }
        })
        SettingRow({
          title: '查看密码前验证',
          desc: '打开后，显示明文密码需要再认证一次。',
          checked: AppSession.settings.viewAuth,
          onChange: (v: boolean) => {
            AppSession.settings.viewAuth = v;
            AppSession.persist();
          }
        })
        SettingRow({
          title: '复制密码前验证',
          desc: '复制密码前再确认一次是你本人。',
          checked: AppSession.settings.copyAuth,
          onChange: (v: boolean) => {
            AppSession.settings.copyAuth = v;
            AppSession.persist();
          }
        })
        SettingRow({
          title: '显示验证码前验证',
          desc: '显示 TOTP 前再认证。',
          checked: AppSession.settings.totpAuth,
          onChange: (v: boolean) => {
            AppSession.settings.totpAuth = v;
            AppSession.persist();
          }
        })
        SettingRow({
          title: '导出或备份前验证',
          desc: '导出加密备份前再认证。',
          checked: AppSession.settings.exportAuth,
          onChange: (v: boolean) => {
            AppSession.settings.exportAuth = v;
            AppSession.persist();
          }
        })
        this.section('隐私保护')
        SettingRow({
          title: '防截屏、录屏和投屏',
          desc: '打开后，系统会阻止截屏和录屏。部分投屏场景仍可能被对方看到。',
          checked: AppSession.settings.privacyWindow,
          onChange: (v: boolean) => {
            AppSession.settings.privacyWindow = v;
            AppSession.applyPrivacy();
            AppSession.persist();
          }
        })
        SettingRow({
          title: '后台隐私遮罩',
          desc: '离开应用时用空白页盖住内容，避免多任务预览泄露。',
          checked: AppSession.settings.backgroundMask,
          onChange: (v: boolean) => {
            AppSession.settings.backgroundMask = v;
            AppSession.persist();
          }
        })
        SettingRow({
          title: '剪贴板自动清理',
          desc: '复制后倒计时清除，且只清除仍是本应用写入的内容。当前 ' +
            AppSession.settings.clipboardSec + ' 秒。',
          checked: AppSession.settings.clipboardSec > 0,
          onChange: (v: boolean) => {
            AppSession.settings.clipboardSec = v ? 30 : 0;
            AppSession.persist();
          }
        })
        SettingRow({
          title: '回收站',
          desc: '关闭后删除将立即永久清除，无法恢复。',
          checked: AppSession.settings.recycleEnabled,
          onChange: (v: boolean) => {
            AppSession.settings.recycleEnabled = v;
            AppSession.persist();
          }
        })
        SettingRow({
          title: '使用频率统计',
          desc: '仅用于排序和最常用，数据留在本机。',
          checked: AppSession.settings.statsEnabled,
          onChange: (v: boolean) => {
            AppSession.settings.statsEnabled = v;
            AppSession.persist();
          }
        })
        this.section('数据管理')
        Button('导出与导入', { type: ButtonType.Normal })
          .width('100%')
          .backgroundColor($r('app.color.surface_muted'))
          .fontColor($r('app.color.ink'))
          .onClick(() => {
            router.pushUrl({ url: 'pages/BackupPage' });
          })
        Button('密码生成器', { type: ButtonType.Normal })
          .width('100%')
          .backgroundColor($r('app.color.surface_muted'))
          .fontColor($r('app.color.ink'))
          .margin({ top: 8 })
          .onClick(() => {
            router.pushUrl({ url: 'pages/GeneratorPage' });
          })
        Button('验证码工具', { type: ButtonType.Normal })
          .width('100%')
          .backgroundColor($r('app.color.surface_muted'))
          .fontColor($r('app.color.ink'))
          .margin({ top: 8 })
          .onClick(() => {
            router.pushUrl({ url: 'pages/TotpPage' });
          })
        this.section('伪装保险库')
        SettingRow({
          title: '伪装保险库',
          desc: '用另一组密码打开一个完全隔离的空库。不能对抗取证。',
          checked: AppSession.settings.decoyEnabled,
          onChange: (v: boolean) => {
            AppSession.settings.decoyEnabled = v;
            AppSession.persist();
          }
        })
        if (AppSession.settings.decoyEnabled) {
          TextInput({ placeholder: '设置伪装密码', text: this.decoyPw })
            .type(InputType.Password)
            .onChange((v: string) => {
              this.decoyPw = v;
            })
          Button('保存伪装密码').onClick(() => {
            if (this.decoyPw.length >= 10) {
              AppSession.enableDecoy(this.decoyPw);
            }
          })
        }
        this.section('私密问题')
        SettingRow({
          title: '自定义私密问题重置',
          desc: '自己写问题与答案，不使用容易猜的预设题。',
          checked: AppSession.settings.resetQuestion,
          onChange: (v: boolean) => {
            AppSession.settings.resetQuestion = v;
            AppSession.persist();
          }
        })
        if (AppSession.settings.resetQuestion) {
          TextInput({ placeholder: '问题', text: this.question })
            .onChange((v: string) => {
              this.question = v;
            })
          TextInput({ placeholder: '答案', text: this.answer })
            .onChange((v: string) => {
              this.answer = v;
            })
          Button('保存问题').onClick(() => {
            AppSession.settings.questionText = this.question;
            AppSession.persistWraps(AppSession.vault.dek,
              '', this.answer);
            AppSession.persist();
          })
        }
        this.section('关于')
        Text('如需保管普通文件，请使用系统自带的文件保险箱。本应用不提供通用文件柜。')
          .fontSize(12)
          .fontColor($r('app.color.ink_secondary'))
          .width('100%')
          .margin({ top: 8, bottom: 8 })
        Button('关于与隐私说明', { type: ButtonType.Normal })
          .width('100%')
          .backgroundColor($r('app.color.surface_muted'))
          .fontColor($r('app.color.ink'))
          .onClick(() => {
            router.pushUrl({ url: 'pages/AboutPage' });
          })
      }
      .padding(20)
      .constraintSize({ maxWidth: 640 })
      .width('100%')
    }
    .width('100%')
    .layoutWeight(1)
    .align(Alignment.Top)
  }

  @Builder
  section(title: string) {
    Text(title)
      .fontSize(12)
      .fontColor($r('app.color.ink_tertiary'))
      .margin({ top: 20, bottom: 4 })
      .width('100%')
  }

  private filters(): string[][] {
    return [
      ['all', '全部'], ['login', '登录密码'], ['wifi', 'WiFi'], ['card', '银行卡'],
      ['id', '证件'], ['note', '安全笔记'], ['server', '服务器'], ['totp', '验证码'],
      ['fav', '收藏'], ['frequent', '最常用'], ['recent', '最近使用'], ['added', '最近添加'],
      ['recycle', '回收站']
    ];
  }

  private grouped(): GroupBucket[] {
    const list = this.kind === 'frequent' ?
      SearchUtil.frequent(AppSession.vault.snapshot.entries, 30) : this.items();
    const buckets: GroupBucket[] = [];
    const order = [DateGroupUtil.TODAY, DateGroupUtil.WEEK, DateGroupUtil.MONTH, DateGroupUtil.OLDER];
    for (let i = 0; i < order.length; i++) {
      const b = new GroupBucket();
      b.key = order[i];
      b.label = DateGroupUtil.label(order[i]);
      b.items = [];
      buckets.push(b);
    }
    const now = Date.now();
    for (let i = 0; i < list.length; i++) {
      const g = SearchUtil.groupKey(list[i], this.sortMode === 'created', now);
      for (let j = 0; j < buckets.length; j++) {
        if (buckets[j].key === g) {
          buckets[j].items.push(list[i]);
        }
      }
    }
    const out: GroupBucket[] = [];
    for (let i = 0; i < buckets.length; i++) {
      if (buckets[i].items.length > 0) {
        out.push(buckets[i]);
      }
    }
    return out;
  }

  private sortLabel(): string {
    if (this.sortMode === 'freq') {
      return '排序：使用频率';
    }
    if (this.sortMode === 'used') {
      return '排序：最近使用';
    }
    if (this.sortMode === 'created') {
      return '排序：创建时间';
    }
    if (this.sortMode === 'name') {
      return '排序：名称';
    }
    return '排序：最近修改';
  }

  private cycleSort(): void {
    const modes = ['modified', 'freq', 'used', 'created', 'name'];
    const i = modes.indexOf(this.sortMode);
    this.sortMode = modes[(i + 1) % modes.length];
  }

  private openEntry(e: VaultEntry): void {
    this.selectedId = e.id;
    AppSession.vault.markUsed(e.id, AppSession.settings.statsEnabled);
    AppSession.persist();
    if (this.bp() === 'sm') {
      AppStorage.setOrCreate('detailEntryId', e.id);
      router.pushUrl({ url: 'pages/EntryDetailPage' });
    }
  }

  private async copySecret(e: VaultEntry): Promise<void> {
    if (AppSession.settings.copyAuth) {
      const ok = await AuthService.deviceUnlock();
      if (!ok) {
        return;
      }
    }
    await ClipboardGuard.copy(e.password, AppSession.settings.clipboardSec, AppSession.settings.clipboardLocal);
    this.clipboardLeft = AppSession.settings.clipboardSec;
  }

  private newDiary(): void {
    let book = AppSession.vault.snapshot.books[0];
    if (!book) {
      book = new DiaryBook();
      book.id = IdUtil.randomId(AppSession.random);
      book.title = '日记本';
      book.createdAt = Date.now();
      AppSession.vault.snapshot.books.push(book);
    }
    const d = new DiaryEntry();
    d.id = IdUtil.randomId(AppSession.random);
    d.bookId = book.id;
    d.day = Date.now();
    d.createdAt = Date.now();
    d.modifiedAt = d.createdAt;
    AppSession.vault.snapshot.diary.push(d);
    AppSession.persist();
    AppStorage.setOrCreate('diaryId', d.id);
    router.pushUrl({ url: 'pages/DiaryEditPage' });
  }

  private diaryItems(): DiaryEntry[] {
    const list: DiaryEntry[] = [];
    const src = AppSession.vault.snapshot.diary;
    for (let i = 0; i < src.length; i++) {
      if (src[i].deletedAt <= 0) {
        list.push(src[i]);
      }
    }
    list.sort((a: DiaryEntry, b: DiaryEntry) => b.day - a.day);
    return list;
  }

  private dayLabel(ts: number): string {
    const d = new Date(ts);
    return d.getFullYear() + '年' + (d.getMonth() + 1) + '月' + d.getDate() + '日';
  }

  private issues(): CheckIssue[] {
    return AppSession.vault.issues(Date.now());
  }

  private issueKind(k: string): string {
    if (k === 'weak') {
      return '弱密码';
    }
    if (k === 'reuse') {
      return '重复密码';
    }
    if (k === 'stale') {
      return '长期未更换';
    }
    return '已过期';
  }
}
