# Contributing

Testing Locally:

```shell
asdf plugin test <plugin-name> <plugin-url> [--asdf-tool-version <version>] [--asdf-plugin-gitref <git-ref>] [test-command*]

#
asdf plugin test 1password-cli https://github.com/NeoHsu/asdf-1password-cli.git "op --version"
```

Tests are automatically run in GitHub Actions on push and PR.
