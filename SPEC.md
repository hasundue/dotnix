---
status: agreed
---

# Spec の翻訳を廃止し，テンプレートと運用ルールを整理する

## 問題

日本語セッションの spec は承認のたびに英語へ翻訳され，独立チェックとファイル名の
変更を伴う．同じ約束が keel，sail，両テンプレート，lifecycle に分散し，一箇所を
直してもほかが古いままになる．翻訳を廃止し，spec の置き場所とテンプレートの役割
を一本化する．

## 設計

- 言語にかかわらず spec のファイル名は `SPEC.md` に統一する．keel の配置，
  sail の discovery，マージ時のチェックを同じ名前に合わせる．
- 承認は status を `agreed` に更新するだけとし，翻訳と skiff の独立チェックは
  行わない．spec は書かれた言語のまま運用する．内容レビューの仕組みは
  別案件として `TODO.md` に残す．
- この spec 自身も新しい約束に従い，`SPEC.md` として昇格させる．
- skiff の translation-check prompt は汎用ツールとして変更しない．spec 側から
  参照を外すだけにする．
- frontmatter から `session_lang` を外す．レポート言語は会話の言語で決め，
  手掛かりがなければユーザーに尋ねる．
- テンプレートは
  `configs/home/pi/agent/skills/keel/references/templates/SPEC.ja.md` と
  `SPEC.en.md` に移動し，frontmatter と各セクションのプレースホルダだけを置く．
  運用の説明は書かず，コピーしてそのまま spec として使えるようにする．
- テンプレートから外したルール（status の意味，チェックの記録，承認と昇格，言語
  の扱い）は `references/spec-lifecycle.md` に集約する．ファイル名は変えず，
  keel と sail の参照もそのまま使う．
- 翻訳を前提にした見出しマップは削除する．keel と sail が英語見出しを直接
  参照している箇所は，問題・設計・対象外・受け入れ条件・停止条件を言語に
  依存しない呼び方に変える．
- `## Blocker` は `status: blocked` のときだけ置くという直前の変更を維持する．
- `TODO.md` の扱いはこのスキルの外で定義する．今回はスキル側にルールを追加せず，
  作業メモとして `TODO.md` に残すだけにする．

## 対象外

- 内容レビューの仕組みと `TODO.md` 扱いの一般化．どちらも `TODO.md` に記録し，
  後者はスキル外で定義する．
- skiff の translation-check prompt の変更
- `home-switch` による設定の適用，既存ブランチの spec 移行
- Blocker と `stale` のルールの再設計

## 受け入れ条件

- ファイル名が `SPEC.md` に統一され，`SPEC.ja.md` と `SPEC.en.md` が生成されない
  - [x] `grep -rn 'SPEC\.ja\.md\|SPEC\.en\.md' \
        configs/home/pi/agent/skills/keel \
        configs/home/pi/agent/skills/sail` -- 終了コード 1，出力なし
- 承認時に翻訳と独立チェックが行われない
  - [x] `grep -rn 'translation-check\|SPEC\.en\.md' \
        configs/home/pi/agent/skills/keel` -- 終了コード 1，出力なし
  - [x] `git diff -- configs/home/pi/agent/skills/skiff` -- 出力なし
- テンプレートが新しいパスにあり，コピーしてそのまま使える
  - [x] `configs/home/pi/agent/skills/keel/references/templates/SPEC.ja.md` と
        `SPEC.en.md` を読む -- frontmatter，見出し，プレースホルダのみで，
        旧パスは `git rm` 済み
- 運用ルールが spec-lifecycle に集約されている
  - [x] `configs/home/pi/agent/skills/keel/references/spec-lifecycle.md` を読む
        -- status，チェックの記録，承認，言語を確認
  - [x] keel と sail の参照先が `references/spec-lifecycle.md` のままである
        -- keel:55,73,197,239，sail:52
- `session_lang` が消え，レポート言語が会話から決まる
  - [x] `grep -rn 'session_lang' configs/home/pi/agent/skills` -- 終了コード 1，
        出力なし
- 見出しマップと英語見出しへの直接参照が消えている
  - [x] `cd configs/home/pi/agent/skills && grep -rn \
        -e '## Problem\|## Design\|## Out of scope' \
        -e '## Acceptance criteria\|## Stop conditions\|## Blocker' \
        keel/SKILL.md sail/SKILL.md \
        keel/references/spec-lifecycle.md` -- 終了コード 1，出力なし
- keel と sail に `TODO.md` の扱いが書かれていない
  - [x] `grep -rn 'TODO\.md' configs/home/pi/agent/skills/keel \
        configs/home/pi/agent/skills/sail` -- 終了コード 1，出力なし
- 差分に余計な空白がない
  - [x] `git diff --check` -- 終了コード 0
