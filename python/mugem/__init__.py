"""Python bridge for Mugem bidirectional terminal."""
import ctypes
import os
import socket
from pathlib import Path

__version__ = "0.2.0-12worktrees"

class MugemConfig:
    """5 Tawhid verbosity modes."""
    FATIHA = 0   # Maximum presence
    BAQARA = 1   # Balanced
    NAHL = 2     # Compact
    TAKWIR = 3   # Minimal
    MUGETSU = 4  # Moonless
    
    MIN_FIVES = [5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60]
    CHECKPOINTS = [1, 2, 3, 4, 5, 6, 7]

class MugemBridge:
    """Connects Python getsuga.py to Mugem Zig terminal."""
    
    def __init__(self, socket_path: str = "/tmp/mugem.sock"):
        self.socket_path = socket_path
        self.connected = False
    
    def connect(self) -> bool:
        """Connect to Mugem daemon."""
        try:
            self.socket = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            self.socket.connect(self.socket_path)
            self.connected = True
            return True
        except FileNotFoundError:
            # Daemon not running, use fallback
            return False
    
    def spawn_window(self, worktree: str, command: list) -> dict:
        """Spawn terminal window for agent."""
        if not self.connected:
            return {"status": "fallback", "worktree": worktree}
        
        # Send spawn request to Mugem daemon
        req = {
            "cmd": "spawn",
            "worktree": worktree,
            "command": command,
            "mode": MugemConfig.MUGETSU  # Default to compressed
        }
        
        self.socket.send(json.dumps(req).encode())
        resp = self.socket.recv(1024).decode()
        return json.loads(resp)
    
    def close(self):
        if self.connected:
            self.socket.close()
            self.connected = False

def test_import():
    """Verify mugem module loads."""
    print(f"Mugem Python bridge v{__version__}")
    print(f"5 modes: Fatiha={MugemConfig.FATIHA} to Mugetsu={MugemConfig.MUGETSU}")
    print(f"12 fives: {MugemConfig.MIN_FIVES}")
    print(f"7 checkpoints: {MugemConfig.CHECKPOINTS}")

if __name__ == "__main__":
    test_import()
