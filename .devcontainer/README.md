# Development Environment Guide

Welcome to the development environment for this course! This guide will help you understand how your development environment works, what services are available to you, and how to troubleshoot common issues.

## What is This Development Environment?

Your development environment is a fully-configured, consistent workspace that runs inside VS Code. Think of it as a complete computer setup that has all the tools, libraries, and services you need for this course already installed and configured. Every student gets an identical environment, which means code that works on your machine will work on your classmates' machines too.

When you open this project in VS Code and start the development environment, several things happen automatically behind the scenes. Your code editor connects to a specialized workspace that includes Python, Node.js, database tools, and other essential software. More importantly, it also starts up dedicated services like PostgreSQL and Redis that your applications will use to store and retrieve data.

## Architecture Overview

The following diagram shows how your development environment connects to the available services:

```mermaid
flowchart TB
    subgraph VSCode["VS Code on Your Computer"]
        Editor["VS Code Editor"]
    end
    
    subgraph DevEnv["Development Environment"]
        direction TB
        Workspace["Your Code & Terminal"]
        Python["Python 3.x"]
        Node["Node.js & npm"]
        Git["Git"]
        Tools["Development Tools"]
    end
    
    subgraph Services["Available Services"]
        direction LR
        Postgres["PostgreSQL Database<br/>(dev_pg:5432)<br/>User: app<br/>Password: app<br/>Database: db"]
        Redis["Redis Cache<br/>(dev_redis:6379)"]
    end
    
    Editor -.->|Remote Connection| Workspace
    Workspace <-->|Database Queries| Postgres
    Workspace <-->|Cache Operations| Redis
    
    classDef service fill:#e1f5ff,stroke:#0066cc,stroke-width:2px;
    classDef env fill:#f0f0f0,stroke:#666,stroke-width:2px;
    class Postgres,Redis service;
    class Workspace,Python,Node,Git,Tools env;
```

## Understanding the Services

Your development environment includes two essential services that your applications will interact with: PostgreSQL and Redis. These services are always running and ready to accept connections whenever your development environment is active.

### PostgreSQL Database Service

PostgreSQL is a powerful relational database system that stores structured data in tables with rows and columns. You'll use PostgreSQL to store persistent data for your applications—things like user accounts, blog posts, product catalogs, or any other information that needs to survive when your application restarts.

The PostgreSQL service is accessible at the hostname **dev_pg** on port **5432**. Here are the default credentials you'll use to connect:

- **Hostname:** dev_pg
- **Port:** 5432
- **Username:** app
- **Password:** app
- **Database Name:** db

Think of these credentials as the "login information" for your database. When your application needs to save or retrieve data, it will use these credentials to establish a connection to PostgreSQL.

### Redis Cache Service

Redis is an in-memory data store that excels at fast read and write operations. Unlike PostgreSQL, which stores data on disk for long-term persistence, Redis keeps data in memory for quick access. You'll typically use Redis for caching frequently accessed data, storing session information, managing real-time features, or implementing task queues.

The Redis service is accessible at the hostname **dev_redis** on port **6379**. Redis doesn't require a password in this development environment, making it simple to connect and use.

- **Hostname:** dev_redis
- **Port:** 6379
- **Password:** (none required)

Because Redis stores data in memory, anything you store there will be lost when the Redis service restarts. This is intentional as Redis is designed for temporary, fast-access data rather than permanent storage.

## Connecting to Services from the Command Line

You can interact with both PostgreSQL and Redis directly from your terminal, which is helpful for testing connections, inspecting data, or running administrative commands.

### Accessing the VS Code Terminal

Your development environment includes a built-in terminal that gives you direct command-line access to all the tools and services. The terminal is integrated into VS Code, making it easy to run commands without switching between applications.

**Opening the Terminal:**
- **Menu:** Go to Terminal → New Terminal
- **Keyboard shortcut:** Ctrl+` (backtick) on Windows/Linux, or Cmd+` on Mac
- **Command Palette:** Press Ctrl+Shift+P (Cmd+Shift+P on Mac), type "Terminal: Create New Terminal"

**Using Multiple Terminals:**
You can have multiple terminal sessions open simultaneously. Click the "+" icon in the terminal panel to create additional terminals, or use Ctrl+Shift+` to open a new terminal quickly.

**Terminal Features:**
- **Tab completion:** Press Tab to auto-complete file names and commands
- **Command history:** Use up/down arrow keys to navigate through previous commands
- **Copy/paste:** Ctrl+C and Ctrl+V work normally (Cmd+C/Cmd+V on Mac)
- **Clear screen:** Type `clear` or press Ctrl+L to clear the terminal output

The terminal runs in your development environment, so all the pre-installed tools (python3, git, psql, redis-cli, etc.) are available on the PATH and ready to use.

### Testing PostgreSQL Connection

To verify that PostgreSQL is running and accessible, open a terminal in VS Code and run:

```bash
PGPASSWORD=app psql -h dev_pg -U app -d db -c "SELECT version();"
```

This command connects to the database and queries the PostgreSQL version. If successful, you'll see detailed version information printed to your terminal. The `PGPASSWORD=app` part provides the password for this single command without storing it permanently. Type `q` to close the terminal output.

To start an interactive PostgreSQL session where you can run multiple queries:

```bash
PGPASSWORD=app psql -h dev_pg -U app -d db
```

Once connected, you'll see a `db=#` prompt where you can type SQL commands. For example, try:

```sql
\dt              -- List all tables
\l               -- List all databases
\q               -- Quit and return to bash
```

### Testing Redis Connection

To verify that Redis is running and accessible, use the Redis command-line client:

```bash
redis-cli -h dev_redis PING
```

You should see `PONG` as the response, confirming that Redis is active and responding to commands. To start an interactive Redis session:

```bash
redis-cli -h dev_redis
```

At the Redis prompt, you can try some basic commands:

```
SET mykey "Hello"     -- Store a value
GET mykey             -- Retrieve a value
KEYS *                -- List all keys
DEL mykey             -- Delete a key
QUIT                  -- Exit Redis CLI
```

## Using Services in Your Applications

When writing application code, you'll typically use connection strings or configuration objects to connect to these services. Here are examples of how to set this up in your applications.

### Python Applications

For Python applications using PostgreSQL, you might use a library like `psycopg2` or `asyncpg`. Here's how you'd construct a connection string:

```python
DATABASE_URL = "postgresql://app:app@dev_pg:5432/db"
```

For Redis in Python using the `redis` library:

```python
import redis
r = redis.Redis(host='dev_redis', port=6379, decode_responses=True)
```

### Environment Variables

It's a good practice to store connection information in environment variables. You have several options for managing these variables in your development environment.

#### Using a .env File

The most convenient approach is to create a `.env` file in your project root directory. This file stores your environment variables and can be loaded automatically by many applications:

```bash
# Create a .env file in your project root
cat > .env << EOF
DATABASE_URL=postgresql://app:app@dev_pg:5432/db
REDIS_URL=redis://dev_redis:6379/0
DB_HOST=dev_pg
DB_PORT=5432
DB_USERNAME=app
DB_PASSWORD=app
DB_NAME=db
REDIS_HOST=dev_redis
REDIS_PORT=6379
EOF
```

Your `.env` file should look like this:

```
DATABASE_URL=postgresql://app:app@dev_pg:5432/db
REDIS_URL=redis://dev_redis:6379/0
DB_HOST=dev_pg
DB_PORT=5432
DB_USERNAME=app
DB_PASSWORD=app
DB_NAME=db
REDIS_HOST=dev_redis
REDIS_PORT=6379
```

**Security Warning:** Never share, distribute, or commit your `.env` file to version control if it contains passwords, API keys, or other sensitive information. Even though these are development credentials, it's important to develop secure habits early.

**Important:** Always add `.env` to your `.gitignore` file to prevent accidentally committing credentials to version control:

```bash
echo ".env" >> .gitignore
```

#### Loading .env Files in Python

Use the `python-dotenv` package to automatically load variables from your `.env` file:

```bash
pip install python-dotenv
```

Then in your Python code:

```python
import os
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

DATABASE_URL = os.getenv('DATABASE_URL')
REDIS_URL = os.getenv('REDIS_URL')

# Or access individual components
DB_HOST = os.getenv('DB_HOST')
DB_PASSWORD = os.getenv('DB_PASSWORD')
DB_NAME = os.getenv('DB_NAME')
```

#### Setting Variables in Terminal

You can also set environment variables directly in your terminal session:

```bash
export DATABASE_URL="postgresql://app:app@dev_pg:5432/db"
export REDIS_URL="redis://dev_redis:6379/0"
export DB_PASSWORD="app"
```

Then access them in your Python code:

```python
import os
DATABASE_URL = os.getenv('DATABASE_URL')
REDIS_URL = os.getenv('REDIS_URL')
DB_PASSWORD = os.getenv('DB_PASSWORD')
```

Note that variables set this way only persist for the current terminal session.

## Troubleshooting Common Issues

Even with a pre-configured environment, you may occasionally encounter issues. This section covers the most common problems and their solutions.

### Development Environment Won't Start

**Problem:** VS Code shows an error when trying to open the development environment, or the environment fails to start completely.

**Solutions:**
- Make sure you have the "Dev Containers" extension installed in VS Code. Check the Extensions panel (Ctrl+Shift+X or Cmd+Shift+X) and search for "Dev Containers".
- Try rebuilding the environment: Open the Command Palette (Ctrl+Shift+P or Cmd+Shift+P) and run "Dev Containers: Rebuild Container".
- If rebuilding doesn't work, try "Dev Containers: Rebuild Container Without Cache" which forces a complete rebuild.
- Ensure you have enough disk space. Development environments can require several gigabytes of space.
- Check that no other instances of this project are already running. Close all VS Code windows for this project and try again.

### Cannot Connect to PostgreSQL (dev_pg)

**Problem:** Your application or command-line tools report errors like "could not connect to server" or "host not found: dev_pg".

**Solutions:**
- Verify the service is running by checking if you can ping it: `ping -c 3 dev_pg`
- If the hostname doesn't resolve, you may need to restart the development environment. Close and reopen the window in the development environment.
- Check that you're using the correct credentials: username `app`, password `app`, database `db`.
- Ensure you're using the correct hostname `dev_pg`, not `localhost` or `127.0.0.1`.
- If `psql` command is not found, the PostgreSQL client tools may not be installed. Run: `sudo apt-get update && sudo apt-get install -y postgresql-client`

### Cannot Connect to Redis (dev_redis)

**Problem:** Redis commands fail with connection errors or the hostname is not found.

**Solutions:**
- Test basic connectivity: `redis-cli -h dev_redis PING`
- If the hostname doesn't resolve, restart the development environment.
- Ensure you're using hostname `dev_redis`, not `localhost`.
- If `redis-cli` is not available, install it: `sudo apt-get update && sudo apt-get install -y redis-tools`
- Remember that Redis data is temporary and will be cleared when the service restarts. This is normal behavior.

### Python Interpreter Issues

**Problem:** VS Code doesn't recognize Python commands, shows import errors for installed packages, or uses the wrong Python version.

**Solutions:**
- Check which Python interpreter VS Code is using: Open a Python file and look at the bottom-right corner of VS Code where it shows the Python version.
- Select the correct interpreter: Click on the Python version in the bottom-right, or open Command Palette and run "Python: Select Interpreter".
- The development environment includes Python 3.x. Make sure you're using `python` and `pip` commands in the terminal.
- If packages are missing, verify you're installing them with the correct pip: `pip install package-name`
- Create a virtual environment if your project requires isolated dependencies: `python -m venv .venv` then activate it with `source .venv/bin/activate`

### Import Errors in Python

**Problem:** Your code shows errors like "ModuleNotFoundError" or "No module named 'xyz'" even though you installed the package.

**Solutions:**
- Verify the package is installed: `pip list | grep package-name`
- Make sure you installed packages using the same Python interpreter that VS Code is using. Check the interpreter in the bottom-right of VS Code.
- If using a virtual environment, make sure it's activated. You should see `(.venv)` or similar at the start of your terminal prompt.
- Try reinstalling the package: `pip install --force-reinstall package-name`
- Check that your workspace folder is correct. Python's import system is sensitive to working directories.
- Some language features require the language server to be restarted after installing new packages. Use Command Palette → "Python: Restart Language Server" if you're experiencing import errors after installing packages.

### Permission Denied Errors

**Problem:** Commands fail with "permission denied" errors when trying to install packages or modify files.

**Solutions:**
- For system-wide package installation, you may need sudo: `sudo apt-get install package-name`
- For Python packages, avoid using `sudo` with pip. Instead, use user installation: `pip install --user package-name`
- If you're getting permission errors on your own project files, the file permissions may have been corrupted. Check with `ls -la` and fix with `chmod`.
- Remember that some directories are protected for security. Install development tools in your home directory or project workspace.

### Terminal Commands Not Found

**Problem:** Common commands like `git`, `curl`, or development tools report "command not found".

**Solutions:**
- Many tools are pre-installed. Try the full path: `/usr/bin/git` or search for it with `which git`.
- If a tool is genuinely missing, you can install it: `sudo apt-get update && sudo apt-get install tool-name`
- Check if the command is available but not in your PATH: `find /usr -name "command-name" 2>/dev/null`
- After installing new tools, you may need to reload your shell: `source ~/.bashrc`

### Port Already in Use

**Problem:** Your application fails to start with errors like "address already in use" or "port 8000 is already allocated".

**Solutions:**
- Check what's using the port: `lsof -i :8000` (replace 8000 with your port number)
- Kill the process using the port: Find the PID from `lsof` output and run `kill -9 PID`
- Choose a different port for your application if the port conflict persists.

### VS Code Extensions Not Working

**Problem:** Extensions don't seem to be active, or language features like autocomplete aren't working.

**Solutions:**
- Some extensions need to be installed separately for the development environment. Check the Extensions panel and look for a "Install in Dev Container" button.
- Reload the window: Command Palette → "Developer: Reload Window"
- Check the extension's output logs: View → Output, then select the extension from the dropdown.
- Some extensions require specific settings. Check the extension's documentation for required configuration.

### Files Not Saving or Changes Not Appearing

**Problem:** You save files but changes don't seem to take effect, or files appear empty.

**Solutions:**
- Check if there are any error notifications in VS Code (bottom-right corner).
- Verify you have write permissions: `ls -la filename`
- Make sure you're editing files inside your workspace directory, not in system directories.
- Try closing and reopening the file.
- Check your disk space: `df -h`

### Slow Performance

**Problem:** The development environment feels sluggish or commands take a long time to execute.

**Solutions:**
- Check your computer's available resources. Development environments require adequate RAM (at least 4GB recommended).
- Close unnecessary applications on your host computer.
- If running on Windows, ensure WSL 2 is being used (faster than WSL 1).
- Large Git repositories can slow things down. Consider using Git's sparse-checkout for huge repositories.
- Disable unnecessary VS Code extensions that might be scanning files in the background.

### Cloud Storage Folder Issues

**Problem:** The development environment or file operations feel extremely slow, especially when opening files, saving changes, or running commands.

**Possible Cause:** If your project folder is located inside a cloud storage directory (Google Drive, iCloud, OneDrive, Dropbox), this can significantly impact performance and cause various issues.

**Why This Happens:**
- **File sync conflicts:** Cloud storage services continuously monitor and sync file changes, which can interfere with the development environment's file operations
- **Network overhead:** Every file read/write may trigger network activity as the cloud service tries to sync changes
- **Lock conflicts:** Cloud storage and the development environment may compete for file access, causing delays or errors
- **Excessive disk I/O:** Cloud sync services can cause high disk usage, slowing down all file operations
- **Hidden files and metadata:** Development environments create many temporary and configuration files that cloud services attempt to sync unnecessarily

**Solutions:**
- **Move your project folder** to a local directory outside of any cloud storage folders:
  ```bash
  # Example: move from cloud storage to local directory
  mkdir ~/projects
  mv "/Users/yourname/Google Drive/my-project" ~/projects/my-project
  ```
- **Exclude development folders** from cloud sync if you must keep projects in cloud storage:
  - **OneDrive:** Right-click folder → "Always keep on this device" → "Free up space"
  - **Google Drive:** Right-click folder → "Available offline" (uncheck)
  - **iCloud:** Move projects to a folder outside of `~/Documents` or `~/Desktop`
  - **Dropbox:** Use selective sync to exclude development folders

**Prevention:**
- Keep active development projects in local directories like `~/projects` or `~/dev`
- Only sync completed projects or source code (not entire development environments) to cloud storage
- Use Git repositories with cloud hosting (GitHub, GitLab) for code backup instead of file sync services


## Best Practices

To make the most of your development environment, keep these practices in mind:

**Save your work frequently.** Your code files are persisted between sessions, but any data in Redis and uncommitted changes could be lost if something goes wrong. Commit your work to Git regularly.

**Use version control.** Git is pre-installed and ready to use. Commit your changes often and push to a remote repository to ensure your work is backed up.

**Keep your environment clean.** If you install additional packages or tools, document them in a `requirements.txt` file (for Python) or similar so that others can recreate your setup.

**Test database connections early.** When starting a new project that uses PostgreSQL or Redis, test the connection first with the command-line tools before writing application code. This helps you catch configuration issues early.

**Read error messages carefully.** Error messages often tell you exactly what's wrong. Take time to read the full error message rather than just the first line.

**Don't modify service credentials.** The default credentials (username `app`, password `app`) are meant for this development environment. In real-world production systems, you would use strong, unique passwords.

## Getting Help

If you encounter issues not covered in this troubleshooting guide:

1. **Check the course discussion forum.** Other students may have experienced similar issues.
2. **Review error messages carefully.** Copy the exact error message when asking for help.
3. **Describe what you were trying to do.** "I ran command X and expected Y but got Z instead."
4. **Contact your instructor or TA.** Provide specific details about the error, what you've tried, and any error messages.

## Appendix: Installed Tools and Software

Your development environment comes with a comprehensive set of tools pre-installed and ready to use. This appendix lists the most important ones.

### Programming Languages and Runtimes

- **Python 3.x** - Primary programming language with pip package manager
  - Command: `python3 --version`
  - Package manager: `pip`
  
- **Node.js** - JavaScript runtime with npm package manager
  - Command: `node --version`
  - Package manager: `npm --version`

### Version Control

- **Git** - Distributed version control system
  - Command: `git --version`
  - Pre-configured for command-line use

### Database and Cache Clients

- **psql** - PostgreSQL interactive terminal
  - Command: `psql --version`
  - Used to connect to the dev_pg database service
  
- **redis-cli** - Redis command-line interface
  - Command: `redis-cli --version`
  - Used to connect to the dev_redis cache service

### Development Tools

- **curl** - Command-line tool for transferring data with URLs
  - Command: `curl --version`
  - Useful for testing HTTP APIs
  
- **wget** - Network downloader
  - Command: `wget --version`
  
- **ssh** - Secure shell client
  - Command: `ssh -V`
  
- **rsync** - Fast file synchronization tool
  - Command: `rsync --version`

### Build and Archive Tools

- **zip/unzip** - Archive compression tools
  - Commands: `zip --version`, `unzip -v`
  
- **tar** - Tape archive utility
  - Command: `tar --version`
  
- **gzip, bzip2, xz** - Compression utilities
  - Commands: `gzip --version`, `bzip2 --version`, `xz --version`

### System Utilities

- **grep** - Search text using patterns
  - Command: `grep --version`
  
- **find** - Search for files in a directory hierarchy
  - Command: `find --version`
  
- **tree** - Display directory structure
  - Command: `tree --version`
  
- **lsof** - List open files and network connections
  - Command: `lsof -v`
  
- **netstat** - Network statistics
  - Command: `netstat --version`
  
- **ps** - Process status
  - Command: `ps --version`
  
- **top** - Display system processes
  - Command: `top -v`

### Package Management

- **apt** - Debian package manager
  - Command: `apt --version`
  - Use with sudo to install additional system packages
  
- **dpkg** - Debian package handler
  - Command: `dpkg --version`

### Editors and Text Processing

- **nano** - Simple text editor
  - Command: `nano --version`
  
- **vim** - Advanced text editor
  - Command: `vim --version`

### Security and Encryption

- **gpg** - GNU Privacy Guard
  - Command: `gpg --version`
  - Used for encryption and signing

### Network Tools

- **ping** - Test network connectivity
  - Command: `ping -V`
  
- **netcat (nc)** - Network utility for TCP/UDP connections
  - Command: `nc -h`

### Additional Python Tools

Many Python packages can be installed as needed using `pip`. Common ones for this course might include:

- **FastAPI** - Modern web framework
- **SQLAlchemy** - SQL toolkit and ORM
- **psycopg2** - PostgreSQL adapter for Python
- **redis** - Redis client for Python
- **pytest** - Testing framework
- **requests** - HTTP library

To see all installed Python packages: `pip list`

### Pre-installed VS Code Extensions

Your development environment comes with several VS Code extensions pre-installed to enhance your development experience:

#### Language and Development Extensions

- **Python** (`ms-python.python`) - Comprehensive Python language support with IntelliSense, debugging, and code formatting
- **Pylance** (`ms-python.vscode-pylance`) - Fast, feature-rich Python language server with type checking
- **JavaScript and TypeScript** (`ms-vscode.vscode-typescript-next`) - Enhanced JavaScript and TypeScript language support
- **ESLint** (`dbaeumer.vscode-eslint`) - JavaScript and TypeScript linting to catch errors and enforce code style

#### Database and Development Tools

- **PostgreSQL** (`ms-ossdata.vscode-postgresql`) - Connect to and query PostgreSQL databases directly from VS Code
- **Thunder Client** (`rangav.vscode-thunder-client`) - Lightweight REST API client for testing HTTP endpoints
- **Docker** (`ms-azuretools.vscode-docker`) - Build, manage, and deploy containerized applications

#### Code Quality and Formatting

- **Prettier** (`esbenp.prettier-vscode`) - Automatic code formatting for JavaScript, TypeScript, JSON, and more
- **GitLens** (`eamodio.gitlens`) - Enhanced Git capabilities with blame annotations, commit history, and repository insights

#### Additional Utilities

- **Live Server** (`ritwickdey.liveserver`) - Launch a local development server with live reload for static and dynamic pages
- **Markdown All in One** (`yzhang.markdown-all-in-one`) - Enhanced Markdown editing with preview, table of contents, and shortcuts

#### Viewing Installed Extensions

To see all extensions currently available in your development environment:
1. Open the Extensions panel (Ctrl+Shift+X or Cmd+Shift+X)
2. View the "Installed" section to see all active extensions
3. Extensions with a gear icon can be configured through VS Code settings

Any additional extensions you install will persist in your development environment between sessions.

---

**Document Version:** 2.0
**Last Updated:** October 2025

This development environment is designed to provide you with everything you need for this course. Focus on writing great code, and let the environment handle the infrastructure details!
