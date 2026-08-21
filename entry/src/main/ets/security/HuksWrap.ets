import { huks } from '@kit.UniversalKeystoreKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { BytesUtil } from '../common/utils/BytesUtil';
import { HexUtil } from '../common/utils/HexUtil';

export class HuksWrap {
  static readonly ALIAS: string = 'zero_vault_dek_wrap_aes256';

  static async ensureKey(): Promise<void> {
    const exists = await HuksWrap.hasKey();
    if (exists) {
      return;
    }
    const properties: Array<huks.HuksParam> = [
      { tag: huks.HuksTag.HUKS_TAG_ALGORITHM, value: huks.HuksKeyAlg.HUKS_ALG_AES },
      { tag: huks.HuksTag.HUKS_TAG_KEY_SIZE, value: huks.HuksKeySize.HUKS_AES_KEY_SIZE_256 },
      { tag: huks.HuksTag.HUKS_TAG_PURPOSE, value: huks.HuksKeyPurpose.HUKS_KEY_PURPOSE_ENCRYPT | huks.HuksKeyPurpose.HUKS_KEY_PURPOSE_DECRYPT },
      { tag: huks.HuksTag.HUKS_TAG_PADDING, value: huks.HuksKeyPadding.HUKS_PADDING_NONE },
      { tag: huks.HuksTag.HUKS_TAG_BLOCK_MODE, value: huks.HuksCipherMode.HUKS_MODE_GCM }
    ];
    await huks.generateKeyItem(HuksWrap.ALIAS, { properties: properties });
  }

  static async hasKey(): Promise<boolean> {
    try {
      const ok = await huks.isKeyItemExist(HuksWrap.ALIAS, { properties: [] });
      return ok;
    } catch (_e) {
      return false;
    }
  }

  static async wrap(plain: Uint8Array, nonce: Uint8Array): Promise<Uint8Array> {
    await HuksWrap.ensureKey();
    const encProps: Array<huks.HuksParam> = [
      { tag: huks.HuksTag.HUKS_TAG_ALGORITHM, value: huks.HuksKeyAlg.HUKS_ALG_AES },
      { tag: huks.HuksTag.HUKS_TAG_PURPOSE, value: huks.HuksKeyPurpose.HUKS_KEY_PURPOSE_ENCRYPT },
      { tag: huks.HuksTag.HUKS_TAG_PADDING, value: huks.HuksKeyPadding.HUKS_PADDING_NONE },
      { tag: huks.HuksTag.HUKS_TAG_BLOCK_MODE, value: huks.HuksCipherMode.HUKS_MODE_GCM },
      { tag: huks.HuksTag.HUKS_TAG_NONCE, value: nonce }
    ];
    const options: huks.HuksOptions = { properties: encProps, inData: plain };
    const session = await huks.initSession(HuksWrap.ALIAS, options);
    const fin = await huks.finishSession(session.handle, options);
    return fin.outData as Uint8Array;
  }

  static async unwrap(cipher: Uint8Array, nonce: Uint8Array): Promise<Uint8Array> {
    if (cipher.length < 16) {
      throw new Error('huks cipher short');
    }
    const tag = BytesUtil.slice(cipher, cipher.length - 16, cipher.length);
    const body = BytesUtil.slice(cipher, 0, cipher.length - 16);
    const decProps: Array<huks.HuksParam> = [
      { tag: huks.HuksTag.HUKS_TAG_ALGORITHM, value: huks.HuksKeyAlg.HUKS_ALG_AES },
      { tag: huks.HuksTag.HUKS_TAG_PURPOSE, value: huks.HuksKeyPurpose.HUKS_KEY_PURPOSE_DECRYPT },
      { tag: huks.HuksTag.HUKS_TAG_PADDING, value: huks.HuksKeyPadding.HUKS_PADDING_NONE },
      { tag: huks.HuksTag.HUKS_TAG_BLOCK_MODE, value: huks.HuksCipherMode.HUKS_MODE_GCM },
      { tag: huks.HuksTag.HUKS_TAG_NONCE, value: nonce },
      { tag: huks.HuksTag.HUKS_TAG_AE_TAG, value: tag }
    ];
    const options: huks.HuksOptions = { properties: decProps, inData: body };
    try {
      const session = await huks.initSession(HuksWrap.ALIAS, options);
      const fin = await huks.finishSession(session.handle, options);
      return fin.outData as Uint8Array;
    } catch (e) {
      const err = e as BusinessError;
      throw new Error('huks unwrap ' + err.code);
    }
  }

  static async deleteKey(): Promise<void> {
    try {
      await huks.deleteKeyItem(HuksWrap.ALIAS, { properties: [] });
    } catch (_e) {
    }
  }

  static hex(data: Uint8Array): string {
    return HexUtil.encode(data);
  }
}
