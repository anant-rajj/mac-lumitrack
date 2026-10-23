CC = clang
CFLAGS = -O3 -fobjc-arc -Wall -Wextra
FRAMEWORKS = -framework Foundation -framework CoreGraphics -F/System/Library/PrivateFrameworks -framework MultitouchSupport -framework CoreBrightness
TARGET = trackpad-kb-brightness

all: $(TARGET)

$(TARGET): main.m
	$(CC) $(CFLAGS) $(FRAMEWORKS) main.m -o $(TARGET)
	@strip $(TARGET)
	@echo "[BUILD SUCCESS] Created ultra-lightweight binary: $(TARGET)"
	@ls -lh $(TARGET)

clean:
	rm -f $(TARGET)

.PHONY: all clean
