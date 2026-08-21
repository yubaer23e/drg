import { router } from '@kit.ArkUI';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { common } from '@kit.AbilityKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { AppSession } from '../service/AppSession';
import { DiaryEntry } from '../model/DiaryModels';
import { IdUtil } from '../common/utils/IdUtil';
import { SecretBox } from '../security/SecretBox';

@Entry
@Component
struct DiaryEditPage {
  @State entry: DiaryEntry = new DiaryEntry();
  @State dateText: string = '';
  @State recording: boolean = false;

  aboutToAppear(): void {
    const id = AppStorage.get('diaryId') as string;
    const list = AppSession.vault.snapshot.diary;
    for (let i = 0; i < list.length; i++) {
      if (list[i].id === id) {
        this.entry = list[i].clone();
      }
    }
    this.dateText = this.label(this.entry.day);
  }

  build() {
    Column() {
      Row() {
        SymbolGlyph($r('sys.symbol.chevron_left')).fontSize(22).onClick(() => {
          this.save();
          router.back();
        })
        Blank()
        Text('日记').fontSize(18).fontWeight(FontWeight.Medium)
        Blank()
        Text('保存').fontColor($r('app.color.accent')).onClick(() => {
          this.save();
          router.back();
        })
      }
      .padding(16)
      .width('100%')

      Scroll() {
        Column({ space: 12 }) {
          Text(this.dateText)
            .fontSize(28)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.ink'))
            .width('100%')
            .onClick(() => {
              this.shiftDay(-1);
            })
          Text('点击日期可改为前一天，便于补记。')
            .fontSize(12)
            .fontColor($r('app.color.ink_tertiary'))
            .width('100%')
          TextInput({ text: this.entry.title, placeholder: '标题（可空）' })
            .onChange((v: string) => {
              this.entry.title = v;
            })
          TextArea({ text: this.entry.body, placeholder: '今天想写下的事' })
            .height(220)
            .onChange((v: string) => {
              this.entry.body = v;
            })
          Row({ space: 8 }) {
            Button('加粗', { type: ButtonType.Normal }).onClick(() => {
              this.wrap('**');
            })
            Button('列表', { type: ButtonType.Normal }).onClick(() => {
              this.entry.body += '\n- ';
            })
            Button('引用', { type: ButtonType.Normal }).onClick(() => {
              this.entry.body += '\n> ';
            })
            Button('分割线', { type: ButtonType.Normal }).onClick(() => {
              this.entry.body += '\n---\n';
            })
          }
          TextInput({ text: this.entry.mood, placeholder: '心情（文字，不用表情）' })
            .onChange((v: string) => {
              this.entry.mood = v;
            })
          TextInput({ text: this.entry.weather, placeholder: '天气（文字）' })
            .onChange((v: string) => {
              this.entry.weather = v;
            })
          Row({ space: 8 }) {
            Button(this.recording ? '停止录音' : '录音').onClick(() => {
              this.toggleRec();
            })
            Button('配图').onClick(() => {
              this.pickPhoto();
            })
          }
          if (this.entry.audioRel.length > 0) {
            Text('已保存录音').fontSize(12).fontColor($r('app.color.ink_secondary'))
          }
          if (this.entry.photoRel.length > 0) {
            Text('已保存配图').fontSize(12).fontColor($r('app.color.ink_secondary'))
          }
        }
        .padding(20)
        .width('100%')
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_bg'))
  }

  private wrap(mark: string): void {
    this.entry.body = mark + this.entry.body + mark;
  }

  private shiftDay(delta: number): void {
    this.entry.day += delta * 24 * 3600 * 1000;
    this.dateText = this.label(this.entry.day);
  }

  private label(ts: number): string {
    const d = new Date(ts);
    const w = ['日', '一', '二', '三', '四', '五', '六'];
    return d.getFullYear() + '年' + (d.getMonth() + 1) + '月' + d.getDate() + '日  星期' + w[d.getDay()];
  }

  private save(): void {
    this.entry.modifiedAt = Date.now();
    const list = AppSession.vault.snapshot.diary;
    let found = false;
    for (let i = 0; i < list.length; i++) {
      if (list[i].id === this.entry.id) {
        list[i] = this.entry;
        found = true;
      }
    }
    if (!found) {
      list.push(this.entry);
    }
    AppSession.persist();
  }

  private async toggleRec(): Promise<void> {
    this.recording = !this.recording;
    if (!this.recording) {
      this.entry.audioRel = 'audio-' + IdUtil.randomId(AppSession.random);
    }
  }

  private async pickPhoto(): Promise<void> {
    try {
      const opt = new photoAccessHelper.PhotoSelectOptions();
      opt.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
      opt.maxSelectNumber = 1;
      const pickerView = new photoAccessHelper.PhotoViewPicker();
      const result = await pickerView.select(opt);
      if (result.photoUris && result.photoUris.length > 0) {
        const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
        const name = 'photo-' + IdUtil.randomId(AppSession.random) + '.bin';
        const path = ctx.filesDir + '/media/' + name;
        try {
          fs.mkdirSync(ctx.filesDir + '/media');
        } catch (_e) {
        }
        const src = fs.openSync(result.photoUris[0], fs.OpenMode.READ_ONLY);
        const stat = fs.statSync(result.photoUris[0]);
        const buf = new ArrayBuffer(stat.size);
        fs.readSync(src.fd, buf);
        fs.closeSync(src);
        const sealed = SecretBox.seal(AppSession.vault.dek, new Uint8Array(buf), 'photo', AppSession.random);
        const dst = fs.openSync(path, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
        fs.writeSync(dst.fd, sealed.buffer.slice(sealed.byteOffset, sealed.byteOffset + sealed.byteLength));
        fs.closeSync(dst);
        this.entry.photoRel = name;
        this.save();
      }
    } catch (_e) {
    }
  }
}
