{ lib, ... }:
{
  environment.etc.bashrc.text = lib.mkAfter ''
    __ETC_BASHRC_DONE=1
  '';

  home-files.allUsers.".inputrc" = ''
    $include /etc/inputrc
    set completion-ignore-case on
    set skip-completed-text on
  '';

  programs.bash = {
    interactiveShellInit = ''
      shopt -s checkjobs checkwinsize globstar histappend nullglob

      HISTCONTROL=erasedups:ignoredups
      HISTFILESIZE=-1
      HISTSIZE=-1

      shopt -q login_shell && export INTERACTIVE_LOGIN_SHELL=1
    '';
    promptInit = ''
      if [[ "$TERM" != "dumb" ]] || [[ -n "$INSIDE_EMACS" ]]; then
        _prompt_cmd() {
          _prev_command_exit=$?
          history -a
        }

        _prompt_cmd_set_prompt() {
          local nested_shells=$((SHLVL - (INTERACTIVE_LOGIN_SHELL ? 1 : 2)))
          PS1="\[\033[1;$((UID ? 32 : 31))m\]\\$"
          ((nested_shells)) && PS1="$PS1\[\033[22;37m\]+"
          ((DIRENV_ACTIVE)) && PS1="$PS1\[\033[22;37m\]*"
          PS1="$PS1 "

          local git_dir
          if git_dir="$(git rev-parse --show-toplevel 2>/dev/null)"; then
            local git_branch="$(git branch --show-current 2>/dev/null)"
            PS1="$PS1\[\033[1;37m\]''${PWD/#''${git_dir%/*}/…} "
            PS1="$PS1\[\033[1;35m\]$git_branch "
          else
            PS1="$PS1\[\033[1;37m\]\w "
          fi

          local small_prompt="\[\033[22;$((_prev_command_exit ? 31 : 90))m\]• \[\033[0m\]"
          PS1="$PS1$small_prompt"
          PS2="$small_prompt"

          [[ -z "$INSIDE_EMACS" ]] && PS1="\[\e]0;\w\a\]$PS1"
        }

        PROMPT_COMMAND="_prompt_cmd;$PROMPT_COMMAND''${PROMPT_COMMAND:+;}_prompt_cmd_set_prompt"

        _set_title() {
          if [[ -n "$__ETC_BASHRC_DONE" && "$BASH_COMMAND" != _* ]]; then
            echo -ne "\033]0;''${PWD/#"$HOME"/\~} \`$BASH_COMMAND\`\007"
          else
            echo -ne "\033]0;''${PWD/#"$HOME"/\~}\007"
          fi
        }

        [[ -z "$INSIDE_EMACS" ]] && trap _set_title DEBUG; :
      fi
    '';
  };
}
