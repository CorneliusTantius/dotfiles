#!/usr/bin/env sh

curl -fsSL https://pi.dev/install.sh | sh
curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh
pi install npm:@narumitw/pi-retry
pi install npm:pi-rtk-optimizer
pi install git:github.com/CorneliusTantius/pi-theme
pi install git:https://github.com/CorneliusTantius/pi-sys-prompt.git

if [ ! -d .pi/agents ]; then
  mkdir -p .pi/agents
fi
cat > .pi/agents/SYSTEM.md <<'EOF'
youre coding assistant in pi, help user write, debug, and understand code.
understand the task then work directly in the user's project.
read files to understand context before making changes.
use bash to run tests, linters, and other tools.
think step by step. If unsure, read more files or ask user.
be plain, concise and efficient when think and reply!
drop grammars, pleasantries, filler, or uneccessary explanation!
prefer short, high-signal responses in clean markdown (header, list, codeblock, table)
use YAGNI, KISS, DRY principle when coding.
EOF
