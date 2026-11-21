# リポジトリ作業ガイド

## 構成

このリポジトリは、miseによるグローバルCLI環境と、chezmoiによるホームディレクトリ設定を管理する。

- `chezmoi/`: chezmoi管理ファイルだけを置く（`.chezmoiroot`で指定）。ホームディレクトリへ反映されるのはこの中身だけ
- `chezmoi/private_dot_config/mise/`: グローバルCLIの設定、lock、依存関係の記録
- `justfile`: 定型操作
- ルート直下、`blender/`、`godot/`、`lib/`: リポジトリ自体のもの（スクリプトやドキュメント）。chezmoi管理ファイルは置かない

## 作業ルール

作業前に`git status --short --branch`、`just chz-status`、`just chz-diff`で現状を確認する。

- レシピは`just --list`で確認し、分類名には`mise`、`chz`、`godot`、`b3d`を使う。
- miseの変更後は`just mise-install`と`just mise-check`でインストールと実行元を確認する。
- mise設定の反映は`~/.config/mise`を対象に限定する。ツール追加・更新後は設定・lock・`locks/`をまとめてchezmoiへ取り込む。
- chezmoiの変更後は`just chz-diff`と`just chz-status`で状態を確認する。アプリが自動更新した設定は、必要に応じて`just chz-add`でソースへ取り込む。chezmoiからホームへの一括適用は行わない。
- `upgrade`、lock更新、ツールのバージョン切替、chezmoi applyは依頼の範囲と影響を確認してから行う。
- ユーザーの既存変更を保持し、Gitへのstage、commit、pushは明示的な依頼なしに行わない。

## 安全上のルール

- 秘密情報、トークン、秘密鍵、認証情報を平文で追加しない。必要なら暗号化または外部シークレット管理を提案する。
- `.gitconfig`はテンプレートのみを管理し、identityはchezmoi dataの`gitName`と`gitEmail`を参照する。
- `chezmoi purge`、`chezmoi destroy`、`chezmoi state reset`などの破壊的操作は、明示的な依頼なしに実行しない。
- 古いツールや移行前バックアップの削除では、先に移行先の動作を検証する。
