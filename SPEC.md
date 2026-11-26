---
status: agreed
---

# Herdr のワークスペースを worktree の移動に追従させる

## 問題

Herdr 内の Pi セッションが worktree へ移動しても，
Herdr のワークスペースとペイン配置が追従しない．
worktree の場所がワークスペースに表示されず，
ステータス集計，ペイン移動，クリーンアップが使われないままになる．

## 設計

### worktree の移動

- Herdr のみを対応対象とし，worktree の作成と削除は Herdr の API を使う．
  Worktrunk の directory directive はセッションを切り替えても
  プロセスの cwd を変えないため，
  `configs/home/pi/default.nix` の pi-worktrunk 宣言と
  `.pi/settings.json` のプロジェクト有効化は削除する．
- `configs/home/pi/agent/extensions/herdr-worktree/index.ts` を追加し，
  `HERDR_ENV=1` 以外では何もしない．
  Herdr 外のセッションに Herdr 固有の手順を渡さないため．
- 同じ extension が `herdr_move_to_worktree` tool を登録する．
  自然文の依頼をモデルがコマンドへ変換せず，tool が手順を持つため．
- tool は `promptSnippet` と `promptGuidelines` で，worktree の依頼に
  応じて呼ばれることを 1 行だけモデルに伝える．
  長い手順を context に注入しないため．
- tool は対象を branch または path から解決し，既存なら open，
  無ければ main を base に create する．重複を作らないため．
- tool は workspace，tab，root pane の ID を得て，旧ペインを動かさず
  その root pane でセッションをフォークする．
  会話と cwd を移動先に保つため．
- tool は `before_agent_start` で保持したユーザー要求を `--fork` の
  初期プロンプトとして渡す．要求の再入力をモデルに任せないため．
- tool は既に target worktree の cwd なら何もしない．
  フォーク先が再ハンドオフしないため．
- `local.worktree-hooks` プラグインは `worktree.created` で
  共有 post-start hooks を実行する．
  新しい checkout でも既存の初期化を欠かさないため．

### ハンドオフ

- tool はフォーク前に `old_pane_id` トークンを root pane に報告する．
  新しいセッションが起動時に読めるようにするため．
- `session_start` で自身のペインから `old_pane_id` トークンを読み，
  対象エージェントの起動が落ち着くまで待ち，
  ワークスペースの最後のペインでもユーザー作成ペインでも
  なければ旧ペインを閉じてトークンを消す．
  フォーク後の旧ペインを自動で整理するため．
- `configs/home/pi/agent/AGENTS.md` には worktree ツールの指示を置かない．
  環境固有の手順を tool に集約するため．

### ウィンドウとサブエージェントの名前

- サブエージェントは `herdr agent start` の `--` 以降で
  `pi --name <Role>` として起動する．役割名をセッション名として
  保持するため．
- ユーザーが作成したウィンドウのタイトルは
  実行中のプログラムから導出したままにする．
  Herdr の既存の挙動を変えないため．
- 1 ウィンドウ 1 Pi ペインはエージェント側の慣習とし，強制しない．
  ユーザー作成ウィンドウの自由度を残すため．

### クリーンアップと設定の適用

- クリーンアップでは `herdr pane list --workspace <id>` を確認し，
  実行中のプログラムがあるユーザーウィンドウを閉じる前に尋ねる．
  意図しない作業を失わないため．
- 削除は `herdr worktree remove --workspace <id>` を使い，
  `--force` はユーザーが同意した後にだけ使う．
- store-backed link で提供されているファイルへの変更は
  `home-switch` で適用する．
  `.pi/settings.json` はローカルの可変ファイルなので直接編集する．

### テスト

- 検証用のペインは，実装している Pi と同じタブに作らない．
  作業画面と検証画面が混ざらないようにするため．
- 検証は一度に 1 つだけ実行する．失敗の原因が混ざらないようにするため．
- 開発中の Pi は `pi --no-extensions` で起動し，`-e` には
  `~/.pi/agent/extensions/herdr-agent-state.ts` と
  `configs/home/pi/agent/extensions/herdr-worktree/index.ts` だけを指定する．
  installed 版との二重登録を避けるため．
- herdr-worktree のパスは Extension 自身の `import.meta.url` から取り，
  フォーク先にも同じ `-e` を渡す．これは開発用の分岐で，テスト終了後は
  通常の `herdr agent start ... --fork ... -- "<request>"` に戻す．
- 開発中の反復はこの起動引数を使い，最終的な受け入れ確認は
  activation 後の通常起動で行う．

## 対象外

- 設計に挙げた変更以外の Pi 拡張，Herdr プラグイン，worktree hooks
- keel と sail のスキル文書の変更
- `configs/home/pi/agent/extensions/session-namer.ts` の変更と，
  セッション名・ボーダーラベルの検証
- `pi-agent-teleport` への移行
- `workflow.md` のような worktree 手順のコンテキスト注入
- 1 ウィンドウ 1 Pi ペインの自動強制と，プログラム名からのタイトル自動生成
- クリーンアップの自動検出と確認 UI
- `~/vault/fragments/software/herdr-pi-workflow.md` と既存 vault ノートの編集

## 受け入れ条件

- `herdr_move_to_worktree` tool が自然文の依頼で呼ばれ，
  worktree の作成・フォーク・ハンドオフが終わる
  - [ ] activation 後に起動した Herdr 内の Pi に
        「新しい worktree で作業して」とだけ伝える．tool 呼び出しが記録され，
        `herdr worktree list` に linked worktree が現れ，
        `herdr pane list` の `cwd` と `agent_session` が移動先を指す
  - [ ] `herdr worktree create` の後，`local.worktree-hooks` プラグインが
        新しい checkout で共有 post-start hooks を実行する
  - [ ] 1 つ目のセッションで，フォーク先がユーザー要求を初期プロンプトとして
        持ち，旧ペインがチャット指示なしに閉じる
- tool は既存 worktree を重複なく開き，フォーク先では再ハンドオフしない
  - [ ] `herdr worktree create --branch existing-check --base main --no-focus`
        で worktree を用意した後，Pi に
        「`existing-check` の worktree で作業して」と伝える．
        `herdr worktree list` の数が増えず，既存 workspace の
        root pane で作業が続く
  - [ ] 同じフォーク先の transcript を読み，`herdr_move_to_worktree` が
        1 回だけ呼ばれていることを確認する
- 旧ペインのトークンが新しいペインで消える
  - [ ] ハンドオフ後に `herdr pane get <new_pane_id>` を確認し，
        `tokens.old_pane_id` が無い
- pi-worktrunk が設定から消え，新しい拡張が Herdr 専用になっている
  - [x] `rg -n 'HERDR_ENV' configs/home/pi/agent/extensions/herdr-worktree/index.ts` --
        ガードがある
  - [x] `rg -n 'pi-worktrunk' configs/home/pi/default.nix .pi/settings.json` --
        出力なし
  - [x] `configs/home/pi/agent/AGENTS.md` を読む -- worktree ツールの指示なし
  - [ ] print mode で `HERDR_ENV=1` のとき，
        `herdr_move_to_worktree` の promptSnippet が表示される
- サブエージェントのセッション名が役割名になる
  - [ ] `herdr agent start reviewer --kind pi --pane <pane_id> -- --name Review`
        で起動し，`herdr agent prompt reviewer "Hi."`
        を送る．`herdr pane list` の terminal title が
        `π - Review - <repo>` になる
- worktree のクリーンアップで，ユーザーウィンドウを閉じる前に
  確認を求める
  - [ ] worktree ワークスペースで `top` を実行するユーザーペインを作り，
        Pi に「この worktree を片付けて」と伝える．
        閉じる前に質問が出て，拒否するとワークスペースが残る
- 整形と差分チェックを通る
  - [x] `nix fmt` の後に `git diff --check` -- 出力なし，終了コード 0
    - `nix fmt` は 2 回とも 0 files changed，`git diff --check` は
      2 回とも終了コード 0

## 停止条件

- `herdr worktree create` が 2 回失敗する，worktree メタデータが返らない，
  `worktree.created` プラグインが共有 post-start hooks を
  実行しなかった場合は，新しい worktree で Pi を起動する前に停止し，
  `herdr workspace create` にフォールバックしない
- ユーザーがクリーンアップの質問に答えない場合は停止し，
  ワークスペースを残す
- 新しいセッションの開始時にハンドオフトークンが欠けていたら，
  旧ペインを開けたまま報告する
- 必要な変更が `configs/home/pi/agent/AGENTS.md`，
  `configs/home/pi/agent/extensions/herdr-worktree/index.ts`，
  `configs/home/pi/default.nix`，`.pi/settings.json` の外に及ぶ場合は停止する
