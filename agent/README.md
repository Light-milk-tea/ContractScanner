# ContractScanner RAG Agent

Python 知识库检索服务，为 Node 分析流水线提供风险规则 / 样例标注 / 法条摘录检索。

## 启动

```bash
cd agent
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python scripts/build_index.py
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

默认端口 `8000`。Embedding 优先使用与 Node 相同的百炼 Key（环境变量 `LLM_API_KEY` / `EMBEDDING_API_KEY`，或仓库根目录 `apikey.txt`）。无 Key 时自动降级为本地 hash embedding，便于离线建库联调。

## 接口

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/health` | 健康检查与索引条数 |
| POST | `/v1/retrieve` | 检索 hits（含可选 citation） |
| POST | `/v1/admin/rebuild` | 重建索引 |

### 检索示例

```bash
curl -s http://127.0.0.1:8000/v1/retrieve \
  -H 'Content-Type: application/json' \
  -d '{"query":"自动续约两年 押金自行决定是否退还","businessTag":"租房","topK":5}'
```

## 语料

- `kb/risk_rules/`：风险规则
- `kb/samples_annotated/`：样例标注
- `kb/law_snippets/`：法条短摘录（唯一允许作为 legalBasis 的 citation 来源）
  - `laws.json`：人工精选条款
  - `laws_imported.json`：从开源法规集切条导入（可重建）

### 从开源数据集导入法条

原始全量包约 100MB（Git LFS），已下载到 `data/raw_laws/`（gitignore，不入库）。切条：

```bash
# 若尚未有 raw：用 scripts 旁说明或重新跑 Git LFS / HF 下载
python scripts/import_law_dataset.py --civil-code-only-contract
python scripts/build_index.py
```

`--civil-code-only-contract`：民法典只保留合同相关条款，避免全量 1200+ 条噪声。

修改语料后执行 `python scripts/build_index.py` 或调用 `/v1/admin/rebuild`。
