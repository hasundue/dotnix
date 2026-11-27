# Review: Herdr worktree handoff

## 対象と結論

- 対象は `main...HEAD` の実装差分と `SPEC.md`．
- handoff cleanup の修正と再検証は完了した．残る指摘は高 2 件，中 2 件．

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

## 残る指摘

### 1. 高: fork の失敗が成功扱いになる

`configs/home/herdr/worktree-handoff.nix:29-32`\
`configs/home/pi/agent/extensions/herdr-worktree/index.ts:264-276`

job を削除した後に `agent start ... || true` を実行し，focus も失敗を無視する．
そのため plugin action は exit 0 で完了し，tool は fork 失敗を知らずに
`Forked this session...` と `terminate: true` を返す．

失敗状態の保存・通知，または tool が成功を主張する条件の見直しが必要である．

### 2. 高: `pi-worktrunk` の削除が適用環境に反映しない

`configs/home/pi/default.nix:37`\
`configs/home/worktrunk/hooks.nix:18-21`

`mutableSettings = true` では，Nix 側から宣言を削除しても既存の動的
package entry は残る．現在の `~/.pi/agent/settings.json:31` にも
`npm:pi-worktrunk` が残っている．

さらに primary checkout の `~/dotnix/.pi/settings.json:8-11` は
`+worktrunk.ts` を有効化しており，新規 worktree で project settings が
存在しない場合は hook がコピーする．SPEC の削除条件と，新規 worktree での
無効化を満たしていない．

現在の user・primary settings は確認したが，fresh worktree へのコピーは
再実行していない．新規 worktree で `pi-worktrunk` が無効であることを再検証する．

### 3. 中: hook 成功判定が別 worktree の log を拾う

`configs/home/pi/agent/extensions/herdr-worktree/index.ts:56-66`

plugin log は global で checkout を識別せず，ファイル存在確認も既存ファイルで
成立する．別の worktree で同時に成功した hook と，tracked な `.envrc` または
`.pi/settings.json` の存在で，現在の checkout の hook 未実行を見逃せる．

event と checkout を結び付けるか，checkout 固有の完了 marker を確認する
必要がある．

### 4. 中: relative path の解決基準が SPEC と異なる

`configs/home/pi/agent/extensions/herdr-worktree/index.ts:129`

`params.path` を `repoRoot` 取得前に `ctx.cwd` から解決している．
SPEC では `repo_root` を解決基準とし，削除済み cwd でも動作する必要がある．
`repoRoot` 取得後に `resolve(repoRoot, ...)` へ変更する必要がある．

## 検証

- `nix fmt` と `git diff --check` は clean．
- `handoff.ts` の `--herdr-worktree-handoff` 登録を確認．
- single-pane，multi-pane，main → worktree の実セッション E2E を再実行した．
- close 失敗と metadata 失敗は mock で再検証した．
