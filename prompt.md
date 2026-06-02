# 项目 22：HR 招聘管理 App（Flutter）

> 本文件仅描述需求，不包含任何实现代码。UI 使用 Material 基础组件，不做美化。

## 一、项目简介
企业招聘 HR 端 + 候选人端双角色 App：职位发布、简历筛选、面试安排、Offer 审批、内推、人才库、招聘漏斗数据看板、候选人进度查询。Express Mock 后端实现招聘 pipeline 与权限，Flutter Web 调试双角色切换。

## 二、技术栈

### 前端
- Flutter 3.22+ / Dart 3
- Riverpod + freezed
- go_router（按角色不同 Shell）
- dio
- table_calendar（面试排期）
- fl_chart（漏斗、来源分布）

### 后端 Mock
- Express + SQLite
- 端口 `3009`
- 角色：hr / interviewer / candidate / hiring_manager

### Web 兼容约束
- **禁止**：简历 PDF 原生解析、LinkedIn SDK、calendar 同步原生
- **替代**：简历=结构化 JSON 字段展示；附件=URL 链接；日历仅 App 内 table_calendar

## 三、后端 Mock API 设计

| 模块 | 路径 | 说明 |
|------|------|------|
| 认证 | `/api/auth/*` | 返回 role |
| 职位 | CRUD `/api/jobs` | 发布/下架/复制 |
| 职位 | GET `/api/jobs/public` | 候选人浏览 |
| 简历 | POST `/api/applications` | 投递 |
| 简历 | GET `/api/applications` | HR 筛选 pipeline |
| 简历 | PATCH `/api/applications/:id/stage` | 阶段推进 |
| 简历 | GET `/api/applications/:id/timeline` | 操作日志 |
| 人才库 | GET `/api/talent-pool` | 标签、收藏 |
| 面试 | POST `/api/interviews` | 排期、冲突检测 |
| 面试 | GET `/api/interviews` | 面试官视图 |
| 面试 | POST `/api/interviews/:id/feedback` | 评分表 |
| Offer | POST `/api/offers` | 创建 |
| Offer | POST `/api/offers/:id/approve` | 经理审批 |
| 内推 | POST `/api/referrals` | 内推码 |
| 内推 | GET `/api/referrals/stats` | 奖励 Mock |
| 报表 | GET `/api/reports/funnel` | 各阶段转化率 |
| 报表 | GET `/api/reports/source` | 渠道 |
| 通知 | `/api/notifications` | |
| 候选人 | GET `/api/candidate/applications` | 我的投递 |

**业务规则**
- Pipeline：投递→筛选→笔试→一面→二面→Offer→入职 / 淘汰
- 面试冲突：同一面试官同时段不可重复
- Offer：薪资超 band 需 hiring_manager 审批
- 内推：成功入职奖励 5000 Mock 积分
- 简历筛选：关键词+学历+年限过滤

## 四、页面清单（≥25 页）

| 序号 | 页面 | 路由 | 说明 |
|------|------|------|------|
| 1 | 启动 | `/` | |
| 2 | 登录 | `/login` | 角色随账号 |
| 3 | HR 工作台 | `/hr/dashboard` | 待办、漏斗摘要 |
| 4 | 职位管理 | `/hr/jobs` | |
| 5 | 发布职位 | `/hr/job/create` | JD 表单 |
| 6 | 职位详情 | `/hr/job/:id` | 投递列表入口 |
| 7 | 候选人 Pipeline | `/hr/pipeline/:jobId` | Kanban |
| 8 | 简历详情 | `/hr/application/:id` | 时间轴、推进 |
| 9 | 安排面试 | `/hr/interview/schedule` | 日历选时 |
| 10 | 面试列表 | `/hr/interviews` | |
| 11 | 面试反馈 | `/hr/interview/:id/feedback` | 评分维度 |
| 12 | 创建 Offer | `/hr/offer/create` | |
| 13 | Offer 列表 | `/hr/offers` | |
| 14 | Offer 审批 | `/manager/approvals` | 经理角色 |
| 15 | 人才库 | `/hr/talent-pool` | 搜索标签 |
| 16 | 内推管理 | `/hr/referrals` | |
| 17 | 数据报表 | `/hr/reports` | 漏斗+来源 |
| 18 | 职位广场 | `/jobs` | 候选人首页 |
| 19 | 职位详情 | `/job/:id` | 公开 JD |
| 20 | 投递 | `/job/:id/apply` | 表单 |
| 21 | 我的投递 | `/candidate/applications` | 进度 |
| 22 | 投递详情 | `/candidate/application/:id` | 阶段轴 |
| 23 | 内推码 | `/referral` | 生成分享 |
| 24 | 面试官日程 | `/interviewer/schedule` | |
| 25 | 填写反馈 | `/interviewer/interview/:id` | |
| 26 | 消息 | `/messages` | |
| 27 | 个人中心 | `/profile` | |
| 28 | 设置 | `/settings` | |

**导航**：按角色切换不同 BottomNav（HR 三 Tab / 候选人两 Tab）

## 五、核心功能需求
1. 双角色路由：登录后 redirect 到 `/hr/*` 或 `/candidate/*`
2. Pipeline Kanban：拖拽或按钮改阶段，写 timeline
3. 面试排期：冲突 API 返回 409 + 可选时段
4. 漏斗报表：fl_chart 横向条形
5. 候选人进度轴：只读视图

## 六、编译与调试
```bash
cd backend && npm run dev    # :3009
flutter run -d chrome --dart-define=API_BASE=http://localhost:3009
```

## 七、交付物
- 前后端工程
- seed：≥20 职位、≥80 投递、各阶段分布
- 测试账号：hr1、manager1、candidate1、interviewer1
- 测试：阶段推进、面试冲突、Offer 审批
- README

## 八、本次任务
**只列出需求和架构规划，不要写代码。**
请输出：
1. 四角色路由与 Shell 设计
2. 招聘 Pipeline 状态机
3. 面试冲突检测算法
4. 报表漏斗 SQL 聚合
5. Kanban 与 timeline 一致性
6. Web 端多角色测试方案
