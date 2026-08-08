# 单词消消乐 (WordMatch)

一款结合「游戏化 + 间隔重复」的英语单词记忆 Flutter 应用。

## 功能特性

- **配对消除游戏**：单词与释义、例句等成对消除，寓教于乐。
- **多主题卡片**：学术、森林、太空等主题，高吸引力的视觉反馈。
- **AI 词库清洗**：支持粘贴杂乱文本，调用大模型自动提取结构化词条，失败时自动降级到正则解析。
- **SM-2 复习算法**：基于 SuperMemo-2 安排每日新词与复习计划。
- **学习报告**：每日学习量、正确率、最大连击等数据回顾。

## 技术栈

- **Flutter** >= 3.0.0
- **状态管理**：flutter_riverpod
- **本地数据库**：drift + sqlite3
- **本地存储**：shared_preferences
- **音频**：audioplayers
- **网络**：http

## 环境准备

1. 安装 Flutter SDK（>= 3.0.0）并配置环境变量。
2. 安装 Android Studio / Xcode，配置模拟器或真机。
3. 配置国内镜像（推荐）：

   ```bash
   export FLUTTER_STORAGE_BASE_URL=https://mirrors.tuna.tsinghua.edu.cn/flutter
   export PUB_HOSTED_URL=https://mirrors.tuna.tsinghua.edu.cn/dart-pub
   ```

4. 安装项目依赖：

   ```bash
   flutter pub get
   ```

## 构建说明

### Android Release APK

> 注意：NDK 版本需为 `28.2.13676358`，以解决部分插件依赖冲突。

```bash
flutter build apk --release --target-platform android-arm64
```

输出路径：`build/app/outputs/flutter-apk/app-release.apk`

### Android App Bundle

```bash
flutter build appbundle --release
```

### iOS

```bash
flutter build ios --release
```

## 运行测试

```bash
# 静态分析
flutter analyze

# 单元测试 + Widget 测试
flutter test

# 查看测试覆盖率
flutter test --coverage
```

## 项目结构

```
lib/
├── core/              # 路由、主题、常量、错误处理等核心能力
├── features/          # 按业务模块组织
│   ├── game/          # 游戏核心逻辑与 UI
│   ├── learning/      # 学习、复习、报告
│   ├── wordbook/      # 词库、导入、AI 清洗
│   └── onboarding/    # 引导页
├── shared/            # 通用组件与工具
└── main.dart          # 应用入口
```

## 配置 AI 服务

AI 清洗服务默认使用阿里云 DashScope，可在应用内的设置页面配置：

- API Key：用户私有 key，存储在本地 shared_preferences
- API URL：可选，为空时使用默认 DashScope 接口
- 模型：默认 `qwen-turbo`

## 发布签名

Release 构建需要签名配置。在 `android/` 目录下创建 `keystore.properties`（已被 git 忽略），
或在 CI 中通过环境变量注入（`WORLDMATCH_STOREFILE` / `WORLDMATCH_STOREPASSWORD` / `WORLDMATCH_KEYALIAS` / `WORLDMATCH_KEYPASSWORD`）：

```properties
storeFile=your-key.jks
storePassword=your_store_password
keyAlias=your_key_alias
keyPassword=your_key_password
```

缺失任一签名配置时构建会明确报错并提示配置方式。

**切勿将签名文件和密码提交到版本控制。**

## 贡献指南

1. 运行 `flutter analyze` 确保无静态分析问题。
2. 为新功能或修复补充单元/Widget 测试。
3. 保持代码风格一致，启用 `prefer_single_quotes`、`avoid_print` 等 lint 规则。

## 许可证

MIT
