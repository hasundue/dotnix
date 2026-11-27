# Review: Herdr worktree handoff

## 対象と結論

- 対象は `main...HEAD` の実装差分と `SPEC.md`．
- `SPEC.md` の実装として承認できない．高 3 件，中 3 件の修正が必要．

## 再検証

### main 復帰の cleanup

scratch repo の linked worktree から `branch: "main"` を呼び出し，以下を確認し
た．

- 旧 linked workspace `w2S` が閉じた．
- main workspace に新規 tab `w2R:t2` と root pane `w2R:p2` が作られ，fork が続い
  た．
- 旧 pane と旧 session file は削除され，linked worktree は checkout として残っ
  た．

`herdr pane close` が最後の pane を閉じると Herdr は workspace も閉じるため，
`isMainReturn` による明示的な `workspace close` が false でも単一 pane の
受け入れ条件は満たされる．

旧 workspace に別 pane がある場合も検証した．source pane と旧 session file は
削除されたが，旧 workspace `w2Y` は `w2Y:p2` を残して残存し，linked worktree の
`open_workspace_id` も `w2Y` のままだった．

## 指摘

### 1. 高: pane close 失敗後も session file を削除する

`configs/home/pi/agent/extensions/herdr-worktree/handoff.ts:129-140`

`herdr pane close` が失敗しても catch 後に `unlink(sourceSession)` へ進む．
まだ動いている source session の file を削除し得るため，close 成功時にのみ
削除し，失敗時は処理を終了する必要がある．

### 2. 高: fork の失敗が成功扱いになる

`configs/home/herdr/worktree-handoff.nix:29-32`\
`configs/home/pi/agent/extensions/herdr-worktree/index.ts:264-276`

job を削除した後に `agent start ... || true` を実行し，focus も失敗を無視する．
そのため plugin action は exit 0 で完了し，tool は fork 失敗を知らずに
`Forked this session...` と `terminate: true` を返す．

失敗状態の保存・通知，または tool が成功を主張する条件の見直しが必要である．

### 3. 高: `pi-worktrunk` の削除が適用環境に反映しない

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

### 4. 中: hook 成功判定が別 worktree の log を拾う

`configs/home/pi/agent/extensions/herdr-worktree/index.ts:56-66`

plugin log は global で checkout を識別せず，ファイル存在確認も既存ファイルで
成立する．別の worktree で同時に成功した hook と，tracked な `.envrc` または
`.pi/settings.json` の存在で，現在の checkout の hook 未実行を見逃せる．

event と checkout を結び付けるか，checkout 固有の完了 marker を確認する
必要がある．

### 5. 中: relative path の解決基準が SPEC と異なる

`configs/home/pi/agent/extensions/herdr-worktree/index.ts:129`

`params.path` を `repoRoot` 取得前に `ctx.cwd` から解決している．
SPEC では `repo_root` を解決基準とし，削除済み cwd でも動作する必要がある．
`repoRoot` 取得後に `resolve(repoRoot, ...)` へ変更する必要がある．

### 6. 中: multi-pane の main 復帰で旧 workspace が残る

`configs/home/pi/agent/extensions/herdr-worktree/handoff.ts:147`

旧 workspace に別 pane が残っていると，source pane の close 後も workspace は
自動 close されない．main 復帰では `currentWorkspaceId` と `oldWorkspaceId` が
異なるため `isMainReturn` は false になり，明示的な `workspace close` も
スキップされる．scratch E2E では旧 workspace と残った pane がそのまま残った．

main 復帰時は job の `returningToMain` を見て，source pane close 後に旧
workspace
を明示的に close する．

## 検証

- `git diff --check main...HEAD` は clean．
- 変更した Nix ファイル 3 件の parse は成功．
- `nix eval` で Pi package 一覧と handoff plugin の登録を確認．
- `handoff.ts` の `--herdr-worktree-handoff` 登録を確認．
- main 復帰以外の Herdr 実セッション E2E は再実行していない．
