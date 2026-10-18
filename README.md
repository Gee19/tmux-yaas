# Yet Another Agent Status (tmux-yaas)

Shows what Claude Code is doing in each tmux window, as a dot after the window name:

- `●∙∙` bouncing purple dots while it's working
- `●` red when it's waiting on you (permission prompt, question)
- `●` green when it's idle

Windows without a Claude session show nothing.

`prefix + a` toggles a sidebar on the left that lists every Claude pane across all sessions, with its state and how long it's been in it. The sidebar follows you: switching windows or sessions moves it into the new window (`join-pane`, so the same process keeps running). Press 1-9 to jump to that agent or `q` to close. A `▸` marks agents in the sidebar's own window, and a hollow `○` marks a pane where Claude has exited.

```
 Agents  1 working  1 waiting

▸1 ∙●∙ dotfiles
    0:2 dots · working 1m

 2 ● vtour
    0:1 zsh · waiting 12s

 1-9 jump · q close
```

Claude Code hooks run `scripts/yaas-hook`, which stores the state in a tmux window option (`@yaas_state`). The plugin draws the dot from that option. The animation uses tmux's own time formatting, so nothing runs per frame.

## Install

Clone or symlink the plugin into `~/.tmux/plugins/`:

```
ln -sfn ~/dev/tmux-yaas ~/.tmux/plugins/tmux-yaas
```

Add it to `tmux.conf` and put `#{yaas}` where you want the dot:

```
set -g @plugin 'tmux-yaas'
setw -g window-status-format " #I #W #F#{yaas} "
setw -g window-status-current-format " #I #W #F#{yaas} "
```

The `@plugin` line has to come before `run '~/.tmux/plugins/tpm/tpm'`. tpm looks the plugin up by folder name, so it needs to be a git repo (`git init` is enough), or `prefix + I` will try to clone over it.

The plugin sets `status-interval 1` so the dots move once a second. That also makes other `#()` commands in your status line run every second.

## Claude Code hooks

Merge this into `~/.claude/settings.json`. If you already have a `hooks` block, add these events to it rather than replacing it.

```json
{
  "hooks": {
    "SessionStart":       [{ "hooks": [{ "type": "command", "command": "$HOME/.tmux/plugins/tmux-yaas/scripts/yaas-hook", "timeout": 5 }] }],
    "SessionEnd":         [{ "hooks": [{ "type": "command", "command": "$HOME/.tmux/plugins/tmux-yaas/scripts/yaas-hook", "timeout": 5 }] }],
    "UserPromptSubmit":   [{ "hooks": [{ "type": "command", "command": "$HOME/.tmux/plugins/tmux-yaas/scripts/yaas-hook", "timeout": 5 }] }],
    "PreToolUse":         [{ "hooks": [{ "type": "command", "command": "$HOME/.tmux/plugins/tmux-yaas/scripts/yaas-hook", "timeout": 5 }] }],
    "PostToolUse":        [{ "hooks": [{ "type": "command", "command": "$HOME/.tmux/plugins/tmux-yaas/scripts/yaas-hook", "timeout": 5 }] }],
    "PostToolUseFailure": [{ "hooks": [{ "type": "command", "command": "$HOME/.tmux/plugins/tmux-yaas/scripts/yaas-hook", "timeout": 5 }] }],
    "PermissionRequest":  [{ "hooks": [{ "type": "command", "command": "$HOME/.tmux/plugins/tmux-yaas/scripts/yaas-hook", "timeout": 5 }] }],
    "Notification":       [{ "hooks": [{ "type": "command", "command": "$HOME/.tmux/plugins/tmux-yaas/scripts/yaas-hook", "timeout": 5 }] }],
    "Stop":               [{ "hooks": [{ "type": "command", "command": "$HOME/.tmux/plugins/tmux-yaas/scripts/yaas-hook", "timeout": 5 }] }],
    "StopFailure":        [{ "hooks": [{ "type": "command", "command": "$HOME/.tmux/plugins/tmux-yaas/scripts/yaas-hook", "timeout": 5 }] }]
  }
}
```

Every event runs the same script; it reads the hook JSON on stdin and decides the state:

- idle: `SessionStart` (except after a compaction), `Stop`, `StopFailure`
- working: `UserPromptSubmit`, `PreToolUse`, `PostToolUse`, `PostToolUseFailure`
- waiting: `PermissionRequest`, `PreToolUse` for `AskUserQuestion`, and `Notification` of type `permission_prompt` or `elicitation_dialog`
- cleared: `SessionEnd`

The 60-second "still idle" notification is ignored, so idle windows don't turn red.

Running sessions pick up new hooks after you open `/hooks` once or restart. The script needs `jq` on the `PATH`, and it does nothing outside tmux.

## Options

```
set -g @yaas_working_color '#bb9af7'
set -g @yaas_waiting_color '#f7768e'
set -g @yaas_idle_color    '#9ece6a'
```

The defaults are TokyoNight colors; the sidebar uses them too.

```
set -g @yaas_sidebar_key   'a'
set -g @yaas_sidebar_width '32'
set -g @yaas_sidebar_follow 'on'   # 'off' gives each window its own sidebar
```

## Quirks

Pressing Esc to interrupt Claude may not fire `Stop`, so the dots keep moving until your next prompt.

After you approve a permission, the dot stays red until that tool finishes. No hook fires between approval and execution.

A killed or crashed session leaves its dot behind. Clear it with `tmux set -wu @yaas_state` in that window.

The status bar dot is per window, so two Claude panes in one window share one dot, and the last event wins. The sidebar lists each pane separately.

The sidebar stays put when you switch to a zoomed window, since joining would unzoom it. tmux-resurrect will restore an open sidebar as a plain shell pane; close it with `exit` and reopen it with the key.
