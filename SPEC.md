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
- 同じ extension が `herdr_worktree_move` tool を登録する．
  自然文の依頼をモデルがコマンドへ変換せず，tool が手順を持つため．
- tool は `promptSnippet` と `promptGuidelines` で，worktree の依頼に
  応じて呼ばれることを 1 行だけモデルに伝える．
  長い手順を context に注入しないため．
- extension は `before_agent_start` の `sections` に `<herdr>` を足し，
  Herdr 内で動いていることを静的に告知する．
  毎回の環境確認をモデルに任せないため．
- tool は対象を branch または path から解決し，既存なら open，
  無ければ main を base に create する．重複を作らないため．
  main も worktree list の通常のエントリとして扱い，
  `branch: "main"` で main checkout へ戻る．
  direction のような追加引数を持たないため，Worktrunk と同じ対称性になる．
- tool は現在の workspace メタデータから repo_root を取り，
  移動先の解決と Herdr コマンドの cwd に使う．
  `wt merge` で worktree が削除された後も cwd が消えているため．
- tool は `worktree open` / `worktree create` の応答から workspace と
  root pane の ID を得て，旧ペインを動かさずその root pane でセッションを
  フォークする．worktree 作成時は空の root pane ができるため．
- main へ戻るときは worktree メタデータから workspace ID を得て，その
  workspace に新しい tab を作り，その root pane でセッションをフォークする．
  既存 root pane が agent に占有されていても起動できるようにするため．
- tool は `before_agent_start` で保持したユーザー要求を `--fork` の
  初期プロンプトとして渡す．要求の再入力をモデルに任せないため．
- tool は既に target worktree の cwd なら何もしない．
  フォーク先が再ハンドオフしないため．
- tool は main へのフォーク後，旧 worktree workspace を
  `herdr workspace close` で閉じる．checkout は残し，
  `wt` での削除タイミングをユーザーに残すため．
- `local.worktree-hooks` プラグインは `worktree.created` で
  共有 post-start hooks を実行する．
  新しい checkout でも既存の初期化を欠かさないため．

### ハンドオフ

- tool は `herdr-worktree-handoff` の string flag を登録し，フォーク先の
  起動引数に旧ペイン ID を値として渡す．
  一般の fork と区別し，Herdr の metadata に依存せず ID を届けるため．
- `session_start` で flag の値から旧ペイン ID を読み，値が無ければ何もしない．
  一般の fork と通常セッションを巻き込まないため．
- 得た旧ペイン ID について，対象エージェントの起動が落ち着くまで待ち，
  ワークスペースの最後のペインでもユーザー作成ペインでも
  なければ旧ペインを閉じる．
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

### クリーンアップ

- 明示的な削除は `herdr worktree remove --workspace <id>` を使い，
  `--force` はユーザーが同意した後にだけ使う．
- main へ戻る際の workspace 終了は `herdr workspace close` とし，
  checkout と branch は残す．

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
  通常の
  `herdr agent start ... -- --herdr-worktree-handoff <old_pane_id> -a --fork <session> "<request>"`
  に戻す．
- 開発中の反復はこの起動引数を使う．

## 対象外

- 設計に挙げた変更以外の Pi 拡張，Herdr プラグイン，worktree hooks
- keel と sail のスキル文書の変更
- `configs/home/pi/agent/extensions/session-namer.ts` の変更と，
  セッション名・ボーダーラベルの検証
- `pi-agent-teleport` への移行
- `workflow.md` のような worktree 手順のコンテキスト注入
- 1 ウィンドウ 1 Pi ペインの自動強制と，プログラム名からのタイトル自動生成
- クリーンアップの自動検出と確認 UI
- 実行中のユーザーペインを閉じる前の確認（今後の課題）
- `wt merge` 自体の実行
- `~/vault/fragments/software/herdr-pi-workflow.md` と既存 vault ノートの編集

## 受け入れ条件

- `herdr_worktree_move` tool が自然文の依頼で呼ばれ，
  worktree の作成・フォーク・ハンドオフが終わる
  - [x] Herdr 内の Pi に「新しい worktree で作業して」とだけ伝える．
        tool 呼び出しが記録され，
        `herdr worktree list` に linked worktree が現れ，
        `herdr pane list` の `cwd` と `agent_session` が移動先を指す
    - 改名前の dev 検証で引数なしの tool 呼び出しを確認．
      `pi-worktree-mwxc69zh` が linked worktree として現れ，`wQ:p1` の
      `cwd` と `agent_session` が移動先を指した
  - [x] `herdr worktree create` の後，`local.worktree-hooks` プラグインが
        新しい checkout で共有 post-start hooks を実行する
    - `.envrc` と `.pi/settings.json` の copy と，
      `.pre-commit-config.yaml` の symlink を確認
  - [x] 1 つ目のセッションで，フォーク先がユーザー要求を初期プロンプトとして
        持ち，旧ペインがチャット指示なしに閉じる
    - フォーク先の先頭 user message が「新しい worktree で作業して」．
      旧ペイン `wG:pP` は `pane_not_found` で，チャット指示は出していない
- main 復帰時は workspace に新しい tab が作られ，その root pane で fork が
  起動する
  - [x] 既存 root pane が agent に占有されていても `agent_pane_busy` と
        ならず，新しい tab の root pane でセッションが続くことを確認する
    - scratch repo で `w16:p1` を agent が占有した状態で main 復帰し，
      `w16:t2` / `w16:p3` でセッションが継続．旧 workspace `w17` は消えた
- tool は既存 worktree を重複なく開き，フォーク先では再ハンドオフしない
  - [x] `herdr worktree create --branch existing-check --base main --no-focus`
        で worktree を用意した後，Pi に
        「`existing-check` の worktree で作業して」と伝える．
        `herdr worktree list` の数が増えず，既存 workspace の
        root pane で作業が続く
    - `--cwd /home/hasundue/dotnix` を付けて作成．前後とも 3 件で，`wT:p1`
      でフォークが継続
  - [x] 同じフォーク先の transcript を読み，`herdr_worktree_move` が
        1 回だけ呼ばれていることを確認する
    - 旧セッションで 1 回実行し，フォーク先では新規呼び出しなし
- 旧ペイン ID が flag で渡り，一般 fork には flag が無い
  - [x] ハンドオフ先の起動引数に `herdr-worktree-handoff` があり，
        その値が旧ペイン ID であることを確認する
    - 2 ペイン構成の実セッションで旧ペイン `w11:p2` が実際に閉じたことを
      もって確認．argv 自体は読んでいない
  - [x] 一般の `pi --fork` では flag が無く，旧ペインが閉じられないことを
        確認する
    - `herdr agent start ... --fork <session>` の argv に flag が無く，
      元の pane `w19:p3` は残り，`herdr worktree list` も 1 件のまま
- pi-worktrunk が設定から消え，新しい拡張が Herdr 専用になっている
  - [x] `rg -n 'HERDR_ENV' configs/home/pi/agent/extensions/herdr-worktree/index.ts` --
        ガードがある
  - [x] `rg -n 'pi-worktrunk' configs/home/pi/default.nix .pi/settings.json` --
        出力なし
  - [x] `configs/home/pi/agent/AGENTS.md` を読む -- worktree ツールの指示なし
  - [x] print mode で `HERDR_ENV=1` のとき，
        `herdr_worktree_move` の promptSnippet が表示される
    - `<tools>` に `herdr_worktree_move: Move the current work between the
      main checkout and Git worktrees in Herdr` を確認
  - [x] print mode で `<herdr>` セクションが表示される
    - `You are running inside Herdr, a terminal multiplexer designed for
      coding agents, which manages workspaces, tabs, panes, and agent status.`
      を確認
- サブエージェントのセッション名が役割名になる
  - [x] `herdr agent start reviewer --kind pi --pane <pane_id> -- --name Review`
        で起動し，`herdr agent prompt reviewer "Hi."`
        を送る．`herdr pane list` の terminal title が
        `π - Review - <repo>` になる
    - terminal title は `π - Review - dotnix`
- tool は main checkout へ戻り，旧 Herdr workspace を閉じる
  - [x] linked worktree の Pi に「main に戻って」と伝える．
        `herdr_worktree_move` が `branch: "main"` で呼ばれ，
        main workspace に作った新しい tab の root pane でセッションが続き，
        旧 worktree workspace が `herdr workspace list` から消える
    - `wK:p1` で cwd `/home/hasundue/dotnix` のフォークが起動し，`wZ` は消えた
      のは旧設計の検証で，新設計では再検証が必要
  - [x] `herdr worktree list` には worktree が残り，
        ユーザーが `wt remove` を選べる状態になっている
    - `return-check3` は `open_workspace_id: null` で残存

## 停止条件

- `herdr worktree create` が 2 回失敗する，worktree メタデータが返らない，
  `worktree.created` プラグインが共有 post-start hooks を
  実行しなかった場合は，新しい worktree で Pi を起動する前に停止し，
  `herdr workspace create` にフォールバックしない
- 新しいセッションの開始時にハンドオフ flag の値が空，または既存の
  ペイン ID として読めない場合は，旧ペインを開けたまま報告する．
  flag が無い一般 fork は対象外とする
- 必要な変更が `configs/home/pi/agent/AGENTS.md`，
  `configs/home/pi/agent/extensions/herdr-worktree/index.ts`，
  `configs/home/pi/default.nix`，`.pi/settings.json` の外に及ぶ場合は停止する
