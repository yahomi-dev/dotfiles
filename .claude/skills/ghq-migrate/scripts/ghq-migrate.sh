#!/usr/bin/env bash
# Move a local git repository into the ghq layout (<ghq root>/<host>/<path>) together with its worktrees, Claude Code state and mise trust.
# Without --apply it only prints the plan, so it is safe to run from inside a Claude Code session.
set -euo pipefail

usage() {
	cat <<'EOF'
Usage: ghq-migrate.sh [--apply [--yes]] [--remote NAME] [--keep-worktrees] <repo-path>

  (フラグなし)      dry-run。計画とブロッカーを表示するだけで何も変更しない
  --apply           計画を実行する (Claude Code の外のシェルから実行する)
  --yes             --apply の確認プロンプトを省略する
  --remote NAME     ghq のパスを決める remote (既定: origin)
  --keep-worktrees  リポジトリ外の worktree をその場に残し、リンクだけ修復する
                    (既定は <repo>/.claude/worktrees/ の下へ移動する)
EOF
}

die() {
	printf 'error: %s\n' "$*" >&2
	exit 1
}

apply=0
assume_yes=0
remote=origin
keep_worktrees=0
src=
while (($#)); do
	case $1 in
	--apply) apply=1 ;;
	--yes) assume_yes=1 ;;
	--remote)
		remote=${2:?--remote には値が必要}
		shift
		;;
	--keep-worktrees) keep_worktrees=1 ;;
	-h | --help)
		usage
		exit 0
		;;
	-*) die "unknown option: $1" ;;
	*)
		[[ -z $src ]] || die "リポジトリのパスが 2 つ指定されている"
		src=$1
		;;
	esac
	shift
done
if [[ -z $src ]]; then
	usage >&2
	exit 2
fi

for cmd in git ghq jq perl; do
	command -v "$cmd" >/dev/null || die "$cmd が見つからない"
done

[[ -d $src ]] || die "ディレクトリではない: $src"
src=$(cd "$src" && pwd -P)
top=$(git -C "$src" rev-parse --show-toplevel 2>/dev/null) || die "git リポジトリではない: $src"
[[ $top == "$src" ]] || die "リポジトリのルートを指定する: $top"
[[ -d $src/.git ]] || die "linked worktree が指定された。メインの worktree を指定する"
# Paths are written verbatim into JSON and perl patterns, so characters that would need escaping are rejected.
[[ $src != *[\"\\]* ]] || die "パスに \" または \\ を含むリポジトリは扱わない: $src"

# Scanning /proc/*/cwd later must not see this script itself inside the repository.
cd /

url=$(git -C "$src" remote get-url "$remote" 2>/dev/null) || die "remote '$remote' がない"
case $url in
*://*)
	rest=${url#*://}
	authority=${rest%%/*}
	host=${authority##*@}
	repo_path=${rest#"$authority"}
	repo_path=${repo_path#/}
	;;
*:*)
	authority=${url%%:*}
	host=${authority##*@}
	repo_path=${url#*:}
	;;
*) die "remote URL から host / path を決められない: $url" ;;
esac
host=${host%%:*}
repo_path=${repo_path%/}
repo_path=${repo_path%.git}
[[ -n $host && -n $repo_path ]] || die "remote URL から host / path を決められない: $url"

ghq_root=$(ghq root)
if [[ -d $ghq_root ]]; then
	ghq_root=$(cd "$ghq_root" && pwd -P)
fi
dest=$ghq_root/$host/$repo_path
[[ $src != "$ghq_root"/* ]] || die "既に ghq root の下にある: $src"

blockers=()
warnings=()
[[ ! -e $dest ]] || blockers+=("移行先が既に存在する: $dest")

# --- worktrees -------------------------------------------------------------

wt_paths=()
wt_prunable=()
while IFS= read -r line; do
	case $line in
	'worktree '*)
		wt_paths+=("${line#worktree }")
		wt_prunable+=(0)
		;;
	prunable*) wt_prunable[${#wt_prunable[@]}-1]=1 ;;
	esac
done < <(git -C "$src" worktree list --porcelain)

repo_name=${src##*/}
wt_old=()
wt_new=()
wt_kind=()
declare -A planned_names=()
for ((i = 1; i < ${#wt_paths[@]}; i++)); do
	path=${wt_paths[i]}
	if ((wt_prunable[i])); then
		warnings+=("実体のない worktree は対象外 (git worktree prune で整理できる): $path")
		continue
	fi
	path=$(cd "$path" && pwd -P)
	if [[ $path == "$src"/* ]]; then
		wt_old+=("$path")
		wt_new+=("$dest${path#"$src"}")
		wt_kind+=(inside)
		continue
	fi
	if ((keep_worktrees)); then
		wt_old+=("$path")
		wt_new+=("$path")
		wt_kind+=(kept)
		continue
	fi
	name=${path##*/}
	name=${name#"$repo_name"-}
	if [[ -e $src/.claude/worktrees/$name || -n ${planned_names[$name]:-} ]]; then
		blockers+=("移動先の worktree 名が衝突する: .claude/worktrees/$name ($path)")
		continue
	fi
	planned_names[$name]=1
	wt_old+=("$path")
	wt_new+=("$dest/.claude/worktrees/$name")
	wt_kind+=(external)
done

need_exclude=0
if ((${#planned_names[@]})) && ! git -C "$src" check-ignore -q .claude/worktrees/probe; then
	need_exclude=1
fi

# --- running processes -----------------------------------------------------

watched=("$src")
for ((i = 0; i < ${#wt_old[@]}; i++)); do
	[[ ${wt_kind[i]} != external ]] || watched+=("${wt_old[i]}")
done
for proc in /proc/[0-9]*; do
	cwd=$(readlink "$proc/cwd" 2>/dev/null) || continue
	for dir in "${watched[@]}"; do
		if [[ $cwd == "$dir" || $cwd == "$dir"/* ]]; then
			comm=$(cat "$proc/comm" 2>/dev/null) || comm='?'
			blockers+=("移動対象の中で動いているプロセス: pid ${proc#/proc/} ($comm) cwd=$cwd")
			break
		fi
	done
done

# --- Claude Code state -----------------------------------------------------

claude_dir=${CLAUDE_CONFIG_DIR:-$HOME/.claude}
if [[ -n ${CLAUDE_CONFIG_DIR:-} ]]; then
	claude_json=$CLAUDE_CONFIG_DIR/.claude.json
else
	claude_json=$HOME/.claude.json
fi
history_file=$claude_dir/history.jsonl
projects_dir=$claude_dir/projects

# Claude Code names a project directory after its path with every non-alphanumeric character replaced by '-'.
slug() {
	printf '%s' "${1//[^a-zA-Z0-9]/-}"
}

map_old=("$src")
map_new=("$dest")
for ((i = 0; i < ${#wt_old[@]}; i++)); do
	[[ ${wt_old[i]} == "${wt_new[i]}" ]] && continue
	map_old+=("${wt_old[i]}")
	map_new+=("${wt_new[i]}")
done

proj_from=()
proj_to=()
hist_old=()
hist_new=()
hist_count=0
json_old=()
json_new=()
for ((i = 0; i < ${#map_old[@]}; i++)); do
	old=${map_old[i]}
	new=${map_new[i]}
	slug_old=$(slug "$old")
	slug_new=$(slug "$new")
	if ((${#slug_old} > 200 || ${#slug_new} > 200)); then
		warnings+=("パスが長く Claude Code がハッシュ付きの名前を使うため、projects の移動は手動で行う: $new")
	elif [[ -d $projects_dir/$slug_old ]]; then
		if [[ -e $projects_dir/$slug_new ]]; then
			blockers+=("移行先の Claude プロジェクトが既にある (新パスで claude を先に起動した?): $projects_dir/$slug_new")
		else
			proj_from+=("$projects_dir/$slug_old")
			proj_to+=("$projects_dir/$slug_new")
		fi
	fi
	if [[ -f $history_file ]]; then
		count=$(grep -cF "\"project\":\"$old\"" "$history_file" || true)
		if ((count > 0)); then
			hist_old+=("$old")
			hist_new+=("$new")
			hist_count=$((hist_count + count))
		fi
	fi
	if [[ -f $claude_json ]] && jq -e --arg k "$old" '.projects | has($k)' "$claude_json" >/dev/null 2>&1; then
		if jq -e --arg k "$new" '.projects | has($k)' "$claude_json" >/dev/null 2>&1; then
			warnings+=("$claude_json に新パスのキーが既にあるため旧キーは移さない: $new")
		else
			json_old+=("$old")
			json_new+=("$new")
		fi
	fi
done

# --- mise trust --------------------------------------------------------------

mise_state=${MISE_STATE_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/mise}
mise_trust=()
if command -v mise >/dev/null && [[ -d $mise_state/trusted-configs ]]; then
	for ((i = 0; i < ${#map_old[@]}; i++)); do
		if [[ -n $(find "$mise_state/trusted-configs" -maxdepth 1 -lname "${map_old[i]}" -print -quit) ]]; then
			mise_trust+=("${map_new[i]}")
		fi
	done
fi

# --- references to the old path (reported, never rewritten) ----------------

ref_targets=()
for target in "$projects_dir"/*/memory "$claude_dir"/CLAUDE.md "$claude_dir"/settings.json "$claude_dir"/settings.local.json \
	"$claude_dir"/skills "$claude_dir"/rules "$claude_dir"/agents "$claude_dir"/commands \
	"$HOME"/.zshrc "$HOME"/.zshenv "$HOME"/.zprofile "$HOME"/.bashrc "$HOME"/.profile; do
	[[ -e $target ]] && ref_targets+=("$target")
done
ref_patterns=(-e "$src")
if [[ $src == "$HOME"/* ]]; then
	ref_patterns+=(-e "~/${src#"$HOME"/}")
fi
refs=()
if ((${#ref_targets[@]})); then
	mapfile -t refs < <(grep -rlIF --exclude-dir=node_modules --exclude-dir=.git "${ref_patterns[@]}" "${ref_targets[@]}" 2>/dev/null || true)
fi
# Show memory files at the location they will have after the project directory is renamed.
for ((r = 0; r < ${#refs[@]}; r++)); do
	for ((i = 0; i < ${#proj_from[@]}; i++)); do
		if [[ ${refs[r]} == "${proj_from[i]}"/* ]]; then
			refs[r]=${proj_to[i]}${refs[r]#"${proj_from[i]}"}
		fi
	done
done

# --- plan --------------------------------------------------------------------

if ((apply)); then
	printf '== 移行計画\n'
else
	printf '== 移行計画 (dry-run: 何も変更しない)\n'
fi
printf '\nリポジトリ\n  %s\n  -> %s\n' "$src" "$dest"
printf '\nworktree (%d 本)\n' "${#wt_old[@]}"
for ((i = 0; i < ${#wt_old[@]}; i++)); do
	case ${wt_kind[i]} in
	inside) printf '  [一緒に移動] %s\n' "${wt_new[i]}" ;;
	external) printf '  [移動] %s\n         -> %s\n' "${wt_old[i]}" "${wt_new[i]}" ;;
	kept) printf '  [据え置き] %s (リンクだけ修復)\n' "${wt_old[i]}" ;;
	esac
done
if ((need_exclude)); then
	printf '  .git/info/exclude に /.claude/worktrees/ を追記する\n'
fi
printf '\nClaude Code\n'
for ((i = 0; i < ${#proj_from[@]}; i++)); do
	printf '  projects: %s\n         -> %s\n' "${proj_from[i]##*/}" "${proj_to[i]##*/}"
done
((${#proj_from[@]})) || printf '  projects: 移すディレクトリなし\n'
printf '  history.jsonl: 旧パスの行 %d 件を書き換える\n' "$hist_count"
for ((i = 0; i < ${#json_old[@]}; i++)); do
	printf '  %s: projects キー %s -> 新パス\n' "${claude_json/#$HOME/\~}" "${json_old[i]}"
done
if ((${#mise_trust[@]})); then
	printf '\nmise trust\n'
	printf '  %s\n' "${mise_trust[@]}"
fi
if ((${#refs[@]})); then
	printf '\n旧パスを参照しているファイル (このスクリプトは書き換えない。移行後に更新する)\n'
	printf '  %s\n' "${refs[@]}"
fi
if ((${#warnings[@]})); then
	printf '\n注意\n'
	printf '  %s\n' "${warnings[@]}"
fi
if ((${#blockers[@]})); then
	printf '\nブロッカー (解消してから再実行する)\n'
	printf '  %s\n' "${blockers[@]}"
	exit 1
fi

if ((!apply)); then
	printf '\nブロッカーなし。Claude Code を終了したシェルから --apply 付きで実行する。\n'
	exit 0
fi

if ((!assume_yes)); then
	[[ -t 0 ]] || die "非対話で実行するときは --yes を付ける"
	printf '\n'
	read -r -p "この計画で実行しますか? [y/N] " answer
	if [[ $answer != [yY] ]]; then
		printf '中止した\n'
		exit 1
	fi
fi

# --- apply -------------------------------------------------------------------

ts=$(date +%Y%m%d-%H%M%S)
log_dir=${XDG_STATE_HOME:-$HOME/.local/state}/ghq-migrate
mkdir -p "$log_dir"
log=$log_dir/$ts-${dest##*/}.tsv
record() {
	printf '%s\t%s\t%s\n' "$1" "$2" "${3:-}" >>"$log"
}
step() {
	printf '==> %s\n' "$*"
}

step "リポジトリを移動"
mkdir -p "${dest%/*}"
mv "$src" "$dest"
record repo "$src" "$dest"

for ((i = 0; i < ${#wt_old[@]}; i++)); do
	[[ ${wt_kind[i]} == external ]] || continue
	step "worktree を移動: ${wt_old[i]##*/}"
	mkdir -p "${wt_new[i]%/*}"
	mv "${wt_old[i]}" "${wt_new[i]}"
done
for ((i = 0; i < ${#wt_old[@]}; i++)); do
	record worktree "${wt_old[i]}" "${wt_new[i]}"
done

if ((need_exclude)); then
	step ".git/info/exclude に /.claude/worktrees/ を追記"
	mkdir -p "$dest/.git/info"
	printf '/.claude/worktrees/\n' >>"$dest/.git/info/exclude"
fi

if ((${#wt_new[@]})); then
	step "worktree のリンクを修復"
	git -C "$dest" worktree repair "${wt_new[@]}"
	prunable_before=0
	for flag in "${wt_prunable[@]}"; do
		prunable_before=$((prunable_before + flag))
	done
	prunable_after=$(git -C "$dest" worktree list --porcelain | grep -c '^prunable' || true)
	if ((prunable_after > prunable_before)); then
		warnings+=("修復できなかった worktree がある (git worktree list で prunable を確認する)")
	fi
fi

for ((i = 0; i < ${#proj_from[@]}; i++)); do
	step "Claude Code のプロジェクトを移動: ${proj_to[i]##*/}"
	mv "${proj_from[i]}" "${proj_to[i]}"
	record claude-project "${proj_from[i]}" "${proj_to[i]}"
done

if ((${#hist_old[@]})); then
	step "history.jsonl のプロジェクトパスを書き換え"
	cp -p "$history_file" "$history_file.bak-ghq-migrate-$ts"
	record backup "$history_file.bak-ghq-migrate-$ts"
	for ((i = 0; i < ${#hist_old[@]}; i++)); do
		OLD_PATH=${hist_old[i]} NEW_PATH=${hist_new[i]} \
			perl -pi -e 's/\Q"project":"$ENV{OLD_PATH}"\E/"project":"$ENV{NEW_PATH}"/g' "$history_file"
	done
fi

if ((${#json_old[@]})); then
	step "$claude_json の projects キーを付け替え"
	cp -p "$claude_json" "$claude_json.bak-ghq-migrate-$ts"
	record backup "$claude_json.bak-ghq-migrate-$ts"
	for ((i = 0; i < ${#json_old[@]}; i++)); do
		tmp=$(mktemp "$claude_json.XXXXXX")
		jq --arg o "${json_old[i]}" --arg n "${json_new[i]}" \
			'.projects[$n] = .projects[$o] | del(.projects[$o])' "$claude_json" >"$tmp"
		chmod --reference="$claude_json" "$tmp"
		mv "$tmp" "$claude_json"
	done
fi

for dir in "${mise_trust[@]}"; do
	step "mise trust: $dir"
	mise trust "$dir"
	record mise-trust "$dir"
done

printf '\n完了。対応表: %s\n' "$log"
if ((${#warnings[@]})); then
	printf '\n注意\n'
	printf '  %s\n' "${warnings[@]}"
fi
printf '\n次の手順:\n  cd %s && claude\n  -> 新しいセッションで /ghq-migrate を実行し、事後処理 (依存の再インストール・検証・メモリのパス更新) を行う\n' "$dest"
