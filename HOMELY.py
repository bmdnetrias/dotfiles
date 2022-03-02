import platform
import shutil
import tempfile
import time

from pathlib import Path

from homely.files import symlink, mkdir, download
from homely.install import installpkg
from homely.system import execute, haveexecutable
from homely.ui import head, note

home_dir = Path.home()
emacs_init_dir = home_dir / ".emacs.d"
dotfiles_old_dir = home_dir / "dotfiles.old"

mkdir("~/.emacs.d")

if not dotfiles_old_dir.exists():
    dotfiles_old_dir.mkdir()

install_system = platform.system()

PYDEV_PACKAGES = """
make build-essential libssl-dev zlib1g-dev
libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm
libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev
"""

if install_system == "Linux":
    for pkg in PYDEV_PACKAGES.split():
        installpkg.strip(pkg)

HOMEBREW_INSTALL_SCRIPT = (
    "https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
)


def brew_executable():
    brew_dir = Path("/home/linuxbrew/.linuxbrew")

    if brew_dir.is_dir():
        brew_binary = brew_dir / "bin" / "brew"
    else:
        return ""

    if brew_binary.exists() and brew_binary.is_file():
        return str(brew_binary)
    else:
        return False


with head("homebrew"):
    if not (haveexecutable("brew") or brew_executable()):
        if install_system == "Linux" and False:
            note("need to install Linux homebrew")
            with tempfile.NamedTemporaryFile(delete=False) as install_sh_tmp:
                note(f"Downloading brew install script to: {install_sh_tmp.name}")
                execute(
                    [
                        "curl",
                        "-fsSL",
                        "-o",
                        install_sh_tmp.name,
                        HOMEBREW_INSTALL_SCRIPT,
                    ]
                )
                note("Executing brew install script")
                execute(["/bin/bash", "-x", install_sh_tmp.name])
        elif install_system == "Darwin":
            note("need to install Mac homebrew")
            with tempfile.NamedTemporaryFile() as install_sh_tmp:
                note(f"Downloading brew install script to: {install_sh_tmp}")
                download(HOMEBREW_INSTALL_SCRIPT, install_sh_tmp)
                note("Executing brew install script")
                execute(["/bin/bash", "-c", install_sh_tmp])
        else:
            note("Unknown brew platform")
    else:
        note("homebrew already installed")

with head("pyenv"):
    note("Installing pyenv")
    execute(
        [
            "git",
            "clone",
            "https://github.com/pyenv/pyenv.git",
            "/home/crossjam/.pyenv",
        ]
    )
    # execute([brew, "install", "pyenv"])
    note("Installing pyenv-virtualenv")
    execute(
        [
            "git",
            "clone",
            "https://github.com/pyenv/pyenv-virtualenv.git",
            "/home/crossjam/.pyenv/plugins/pyenv-virtualenv",
        ]
    )
    # execute([brew, "install", "pyenv-virtualenv"])


INSTALL_DOTFILES = [
    ("screenrc", ".screenrc"),
    ("bashrc", ".bashrc"),
    ("bash_profile", ".bash_profile"),
    ("gitconfig", ".gitconfig"),
    ("gitignore", ".gitignore"),
    ("emacs_init.el", "~/.emacs.d/init.el"),
]

with head("Processing potentially preexisting targets."):
    for dot_file, orig_file in INSTALL_DOTFILES:
        orig_file_path = Path(orig_file).expanduser()
        dot_file_path = Path("~/dotfiles").expanduser() / dot_file
        note(f"Checking {orig_file_path}")
        if orig_file_path.exists() and not (orig_file_path.samefile(dot_file_path)):
            dst_file_path = (
                dotfiles_old_dir / f"{orig_file_path.name}_{int(time.time())}"
            )
            note(f"Original file: {orig_file_path} -> {dst_file_path}")
            shutil.move(orig_file_path, dst_file_path)

with head("Installing dotfiles."):
    for dot_file, orig_file in INSTALL_DOTFILES:
        symlink(dot_file, orig_file)
