export class WifiQrPayload {
  static escape(value: string): string {
    let s = '';
    for (let i = 0; i < value.length; i++) {
      const ch = value.charAt(i);
      if (ch === '\\' || ch === ';' || ch === ',' || ch === ':') {
        s += '\\' + ch;
      } else {
        s += ch;
      }
    }
    return s;
  }

  static unescape(value: string): string {
    let s = '';
    for (let i = 0; i < value.length; i++) {
      if (value.charAt(i) === '\\' && i + 1 < value.length) {
        s += value.charAt(i + 1);
        i++;
      } else {
        s += value.charAt(i);
      }
    }
    return s;
  }

  static build(security: string, ssid: string, password: string, hidden: boolean): string {
    const t = security.length === 0 ? 'nopass' : security;
    const h = hidden ? 'true' : 'false';
    return 'WIFI:T:' + WifiQrPayload.escape(t) +
      ';S:' + WifiQrPayload.escape(ssid) +
      ';P:' + WifiQrPayload.escape(password) +
      ';H:' + h + ';;';
  }
}

export class QuickQrPayload {
  static text(value: string): string {
    return value;
  }

  static url(value: string): string {
    return value;
  }

  static phone(value: string): string {
    return 'TEL:' + value;
  }

  static sms(number: string, body: string): string {
    return 'SMSTO:' + number + ':' + body;
  }

  static email(addr: string, subject: string, body: string): string {
    let s = 'MATMSG:TO:' + addr + ';SUB:' + subject + ';BODY:' + body + ';;';
    return s;
  }

  static vcard(name: string, phone: string, email: string): string {
    return 'BEGIN:VCARD\nVERSION:3.0\nFN:' + name + '\nTEL:' + phone + '\nEMAIL:' + email + '\nEND:VCARD';
  }

  static tooLong(content: string): boolean {
    return content.length > 1200;
  }

  static contrastOk(fg: number, bg: number): boolean {
    const lum = (c: number): number => {
      const r = ((c >> 16) & 0xff) / 255;
      const g = ((c >> 8) & 0xff) / 255;
      const b = (c & 0xff) / 255;
      const f = (v: number): number => v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4);
      return 0.2126 * f(r) + 0.7152 * f(g) + 0.0722 * f(b);
    };
    const l1 = lum(fg);
    const l2 = lum(bg);
    const hi = l1 > l2 ? l1 : l2;
    const lo = l1 > l2 ? l2 : l1;
    return (hi + 0.05) / (lo + 0.05) >= 3.0;
  }
}
