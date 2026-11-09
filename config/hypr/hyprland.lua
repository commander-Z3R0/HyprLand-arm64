-- ~/.config/hypr/hyprland.lua
-- Hyprland Lua configuration for PinePhone Pro / Mobian

local terminal = "alacritty"
local fileManager = "nautilus"
local menu = "fuzzel"
local keyboard = "wvkbd-mobintl"

-- Keyboard height reduced: 200 -> 150
local keyboardArgs = "-l simple,specialpad -H 180 --fn 'DejaVu Sans 10' --bg 22222288"

-- Monitor
hl.monitor({
    output = "DSI-1",
    mode = "preferred",
    position = "auto",
    scale = 2.5,
})

-- Environment variables
hl.env("GSK_RENDERER", "ngl")
hl.env("GTK_USE_PORTAL", "1")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("QT_QPA_SYSTEM_ICON_THEME", "breeze")
hl.env("XCURSOR_SIZE", "24")

-- General options
hl.config({
    render = {
        direct_scanout = false,
    },

    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_guiutils_check = true,
    },

    input = {
        follow_mouse = 1,
        sensitivity = 0,

        touchpad = {
            natural_scroll = true,
        },
    },

    general = {
        gaps_in = 5,
        gaps_out = 10,
        border_size = 2,
        layout = "dwindle",
        allow_tearing = false,
        resize_on_border = true,

        col = {
            active_border = {
                colors = {
                    "rgba(33ccffee)",
                    "rgba(00ff99ee)",
                },
                angle = 45,
            },
            inactive_border = "rgba(595959aa)",
        },
    },

    decoration = {
        rounding = 20,

        blur = {
            enabled = true,
            size = 3,
            passes = 1,
        },
    },

    animations = {
        enabled = true,
    },

    gestures = {
        workspace_swipe_cancel_ratio = 0.5,
        workspace_swipe_min_speed_to_force = 5,
        workspace_swipe_touch = true,
        workspace_swipe_invert = false,
        workspace_swipe_forever = true,
        workspace_swipe_use_r = true,
    },
})

-- Layer rules
hl.layer_rule({
    match = { namespace = "syslock" },
    blur = true,
})

hl.layer_rule({
    match = { namespace = "swaync-control-center" },
    blur = true,
    ignore_alpha = 0.5,
})

hl.layer_rule({
    match = { namespace = "swaync-notification-window" },
    blur = true,
    ignore_alpha = 0.5,
})

hl.layer_rule({
    match = { namespace = "wvkbd" },
    above_lock = 2,
    no_anim = true,
})

-- Autostart
hl.on("hyprland.start", function()
    hl.exec_cmd("/usr/libexec/pipewire-launcher")
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=Hyprland")
    hl.exec_cmd("/usr/libexec/xdg-desktop-portal-hyprland")
    hl.exec_cmd("/usr/libexec/xdg-desktop-portal")
    hl.exec_cmd("swaybg -i ~/Pictures/wallpaper_sirros.png -m fill || swaybg -c 1a1a2e")
    hl.exec_cmd("sh -c 'sleep 2 && waybar'")
    hl.exec_cmd("swaync")
    hl.exec_cmd("switch.sh")
    hl.exec_cmd(keyboard .. " " .. keyboardArgs)
end)

-- Applications
hl.bind("SUPER + Return", hl.dsp.exec_cmd(terminal))
hl.bind("SUPER + E", hl.dsp.exec_cmd(fileManager))
hl.bind("SUPER + D", hl.dsp.exec_cmd(menu))
hl.bind("SUPER + W", hl.dsp.exec_cmd("firefox-esr"))

-- Windows
hl.bind("SUPER + Q", hl.dsp.exec_cmd("hyprctl dispatch killactive"))
hl.bind("SUPER + M", hl.dsp.exec_cmd("hyprctl dispatch exit"))
hl.bind("SUPER + V", hl.dsp.exec_cmd("hyprctl dispatch togglefloating"))
hl.bind("SUPER + P", hl.dsp.exec_cmd("hyprctl dispatch pseudo"))
hl.bind("SUPER + J", hl.dsp.exec_cmd("hyprctl dispatch togglesplit"))

-- Focus
hl.bind("SUPER + Left", hl.dsp.exec_cmd("hyprctl dispatch movefocus l"))
hl.bind("SUPER + Right", hl.dsp.exec_cmd("hyprctl dispatch movefocus r"))
hl.bind("SUPER + Up", hl.dsp.exec_cmd("hyprctl dispatch movefocus u"))
hl.bind("SUPER + Down", hl.dsp.exec_cmd("hyprctl dispatch movefocus d"))

-- Switch workspaces
for i = 1, 9 do
    hl.bind("SUPER + " .. i, hl.dsp.exec_cmd("hyprctl dispatch workspace " .. i))
    hl.bind("SUPER + SHIFT + " .. i, hl.dsp.window.move({ workspace = tostring(i) }))
end

hl.bind("SUPER + 0", hl.dsp.exec_cmd("hyprctl dispatch workspace 10"))
hl.bind("SUPER + SHIFT + 0", hl.dsp.window.move({ workspace = "10" }))

-- Scratchpad
hl.bind("SUPER + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind("SUPER + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic", follow = false }))

-- Scroll between workspaces
hl.bind("SUPER + mouse_down", hl.dsp.exec_cmd("hyprctl dispatch workspace e+1"))
hl.bind("SUPER + mouse_up", hl.dsp.exec_cmd("hyprctl dispatch workspace e-1"))

-- Brightness
hl.bind(
    "SUPER + SHIFT + Up",
    hl.dsp.exec_cmd("brightnessctl set +10%"),
    { repeating = true }
)

hl.bind(
    "SUPER + SHIFT + Down",
    hl.dsp.exec_cmd("brightnessctl set 10%-"),
    { repeating = true }
)

-- Volume
hl.bind(
    "SUPER + CTRL + Up",
    hl.dsp.exec_cmd("pactl set-sink-volume @DEFAULT_SINK@ +10%")
)

hl.bind(
    "SUPER + CTRL + Down",
    hl.dsp.exec_cmd("pactl set-sink-volume @DEFAULT_SINK@ -10%")
)

-- Delayed screenshot
hl.bind(
    "SUPER + SHIFT + P",
    hl.dsp.exec_cmd("sh -c 'sleep 3 && sh ~/.config/hypr/scripts/screenshot.sh'")
)

-- Toggle gaps
hl.bind(
    "SUPER + F",
    hl.dsp.exec_cmd(
        "hyprctl keyword general:gaps_out $(hyprctl -j getoption general:gaps_out 10 | jq 'if .int == 10 then 0 else 10 end')"
    )
)

-- Physical buttons
hl.bind(
    "XF86AudioRaiseVolume",
    hl.dsp.exec_cmd("alacritty"),
    { locked = true, repeating = true }
)

hl.bind(
    "XF86AudioLowerVolume",
    hl.dsp.exec_cmd("pkill -SIGRTMIN -f wvkbd-mobintl"),
    { locked = true, repeating = true }
)

hl.bind(
    "XF86AudioLowerVolume",
    hl.dsp.exec_cmd("pgrep " .. keyboard .. " || " .. keyboard .. " " .. keyboardArgs),
    { locked = true, repeating = true }
)

hl.bind(
    "XF86PowerOff",
    hl.dsp.exec_cmd(
        "hyprctl dispatch dpms $(hyprctl -j monitors | jq -r 'first|.dpmsStatus|if . then \"off\" else \"on\" end')"
    ),
    { locked = true, repeating = true }
)

hl.bind(
    "XF86PowerOff",
    hl.dsp.exec_cmd(
        "hyprctl keyword input:touchdevice:enabled $(hyprctl -j getoption input:touchdevice:enabled | jq '.int==0')"
    ),
    { locked = true, repeating = true }
)
