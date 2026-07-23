# Git 完整手冊

> 基於 [git-scm.com/docs](https://git-scm.com/docs) 官方文件整理
> 版本：2026-05-13

> ⚠️ 本檔為純指令查閱手冊，不含執行權限規則。危險操作（`branch -D`、`push --force`、
> `reset --hard`、`clean -f`、`worktree remove` 等）會造成不可逆的損失，執行前一律先向
> 使用者說明「要刪什麼、影響範圍」並取得明確同意；各專案可在自己的規則檔訂定更嚴格的條件。

---

## 目錄

1. [初始設定](#1-初始設定)
2. [建立與取得專案](#2-建立與取得專案)
3. [基本快照操作](#3-基本快照操作)
4. [分支與合併](#4-分支與合併)
5. [遠端協作](#5-遠端協作)
6. [歷史查看與比較](#6-歷史查看與比較)
7. [撤銷與修復](#7-撤銷與修復)
8. [進階技巧](#8-進階技巧)
9. [除錯工具](#9-除錯工具)
10. [常用 Alias 速查](#10-常用-alias-速查)
11. [概念圖解](#11-概念圖解)

---

## 1. 初始設定

### 1.1 身份設定（必做）

```bash
git config --global user.name "你的名字"
git config --global user.email "你的信箱@example.com"
```

### 1.2 常用全域設定

```bash
# 預設編輯器
git config --global core.editor "vim"           # Linux/Mac
git config --global core.editor "notepad"       # Windows

# 換行符號處理
git config --global core.autocrlf true          # Windows
git config --global core.autocrlf input         # Mac/Linux

# 彩色輸出
git config --global color.ui auto

# 自動更正拼字錯誤（0.1 秒後執行）
git config --global help.autocorrect 1
```

### 1.3 設定作用範圍

| 範圍 | 旗標 | 檔案位置 |
|------|------|---------|
| 系統 | `--system` | `/etc/gitconfig` |
| 使用者 | `--global` | `~/.gitconfig` |
| 專案 | `--local`（預設） | `.git/config` |
| Worktree | `--worktree` | `.git/config.worktree` |

**後者蓋過前者**（系統 → 使用者 → 專案 → Worktree）

```bash
# 查看所有設定及來源
git config --list --show-origin

# 查看單一設定值
git config user.name

# 刪除設定
git config --global --unset core.editor
```

### 1.4 設定 Alias（縮寫指令）

```bash
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.st status
git config --global alias.lg "log --oneline --graph --all --decorate"
git config --global alias.unstage "reset HEAD --"
git config --global alias.amend "commit --amend --no-edit"
```

使用方式：`git co main`、`git lg`

---

## 2. 建立與取得專案

### 2.1 初始化新專案

```bash
# 在當前目錄初始化
git init

# 指定目錄初始化
git init my-project

# 初始化並指定主幹名稱
git init -b main
```

### 2.2 複製遠端專案

```bash
# 基本複製
git clone https://github.com/user/repo.git

# 複製到指定目錄
git clone https://github.com/user/repo.git my-folder

# 只複製最新版本（淺複製，加速下載）
git clone --depth 1 https://github.com/user/repo.git

# 複製特定分支
git clone -b develop https://github.com/user/repo.git

# 複製含子模組
git clone --recurse-submodules https://github.com/user/repo.git
```

---

## 3. 基本快照操作

### 3.1 查看工作區狀態

```bash
git status

# 簡短輸出
git status -s
```

**狀態符號說明：**

| 符號 | 含義 |
|------|------|
| `M ` | 已暫存的修改 |
| ` M` | 未暫存的修改 |
| `A ` | 新增到暫存區 |
| `??` | 未追蹤的檔案 |
| `D ` | 已暫存的刪除 |

### 3.2 暫存檔案（git add）

```bash
# 暫存單一檔案
git add file.txt

# 暫存所有變更
git add .
git add -A

# 互動式選擇暫存內容（hunk 級別）
git add -p

# 暫存目錄下所有 .js 檔
git add "*.js"
```

### 3.3 提交（git commit）

```bash
# 基本提交（開啟編輯器）
git commit

# 直接帶訊息提交
git commit -m "修正登入 bug"

# 自動暫存已追蹤檔案並提交
git commit -a -m "更新所有追蹤檔案"

# 修改上一次提交
git commit --amend -m "新的提交訊息"

# 修改上一次提交但保留訊息
git commit --amend --no-edit

# 預覽將提交什麼（不實際提交）
git commit --dry-run

# 提交並加入 Signed-off-by
git commit -s -m "實作功能 X"
```

**提交訊息格式建議：**

```
<類型>(<範圍>): <簡短描述>（≤50字）

<詳細說明>（選填，72字換行）

<頁腳：Breaking change / Issue 連結>（選填）
```

類型：`feat` / `fix` / `chore` / `docs` / `refactor` / `test`

### 3.4 查看差異（git diff）

```bash
# 工作區 vs 暫存區
git diff

# 暫存區 vs 最新提交
git diff --staged
git diff --cached   # 同上

# 兩個提交之間的差異
git diff HEAD~3 HEAD

# 只看變更的檔案名
git diff --name-only

# 查看特定檔案差異
git diff HEAD -- path/to/file.txt
```

### 3.5 移除與移動檔案

```bash
# 從工作區和暫存區刪除
git rm file.txt

# 只從追蹤清單移除（保留本地檔案）
git rm --cached file.txt

# 移動 / 重新命名
git mv old-name.txt new-name.txt
```

### 3.6 還原工作區（git restore）

```bash
# 還原工作區到 HEAD 狀態（丟棄未暫存的修改）
git restore file.txt

# 取消暫存（從暫存區移回工作區）
git restore --staged file.txt

# 從特定提交還原
git restore --source=HEAD~2 file.txt
```

---

## 4. 分支與合併

### 4.1 分支管理（git branch）

```bash
# 列出本地分支
git branch

# 列出所有分支（含遠端）
git branch -a

# 列出遠端分支
git branch -r

# 建立新分支
git branch feature/login

# 建立並切換（舊語法）
git checkout -b feature/login

# 建立並切換（新語法，推薦）
git switch -c feature/login

# 重新命名分支
git branch -m old-name new-name

# 刪除分支（已合併才能刪）
git branch -d feature/login

# 強制刪除分支
git branch -D feature/login

# 查看哪些分支已合併到 main
git branch --merged main

# 查看哪些分支尚未合併
git branch --no-merged main

# 顯示目前所在分支
git branch --show-current
```

### 4.2 切換分支（git switch / checkout）

```bash
# 切換到已存在的分支（新語法）
git switch main

# 切換到已存在的分支（舊語法）
git checkout main

# 建立並切換
git switch -c new-feature

# 切換到上一個分支
git switch -
```

### 4.3 合併（git merge）

```bash
# 合併分支（預設行為：有可能 fast-forward）
git merge feature/login

# 強制建立 merge commit（保留分支記錄）
git merge --no-ff feature/login

# 只允許 fast-forward（不可能則失敗）
git merge --ff-only feature/login

# 合併但不自動 commit（可先審查）
git merge --no-commit feature/login

# 壓縮所有提交為一個（不記錄合併關係）
git merge --squash feature/login && git commit -m "合併 feature/login"

# 衝突時選擇我方版本
git merge -Xours upstream

# 衝突時選擇對方版本
git merge -Xtheirs upstream

# 中止合併
git merge --abort

# 繼續合併（解衝突後）
git merge --continue
```

**解衝突流程：**

```bash
git merge feature-branch   # 發生衝突
# 手動編輯衝突檔案，移除 <<<<< ===== >>>>> 標記
git add resolved-file.txt  # 標記為已解決
git merge --continue       # 或 git commit
```

### 4.4 Rebase

```bash
# 把當前分支接到 main 最新點
git rebase main

# 互動式 rebase（整理最近 5 次提交）
git rebase -i HEAD~5

# 使用 --onto 移植分支
git rebase --onto main feature-base feature-branch

# 繼續（解衝突後）
git rebase --continue

# 跳過當前提交
git rebase --skip

# 中止 rebase
git rebase --abort
```

**互動式 rebase 指令：**

| 指令 | 說明 |
|------|------|
| `pick` | 保留此提交 |
| `reword` | 修改提交訊息 |
| `edit` | 暫停以修改此提交 |
| `squash` | 合併到上一個提交 |
| `fixup` | 合併到上一個提交（丟棄訊息） |
| `drop` | 刪除此提交 |
| `exec <cmd>` | 在此提交後執行指令 |

> **黃金原則**：永遠不要 rebase 已推送到共享分支的提交。

### 4.5 暫存工作（git stash）

```bash
# 暫存當前所有變更
git stash

# 暫存並加標籤
git stash push -m "WIP: 登入功能一半"

# 暫存含未追蹤的檔案
git stash push -u

# 只暫存特定檔案
git stash push -- src/login.js

# 查看所有暫存
git stash list

# 套用最新暫存（保留 stash）
git stash apply

# 套用指定暫存
git stash apply stash@{2}

# 套用並刪除暫存
git stash pop

# 查看暫存內容
git stash show -p stash@{0}

# 刪除指定暫存
git stash drop stash@{1}

# 清空所有暫存
git stash clear
```

**典型場景：**

```bash
# 需要緊急切換分支時
git stash
git switch hotfix/urgent
# ... 修完後 ...
git switch feature/mine
git stash pop
```

### 4.6 標籤（git tag）

```bash
# 建立輕量標籤
git tag v1.0.0

# 建立附註標籤（推薦用於發版）
git tag -a v1.0.0 -m "Release 1.0.0"

# 為歷史提交打標籤
git tag -a v0.9.0 abc1234

# 列出所有標籤
git tag

# 篩選標籤
git tag -l "v1.*"

# 推送標籤到遠端
git push origin v1.0.0
git push origin --tags    # 推送所有標籤

# 刪除本地標籤
git tag -d v1.0.0

# 刪除遠端標籤
git push origin --delete v1.0.0
```

---

## 5. 遠端協作

### 5.1 遠端管理（git remote）

```bash
# 查看遠端
git remote -v

# 新增遠端
git remote add origin https://github.com/user/repo.git

# 重新命名遠端
git remote rename origin upstream

# 移除遠端
git remote remove upstream

# 修改遠端 URL
git remote set-url origin https://github.com/user/new-repo.git
```

### 5.2 抓取與拉取

```bash
# 抓取遠端變更（不合併）
git fetch origin

# 抓取所有遠端
git fetch --all

# 拉取並合併（= fetch + merge）
git pull

# 拉取並以 rebase 整合（推薦）
git pull --rebase

# 拉取特定分支
git pull origin main
```

### 5.3 推送

```bash
# 推送到遠端
git push origin main

# 首次推送並設置追蹤
git push -u origin feature/login

# 推送所有分支
git push --all origin

# 強制推送（危險！確保自己清楚後果）
git push --force-with-lease origin feature/login   # 較安全
git push --force origin feature/login              # 危險，會覆蓋

# 刪除遠端分支
git push origin --delete feature/old-branch
```

---

## 6. 歷史查看與比較

### 6.1 查看提交歷史（git log）

```bash
# 基本查看
git log

# 簡潔一行
git log --oneline

# 圖形化顯示所有分支
git log --oneline --graph --all --decorate

# 限制筆數
git log -10

# 依時間篩選
git log --since="2 weeks ago"
git log --after="2024-01-01" --before="2024-12-31"

# 依作者篩選
git log --author="Alice"

# 依提交訊息篩選
git log --grep="bug fix"

# 查看特定檔案的歷史
git log -p -- path/to/file.txt

# 查看兩分支之間的差異提交
git log main..feature-branch

# 顯示檔案統計
git log --stat

# 自訂格式
git log --format="%h %an %ar: %s"
```

**常用格式佔位符：**

| 佔位符 | 說明 |
|--------|------|
| `%H` | 完整 commit hash |
| `%h` | 短 commit hash |
| `%an` | 作者姓名 |
| `%ae` | 作者信箱 |
| `%ar` | 相對時間（e.g. 2 days ago） |
| `%s` | 提交標題 |
| `%b` | 提交內文 |
| `%d` | 分支 / 標籤裝飾 |

### 6.2 查看單一提交（git show）

```bash
# 查看最新提交
git show

# 查看特定提交
git show abc1234

# 查看特定提交的特定檔案
git show abc1234:path/to/file.txt

# 查看標籤資訊
git show v1.0.0
```

### 6.3 Reflog — 救命工具

reflog 記錄 HEAD 的每一次移動，即使提交被刪除也能找回。

```bash
# 查看 HEAD 移動記錄
git reflog

# 查看特定分支的 reflog
git reflog show main

# 列出所有 ref 的 reflog
git reflog list

# 還原到 reflog 中的某個狀態
git reset --hard HEAD@{3}
git checkout HEAD@{5}
```

**典型救援場景：**

```bash
# 誤刪分支或 reset --hard 後救回
git reflog                        # 找到丟失前的 hash
git checkout -b recovered abc123  # 建立新分支指向那個提交
```

---

## 7. 撤銷與修復

### 7.1 git reset — 回退到過去

```bash
# 取消暫存（保留工作區）
git reset HEAD file.txt
git restore --staged file.txt    # 現代寫法

# --soft：只移動 HEAD（保留暫存區和工作區）
git reset --soft HEAD~1

# --mixed（預設）：移動 HEAD + 清空暫存區
git reset HEAD~1

# --hard：完全回退（危險！丟失所有變更）
git reset --hard HEAD~3

# 安全：使用 --keep（若有未提交變更則中止）
git reset --keep HEAD~1
```

| 模式 | HEAD | 暫存區 | 工作區 |
|------|------|--------|--------|
| `--soft` | ✅ 移動 | 不變 | 不變 |
| `--mixed` | ✅ 移動 | ✅ 重置 | 不變 |
| `--hard` | ✅ 移動 | ✅ 重置 | ✅ 重置 |

### 7.2 git revert — 安全撤銷（不改歷史）

```bash
# 建立一個撤銷某提交的新提交
git revert abc1234

# 撤銷但不自動 commit
git revert --no-commit abc1234

# 撤銷範圍
git revert HEAD~3..HEAD
```

> **共享分支請用 revert，不要用 reset**。revert 不改歷史，reset 會。

### 7.3 Cherry-pick — 挑選提交

```bash
# 把某個提交套用到當前分支
git cherry-pick abc1234

# 套用但不自動 commit
git cherry-pick -n abc1234

# 套用多個提交
git cherry-pick abc1234 def5678

# 套用範圍（不含 start，含 end）
git cherry-pick start..end

# 加入來源資訊到訊息
git cherry-pick -x abc1234

# 解衝突後繼續
git cherry-pick --continue

# 中止
git cherry-pick --abort
```

---

## 8. 進階技巧

### 8.1 Worktree — 多分支同時工作

允許在同一個 repo 中同時 checkout 多個分支到不同目錄。

```bash
# 建立新 worktree
git worktree add ../feature-branch feature/login

# 建立 worktree 並建立新分支
git worktree add -b hotfix/urgent ../hotfix main

# 列出所有 worktree
git worktree list

# 移除 worktree
git worktree remove ../feature-branch

# 清理過時的 worktree 記錄
git worktree prune
```

### 8.2 Submodule — 子模組

```bash
# 新增子模組
git submodule add https://github.com/user/lib.git libs/mylib

# 初始化並更新子模組
git submodule init
git submodule update

# 一步完成
git submodule update --init --recursive

# 更新所有子模組到最新
git submodule update --remote

# 複製含子模組的專案
git clone --recurse-submodules https://github.com/user/repo.git
```

### 8.3 搜尋（git grep）

```bash
# 在工作區搜尋字串
git grep "TODO"

# 顯示行號
git grep -n "function login"

# 在特定提交搜尋
git grep "deprecated" v1.0.0

# 搜尋並只顯示檔名
git grep -l "TODO"

# 配合正則表達式
git grep -E "function\s+\w+"
```

### 8.4 清理工作區（git clean）

```bash
# 預覽將被刪除的未追蹤檔案
git clean -n

# 刪除未追蹤的檔案
git clean -f

# 刪除未追蹤的檔案和目錄
git clean -fd

# 連 .gitignore 忽略的也刪
git clean -fdx
```

### 8.5 Archive — 匯出版本

```bash
# 匯出為 tar.gz
git archive --format=tar.gz HEAD > release.tar.gz

# 匯出特定標籤
git archive --format=zip v1.0.0 > v1.0.0.zip

# 匯出特定目錄
git archive HEAD:src/ > src.tar
```

### 8.6 Bundle — 離線傳輸

```bash
# 建立完整 bundle
git bundle create repo.bundle --all

# 從 bundle 複製
git clone repo.bundle my-repo

# 只包含某個分支
git bundle create feature.bundle origin/main..feature/login
```

---

## 9. 除錯工具

### 9.1 git blame — 逐行追責

```bash
# 查看檔案每行的最後修改者
git blame file.txt

# 顯示簡短 hash
git blame -s file.txt

# 只看第 10-20 行
git blame -L 10,20 file.txt

# 忽略空白差異
git blame -w file.txt

# 追蹤跨檔案的移動
git blame -C file.txt
```

### 9.2 git bisect — 二分搜尋 Bug

用二分法快速找出引入 bug 的提交。

```bash
# 開始 bisect
git bisect start

# 標記當前版本有 bug
git bisect bad

# 標記已知正常版本
git bisect good v1.0.0

# Git 自動 checkout 中間版本，測試後標記...
git bisect good    # 或
git bisect bad

# 找到後結束
git bisect reset
```

**自動化測試：**

```bash
git bisect start
git bisect bad HEAD
git bisect good v1.0.0
git bisect run ./test.sh    # 0=good, 非0=bad, 125=skip
git bisect reset
```

**跳過無法測試的提交：**

```bash
git bisect skip                    # 跳過當前
git bisect skip v2.5..v2.6        # 跳過範圍
```

### 9.3 git fsck — 檔案系統完整性檢查

```bash
# 檢查物件資料庫
git fsck

# 只顯示懸空物件（可能是遺失的提交）
git fsck --lost-found
```

---

## 10. 常用 Alias 速查

推薦加入 `~/.gitconfig` 的實用 alias：

```ini
[alias]
    # 常用縮寫
    co = checkout
    sw = switch
    br = branch
    st = status
    ci = commit

    # 漂亮的 log
    lg = log --oneline --graph --all --decorate
    ll = log --oneline -20
    lf = log --format="%h %an %ar: %s"

    # 暫存相關
    unstage = restore --staged
    undo = reset --soft HEAD~1

    # 修正上一次 commit
    amend = commit --amend --no-edit

    # 快速 push 到遠端同名分支
    pub = push -u origin HEAD

    # 查看哪些分支已合併
    merged = branch --merged
    unmerged = branch --no-merged

    # 清理已合併的本地分支
    cleanup = "!git branch --merged | grep -v '\\*\\|main\\|master\\|develop' | xargs git branch -d"
```

---

## 11. 概念圖解

### 11.1 Git 三個工作區域

```
工作目錄          暫存區（Index）       本地 Repo
Working Tree   →   Staging Area    →   .git/
              add                commit

         ←  restore --staged         ←  reset --soft
         ←  restore                  ←  reset --hard
```

### 11.2 分支指標示意

```
main:    A ← B ← C
                   ↑
                 HEAD

feature: A ← B ← C ← D ← E
                             ↑
                           HEAD
```

### 11.3 Merge vs Rebase

```
# Merge（保留分支歷史）
main:    A ← B ← C ← M       ← merge commit
                 ↗
feature: D ← E

# Rebase（線性歷史）
main:    A ← B ← C ← D' ← E'  ← D, E 重新應用
```

### 11.4 Reset 三種模式

```
提交歷史:  A ← B ← C  (HEAD)
執行: git reset HEAD~1

--soft:   HEAD 指向 B，C 的變更還在暫存區
--mixed:  HEAD 指向 B，C 的變更退回工作目錄
--hard:   HEAD 指向 B，C 的變更完全消失
```

### 11.5 Cherry-pick

```
main:    A ← B ← C ← D
feature: A ← B ← E ← F

# git cherry-pick D（在 feature 上）
feature: A ← B ← E ← F ← D'
```

---

## 附錄：常用情境速查

| 情境 | 指令 |
|------|------|
| 撤銷最後一次提交（保留變更） | `git reset --soft HEAD~1` |
| 撤銷最後一次提交（丟棄變更） | `git reset --hard HEAD~1` |
| 修改最後一次提交訊息 | `git commit --amend -m "新訊息"` |
| 取消已暫存的檔案 | `git restore --staged file.txt` |
| 還原工作區的修改 | `git restore file.txt` |
| 緊急切換分支但不想 commit | `git stash` |
| 找回誤刪的提交 | `git reflog` → `git checkout <hash>` |
| 找出 bug 在哪次提交引入 | `git bisect start` → 二分標記 |
| 把某個提交搬到另一分支 | `git cherry-pick <hash>` |
| 合併但保留分支歷史記錄 | `git merge --no-ff` |
| 本地提交整理後再推送 | `git rebase -i HEAD~N` |
| 查看某檔案誰改了哪行 | `git blame file.txt` |
| 在整個 repo 搜尋字串 | `git grep "keyword"` |

---

*參考來源：[git-scm.com/docs](https://git-scm.com/docs)*

---
**最後更新**: 2026-05-13
**維護者**: 開發團隊
**文件版本**: v1.0
**變更記錄**（里程碑，最多 5 條）:
- v1.0 (2026-05-13): 首版，依 git-scm.com 官方文件整理成純指令查閱手冊；危險操作的執行權限規則由各專案自訂
