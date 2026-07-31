# Homebrew packages, declaratively managed by nix-darwin's homebrew module.
# Converted from the former Brewfile (`make brew`). `nix run .#switch` runs
# `brew bundle` against this set during activation; Homebrew itself must
# already be installed. Activation defaults are conservative: no auto
# update/upgrade, and packages missing from this file are left untouched
# (onActivation.cleanup = "none").
{ ... }:
{
  homebrew = {
    enable = true;

    taps = [
      "appsody/appsody"
      "arto-app/tap"
      "brona/iproute2mac"
      "bufbuild/buf"
      "c-bata/kube-prompt"
      "datawire/blackbird"
      "derailed/k9s"
      "derailed/popeye"
      "dotenvx/brew"
      "dtan4/tools"
      "ethereum/ethereum"
      "garethr/kubeval"
      "getsentry/tools"
      "go-delve/delve"
      "hashicorp/tap"
      "icu4c/taps"
      "jesseduffield/lazydocker"
      "johanhaleby/kubetail"
      "ktr0731/evans"
      "kyoshidajp/ghkw"
      "laurent22/massren"
      "osx-cross/avr"
      "px4/px4"
      "rcmdnk/rcmdnkpac"
      "reviewdog/tap"
      "rinchsan/tap"
      "sachaos/todoist"
      "sanemat/font"
      "stripe/stripe-cli"
      "supabase/tap"
      "tldr-pages/tldr"
      "wagoodman/dive"
      "yakitrak/yakitrak"
    ];

    brews = [
      # All-in-one AI-Powered CLI Chat & Copilot
      "aichat"
      # Access Log Profiler
      "alp"
      # All in one for **env
      "anyenv"
      # Cryptography and SSL/TLS Toolkit
      "openssl@3"
      # Library for manipulating PNG images
      "libpng"
      # Automatic configure script builder
      "autoconf"
      # Tool for generating GNU Standards-compliant Makefiles
      "automake"
      # Bourne-Again SHell, a UNIX command interpreter
      "bash"
      # Programmable completion for Bash 3.2
      "bash-completion"
      # Regular expressions library
      "oniguruma"
      # Clone of cat(1) with syntax highlighting and Git integration
      "bat"
      # General-purpose data compression with high compression ratio
      "xz"
      # GNU binary tools for native development
      "binutils"
      # Parser generator
      "bison"
      # Freely available high-quality data compressor
      "bzip2"
      # Core application library for C
      "glib"
      # Share macOS clipboard with tmux and other local and remote apps
      "clipper"
      # Cross-platform make
      "cmake"
      # Color-highlighted diff(1) output
      "colordiff"
      # Get a file from an HTTP, HTTPS or FTP server
      "curl"
      # Generic library support script
      "libtool"
      # Image format providing lossless and lossy compression for web images
      "webp"
      # Graphics library to dynamically manipulate images
      "gd"
      # Network authentication protocol
      "krb5"
      # C library for reading, creating, and modifying zip archives
      "libzip"
      # Granddaddy of HTML tools, with support for modern standards
      "tidy-html5"
      # General-purpose scripting language
      "php"
      # Dependency Manager for PHP
      "composer"
      # GNU File, Shell, and Text utilities
      "coreutils"
      # Tool for browsing source code
      "cscope"
      # Reimplementation of ctags(1)
      "ctags"
      # Top-like interface for container metrics
      "ctop"
      # High-level C binding for ZeroMQ
      "czmq"
      # Modern diagram scripting language that turns text to diagrams
      "d2"
      # Secure runtime for JavaScript and TypeScript
      "deno"
      # Kubernetes command-line interface
      "kubernetes-cli"
      # CLI helps develop/deploy/debug apps with Docker and k8s
      "devspace"
      # Device firmware update based USB programmer for Atmel chips
      "dfu-programmer"
      # Good-lookin' diffs with diff-highlight and more
      "diff-so-fancy"
      # Load/unload environment variables based on $PWD
      "direnv"
      # Tool for exploring each layer in a docker image
      "dive"
      # Lightweight DNS forwarder and DHCP server
      { name = "dnsmasq"; restart_service = "changed"; }
      # Docker Credential Helper for Amazon ECR
      "docker-credential-helper-ecr"
      # Emoji on the command-line :scream:
      "emojify"
      # Cross-platform C++ GUI toolkit
      "wxwidgets"
      # Programming language for highly scalable real-time systems
      "erlang"
      # Modern, maintained replacement for ls (successor to exa)
      "eza"
      # Simple, fast and user-friendly alternative to find
      "fd"
      # Play, record, convert, and stream select audio and video codecs
      "ffmpeg"
      # Collection of GNU find, xargs, and locate
      "findutils"
      # C/C++ and Java libraries for Unicode and globalization
      "icu4c@76"
      # Command-line outline and bitmap font editor/converter
      "fontforge"
      # Terminal JSON viewer
      "fx"
      # Command-line fuzzy finder written in Go
      "fzf"
      # Easily access your Google Calendar(s) from a command-line
      "gcalcli"
      # GNU compiler collection
      "gcc"
      # Toolkit for image loading and pixel buffer manipulation
      "gdk-pixbuf"
      # GitHub command-line tool
      "gh"
      # Interpreter for PostScript and PDF
      "ghostscript"
      # Remote repository management made easy
      "ghq"
      # Access GitHub's .gitignore boilerplates
      "gibo"
      # Distributed revision control system
      "git"
      # Extensions to follow Vincent Driessen's branching model
      "git-flow"
      # Git extension for versioning large files
      "git-lfs"
      # Command-line option parsing utility
      "gnu-getopt"
      # Light, temporary commits for git
      "git-now"
      # Prevents you from committing sensitive information to a git repo
      "git-secrets"
      # OpenGL and OpenGL ES reference compiler for shading languages
      "glslang"
      # Asynchronous event library
      "libevent"
      # GNU Transport Layer Security (TLS) Library
      "gnutls"
      # Open source programming language to build simple/reliable/efficient software
      "go"
      # Task is a task runner/build tool that aims to be simpler and easier to use
      "go-task"
      # Package compiler and linker metadata toolkit
      "pkgconf"
      # Generate introspection data for GObject libraries
      "gobject-introspection"
      # Database migrations CLI tool
      "golang-migrate"
      # Library for manipulating JPEG-2000 images
      "jasper"
      # Image manipulation
      "netpbm"
      # Library to render SVG files using Cairo
      "librsvg"
      # Graph visualization software from AT&T and Bell Labs
      "graphviz"
      # GNU troff text-formatting system
      "groff"
      # Java-based scripting language
      "groovy"
      # Like cURL, but for gRPC
      "grpcurl"
      # GNU Ubiquitous Intelligent Language for Extensions
      "guile"
      # Smarter Dockerfile linter to validate best practices
      "hadolint"
      # Kubernetes package manager
      "helm"
      # Deploy Kubernetes Helm Charts
      "helmfile"
      # Convert source code to formatted text with syntax highlighting
      "highlight"
      # Improved top (interactive process viewer)
      "htop"
      # Review-first terminal diff viewer for agent-authored changesets
      "hunk"
      # Configurable static site generator
      "hugo"
      # ISO/IEC 23008-12:2017 HEIF file format decoder and encoder
      "libheif"
      # Tools and libraries to manipulate images in select formats
      "imagemagick"
      # CLI wrapper for basic network utilities on macOS - ip command
      "iproute2mac"
      # JSON output from a shell
      "jo"
      # Image manipulation library
      "jpeg"
      # Lightweight and flexible command-line JSON processor
      "jq"
      # Tool to move from `docker-compose` to Kubernetes
      "kompose"
      # Tool that can switch between kubectl contexts easily and create aliases
      "kubectx"
      # Validate Kubernetes configuration files, supports multiple Kubernetes versions
      "kubeval"
      # BSD-style licensed readline alternative
      "libedit"
      # Conversion library
      "libiconv"
      # Rainbows and unicorns in your console!
      "lolcat"
      # Keep your Mac's application settings in sync
      "mackup"
      # GUI for vim, made for macOS
      "macvim"
      # Utility for directing compilation
      "make"
      # Easily convert Marp Markdown files into static HTML/CSS, PDF, PPT and images
      "marp-cli"
      # Run a Kubernetes cluster locally
      "minikube"
      # Simple tool to make locally trusted development certificates
      "mkcert"
      # Protocol buffers (Google's data interchange format)
      "protobuf"
      # Remote terminal application
      "mosh"
      # Tail multiple files in one terminal simultaneously
      "multitail"
      # CLI for MySQL with auto-completion and syntax highlighting
      "mycli"
      # General-purpose lossless data-compression library
      "zlib"
      # Open source relational database management system
      "mysql"
      # Search tool like grep and The Silver Searcher
      "ripgrep"
      # Text interface for Git repositories
      "tig"
      # Command-line and local web note-taking, bookmarking, and archiving
      "nb"
      # HTTP/2 C Library
      "nghttp2"
      # C library to read whole-slide images (a.k.a. virtual slides)
      "openslide"
      # Small collection of programs that operate on patch files
      "patchutils"
      # Simplistic interactive filtering tool
      "peco"
      # Draw UML diagrams
      "plantuml"
      # Save clipboard image as PNG (karabiner-config: iTerm2 Cmd+V image paste for Claude Code)
      "pngpaste"
      # PDF rendering library (based on the xpdf-3.0 code base)
      "poppler"
      # Show ps output as a tree
      "pstree"
      # Python version management
      "pyenv"
      # Pyenv plugin to manage virtualenv
      "pyenv-virtualenv"
      # Tiny command-line DNS client with support for UDP, TCP, DoT, DoH, DoQ and ODoH
      "q"
      # QR Code generation
      "qrencode"
      # Cross-platform application and UI framework
      "qt"
      # Software environment for statistical computing
      "r"
      # Generate C-based recognizers from regular expressions
      "re2c"
      # Reattach process (e.g., tmux) to background
      "reattach-to-user-namespace"
      # Perl-powered file rename script with many helpful built-ins
      "rename"
      # Safe, concurrent, practical language
      "rust"
      # 7-Zip is a file archiver with a high compression ratio
      "sevenzip"
      # Static analysis and lint tool, for (ba)sh scripts
      "shellcheck"
      # Autoformat shell script source code
      "shfmt"
      # Easy and Repeatable Kubernetes Development
      "skaffold"
      # Editor of encrypted files
      "sops"
      # Secure Reliable Transport
      "srt"
      # Tail multiple Kubernetes pods & their containers
      "stern"
      # Command-line integration for Teensy USB development boards
      "teensy_loader_cli"
      # User interface to the TELNET protocol
      "telnet"
      # Send macOS User Notifications from the command-line
      "terminal-notifier"
      # Terraform version manager inspired by rbenv
      "tfenv"
      # Code-search similar to ack
      "the_silver_searcher"
      # Simplified and community-driven man pages
      "tldr"
      # Terminal multiplexer
      "tmux"
      # Command-line translator using Google Translate and more
      "translate-shell"
      # CLI tool that moves files or folder to the trash
      { name = "trash"; link = true; }
      # Display directories as trees (with optional color/HTML output)
      "tree"
      # Command-line unarchiving tools supporting multiple formats
      "unar"
      # Extremely fast Python package installer and resolver, written in Rust
      "uv"
      # HTTP load testing tool and library
      "vegeta"
      # Command-line interface for Vercel
      "vercel-cli"
      # Image processing library
      "vips"
      # Executes a program periodically, showing output fullscreen
      "watch"
      # Internet file retriever
      "wget"
      # Network settings helper
      "whatmask"
      # Blazing fast terminal file manager written in Rust, based on async I/O
      "yazi"
      # Feature-rich command-line audio/video downloader
      "yt-dlp"
      # Shell extension to navigate your filesystem faster
      "zoxide"
      # Next-generation plugin manager for zsh
      "zplug"
      # UNIX shell (command interpreter)
      "zsh"
      # Additional completion definitions for zsh
      "zsh-completions"
    ];

    casks = [
      # Speech-to-text system
      "aqua-voice"
      # The Art of Reading Markdown.
      "arto-app/tap/arto"
      # Securely stores and accesses AWS credentials in a development environment
      "aws-vault-binary"
      # Audio utility
      "background-music-pre"
      # Virtual Audio Driver
      "blackhole-16ch"
      # Free and open-source web browser
      "chromium"
      # Ghostty-based terminal with vertical tabs and notifications for AI coding agents
      "cmux"
      "font-symbols-only-nerd-font"
      # Set of tools to manage resources and applications hosted on Google Cloud
      "gcloud-cli"
      # Terminal built on web technologies
      "hyper"
      # Adaptive brightness for external displays
      "lunar"
      # Markdown editor
      "markedit"
      # Neovim Client
      "neovide-app"
      # Replacement for Docker Desktop
      "orbstack"
    ];
  };
}
