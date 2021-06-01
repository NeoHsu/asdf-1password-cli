<div align="center">

# asdf-1password-cli ![Build](https://github.com/NeoHsu/asdf-1password-cli/workflows/Build/badge.svg) ![Lint](https://github.com/NeoHsu/asdf-1password-cli/workflows/Lint/badge.svg)

[1password-cli](https://support.1password.com/command-line-getting-started/) plugin for the [asdf version manager](https://asdf-vm.com).

</div>

# Contents

- [Dependencies](#dependencies)
- [Install](#install)
- [Why?](#why)
- [Contributing](#contributing)
- [License](#license)

# Dependencies

- `bash`, `curl`, `tar`: generic POSIX utilities.
- `SOME_ENV_VAR`: set this environment variable in your shell config to load the correct version of tool x.

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
asdf list-all 1password-cli

# Install specific version
asdf install 1password-cli latest

# Set a version globally (on your ~/.tool-versions file)
asdf global 1password-cli latest

# Now 1password-cli commands are available
op --version
```

Check [asdf](https://github.com/asdf-vm/asdf) readme for more instructions on how to
install & manage versions.

# Contributing

Contributions of any kind welcome! See the [contributing guide](contributing.md).

[Thanks goes to these contributors](https://github.com/NeoHsu/asdf-1password-cli/graphs/contributors)!

# License

See [LICENSE](LICENSE) © [Neo Hsu](https://github.com/NeoHsu/)
