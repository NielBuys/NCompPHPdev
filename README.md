# NCompPHPdev
NCompPHPdev Docker Containers

PHP development Docker containers with XDebug configured and working.

The following PHP modules are installed: mysql, cli, common, curl, gd, intl, ldap, mbstring, readline, sqlite3 (with pdo_sqlite), xdebug, xml, zip, sqlsrv and pdo_sqlsrv.

> **Current release: `v1.3.0`** - PHP 8.6.0 on Ubuntu 26.04. Xdebug is still a 3.6.0
> alpha build. See [PHP 8.6 package notes](#php-86-package-notes).

## Why this exists

Developing PHP web apps natively on Windows never gives me exactly what I get on the
server. It is close, but it is not identical, and the differences tend to surface late.
This container exists so that when I develop on Windows, I am working in exactly the
environment the application will run in on the server.

On Linux the reason is a different one. The environment already matches, so the value is
in not having to set everything up by hand on every machine, and in knowing that every
developer gets the same consistent environment.

---

## How this repository works

### A branch per PHP version

Each PHP minor version has its own long-lived branch:

| Branch   | PHP | Base image     | Image tag            | Status                                |
| -------- | --- | -------------- | -------------------- | ------------------------------------- |
| `main`   | 8.6 | `ubuntu:26.04` | `v1.3.0`             | Current release - what gets published |
| `php8.6` | 8.6 | `ubuntu:26.04` | `v1.3.0`             | Merged to `main`                      |
| `php8.5` | 8.5 | `ubuntu:24.04` | `v1.2.0`, `v1.2.1`   | Previous version                      |
| `php8.4` | 8.4 | `ubuntu:24.04` | `v1.1.0`             | Previous version                      |
| `php8.3` | 8.3 | `ubuntu:24.04` | `v1.0.0`, `v1.0.1`   | Previous version                      |
| `php8.2` | 8.2 | `ubuntu:24.04` | -                    | Pre-dates tagged releases             |

`main` always holds the current, fully working release. Older `php8.x` branches are
kept around so an earlier PHP version can still be built if a project needs it.

### The lifecycle of a new PHP version

1. A `php8.x` branch is created when the next PHP version enters its pre-release cycle.
2. The Dockerfile is pointed at the new PHP version and, where needed, a newer Ubuntu LTS.
3. Anything that does not build yet - typically xdebug and the Microsoft sqlsrv
   drivers, which lag a new PHP release - is **commented out** with a note saying why
   and what has to happen before it can come back.
4. As upstream catches up, those blocks are uncommented one at a time.
5. **When the PHP version reaches General Availability and every package works again,
   the branch is merged to `main` via a pull request.**
6. A `v*.*.*` tag is pushed, which publishes the new image. See [Versioning](#versioning).

Smaller pieces of work happen on short-lived `tasks/<description>` branches, which are
merged into the relevant `php8.x` branch by pull request.

### Versioning

**Each PHP minor version gets its own minor version of the image tag**, so the image
version tracks the PHP version rather than the calendar:

| Image tag | PHP |
| --------- | --- |
| `v1.0.x`  | 8.3 |
| `v1.1.x`  | 8.4 |
| `v1.2.x`  | 8.5 |
| `v1.3.x`  | 8.6 |

So **PHP 8.6 is released as `v1.3.0`**. The patch number is for fixes to an image
within the same PHP version - for example `v1.2.1` added the `:delegated` flag to the
PHP 8.5 image.

### Publishing

[`.github/workflows/docker-publish.yml`](.github/workflows/docker-publish.yml) builds
and publishes the image to `ghcr.io/nielbuys/ncompphpdev`, signed with cosign. It runs on:

- every push to `main`
- every `v*.*.*` tag
- pull requests against `main` (build only, nothing is pushed)
- a nightly schedule

Because it only publishes from `main`, **a `php8.x` branch produces no published image
until it is merged.** To use an in-progress version, build it locally from its branch.

---

## PHP 8.6 package notes

PHP 8.6 reached General Availability on **2026-11-19** (`8.6.0`) and is published as
`v1.3.0`. The one caveat is Xdebug: no stable release supports PHP 8.6 yet, so
`php8.6-xdebug` is built from Xdebug 3.6.0alpha1. It moves to the stable 3.6.x when
that ships and the image is rebuilt.

**Packages no longer come from `ppa:ondrej/php`.** Ondřej Surý has stopped adding new
Ubuntu LTS releases to the Launchpad PPA - it stops at `noble`/24.04. From Ubuntu 26.04
onwards the packages live at **`packages.sury.org`**, which is what the Dockerfile now
configures.

| Item                    | Status                                                                 |
| ----------------------- | ---------------------------------------------------------------------- |
| `php8.6` + core modules | Working - `8.6.0` from `packages.sury.org`                              |
| `php8.6-xdebug`         | Working - from `packages.sury.org`, built from Xdebug **3.6.0alpha1** (3.5.x refuses PHP 8.6) |
| `sqlsrv` / `pdo_sqlsrv` | Working - `php8.6-sqlsrv` / `php8.6-pdo-sqlsrv` 5.14.0 from `packages.sury.org` |
| `msodbcsql18`           | Working - Microsoft publishes a `resolute` (26.04) build                |

**sqlsrv no longer comes from pecl.** Microsoft's last pecl release is 5.13.3, which does
not compile on PHP 8.6. From 5.14.0 the drivers ship only through
[PIE](https://github.com/php/pie) and GitHub releases, so the Dockerfile installs
the `packages.sury.org` builds instead.

---

## Getting Started

### Prerequisites
Ensure you have Docker installed on your system. These instructions were tested on **Ubuntu 26.04** and **Windows**.

---

### Pull docker image

The published image is built from `main`: the **current release, `v1.3.0` (PHP 8.6)**.
For an older PHP version, pull its tag (see [Versioning](#versioning)) or build locally
from its branch.

1. **Pull Docker image**

  - **Ubuntu**

        sudo docker pull ghcr.io/nielbuys/ncompphpdev:v1.3.0
    
  - **Windows**

        docker pull ghcr.io/nielbuys/ncompphpdev:v1.3.0

2. **Run the Docker container**

  - **Ubuntu**

        sudo docker run  -p 80:80 --add-host=host.docker.internal:host-gateway --name ncompphp86dev -d -v /var/www/html:/var/www/html ghcr.io/nielbuys/ncompphpdev:v1.3.0

  - **Windows**

        docker run  -p 80:80 --name ncompphp86dev -d -v C:/html:/var/www/html:delegated ghcr.io/nielbuys/ncompphpdev:v1.3.0

### How to Build and Run the Docker Container

1. **Open a terminal and navigate to your project folder.**

2. **Build the Docker image**

  - **Ubuntu:**

        sudo docker build -t ncompphp86dev .

  - **Windows:**

        docker build -t ncompphp86dev .

3. **Run the Docker container:**

  - **Ubuntu:**

        sudo docker run  -p 80:80 --add-host=host.docker.internal:host-gateway --name ncompphp86dev -d -v /var/www/html:/var/www/html ncompphp86dev

  - **Windows**

        docker run  -p 80:80 --name ncompphp86dev -d -v C:/html:/var/www/html:delegated ncompphp86dev

## Notes

### What does the volume mapping (-v C:/html:/var/www/html) mean?

The two paths either side of the colon are the host and the container:

- The first path (before the colon `:`) is the folder on your host machine.
- The second path (after the colon `:`) is the folder inside the Docker container.

So your files stay where you edit them on the host, and the container reads them from
`/var/www/html`. Nothing is copied into the image - edit a file on the host and the
change is live on the next request.

### Where do I put my PHP files?

In the folder mapped on your host machine - `C:/html` on Windows, `/var/www/html` on
Linux. They are automatically accessible inside the container, no rebuild needed.

### How do I open the site in a browser?

Go to http://localhost. You should see the Apache test page, or your own project if
you have placed files in the mapped folder.

### Why does PHP feel slow on Windows, and what does ":delegated" do?

On Windows the code lives on the host (`C:/html`) and is bind-mounted into the container
at `/var/www/html`. Every file the container reads therefore crosses the Windows-to-Linux
filesystem boundary, and each `stat()` and `open()` across that boundary is far more
expensive than a native read inside the container.

This hits PHP harder than most workloads. A framework bootstrap `require`s hundreds of
small files on *every single request*, so the cost scales with the *number* of files in
the project rather than their size. A large framework, or a `vendor` directory full of
dependencies, can make an otherwise trivial page feel sluggish - while the same code on
a Linux host feels instant.

The `:delegated` flag relaxes the consistency guarantee for the mount: the container's
view of the filesystem is treated as authoritative, so writes made inside the container
may take a moment to become visible on the host. That looser contract allows more
aggressive caching instead of checking back with the host on every access. It is safe
for this setup because editing happens on the host and the container only reads. The
flag originated in Docker Desktop for Mac, so how much it helps on Windows depends on
the Docker Desktop version and backend - worth measuring rather than assuming.

### Why is the opcode cache on for the command line?

PHP's opcode cache keeps compiled code so it does not have to be read and compiled again.
It is on for Apache by default, but off for the command line, so every CLI run (a test
runner, a cron script) starts cold and reads and compiles every file it needs again.
Across the Windows mount that is most of its time.

The image switches it on for the CLI with a file cache in `/tmp/opcache`
(`/etc/php/8.6/cli/conf.d/99-opcache-cli.ini`), so each run reuses what the previous run
compiled. Timestamps are still checked, so an edited file is picked up on the next run. The
cache lives inside the container and starts empty when the container is recreated.

### What if it is still slow?

Stop crossing the filesystem boundary altogether. Docker's guidance for the WSL 2
backend is:

> Performance is much higher when files are bind-mounted from the Linux filesystem,
> rather than accessed from the Windows host filesystem.

Moving the project inside the WSL 2 distribution and mounting it from there avoids the
translation layer entirely. File change notifications (`inotify`) also only work for
files stored in the Linux filesystem, so editors, watchers and auto-reload behave better
there as well. See
[WSL 2 best practices](https://docs.docker.com/desktop/features/wsl/best-practices/).

### Why is --add-host=host.docker.internal:host-gateway needed?

It gives the container a name that resolves to the host system's IP, which is what
Xdebug connects back to. It is required **only on Linux** - on Windows Docker Desktop
provides `host.docker.internal` already.

### How do I run Composer or npm inside the container?

Open a shell in the running container and work from `/var/www/html`:

     docker exec -it ncompphp86dev /bin/bash

### How do I configure Xdebug in VS Code?

Install the PHP Debug (XDebug.org) extension, then add this to `launch.json`:

      {
          "name": "Listen for Xdebug",
          "type": "php",
          "request": "launch",
          "port": 9003,
          "pathMappings": {
              "/var/www/html": "${workspaceFolder}"
          }
      },

The `pathMappings` entry ensures that files inside the container are correctly mapped to
your VS Code project folder - without it, breakpoints will not bind.

> **In `v1.3.0` Xdebug is a 3.6.0 alpha build**, the first Xdebug with PHP 8.6
> support. If debugging misbehaves, suspect the alpha first. See
> [PHP 8.6 package notes](#php-86-package-notes).

### How do I clear the Docker build cache?

     docker builder prune
