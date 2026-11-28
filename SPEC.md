---
status: agreed
---

# ワークツリー移動のハンドオフをセッション metadata で渡す

## 問題

`herdr_worktree_move` のあとに同じ Pi セッションで `/new` すると，移動済みを伝える非表示メッセージが再注入され，エージェントが自動で返答する．この再注入は CLI フラグが根拠になっており，プロセスの argv に残る値はセッションが置き換わっても消えない．移動が一度きりであることを，セッションの再開や fork をまたいで保持する必要がある．

## 設計

- 作業は `/home/hasundue/dotnix.pi-handoff-metadata`（branch `pi-handoff-metadata`）で行い，main checkout では編集しない．
- CLI フラグ `--herdr-worktree-handoff` は撤廃する．argv に残ると `/new` のたびに再読まれるため．
- `configs/home/herdr/worktree-handoff.nix` から agent start のフラグを外す．
- `configs/home/pi/agent/extensions/herdr-worktree/common.ts` に metadata と done の customType，型，読み取り helper を定義する．途中まで入った変更を仕上げる．
- `configs/home/pi/agent/extensions/herdr-worktree/index.ts` は plugin action の起動前に，移動元セッションへ `handoffId`，`sourcePaneId`，`destinationPaneId` の custom entry を書く．移動先が `--fork` で受け取るには起動前の書き込みが必要なため．
- `configs/home/pi/agent/extensions/herdr-worktree/handoff.ts` は `session_start` を `reason === "startup"` に限定し，`HERDR_PANE_ID` と `destinationPaneId` が一致し，対応する done が無い metadata がちょうど 1 つの場合だけ処理する．
- 未処理 metadata が自分の pane 向けに複数なら，どれも選ばず警告して `HANDOFF_MESSAGE` の `triggerTurn` を送らない．誤った pane の cleanup を避けるため．
- done は処理開始時に同じ `handoffId` で書く．途中で落ちた場合の再実行を防ぐため．
- metadata と done は `custom` entry にして LLM コンテキストに乗せない．モデルへの指示は既存の `HANDOFF_MESSAGE` を `sendMessage` で送る．
- `placement()` の `rootPaneId` は Herdr レスポンス名として残し，metadata 側のフィールド名は `destinationPaneId` を使う．source 側は `sourcePaneId` を使う．

## 対象外

- Herdr 本体の変更
- 既存セッションに残った CLI フラグの移行
- `HANDOFF_MESSAGE` の文言変更
- pane の agent session 参照が失われる別件の修正

## 受け入れ条件

- CLI フラグがコードから消えている．
  - [ ] `rg -n 'HANDOFF_FLAG|--herdr-worktree-handoff' configs/home/herdr configs/home/pi/agent/extensions/herdr-worktree` が不一致になること．
    - 未実施
- metadata と done がモデルに渡されない．
  - [ ] 移動先セッションの JSONL で，両者が `type: "custom"` の entry であり，`custom_message` や message として現れないこと．
    - 未実施
- `/new` で自動ターンが始まらない．
  - [ ] 移動先で `/new` した直後のセッションに `herdr-worktree-handoff` の `custom_message` が無く，assistant message が生成されないこと．
    - 未実施
- 初回ハンドオフは従来どおり動く．
  - [ ] move 直後の初回起動で，focus が移動先 pane に移り，source pane と source session が cleanup されること．
    - 未実施
  - [ ] そのセッションに同じ `handoffId` の done entry が 1 つだけあること．
    - 未実施
- 複数移動でも古い metadata を再処理しない．
  - [ ] 同じセッションから 2 回 move し，2 回目の移動先では 1 回目の `handoffId` の focus と cleanup が走らず，2 回目だけが処理されること．
    - 未実施
- pane 向けの未処理 metadata が複数なら fail-closed になる．
  - [ ] 2 つの metadata を同じ `destinationPaneId` で入れたセッションを起動し，警告が出て，`triggerTurn` も cleanup も起きないこと．
    - 未実施
- 静的検証が通る．
  - [ ] `nix fmt` と `nix run .#home-build` が成功すること．
    - 未実施

## 停止条件

- pane に `agent_session` が無い状態でスモークテストを始める場合，別件のセッション参照問題として停止する．
- 既存セッションの移行や `HANDOFF_MESSAGE` の文言変更が必要になった場合，この spec の合意を変更するため keel に戻る．
