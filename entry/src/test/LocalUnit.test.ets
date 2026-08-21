import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import { Sha256 } from '../main/ets/common/crypto/Sha256';
import { Sha1 } from '../main/ets/common/crypto/Sha1';
import { Hmac } from '../main/ets/common/crypto/Hmac';
import { Pbkdf2 } from '../main/ets/common/crypto/Pbkdf2';
import { AesGcm } from '../main/ets/common/crypto/AesGcm';
import { SequenceRandom } from '../main/ets/common/crypto/RandomSource';
import { Utf8Util } from '../main/ets/common/utils/Utf8Util';
import { HexUtil } from '../main/ets/common/utils/HexUtil';
import { BytesUtil } from '../main/ets/common/utils/BytesUtil';
import { Base32Util } from '../main/ets/common/utils/Base32Util';
import { TotpEngine } from '../main/ets/format/TotpEngine';
import { WifiQrPayload } from '../main/ets/format/WifiQrPayload';
import { ZvaultCodec } from '../main/ets/format/ZvaultCodec';
import { DekManager } from '../main/ets/security/DekManager';
import { SecretBox } from '../main/ets/security/SecretBox';
import { PasswordGenerator, GeneratorOptions } from '../main/ets/service/PasswordGenerator';
import { SecurityChecker } from '../main/ets/service/SecurityChecker';
import { VaultEntry } from '../main/ets/model/VaultEntry';
import { EntryKind } from '../main/ets/model/EntryKind';
import { MemoryVault, VaultSnapshot } from '../main/ets/store/MemoryVault';
import { AppConstants } from '../main/ets/common/constants/AppConstants';
import { OtpAuthParser } from '../main/ets/format/OtpAuthParser';
import { QrMessages } from '../main/ets/format/QrMessages';
import { SearchUtil } from '../main/ets/common/utils/SearchUtil';
import { DateGroupUtil } from '../main/ets/common/utils/DateGroupUtil';
import { CredentialProviderAdapter } from '../main/ets/service/CredentialProviderAdapter';

export default function localUnitTest() {
  describe('ZeroVaultCrypto', () => {
    it('sha256_abc', 0, () => {
      const d = Sha256.hash(Utf8Util.encode('abc'));
      expect(HexUtil.encode(d)).assertEqual('ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad');
    });

    it('sha1_abc', 0, () => {
      const d = Sha1.hash(Utf8Util.encode('abc'));
      expect(HexUtil.encode(d)).assertEqual('a9993e364706816aba3e25717850c26c9cd0d89d');
    });

    it('hmac_sha256_rfc4231', 0, () => {
      const key = Utf8Util.encode('key');
      const d = Hmac.digest('SHA256', key, Utf8Util.encode('The quick brown fox jumps over the lazy dog'));
      expect(HexUtil.encode(d)).assertEqual('f7bc83f430538424b13298e6aa6fb143ef4d59a14946175997479dbc2d1a3cd8');
    });

    it('pbkdf2_known', 0, () => {
      const dk = Pbkdf2.deriveUtf8('password', Utf8Util.encode('salt'), 2, 32);
      expect(dk.length).assertEqual(32);
      const again = Pbkdf2.deriveUtf8('password', Utf8Util.encode('salt'), 2, 32);
      expect(BytesUtil.equal(dk, again)).assertTrue();
      const other = Pbkdf2.deriveUtf8('password1', Utf8Util.encode('salt'), 2, 32);
      expect(BytesUtil.equal(dk, other)).assertFalse();
    });

    it('aes256_gcm_roundtrip_and_vector', 0, () => {
      const key = HexUtil.decode('000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f');
      const nonce = HexUtil.decode('cafebabefacedbaddecaf8');
      const pt = Utf8Util.encode('0号保险库 secret note');
      const aad = Utf8Util.encode('zvault');
      const packed = AesGcm.encrypt(key, nonce, pt, aad);
      const back = AesGcm.decrypt(key, nonce, packed, aad);
      expect(Utf8Util.decode(back)).assertEqual('0号保险库 secret note');
      const emptyKey = new Uint8Array(32);
      const emptyIv = new Uint8Array(12);
      const empty = AesGcm.encrypt(emptyKey, emptyIv, new Uint8Array(0), new Uint8Array(0));
      expect(HexUtil.encode(empty)).assertEqual('530f8afbc74536b9a963b4f1c4cb738b');
    });

    it('aes256_gcm_tamper_fails', 0, () => {
      const key = new Uint8Array(32);
      key[0] = 7;
      const nonce = new Uint8Array(12);
      nonce[0] = 1;
      const packed = AesGcm.encrypt(key, nonce, Utf8Util.encode('hello'), new Uint8Array(0));
      packed[0] = packed[0] ^ 1;
      let failed = false;
      try {
        AesGcm.decrypt(key, nonce, packed, new Uint8Array(0));
      } catch (_e) {
        failed = true;
      }
      expect(failed).assertTrue();
    });
  });

  describe('TotpWifiZvault', () => {
    it('totp_rfc6238_sha1', 0, () => {
      const secret = Utf8Util.encode('12345678901234567890');
      expect(TotpEngine.fromCounter(secret, 1, 8, 'SHA1')).assertEqual('94287082');
      expect(TotpEngine.fromCounter(secret, 37037036, 8, 'SHA1')).assertEqual('07081804');
    });

    it('wifi_escape', 0, () => {
      const raw = WifiQrPayload.build('WPA', 'Cafe;Net', 'p:a,ss\\', true);
      expect(raw).assertEqual('WIFI:T:WPA;S:Cafe\\;Net;P:p\\:a\\,ss\\\\;H:true;;');
    });

    it('zvault_true_encryption', 0, () => {
      const random = new SequenceRandom(42);
      const payload = '{"title":"mailbox","password":"UniqueSecret999","diary":"今天天气很好"}';
      const file = ZvaultCodec.encode('export-pass-word', payload, random, 8);
      expect(Utf8Util.decode(BytesUtil.slice(file, 0, 4))).assertEqual('ZVLT');
      expect(HexUtil.containsAscii(file, 'UniqueSecret999')).assertFalse();
      expect(HexUtil.containsAscii(file, 'mailbox')).assertFalse();
      expect(HexUtil.containsAscii(file, '今天天气很好')).assertFalse();
      const again = ZvaultCodec.encode('export-pass-word', payload, new SequenceRandom(99), 8);
      expect(BytesUtil.equal(file, again)).assertFalse();
      expect(ZvaultCodec.decode('export-pass-word', file)).assertEqual(payload);
      let bad = false;
      try {
        ZvaultCodec.decode('wrong-password', file);
      } catch (_e) {
        bad = true;
      }
      expect(bad).assertTrue();
      const tampered = BytesUtil.copy(file);
      tampered[tampered.length - 3] = tampered[tampered.length - 3] ^ 0xff;
      let tamper = false;
      try {
        ZvaultCodec.decode('export-pass-word', tampered);
      } catch (_e) {
        tamper = true;
      }
      expect(tamper).assertTrue();
    });

    it('dek_wrap_password_and_question', 0, () => {
      const random = new SequenceRandom(7);
      const dek = DekManager.createDek(random);
      const wrap = DekManager.wrapWithPassword(dek, 'long-master-pass', random, 8);
      const back = DekManager.unwrapWithPassword(wrap, 'long-master-pass');
      expect(BytesUtil.equal(dek, back)).assertTrue();
      let fail = false;
      try {
        DekManager.unwrapWithPassword(wrap, 'nope');
      } catch (_e) {
        fail = true;
      }
      expect(fail).assertTrue();
      const q = DekManager.wrapWithAnswer(dek, '  MyStreet  ', random, 8);
      const backQ = DekManager.unwrapWithAnswer(q, 'mystreet');
      expect(BytesUtil.equal(dek, backQ)).assertTrue();
    });

    it('secret_box', 0, () => {
      const random = new SequenceRandom(3);
      const dek = random.bytes(32);
      const boxed = SecretBox.sealText(dek, 'note', 'aad', random);
      expect(SecretBox.openText(dek, boxed, 'aad')).assertEqual('note');
    });
  });

  describe('VaultLogic', () => {
    it('search_skips_password_body', 0, () => {
      const e = new VaultEntry();
      e.id = '1';
      e.title = '邮箱';
      e.username = 'ada';
      e.password = 'HiddenBodyZZ';
      e.url = 'https://mail.example';
      const list = [e];
      expect(SearchUtil.filter(list, '邮箱', 'all', Date.now()).length).assertEqual(1);
      expect(SearchUtil.filter(list, 'HiddenBodyZZ', 'all', Date.now()).length).assertEqual(0);
    });

    it('generator_never_math_random_and_entropy_label', 0, () => {
      const opt = new GeneratorOptions();
      opt.length = 20;
      const a = PasswordGenerator.generate(opt, new SequenceRandom(1));
      const b = PasswordGenerator.generate(opt, new SequenceRandom(1));
      expect(a).assertEqual(b);
      expect(a.length).assertEqual(20);
      const bits = PasswordGenerator.entropyBits(opt, a);
      expect(bits > 80).assertTrue();
      expect(PasswordGenerator.strengthLabel(30)).assertEqual('弱');
    });

    it('security_checker_weak_reuse_expired', 0, () => {
      expect(SecurityChecker.weak('123456')).assertTrue();
      expect(SecurityChecker.weak('correct-horse-staple-ok')).assertFalse();
      const dek = new Uint8Array(32);
      const a = new VaultEntry();
      a.id = 'a';
      a.title = 'A';
      a.password = '12345678';
      a.kind = EntryKind.LOGIN;
      a.modifiedAt = 1;
      const b = new VaultEntry();
      b.id = 'b';
      b.title = 'B';
      b.password = '12345678';
      b.kind = EntryKind.LOGIN;
      b.modifiedAt = 1;
      const c = new VaultEntry();
      c.id = 'c';
      c.title = '证';
      c.kind = EntryKind.ID_DOC;
      c.idExpiresAt = '2000-01-01';
      const issues = SecurityChecker.scan([a, b, c], dek, Date.now(), 90);
      expect(issues.length > 0).assertTrue();
    });

    it('memory_vault_crud_and_recycle', 0, () => {
      const v = new MemoryVault();
      v.load(new VaultSnapshot(), new Uint8Array(32), 'primary');
      const e = new VaultEntry();
      e.id = 'x';
      e.title = 'one';
      e.password = 'old';
      v.upsert(e, new SequenceRandom(2), false);
      const e2 = e.clone();
      e2.password = 'new';
      v.upsert(e2, new SequenceRandom(2), true);
      expect(v.historyOf('x').length).assertEqual(1);
      v.softDelete('x', true);
      expect(v.list('recycle', '', 'modified', Date.now()).length).assertEqual(1);
      v.restore('x');
      expect(v.list('all', '', 'modified', Date.now()).length).assertEqual(1);
    });

    it('otpauth_parse', 0, () => {
      const r = OtpAuthParser.parse('otpauth://totp/ACME:ada?secret=JBSWY3DPEHPK3PXP&issuer=ACME&digits=6&period=30');
      expect(r['secret']).assertEqual('JBSWY3DPEHPK3PXP');
      expect(r['issuer']).assertEqual('ACME');
    });

    it('base32_roundtrip', 0, () => {
      const raw = Utf8Util.encode('hello');
      expect(BytesUtil.equal(Base32Util.decode(Base32Util.encode(raw)), raw)).assertTrue();
    });

    it('date_group', 0, () => {
      const now = new Date(2026, 7, 21, 12, 0, 0).getTime();
      expect(DateGroupUtil.group(now, now)).assertEqual(DateGroupUtil.TODAY);
    });

    it('no_emoji_in_brand_and_wipe_phrase', 0, () => {
      expect(AppConstants.APP_NAME).assertEqual('0号保险库');
      expect(AppConstants.WIPE_PHRASE.indexOf('我了解') >= 0).assertTrue();
      const re = /[\uD800-\uDBFF][\uDC00-\uDFFF]/;
      expect(re.test(AppConstants.APP_NAME)).assertFalse();
      expect(re.test(AppConstants.WIPE_PHRASE)).assertFalse();
    });

    it('qr_emulator_message_detect', 0, () => {
      expect(QrMessages.isEmulatorMessage('The capability is not supported on the emulator at this time.')).assertTrue();
      expect(QrMessages.EMULATOR_DIALOG.indexOf('模拟器') >= 0).assertTrue();
    });

    it('autofill_adapter_honest', 0, () => {
      expect(CredentialProviderAdapter.canProvide()).assertFalse();
      const p = CredentialProviderAdapter.parseSharedText('username: ada\npassword: x');
      expect(p['username']).assertEqual('ada');
    });
  });
}
