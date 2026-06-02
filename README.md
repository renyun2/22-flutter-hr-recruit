# HR 招聘管理 App

企业招聘 HR 端 + 候选人端双角色 App：职位发布、简历筛选、面试安排、Offer 审批、内推、人才库、招聘漏斗数据看板、候选人进度查询。

## 技术栈

| 层 | 技术 |
|---|---|
| 前端 | Flutter 3.22+、Riverpod、go_router、dio、fl_chart、table_calendar |
| 后端 Mock | Express + better-sqlite3，端口 **3009** |

## 测试账号

| 账号 | 密码 | 角色 | 登录后首页 |
|------|------|------|------------|
| hr1 | 123456 | hr | `/hr/dashboard` |
| manager1 | 123456 | hiring_manager | `/manager/approvals` |
| candidate1 | 123456 | candidate | `/jobs` |
| interviewer1 | 123456 | interviewer | `/interviewer/schedule` |

## 快速开始

### 1. 启动 Mock 后端

```bash
cd backend
npm install
npm run dev
```

服务地址：`http://localhost:3009`

### 2. Web 调试 Flutter

```bash
cd mobile
flutter pub get
flutter run -d chrome --dart-define=API_BASE=http://localhost:3009
```

## 路由（28 页）

| 路由 | 页面 |
|------|------|
| `/` | 启动 |
| `/login` | 登录 |
| `/hr/dashboard` | HR 工作台（Tab） |
| `/hr/jobs` | 职位管理（Tab） |
| `/hr/profile` | HR 个人中心（Tab） |
| `/hr/job/create` | 发布职位 |
| `/hr/job/:id` | 职位详情 |
| `/hr/pipeline/:jobId` | Pipeline Kanban |
| `/hr/application/:id` | 简历详情 + 时间轴 |
| `/hr/interview/schedule` | 安排面试（table_calendar） |
| `/hr/interviews` | 面试列表 |
| `/hr/interview/:id/feedback` | 面试反馈 |
| `/hr/offer/create` | 创建 Offer |
| `/hr/offers` | Offer 列表 |
| `/manager/approvals` | Offer 审批（经理） |
| `/hr/talent-pool` | 人才库 |
| `/hr/referrals` | 内推管理 |
| `/hr/reports` | 漏斗 + 来源报表 |
| `/jobs` | 职位广场（候选人 Tab） |
| `/job/:id` | 公开 JD |
| `/job/:id/apply` | 投递表单 |
| `/candidate/applications` | 我的投递 |
| `/candidate/application/:id` | 投递进度轴 |
| `/referral` | 内推码 |
| `/interviewer/schedule` | 面试官日程 |
| `/interviewer/interview/:id` | 填写反馈 |
| `/messages` | 消息 |
| `/profile` | 个人中心 |
| `/settings` | 设置 |

## 业务规则（Mock）

- Pipeline：投递 → 筛选 → 笔试 → 一面 → 二面 → Offer → 入职 / 淘汰
- 面试冲突：同一面试官同时段返回 **409** + 推荐时段
- Offer：薪资超 band 需 `manager1` 审批
- 内推：成功入职奖励 **5000** Mock 积分
- 简历筛选：关键词 + 学历 + 年限

## 测试

```bash
# 后端 API 测试
cd backend && npm test

# Flutter 单元测试
cd mobile && flutter test
```

Seed 数据：22 职位、90 投递，各阶段均有分布。

## Web 兼容说明

- 简历以结构化 JSON 字段 + URL 链接展示，不做 PDF 原生解析
- 日历仅 App 内 table_calendar，不同步系统日历
- 不使用 LinkedIn SDK 等原生插件

## 多角色 Web 调试

1. 启动后端 + `flutter run -d chrome`
2. 用 `hr1` 登录测试 Pipeline、排期、Offer
3. 退出后用 `manager1` 审批超 band Offer
4. 用 `candidate1` 浏览职位、投递、查看进度
5. 用 `interviewer1` 查看日程并提交反馈
