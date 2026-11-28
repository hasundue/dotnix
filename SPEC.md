---
status: agreed
---

# ワークツリー移動のハンドオフをセッション metadata で渡す

## 問題

`herdr_worktree_move` のあとに同じ Pi セッションで `/new` すると，移動済みを伝え
る非表示メッセージが再注入され，エージェントが自動で返答する．この再注入は CLI
フラグが根拠になっており，プロセスの argv に残る値はセッションが置き換わっても消
えない．移動が一度きりであることを，セッションの再開や fork をまたいで保持する必
要がある．

## 設計

- 作業は `/home/hasundue/dotnix.pi-handoff-metadata`（branch
  `pi-handoff-metadata`）で行い，main checkout では編集しない．
- CLI フラグ `--herdr-worktree-handoff` は撤廃する．argv に残ると `/new` のたび
  に再読まれるため．
- `configs/home/herdr/worktree-handoff.nix` から agent start のフラグを外す．
- `configs/home/pi/agent/extensions/herdr-worktree/common.ts` に metadata と
  done の customType，型，読み取り helper を定義する．途中まで入った変更を仕上げ
  る．
- `configs/home/pi/agent/extensions/herdr-worktree/index.ts` は plugin action の
  起動前に，移動元セッションへ `handoffId`，`sourcePaneId`，`destinationPaneId`
  の custom entry を書く．移動先が `--fork` で受け取るには起動前の書き込みが必要
  なため．metadata は job ファイルより先に置き，job は一時名に書いてから
  consumer が見る名前へ atomically rename する．job の作成や action が失敗した
  場合は同じ `handoffId` を done にして job を取り消す．
- `configs/home/pi/agent/extensions/herdr-worktree/handoff.ts` は
  `session_start` を `reason === "startup"` に限定し，`HERDR_PANE_ID` と
  `destinationPaneId` が一致し，対応する done が無い metadata がちょうど 1 つの
  場合だけ処理する．
- 未処理 metadata が自分の pane 向けに複数なら，どれも選ばず警告して
  `HANDOFF_MESSAGE` の `triggerTurn` を送らない．誤った pane の cleanup を避ける
  ため．壊れた metadata が同じ pane 向けにある場合も処理しない．ID は非空文字列
  だけを有効とし，空文字や壊れた record は候補として扱わない．
- done は処理開始時に同じ `handoffId` で書く．途中で落ちた場合の再実行を防ぐた
  め．
- metadata と done は `custom` entry にして LLM コンテキストに乗せない．モデルへ
  の指示は既存の `HANDOFF_MESSAGE` を `sendMessage` で送る．
- cleanup の前と pane を閉じる直前の 2 回，source pane が今も moving 元 session
  を指していることを，fork された session header の `parentSession` と照合する．
  照合できない場合は pane も session も触らない．
- `placement()` の `rootPaneId` は Herdr レスポンス名として残し，metadata 側の
  フィールド名は `destinationPaneId` を使う．source 側は `sourcePaneId` を使う．

## 対象外

- Herdr 本体の変更
- 既存セッションに残った CLI フラグの移行
- `HANDOFF_MESSAGE` の文言変更
- pane の agent session 参照が失われる別件の修正

## 受け入れ条件

- CLI フラグがコードから消えている．
  - [x] `rg -n 'HANDOFF_FLAG|--herdr-worktree-handoff' configs/home/herdr configs/home/pi/agent/extensions/herdr-worktree`
        が不一致になること．
    - 実施: exit 1 で出力なし．
- metadata と done がモデルに渡されない．
  - [x] 移動先セッションの JSONL で，両者が `type: "custom"` の entry であ
        り，`custom_message` や message として現れないこと．
    - 実施: 移動先 JSONL の metadata と done は `type: "custom"` のみ．
      `herdr-worktree-handoff` の `custom_message` は `HANDOFF_MESSAGE` の 1 件
      だけで，metadata と done は `custom_message` にも message にも現れない．
- `/new` で自動ターンが始まらない．
  - [x] 移動先で `/new` した直後のセッションに `herdr-worktree-handoff` の
        `custom_message` が無く，assistant message が生成されないこと．
    - 実施: `w0:p1` で `/new` 後，端末出力は `New session started`，
      `agent_status` は 30 秒間 idle のまま．handoff の `custom_message` も
      assistant message も生成されず，セッションファイルも作成されなかった．
- 初回ハンドオフは従来どおり動く．
  - [x] move 直後の初回起動で，focus が移動先 pane に移り，source pane と source
        session が cleanup されること．
    - 実施: `wR:p2` から `handoff-smoke` へ move し，移動先 `w0:p1` は
      `focused: true`．Niri の focused-window title は
      `x1carbon: dotnix.handoff-smoke`．source pane は `pane_not_found`，
      source session file は削除済み．別途 `wR:p3` から
      `handoff-smoke-verify` へ move した際は，移動先 header の `parentSession`
      が source session と一致し，warning なしで cleanup された．
  - [x] そのセッションに同じ `handoffId` の done entry が 1 つだけあること．
    - 実施: `032c8916-6f70-4636-a5bf-8594590d519f` の done entry は 1 件．
- 複数移動でも古い metadata を再処理しない．
  - [x] 同じセッションから 2 回 move し，2 回目の移動先では 1 回目の `handoffId`
        の focus と cleanup が走らず，2 回目だけが処理されること．
    - 実施: `w0:p1` から `handoff-smoke-2` へ move．2 回目の
      `ebf7fea3-c05f-42ba-b729-c07ad87c9e10` の done は 1 件，1 回目の
      `032c8916-6f70-4636-a5bf-8594590d519f` の done は 0 件．focus は
      22:25:42 に `x1carbon: dotnix.handoff-smoke-2` へ移り，1 回目の source
      pane `wR:p2` は再処理されず，2 回目の source pane `w0:p1` だけ cleanup
      された．別途 RPC で `test:p1` 向けに done 済み `old-handoff` と未処理
      `new-handoff` を置き，`new-handoff` だけが処理されることも確認した．
- pane 向けの未処理 metadata が複数なら fail-closed になる．
  - [x] 2 つの metadata を同じ `destinationPaneId` で入れたセッションを起動し，
        警告が出て，`triggerTurn` も cleanup も起きないこと．
    - 実施: RPC で `test:p1` 向けの未処理 metadata を 2 件入れたところ，警告
      `Multiple handoffs target pane test:p1; none was processed.` が 1 件．
      done entry は 0，handoff の `custom_message` と cleanup notification も 0
      件．空文字の ID を含む metadata では
      `Malformed handoff metadata targets pane test:p1; none was processed.`
      が 1 件で，done と `custom_message` は 0 件だった．
- 静的検証が通る．
  - [x] `nix fmt` と `nix run .#home-build` が成功すること．
    - 実施: `nix fmt` は 1 ファイルを整形して終了，`nix run .#home-build` と
      `nix run .#home-switch` も成功．

## 停止条件

- pane に `agent_session` が無い状態でスモークテストを始める場合，別件のセッショ
  ン参照問題として停止する．
- 既存セッションの移行や `HANDOFF_MESSAGE` の文言変更が必要になった場合，この
  spec の合意を変更するため keel に戻る．
