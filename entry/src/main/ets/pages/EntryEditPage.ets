import { router } from '@kit.ArkUI';
import { AppSession } from '../service/AppSession';
import { VaultEntry } from '../model/VaultEntry';
import { EntryKind, EntryKindUtil } from '../model/EntryKind';
import { AppPrimaryButton, AppGhostButton } from '../common/components/AppWidgets';
import { CustomField } from '../model/CustomField';
import { IdUtil } from '../common/utils/IdUtil';

@Entry
@Component
struct EntryEditPage {
  @State entry: VaultEntry = new VaultEntry();
  @State error: string = '';
  @State dirty: boolean = false;
  private original: string = '';

  aboutToAppear(): void {
    const id = AppStorage.get('editEntryId') as string;
    const found = AppSession.vault.byId(id);
    if (found) {
      this.entry = found.clone();
      this.original = found.toJson();
    }
  }

  build() {
    Column() {
      Row() {
        Text('取消')
          .fontColor($r('app.color.ink_secondary'))
          .onClick(() => {
            this.leave();
          })
        Blank()
        Text(this.entry.id.length === 0 ? '新建' : '编辑')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
        Blank()
        Text('保存')
          .fontColor($r('app.color.accent'))
          .onClick(() => {
            this.save();
          })
      }
      .padding(16)
      .width('100%')

      Scroll() {
        Column({ space: 12 }) {
          Text(EntryKindUtil.label(this.entry.kind))
            .fontSize(12)
            .fontColor($r('app.color.ink_tertiary'))
            .width('100%')
          this.input('名称', this.entry.title, (v: string) => {
            this.entry.title = v;
            this.dirty = true;
          })
          if (this.entry.kind === EntryKind.LOGIN || this.entry.kind === EntryKind.SERVER ||
            this.entry.kind === EntryKind.CUSTOM) {
            this.input('用户名', this.entry.username, (v: string) => {
              this.entry.username = v;
              this.dirty = true;
            })
            this.secret('密码', this.entry.password, (v: string) => {
              this.entry.password = v;
              this.dirty = true;
            })
          }
          if (this.entry.kind === EntryKind.LOGIN) {
            this.input('网站或应用', this.entry.url, (v: string) => {
              this.entry.url = v;
              this.dirty = true;
            })
          }
          if (this.entry.kind === EntryKind.WIFI) {
            this.input('网络名称', this.entry.wifiSsid, (v: string) => {
              this.entry.wifiSsid = v;
              this.dirty = true;
            })
            this.secret('密码', this.entry.password, (v: string) => {
              this.entry.password = v;
              this.dirty = true;
            })
            this.input('安全类型', this.entry.wifiSecurity, (v: string) => {
              this.entry.wifiSecurity = v;
              this.dirty = true;
            })
          }
          if (this.entry.kind === EntryKind.CARD) {
            this.input('持卡人', this.entry.cardHolder, (v: string) => {
              this.entry.cardHolder = v;
              this.dirty = true;
            })
            this.secret('卡号', this.entry.cardNumber, (v: string) => {
              this.entry.cardNumber = v;
              this.dirty = true;
            })
            this.input('有效期', this.entry.cardExpiry, (v: string) => {
              this.entry.cardExpiry = v;
              this.dirty = true;
            })
            this.secret('安全码', this.entry.cardCvv, (v: string) => {
              this.entry.cardCvv = v;
              this.dirty = true;
            })
            this.input('开户行', this.entry.cardBank, (v: string) => {
              this.entry.cardBank = v;
              this.dirty = true;
            })
          }
          if (this.entry.kind === EntryKind.ID_DOC) {
            this.input('证件类型', this.entry.idType, (v: string) => {
              this.entry.idType = v;
              this.dirty = true;
            })
            this.input('姓名', this.entry.idName, (v: string) => {
              this.entry.idName = v;
              this.dirty = true;
            })
            this.secret('号码', this.entry.idNumber, (v: string) => {
              this.entry.idNumber = v;
              this.dirty = true;
            })
            this.input('签发地', this.entry.idIssuer, (v: string) => {
              this.entry.idIssuer = v;
              this.dirty = true;
            })
            this.input('签发日', this.entry.idIssuedAt, (v: string) => {
              this.entry.idIssuedAt = v;
              this.dirty = true;
            })
            this.input('到期日', this.entry.idExpiresAt, (v: string) => {
              this.entry.idExpiresAt = v;
              this.dirty = true;
            })
          }
          if (this.entry.kind === EntryKind.SERVER) {
            this.input('主机', this.entry.host, (v: string) => {
              this.entry.host = v;
              this.dirty = true;
            })
            this.input('端口', this.entry.port, (v: string) => {
              this.entry.port = v;
              this.dirty = true;
            })
            this.secret('私钥', this.entry.privateKey, (v: string) => {
              this.entry.privateKey = v;
              this.dirty = true;
            })
          }
          if (this.entry.kind === EntryKind.TOTP) {
            this.input('发行方', this.entry.totpIssuer, (v: string) => {
              this.entry.totpIssuer = v;
              this.dirty = true;
            })
            this.input('账号', this.entry.totpAccount, (v: string) => {
              this.entry.totpAccount = v;
              this.dirty = true;
            })
            this.secret('密钥', this.entry.totpSecret, (v: string) => {
              this.entry.totpSecret = v;
              this.dirty = true;
            })
          }
          TextArea({ placeholder: '备注', text: this.entry.notes })
            .onChange((v: string) => {
              this.entry.notes = v;
              this.dirty = true;
            })
          Row() {
            Text('收藏').layoutWeight(1)
            Toggle({ type: ToggleType.Switch, isOn: this.entry.favorite })
              .onChange((v: boolean) => {
                this.entry.favorite = v;
                this.dirty = true;
              })
          }
          Row() {
            Text('置顶').layoutWeight(1)
            Toggle({ type: ToggleType.Switch, isOn: this.entry.pinned })
              .onChange((v: boolean) => {
                this.entry.pinned = v;
                this.dirty = true;
              })
          }
          Button('添加自定义字段', { type: ButtonType.Normal })
            .onClick(() => {
              this.entry.customFields.push(CustomField.of(IdUtil.randomId(AppSession.random), '字段', 'text', ''));
              this.dirty = true;
            })
          ForEach(this.entry.customFields, (f: CustomField) => {
            Row({ space: 8 }) {
              TextInput({ text: f.name, placeholder: '名称' })
                .layoutWeight(1)
                .onChange((v: string) => {
                  f.name = v;
                  this.dirty = true;
                })
              TextInput({ text: f.value, placeholder: '内容' })
                .layoutWeight(1)
                .onChange((v: string) => {
                  f.value = v;
                  this.dirty = true;
                })
            }
          }, (f: CustomField) => f.id)
          if (this.error.length > 0) {
            Text(this.error).fontColor($r('app.color.danger'))
          }
          AppPrimaryButton({
            label: '保存',
            onTap: () => {
              this.save();
            }
          })
          Text('生成密码')
            .fontColor($r('app.color.accent'))
            .onClick(() => {
              router.pushUrl({ url: 'pages/GeneratorPage' });
            })
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
  input(label: string, value: string, change: (v: string) => void) {
    Column({ space: 4 }) {
      Text(label).fontSize(12).fontColor($r('app.color.ink_tertiary')).width('100%')
      TextInput({ text: value, placeholder: label })
        .onChange(change)
    }
    .width('100%')
  }

  @Builder
  secret(label: string, value: string, change: (v: string) => void) {
    Column({ space: 4 }) {
      Text(label).fontSize(12).fontColor($r('app.color.ink_tertiary')).width('100%')
      TextInput({ text: value, placeholder: label })
        .type(InputType.Password)
        .onChange(change)
    }
    .width('100%')
  }

  private save(): void {
    if (this.entry.title.length === 0 && this.entry.username.length === 0 &&
      this.entry.wifiSsid.length === 0 && this.entry.totpIssuer.length === 0) {
      this.error = '请至少填写名称或用户名';
      return;
    }
    AppSession.vault.upsert(this.entry, AppSession.random, true);
    AppSession.persist();
    this.dirty = false;
    router.back();
  }

  private leave(): void {
    if (this.dirty && this.entry.toJson() !== this.original) {
      this.getUIContext().showAlertDialog({
        title: '放弃这次修改？',
        message: '未保存的内容会丢失。',
        primaryButton: {
          value: '继续编辑',
          action: () => {
          }
        },
        secondaryButton: {
          value: '放弃修改',
          action: () => {
            router.back();
          }
        }
      });
      return;
    }
    router.back();
  }
}
