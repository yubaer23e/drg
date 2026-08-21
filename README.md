# DRG

HarmonyOS 应用工程，基于 DevEco Studio Empty Ability（Stage 模型）模板创建。

- 包名：`com.yubaer23e.drg`
- 兼容 SDK：HarmonyOS 6.1.1(24)
- 设备类型：手机、2in1

## 工程结构

```
AppScope/                 应用全局配置与图标
entry/                    入口模块，编译生成 HAP
  src/main/ets/
    entryability/         应用入口 Ability
    entrybackupability/   备份恢复扩展
    pages/                页面（当前为 Index）
  src/main/module.json5   模块配置
build-profile.json5       工程级编译与产品配置
oh-package.json5          工程依赖
hvigorfile.ts             工程级构建脚本
```

## 本地开发

1. 使用 [DevEco Studio 6.1.1](https://developer.huawei.com/consumer/cn/deveco-studio/) 打开本仓库根目录。
2. 等待工程同步完成。
3. 在 `File > Project Structure > Signing Configs` 勾选自动签名。
4. 连接 HarmonyOS 真机或使用模拟器，运行 `entry` 模块。

首页 `entry/src/main/ets/pages/Index.ets` 是后续业务开发的起点。
