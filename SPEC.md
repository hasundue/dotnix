---
status: agreed
---

# Herdr のワークスペースを worktree の移動に追従させる

## 問題

Herdr 内の Pi セッションが worktree へ移動しても，Herdr のワークスペースと
ペイン配置が追従しない．worktree の場所がワークスペースに表示されず，
ステータス集計，ペイン移動，クリーンアップが使われないままになる．

## 設計

### worktree の作成と Herdr の配置

- Herdr のみを対応対象とし，worktree の作成と削除は `herdr worktree create` と
  `herdr worktree remove` を使う．Worktrunk の directory directive はセッションを
  切り替えてもプロセスの cwd を変えないため，`configs/home/pi/default.nix` の
  pi-worktrunk 宣言と `.pi/settings.json` のプロジェクト有効化は削除する．
- worktree は
  `herdr worktree create --cwd <root> --branch <branch> --base main --path <path> --no-focus`
  で作る．レスポンスから workspace，tab，root pane の ID を得て後続の配置に使うため．
- `local.worktree-hooks` プラグインは `worktree.created` で共有 post-start hooks を
  実行する．新しい checkout でも既存の初期化を欠かさないため．
- 既存の Pi ペインは移動させず，新しい root pane で
  `herdr agent start <name> --kind pi --pane <root_pane_id> -- --fork <current session file> "<initial prompt>"`
  を実行する．フォークなら会話を保ったまま，宛先 worktree を cwd として起動できるため．

### ハンドオフとエージェントコンテキスト

- `configs/home/pi/agent/extensions/herdr-worktree.ts` を追加し，`HERDR_ENV=1` 以外では
  何もしない．Herdr 外のセッションに Herdr 固有の手順を渡さないため．
- Herdr 内では worktree の手順をエージェントコンテキストに注入する．移動操作を
  エージェントが自分で実行できるようにするため．
- `session_start` で自身のペインから `old_pane_id` トークンを読み，対象エージェントの
  起動が落ち着くまで待ち，ワークスペースの最後のペインでもユーザー作成ペインでも
  なければ旧ペインを閉じてトークンを消す．フォーク後の旧ペインを自動で整理するため．
- 旧ペインはフォーク前にトークンを報告する．新しいセッションが起動時に読めるようにするため．
- `configs/home/pi/agent/AGENTS.md` には worktree ツールの指示を置かない．
  環境固有の手順を拡張側に集約するため．

### セッション名とボーダーラベル

- `configs/home/pi/agent/extensions/session-namer.ts` は長いセッション名と短い
  ボーダーラベルを別に尋ねる．タイトルとボーダー表示で必要な情報が異なるため．
- 長い名前は `pi.setSessionName()` に渡し，短いラベルは
  `herdr pane report-metadata "$HERDR_PANE_ID" --source herdr:pi-short-title --agent pi --title <label>`
  で報告する．両者を別の表示先に出すため．
- ラベルは既定では英語 1 語とし，命名時に `herdr pane list` を見て他のウィンドウと
  衝突するときだけ 2 語にする．ボーダー上で区別できるようにするため．
- Herdr 外ではラベルを設定しない．ボーダー以外にラベルを出す先がないため．
- サブエージェントは `herdr agent start` の `--` 以降で `pi --name <Role>` として起動する．
  session-namer が既存の名前を上書きしないため，役割名を保持できる．
- ユーザーが作成したウィンドウのタイトルは実行中のプログラムから導出したままにする．
  Herdr の既存の挙動を変えないため．
- 1 ウィンドウ 1 Pi ペインはエージェント側の慣習とし，強制しない．ユーザー作成
  ウィンドウの自由度を残すため．

### クリーンアップと設定の適用

- クリーンアップでは `herdr pane list --workspace <id>` を確認し，実行中のプログラムが
  あるユーザーウィンドウを閉じる前に尋ねる．意図しない作業を失わないため．
- 削除は `herdr worktree remove --workspace <id>` を使い，`--force` はユーザーが
  同意した後にだけ使う．
- store-backed link で提供されているファイルへの変更は `home-switch` で適用する．
  `.pi/settings.json` はローカルの可変ファイルなので直接編集する．

## 対象外

- 設計に挙げた変更以外の Pi 拡張，Herdr プラグイン，worktree hooks
- keel と sail のスキル文書の変更
- `pi-agent-teleport` への移行
- 1 ウィンドウ 1 Pi ペインの自動強制と，プログラム名からのタイトル自動生成
- クリーンアップの自動検出と確認 UI
- `~/vault/fragments/software/herdr-pi-workflow.md` と既存 vault ノートの編集

## 受け入れ条件

- `herdr worktree create` が作った worktree が Herdr のワークスペースとして追従し，
  ペイン状態と会話が移動先を指す
  - [ ] 手動: Herdr で `herdr worktree create` から worktree を作り，`herdr workspace list` と
        `herdr pane list` を確認する．worktree ワークスペースの `worktree.repo_key` がルートと
        同じで `is_linked_worktree: true` になる．Pi ペインの `cwd` がその worktree のパスで，
        `agent_session` がフォーク後のセッションを指す．移動前に決めたタイトルを
        エージェントに尋ね，同じ答えが返る
  - [ ] 手動: `herdr worktree create` の後，`local.worktree-hooks` プラグインが新しい
        checkout で共有 post-start hooks を実行する
  - [ ] 手動: 新しい root pane で `--fork <current session>` とユーザーの依頼を初期
        プロンプトにして Pi を起動する．拡張がチャット上の指示なしに旧ペインを閉じる
- session-namer が長いセッション名と短いラベルを分けて出し，短いラベルが Herdr の
  ボーダーに表示される
  - [ ] 手動: 同じ Herdr セッションで話題の異なる Pi セッションを 2 つ始める．
        `herdr pane list` の terminal title は長いセッション名のままで，各ペインの
        ボーダーに 1 語のラベルが出る．次に自然な 1 語ラベルが既存ウィンドウと
        一致する話題で 3 つ目を始めると，ボーダーラベルが 2 語になる
    - 長いタイトルと別の 1 語ラベルを確認: `Create herdr-follow-test worktree`/`worktree`，
      `Fix CJK font weight regression`/`review`，`Compare terminal markdown viewers` が
      `compare` と `comparison`
- pi-worktrunk が設定から消え，新しい拡張が Herdr 専用になっている
  - [x] `rg -n 'HERDR_ENV' configs/home/pi/agent/extensions/herdr-worktree.ts` -- ガードがある
  - [x] `rg -n 'pi-worktrunk' configs/home/pi/default.nix .pi/settings.json` -- 出力なし
  - [x] `configs/home/pi/agent/AGENTS.md` を読む -- worktree ツールの指示なし
    - print mode で `HERDR_ENV=1` のとき `<project_instructions path="herdr-worktree">` が
      グローバル AGENTS.md と `./AGENTS.md` の間に挿入され，`HERDR_ENV` 未設定では
      現れなかった
- サブエージェントのセッション名が役割名になる
  - [ ] 手動: `herdr agent start reviewer --kind pi --pane <pane_id> -- --name Review` で
        起動する．`herdr pane list` の terminal title が `π - Review - <repo>` になり，
        session-namer が上書きしない
- worktree のクリーンアップで，ユーザーウィンドウを閉じる前に確認を求める
  - [ ] 手動: worktree ワークスペースで `top` を実行するユーザーペインを作り，
        クリーンアップを依頼する．閉じる前に質問が出て，拒否すると
        ワークスペースが残る
- 整形と差分チェックを通る
  - [x] `nix fmt` の後に `git diff --check` -- 出力なし，終了コード 0
    - `nix fmt` は 2 回とも 0 files changed，`git diff --check` は 2 回とも
      終了コード 0

## 停止条件

- `herdr worktree create` が 2 回失敗する，worktree メタデータが返らない，
  `worktree.created` プラグインが共有 post-start hooks を実行しなかった場合は，
  新しい worktree で Pi を起動する前に停止し，`herdr workspace create` に
  フォールバックしない
- session-namer のモデル応答に長い名前か短いラベルが欠けたら，長い名前のみの
  挙動に戻し，再試行は最大 1 回とする
- ユーザーがクリーンアップの質問に答えない場合は停止し，ワークスペースを残す
- 新しいセッションの開始時にハンドオフトークンが欠けていたら，旧ペインを
  開けたまま報告する
- 必要な変更が `configs/home/pi/agent/AGENTS.md`，
  `configs/home/pi/agent/extensions/session-namer.ts`，
  `configs/home/pi/agent/extensions/herdr-worktree.ts`，
  `configs/home/pi/default.nix`，`.pi/settings.json` の外に及ぶ場合は停止する
