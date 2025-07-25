if [[ "$INSIDE_EMACS" == *comint* || "$INSIDE_EMACS" == *vterm* ]]; then
  export TERM=xterm-256color
  set -o emacs
fi

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

if [[ -n $(type -p gdircolors) ]]; then
   if [[ "$INSIDE_EMACS" == *comint* || "$INSIDE_EMACS" == *vterm* ]]; then
       eval "$(TERM=xterm-256color gdircolors -b ~/.dircolors.emacs)"
       PS1='${debian_chroot:+($debian_chroot)}\[\033[01;38;5;117m\]\u@\h\[\033[00m\]:\[\033[01;38;5;117m\]\w\[\033[00m\]\$ '
    else
        test -r ~/.dircolors && eval "$(TERM=xterm-256color gdircolors -b ~/.dircolors.emacs)" || eval "$(gdircolors -b)"
    fi
    alias ls='gls -f -CF --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
elif [[ -n $(type -p dircolors) ]]; then
   if [[ "$INSIDE_EMACS" == *comint* || "$INSIDE_EMACS" == *vterm* ]]; then
       eval "$(TERM=xterm-256color dircolors -b ~/.dircolors.emacs)"
    else
        test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    fi
    alias ls='ls -f -CF --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

[[ -r "/opt/homebrew/etc/profile.d/bash_completion.sh" ]] && . "/opt/homebrew/etc/profile.d/bash_completion.sh"  # Apple Silicon

[[ -r ~/.config/op/plugins.sh ]] && . ~/.config/op/plugins.sh

# if [ -x /etc/bash_completion ] && ! shopt -oq posix; then
#     . /etc/bash_completion
# fi

uvp() {
    local project_name
    local dir_name=$(basename "$PWD")
    
    # If there are no arguments or the last argument starts with a dash, use dir_name
    if [ $# -eq 0 ] || [[ "${!#}" == -* ]]; then
        project_name="$dir_name"
    else
        project_name="${!#}"
        set -- "${@:1:$#-1}"
    fi
    
    export UV_PROJECT_ENVIRONMENT=".${project_name:-venv}"

    # Check if .envrc already exists
    if [ -f .envrc ]; then
        echo "Error: .envrc already exists" >&2
        return 1
    fi


    # Create .envrc
    echo "export UV_PROJECT_ENVIRONMENT=$PWD/${UV_PROJECT_ENVIRONMENT}" >> .envrc
    echo "layout python" >> .envrc

    # Create Python package using uv with all passed arguments
    if ! uv init --package --build-backend setuptools --name $project_name; then
        echo "Error: Failed to create uv project" >&2
        return 1
    fi

    # Create Python package using uv with all passed arguments
    if ! uv sync; then
        echo "Error: Failed to sync uv project" >&2
        return 1
    fi

    # Append to ~/.projects
    echo "${project_name}=${PWD}" >> ~/.projects

    # Allow direnv to immediately activate the virtual environment
    direnv allow
}

uvpi() {
    local project_name=$(basename "$PWD")

    if [ -n "$VIRTUAL_ENV" ]; then
       	 export UV_PROJECT_ENVIRONMENT="$VIRTUAL_ENV"
    elif [ -n "$UV_PROJECT_ENVIRONMENT" ]; then
    	 :
    elif [ -d ".venv" ]; then
     	 export UV_PROJECT_ENVIRONMENT="$PWD/.venv"
    else
	 export UV_PROJECT_ENVIRONMENT="$PWD/$project_name"
    fi

    echo "UV_PROJECT_ENVIRONMENT=$UV_PROJECT_ENVIRONMENT"

    # Check if .envrc already exists
    if [ -f .envrc ]; then
        echo "Error: .envrc already exists" >&2
        return 1
    fi

    # Create .envrc
    echo "export UV_PROJECT_ENVIRONMENT=${UV_PROJECT_ENVIRONMENT}" >> .envrc
    echo "layout python" >> .envrc

    # Append to ~/.projects
    echo "${project_name}=${PWD}" >> ~/.projects

    # Allow direnv to immediately activate the virtual environment
    direnv allow
}


uvwork() {
    local project_name="$1"
    local projects_file="$HOME/.projects"
    local project_dir

    # Check for projects config file
    if [[ ! -f "$projects_file" ]]; then
        echo "Error: $projects_file not found" >&2
        return 1
    fi

    # Get the project directory for the given project name
    project_dir=$(grep -E "^$project_name\s*=" "$projects_file" | sed 's/^[^=]*=\s*//')

    # Ensure a project directory was found
    if [[ -z "$project_dir" ]]; then
        echo "Error: Project '$project_name' not found in $projects_file" >&2
        return 1
    fi

    # Ensure the project directory exists
    if [[ ! -d "$project_dir" ]]; then
        echo "Error: Directory -$project_dir- does not exist" >&2
        return 1
    fi

    # Change directories
    cd "$project_dir"
}

alias claude="$HOME/.claude/local/claude"

. "$HOME/.atuin/bin/env"

[ -f $HOMEBREW_PREFIX/etc/profile.d/bash-preexec.sh ] && . $HOMEBREW_PREFIX/etc/profile.d/bash-preexec.sh

# [[ -f ~/.bash-preexec.sh ]] && source ~/.bash-preexec.sh

eval "$(atuin init bash)"
eval "$(zoxide init bash)"
eval "$(starship init bash)"
eval "$(direnv hook bash)"

