{ pkgs, ... }:
{
  # Selection of sysadmin tools that can come in handy
  environment.systemPackages = with pkgs; [
    bashInteractive
    bat
    cacert
    coreutils
    ddrescue
    direnv
    eza
    fd
    findutils
    fzf
    gawk
    git
    gnumake
    gnupg
    gnused
    gnutar
    grc
    hyperfine
    jq
    less
    moreutils
    openssh
    openssl
    (ripgrep.override { withPCRE2 = true; })
    rsync
    sd
    tealdeer
    tmux

    # (
    #   if stdenv.hostPlatform.isDarwin
    #   then clang
    #   else gcc
    # )

    ## === Network ===

    curl
    dig
    dnsutils
    nmap
    wget
    speedtest-cli
    iperf3
    # whois

    ## === Monitoring ===

    dua # <- learn about the disk usage of directories, fast!
    lnav # <- log file navigator
    procs # <- a "modern" replacement for ps
    bottom # <- a "modern" replacement for ps

    ## === Files ===

    dust # <- like du but more intuitive
    file # <- a program that shows the type of files
    glow # <- charmbracelet's markdown cli renderer
    unzip # <- *.zip archive extraction utility

    ## === nix ===
    nix-index
    manix
  ];
}
