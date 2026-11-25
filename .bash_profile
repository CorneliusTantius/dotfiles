#
# ~/.bash_profile
#

[[ -f ~/.bashrc ]] && . ~/.bashrc

# Start MangoWM when logging in on any text console (not over SSH).
# Quit MangoWM to come back to this shell. Delete these lines to turn it off.
if [[ -z ${WAYLAND_DISPLAY:-} && $(tty) == /dev/tty* ]]; then
    mango
fi
