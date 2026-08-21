import { router } from '@kit.ArkUI';
import { picker } from '@kit.CoreFileKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { AppSession } from '../service/AppSession';
import { ZvaultCodec } from '../format/ZvaultCodec';
import { VaultSnapshot } from '../store/MemoryVault';
import { AuthService } from '../service/AuthService';
import { AppPrimaryButton } from '../common/components/AppWidgets';
import { AppConstants } from '../common/constants/AppConstants';

@Entry
@Component
struct BackupPage {
  @State exportPw: string = '';
  @State exportPw2: string = '';
  @State importPw: string = '';
  @State message: string = '';
  @State error: string = '';

  build() {
    Column({ space: 14 }) {
      Row() {
        SymbolGlyph($r('sys.symbol.chevron_left')).fontSize(22).onClick(() => {
          router.back();
        })
        Blank()
        Text('导出与导入').fontSize(18).fontWeight(FontWeight.Medium)
        Blank()
      }
      .width('100%')

      Text('文字与结构化数据导出为加密 .zvault。照片和录音走普通导出，导出后不再受本应用保护。')
        .fontSize(14)
        .fontColor($r('app.color.ink_secondary'))
        .width('100%')

      TextInput({ text: this.exportPw, placeholder: '设置导出密码' })
        .type(InputType.Password)
        .onChange((v: string) => {
          this.exportPw = v;
        })
      TextInput({ text: this.exportPw2, placeholder: '确认导出密码' })
        .type(InputType.Password)
        .onChange((v: string) => {
          this.exportPw2 = v;
        })
      AppPrimaryButton({
        label: '导出加密保险库',
        onTap: () => {
          this.doExport();
        }
      })

      TextInput({ text: this.importPw, placeholder: '导入时的导出密码' })
        .type(InputType.Password)
        .onChange((v: string) => {
          this.importPw = v;
        })
      Button('从备份恢复（完整替换）', { type: ButtonType.Normal })
        .width('100%')
        .onClick(() => {
          this.doImport(true);
        })
      Button('合并导入', { type: ButtonType.Normal })
        .width('100%')
        .onClick(() => {
          this.doImport(false);
        })
      Text('导出后的照片和录音不再受本应用加密保护，请自行保管。')
        .fontSize(12)
        .fontColor($r('app.color.warning'))
        .width('100%')

      if (this.message.length > 0) {
        Text(this.message).fontSize(14).fontColor($r('app.color.accent')).width('100%')
      }
      if (this.error.length > 0) {
        Text(this.error).fontSize(14).fontColor($r('app.color.danger')).width('100%')
      }
      Blank()
    }
    .padding(20)
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_bg'))
  }

  private async gate(): Promise<boolean> {
    if (!AppSession.settings.exportAuth) {
      return true;
    }
    return await AuthService.deviceUnlock();
  }

  private async doExport(): Promise<void> {
    this.error = '';
    this.message = '';
    if (this.exportPw.length < 10 || this.exportPw !== this.exportPw2) {
      this.error = '导出密码过短或两次不一致';
      return;
    }
    if (!await this.gate()) {
      this.error = '认证未通过';
      return;
    }
    try {
      const bytes = ZvaultCodec.encode(this.exportPw, AppSession.vault.snapshot.toJson(), AppSession.random,
        AppConstants.PBKDF2_ITER_MIN);
      const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const save = new picker.DocumentSaveOptions();
      save.newFileNames = ['zero-vault.zvault'];
      save.storageMode = picker.DocumentPickerMode.DOWNLOAD;
      const helper = new picker.DocumentViewPicker(ctx);
      const uris = await helper.save(save);
      if (uris && uris.length > 0) {
        const file = fs.openSync(uris[0], fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
        fs.writeSync(file.fd, bytes.buffer.slice(bytes.byteOffset, bytes.byteOffset + bytes.byteLength));
        fs.closeSync(file);
        this.message = '导出完成，格式版本 1。文件头仅含魔数与密钥参数，不含条目明文。';
      }
    } catch (_e) {
      this.error = '无法完成导出';
    }
  }

  private async doImport(replace: boolean): Promise<void> {
    this.error = '';
    this.message = '';
    if (!await this.gate()) {
      this.error = '认证未通过';
      return;
    }
    try {
      const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const opt = new picker.DocumentSelectOptions();
      opt.maxSelectNumber = 1;
      const helper = new picker.DocumentViewPicker(ctx);
      const uris = await helper.select(opt);
      if (!uris || uris.length === 0) {
        return;
      }
      const path = uris[0];
      if (path.indexOf('.zvault') < 0) {
        this.error = '请选择 .zvault 文件';
        return;
      }
      const stat = fs.statSync(path);
      const buf = new ArrayBuffer(stat.size);
      const file = fs.openSync(path, fs.OpenMode.READ_ONLY);
      fs.readSync(file.fd, buf);
      fs.closeSync(file);
      const data = new Uint8Array(buf);
      let json = '';
      try {
        json = ZvaultCodec.decode(this.importPw, data);
      } catch (_e) {
        this.error = '密码不正确或文件已损坏';
        return;
      }
      const snap = VaultSnapshot.fromJson(json);
      if (replace) {
        AppSession.vault.replaceWith(snap);
      } else {
        const n = AppSession.vault.merge(snap);
        this.message = '合并完成，冲突 ' + n + ' 条。';
      }
      await AppSession.persist();
      if (replace) {
        this.message = '已完整替换当前保险库。';
      }
    } catch (_e) {
      this.error = '密码不正确或文件已损坏';
    }
  }
}
