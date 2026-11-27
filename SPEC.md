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
  root pane の ID を得る．worktree 作成時は空の root pane ができるため．
- main へ戻るときは worktree メタデータから workspace ID を得て，その
  workspace に新しい tab を作り，その root pane を使う．
  既存 root pane が agent に占有されていても起動できるようにするため．
- fork と新セッション起動は `local.worktree-handoff` プラグインの action が
  担当する．tool はプラグインへ依頼して先に result を返すことで，
  旧セッションが toolResult を書き込んでから fork させる．
- tool は `--fork` に初期プロンプトを渡さない．fork 先は flag を見て
  非表示の continuation message で移動完了を通知する．その文は，移動は
  完了済みで別の移動操作をせず，移動だけが依頼なら完了を報告し，
  他に残りの作業があれば続けることを明示する．
  確認のための追加コマンドは安全側の挙動として許容する．
- tool の成功 result は `terminate: true` を返し，移動元で自動の
  follow-up turn を起こさない．
- `common.ts` の `renderMoveResult` を `index.ts` の tool と `handoff.ts` の
  `registerToolRenderer` resolver の両方で使う．移動先は tool を登録しない
  ため，renderer だけを未登録 tool に渡して compact 表示を保つため．
  折りたたみ時の本文は空にする（header のツール名で十分）．失敗時は error
  の一行を残す．展開時は組込みツールと同じく details の JSON をそのまま
  出さず，destination や pane ID をラベル付きの短い行で整形する．
  details 自体は structured なまま
  toolResult に残し，エージェントが使う情報は保持するため．
- tool は既に target worktree の cwd なら何もしない．
  フォーク先が再ハンドオフしないため．
- main 復帰時に旧 worktree workspace を閉じる処理は fork 先に委ねる．
  tool が先に閉じると fork 先が旧 session file の場所を読めなくなるため．
- `local.worktree-hooks` プラグインは `worktree.created` で
  共有 post-start hooks を実行する．新しい checkout でも既存の初期化を
  欠かさないため．`worktree-hooks.nix` は main の純粋な hook だけの
  状態に戻す．Worktrunk の共通初期化と Pi 固有の引き継ぎは別の plugin に
  分けるのが妥当だったため．
- `configs/home/herdr/worktree-handoff.nix` が `local.worktree-handoff`
  プラグインを登録し，handoff action と job 実行 script を持つ．
  tool はその plugin state dir に job JSON を書いてから action を invoke し，
  action は未処理の job を順に読んで `herdr agent start ... --fork` と
  フォーカス移動を実行する．`plugin action invoke` は command の完了を
  待たないため，tool はすぐ result を返せる．
- herdr-worktree は常に読み込む `index.ts` と，移動先だけが `-e` で
  読み込む `handoff.ts` に分ける．移動先の後始末はフォーク先だけが持つため．
- 両方が使う定数，型，Herdr コマンド実行，`<herdr>` の登録は `common.ts`
  に置いて import する．同じ手順を一箇所に保つため．
- tool は job JSON に `-e <extension dir>/handoff.ts` を入れ，plugin action
  は常にその引数を `herdr agent start` に渡す．installed 版の移動先にも
  handoff entry を読み込ませるため．

### ハンドオフ

- tool は `herdr-worktree-handoff` の string flag に旧ペイン ID を値として
  渡し，flag の登録は `handoff.ts` が行う．flag が必要なのはフォーク先だけ
  で，2 つの extension が同じ flag を登録すると Pi が衝突を報告するため．
- `session_start` で flag の値から旧ペイン ID を読み，値が無ければ何もしない．
  一般の fork と通常セッションを巻き込まないため．
- fork 先は toolResult の修復を行わない．tool が先に完了するため，
  コピーされた session には toolResult が含まれている．
- `agent start` の後，移動先 pane を `herdr agent focus` でフォーカスする．
  ユーザーが移動先の画面に移れるようにするため．
- 旧ペインがまだある間に旧 session file の場所を読み，
  対象エージェントの起動が落ち着くまで待つ．
- 旧ペインを `herdr pane close` で閉じ，その後で旧 session file を
  削除する．セッションファイルが乱立しないようにするため．
- 旧 workspace が main checkout で，旧ペインがその workspace の最後の
  pane 場合，先に空の tab を作る．worktree group の最後の pane を閉じる
  と Herdr が確認を要求するため．
- 旧 workspace に別の pane が残っている場合は tab を作らず，旧ペインだけ
  を閉じる．
- main 復帰では旧ペインを閉じた後，旧 worktree workspace を
  `herdr workspace close` で閉じる．checkout と branch は残す．
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
- main へ戻る際の workspace 終了は fork 先が行い，checkout と branch は残す．

### テスト

- 検証用のペインは，実装している Pi と同じタブに作らない．
  作業画面と検証画面が混ざらないようにするため．
- 検証は一度に 1 つだけ実行する．失敗の原因が混ざらないようにするため．
- 開発中の Pi は `pi --no-extensions` で起動し，`-e` には
  `~/.pi/agent/extensions/herdr-agent-state.ts` と
  `configs/home/pi/agent/extensions/herdr-worktree/index.ts` だけを指定する．
  installed 版との二重登録を避けるため．
- herdr-worktree のパスは Extension 自身の `import.meta.url` から取り，
  プラグインの action が起動する Pi には `handoff.ts` の `-e` を渡す．
  開発中は `--no-extensions` と herdr-agent-state の `-e` も渡し，
  installed 版では `handoff.ts` だけを渡す．
- 開発中の反復はこの起動引数を使う．

## 対象外

- 設計に挙げた変更以外の Pi 拡張，Herdr プラグイン，worktree hooks
  （plugin job 方式のため `configs/home/herdr/worktree-handoff.nix` の追加と
  `configs/home/herdr/worktree-hooks.nix` の main への復元は設計範囲に含める）
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
  - [x] tool が成功表示（緑）になる
    - plugin 分離後の scratch E2E で toolResult が `isError: false` の
      created summary と `w25:p1` への fork を表示（07:29）
  - [x] 移動元に余計なターンが無い
    - フォーク先 transcript が `USER → herdr_worktree_move → custom
      continuation → 応答` の順で，tool の直後に移動元の応答はなし
  - [x] 移動先 pane にフォーカスが移る
    - Herdr で `w25:p1` が `focused: true`．Niri の前面は Steam のままで，
      compositor 側の遷移は此次では観測していない
  - [x] Herdr 内の Pi に「新しい worktree で作業して」とだけ伝える．
        tool 呼び出しが記録され，
        `herdr worktree list` に linked worktree が現れ，
        `herdr pane list` の `cwd` と `agent_session` が移動先を指す
    - `herdr_worktree_move` の呼び出しは 1 回だけ（引数 `branch:
      e2e-split`）．`w25:p1` の cwd と session file が移動先を指す
  - [x] `herdr worktree create` の後，`local.worktree-hooks` プラグインが
        新しい checkout で共有 post-start hooks を実行する
    - `.envrc` と `.pi/settings.json` の copy と，
      `.pre-commit-config.yaml` の symlink を確認
  - [x] フォーク先が非表示 continuation で移動完了を認識し，元の作業を
        続けて再ハンドオフしない
    - scratch transcript に `customType: herdr-worktree-handoff`,
      `display: false`（07:29:51.472Z）．追加 tool 呼び出しは 0 回で，
      応答は `Worktree move to branch e2e-split is done.` のみ
  - [x] 旧ペインがチャット指示なしに閉じる
    - 旧ペイン `w24:p1` が消え，main checkout に空 pane `w24:p2` が残る
  - [x] 旧 session file が削除され，`herdr agent list` に旧セッションが残らない
    - 旧 `w24:p1` の `.jsonl` は存在せず，`herdr agent list` に旧 session なし
  - [x] main checkout の最後の pane から移動すると，空 tab が作られ，
        旧 pane と旧 session file が消える
    - `w24:p1` が閉じ，`w24:p2` の空 shell が残った（上記 E2E）
  - [x] main checkout に別 pane が残っている場合は空 tab を作らず，
        旧 pane と旧 session file だけが消える
    - `w1G:p2` が残る状態で `w1G:p3` から移動し，tab は増えず，
      `panes 1 / tabs 1` を維持．旧 `.jsonl` は消えた
- main 復帰時は workspace に新しい tab が作られ，その root pane で fork が
  起動する
  - [x] 既存 root pane が agent に占有されていても `agent_pane_busy` と
        ならず，新しい tab の root pane でセッションが続くことを確認する
    - `w1A:t1` を agent が占有した状態で main 復帰し，`w1A:t2` / `w1A:p4`
      でセッションが継続．旧 workspace `w1C` は消えた
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
      （`w1B:p1` の transcript で確認）
- 旧ペイン ID が flag で渡り，一般 fork には flag が無い
  - [x] ハンドオフ先の起動引数に `herdr-worktree-handoff` があり，
        その値が旧ペイン ID であることを確認する
    - 2 ペイン構成の実セッションで旧ペイン `w11:p2` が実際に閉じたことを
      もって確認．argv 自体は読んでいない
  - [x] 一般の `pi --fork` では flag が無く，旧ペインが閉じられないことを
        確認する
    - `herdr agent start ... --fork <session>` の argv に flag が無く，
      元の pane `w19:p3` は残り，`herdr worktree list` も 1 件のまま
- pi-worktrunk が消え，Herdr 用の拡張と plugin が分かれている
  - [x] `rg -n 'HERDR_ENV' configs/home/pi/agent/extensions/herdr-worktree/index.ts` --
        ガードがある
  - [x] `rg -n 'pi-worktrunk' configs/home/pi/default.nix .pi/settings.json` --
        出力なし
  - [x] `configs/home/pi/agent/AGENTS.md` を読む -- worktree ツールの指示なし
  - [x] print mode で `HERDR_ENV=1` のとき，
        `herdr_worktree_move` の promptSnippet と `<herdr>` が表示される
    - `<tools>` に `herdr_worktree_move: Move the current work between the
      main checkout and Git worktrees in Herdr`，`<herdr>` に Herdr の告知を確認
  - [x] `index.ts` に tool と `<herdr>` の登録があり，handoff 処理は
        `handoff.ts` にある
    - `session_start` と `finishHandoff` は `handoff.ts` にのみ存在
  - [x] `common.ts` に定数，型，`createHerdr`，`samePath`，`textResult`，
        `sleep`，`registerHerdrNotice`，`handoffArgs` があり，両 entry が import
  - [x] `handoffArgs()` が `-e <extension dir>/handoff.ts` を渡し，
        plugin script が開発モードに関わらず展開する
    - 実行値は `["--no-extensions","-e",.../herdr-agent-state.ts,"-e",.../handoff.ts]`
      で，`jq -r '.extraArgs // [] | .[]'` を生成 script で確認
  - [x] `handoff.ts` 単独の print mode では flag が読め，tool は出ない
    - `herdr_worktree_move` は 0 回，`<herdr>` は 1 回．
      `--herdr-worktree-handoff zzzzz:p99` が unknown option にならず exit 0
  - [x] `worktree-hooks.nix` が main と一致し，handoff action と script が
        無いことを読んで確認
    - `git diff --exit-code main -- configs/home/herdr/worktree-hooks.nix` は
      差分なし．`nix eval` の manifest は `[[events]]` の
      `on = "worktree.created"` のみ
  - [x] `worktree-handoff.nix` が plugin id `local.worktree-handoff` を宣言し，
        `configs/home/herdr/default.nix` が import することを `nix eval` で確認
    - manifest は `id = "local.worktree-handoff"` と `[[actions]]` の
      `id = "handoff"`．`herdr plugin list` に両 plugin が enabled
  - [x] tool が `local.worktree-handoff` の state dir と action を使うことを
        読んで確認
    - `common.ts` の `HANDOFF_PLUGIN` が `local.worktree-handoff` で，
      `index.ts` がその state dir へ job を書き，同名 plugin の action を invoke
  - [x] scratch repo の E2E で plugin 分離後も作成・フォーク・ハンドオフが
        従来どおり動くことを確認
    - `/tmp/herdr-e2e-plugin` の `w24:p1` から `branch: e2e-split` を呼び，
      `w25:p1` でフォーク．両 repo の `git status` は空で実作業なし．
      `herdr worktree remove --workspace w25` と `herdr workspace close w24`
      が成功し，focus は `wG` / window 2 に復元，通知 0 件
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
    - `w1A:t2` / `w1A:p4` で cwd `/tmp/herdr-handoff-final` のフォークが
      起動し，旧 workspace `w1C` は消えた
  - [x] `herdr worktree list` には worktree が残り，
        ユーザーが `wt remove` を選べる状態になっている
    - `pi-worktree-mwxppuxx` は `open_workspace_id: null` で残存

- tool 結果が移動元と移動先の両方で短く，エージェントには情報を保つ
  - [ ] TUI で tool 実行後の collapsed 本文が空で，header のツール名だけが
        出ることを確認
    - 旧表示では header と本文の両方に `herdr_worktree_move` が出ていた
      （`Pictures/Screenshots/Screenshot from 2026-11-27 16-43-37.png`）．
      共有 renderer を空本文にして移動元・移動先を再確認する
  - [x] expand すると JSON の波括弧ではなくラベル付きの行で destination と
        pane ID が読めることを確認
    - 両 pane の `herdr pane read` で `destination: /tmp/herdr-e2e-render.e2e-render`
      と `pane: w27:p1`，wrapper 側は `destination: /tmp/e2e-display-check`
      と `pane: w99:p1` を確認．波括弧なし（expand 後の Niri スクショは
      別ウィンドウが前面だったため Herdr の pane 出力を証拠にした）
  - [x] フォーク先 transcript の toolResult が content と structured な
        details を従来どおり持つことを読んで確認
    - execute は無変更で，renderer は表示のみ．最新 E2E で toolResult の
      content 141 文字と details の 8 キー，tool 呼び出し 1 回を確認
  - [x] テスト用 workspace を片付け，フォーカスを戻す
    - `herdr worktree remove --workspace w27` と `herdr workspace close w26/w28`
      が成功．workspace は 3 件，Niri focused window 2 と Herdr workspace
      `wG` が一致，通知 0 件

## 停止条件

- `herdr worktree create` が 2 回失敗する，worktree メタデータが返らない，
  `worktree.created` プラグインが共有 post-start hooks を
  実行しなかった場合は，新しい worktree で Pi を起動する前に停止し，
  `herdr workspace create` にフォールバックしない
- 新しいセッションの開始時にハンドオフ flag の値が空，または既存の
  ペイン ID として読めない場合は，旧ペインを開けたまま報告する．
  flag が無い一般 fork は対象外とする
- 必要な変更が `configs/home/pi/agent/AGENTS.md`，
  `configs/home/pi/agent/extensions/herdr-worktree/index.ts`，`handoff.ts`，
  `common.ts`，`configs/home/pi/default.nix`，`.pi/settings.json`，
  `configs/home/herdr/worktree-hooks.nix`，`configs/home/herdr/worktree-handoff.nix`，
  `configs/home/herdr/default.nix` の外に及ぶ場合は停止する
