# Fish Test Utils

Fish shell utilities for (unit-)testing fishy things 🐟️.

## Description

A currently somewhat random assortment of utilities to facilitate (unit-)testing fish shell code.  The utilities are namespaces using the `ftutil-` prefix (shorter than fish-test-utils, still recognizable and unique enough).

Assumes tests are run via [Fishtape](https://github.com/jorgebucaran/fishtape), or at least a fresh fish process per executed test context.

This simplifying assumption is so automatic cleanup or restore functionality can simply hook into the `fish_exit` event.

This requires:

- New fish process per test context (test-file for fishtape);
- No parallel test execution (at least for cleanup/restore aware utilities).

## Status: Alpha

This project needs more docs, `-h` / `--help` implemented for commands, more and better function descriptions.  There is good test-coverage though.

## Installation

Install with [Fisher](https://github.com/jorgebucaran/fisher)

    fisher install tomvdsom/fish-test-utils

## The Utilities:

In short:

- `ftutil-echo-err`: echo, but output to stderr.

    When only given the `--short-cmd` option, creates `echo-err` function as an alias.

- `ftutil-empty-variables`: empties (local, global) or shadows (universal, via a global) variables matching given regexes.
- `ftutil-erase-functions`: erases functions matching given regexes.

    When `-s` / `--save-origin` is given, outputs filepaths where the erased functions originate from (when known).

- `ftutil-erase-variables`: erases variables (local, global, _and_ universal) matching given regexes.

    By default "saves" universal variables as encoded quads (pipe separated name, scope, exported, value(s) comma separated and escaped).

    When `--save-variables=...` (or `-s`) is given, your can specify which scopes should be "saved":

    - `l` / `local`
    - `g` / `global`
    - `u` / `universal`
    - `a` / `all` (all of the above)

    Comma separated when specifying more than one, or:

    - `n` / `none` (don't save anything)

    The `local` scope saving is only useful for debugging your code, since:

    - Locals cannot be programmatically set in another (calling) local scope (or "stack frame");
    - Shadowed values are not accessible unless a shadowing variable goes out of scope.

    Use `ftutil-set-variables` to restore saved variables.

- `ftutil-eval-nl`: `eval` (yes, that one) the arguments, and append a newline to stdout unconditionally:

    For testing with `test` / fishtape `@test`, or other commands where input should not be elided when they generate no output.

    Use in conjunction with `... | string collect)`, because if the _input to_ string collect is not-empty - even though the _output of_ string collect may be, the (now possibly empty) argument is **not elided**.

    Otherwise `test` will complain that is either misses arguments or it doesn't understand an operator.

    When only given the `--short-cmd` option, creates `en` function as an alias.

- `ftutil-eval-nl-err`: Same as `ftutil-eval-nl`, but append the newline to stderr:

    When only given the `--short-cmd` option, creates `ene` function as an alias.

- `ftutil-fn-var-cleanup`: Convenience combining `ftutil-erase-functions`, `ftutil-erase-variables` and `ftutil-set-variables` with a bit of restore magic to:

    1. Erase functions matching given regexes:

        Functions can be erased without restoring since that only leaves a pure in-memory "erased-marker" (to prevent unintentional auto(re)loading after erasing).

    2. Erase variables matching given regexes (in all scopes);
    3. On `fish_exit` restore erased universal variables:

       Only universal variables (testing) is hard, since they are shared across processes (by design), and so need to be restored into pristine pre-test condition.

- `ftutil-fn-var-cleanup-restore`: Don't wait for `fish_exit`, restore now (if `ftutil-fn-var-cleanup` called earlier).

- `ftutil-log-args`: Logging `$argv`, arguments are:

    - space separated;
    - encoded (with style `var`) and;
    - empty argument (or empty string) as `''` (two single quotes).

    Output to stdout, with an added newline (unconditional).

    When only given the `--short-cmd` option, creates `log-args` function as an alias.

- `ftutil-log-args-err`: Same as `ftutil-log-args`, but output to stderr:

    When only given the `--short-cmd` option, creates `log-args-err` function as an alias.

- `ftutil-random-string`: Output a random alphanumeric string.

- `ftutil-set-variables`: Sets variables for either arguments or stdin provided, newline separated, quads:

    To be used with `ftutil-erase-variables` output (saved variables).

- `ftutil-source-files`: Sourcing files, 0..n, given as arguments:

    Empty arguments are ignored.

- `ftutil-tempdir`: Creates a tempdir for you:

    Like `mktemp -d -t <template>`, but with cleanup `rm -rf <template-glob>` on `fish_exit`.

- `ftutil-tempdir-cleanup`: Don't wait for `fish_exit`, cleanup now (if `ftutil-tempdir` called earlier).

## Running Tests

Have [Fishtape](https://github.com/jorgebucaran/fishtape) installed, and run:

    fishtape tests/**.fish

## License

[MIT](LICENSE)
