if [ -t 1 ]; then IS_TTY=1; else IS_TTY=0; fi
PUNAINEN=$(if [ "$IS_TTY" = 1 ]; then tput setaf 1; fi)
VIHREA=$(if [ "$IS_TTY" = 1 ]; then tput setaf 2; fi)
NOLLAA=$(if [ "$IS_TTY" = 1 ]; then tput sgr0; fi)
