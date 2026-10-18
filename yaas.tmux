#!/usr/bin/env bash
# Shows Claude Code's state per window. Put #{yaas} in
# window-status-format / window-status-current-format.
# State comes from scripts/yaas-hook, run by Claude Code hooks.

get_opt() {
  local value
  value="$(tmux show -gqv "$1")"
  echo "${value:-$2}"
}

working="$(get_opt @yaas_working_color '#bb9af7')"
waiting="$(get_opt @yaas_waiting_color '#f7768e')"
idle="$(get_opt @yaas_idle_color '#9ece6a')"

# bouncing dots, one frame per second (needs status-interval 1)
frame='#{e|%%:%S,4}'
dots="#{?#{==:$frame,0},●∙∙,#{?#{==:$frame,2},∙∙●,∙●∙}}"
seg="#{?@yaas_state, #{?#{==:#{@yaas_state},working},#[fg=$working]$dots,#{?#{==:#{@yaas_state},waiting},#[fg=$waiting]●,#[fg=$idle]●}},}"

tmux set -g @yaas_seg "$seg"
tmux set -g status-interval 1

for opt in window-status-format window-status-current-format; do
  fmt="$(tmux show -gv "$opt")"
  tmux set -g "$opt" "${fmt//\#\{yaas\}/#\{T:@yaas_seg\}}"
done

# agent sidebar
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
key="$(get_opt @yaas_sidebar_key a)"
tmux bind-key "$key" run-shell "$DIR/scripts/toggle-sidebar '#{window_id}'"
# follow mode: move the sidebar into whichever window you switch to
for hook in session-window-changed client-session-changed; do
  tmux set-hook -g "${hook}[42]" "run-shell -b '$DIR/scripts/follow-sidebar #{window_id}'"
done
