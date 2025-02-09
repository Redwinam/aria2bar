# Hammerspoon Aria2 Monitor

A menubar tool for monitoring Aria2 downloads on macOS using Hammerspoon.

## Features

- Real-time download speed monitoring in menubar
- Display active, waiting, and completed downloads
- Control downloads (pause/resume/delete)
- Open download folder directly
- Clean and minimal interface

## Requirements

- macOS
- [Hammerspoon](https://www.hammerspoon.org/)
- Aria2 with RPC enabled

## Installation

1. Install Hammerspoon if you haven't already:

   ```bash
   brew install hammerspoon
   ```

2. Install Aria2:

   ```bash
   brew install aria2
   ```

3. Clone this repository to your Hammerspoon configuration directory:

   ```bash
   git clone https://github.com/Redwinam/hammerspoon-aria2-monitor.git ~/.hammerspoon/aria2
   ```

4. Add the following to your `~/.hammerspoon/init.lua`:

   ```lua
   require('aria2')
   ```

5. Reload Hammerspoon configuration

## Configuration

Make sure Aria2 is running with RPC enabled. You can start it with:

```bash
aria2c --enable-rpc --rpc-listen-all=false --rpc-listen-port=16800 --rpc-secret=YOUR_SECRET
```

## Usage

- Click the menubar icon to see all downloads
- Active downloads show progress and speed
- Completed downloads show file size and completion time
- Right-click on a download to:
  - Pause/Resume download
  - Open containing folder
  - Delete download or its record

## License

This work is licensed under a [Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License](http://creativecommons.org/licenses/by-nc-sa/4.0/).

[![CC BY-NC-SA 4.0](https://i.creativecommons.org/l/by-nc-sa/4.0/88x31.png)](http://creativecommons.org/licenses/by-nc-sa/4.0/)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
