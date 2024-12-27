# 节拍器

一个使用 Flutter 开发的跨平台节拍器应用。

## 功能特点

- 可调节速度(BPM: 40-240)
- 支持不同节拍类型(2/4, 3/4, 4/4 等)
- 可视化节拍指示器
- 开始/停止控制
- 音频反馈
- Material Design 界面设计
- 支持深色/浅色主题

## 使用方法

1. 调节 BPM
   - 使用滑块或点击 +/- 按钮设置所需速度(每分钟节拍数)
   - 支持范围: 40-240 BPM

2. 选择节拍类型
   - 点击节拍选择器切换不同拍号
   - 支持 2/4, 3/4, 4/4 等常用拍号

3. 控制播放
   - 点击中央按钮开始/停止节拍器
   - 播放时会有视觉和声音提示

## 技术实现

- 使用 Flutter 音频插件实现精确的节拍声音
- Flutter 动画系统实现流畅的视觉效果
- 状态管理使用 Provider/Riverpod
- 遵循 Flutter 最佳实践和设计规范

## 平台支持

- Android
- iOS
- Web
- Windows
- macOS
- Linux

## 开发环境配置

1. 安装 Flutter SDK
2. 配置开发环境变量
3. 运行以下命令检查环境:
   ```bash
   flutter doctor
   ```

## 本地运行

1. 克隆仓库:
   ```bash
   git clone https://github.com/your-username/metronome.git
   ```

2. 安装依赖:
   ```bash
   flutter pub get
   ```

3. 运行应用:
   ```bash
   flutter run
   ```

## 构建发布版本

Android:
```bash
flutter build apk
```

iOS:
```bash
flutter build ios
```

Web:
```bash
flutter build web
```

## 项目结构

```
lib/
├── models/          # 数据模型
├── providers/       # 状态管理
├── screens/         # 页面UI
├── widgets/         # 可复用组件
├── utils/          # 工具类
└── main.dart       # 入口文件
```

## 依赖项

主要使用的第三方包:

- audioplayers: ^5.2.1  # 音频播放
- provider: ^6.1.1      # 状态管理
- shared_preferences: ^2.2.2  # 本地存储

## 贡献指南

1. Fork 项目
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

## 更新日志

### [1.0.0] - 2024-03-xx
- 初始版本发布
- 基础节拍器功能
- 支持多种拍号
- 深色模式支持

## 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件