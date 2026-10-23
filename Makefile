CC = clang
CFLAGS = -O3 -fobjc-arc -Wall -Wextra
FRAMEWORKS = -framework Foundation -framework CoreGraphics -F/System/Library/PrivateFrameworks -framework MultitouchSupport -framework CoreBrightness
TARGET = mac-lumitrack
PLIST = com.anantraj.mac-lumitrack.plist
BINDIR = $(HOME)/.local/bin
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
	@./$(TARGET) --stop 2>/dev/null || pkill -f "mac-lumitrack" 2>/dev/null || true
	@rm -f /tmp/mac-lumitrack.pid
	@echo "[OK] Stopped any running mac-lumitrack process."

# Check status
status:
	@pgrep -fl mac-lumitrack || echo "Not running."

# Native macOS LaunchAgent (works for ANY user on any Mac: auto-starts on login)
install-service: $(TARGET)
	@mkdir -p $(BINDIR) $(LAUNCH_AGENTS_DIR)
	@cp $(TARGET) $(BINDIR)/$(TARGET)
	@sed 's|BINARY_PATH_PLACEHOLDER|$(BINDIR)/$(TARGET)|g' $(PLIST) > $(LAUNCH_AGENTS_DIR)/$(PLIST)
	@launchctl bootout gui/$$(id -u) $(LAUNCH_AGENTS_DIR)/$(PLIST) 2>/dev/null || true
	@launchctl bootstrap gui/$$(id -u) $(LAUNCH_AGENTS_DIR)/$(PLIST)
	@echo "[OK] Installed persistent LaunchAgent to $(LAUNCH_AGENTS_DIR)/$(PLIST)"
	@echo "[OK] Binary installed to $(BINDIR)/$(TARGET)"
	@sleep 0.5
	@$(MAKE) status

uninstall-service:
	@launchctl bootout gui/$$(id -u) $(LAUNCH_AGENTS_DIR)/$(PLIST) 2>/dev/null || true
	@rm -f $(LAUNCH_AGENTS_DIR)/$(PLIST) $(BINDIR)/$(TARGET)
	@echo "[OK] Uninstalled LaunchAgent and removed binary."

clean:
	rm -f $(TARGET)

.PHONY: all start stop status install-service uninstall-service clean
