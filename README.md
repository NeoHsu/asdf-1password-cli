<div align="center">

# asdf-1password-cli ![Build](https://github.com/NeoHsu/asdf-1password-cli/workflows/Build/badge.svg) ![Lint](https://github.com/NeoHsu/asdf-1password-cli/workflows/Lint/badge.svg)

[1password-cli](https://support.1password.com/command-line-getting-started/) plugin for the [asdf version manager](https://asdf-vm.com).

</div>

# Build History

[![Build history](https://buildstats.info/github/chart/NeoHsu/asdf-1password-cli?branch=master)](https://github.com/NeoHsu/asdf-1password-cli/actions)

# Contents

- [Dependencies](#dependencies)
- [Install](#install)
  - [Version selection](#version-selection)
  - [1Password app integration](#1password-app-integration)
- [Contributing](#contributing)
- [License](#license)

# Dependencies

- `bash`, `curl`, `unzip`: generic POSIX utilities.
- `gpg`, `gpg2`: optional, if you want to verify the 1password-cli installer with GPG.

# Install

Plugin:

```shell
asdf plugin add 1password-cli
# or
asdf plugin add 1password-cli https://github.com/NeoHsu/asdf-1password-cli.git
```

1password-cli:

```shell
# Show all installable versions
asdf list all 1password-cli

# Install the latest stable 1Password CLI
asdf install 1password-cli latest

# Set a version for your user (writes to your ~/.tool-versions)
asdf set -u 1password-cli latest

# Now 1password-cli commands are available
op --version
```

Check [asdf](https://github.com/asdf-vm/asdf) readme for more instructions on how to
install & manage versions.

## Version selection

`latest` resolves to the newest stable 1Password CLI release and skips beta releases.

```shell
# Latest stable release
asdf install 1password-cli latest

# Latest stable release in a version series
asdf install 1password-cli latest:2.34

# Specific release
asdf install 1password-cli 2.34.0
```

## 1Password app integration

This plugin installs `op` into the asdf-managed install directory. For Linux,
the plugin tries to set the `onepassword-cli` group and setgid bit on `op` when
the group already exists on the system and the current user has permission to
change the file group.

If the 1Password app integration does not connect on Linux, create the group
and re-apply the permissions to the asdf-managed binary:

```shell
sudo groupadd -f onepassword-cli
sudo chgrp onepassword-cli "$(asdf which op)"
sudo chmod g+s "$(asdf which op)"
```

1Password for Mac 8.10.12 and earlier require the CLI binary to be available at
`/usr/local/bin/op`. If you use one of those older app versions, create a
symlink to the asdf-managed binary:

```shell
sudo ln -sf "$(asdf which op)" /usr/local/bin/op
```

# Contributing

Contributions of any kind welcome! See the [contributing guide](contributing.md).

[Thanks goes to these contributors](https://github.com/NeoHsu/asdf-1password-cli/graphs/contributors)!

# License

See [LICENSE](LICENSE) © [Neo Hsu](https://github.com/NeoHsu/)
