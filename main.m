#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <objc/runtime.h>
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <unistd.h>

// --- Multitouch Support Private Framework Definitions ---
typedef struct {
    float x;
    float y;
} MTPoint;

typedef struct {
    MTPoint position;
    MTPoint velocity;
} MTVector;

typedef enum {
    MTTouchStateNotTracking   = 0,
    MTTouchStateStartInRange  = 1,
    MTTouchStateHoverInRange  = 2,
    MTTouchStateMakeTouch     = 3,
    MTTouchStateTouching      = 4,
    MTTouchStateBreakTouch    = 5,
    MTTouchStateLingerInRange = 6,
    MTTouchStateOutOfRange    = 7
} MTTouchState;

typedef struct {
    int32_t frame;
    double timestamp;
    int32_t pathIndex;
    int32_t state;
    int32_t fingerID;
    int32_t handID;
    MTVector normalized;
    float zTotal;
    int32_t field9;
    float angle;
    float majorAxis;
    float minorAxis;
    MTVector absolute;
    int32_t field14;
    int32_t field15;
    float zDensity;
} MTTouch;

typedef void *MTDeviceRef;
typedef int (*MTContactCallbackFunction)(MTDeviceRef, MTTouch *, int numTouches, double timestamp, int frame);

extern CFMutableArrayRef MTDeviceCreateList(void);
extern void MTRegisterContactFrameCallback(MTDeviceRef, MTContactCallbackFunction);
extern void MTDeviceStart(MTDeviceRef, int);
extern void MTDeviceStop(MTDeviceRef, int);

// --- Forward declaration for CoreBrightness private API ---
@interface KeyboardBrightnessClient : NSObject
- (NSArray *)copyKeyboardBacklightIDs;
- (BOOL)isKeyboardBuiltIn:(unsigned long long)keyboardID;
- (float)brightnessForKeyboard:(unsigned long long)keyboardID;
- (BOOL)setBrightness:(float)brightness forKeyboard:(unsigned long long)keyboardID;
- (BOOL)enableAutoBrightness:(BOOL)enabled forKeyboard:(unsigned long long)keyboardID;
- (BOOL)isAutoBrightnessEnabledForKeyboard:(unsigned long long)keyboardID;
@end

// --- Configuration Constants ---
#define BOTTOM_EDGE_THRESHOLD 0.50f  // Active on lower 50% of trackpad
#define SENSITIVITY           3.50f  // Fast response rate
#define DEADZONE_DELTA        0.002f // Instant micro-movement response

// --- Global State ---
static KeyboardBrightnessClient *g_kbClient = nil;
static unsigned long long g_builtinKeyboardID = 0;
static BOOL g_tracking = NO;
static int g_trackingFingerID = -1;
static float g_lastX = 0.0f;
static BOOL g_verbose = NO;

// Check if physical Command (⌘) modifier key is currently held down
static inline BOOL isCommandKeyPressed(void) {
    CGEventFlags hid = CGEventSourceFlagsState(kCGEventSourceStateHIDSystemState);
    CGEventFlags session = CGEventSourceFlagsState(kCGEventSourceStateCombinedSessionState);
    return ((hid & kCGEventFlagMaskCommand) != 0) || ((session & kCGEventFlagMaskCommand) != 0);
}

static void updateKeyboardBrightness(float deltaX, float currentX) {
    if (!g_kbClient || g_builtinKeyboardID == 0) return;

    float current = [g_kbClient brightnessForKeyboard:g_builtinKeyboardID];
    float change = deltaX * SENSITIVITY;
    float target = current + change;

    // Edge snapping to guarantee reaching true 0% and 100% bounds
    if (target <= 0.04f || (deltaX < 0.0f && currentX <= 0.08f)) {
        target = 0.0f;
    } else if (target >= 0.96f || (deltaX > 0.0f && currentX >= 0.92f)) {
        target = 1.0f;
    }

    if (target < 0.0f) target = 0.0f;
    if (target > 1.0f) target = 1.0f;

    if (fabsf(target - current) > 0.002f || target == 0.0f || target == 1.0f) {
        [g_kbClient setBrightness:target forKeyboard:g_builtinKeyboardID];
        if (g_verbose) {
            printf("[KB-BRIGHTNESS] Delta: %+0.3f | %0.1f%% -> %0.1f%%\n", change, current * 100.0f, target * 100.0f);
            fflush(stdout);
        }
    }
}

static int touchCallback(MTDeviceRef device, MTTouch *touches, int numTouches, double timestamp, int frame) {
    (void)device;
    (void)timestamp;
    (void)frame;

    // 1. COMMAND KEY GUARD: Only activate when Command (⌘) key is held down
    BOOL cmdDown = isCommandKeyPressed();
    if (!cmdDown) {
        if (g_tracking) {
            g_tracking = NO;
            g_trackingFingerID = -1;
            if (g_verbose) {
                printf("[TRACKING] Stopped (Command key released)\n");
                fflush(stdout);
            }
        }
        // Normal mouse / gesture behavior completely untouched
        return 0;
    }

    if (numTouches == 0) {
        if (g_tracking) {
            g_tracking = NO;
            g_trackingFingerID = -1;
            if (g_verbose) {
                printf("[TRACKING] Completed (finger released)\n");
                fflush(stdout);
            }
        }
        return 0;
    }

    if (numTouches > 1) {
        if (g_tracking) {
            g_tracking = NO;
            g_trackingFingerID = -1;
            if (g_verbose) {
                printf("[TRACKING] Canceled (%d fingers detected)\n", numTouches);
                fflush(stdout);
            }
        }
        return 0;
    }

    MTTouch *t = &touches[0];
    float x = t->normalized.position.x; // 0.0 = Left, 1.0 = Right
    float y = t->normalized.position.y; // 0.0 = Bottom, 1.0 = Top
    int state = t->state;
    int fingerID = t->fingerID;

    if (state == MTTouchStateBreakTouch || state >= MTTouchStateLingerInRange || state == MTTouchStateNotTracking) {
        if (g_tracking && fingerID == g_trackingFingerID) {
            g_tracking = NO;
            g_trackingFingerID = -1;
            if (g_verbose) {
                printf("[TRACKING] Finger lifted\n");
                fflush(stdout);
            }
        }
        return 0;
    }

    // Actively touching / sliding on lower trackpad (y <= 0.50)
    if (!g_tracking) {
        if (y <= BOTTOM_EDGE_THRESHOLD && (state == MTTouchStateMakeTouch || state == MTTouchStateTouching || state == MTTouchStateStartInRange)) {
            g_tracking = YES;
            g_trackingFingerID = fingerID;
            g_lastX = x;
            if (g_verbose) {
                printf("[TRACKING] Started Cmd + Drag at (x: %0.2f, y: %0.2f)\n", x, y);
                fflush(stdout);
            }
        }
    } else {
        if (fingerID == g_trackingFingerID) {
            if (y > 0.70f) {
                g_tracking = NO;
                g_trackingFingerID = -1;
                if (g_verbose) {
                    printf("[TRACKING] Exited active zone (y: %0.2f > 0.70)\n", y);
                    fflush(stdout);
                }
                return 0;
            }

            float dx = x - g_lastX;
            if (fabsf(dx) >= DEADZONE_DELTA) {
                updateKeyboardBrightness(dx, x);
                g_lastX = x;
            }
        } else {
            g_tracking = NO;
            g_trackingFingerID = -1;
        }
    }

    return 0;
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        for (int i = 1; i < argc; i++) {
            if (strcmp(argv[i], "-v") == 0 || strcmp(argv[i], "--verbose") == 0) {
                g_verbose = YES;
            }
        }

        printf("====================================================\n");
        printf("  Ultra-Lightweight Cmd + Trackpad Backlight Tool\n");
        printf("====================================================\n");
        printf("- Shortcut          : Hold [Command ⌘] + Slide on trackpad\n");
        printf("- Left-to-Right     : Increase Keyboard Brightness\n");
        printf("- Right-to-Left     : Decrease Keyboard Brightness\n");
        printf("- Normal Trackpad   : 100%% Unaffected (zero accidental triggers)\n");
        printf("- RAM Footprint     : ~2-3 MB RSS (Pure C / Objective-C)\n");
        printf("----------------------------------------------------\n");

        Class kbcClass = objc_getClass("KeyboardBrightnessClient");
        if (!kbcClass) {
            fprintf(stderr, "Error: KeyboardBrightnessClient not available on this macOS version.\n");
            return 1;
        }

        g_kbClient = [[kbcClass alloc] init];
        NSArray *kbIDs = [g_kbClient copyKeyboardBacklightIDs];
        if (!kbIDs || [kbIDs count] == 0) {
            fprintf(stderr, "Error: No keyboard backlight detected on this machine.\n");
            return 1;
        }

        for (NSNumber *kbID in kbIDs) {
            unsigned long long uid = [kbID unsignedLongLongValue];
            if ([g_kbClient isKeyboardBuiltIn:uid]) {
                g_builtinKeyboardID = uid;
                break;
            }
        }
        if (g_builtinKeyboardID == 0) {
            g_builtinKeyboardID = [[kbIDs firstObject] unsignedLongLongValue];
        }

        [g_kbClient enableAutoBrightness:NO forKeyboard:g_builtinKeyboardID];

        float initialBrightness = [g_kbClient brightnessForKeyboard:g_builtinKeyboardID];
        printf("[OK] Built-in Keyboard ID: %llu (Initial Brightness: %0.1f%%, Auto-Brightness Disabled)\n",
               g_builtinKeyboardID, initialBrightness * 100.0f);

        CFMutableArrayRef devices = MTDeviceCreateList();
        if (!devices) {
            fprintf(stderr, "Error: Unable to enumerate multitouch devices.\n");
            return 1;
        }

        CFIndex count = CFArrayGetCount(devices);
        if (count == 0) {
            fprintf(stderr, "Error: No multitouch trackpad found.\n");
            return 1;
        }

        for (CFIndex i = 0; i < count; i++) {
            MTDeviceRef dev = (MTDeviceRef)CFArrayGetValueAtIndex(devices, i);
            MTRegisterContactFrameCallback(dev, touchCallback);
            MTDeviceStart(dev, 0);
        }

        printf("[OK] Registered %ld Multitouch device(s). Ready!\n", count);
        if (!g_verbose) {
            printf("(Pass --verbose to see real-time touch and brightness logs)\n");
        }

        CFRunLoopRun();
    }
    return 0;
}
