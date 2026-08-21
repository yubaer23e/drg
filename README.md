# 0号保险库

纯本地、零联网的 HarmonyOS 密码与日记保险库。基于 DevEco Studio Empty Ability（Stage 模型）模板，在独立功能分支上开发，不改动空白模板基线。

- 产品名：0号保险库
- 包名：`com.yubaer23e.drg`
- 兼容 SDK：HarmonyOS 6.1.1(24)
- 设备：手机、平板、2in1/电脑
- 商业模式：商店一次买断；应用内无付费、无广告、无账号

## 承诺

- 不声明 `ohos.permission.INTERNET`，不含云同步、统计或广告 SDK。
- 条目由随机数据主密钥（DEK）加密；DEK 由 HUKS 设备密钥、可选内置密码、可选私密问题和 `.zvault` 导出密码分别包裹。
- 界面与资源不含 Emoji，不含 SVG。图标使用系统 SymbolGlyph 与分层 PNG。
- 二维码在模拟器上按能力探测失败处理，不崩溃。
- 不做通用文件保管箱；文件请使用系统自带保险箱。

## 工程结构

```
docs/PLAN.md              已批准的产品策划
entry/src/main/ets/
  common/                 设计令牌、工具、密码学
  model/                  条目、日记、设置
  security/               DEK 包裹、HUKS、安全随机
  format/                 TOTP、WiFi QR、.zvault
  store/                  内存库与持久化
  service/                会话、认证、剪贴板、生成器、检查
  pages/                  引导、解锁、主壳与各功能页
```

## 本地开发

1. 使用 DevEco Studio 6.1.1 打开仓库根目录。
2. 等待同步，在 `File > Project Structure > Signing Configs` 勾选自动签名。
3. 连接 HarmonyOS 真机（二维码生成在模拟器上会提示不支持）或使用模拟器跑其余功能。
4. 运行 `entry` 模块。

单元测试覆盖 KDF、AES-256-GCM、TOTP 向量、WiFi 转义、DEK 包裹、`.zvault` 真加密门槛（明文零残留、错误密码失败、篡改失败）。

## 分支约定

空白模板单独保留。本应用在 `cursor/password-vault-app-0488` 上开发，从模板基线分出，不往模板分支堆业务代码。
