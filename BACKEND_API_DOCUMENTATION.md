# SilentFlow 后端开发接口文档

> 📋 **静默协作**后端API接口设计规范和开发指南  
> 为前端Flutter应用提供完整的RESTful API支持

## 📖 项目概述

**静默协作 (SilentFlow)** 是一个现代化团队协作管理系统，采用前后端分离架构。本文档面向后端开发人员，详细说明API接口设计、数据模型、业务逻辑和技术要求。

### 🎯 核心业务场景
- **团队池管理**：队长创建团队，成员加入协作
- **项目模板系统**：8种预定义项目类型，标准化协作流程
- **任务工作流**：任务依赖关系、状态管理、进度跟踪
- **工作流可视化**：实时展示团队任务执行状态

## 🏗️ 系统架构

### 技术栈建议
```
后端框架：Node.js/Express, Java/Spring Boot, Python/Django, Go/Gin (任选)
数据库：PostgreSQL (主) + Redis (缓存)
认证：JWT Token
API风格：RESTful
实时通信：WebSocket/Server-Sent Events
文件存储：OSS/S3/MinIO
监控：日志系统 + 性能监控
```

### 部署架构
```
负载均衡 → API网关 → 应用服务器集群 → 数据库集群
                   ↓
              缓存层 (Redis)
                   ↓
              文件存储 (OSS)
```

## 📊 数据模型设计

### 1. 用户模型 (users)
```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    display_name VARCHAR(100),
    avatar_url VARCHAR(500),
    bio TEXT,
    skills JSONB DEFAULT '[]',
    preferences JSONB DEFAULT '{}',
    status VARCHAR(20) DEFAULT 'active', -- active, inactive, suspended
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 索引
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_status ON users(status);
```

### 2. 团队模型 (teams)
```sql
CREATE TABLE teams (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    nature VARCHAR(50) NOT NULL, -- software_dev, academic_research, business_proposal, etc.
    avatar_url VARCHAR(500),
    invite_code VARCHAR(20) UNIQUE,
    max_members INTEGER DEFAULT 10,
    visibility VARCHAR(20) DEFAULT 'private', -- public, private, invite_only
    join_permission VARCHAR(20) DEFAULT 'invite_only', -- open, invite_only, approval_required
    settings JSONB DEFAULT '{}',
    stats JSONB DEFAULT '{}', -- team statistics
    owner_id UUID REFERENCES users(id),
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 索引
CREATE INDEX idx_teams_owner ON teams(owner_id);
CREATE INDEX idx_teams_nature ON teams(nature);
CREATE INDEX idx_teams_status ON teams(status);
CREATE INDEX idx_teams_invite_code ON teams(invite_code);
```

### 3. 团队成员关系 (team_members)
```sql
CREATE TABLE team_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    team_id UUID REFERENCES teams(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(20) DEFAULT 'member', -- owner, admin, member
    permissions JSONB DEFAULT '{}',
    contribution_score INTEGER DEFAULT 0,
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_active_at TIMESTAMP WITH TIME ZONE,
    status VARCHAR(20) DEFAULT 'active', -- active, inactive, left
    
    UNIQUE(team_id, user_id)
);

-- 索引
CREATE INDEX idx_team_members_team ON team_members(team_id);
CREATE INDEX idx_team_members_user ON team_members(user_id);
CREATE INDEX idx_team_members_role ON team_members(role);
```

### 4. 项目模板 (project_templates)
```sql
CREATE TABLE project_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    category VARCHAR(50), -- software_dev, writing, academic, business, etc.
    icon VARCHAR(50),
    color VARCHAR(20),
    phases JSONB NOT NULL, -- project phases definition
    default_tasks JSONB DEFAULT '[]', -- default task templates
    estimated_duration INTEGER, -- in days
    recommended_team_size JSONB DEFAULT '{"min": 2, "max": 6}',
    required_skills JSONB DEFAULT '[]',
    is_active BOOLEAN DEFAULT true,
    usage_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 索引
CREATE INDEX idx_templates_category ON project_templates(category);
CREATE INDEX idx_templates_active ON project_templates(is_active);
```

### 5. 任务模型 (tasks)
```sql
CREATE TABLE tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    team_id UUID REFERENCES teams(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    type VARCHAR(50) DEFAULT 'task', -- project, task, subtask
    parent_id UUID REFERENCES tasks(id),
    template_id UUID REFERENCES project_templates(id),
    priority VARCHAR(20) DEFAULT 'medium', -- high, medium, low
    status VARCHAR(50) DEFAULT 'pending', -- pending, ready, in_progress, review, completed, blocked
    workflow_status VARCHAR(50),
    progress INTEGER DEFAULT 0, -- 0-100
    estimated_hours INTEGER,
    actual_hours INTEGER DEFAULT 0,
    tags JSONB DEFAULT '[]',
    metadata JSONB DEFAULT '{}',
    start_date DATE,
    due_date DATE,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_by UUID REFERENCES users(id),
    assigned_to UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 索引
CREATE INDEX idx_tasks_team ON tasks(team_id);
CREATE INDEX idx_tasks_assignee ON tasks(assigned_to);
CREATE INDEX idx_tasks_creator ON tasks(created_by);
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_tasks_parent ON tasks(parent_id);
CREATE INDEX idx_tasks_due_date ON tasks(due_date);
```

### 6. 任务依赖 (task_dependencies)
```sql
CREATE TABLE task_dependencies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    predecessor_id UUID REFERENCES tasks(id) ON DELETE CASCADE,
    successor_id UUID REFERENCES tasks(id) ON DELETE CASCADE,
    dependency_type VARCHAR(20) DEFAULT 'finish_to_start', -- finish_to_start, start_to_start, etc.
    lag_time INTEGER DEFAULT 0, -- in hours
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(predecessor_id, successor_id)
);

-- 索引
CREATE INDEX idx_task_deps_predecessor ON task_dependencies(predecessor_id);
CREATE INDEX idx_task_deps_successor ON task_dependencies(successor_id);
```

### 7. 任务提交 (task_submissions)
```sql
CREATE TABLE task_submissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_id UUID REFERENCES tasks(id) ON DELETE CASCADE,
    submitter_id UUID REFERENCES users(id),
    content TEXT,
    attachments JSONB DEFAULT '[]',
    submission_type VARCHAR(50) DEFAULT 'completion', -- completion, progress_update, question
    status VARCHAR(20) DEFAULT 'pending', -- pending, approved, rejected, revision_required
    feedback TEXT,
    reviewed_by UUID REFERENCES users(id),
    reviewed_at TIMESTAMP WITH TIME ZONE,
    submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 索引
CREATE INDEX idx_submissions_task ON task_submissions(task_id);
CREATE INDEX idx_submissions_submitter ON task_submissions(submitter_id);
CREATE INDEX idx_submissions_status ON task_submissions(status);
```

## 🔗 API接口设计

### 基础规范
- **Base URL**: `https://api.silentflow.com/v1`
- **认证方式**: Bearer Token (JWT)
- **响应格式**: JSON
- **HTTP状态码**: 标准RESTful状态码
- **分页**: `?page=1&limit=20&sort=created_at&order=desc`

### 统一响应格式
```json
{
  "success": true,
  "data": {},
  "message": "操作成功",
  "timestamp": "2025-08-18T10:30:00Z",
  "request_id": "uuid-string"
}

// 错误响应
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "参数验证失败",
    "details": []
  },
  "timestamp": "2025-08-18T10:30:00Z",
  "request_id": "uuid-string"
}
```

## 👤 用户认证模块

### 1. 用户注册
```http
POST /auth/register
Content-Type: application/json

{
  "username": "john_doe",
  "email": "john@example.com",
  "password": "securePassword123",
  "display_name": "John Doe"
}

# 响应
{
  "success": true,
  "data": {
    "user": {
      "id": "uuid",
      "username": "john_doe",
      "email": "john@example.com",
      "display_name": "John Doe",
      "avatar_url": null,
      "created_at": "2025-08-18T10:30:00Z"
    },
    "token": "jwt-token-string"
  }
}
```

### 2. 用户登录
```http
POST /auth/login
Content-Type: application/json

{
  "email": "john@example.com",
  "password": "securePassword123"
}

# 响应
{
  "success": true,
  "data": {
    "user": { /* user object */ },
    "token": "jwt-token-string",
    "expires_in": 86400
  }
}
```

### 3. 获取当前用户信息
```http
GET /auth/me
Authorization: Bearer jwt-token-string

# 响应
{
  "success": true,
  "data": {
    "user": {
      "id": "uuid",
      "username": "john_doe",
      "email": "john@example.com",
      "display_name": "John Doe",
      "avatar_url": "https://example.com/avatar.jpg",
      "bio": "Full-stack developer",
      "skills": ["JavaScript", "Python", "Flutter"],
      "stats": {
        "teams_count": 5,
        "tasks_completed": 42,
        "contribution_score": 1250
      }
    }
  }
}
```

## 👥 团队管理模块

### 1. 创建团队
```http
POST /teams
Authorization: Bearer jwt-token-string
Content-Type: application/json

{
  "name": "移动应用开发团队",
  "description": "专注于Flutter移动应用开发",
  "nature": "software_dev",
  "max_members": 8,
  "visibility": "private",
  "join_permission": "invite_only",
  "template_id": "software-dev-template-uuid"
}

# 响应
{
  "success": true,
  "data": {
    "team": {
      "id": "team-uuid",
      "name": "移动应用开发团队",
      "description": "专注于Flutter移动应用开发",
      "nature": "software_dev",
      "invite_code": "ABC123XYZ",
      "avatar_url": null,
      "max_members": 8,
      "current_members_count": 1,
      "visibility": "private",
      "join_permission": "invite_only",
      "owner": {
        "id": "user-uuid",
        "username": "john_doe",
        "display_name": "John Doe"
      },
      "created_at": "2025-08-18T10:30:00Z"
    }
  }
}
```

### 2. 获取用户团队列表
```http
GET /teams/my-teams?include_stats=true
Authorization: Bearer jwt-token-string

# 响应
{
  "success": true,
  "data": {
    "teams": [
      {
        "id": "team-uuid",
        "name": "移动应用开发团队",
        "nature": "software_dev",
        "role": "owner",
        "avatar_url": null,
        "members_count": 5,
        "active_tasks": 12,
        "completion_rate": 78.5,
        "last_activity": "2025-08-18T09:15:00Z",
        "created_at": "2025-08-18T10:30:00Z"
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 5,
      "pages": 1
    }
  }
}
```

### 3. 通过邀请码加入团队
```http
POST /teams/join
Authorization: Bearer jwt-token-string
Content-Type: application/json

{
  "invite_code": "ABC123XYZ"
}

# 响应
{
  "success": true,
  "data": {
    "team": { /* team object */ },
    "member": {
      "id": "member-uuid",
      "role": "member",
      "permissions": {},
      "joined_at": "2025-08-18T10:30:00Z"
    }
  }
}
```

### 4. 获取团队详情
```http
GET /teams/{team_id}
Authorization: Bearer jwt-token-string

# 响应
{
  "success": true,
  "data": {
    "team": {
      "id": "team-uuid",
      "name": "移动应用开发团队",
      "description": "专注于Flutter移动应用开发",
      "nature": "software_dev",
      "avatar_url": null,
      "invite_code": "ABC123XYZ", // 仅对team owner/admin显示
      "max_members": 8,
      "visibility": "private",
      "join_permission": "invite_only",
      "owner": { /* user object */ },
      "members": [
        {
          "id": "member-uuid",
          "user": { /* user object */ },
          "role": "member",
          "contribution_score": 150,
          "joined_at": "2025-08-18T10:30:00Z",
          "last_active_at": "2025-08-18T09:15:00Z"
        }
      ],
      "stats": {
        "total_tasks": 25,
        "completed_tasks": 18,
        "in_progress_tasks": 5,
        "completion_rate": 72.0,
        "average_task_duration": 3.2,
        "team_collaboration_score": 85.5
      },
      "created_at": "2025-08-18T10:30:00Z",
      "updated_at": "2025-08-18T10:30:00Z"
    }
  }
}
```

### 5. 管理团队成员
```http
# 邀请成员
POST /teams/{team_id}/members/invite
Authorization: Bearer jwt-token-string
Content-Type: application/json

{
  "emails": ["member1@example.com", "member2@example.com"],
  "role": "member",
  "message": "欢迎加入我们的开发团队！"
}

# 更新成员角色
PUT /teams/{team_id}/members/{user_id}
Authorization: Bearer jwt-token-string
Content-Type: application/json

{
  "role": "admin",
  "permissions": {
    "can_manage_tasks": true,
    "can_invite_members": true,
    "can_manage_settings": false
  }
}

# 移除成员
DELETE /teams/{team_id}/members/{user_id}
Authorization: Bearer jwt-token-string
```

## 📋 任务管理模块

### 1. 创建任务
```http
POST /teams/{team_id}/tasks
Authorization: Bearer jwt-token-string
Content-Type: application/json

{
  "title": "用户界面设计",
  "description": "设计移动应用的主要用户界面",
  "type": "task",
  "parent_id": "project-task-uuid", // 可选，用于子任务
  "priority": "high",
  "estimated_hours": 16,
  "start_date": "2025-08-20",
  "due_date": "2025-08-25",
  "assigned_to": "user-uuid",
  "tags": ["design", "ui", "mobile"],
  "dependencies": [
    {
      "predecessor_id": "requirement-task-uuid",
      "dependency_type": "finish_to_start"
    }
  ]
}

# 响应
{
  "success": true,
  "data": {
    "task": {
      "id": "task-uuid",
      "title": "用户界面设计",
      "description": "设计移动应用的主要用户界面",
      "type": "task",
      "priority": "high",
      "status": "pending",
      "workflow_status": "ready",
      "progress": 0,
      "estimated_hours": 16,
      "actual_hours": 0,
      "start_date": "2025-08-20",
      "due_date": "2025-08-25",
      "tags": ["design", "ui", "mobile"],
      "assignee": { /* user object */ },
      "creator": { /* user object */ },
      "dependencies": [
        {
          "id": "dep-uuid",
          "predecessor": { /* task object */ },
          "dependency_type": "finish_to_start"
        }
      ],
      "created_at": "2025-08-18T10:30:00Z",
      "updated_at": "2025-08-18T10:30:00Z"
    }
  }
}
```

### 2. 获取团队任务列表
```http
GET /teams/{team_id}/tasks?status=in_progress&assignee={user_id}&sort=due_date&order=asc&page=1&limit=20
Authorization: Bearer jwt-token-string

# 响应
{
  "success": true,
  "data": {
    "tasks": [
      {
        "id": "task-uuid",
        "title": "用户界面设计",
        "type": "task",
        "priority": "high",
        "status": "in_progress",
        "progress": 45,
        "due_date": "2025-08-25",
        "assignee": { /* user object */ },
        "creator": { /* user object */ },
        "subtasks_count": 3,
        "completed_subtasks": 1,
        "dependencies_count": 2,
        "created_at": "2025-08-18T10:30:00Z"
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 45,
      "pages": 3
    },
    "stats": {
      "total": 45,
      "pending": 8,
      "in_progress": 12,
      "completed": 25,
      "overdue": 3
    }
  }
}
```

### 3. 更新任务状态
```http
PUT /teams/{team_id}/tasks/{task_id}
Authorization: Bearer jwt-token-string
Content-Type: application/json

{
  "status": "in_progress",
  "progress": 65,
  "actual_hours": 10,
  "notes": "已完成主要界面设计，正在进行细节优化"
}

# 响应
{
  "success": true,
  "data": {
    "task": { /* updated task object */ }
  }
}
```

### 4. 任务提交
```http
POST /teams/{team_id}/tasks/{task_id}/submissions
Authorization: Bearer jwt-token-string
Content-Type: multipart/form-data

{
  "content": "任务已完成，请查看附件中的设计稿",
  "submission_type": "completion",
  "attachments": [file1, file2] // 文件上传
}

# 响应
{
  "success": true,
  "data": {
    "submission": {
      "id": "submission-uuid",
      "task_id": "task-uuid",
      "content": "任务已完成，请查看附件中的设计稿",
      "submission_type": "completion",
      "status": "pending",
      "attachments": [
        {
          "filename": "ui-design-v1.pdf",
          "url": "https://example.com/files/ui-design-v1.pdf",
          "size": 2048000,
          "mime_type": "application/pdf"
        }
      ],
      "submitter": { /* user object */ },
      "submitted_at": "2025-08-18T10:30:00Z"
    }
  }
}
```

### 5. 审核任务提交
```http
PUT /teams/{team_id}/tasks/{task_id}/submissions/{submission_id}/review
Authorization: Bearer jwt-token-string
Content-Type: application/json

{
  "status": "approved", // approved, rejected, revision_required
  "feedback": "设计很棒！建议调整一下颜色搭配。"
}
```

## 📊 工作流管理模块

### 1. 获取团队工作流图
```http
GET /teams/{team_id}/workflow
Authorization: Bearer jwt-token-string

# 响应
{
  "success": true,
  "data": {
    "workflow": {
      "team_id": "team-uuid",
      "nodes": [
        {
          "task_id": "task-uuid",
          "title": "需求分析",
          "type": "task",
          "status": "completed",
          "progress": 100,
          "assignee": { /* user object */ },
          "position": {
            "x": 100,
            "y": 150
          },
          "due_date": "2025-08-20",
          "estimated_hours": 8,
          "actual_hours": 6
        }
      ],
      "edges": [
        {
          "id": "edge-uuid",
          "from_task_id": "requirement-task-uuid",
          "to_task_id": "design-task-uuid",
          "dependency_type": "finish_to_start",
          "status": "active" // active, blocked, completed
        }
      ],
      "statistics": {
        "total_tasks": 15,
        "completed_tasks": 8,
        "in_progress_tasks": 4,
        "blocked_tasks": 1,
        "completion_rate": 53.3,
        "estimated_completion": "2025-09-15",
        "critical_path": ["task1-uuid", "task2-uuid", "task3-uuid"]
      },
      "generated_at": "2025-08-18T10:30:00Z"
    }
  }
}
```

### 2. 更新工作流节点位置
```http
PUT /teams/{team_id}/workflow/layout
Authorization: Bearer jwt-token-string
Content-Type: application/json

{
  "nodes": [
    {
      "task_id": "task-uuid",
      "position": {
        "x": 200,
        "y": 300
      }
    }
  ]
}
```

## 📈 统计分析模块

### 1. 团队统计数据
```http
GET /teams/{team_id}/statistics?period=30d
Authorization: Bearer jwt-token-string

# 响应
{
  "success": true,
  "data": {
    "team_stats": {
      "members_count": 6,
      "active_members": 5,
      "tasks_created": 45,
      "tasks_completed": 32,
      "tasks_in_progress": 8,
      "completion_rate": 71.1,
      "average_task_duration": 4.2,
      "collaboration_score": 87.5,
      "productivity_trend": [
        {
          "date": "2025-08-01",
          "tasks_completed": 3,
          "productivity_score": 85.2
        }
      ]
    },
    "member_stats": [
      {
        "user": { /* user object */ },
        "tasks_assigned": 8,
        "tasks_completed": 6,
        "completion_rate": 75.0,
        "contribution_score": 180,
        "collaboration_score": 92.3
      }
    ]
  }
}
```

### 2. 个人统计数据
```http
GET /users/me/statistics?period=30d
Authorization: Bearer jwt-token-string

# 响应
{
  "success": true,
  "data": {
    "user_stats": {
      "teams_count": 4,
      "active_teams": 3,
      "tasks_assigned": 15,
      "tasks_completed": 12,
      "tasks_in_progress": 2,
      "completion_rate": 80.0,
      "total_contribution_score": 640,
      "average_collaboration_score": 88.7,
      "skills_used": ["Flutter", "JavaScript", "UI Design"],
      "productivity_chart": [
        {
          "date": "2025-08-01",
          "tasks_completed": 2,
          "hours_worked": 6.5,
          "productivity_score": 91.2
        }
      ]
    }
  }
}
```

## 🔄 实时通信

### WebSocket连接
```javascript
// 连接WebSocket
const ws = new WebSocket('wss://api.silentflow.com/ws?token=jwt-token');

// 订阅团队更新
ws.send(JSON.stringify({
  type: 'subscribe',
  channel: 'team',
  team_id: 'team-uuid'
}));

// 接收实时更新
ws.onmessage = (event) => {
  const data = JSON.parse(event.data);
  switch(data.type) {
    case 'task_updated':
      // 处理任务更新
      break;
    case 'member_joined':
      // 处理新成员加入
      break;
    case 'workflow_changed':
      // 处理工作流变更
      break;
  }
};
```

### 实时事件类型
```json
{
  "type": "task_updated",
  "data": {
    "task_id": "task-uuid",
    "changes": {
      "status": {
        "old": "in_progress",
        "new": "completed"
      },
      "progress": {
        "old": 80,
        "new": 100
      }
    },
    "updated_by": { /* user object */ },
    "timestamp": "2025-08-18T10:30:00Z"
  }
}
```

## 🗂️ 项目模板管理

### 1. 获取可用模板
```http
GET /project-templates?category=software_dev&active=true
Authorization: Bearer jwt-token-string

# 响应
{
  "success": true,
  "data": {
    "templates": [
      {
        "id": "software-dev-template-uuid",
        "name": "软件开发项目",
        "description": "标准软件开发流程模板",
        "category": "software_dev",
        "icon": "code",
        "color": "#667eea",
        "phases": [
          {
            "name": "需求分析",
            "description": "分析和定义项目需求",
            "estimated_duration": 3,
            "tasks": [
              {
                "title": "用户需求调研",
                "description": "收集和分析用户需求",
                "estimated_hours": 8,
                "skills_required": ["产品设计", "用户研究"]
              }
            ]
          }
        ],
        "estimated_duration": 45,
        "recommended_team_size": {
          "min": 3,
          "max": 8
        },
        "required_skills": ["编程", "测试", "设计"],
        "usage_count": 156
      }
    ]
  }
}
```

### 2. 基于模板创建团队项目
```http
POST /teams/{team_id}/projects/from-template
Authorization: Bearer jwt-token-string
Content-Type: application/json

{
  "template_id": "software-dev-template-uuid",
  "project_name": "移动电商应用",
  "customizations": {
    "start_date": "2025-08-20",
    "target_duration": 60,
    "skip_phases": ["deployment"],
    "additional_requirements": "需要支持多语言"
  }
}
```

## 📁 文件管理

### 1. 文件上传
```http
POST /files/upload
Authorization: Bearer jwt-token-string
Content-Type: multipart/form-data

{
  "file": file_object,
  "context": "task_attachment", // task_attachment, team_avatar, user_avatar
  "context_id": "task-uuid"
}

# 响应
{
  "success": true,
  "data": {
    "file": {
      "id": "file-uuid",
      "filename": "design-mockup.pdf",
      "original_name": "设计原稿.pdf",
      "mime_type": "application/pdf",
      "size": 2048000,
      "url": "https://cdn.silentflow.com/files/file-uuid.pdf",
      "thumbnail_url": "https://cdn.silentflow.com/thumbs/file-uuid.jpg",
      "uploaded_by": { /* user object */ },
      "created_at": "2025-08-18T10:30:00Z"
    }
  }
}
```

### 2. 获取文件列表
```http
GET /files?context=task_attachment&context_id={task_id}&page=1&limit=20
Authorization: Bearer jwt-token-string
```

## 🔍 搜索功能

### 1. 全局搜索
```http
GET /search?q=用户界面设计&type=tasks,teams&team_id={team_id}&page=1&limit=20
Authorization: Bearer jwt-token-string

# 响应
{
  "success": true,
  "data": {
    "results": {
      "tasks": [
        {
          "id": "task-uuid",
          "title": "用户界面设计",
          "description": "设计移动应用的用户界面",
          "team": { /* team object */ },
          "highlight": {
            "title": "<em>用户界面设计</em>",
            "description": "设计移动应用的<em>用户界面</em>"
          }
        }
      ],
      "teams": [],
      "users": []
    },
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 8,
      "pages": 1
    }
  }
}
```

## 📧 通知系统

### 1. 获取通知列表
```http
GET /notifications?unread=true&page=1&limit=20
Authorization: Bearer jwt-token-string

# 响应
{
  "success": true,
  "data": {
    "notifications": [
      {
        "id": "notification-uuid",
        "type": "task_assigned",
        "title": "新任务分配",
        "message": "John Doe 为您分配了新任务：用户界面设计",
        "data": {
          "task_id": "task-uuid",
          "team_id": "team-uuid",
          "assigned_by": "user-uuid"
        },
        "is_read": false,
        "created_at": "2025-08-18T10:30:00Z"
      }
    ],
    "unread_count": 5
  }
}
```

### 2. 标记通知已读
```http
PUT /notifications/{notification_id}/mark-read
Authorization: Bearer jwt-token-string

# 批量标记已读
PUT /notifications/mark-all-read
Authorization: Bearer jwt-token-string
```

## 🚀 部署和运维

### 环境变量配置
```bash
# 数据库配置
DATABASE_URL=postgresql://user:password@localhost:5432/silentflow
REDIS_URL=redis://localhost:6379

# JWT配置
JWT_SECRET=your-super-secret-key
JWT_EXPIRES_IN=24h

# 文件存储配置
STORAGE_TYPE=s3 # local, s3, oss
S3_BUCKET=silentflow-files
S3_REGION=us-west-2
S3_ACCESS_KEY=your-access-key
S3_SECRET_KEY=your-secret-key

# 邮件服务配置
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=noreply@silentflow.com
SMTP_PASSWORD=smtp-password

# WebSocket配置
WS_PORT=8080
WS_PATH=/ws

# 日志配置
LOG_LEVEL=info
LOG_FORMAT=json

# 限流配置
RATE_LIMIT_WINDOW=15m
RATE_LIMIT_MAX_REQUESTS=1000
```

### 性能要求
- **响应时间**: 95%的API请求响应时间 < 500ms
- **并发支持**: 至少支持1000并发用户
- **可用性**: 99.9%服务可用性
- **数据备份**: 每日自动备份，异地存储

### 监控指标
- API响应时间和错误率
- 数据库连接池状态
- 内存和CPU使用率
- WebSocket连接数
- 文件上传成功率

## 🔐 安全要求

### 1. 身份认证
- JWT Token有效期管理
- 刷新Token机制
- 多设备登录控制
- 异常登录检测

### 2. 权限控制
- 基于角色的访问控制(RBAC)
- 资源级权限验证
- API限流和防刷
- 操作日志记录

### 3. 数据安全
- 敏感数据加密存储
- HTTPS强制要求
- SQL注入防护
- XSS攻击防护

### 4. 隐私保护
- 用户数据最小化收集
- 数据删除机制
- 隐私设置支持
- GDPR合规

## 🧪 测试要求

### 单元测试
- 业务逻辑单元测试覆盖率 > 80%
- 数据库操作测试
- API接口测试
- 工具函数测试

### 集成测试
- API端到端测试
- 数据库集成测试
- 第三方服务集成测试
- WebSocket通信测试

### 性能测试
- 负载测试
- 压力测试
- 数据库性能测试
- 缓存性能测试

## 📋 开发规范

### 代码规范
- 使用ESLint/Prettier进行代码格式化
- 遵循RESTful API设计原则
- 统一的错误处理机制
- 完善的注释和文档

### 数据库规范
- 使用UUID作为主键
- 创建必要的索引
- 外键约束确保数据完整性
- 软删除支持

### API版本管理
- 使用URL版本控制 (`/v1/`, `/v2/`)
- 向后兼容原则
- 版本弃用通知机制
- 文档版本同步

## 📞 技术支持

### 开发联系方式
- **技术负责人**: Adam (@Adam-code-line)
- **项目地址**: https://github.com/Adam-code-line/SilentFlow
- **API文档**: https://docs.silentflow.com
- **问题反馈**: https://github.com/Adam-code-line/SilentFlow/issues

### 开发环境
- **开发环境**: https://dev-api.silentflow.com
- **测试环境**: https://staging-api.silentflow.com
- **生产环境**: https://api.silentflow.com

---

**文档版本**: v1.0  
**最后更新**: 2025年8月18日  
**面向对象**: 后端开发工程师

> 🎯 **目标**: 为静默协作系统提供稳定、高效、可扩展的后端API服务  
> 📈 **愿景**: 支撑千万级用户的团队协作平台
