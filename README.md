# Aura - AI 个人助手

> 你的 AI 个人助手，一站式处理工作、学习、生活事务。

## ✨ 功能

- 💬 **AI 对话** - 基于 Claude API 的智能对话，自然交流
- 🌤 **天气查询** - 实时天气和未来预报
- ✅ **待办管理** - 添加、完成、查看待办事项
- 📅 **日历日程** - 安排和管理日程
- 🔔 **提醒通知** - 设置提醒不遗漏重要事项
- 🧠 **AI 记忆** - 记住你的偏好和习惯，越用越懂你（开发中）

## 🚀 开始使用

### 环境要求

- Flutter 3.2+
- Dart 3.2+

### 安装

```bash
git clone <repo-url>
cd aura
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```

### 配置

1. 启动 App
2. 进入"设置"页面
3. 输入你的 [Claude API Key](https://console.anthropic.com/) (sk-ant-...)
4. 开始对话！

## 🏗 项目结构

```
lib/
├── core/               # 核心配置
│   ├── config/         # 应用配置、常量
│   ├── theme/          # 主题（微信风格绿色主题）
│   └── router/         # 路由管理
├── database/           # 数据层
│   ├── tables/         # 数据库表定义
│   ├── repositories/   # 数据仓库和 Provider
│   └── database.dart   # 数据库管理
├── features/
│   ├── agent/          # AI Agent 核心
│   │   ├── llm/        # Claude API 封装，Agent 编排
│   │   ├── tools/      # 工具系统（天气、待办、日历等）
│   │   └── memory/     # 记忆系统
│   ├── chat/           # 聊天模块
│   │   ├── models/     # 消息模型
│   │   ├── providers/  # 状态管理
│   │   └── ui/         # 聊天界面
│   ├── dashboard/      # 首页仪表盘
│   │   ├── providers/  # 仪表盘状态
│   │   └── ui/         # 仪表盘界面
│   └── settings/       # 设置模块
│       ├── providers/  # 设置状态
│       └── ui/         # 设置界面
└── shared/             # 共享组件
    └── widgets/        # 通用 UI 组件
```

## 🛠 技术栈

| 组件 | 技术 |
|------|------|
| 框架 | Flutter 3.x |
| 状态管理 | Riverpod |
| 数据库 | Drift (SQLite) |
| AI API | Claude API (Anthropic) |
| 网络 | Dio |
| 存储 | flutter_secure_storage |
| 本地化 | intl |

## 📱 截图预览
<img width="356" height="555" alt="截屏2026-06-08 下午11 17 40" src="https://github.com/user-attachments/assets/bd8ff16c-63a3-40c9-8289-649ccffdec46" />
<img width="321" height="624" alt="截屏2026-06-08 下午11 12 39" src="https://github.com/user-attachments/assets/80a81cbe-5860-4699-8819-26b8107ef97d" />
<img width="76" height="72" alt="截屏2026-06-08 下午11 18 26" src="https://github.com/user-attachments/assets/3d120b76-cd95-4f51-a224-f789e4638808" />
<img width="318" height="613" alt="截屏2026-06-08 下午11 14 42" src="https://github.com/user-attachments/assets/d0d35299-047b-4255-b8c3-5afb9838e9be" />
<img width="318" height="610" alt="截屏2026-06-08 下午11 14 31" src="https://github.com/user-attachments/assets/5f19bce9-aaa3-423a-b86f-0be47218b731" />



## 📄 许可

MIT License

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！
