#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>
#import <mach-o/loader.h>
#import <string.h>

#pragma mark - Memory Patch Core

// アドレス
static const intptr_t addr1 = -0x130; //猫缶
static const intptr_t addr2 = 0x40; //xp
static const intptr_t addr3 = 0x48; //np

static uintptr_t getModuleBase(const char *moduleName) {
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && strstr(name, moduleName)) {
            const struct mach_header *header = _dyld_get_image_header(i);
            intptr_t slide = _dyld_get_image_vmaddr_slide(i);
            return (uintptr_t)header + (uintptr_t)slide;
        }
    }
    return 0;
}

// setvalue(offset, value)
bool setvalue(intptr_t offset, int32_t value) {
    const char *moduleName = "jp.co.ponos.battlecats"; // モジュール名
    uintptr_t startAddress = getModuleBase(moduleName);
    if (startAddress == 0) return false;

    uintptr_t address = (uintptr_t)((intptr_t)startAddress + offset);  
    *((int32_t *)address) = value;  
    return true;
}

#pragma mark - Mod Menu

@interface ModMenuManager : NSObject
@property UIButton *floatingButton;
@property UIView *overlay;
@property UIView *menu;

@property UISwitch *toggleA;
@property UISwitch *toggleB;
@property UISwitch *toggleC;

@property NSTimer *timer;

+ (instancetype)shared;
@end

@implementation ModMenuManager

+ (instancetype)shared {
    static ModMenuManager *m;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ m = [ModMenuManager new]; });
    return m;
}

- (UIWindow *)keyWindow {
    for (UIWindow *w in UIApplication.sharedApplication.windows) {
        if (w.isKeyWindow) return w;
    }
    return nil;
}

#pragma mark - Floating Icon

- (void)showFloatingButton {
    UIWindow *w = [self keyWindow];
    if (!w) return;

    self.floatingButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.floatingButton.frame = CGRectMake(40, 120, 56, 56);
    self.floatingButton.layer.cornerRadius = 28;
    self.floatingButton.backgroundColor = UIColor.systemGreenColor;

    [self.floatingButton addTarget:self
                            action:@selector(toggleMenu)
                  forControlEvents:UIControlEventTouchUpInside];

    UIPanGestureRecognizer *pan =
    [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(drag:)];
    [self.floatingButton addGestureRecognizer:pan];

    [w addSubview:self.floatingButton];
}

#pragma mark - Menu

- (void)toggleMenu {
    if (self.overlay.superview) {
        [self hideMenu];
    } else {
        [self showMenu];
    }
}

- (void)showMenu {
    UIWindow *w = [self keyWindow];
    if (!w) return;

    // 背景 黒70%
    self.overlay = [[UIView alloc] initWithFrame:w.bounds];
    self.overlay.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
    [w addSubview:self.overlay];

    // メニュー本体 250×300
    self.menu = [[UIView alloc] initWithFrame:CGRectMake(60, 160, 250, 300)];
    self.menu.backgroundColor = UIColor.whiteColor;
    self.menu.layer.cornerRadius = 14;

    UIPanGestureRecognizer *pan =
    [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(drag:)];
    [self.menu addGestureRecognizer:pan];

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(16, 12, 200, 24)];
    title.text = @"Mod Menu";
    title.font = [UIFont boldSystemFontOfSize:18];

    // トグルA
    UILabel *labelA = [[UILabel alloc] initWithFrame:CGRectMake(16, 60, 120, 24)];
    labelA.text = @"A";
    self.toggleA = [[UISwitch alloc] initWithFrame:CGRectMake(170, 56, 0, 0)];
    [self.toggleA addTarget:self action:@selector(toggleChanged:)
           forControlEvents:UIControlEventValueChanged];

    // トグルB
    UILabel *labelB = [[UILabel alloc] initWithFrame:CGRectMake(16, 110, 120, 24)];
    labelB.text = @"B";
    self.toggleB = [[UISwitch alloc] initWithFrame:CGRectMake(170, 106, 0, 0)];
    [self.toggleB addTarget:self action:@selector(toggleChanged:)
           forControlEvents:UIControlEventValueChanged];

    // トグルC
    UILabel *labelC = [[UILabel alloc] initWithFrame:CGRectMake(16, 160, 120, 24)];
    labelC.text = @"C";
    self.toggleC = [[UISwitch alloc] initWithFrame:CGRectMake(170, 156, 0, 0)];
    [self.toggleC addTarget:self action:@selector(toggleChanged:)
           forControlEvents:UIControlEventValueChanged];

    UIButton *close = [UIButton buttonWithType:UIButtonTypeSystem];
    close.frame = CGRectMake(150, 250, 80, 30);
    [close setTitle:@"Close" forState:UIControlStateNormal];
    [close addTarget:self action:@selector(hideMenu)
    forControlEvents:UIControlEventTouchUpInside];

    [self.menu addSubview:title];
    [self.menu addSubview:labelA];
    [self.menu addSubview:self.toggleA];
    [self.menu addSubview:labelB];
    [self.menu addSubview:self.toggleB];
    [self.menu addSubview:labelC];
    [self.menu addSubview:self.toggleC];
    [self.menu addSubview:close];

    [self.overlay addSubview:self.menu];
}

- (void)hideMenu {
    [self.timer invalidate];
    self.timer = nil;
    [self.overlay removeFromSuperview];
    self.overlay = nil;
}

#pragma mark - Drag

- (void)drag:(UIPanGestureRecognizer *)g {
    UIView *v = g.view;
    CGPoint t = [g translationInView:v.superview];
    v.center = CGPointMake(v.center.x + t.x, v.center.y + t.y);
    [g setTranslation:CGPointZero inView:v.superview];
}

#pragma mark - Toggle Logic

- (void)toggleChanged:(UISwitch *)sw {
    if (self.toggleA.isOn || self.toggleB.isOn || self.toggleC.isOn) {
        if (!self.timer) {
            self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                                          target:self
                                                        selector:@selector(applyPatch)
                                                        userInfo:nil
                                                         repeats:YES];
        }
    } else {
        [self.timer invalidate];
        self.timer = nil;
    }
}

- (void)applyPatch {
    // トグルA
    if (self.toggleA.isOn) {
        setvalue(addr1, 58999);
        setvalue(addr1 + 4, 0);
    }

    // トグルB
    if (self.toggleB.isOn) {
        setvalue(addr2, 999);
        setvalue(addr2 + 4, 0);
    }

    // トグルC
    if (self.toggleC.isOn) {
        setvalue(addr3, 1);
        setvalue(addr3 + 4, 0);
    }
}

@end

#pragma mark - Entry

__attribute__((constructor))
static void entry() {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[ModMenuManager shared] showFloatingButton];
    });
}
// by 制作 ChatGPT
