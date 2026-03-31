# MUGEM — Mugen Getsuga Tenshou Terminal

**Fork of Ghostty** — Universal bidirectional terminal for Tawhid execution.

## Core Concept

Ghostty + HarfBuzz + FriBidi + Tawhid Display Protocol = Mugem

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│ LAYER 5: MUGEM BRIDGE (Python)                              │
│ ├─ Zangetsu orchestrator                                  │
│ ├─ 12-agent spawn protocol                                  │
│ └─ LAWH.md visualization                                    │
├─────────────────────────────────────────────────────────────┤
│ LAYER 4: TAWHID DISPLAY                                     │
│ ├─ 5 verbosity modes (Fatiha → Mugetsu)                     │
│ ├─ Geometric encoding (when context permits)                │
│ └─ Compressed transmission (truncation guard)               │
├─────────────────────────────────────────────────────────────┤
│ LAYER 3: VARIABLE-WIDTH GRID                                │
│ ├─ Cell: grapheme + script + width + direction              │
│ ├─ Arabic: contextual shaping (initial/medial/final)        │
│ ├─ Japanese: tategaki mode (縦書き)                        │
│ └─ Chinese: han unification (CN/JP/KR variants)             │
├─────────────────────────────────────────────────────────────┤
│ LAYER 2: SHAPING ENGINE                                     │
│ ├─ HarfBuzz: glyph generation                               │
│ ├─ FriBidi: RTL/LTR resolution                              │
│ └─ ICU: script detection, locale data                     │
├─────────────────────────────────────────────────────────────┤
│ LAYER 1: GPU RASTERIZATION (Ghostty native)                 │
│ ├─ Metal (macOS) / OpenGL (Linux) / WebGL (WASM)          │
│ └─ Subpixel AA, infinite zoom, 4K+                          │
└─────────────────────────────────────────────────────────────┘
```

## Files Modified

### 1. build.zig — Dependencies
```zig
// Add HarfBuzz/FriBidi linking
const harfbuzz = b.addSystemIncludePath("/opt/homebrew/include");
const harfbuzz_lib = b.addLibraryPath("/opt/homebrew/lib");
exe.linkSystemLibrary("harfbuzz");
exe.linkSystemLibrary("fribidi");
```

### 2. src/renderer/Metal.zig — Text Shaping
```zig
// NEW: Shape text via HarfBuzz
const c = @cImport({
    @cInclude("harfbuzz/hb.h");
});

pub fn shapeLine(self: *Metal, text: []const u8) !ShapedLine {
    // 1. Detect scripts
    // 2. Split runs
    // 3. HarfBuzz shape each run
    // 4. Position glyphs
}
```

### 3. src/terminal/page.zig — Variable Cell
```zig
// Cell becomes variable-width
pub const Cell = struct {
    grapheme: [8]u8,        // UTF-8 storage
    len: u1,               // grapheme length
    width: u4,             // NEW: display width (1-4)
    direction: Direction,  // NEW: LTR/RTL/TTB
    script: Script,          // NEW: Latin, Arabic, Han, etc.
    style: Style,
};
```

### 4. src/mugem/ (NEW MODULE)
```
src/mugem/
├── main.zig        # Public API
├── bidi.zig        # Bidirectional layout
├── shape.zig       # HarfBuzz wrapper
├── display.zig     # Tawhid verbosity modes
└── bridge.zig      # Python IPC
```

## Key Features

### Bidirectional Text
```
Input:  "Hello مرحبا World"
Output: "Hello albahram World"  (visual, shaped)
              ↑ Arabic RTL, reshaped
```

### Vertical Japanese
```
無
限
月
牙
天
衝
```

### Atomic Clusters
```
Input:  "👨‍👩‍👧‍👦" (family emoji = 4 glyphs)
Width:  2.0 cells (not 1, not 4)
Render: Single graphene cluster
```

## Python Bridge

```python
# mugem/__init__.py
class MugemBridge:
    """Spawn agents in bidirectional terminal"""
    
    def spawn_wave(self, n: int = 12) -> list[Agent]:
        # Create 12 PTYs in mugem windows
        pass
    
    def render_bidi(self, text: str) -> list[Cell]:
        # Return shaped cells for mixed-script line
        pass
    
    def set_verbosity(self, mode: str):
        # fatiha, baqara, nahl, takwir, mugetsu
        pass
```

## Build Instructions

```bash
cd ~/Programming/mugem

# Install deps (macOS)
brew install harfbuzz fribidi icu4c

# Build with mugem support
zig build -Denable-mugem=true

# Test bidirectional
echo "English ثم Arabic" | ./zig-out/bin/mugem

# Test vertical
echo "無限月牙天衝" | ./zig-out/bin/mugem --tategaki
```

## Tawhid Display Modes

| Mode | Encoding | Use Case |
|------|----------|----------|
| Fatiha | Full Unicode shapes | Architecture, planning |
| Baqara | Moderate geometry | Normal execution |
| Nahl | Compact, functional | Fast execution |
| Takwir | ASCII-only | Context emergency |
| Mugetsu | Brutal minimal | Raw data, API limits |

## Integration with wahidOS

```python
# In getsuga.py — spawn in mugem
from mugem import MugemBridge

bridge = MugemBridge()
for i in range(12):
    agent = bridge.spawn_window()
    agent.execute(tasks[i])
    # Mugem handles bidi, vertical, mixed scripts
```

## Branch

- **mugetsu/wave-1**: Initial bidirectional support
- **mugetsu/tategaki**: Vertical Japanese
- **mugetsu/mask**: Tawhid display protocol
- **main**: Upstream Ghostty (rebase target)

## Status

- [x] Fork Ghostty
- [x] Create branch
- [ ] HarfBuzz integration
- [ ] Variable-width cells
- [ ] Bidi layout
- [ ] Python bridge
- [ ] Integration with getsuga.py

Bismillah. The crescent terminal awakens.
