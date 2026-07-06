# Tasks

- [ ] Task 1: 锁定首版范围与评审主线
  - [ ] SubTask 1.1: 固定目标用户为“非法律专业合同签署者”
  - [ ] SubTask 1.2: 固定主链路为“导入合同 -> 分析中 -> 风险与摘要 -> 对照阅读”
  - [ ] SubTask 1.3: 将电子签署、律师咨询、合同改写、多人协作放入二期清单

- [ ] Task 2: 基于 DevEco Studio 基础模板搭建工程骨架
  - [ ] SubTask 2.1: 使用 Empty Ability 模板创建项目并确认可运行
  - [ ] SubTask 2.2: 在模板首页增加“导入合同”业务入口，形成最小可演示版本
  - [ ] SubTask 2.3: 规划目录分层：`pages`、`components`、`services`、`model`
  - [ ] SubTask 2.4: 保持模板默认构建配置稳定，不在首期引入高风险依赖

- [ ] Task 3: 设计 HarmonyOS 原生页面与导航
  - [ ] SubTask 3.1: 明确页面结构：首页、上传页、分析页、结果页、对照阅读页
  - [ ] SubTask 3.2: 规划页面导航与状态流转（空态、分析中、成功、失败）
  - [ ] SubTask 3.3: 规划手机优先布局，并预留平板/PC 接续后的展示适配

- [ ] Task 4: 设计合同导入与 AI 输出协议
  - [ ] SubTask 4.1: 明确合同输入路径（拍照、相册、文件上传）
  - [ ] SubTask 4.2: 定义统一结果结构（摘要、风险等级、原文片段、白话解释）
  - [ ] SubTask 4.3: 设计异常处理策略（导入失败、识别失败、分析超时、结果不完整）
  - [ ] SubTask 4.4: 明确客户端与服务端协议（上传参数、状态查询、结果响应）

- [ ] Task 5: 实现比赛导向的三项鸿蒙特性
  - [ ] SubTask 5.1: 接入应用接续或跨设备互通，支持手机到平板/PC 连续阅读
  - [ ] SubTask 5.2: 设计互动卡片，展示最近分析状态或高风险摘要
  - [ ] SubTask 5.3: 接入隐私防窥，保护合同正文与风险信息
  - [ ] SubTask 5.4: 资源允许时补充多窗对照阅读作为加分项

- [ ] Task 6: 明确分工与质量基线
  - [ ] SubTask 6.1: 前端负责页面交互、系统能力接入、缓存与展示
  - [ ] SubTask 6.2: 服务端负责 OCR、文本清洗、条款切分、风险分析与摘要生成
  - [ ] SubTask 6.3: 明确日志与错误码，支持现场演示排障
  - [ ] SubTask 6.4: 明确隐私策略，区分本地缓存数据与云端分析数据

- [ ] Task 7: 打磨答辩演示与验收
  - [ ] SubTask 7.1: 准备 3 分钟演示脚本（痛点 -> AI 价值 -> 鸿蒙亮点 -> 结果可信）
  - [ ] SubTask 7.2: 准备至少 2 份样例合同（高风险、低风险）
  - [ ] SubTask 7.3: 制定验收标准（主链路稳定、三项特性可见、结果可解释）
  - [ ] SubTask 7.4: 预演“弱网/服务延迟”场景下的降级展示方案

# Task Dependencies
- Task 2 depends on Task 1
- Task 3 depends on Task 2
- Task 4 depends on Task 2 and Task 3
- Task 5 depends on Task 3 and Task 4
- Task 6 depends on Task 4 and Task 5
- Task 7 depends on Task 5 and Task 6
