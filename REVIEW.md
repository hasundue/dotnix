# Review: Herdr worktree handoff

## 対象と方法

- レビュー対象は `SPEC.md` の Sail 完了時点．
  `main...HEAD` の差分のうち `configs/home/pi/default.nix` と新規の
  `configs/home/pi/agent/extensions/herdr-worktree/index.ts` を渡した．
  新規ファイルなので差分に全文が含まれる．
- 2 回の追記では変更後の差分だけを渡し，変更されていないコードは渡していない．
- モデルは `opencode-go/deepseek-v4.1-flash`，skiff セッションは
  `herdr-worktree-deepseek-review`．
- 行番号はすべて `configs/home/pi/agent/extensions/herdr-worktree/index.ts` の
  現在の作業ツリー版を指す．

## 指摘と対応

### 修正した指摘

- **#1 (defect): 起動待ち時間と client timeout の不一致**
  `herdr agent start` は `--timeout 120000` で待つのに `pi.exec` が 60 秒で切っ
  ていた．`pi.exec` を 180 秒に延長し，フォークの有無をポーリングして誤判定を
  防ぐ（`:82`, `:289`, `:303`）．旧ペイン ID の受け渡しは flag に変更したので，
  トークンの消去や TTL は存在しない．

- **#2 (defect): 起動失敗の誤成功判定と，失敗時の main workspace 終了**
  root pane に既存セッションがあっても，それが新しいセッションと誤判定され，
  main 復帰時に旧 workspace が閉じられる可能性があった．
  起動前に root pane のセッション ID を取得し，起動後も別 ID を確認してから
  旧 workspace を閉じる（`:310`, `:316`, `:380`）．

- **#3 (defect): worktree メタデータが無い場合の停止条件が未実装**
  `worktree create` の応答に worktree が無くても root pane だけ見て進んでいた．
  作成時に worktree のパスが無ければ Pi 起動前に停止する（`:262`）．
  stdout が空の場合は `{}` に変換されるため，停止理由は
  「root pane ID が無い」になるが，起動前の停止自体は行われる．

- **#4 (defect): post-start hooks の実行確認が無い**
  共有 hook が失敗しても Pi を起動していた．
  `worktree.created` の成功ログと，コピー先の `.envrc` と `.pi/settings.json`
  を
  作成した checkout で確認してから起動する（`:99`, `:262`, `:270`）．
  追記で指摘された global log の取り違えは，コピー先ファイルの確認で塞いだ．
  この repo では両ファイルが untracked かつ gitignore なので確認は有意で，
  plugin log の `finished_unix_ms` は hook script の終了後に記録される．
  plugin log 取得は 10 秒で打ち切る（`:99` 以下）．

- **#5 (defect): 旧ペイン待機が一時エラーで打ち切られ，40 秒で途中閉じしてい
  た**
  `agent get` の失敗を `undefined` としてループを抜け，
  まだ作業中のペインを閉じることがあった．閉じる試行の失敗も握り潰していた．
  60 秒の期限までポーリングし，落ち着かなければ旧ペインを開けたまま警告する
  （`:400`, `:416`）．`pane close` の失敗も警告する（`:432`）．

- **#7 (defect): 相対 path が 2 つの基準で解決されていた**
  `findTarget` と `worktree create --path` で基準が異なり，
  既存 worktree を見つけられず別の場所に作る可能性があった．
  `requestedPath` を一度だけ解決して両方で使う（`:178`, `:240`）．

- **#8 (question): main 復帰が optional フィールドの `false` に依存**
  `is_linked_worktree` が無い場合は復帰と判定されなかった．
  `!== true` に変更し，パス一致と合わせて判定する（`:192`）．

- **#12 (defect): 結果文が実際の挙動より強かった**
  単一ペイン workspace では旧ペインを閉じないのに「閉じる」と表示し，
  main の cwd で「worktree にいる」と表示していた．
  文言を実際の挙動に合わせた（`:203`, `:367`）．

- **#14 (defect): 途中失敗で作った worktree と workspace が通知されない**
  `worktree create` の後で失敗すると成果物が残るのに通知が無かった．
  作成パスを保持し，メタデータ不足・hook 失敗・セッション不足・起動失敗の
  すべてに手動 cleanup needed の文言を付ける（`:215`, `:262`, `:279`,
  `:380`）．
  自動削除は SPEC が削除タイミングをユーザーに残すため行わない．

### 追記ラウンドの指摘

- **D1 (defect): 成功時に 1 回の `pane get` で誤判定していた**
  一時エラーや session file の書き込み遅延で誤判定していた．
  `forkStarted()` は成功・失敗・不明を返し，10 秒ポーリングしてから判定する
  （`:289`, `:303`, `:341`）．
- **D2 (defect): トークン報告後，`agent start` 前に例外があるとトークンが残る**
  flag 方式ではトークン報告自体が無く，旧ペイン ID は起動引数に載るだけなので
  この状態は発生しない（`:333`）．
- **#5 (residual): 未決着の旧ペインが無報告だった**
  `session_start` の ctx 経由で警告を出し，旧ペインを開けたままにする（`:74`,
  `:441`）．
  `ctx.ui.notify` の形は installed 版の extension docs の
  `session_start` 例で確認した．
- **#4a / #4b (defect): hook ログが別 worktree のものでも通る，期限を超えて待
  つ**
  コピー先ファイルの確認を追加し，各 CLI 呼び出しを 10 秒に制限した（`:99`）．

### 設計変更で解消した指摘

- **#13 (question): トークン欠落時の報告方法**
  一般の fork を `reason: "fork"` だけで検出すると誤検知になるため，旧ペイン
  ID を `herdr-worktree-handoff` string flag の値として渡す方式に変更した．
  installed 版の pi は string flag をサポートし，`pi.getFlag()` は
  `session_start` で読める（`types.d.ts:1280-1288`）．
  flag が無いセッションは何もせず，値が既存ペインとして読めない場合だけ
  警告する（`:64`, `:76`, `:387`）．
  `SPEC.md` の設計・受け入れ条件・停止条件も同じ方式に更新済み．
- **F1 / F3 (追記): main 復帰直後の誤警告と，flag が残ることによる再実行**
  旧 workspace が既に閉じていた場合は警告せず，同じプロセスで
  `session_start` が再度起きても 1 度だけ実行する（`:63`, `:79`, `:394`）．
  fork 先に flag を渡すため extension が読み込まれないと起動引数が効かない
  点は，SPEC の開発用手順が `-e` を渡すことで解消している．

### 棄却した指摘

- **#6 (question): `-a` が SPEC に無い**
  `pi --help` で `--approve, -a` を確認．fork argv は有効なので変更しない．
- **#9 (question): `.pi/settings.json` 側の pi-worktrunk 削除が差分に無い**
  根拠は `configs/home/pi/default.nix` の設定本体で，`packages` から
  `npm:pi-worktrunk` のエントリが削除されている（diff と現在のファイルで確認）．
  `.pi/settings.json` は git 管理外の生成・コピー先で，diff には現れない．
  現在のファイルにも `pi-worktrunk` は無い（`grep -n` で確認）．
  設定上の有効化は残っていないと判断し，変更しない．
- **#10 (question): 明示削除の tool が無い**
  2 つの「削除」を分ける．

  **自動**: `main` 移動時に旧 worktree workspace を `herdr workspace close`
  で閉じるだけ．workspace 一覧からは消えるが，checkout と branch は残る
  （受け入れでは `return-check3` が `open_workspace_id: null` で残存）．

  **明示**: checkout 自体の削除は `herdr worktree remove --workspace <id>`
  で，明示的な手動操作．`--force` はユーザーが同意した後だけ．extension
  からは呼ばず，tool も登録しない．

  したがって SPEC の「明示的な削除」は自動化の対象ではなく，tool が無い
  ことは欠落ではない．workspace の終了と checkout の削除を同一視した
  指摘とは読める．SPEC が「どの場面で明示削除するか」を書いていない点は
  残るが，削除のタイミングをユーザーに残す設計とは矛盾しない．
- **#11 (question): branch だけ存在して worktree が無い場合**
  SPEC の「既存なら open」は worktree の存在を指す．branch-only の ref は
  create 対象であり，herdr のエラーはそのまま返すでよい．
  なお herdr が既存 branch をどのように扱うかは未確認．

- **Q1 / Q2 (追記の question): コピー確認が空振りする，symlink を確認していな
  い**
  `.envrc` と `.pi/settings.json` はこの repo で untracked かつ gitignore なので
  コピー確認は有意．hook script は `set -euo pipefail` で，
  plugin log は終了後の `finished_unix_ms` を記録するため，
  成功ログは symlink 処理まで含めた成功を表す．

## SPEC の「停止条件」の読み分け

`SPEC.md` の `## 停止条件` には種類の異なる 3 項目が並んでいる．

| 種別         | 項目                                                                             | 意味                                                                  |
| ------------ | -------------------------------------------------------------------------------- | --------------------------------------------------------------------- |
| ツールの挙動 | `worktree create` の失敗・メタデータ欠落・hook 未実行                            | Pi を起動せずにエラーを返すべき実行時挙動．受け入れ条件として検証する |
| ツールの挙動 | 新しいセッション開始時に flag の値が空または不正なら旧ペインを開けたまま報告する | 同上．flag 方式で実装済み                                             |
| Sail の停止  | 必要な変更が 4 ファイルの外に及ぶ場合                                            | 作業を止めてユーザーの判断を仰ぐ条件                                  |

したがって #13 は Sail を止める条件ではなく，実装すべきランタイム挙動の
問題で，flag 方式の採用によって実装した．

## 判断が必要な指摘

なし．#13 は flag 方式の採用で解消した．

## 検証

- `nix fmt` 済み，`git diff --check` は clean．
- トークン方式の修正と SPEC 更新は `aed3b6f` でコミット・push 済み．
  今回の flag 移行は未コミット．
- `HERDR_ENV=1 pi --no-extensions -e <extension> --help` で
  `--herdr-worktree-handoff <value>` が registered flag として表示されることを
  確認した．
- Herdr の実セッションでの受け入れ再検証は未実施．
  SPEC に記録された検証結果は変更していない．
