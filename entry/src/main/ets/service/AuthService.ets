import { userAuth } from '@kit.UserAuthenticationKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { cryptoFramework } from '@kit.CryptoArchitectureKit';

export class AuthCapability {
  pin: boolean = false;
  face: boolean = false;
  finger: boolean = false;

  dualReady(): boolean {
    let n = 0;
    if (this.pin) {
      n++;
    }
    if (this.face) {
      n++;
    }
    if (this.finger) {
      n++;
    }
    return n >= 2;
  }
}

export class AuthService {
  static query(): AuthCapability {
    const cap = new AuthCapability();
    cap.pin = AuthService.available(userAuth.UserAuthType.PIN);
    cap.face = AuthService.available(userAuth.UserAuthType.FACE);
    cap.finger = AuthService.available(userAuth.UserAuthType.FINGERPRINT);
    return cap;
  }

  private static available(t: userAuth.UserAuthType): boolean {
    try {
      userAuth.getAvailableStatus(t, userAuth.AuthTrustLevel.ATL2);
      return true;
    } catch (_e) {
      return false;
    }
  }

  static authenticate(types: userAuth.UserAuthType[], title: string): Promise<boolean> {
    return new Promise<boolean>((resolve: (v: boolean) => void) => {
      try {
        const challenge = cryptoFramework.createRandom().generateRandomSync(16).data;
        const auth = userAuth.getUserAuthInstance({
          challenge: challenge,
          authType: types,
          authTrustLevel: userAuth.AuthTrustLevel.ATL2
        }, { title: title });
        auth.on('result', {
          onResult: (result: userAuth.UserAuthResult) => {
            resolve(result.result === userAuth.ResultCode.SUCCESS);
          }
        });
        auth.start();
      } catch (e) {
        const err = e as BusinessError;
        console.error('auth start ' + err.code);
        resolve(false);
      }
    });
  }

  static async deviceUnlock(): Promise<boolean> {
    const cap = AuthService.query();
    const types: userAuth.UserAuthType[] = [];
    if (cap.finger) {
      types.push(userAuth.UserAuthType.FINGERPRINT);
    }
    if (cap.face) {
      types.push(userAuth.UserAuthType.FACE);
    }
    if (cap.pin) {
      types.push(userAuth.UserAuthType.PIN);
    }
    if (types.length === 0) {
      return false;
    }
    return await AuthService.authenticate(types, '解锁 0号保险库');
  }

  static async oneType(t: userAuth.UserAuthType, title: string): Promise<boolean> {
    return await AuthService.authenticate([t], title);
  }

  static async dualReset(): Promise<boolean> {
    const cap = AuthService.query();
    if (!cap.dualReady()) {
      return false;
    }
    const first = cap.finger ? userAuth.UserAuthType.FINGERPRINT :
      (cap.face ? userAuth.UserAuthType.FACE : userAuth.UserAuthType.PIN);
    let second = userAuth.UserAuthType.PIN;
    if (first === userAuth.UserAuthType.PIN) {
      second = cap.face ? userAuth.UserAuthType.FACE : userAuth.UserAuthType.FINGERPRINT;
    }
    const a = await AuthService.oneType(first, '第一重验证');
    if (!a) {
      return false;
    }
    return await AuthService.oneType(second, '第二重验证');
  }
}
