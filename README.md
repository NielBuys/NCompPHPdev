# NCompPHPdev
NCompPHPdev Docker Containers

PHP development Docker containers with XDebug configured and working.

The following PHP modules are installed: mysql, cli, common, curl, gd, intl, ldap, mbstring, readline, xdebug, xml, zip, sqlsrv, and pdo_sqlsrv.

---

## Getting Started

### Prerequisites
Ensure you have Docker installed on your system. These instructions were tested on **Ubuntu 24.04**.

---

### Pull docker image

1. **Pull Docker image**

  - **Ubuntu**

          sudo docker pull ghcr.io/nielbuys/ncompphpdev:v1.1.0
    
  - **Windows**

          docker pull ghcr.io/nielbuys/ncompphpdev:v1.1.0

2. **Run the Docker container**

  - **Ubuntu**

          sudo docker run  -p 80:80 --add-host=host.docker.internal:host-gateway --name ncompphp85dev -d -v /var/www/html:/var/www/html ghcr.io/nielbuys/ncompphpdev:v1.1.0

  - **Windows**

          docker run  -p 80:80 --name ncompphp85dev -d -v C:/html:/var/www/html ghcr.io/nielbuys/ncompphpdev:v1.1.0

### How to Build and Run the Docker Container

1. **Open a terminal and navigate to your project folder.**

2. **Build the Docker image**

  - **Ubuntu:**

          sudo docker build -t ncompphp85dev .

  - **Windows:**

          docker build -t ncompphp85dev .

3. **Run the Docker container:**

  - **Ubuntu:**

          sudo docker run  -p 80:80 --add-host=host.docker.internal:host-gateway --name ncompphp85dev -d -v /var/www/html:/var/www/html ncompphp84dev

  - **Windows**

          docker run  -p 80:80 --name ncompphp85dev -d -v C:/html:/var/www/html ncompphp85dev

## Notes

Explanation of the volume mapping (-v /var/www/html:/var/www/html):

- The first /var/www/html (before the colon :) is the path on your host machine.  
- The second /var/www/html (after the colon :) is the path inside the Docker container.

The --add-host=host.docker.internal:host-gateway option is required only on Linux systems.

Access your project in a browser: Open your browser and go to http://localhost. You should see the Apache test page.

Add your PHP files: Place your PHP files in the folder mapped on your host machine. These files will automatically be accessible inside the Docker container.

In my VS Code terminal, I execute the following Docker command to access the /var/www/html folder, where I run Composer and npm commands:

     docker exec -it ncompphp85dev /bin/bash

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
