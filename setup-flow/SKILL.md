---
name: setup-flow
description: 工程流程技能組的一次性設定——議題追蹤系統落點與領域文件配置。每個倉庫跑一次。
disable-model-invocation: true
---

# 流程初始化 (Setup Flow)

`to-spec`、`to-tickets`、`implement` 都假設「工單放在哪」已經決定好了。這個技能把那個決定寫成設定檔，讓那三個技能各自去讀，而不是各問一次——**單一真實來源**。

每個倉庫跑一次。

## 步驟

### 1. 先探勘再問

動嘴之前先自己查。**能從環境查到的事實就自己查，不要拿來問使用者**：

```bash
git remote -v
git -C . rev-parse --show-toplevel
```

同時檢查：有沒有 `CONTEXT.md`、有沒有 `docs/adr/`、有沒有 monorepo 的訊號（`pnpm-workspace.yaml`、`lerna.json`、`composer.json` 的多套件配置）、有沒有 GitHub／GitLab remote。

**完成判準**：你能講出這個倉庫的 remote 是什麼、是不是 monorepo、既有的文件落在哪——每一項都指得出證據。

### 2. 把探勘結果連同建議一起攤出來

一次問一個問題，每題附上你依探勘結果建議的答案：

1. **工單放哪**？（GitHub Issues／GitLab Issues／本地檔案 `tmp/{功能名}/tickets/`／其他）
2. **領域文件怎麼配**？（單一倉庫：根目錄一份 `CONTEXT.md` + `docs/adr/`；monorepo：每個 package 一份 `CONTEXT.md`，根目錄放 `CONTEXT-MAP.md` 指過去）

### 3. 寫設定檔

寫到 `docs/agents/flow-config.md`：

```markdown
# 工程流程設定

## 議題追蹤
- 系統：GitHub Issues
- 位置：<owner>/<repo>
- 建立方式：`gh issue create`

## 領域文件
- 模式：單一倉庫
- 詞彙表：`CONTEXT.md`
- ADR：`docs/adr/NNNN-標題.md`
```

### 4. 在倉庫入口檔留一行指標

在 `CLAUDE.md`（或 `AGENTS.md`，取先存在的那個）加一行指向設定檔的指標，別把設定內容抄進去——抄第二份，兩邊就會漂移。

## 完成判準

`docs/agents/flow-config.md` 存在且兩節都填滿；倉庫入口檔有一行指過去。設定檔已存在時，讀出來確認一次，**不要覆寫**——要改就明說改哪一行。
