# Visual Studio Code Remote Development for JUCE Plugins

This guide explains how to set up Visual Studio Code for cross-platform development of JUCE plugins, allowing you to edit code in WSL while building on Windows.

## Prerequisites

1. **On Windows:**
   - [Visual Studio 2019 Community Edition](https://visualstudio.microsoft.com/vs/older-downloads/) with C++ Desktop development workload
   - [Visual Studio Code](https://code.visualstudio.com/)
   - [WSL Extension for VSCode](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-wsl)

2. **In WSL:**
   - Basic development tools: `sudo apt install build-essential cmake git`

## Setup Steps

### 1. Install VSCode Extensions

Open VSCode and install these extensions:
- Remote - WSL
- C/C++
- CMake Tools

### 2. Configure Remote Development

1. Open VSCode
2. Click on the green remote indicator in the bottom-left corner
3. Select "Remote-WSL: New Window"
4. Navigate to your project in WSL
5. VSCode will open your project in WSL context

### 3. Configure Build Tasks

The included `.vscode/tasks.json` defines tasks to:
- Build on Windows
- Clean project
- Run on Windows

### 4. Build Workflow

1. Edit files in VSCode (connected to WSL)
2. Press Ctrl+Shift+B to select a build task
3. Choose "Build on Windows"
4. View results in the terminal panel

## How It Works

This setup leverages:
- WSL for Linux development experience
- Windows tools for actual compilation
- VSCode as the bridge between systems

The configuration runs Windows commands via `wsl.exe` from Windows, allowing seamless interaction between environments.

## Common Issues

- **Path Translation**: Windows paths in VSCode might need adjustment
- **Visual Studio Detection**: Ensure VSCode can find your Visual Studio installation
- **Permission Issues**: WSL files need appropriate permissions

## Additional Resources

- [VSCode Remote Development](https://code.visualstudio.com/docs/remote/remote-overview)
- [Microsoft's WSL Documentation](https://docs.microsoft.com/en-us/windows/wsl/)
- [JUCE Framework Documentation](https://juce.com/learn/documentation)