# PomodoroMac

菜单栏番茄钟 — 帮你健康使用电脑

![Platform](https://img.shields.io/badge/platform-macOS-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## 功能

### 核心功能
- 🍅 番茄工作法计时器（25分钟专注 + 5分钟短休息）
- 📊 每日/每周统计，追踪你的专注时长
- 🎯 自定义每日目标
- 🔔 系统通知 + 弹窗提醒
- 🔊 番茄钟完成提示音

### 可配置
- 专注时长（15/20/25/30/45/60分钟）
- 短休息时长（3/5/10分钟）
- 长休息时长（15/20/30分钟）
- 每日番茄目标
- 通知开关、弹窗开关、声音开关

## 界面预览

```
┌─────────────────────────────┐
│  [计时器]  [统计]  [设置]   │
│                             │
│        ┌─────────┐          │
│       ╱           ╲         │
│      │   25:00    │         │
│       ╲           ╱         │
│        └─────────┘          │
│      第 1 个番茄 🍅          │
│                             │
│      [开始]    [重置]        │
└─────────────────────────────┘
```

## 技术栈

- **Swift + AppKit** — 原生 macOS 应用
- **SQLite.swift** — 数据持久化
- **XcodeGen + CocoaPods** — 项目管理

## 安装

### 从源码编译

```bash
# 克隆仓库
git clone https://github.com/petershi5/pomodoro-mac.git
cd pomodoro-mac

# 生成 Xcode 项目
xcodegen generate

# 安装依赖
pod install

# 用 Xcode 打开并运行
open PomodoroMac.xcworkspace
```

### 系统要求

- macOS 13.0 (Ventura) 或更高版本
- Xcode 15.0 或更高版本

## 使用方法

1. 运行应用后，菜单栏会出现计时器图标
2. 点击图标打开番茄钟面板
3. 点击「开始」启动计时
4. 专注时间结束后会收到通知提醒
5. 切换「统计」查看今日/本周专注数据
6. 切换「设置」自定义时长和提醒

## 项目结构

```
PomodoroMac/
├── Sources/
│   ├── App/
│   │   ├── main.swift              # 应用入口
│   │   └── AppDelegate.swift       # 应用代理
│   ├── UI/
│   │   ├── StatusBarController.swift    # 菜单栏管理
│   │   ├── TimerViewController.swift    # 主控制器
│   │   ├── TimerView.swift             # 计时器视图
│   │   ├── StatisticsView.swift         # 统计视图
│   │   └── SettingsView.swift          # 设置视图
│   ├── Core/
│   │   ├── PomodoroTimer.swift         # 计时器逻辑
│   │   ├── NotificationManager.swift    # 通知管理
│   │   └── SoundManager.swift          # 音效管理
│   └── Data/
│       ├── DatabaseManager.swift        # 数据库管理
│       ├── SettingsStore.swift          # 设置存储
│       └── Models/
│           └── PomodoroRecord.swift     # 数据模型
├── Resources/
│   └── Assets.xcassets                 # 图标资源
├── project.yml                          # XcodeGen 配置
└── Podfile                             # CocoaPods 依赖
```

## License

MIT License
