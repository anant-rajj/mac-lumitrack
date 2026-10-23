CC = clang
CFLAGS = -O3 -fobjc-arc -Wall -Wextra
FRAMEWORKS = -framework Foundation -framework CoreGraphics -F/System/Library/PrivateFrameworks -framework MultitouchSupport -framework CoreBrightness
TARGET = trackpad-kb-brightness
PLIST = com.anantraj.trackpad-kb-brightness.plist
LAUNCH_AGENTS_DIR = $(HOME)/Library/LaunchAgents

all: $(TARGET)

$(TARGET): main.m
	$(CC) $(CFLAGS) $(FRAMEWORKS) main.m -o $(TARGET)
	@strip $(TARGET)
	@echo "[BUILD SUCCESS] Created binary: $(TARGET)"
	@ls -lh $(TARGET)

# Run in background detached from terminal (won't die when terminal closes)
start: $(TARGET)
	@./$(TARGET) --daemon
	@echo "[OK] Started in background as daemon. Safe to close terminal!"
	@sleep 0.5
	@$(MAKE) status

# Stop background daemon
stop:
	@./$(TARGET) --stop 2>/dev/null || pkill -f "trackpad-kb-brightness" 2>/dev/null || true
	@rm -f /tmp/trackpad-kb-brightness.pid
	@echo "[OK] Stopped any running trackpad-kb-brightness process."

# Check status
status:
	@pgrep -fl trackpad-kb-brightness || echo "Not running."

# Native macOS LaunchAgent (starts automatically at login, survives reboots and terminal exits)
install-service: $(TARGET)
	@mkdir -p $(LAUNCH_AGENTS_DIR)
	@cp $(PLIST) $(LAUNCH_AGENTS_DIR)/
	@launchctl bootout gui/$$(id -u) $(LAUNCH_AGENTS_DIR)/$(PLIST) 2>/dev/null || true
	@launchctl bootstrap gui/$$(id -u) $(LAUNCH_AGENTS_DIR)/$(PLIST)
	@echo "[OK] Installed persistent LaunchAgent. Running 24/7 without terminal!"
	@sleep 0.5
	@$(MAKE) status

uninstall-service:
	@launchctl bootout gui/$$(id -u) $(LAUNCH_AGENTS_DIR)/$(PLIST) 2>/dev/null || true
	@rm -f $(LAUNCH_AGENTS_DIR)/$(PLIST)
	@echo "[OK] Uninstalled LaunchAgent."

clean:
	rm -f $(TARGET)

.PHONY: all start stop status install-service uninstall-service clean
