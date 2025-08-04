# Assembly Labyrinth

Assembly Labyrinth is a maze game written in a mix of **AArch64 Assembly** and **C** using **SDL2** for rendering and input handling.  
The player navigates through multiple labyrinth levels, starting from a given position and aiming to reach the goal tile.

## Features

- **10 unique levels** with walls, empty spaces, start, and goal tiles.
- Written in **AArch64 Assembly** for game logic and state handling.
- **C with SDL2** handles rendering and input.
- Smooth movement and collision detection.
- Automatic level progression upon reaching the goal.
- Reset the current level with `R` key.
- Escape the game with `ESC` key.

## Requirements

- AArch64-based system (e.g., Apple Silicon Mac).
- [SDL2](https://libsdl.org/) installed via Homebrew or package manager.
- Clang or GCC compiler with AArch64 support.

### Install SDL2 (macOS / Homebrew)
```bash
brew install sdl2
```

## Build Instructions

```bash
# Clone the repository
git clone https://github.com/metehankaygsz/assembly-labyrinth-aarch64.git
cd assembly-labyrinth

# Build the project
make

# Run the game
./labyrinth
```

## Controls

| Key         | Action                |
|-------------|-----------------------|
| Arrow Keys  | Move                  |
| W/A/S/D     | Move                  |
| I/J/K/L     | Move                  |
| R           | Reset current level   |
| ESC         | Quit game             |

## Level Tiles

| Value | Description |
|-------|-------------|
| `0`   | Empty space |
| `1`   | Wall        |
| `2`   | Goal        |
| `3`   | Start       |

## File Structure

```
src/
  ├── main.c         # SDL2 rendering and input
  ├── game.S         # Assembly game logic
  ├── levels.inc     # 10 level definitions
Makefile             # Build configuration
```

## Screenshot

![Game Screenshot](screenshot.png)

