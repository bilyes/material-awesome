local filesystem = require('gears.filesystem')

-- Thanks to jo148 on github for making rofi dpi aware!
local with_dpi = require('beautiful').xresources.apply_dpi
local get_dpi = require('beautiful').xresources.get_dpi
local rofi_command = 'env /usr/bin/rofi -dpi ' .. get_dpi() .. ' -width ' .. with_dpi(600)
local screenshot_command = filesystem.get_configuration_dir() .. '/configuration/utils/screenshot'

return {
  -- List of apps to start by default on some actions
  default = {
    terminal = 'alacritty',
    rofi = rofi_command .. ' -show combi',
    rofi_calc = rofi_command .. [[ -show calc -modi calc -no-show-match -no-sort -calc-command "echo -n '{result}' | xclip -in -selection clipboard"]],
    lock = 'i3lock-fancy',
    quake = 'alacritty',
    screenshot = screenshot_command .. ' -m',
    region_screenshot = screenshot_command .. ' -r',
    delayed_screenshot = screenshot_command .. ' --delayed -r',
    
    -- Editing these also edits the default program
    -- associated with each tag/workspace
    browser = 'firefox -P default-release',
    private_browser = 'firefox -P Private',
    editor = 'code', -- gui text editor
    social = 'env discord',
    game = rofi_command,
    files = 'nautilus',
    music = rofi_command
  },
  -- List of apps to start once on start-up
  run_on_start_up = {
    --'compton --config ' .. filesystem.get_configuration_dir() .. '/configuration/compton.conf',
    'picom --experimental-backends',
    'nm-applet --indicator', -- wifi
    --'blueberry-tray', -- Bluetooth tray icon
    --'xfce4-power-manager', -- Power manager
    --'ibus-daemon --xim --daemonize', -- Ibus daemon for keyboard
    --'scream-start', -- scream audio sink
    --'numlockx on', -- enable numlock
    '/usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1 & eval $(gnome-keyring-daemon -s --components=pkcs11,secrets,ssh,gpg)', -- credential manager
    --'/usr/lib/x86_64-linux-gnu/libexec/polkit-kde-authentication-agent-1 & eval $(gnome-keyring-daemon -s --components=pkcs11,secrets,ssh,gpg)', -- credential manager
    --'blueman-tray', -- bluetooth tray
    --'geary --hidden', -- Email client
    -- Add applications that need to be killed between reloads
    -- to avoid multipled instances, inside the awspawn script
    '~/.config/awesome/configuration/awspawn', -- Spawn "dirty" apps that can linger between sessions
    -- Set color temperature
    'sct 4500', -- Default is 6500. The lower the warmer
  }
}
