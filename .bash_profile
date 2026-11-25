#
# ~/.bash_profile
#

[[ -f ~/.bashrc ]] && . ~/.bashrc

# Start MangoWM when logging in on tty1 (tty2-6 stay text).
# Quit MangoWM to come back to this shell. Delete these lines to turn it off.
if [[ -z ${WAYLAND_DISPLAY:-} && ${XDG_VTNR:-} == 1 ]]; then
    mango
fi
