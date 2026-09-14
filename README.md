# NCompPHPdev
NCompPHPdev Docker Containers

PHP development Docker containers with XDebug configured and working.

The following PHP modules are installed: mysql, cli, common, curl, gd, intl, ldap, mbstring, readline, xdebug, xml, zip sqlsrv and pdo_sqlsrv.

> **You are on the `php8.6` branch.** PHP 8.6 has not been released yet, so on this
> branch **xdebug, sqlsrv and pdo_sqlsrv are commented out** in the Dockerfile - the
> packages do not build against PHP 8.6 yet. See [Current status of the php8.6 branch](#current-status-of-the-php86-branch).

---

## How this repository works

### A branch per PHP version

Each PHP minor version has its own long-lived branch:

| Branch   | PHP | Base image     | Image tag            | Status                                |
| -------- | --- | -------------- | -------------------- | ------------------------------------- |
| `main`   | 8.5 | `ubuntu:24.04` | `v1.2.1`             | Current release - what gets published |
| `php8.6` | 8.6 | `ubuntu:26.04` | `v1.3.0` (unreleased) | In progress, PHP 8.6 is pre-release   |
| `php8.5` | 8.5 | `ubuntu:24.04` | `v1.2.0`, `v1.2.1`   | Merged to `main`                      |
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

So **PHP 8.6 will be released as `v1.3.0`**. The patch number is for fixes to an image
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

## Current status of the php8.6 branch

PHP 8.6 reaches General Availability on **2026-11-19**. Until then this branch tracks
the pre-release packages.

**Packages no longer come from `ppa:ondrej/php`.** Ondřej Surý has stopped adding new
Ubuntu LTS releases to the Launchpad PPA - it stops at `noble`/24.04. From Ubuntu 26.04
onwards the packages live at **`packages.sury.org`**, which is what the Dockerfile now
configures.

Blocking the merge to `main`:

| Item                    | Status                                                                 |
| ----------------------- | ---------------------------------------------------------------------- |
| `php8.6` + core modules | Working - currently `8.6.0~alpha1` from `packages.sury.org`             |
| `php8.6-xdebug`         | **Not available.** No package built yet, and released Xdebug 3.5.x refuses to build on PHP >= 8.6.0 |
| `sqlsrv` / `pdo_sqlsrv` | **Not available.** pecl 5.13.3 has not been built against PHP 8.6       |
| `msodbcsql18`           | Working - Microsoft publishes a `resolute` (26.04) build                |

Each of these is commented out in the [Dockerfile](Dockerfile) with the condition for
re-enabling it. Uncomment as upstream catches up, then merge to `main`.

---

## Getting Started

### Prerequisites
Ensure you have Docker installed on your system. These instructions were tested on **Ubuntu 26.04** and **Windows**.

---

### Pull docker image

The published image is built from `main`, so it is the **current release (PHP 8.5)**, not
this branch. For PHP 8.6, build locally instead - see the next section.

1. **Pull Docker image**

  - **Ubuntu**

        sudo docker pull ghcr.io/nielbuys/ncompphpdev:v1.2.1
    
  - **Windows**

        docker pull ghcr.io/nielbuys/ncompphpdev:v1.2.1

2. **Run the Docker container**

  - **Ubuntu**

        sudo docker run  -p 80:80 --add-host=host.docker.internal:host-gateway --name ncompphp85dev -d -v /var/www/html:/var/www/html ghcr.io/nielbuys/ncompphpdev:v1.2.1

  - **Windows**

        docker run  -p 80:80 --name ncompphp85dev -d -v C:/html:/var/www/html:delegated ghcr.io/nielbuys/ncompphpdev:v1.2.1

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

Explanation of the volume mapping (-v /var/www/html:/var/www/html):

- The first /var/www/html (before the colon :) is the path on your host machine.  
- The second /var/www/html (after the colon :) is the path inside the Docker container.

### Why PHP can feel slow on Windows, and what ":delegated" is for

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

If a project is large and still slow, the real fix is to stop crossing the boundary
altogether. Docker's guidance for the WSL 2 backend is:

> Performance is much higher when files are bind-mounted from the Linux filesystem,
> rather than accessed from the Windows host filesystem.

Moving the project inside the WSL 2 distribution and mounting it from there avoids the
translation layer entirely. File change notifications (`inotify`) also only work for
files stored in the Linux filesystem, so editors, watchers and auto-reload behave better
there as well. See
[WSL 2 best practices](https://docs.docker.com/desktop/features/wsl/best-practices/).


The --add-host=host.docker.internal:host-gateway option is required only on Linux systems.

Access your project in a browser: Open your browser and go to http://localhost. You should see the Apache test page.

Add your PHP files: Place your PHP files in the folder mapped on your host machine. These files will automatically be accessible inside the Docker container.

In my VS Code terminal, I execute the following Docker command to access the /var/www/html folder, where I run Composer and npm commands:

     docker exec -it ncompphp86dev /bin/bash

**Configuring VS Code with XDebug inside the "launch.json" file. PHP Debug (XDebug.org) vscode extension need to be installed.**

      {
          "name": "Listen for Xdebug",
          "type": "php",
          "request": "launch",
          "port": 9003,
          "pathMappings": {
              "/var/www/html": "${workspaceFolder}"
          }
      },

The pathMappings in launch.json ensure that files inside the container are correctly mapped to your VS Code project folder.

Clear Docker build caches "docker builder prune"
