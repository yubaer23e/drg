export class CredentialProviderAdapter {
  static readonly SUPPORTED: boolean = false;
  static readonly REASON: string =
    'HarmonyOS 6.1.1 未向第三方应用开放系统密码提供方扩展。不会使用无障碍或其他非公开接口模拟自动填充。';

  static canProvide(): boolean {
    return CredentialProviderAdapter.SUPPORTED;
  }

  static parseSharedText(text: string): Record<string, string> {
    const out: Record<string, string> = {};
    const t = text.trim();
    if (t.indexOf('http://') === 0 || t.indexOf('https://') === 0) {
      out['url'] = t;
      return out;
    }
    const lines = t.split('\n');
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];
      const colon = line.indexOf(':');
      if (colon > 0) {
        const k = line.substring(0, colon).trim().toLowerCase();
        const v = line.substring(colon + 1).trim();
        if (k === 'user' || k === 'username' || k === '用户名') {
          out['username'] = v;
        } else if (k === 'password' || k === '密码') {
          out['password'] = v;
        } else if (k === 'url' || k === '网址') {
          out['url'] = v;
        } else if (k === 'title' || k === '名称') {
          out['title'] = v;
        }
      }
    }
    if (!out['title'] && t.length > 0 && t.length < 80 && Object.keys(out).length === 0) {
      out['title'] = t;
    }
    return out;
  }
}
