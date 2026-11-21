# dotfiles

グローバルCLIはmise、ホームディレクトリの設定はchezmoiで管理する。

## 構成

- `chezmoi/`: chezmoi管理ファイル一式（`.chezmoiroot`で指定）。ホームディレクトリへ反映されるのはこの中身だけ
- `chezmoi/private_dot_config/mise/config.toml`: CLIとランタイムの一覧
- `chezmoi/private_dot_config/mise/private_mise.lock`: 解決済みバージョンと配布元
- `chezmoi/private_dot_config/mise/locks/`: npmツールの依存関係の記録
- `chezmoi/dot_zshenv`: 対話シェル以外でもmiseのshimを使うためのPATH設定
- `chezmoi/dot_zshrc`: miseとStarshipの初期化
- `justfile`: インストール、検証、更新などの定型操作

基本CLIはchezmoi、Starship、GitHub CLI、just、just-lsp、Git LFS、ripgrep、fd、fzf、jq、bat、zoxide。Node.js、Rustなども同じmise設定で管理する。

## 初期設定

[公式手順](https://mise.jdx.dev/installing-mise.html)でmiseを`~/.local/bin/mise`へインストールする。lockの形式に対応するmise 2026.10.18以降を使う。GitとZshはOS側で用意する。

このリポジトリをcloneしたディレクトリで、chezmoiを起動する。

```sh
~/.local/bin/mise exec chezmoi@latest -- chezmoi init --source "$PWD"
```

Gitの名前とメールアドレスはchezmoi dataの`gitName`と`gitEmail`へ入力する。設定を確認し、miseとシェル、Gitのファイルだけを反映する。

```sh
~/.local/bin/mise exec chezmoi@latest -- chezmoi diff
~/.local/bin/mise exec chezmoi@latest -- chezmoi apply \
  ~/.config/mise ~/.zshenv ~/.zshrc ~/.gitconfig
~/.local/bin/mise install --locked
exec zsh
just mise-check
```

GitHubの認証ヘルパーは`~/.local/bin/mise`からグローバル設定の`gh`を起動する。`gh`のインストール先にバージョン番号を埋め込まないので、miseで更新しても同じ設定を使える。

## 日常の操作

```sh
just mise-install   # lockに従ってインストール
just mise-check     # インストール漏れ、実行元、起動を確認
just mise-list      # 有効なツールを表示
just mise-upgrade   # CLIとlockを更新
just --list         # その他の操作
```

ツールを追加・更新したときは、グローバル設定とlock、その依存関係を一緒に保存する。

```sh
mise use --global <tool>@<version>
just mise-lock
just chz-add ~/.config/mise/config.toml
just chz-add ~/.config/mise/mise.lock
just chz-add ~/.config/mise/locks
just chz-diff
just chz-status
```

リポジトリの設定をホームへ反映する場合も、先に`just chz-diff`を確認し、`chezmoi apply ~/.config/mise`のように対象を絞る。`just upgrade`はAPTとSnap、mise、Godot、Blenderをまとめて更新するので、CLIだけを更新したい場合は`just mise-upgrade`を使う。

GodotとBlenderは`/opt`へ配置する専用スクリプトで管理する。操作方法は[Godot](godot/README.md)と[Blender](blender/README.md)を参照。

## Nixからの移行

2026-10-26にNixの基本CLIをすべてmiseへ移行した。旧flakeと移行前のホーム設定は`~/.local/state/chezmoi-dotfiles/migrations/`へバックアップ済み。移行先の動作を確認し、ユーザープロファイルの`chezmoi-dotfiles`を解除した。Nix本体、store、プロファイル履歴は復旧用に保持している。

Zsh起動時には、親プロセスから引き継いだNixのPATHとシステムのZsh設定が再追加するNixのPATHを外し、miseのshimを使う。開いていたシェルにも反映するには`exec zsh`を実行する。
