# 静默协作 - 项目架构说明

## 🏗️ 优化后的项目架构

### 📁 目录结构
```
lib/
├── config/          # 配置文件
│   └── app_config.dart
├── models/          # 数据模型
│   ├── user_model.dart
│   ├── collaboration_pool_model.dart
│   └── task_model.dart
├── services/        # 服务层（API接口）
│   ├── api_service.dart
│   ├── user_service.dart
│   └── collaboration_pool_service.dart
├── providers/       # 状态管理
│   ├── app_provider.dart
│   └── collaboration_pool_provider.dart
├── screens/         # 页面
│   ├── auth/
│   │   └── login_screen.dart
│   ├── home/
│   │   └── home_screen.dart
│   ├── collaboration/
│   │   └── collaboration_pool_screen.dart
│   ├── tasks/
│   │   └── task_board_screen.dart
│   ├── profile/
│   │   └── profile_screen.dart
│   └── main_tab_screen.dart
├── widgets/         # 通用组件
│   └── common_widgets.dart
├── utils/           # 工具类
│   └── app_utils.dart
└── main.dart        # 应用入口
```

## 🎯 核心功能模块

### 1. **用户系统**
- ✅ 登录/注册界面
- ✅ 用户信息管理
- ✅ 匿名模式支持
- ⏳ 用户统计和效率标签

### 2. **协作池管理**
- ✅ 创建协作池
- ✅ 加入/退出协作池
- ✅ 公开池和私有池
- ⏳ 协作进度跟踪

### 3. **任务系统**
- ⏳ 任务创建和分配
- ⏳ 任务状态管理
- ⏳ 障碍标签系统
- ⏳ 任务依赖关系

### 4. **默契值系统**
- ⏳ 协作评分算法
- ⏳ 任务衔接检测
- ⏳ 效率图谱生成

### 5. **静默通知**
- ⏳ 关键节点提醒
- ⏳ 冲突检测通知
- ⏳ 极简提醒设计

## 🔧 技术栈

### 前端框架
- **Flutter 3.x** - 跨平台UI框架
- **Material Design 3** - 现代化UI设计

### 状态管理
- **Provider** - 简单高效的状态管理

### 网络请求
- **Dio** - 强大的HTTP客户端
- **JSON序列化** - 数据模型转换

### 本地存储
- **SharedPreferences** - 用户偏好设置
- **设备信息** - 设备标识和特性

### 数据可视化
- **FL Chart** - 协作效率图表

## 🚀 后端接口预留

### API服务层设计
所有后端接口都在 `services/` 目录下预留了位置：

#### 用户相关接口
```dart
// services/user_service.dart
- POST /auth/login          // 用户登录
- POST /auth/register       // 用户注册
- GET  /users/{id}          // 获取用户信息
- PUT  /users/{id}          // 更新用户信息
- GET  /users/{id}/stats    // 用户统计信息
```

#### 协作池相关接口
```dart
// services/collaboration_pool_service.dart
- GET  /users/{id}/pools    // 获取用户的协作池
- GET  /pools/public        // 获取公开协作池
- POST /pools               // 创建协作池
- POST /pools/{id}/join     // 加入协作池
- GET  /pools/{id}/progress // 协作池进度
```

#### 任务相关接口（待实现）
```dart
// services/task_service.dart
- GET  /pools/{id}/tasks    // 获取协作池任务
- POST /pools/{id}/tasks    // 创建任务
- PUT  /tasks/{id}          // 更新任务状态
- POST /tasks/{id}/claim    // 认领任务
- POST /tasks/{id}/obstacle // 报告障碍
```

## 📱 页面功能说明

### 1. 启动页 (SplashScreen)
- 展示应用Logo和理念
- 检查用户登录状态
- 初始化应用配置

### 2. 登录/注册页 (LoginScreen)
- 统一的认证界面
- 支持切换登录/注册模式
- 表单验证和错误处理

### 3. 主页 (HomeScreen)
- **协作默契值显示** - 周/月/总分统计
- **今日关键节点** - 任务完成和开始通知
- **协作池概览** - 参与的活跃协作池
- **效率图谱** - 个人协作标签展示

### 4. 协作池页 (CollaborationPoolScreen)
- **我参与的** - 当前活跃的协作池
- **公开池** - 可加入的公开协作池
- **已完成** - 历史完成的协作池
- 支持匿名协作标识

### 5. 任务面板 (TaskBoardScreen)
- 任务状态筛选（待认领/进行中/已完成）
- 任务认领和状态更新
- 障碍标签系统
- 仅显示关键节点变化

### 6. 个人资料 (ProfileScreen)
- 用户信息和统计
- 效率标签展示
- 协作历史回顾
- 设置和偏好配置

## 🎨 UI/UX 设计理念

### 静默协作主题
- **冷静色调** - 以蓝紫色为主色调，营造专注氛围
- **极简设计** - 减少不必要的视觉干扰
- **关键信息突出** - 只显示重要的协作节点

### 交互设计
- **低打扰原则** - 仅在必要时提供通知
- **一键操作** - 简化常用功能的操作流程
- **状态清晰** - 明确的任务和协作状态指示

## 📋 开发计划

### 第一阶段 ✅ (已完成)
- [x] 项目架构搭建
- [x] 基础UI框架
- [x] 用户认证系统
- [x] 状态管理配置

### 第二阶段 ⏳ (开发中)
- [ ] 协作池完整功能
- [ ] 任务管理系统
- [ ] 默契值计算算法
- [ ] 数据持久化

### 第三阶段 📅 (计划中)
- [ ] 效率图谱分析
- [ ] 静默通知系统
- [ ] 匿名协作优化
- [ ] 性能优化

### 第四阶段 🔮 (未来规划)
- [ ] 后端接口集成
- [ ] 数据同步机制
- [ ] 多设备支持
- [ ] 高级分析功能

## 🚀 运行项目

1. **安装依赖**
   ```bash
   flutter pub get
   ```

2. **生成代码** (JSON序列化)
   ```bash
   flutter packages pub run build_runner build
   ```

3. **运行应用**
   ```bash
   flutter run
   ```

## 📞 后端接口对接

当后端准备就绪时，只需要：

1. 更新 `services/api_service.dart` 中的 `baseUrl`
2. 在各个 service 文件中取消注释真实的API调用代码
3. 注释掉模拟数据相关的代码
4. 根据后端API格式调整数据模型

## 💡 特色功能亮点

### 1. 静默协作理念
- **无需频繁沟通** - 通过系统同步关键信息
- **低成本协作** - 减少会议和消息成本
- **高效任务分配** - 智能匹配和自动分配

### 2. 默契值系统
- **量化协作质量** - 数字化协作配合度
- **激励机制** - 通过分数激励良好协作
- **数据驱动优化** - 基于数据改进协作方式

### 3. 匿名协作支持
- **降低社交压力** - 适合社恐人群
- **专注任务本身** - 减少人际关系干扰
- **灵活协作模式** - 支持不同协作偏好

