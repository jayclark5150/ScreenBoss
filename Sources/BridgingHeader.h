#import <IOKit/i2c/IOI2CInterface.h>
#import <IOKit/graphics/IOGraphicsLib.h>

// CBBlueLightClient — private CoreBrightness API for Night Shift
typedef struct {
    int    mode;        // 0=off 1=on 2=scheduled
    float  strength;    // 0.0–1.0
    _Bool  enabled;
    _Bool  disableFlags;
    _Bool  available;
    char   _reserved[20];
} CBBlueLightStatusData;

@interface CBBlueLightClient : NSObject
- (instancetype)init;
- (BOOL)setEnabled:(BOOL)enabled;
- (BOOL)setStrength:(float)strength commit:(BOOL)commit;
- (BOOL)getBlueLightStatus:(CBBlueLightStatusData *)outStatus;
@end
