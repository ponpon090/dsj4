# DSJ4 - Deluxe Ski Jump 4

A ski jumping simulator built with Godot Engine 4.x.

## Requirements
- Godot Engine 4.3+

## How to Run
1. Open Godot Engine 4.3+
2. Import the project (select the project.godot file)
3. Press F5 or click Run

## Controls
- **Arrow Up / W** - Crouch (gain speed on slope)
- **Space / Arrow Up** - Jump at takeoff
- **Arrow Left/Right** - Balance during flight
- **Arrow Down** - Landing position

## Game Features
- Realistic ski jump physics (gravity, air resistance, wind)
- Multiple hill configurations: K60, K90, K120, K185
- Wind system affecting flight
- HUD with speed, height, distance, wind info
- Leaderboard with top 10 scores saved to JSON
- Settings (audio, graphics, difficulty)

## Project Structure
- `scenes/` - All game scenes
- `scripts/` - Standalone GDScript files
- `resources/` - Hill configs and materials
