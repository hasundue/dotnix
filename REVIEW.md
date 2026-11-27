# Review: Herdr worktree handoff

## 対象と結論

- 対象は `main...HEAD` の実装差分と `SPEC.md`．
- `SPEC.md` の実装として承認できない．高 4 件，中 2 件の修正が必要．

## 指摘

### 1. 高: main 復帰で旧 workspace が閉じない

`configs/home/pi/agent/extensions/herdr-worktree/handoff.ts:147`

main 復帰時，`oldWorkspaceId` は linked worktree の workspace ID，
`currentWorkspaceId` は main の workspace ID なので，通常は異なる．
そのため `isMainReturn` は false になり，SPEC の必須 cleanup である
旧 worktree workspace の close が実行されない．
逆に同一 ID になった場合は，移動先を含む workspace を閉じる危険もある．

`returningToMain` を job で渡すか，旧 workspace と移動先の worktree 種別・
path から判定する必要がある．

受け入れ条件の `[x]` は過去の手動 E2E 記録で，今回は再実行していない．
現在のコードでは cleanup 条件が成立しないため，main 復帰の再検証が必要である．

### 2. 高: pane close 失敗後も session file を削除する

`configs/home/pi/agent/extensions/herdr-worktree/handoff.ts:129-140`

`herdr pane close` が失敗しても catch 後に `unlink(sourceSession)` へ進む．
まだ動いている source session の file を削除し得るため，close 成功時にのみ
削除し，失敗時は処理を終了する必要がある．

### 3. 高: fork の失敗が成功扱いになる

`configs/home/herdr/worktree-handoff.nix:29-32`\
`configs/home/pi/agent/extensions/herdr-worktree/index.ts:264-276`

job を削除した後に `agent start ... || true` を実行し，focus も失敗を無視する．
そのため plugin action は exit 0 で完了し，tool は fork 失敗を知らずに
`Forked this session...` と `terminate: true` を返す．

失敗状態の保存・通知，または tool が成功を主張する条件の見直しが必要である．

### 4. 高: `pi-worktrunk` の削除が適用環境に反映しない

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

### 5. 中: hook 成功判定が別 worktree の log を拾う

`configs/home/pi/agent/extensions/herdr-worktree/index.ts:56-66`

plugin log は global で checkout を識別せず，ファイル存在確認も既存ファイルで
成立する．別の worktree で同時に成功した hook と，tracked な `.envrc` または
`.pi/settings.json` の存在で，現在の checkout の hook 未実行を見逃せる．

event と checkout を結び付けるか，checkout 固有の完了 marker を確認する
必要がある．

### 6. 中: relative path の解決基準が SPEC と異なる

`configs/home/pi/agent/extensions/herdr-worktree/index.ts:129`

`params.path` を `repoRoot` 取得前に `ctx.cwd` から解決している．
SPEC では `repo_root` を解決基準とし，削除済み cwd でも動作する必要がある．
`repoRoot` 取得後に `resolve(repoRoot, ...)` へ変更する必要がある．

## 検証

- `git diff --check main...HEAD` は clean．
- 変更した Nix ファイル 3 件の parse は成功．
- `nix eval` で Pi package 一覧と handoff plugin の登録を確認．
- `handoff.ts` の `--herdr-worktree-handoff` 登録を確認．
- Herdr の実セッション E2E は再実行していない．
