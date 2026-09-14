# CLAUDE.md

Guidance for Claude Code when working in this repository.

## What this repo is

A single-purpose repo: one `Dockerfile` that builds a PHP development container
(Ubuntu + Apache + PHP + Xdebug + the Microsoft SQL Server drivers). There is no
application code, no test suite and no build script. The Dockerfile *is* the project.

Files that matter: `Dockerfile`, `README.md`, `.github/workflows/docker-publish.yml`.

## Branching model

One long-lived branch per PHP minor version: `php8.2`, `php8.3`, `php8.4`, `php8.5`,
`php8.6`. `main` holds the current fully working release (PHP 8.5 / Ubuntu 24.04).

A new `php8.x` branch is cut when the next PHP version enters pre-release, and is
merged to `main` **only once that PHP version is GA and every package works again** -
specifically xdebug, sqlsrv and pdo_sqlsrv, which always lag a new PHP release.
Smaller work happens on `tasks/<description>` branches merged into the relevant
`php8.x` branch by pull request.

Only `main` publishes images (to `ghcr.io/nielbuys/ncompphpdev`, via the Docker
workflow, on push to `main` and on `v*.*.*` tags). A `php8.x` branch produces no
published image, so do not bump the image tag in the README from a version branch -
that tag tracks what is actually published from `main`.

## Versioning

**Each PHP minor version gets its own minor version of the image tag.** The patch
number is for fixes within the same PHP version.

| Image tag | PHP |
| --------- | --- |
| `v1.0.x`  | 8.3 |
| `v1.1.x`  | 8.4 |
| `v1.2.x`  | 8.5 |
| `v1.3.x`  | 8.6 |

So PHP 8.6 releases as **`v1.3.0`**, tagged on `main` after the `php8.6` branch merges -
never from the version branch itself. The README's pull instructions should keep naming
the currently published tag (`v1.2.1`) until that merge and tag actually happen.

## Package sources - read this before editing the Dockerfile

**`ppa:ondrej/php` is dead for new Ubuntu releases.** The Launchpad PPA stops at
`noble` (24.04); its `devel` suite is just an alias whose Release file reads
`Codename: noble`. Ondřej Surý stated that from 26.04 onwards new Ubuntu LTS releases
are only at `packages.sury.org`
(<https://codeberg.org/oerdnj/deb.sury.org/issues/91>). The `php8.6` branch therefore
installs the `debsuryorg-archive-keyring.deb` and adds a `packages.sury.org` apt
source instead of calling `add-apt-repository`.

Do not "fix" a failing build by reverting to the PPA. Check what actually exists first.

## Verify before you edit

Everything here depends on third-party packages existing for a given Ubuntu release.
Check, do not assume - these are cheap and do not need Docker running:

```sh
# Which PHP versions exist for an Ubuntu codename at sury.org (26.04 = resolute)
curl -sS https://packages.sury.org/php/dists/resolute/main/binary-amd64/Packages.gz \
  | gzip -dc | grep -oE '^Package: php8\.[0-9]+$' | sort -u

# Does a specific package exist (e.g. php8.6-xdebug)?
curl -sS https://packages.sury.org/php/dists/resolute/main/binary-amd64/Packages.gz \
  | gzip -dc | grep '^Package: php8.6-xdebug$'

# Ubuntu's own archive (php-pear, build deps)
curl -sS -o /dev/null -w '%{http_code}\n' https://packages.ubuntu.com/resolute/php-pear

# Microsoft ODBC driver for that release
curl -sS https://packages.microsoft.com/ubuntu/26.04/prod/dists/resolute/main/binary-amd64/Packages \
  | grep '^Package: msodbcsql18'

# Newest PHP pre-release tags
git ls-remote --tags https://github.com/php/php-src.git | grep 'php-8\.6'
```

Docker is often not running on this machine (`dockerDesktopLinuxEngine` pipe missing).
If a build is needed to verify a change, say so rather than claiming the change works.

## Conventions

- **Comment out, do not delete.** When a package does not support the new PHP version
  yet, comment the block out with a note saying *why* and *what has to happen* before
  it is re-enabled. That is how previous version bumps were handled, and it keeps the
  re-enable a one-line change. Keep the supporting packages (`php8.x-dev`, `php-pear`,
  `unixodbc-dev`) installed so uncommenting just works.
- **Keep the version string consistent.** A version bump touches the base image, every
  `php8.x` package name, every `/etc/php/8.x/` path, `a2enmod php8.x`, `phpenmod -v 8.x`,
  and the `ncompphp8Xdev` image/container name in the Dockerfile header comments and
  the README.
- **Preserve the file's style.** One `RUN` per step, the existing comment headings and
  the Windows/Ubuntu command pairs in the README. Do not reorganise into multi-stage
  builds or collapse the `RUN` layers unless asked.
- `msodbcsql18` is PHP-independent - it stays in even when the sqlsrv PHP extensions
  are commented out.

## Known upstream lag

Expect these to be unavailable early in a PHP version's life, in this order of recovery:

1. `php8.x` core packages - appear first, at `packages.sury.org`.
2. `php8.x-xdebug` - Xdebug's `config.m4` hard-refuses PHP versions above its supported
   range, so no released Xdebug builds until it ships support.
3. `sqlsrv` / `pdo_sqlsrv` - Microsoft's pecl releases are usually last.
