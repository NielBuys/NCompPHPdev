# NCompPHPdev
NCompPHPdev Docker Containers

PHP development Docker containers with XDebug configured and working.

The following PHP modules is installed  
mysql, cli, common, curl, gd, imap, intl, ldap, mbstring, opcache, readline, xdebug, xml, zip, sqlsrv and pdo_sqlsrv

---

## Getting Started

### Prerequisites
Ensure you have Docker installed on your system. These instructions were tested on **Ubuntu 24.04**.

---

### Pull docker image

1. **Pull Docker image**

       sudo docker pull ghcr.io/nielbuys/ncompphpdev:v1.0.1

2. **Run the Docker container**

       sudo docker run  -p 80:80 --add-host=host.docker.internal:host-gateway --name ncompphp83dev -d -v /var/www/html:/var/www/html ghcr.io/nielbuys/ncompphpdev:v1.0.1

### How to Build and Run the Docker Container

1. **Open a terminal and navigate to your project folder.**

2. **Build the Docker image:**

       sudo docker build -t ncompphp83dev .

3. **Run the Docker container:**

       sudo docker run  -p 80:80 --add-host=host.docker.internal:host-gateway --name ncompphp83dev -d -v /var/www/html:/var/www/html ncompphp83dev

## Notes

Explanation of the volume mapping (-v /var/www/html:/var/www/html):

- The first /var/www/html (before the colon :) is the path on your host machine.  
- The second /var/www/html (after the colon :) is the path inside the Docker container.

The --add-host=host.docker.internal:host-gateway option is required only on Linux systems.

Access your project in a browser: Open your browser and go to http://localhost. You should see the Apache test page.

Add your PHP files: Place your PHP files in the folder mapped on your host machine. These files will automatically be accessible inside the Docker container.

**Configuring VS Code with XDebug**

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
