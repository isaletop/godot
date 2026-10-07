# 🚀 Fly Mode Camera for Godot

A simple and reusable **fly mode camera controller** for Godot Engine.
Perfect for debug cameras, editors, or free exploration in 3D scenes.

---

## ✨ Features

- Toggle fly mode with a single key
- Smooth mouse look (FPS-style camera)
- 6-direction movement (WASD + vertical)
- Speed boost with Shift
- Mouse capture when active
- Lightweight and easy to integrate

---

## 🎮 Controls

| Key | Action |
|-----|--------|
| `F` | Toggle fly mode |
| `Mouse` | Look around |
| `W / S` | Move forward / backward |
| `A / D` | Move left / right |
| `Q / E` | Move down / up |
| `Shift` | Increase movement speed |

---

## 📦 Installation

1. Add the script to your project
2. Attach it to a `Camera3D` node
3. Run the scene

---

## ⚙️ Configuration

You can tweak these exported variables:

```gdscript
@export var speed: float = 10.0
@export var sensitivity: float = 0.1
@export var fast_speed_multiplier: float = 3.0
```

- speed – base movement speed
- sensitivity – mouse look sensitivity
- fast_speed_multiplier – speed boost when holding Shift

## 🧠 How It Works
Press F to enable fly mode
Mouse is captured for camera rotation
Movement is based on the camera's local axes (basis)
Rotation is clamped to prevent flipping

## 🛠️ Use Cases
Debug camera
Level design tools
Free-roam exploration
Prototyping 3D movement

## 📜 License
MIT — use it however you want.
