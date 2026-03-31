# MUGEM Build Instructions

## Manual Steps (Not Automated)

### 1. Link HarfBuzz/FriBidi

Add to build.zig (find lib_ghostty or similar):

```zig
// After lib_ghostty.create(...)
lib_ghostty.linkSystemLibrary("harfbuzz", {});
lib_ghostty.linkSystemLibrary("fribidi", {});
```

Or add via CLI:
```bash
zig build -lharfbuzz -lfribidi
```

### 2. Install System Dependencies

macOS:
```bash
brew install harfbuzz fribidi
```

Ubuntu:
```bash
apt-get install libharfbuzz-dev libfribidi-dev
```

### 3. Module Registration

src/mugem.zig needs to be added to Ghostty's module system.

Find where other modules are registered and add:
```zig
const mugem = @import("mugem");
```

### 4. Python Bridge

Create python/mugem/__init__.py:
```python
import ctypes
mugem_lib = ctypes.CDLL("./zig-out/lib/libmugem.dylib")
mugem_lib.mugem_version.restype = ctypes.c_char_p
```

### 5. Test Build

```bash
cd ~/Programming/mugem
zig build -Doptimize=ReleaseFast
./zig-out/bin/ghostty --version
```

## Current Status

- src/mugem.zig: ✓ Created
- src/mugem/harfbuzz.zig: ✓ Created  
- src/mugem/bidi.zig: ✓ Created
- src/mugem/display.zig: ✓ Created
- build.zig modification: Manual (see above)
- System linking: Manual (platform dependent)

## Verification

After linking succeeds, test:
```bash
echo "Hello مرحبا World" | ./mugem --test-bidi
```
