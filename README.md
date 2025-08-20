# 静默团队 (SilentFlow)

<div align="center">

![SilentFlow Logo](https://via.placeholder.com/200x100/0175C2/FFFFFF?text=SilentFlow)

**智能团队协作管理系统**

通过**团队池架构**和**工作流可视化**，实现高效、结构化的团队协作

[![Flutter](https://img.shields.io/badge/Flutter-3.8.1+-blue.svg?logo=flutter)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2.svg?logo=dart)](https://dart.dev/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Release](https://img.shields.io/github/v/release/Adam-code-line/SilentFlow)](https://github.com/Adam-code-line/SilentFlow/releases)
[![Downloads](https://img.shields.io/github/downloads/Adam-code-line/SilentFlow/total)](https://github.com/Adam-code-line/SilentFlow/releases)

[📱 下载应用](#-下载安装) · [🚀 快速开始](#-快速开始) · [📖 使用指南](#-使用指南) · [🛠️ 开发文档](#️-开发文档)

</div>

---

## 📖 项目简介

**静默团队 (SilentFlow)** 是一个基于Flutter开发的现代化团队协作管理系统，采用**团队池架构**和**工作流可视化技术**，为团队提供结构化的协作环境。系统支持队长-队员角色管理、智能任务分配、工作流图表展示，特别适合软件开发、学术研究、商业提案等协作项目。

### ✨ 核心特性

#### 🏊‍♂️ 团队池架构
- **角色权限体系** - 队长-队员分级管理，精细化权限控制
- **团队生命周期** - 从创建到解散的完整团队管理流程
- **成员协作** - 邀请码机制，便捷的团队加入和退出
- **团队统计** - 实时团队活跃度和协作效率分析

#### 📊 工作流可视化
- **团队工作流图表** - 直观的图表形式展示团队任务流程
- **任务依赖关系** - 可视化任务间的前后依赖连接
- **实时状态更新** - 任务状态变化实时反映到工作流图
- **交互式操作** - 支持节点点击、拖拽和详情查看

#### 🎯 智能任务管理
- **丰富项目模板** - 8种专业项目模板覆盖主流协作场景
- **智能任务分解** - 基于模板自动生成任务和子任务
- **成员技能匹配** - 根据成员专长智能推荐任务分配
- **进度可视化** - 多维度任务进度跟踪和展示

#### 🎨 统一用户体验
- **现代化设计** - Material Design 3风格界面
- **响应式布局** - 完美适配手机、平板和桌面设备
- **流畅动画** - 精心设计的交互动画和过渡效果
- **深色模式** - 支持系统主题切换

---

## 🚀 快速开始

### 📋 系统要求

**对于用户：**
- **Android**: Android 5.0 (API level 21) 及以上
- **iOS**: iOS 12.0 及以上 *(即将支持)*
- **Web**: 现代浏览器支持 *(即将发布)*

**对于开发者：**
- **Flutter SDK**: 3.8.1 或更高版本
- **Dart SDK**: 3.0.0 或更高版本
- **Android Studio** 或 **VS Code** (推荐)
- **Git**: 用于版本控制

### 📱 下载安装

#### 方式一：下载APK安装包
1. 前往 [Releases页面](https://github.com/Adam-code-line/SilentFlow/releases/latest)
2. 下载最新的 `SilentFlow-vX.X.X-release.apk` 文件
3. 在Android设备上启用"允许安装未知来源应用"
4. 点击APK文件完成安装

#### 方式二：从源码构建
```bash
# 1. 克隆项目
git clone https://github.com/Adam-code-line/SilentFlow.git
cd SilentFlow

# 2. 安装依赖
flutter pub get

# 3. 运行应用（调试模式）
flutter run

# 4. 构建发布版本
flutter build apk --release
```

### 🔧 开发环境配置

#### 1. 安装Flutter
```bash
# 检查Flutter是否正确安装
flutter doctor

# 如果有问题，请按照提示解决依赖问题
flutter doctor --android-licenses
```

#### 2. IDE配置推荐

**VS Code插件：**
- Flutter
- Dart
- Flutter Widget Snippets
- Awesome Flutter Snippets

**Android Studio插件：**
- Flutter
- Dart

#### 3. 项目初始化
```bash
# 清理项目
flutter clean

# 获取依赖
flutter pub get

# 生成必要文件（如果需要）
flutter packages pub run build_runner build
```

---

## 📖 使用指南

### 🎯 主要功能介绍

#### 1. 首页 - 团队协作概览
- **团队协作指数** - 实时展示团队活跃度和效率指标
- **快速操作** - 一键创建团队、加入团队、查看任务
- **统计数据** - 个人和团队的关键指标展示

#### 2. 团队池 - 团队管理中心
- **我的团队** - 管理已加入的所有团队
- **发现团队** - 浏览和申请加入公开团队
- **创建团队** - 使用模板快速创建新团队
- **团队统计** - 详细的团队数据分析

#### 3. 任务面板 - 任务管理
- **任务概览** - 我的任务、可认领任务、全部任务分类查看
- **任务操作** - 创建、编辑、分配、完成任务
- **进度跟踪** - 可视化任务进度和状态变化
- **智能推荐** - 基于技能和负载的任务分配建议

#### 4. 工作流图 - 可视化协作
- **流程图表** - 团队工作流程的直观展示
- **依赖关系** - 任务间依赖关系的可视化
- **实时更新** - 任务状态变化实时反映
- **交互操作** - 点击节点查看详情，拖拽调整布局

#### 5. 个人中心 - 个性化设置
- **个人资料** - 编辑个人信息和技能标签
- **偏好设置** - 主题、通知等个性化配置
- **数据统计** - 个人协作数据和成就展示

### 🏃‍♂️ 快速上手步骤

#### 步骤1：创建第一个团队
1. 打开应用，点击"创建团队"
2. 选择项目模板（如"软件开发"）
3. 填写团队信息和项目描述
4. 邀请团队成员加入

#### 步骤2：管理任务
1. 进入"任务面板"
2. 查看自动生成的任务列表
3. 认领或分配任务
4. 更新任务状态和进度

#### 步骤3：查看工作流
1. 切换到"工作流图"页面
2. 查看团队协作流程图
3. 点击任务节点查看详情
4. 实时跟踪项目进展

---

## 🏗️ 技术架构

### 📁 项目结构
```
lib/
├── main.dart                 # 应用入口
├── config/                   # 配置文件
│   └── app_config.dart
├── models/                   # 数据模型
│   ├── team_pool_model.dart
│   ├── task_model.dart
│   ├── task_template_model.dart
│   └── user_model.dart
├── providers/                # 状态管理
│   ├── app_provider.dart
│   └── team_pool_provider.dart
├── services/                 # 业务逻辑服务
│   ├── team_service.dart
│   ├── task_service.dart
│   ├── workflow_service.dart
│   └── storage_service.dart
├── screens/                  # 页面组件
│   ├── home/
│   ├── team/
│   ├── tasks/
│   ├── workflow/
│   └── profile/
└── widgets/                  # 通用组件
    ├── common_widgets.dart
    ├── task_creation_dialog.dart
    └── workflow_graph_widget.dart
```

### 🔧 核心技术栈

| 技术 | 版本 | 用途 |
|------|------|------|
| **Flutter** | 3.8.1+ | 跨平台UI框架 |
| **Dart** | 3.0+ | 编程语言 |
| **Provider** | ^6.0.0 | 状态管理 |
| **Shared Preferences** | ^2.0.0 | 本地数据存储 |
| **Path Provider** | ^2.0.0 | 文件路径管理 |
| **UUID** | ^3.0.0 | 唯一标识生成 |

### 🎯 核心模型设计

#### TeamPool - 团队池模型
```dart
class TeamPool {
  final String id;
  final String name;
  final String description;
  final TeamTemplate template;
  final String creatorId;
  final List<TeamMember> members;
  final DateTime createdAt;
  final TeamStatus status;
}
```

#### Task - 任务模型
```dart
class Task {
  final String id;
  final String title;
  final String description;
  final TaskPriority priority;
  final TaskStatus status;
  final List<String> assigneeIds;
  final DateTime deadline;
  final List<String> dependencies;
}
```

---

## 🛠️ 开发文档

### 📝 代码规范

#### 命名规范
- **文件名**: snake_case (如 `team_pool_screen.dart`)
- **类名**: PascalCase (如 `TeamPoolProvider`)
- **变量名**: camelCase (如 `currentTeam`)
- **常量**: UPPER_SNAKE_CASE (如 `DEFAULT_TIMEOUT`)

#### 代码组织
- 每个文件顶部包含文件描述注释
- 公共方法必须添加文档注释
- 复杂逻辑必须添加行内注释
- 统一使用4空格缩进

### 🔍 调试技巧

#### 1. 调试信息面板
应用内置了调试信息面板，可以实时查看：
- 当前团队状态
- 任务加载情况
- 网络请求日志
- 存储数据状态

#### 2. 常用调试命令
```bash
# 查看应用日志
flutter logs

# 性能分析
flutter run --profile

# 内存分析
flutter run --trace-startup

# 热重载（开发时）
按 'r' 键进行热重载
按 'R' 键进行热重启
```

### 🧪 测试

#### 运行测试
```bash
# 运行所有测试
flutter test

# 运行特定测试文件
flutter test test/models/team_pool_model_test.dart

# 生成测试覆盖率报告
flutter test --coverage
```

#### 测试结构
```
test/
├── models/              # 模型测试
├── services/            # 服务测试
├── widgets/             # 组件测试
└── integration/         # 集成测试
```

### 📦 构建发布

#### Android APK
```bash
# 构建调试版APK
flutter build apk --debug

# 构建发布版APK
flutter build apk --release

# 构建分包APK（减小体积）
flutter build apk --split-per-abi
```

#### 其他平台
```bash
# iOS (需要Mac和Xcode)
flutter build ios --release

# Web应用
flutter build web --release

# Windows桌面应用
flutter build windows --release
```

---

## 🔄 版本历史

### v1.0.0 (2025-08-20) - 首发版本
#### ✨ 新功能
- 🏊‍♂️ 团队池架构完整实现
- 📊 8个专业项目模板系统
- 🎯 智能任务管理系统
- 📈 工作流图表可视化
- 🎨 现代化用户界面设计

#### 🐛 修复问题
- 修复任务创建对话框移动端溢出问题
- 修复工作流图返回按钮黑屏问题
- 修复团队创建后任务同步问题

#### ⚡ 性能优化
- 优化应用启动速度
- 改进内存使用效率
- 增强数据加载性能

---

## 🤝 贡献指南

我们欢迎任何形式的贡献！无论是Bug报告、功能建议、代码提交还是文档改进。

### 🐛 报告问题
1. 在 [Issues](https://github.com/Adam-code-line/SilentFlow/issues) 中搜索是否已有相似问题
2. 如果没有，创建新的Issue并提供详细信息：
   - 问题描述
   - 复现步骤
   - 预期结果 vs 实际结果
   - 设备信息和应用版本

### 💡 功能建议
1. 在 [Discussions](https://github.com/Adam-code-line/SilentFlow/discussions) 中发起讨论
2. 详细描述功能需求和使用场景
3. 提供必要的设计稿或原型图

### 🔧 代码贡献
1. Fork本仓库
2. 创建特性分支: `git checkout -b feature/AmazingFeature`
3. 提交更改: `git commit -m 'Add some AmazingFeature'`
4. 推送分支: `git push origin feature/AmazingFeature`
5. 创建Pull Request

### 📏 贡献要求
- 遵循项目代码规范
- 添加必要的测试
- 更新相关文档
- 确保所有测试通过

---

## 📞 技术支持

### 🆘 获取帮助
- **GitHub Issues**: [技术问题和Bug报告](https://github.com/Adam-code-line/SilentFlow/issues)
- **GitHub Discussions**: [功能讨论和使用问题](https://github.com/Adam-code-line/SilentFlow/discussions)
- **邮件支持**: silentflow.support@example.com

### 📚 学习资源
- [Flutter官方文档](https://flutter.dev/docs)
- [Dart语言指南](https://dart.dev/guides)
- [Material Design规范](https://material.io/design)

### 🔗 相关链接
- **项目主页**: [https://github.com/Adam-code-line/SilentFlow](https://github.com/Adam-code-line/SilentFlow)
- **发布页面**: [Releases](https://github.com/Adam-code-line/SilentFlow/releases)
- **开发文档**: [Wiki](https://github.com/Adam-code-line/SilentFlow/wiki)

---

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

```
MIT License

Copyright (c) 2025 SilentFlow Team

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
```

---

## 🙏 致谢

感谢所有为SilentFlow项目做出贡献的开发者和用户！

### 💎 特别感谢
- Flutter团队提供优秀的跨平台框架
- Material Design团队提供设计规范
- 所有提供反馈和建议的用户

### 🌟 如果这个项目对你有帮助，请给我们一个星标！

---

<div align="center">

**SilentFlow** - *让团队协作更有结构，让项目管理更加智能*

**最后更新**: 2025年8月20日 | **当前版本**: v1.0.0

[⬆️ 回到顶部](#静默团队-silentflow)

</div>
