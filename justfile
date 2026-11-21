# ~/dotfiles/justfile

set shell := ["bash", "-euc"]

# `just` だけで一覧を表示
default:
    @just --list


# ---------------------------------------------------------------------------
# Upgrade
# ---------------------------------------------------------------------------

# APT、Snap、mise、Godot、Blenderを順番に更新
upgrade:
    sudo apt update && sudo apt upgrade -y && sudo snap refresh && mise self-update -y && just mise-upgrade && just godot && just godot-doctor && just b3d && just b3d-doctor


# ---------------------------------------------------------------------------
# mise
# ---------------------------------------------------------------------------

# グローバル設定とlockに従ってCLIをインストール
mise-install:
    mise install --locked

# グローバルCLIのバージョンと配布元をlockへ記録
mise-lock:
    mise lock --global

# グローバルCLIを更新し、lockも更新
mise-upgrade:
    mise upgrade
    mise lock --global

# 現在有効なツールを表示
mise-list:
    mise ls

# インストール漏れと、基本CLIの実行元・起動を確認
mise-check:
    #!/usr/bin/env bash
    set -euo pipefail
    mise install --dry-run-code
    mise_data="${MISE_DATA_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/mise}"
    for tool in chezmoi starship gh just just-lsp git-lfs rg fd fzf jq bat zoxide; do
        resolved="$(realpath "$(mise which "$tool")")"
        case "$resolved" in
            "$mise_data"/installs/*) ;;
            *) printf 'mise以外の実行ファイルです: %s → %s\n' "$tool" "$resolved" >&2; exit 1 ;;
        esac
        "$resolved" --version
    done


# ---------------------------------------------------------------------------
# Applications
# ---------------------------------------------------------------------------

alias gd := godot
alias gd-install := godot-install
alias gd-use := godot-use
alias gd-uninstall := godot-uninstall
alias gd-current := godot-current
alias gd-list := godot-list
alias gd-doctor := godot-doctor
alias gd-register-desktop := godot-register-desktop

# Godot の最新版、または指定バージョンをインストールして有効化
godot version="latest":
    version="$(./godot/install.sh "{{version}}")"; ./godot/use.sh "$version"

# Godot をインストール（有効化はしない）
godot-install version="latest":
    ./godot/install.sh "{{version}}"

# インストール済み Godot の有効バージョンを切り替え
godot-use version:
    ./godot/use.sh "{{version}}"

# 非アクティブな Godot をアンインストール
godot-uninstall version:
    ./godot/uninstall.sh "{{version}}"

# 有効な Godot のバージョンを表示
godot-current:
    ./godot/current.sh

# インストール済み Godot の一覧を表示
godot-list:
    ./godot/list.sh

# Godot のローカル構成を変更せず診断
godot-doctor:
    ./godot/doctor.sh

# Godot をデスクトップアプリとして登録（ユーザーごとに一度）
godot-register-desktop:
    ./godot/register-desktop.sh

# Blender の最新版、または指定バージョンをインストールして有効化
b3d version="latest":
    version="$(./blender/install.sh "{{version}}")"; ./blender/use.sh "$version"

# Blender をインストール（有効化はしない）
b3d-install version="latest":
    ./blender/install.sh "{{version}}"

# インストール済み Blender の有効バージョンを切り替え
b3d-use version:
    ./blender/use.sh "{{version}}"

# 非アクティブな Blender をアンインストール
b3d-uninstall version:
    ./blender/uninstall.sh "{{version}}"

# 有効な Blender のバージョンを表示
b3d-current:
    ./blender/current.sh

# インストール済み Blender の一覧を表示
b3d-list:
    ./blender/list.sh

# Blender のローカル構成を変更せず診断
b3d-doctor:
    ./blender/doctor.sh


# Blender をデスクトップアプリとして登録（ユーザーごとに一度）
b3d-register-desktop:
    ./blender/register-desktop.sh


# ---------------------------------------------------------------------------
# chezmoi
# ---------------------------------------------------------------------------

# chezmoi 管理対象の差分を表示
chz-diff:
    chezmoi diff

# chezmoi 管理対象の状態を表示
chz-status:
    chezmoi status

# 例:
#   just chz-add ~/.gitconfig
# ファイルを chezmoi 管理下へ追加
chz-add path:
    chezmoi add "{{path}}"

# 例:
#   just chz-edit ~/.zshrc
# chezmoi 管理ファイルを編集
chz-edit path:
    chezmoi edit "{{path}}"


# ---------------------------------------------------------------------------
# Git
# ---------------------------------------------------------------------------

# Git repo 自体の状態を表示
git-status:
    git status --short
