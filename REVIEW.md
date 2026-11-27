# Review: Herdr worktree handoff

## 対象と結論

- 対象は `main...HEAD` の実装差分と `SPEC.md`．
- handoff cleanup・queue 失敗報告・hook 相関・relative path の修正と再検証は
  完了した．merge 前の `pi-worktrunk` cleanup も完了し，残る指摘はない．

## 実装・再検証

### handoff cleanup

- main 復帰を workspace ID の比較ではなく，移動元と移動先の worktree metadata
  から判定するようにした．
- source pane の close 失敗時は旧 session file と workspace を残すようにした．
- main 復帰で旧 workspace が残っている場合は，明示的に `workspace close` する．
- single-pane の scratch E2E では，旧 workspace `w20` が閉じ，main の
  `w2Z:t2` / `w2Z:p2` で fork が続いた．旧 session file は削除され，linked
  worktree は残った．
- multi-pane の scratch E2E では，旧 workspace `w33` と残った pane が閉じ，
  `w32:t2` / `w32:p2` で fork が続いた．linked worktree は
  `open_workspace_id: null` で残った．
- main → worktree の scratch E2E では，main workspace `w35` と空 pane
  `w35:p2` が残り，linked workspace `w36:p1` で fork が続いた．
- mock で `pane close` を失敗させ，旧 session file の存在，警告の出力，後続の
  workspace close が無いことを確認した．
- mock で移動先 `workspace get` を失敗させ，旧 session file の存在，警告の出力，
  pane close と workspace close が実行されないことを確認した．

### 既存 worktree と queue 失敗報告

- 既存 workspace が開いている worktree へ移動する場合は，新規 tab と root pane
  を作るようにした．fresh workspace と worktree create は元の root pane を使う．
- 既存 root pane `w38:p1` を Pi で占有した E2E では，tab 数が 2 になり，元の
  agent は残り，新規 `w38:t2` / `w38:p2` で fork が続いた．
- tool の成功文を queue 受付に変更し，source session file の存在と destination
  pane の agent 占有を queue 前に確認するようにした．E2E toolResult は
  `Queued the handoff to pane w38:p2.` だった．
- plugin action は job を `agent start` 成功まで `.running` で保持し，失敗時は
  `.failed` と error を残すようにした．
- 一時 plugin の失敗 E2E では，`agent_pane_busy` と plugin log failed を確認．
  通知は shown，source workspace `w39` に focus，source session は残った．
  2 回目の invoke は succeeded し，failed job は replay されなかった．
- 生成 script の成功 E2E では，plugin log succeeded と job file なしを確認．
  source pane・session は削除され，destination で fork した．
- renderer 単体テストで collapsed は空，expanded は queue 文 1 行，color は
  `muted` のみだった．

### hook 相関と relative path

- shared hook の成功後に，checkout path を含む JSON marker を stdout の最終行へ
  出力するようにした．生成 script の実出力と `.pi/settings.json` の copy を確認
  した．
- tool は success log の marker path が作成先と一致することを確認する．
  tool mock で別 checkout の marker を返すと error になり，plugin action invoke
  は実行されなかった．
- relative path を repoRoot 取得後に解決し，検索と create で共有するようにした．
  tool mock で cwd `/repo/sub`，path `worktrees/foo` が `/repo/worktrees/foo` に
  解決された．
- 既存 worktree E2E では worktree 数が増えず，既存 workspace の新規 tab で
  fork が続いた．

### 開発モード判定

- `IS_DEV_EXTENSION` を path 名の部分一致から `HERDR_WORKTREE_DEV=1` の明示的な
  環境変数判定へ変更した．
- 未設定時は `handoff.ts` だけ，設定時は `--no-extensions` と
  `herdr-agent-state.ts` と `handoff.ts` を渡すことを単体テストで確認した．
- 開発 Pi に環境変数を設定した実 E2E でも，worktree create と fork が継続した．

## 残る指摘

なし．user・primary checkout・現在の worktree の settings から `pi-worktrunk`
を削除し，`pi list` にも残っていないことを確認した．

## 検証

- `nix fmt` と `git diff --check` は clean．
- `handoff.ts` の `--herdr-worktree-handoff` 登録を確認．
- single-pane，multi-pane，main → worktree，既存 worktree の実セッション E2E を
  再実行した．
- close 失敗と metadata 失敗は mock で再検証した．
- plugin action の成功・失敗 path と renderer は実 E2E または単体テストで再検証
  した．
- hook marker・別 checkout log の棄却・relative path は実 E2E または単体テストで
  再検証した．
