export class OtpAuthParser {
  static parse(uri: string): Record<string, string> {
    const out: Record<string, string> = {};
    if (uri.indexOf('otpauth://') !== 0) {
      throw new Error('not otpauth');
    }
    const rest = uri.substring('otpauth://'.length);
    const q = rest.indexOf('?');
    const path = q >= 0 ? rest.substring(0, q) : rest;
    const query = q >= 0 ? rest.substring(q + 1) : '';
    const slash = path.indexOf('/');
    out['type'] = slash >= 0 ? path.substring(0, slash) : path;
    const label = slash >= 0 ? decodeURIComponent(path.substring(slash + 1)) : '';
    const colon = label.indexOf(':');
    if (colon >= 0) {
      out['issuer'] = label.substring(0, colon);
      out['account'] = label.substring(colon + 1);
    } else {
      out['account'] = label;
    }
    const parts = query.split('&');
    for (let i = 0; i < parts.length; i++) {
      if (parts[i].length === 0) {
        continue;
      }
      const eq = parts[i].indexOf('=');
      if (eq < 0) {
        continue;
      }
      const k = decodeURIComponent(parts[i].substring(0, eq));
      const v = decodeURIComponent(parts[i].substring(eq + 1));
      out[k] = v;
      if (k === 'issuer' && v.length > 0) {
        out['issuer'] = v;
      }
    }
    if (!out['digits']) {
      out['digits'] = '6';
    }
    if (!out['period']) {
      out['period'] = '30';
    }
    if (!out['algorithm']) {
      out['algorithm'] = 'SHA1';
    }
    return out;
  }
}
