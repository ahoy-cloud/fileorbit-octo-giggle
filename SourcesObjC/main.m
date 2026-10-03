#import <Cocoa/Cocoa.h>
#import <CoreGraphics/CoreGraphics.h>
#import <QuartzCore/QuartzCore.h>

static NSArray<NSColor *> *FOPalette(void) {
    static NSArray<NSColor *> *colors;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        colors = @[
            [NSColor colorWithRed:.36 green:.70 blue:1 alpha:1],
            [NSColor colorWithRed:.52 green:.42 blue:.96 alpha:1],
            [NSColor colorWithRed:.96 green:.43 blue:.62 alpha:1],
            [NSColor colorWithRed:1 green:.60 blue:.27 alpha:1],
            [NSColor colorWithRed:.96 green:.78 blue:.24 alpha:1],
            [NSColor colorWithRed:.30 green:.78 blue:.55 alpha:1],
            [NSColor colorWithRed:.21 green:.72 blue:.76 alpha:1],
            [NSColor colorWithRed:.48 green:.57 blue:.72 alpha:1]
        ];
    });
    return colors;
}

static NSColor *FOAccentColor(void) {
    NSData *data = [NSUserDefaults.standardUserDefaults dataForKey:@"accentColor.v4"];
    NSColor *saved = data ? [NSKeyedUnarchiver unarchivedObjectOfClass:NSColor.class fromData:data error:nil] : nil;
    return saved ?: [NSColor colorWithRed:.30 green:.51 blue:.44 alpha:1];
}

static NSString *const FOTrashKind = @"trash";

static void FODrawBrandMark(CGFloat size) {
    CGFloat unit = size / 100.0;
    NSRect full = NSMakeRect(0, 0, size, size);
    NSBezierPath *tile = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(full, unit * 3, unit * 3) xRadius:unit * 22 yRadius:unit * 22];
    [[NSColor colorWithRed:.96 green:.96 blue:.94 alpha:1] setFill]; [tile fill];

    NSBezierPath *folder = [NSBezierPath bezierPath];
    [folder moveToPoint:NSMakePoint(unit * 23, unit * 35)];
    [folder lineToPoint:NSMakePoint(unit * 23, unit * 65)];
    [folder curveToPoint:NSMakePoint(unit * 28, unit * 70) controlPoint1:NSMakePoint(unit * 23, unit * 68) controlPoint2:NSMakePoint(unit * 25, unit * 70)];
    [folder lineToPoint:NSMakePoint(unit * 42, unit * 70)];
    [folder lineToPoint:NSMakePoint(unit * 49, unit * 63)];
    [folder lineToPoint:NSMakePoint(unit * 72, unit * 63)];
    [folder curveToPoint:NSMakePoint(unit * 77, unit * 58) controlPoint1:NSMakePoint(unit * 75, unit * 63) controlPoint2:NSMakePoint(unit * 77, unit * 61)];
    [folder lineToPoint:NSMakePoint(unit * 77, unit * 35)];
    [folder curveToPoint:NSMakePoint(unit * 72, unit * 30) controlPoint1:NSMakePoint(unit * 77, unit * 32) controlPoint2:NSMakePoint(unit * 75, unit * 30)];
    [folder lineToPoint:NSMakePoint(unit * 28, unit * 30)];
    [folder curveToPoint:NSMakePoint(unit * 23, unit * 35) controlPoint1:NSMakePoint(unit * 25, unit * 30) controlPoint2:NSMakePoint(unit * 23, unit * 32)];
    [folder closePath];
    [[NSColor colorWithRed:.20 green:.31 blue:.60 alpha:1] setFill]; [folder fill];

    NSBezierPath *satellite = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(unit * 71, unit * 72, unit * 10, unit * 10)];
    [[NSColor colorWithRed:.96 green:.38 blue:.28 alpha:1] setFill]; [satellite fill];
}

static NSImage *FOStatusIcon(void) {
    NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(18, 18)];
    [image lockFocus];
    NSBezierPath *folder = [NSBezierPath bezierPath];
    [folder moveToPoint:NSMakePoint(1.4, 2.0)]; [folder lineToPoint:NSMakePoint(1.4, 13.3)];
    [folder lineToPoint:NSMakePoint(6.7, 13.3)]; [folder lineToPoint:NSMakePoint(8.1, 11.5)];
    [folder lineToPoint:NSMakePoint(16.4, 11.5)]; [folder lineToPoint:NSMakePoint(16.4, 2.0)];
    [folder closePath]; [NSColor.blackColor setFill]; [folder fill];
    [[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(13.5, 14.2, 3.0, 3.0)] fill];
    [image unlockFocus]; image.template = YES; return image;
}

static NSData *FOIconPNG(NSInteger pixels) {
    NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:pixels pixelsHigh:pixels bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSCalibratedRGBColorSpace bytesPerRow:0 bitsPerPixel:0];
    if (!bitmap) return nil;
    NSGraphicsContext *context = [NSGraphicsContext graphicsContextWithBitmapImageRep:bitmap];
    [NSGraphicsContext saveGraphicsState]; [NSGraphicsContext setCurrentContext:context];
    FODrawBrandMark(pixels); [context flushGraphics]; [NSGraphicsContext restoreGraphicsState];
    return [bitmap representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
}

static BOOL FORenderAppIcon(NSString *path) {
    NSArray<NSNumber *> *sizes = @[@16, @32, @64, @128, @256, @512, @1024];
    NSArray<NSString *> *types = @[@"icp4", @"icp5", @"icp6", @"ic07", @"ic08", @"ic09", @"ic10"];
    NSMutableArray<NSData *> *images = [NSMutableArray array];
    uint32_t length = 8;
    for (NSNumber *size in sizes) {
        NSData *png = FOIconPNG(size.integerValue);
        if (!png) return NO;
        [images addObject:png]; length += (uint32_t)png.length + 8;
    }
    NSMutableData *icon = [NSMutableData data];
    [icon appendBytes:"icns" length:4];
    uint32_t encoded = CFSwapInt32HostToBig(length); [icon appendBytes:&encoded length:4];
    for (NSUInteger i = 0; i < images.count; i++) {
        [icon appendBytes:types[i].UTF8String length:4];
        encoded = CFSwapInt32HostToBig((uint32_t)images[i].length + 8); [icon appendBytes:&encoded length:4];
        [icon appendData:images[i]];
    }
    return [icon writeToFile:path atomically:YES];
}

@interface FOStore : NSObject
@property NSMutableArray<NSMutableDictionary *> *targets;
@property BOOL copyMode;
@property NSColor *accentColor;
+ (instancetype)shared;
- (void)save;
- (void)addURL:(NSURL *)url;
@end

@implementation FOStore
+ (instancetype)shared { static FOStore *s; static dispatch_once_t once; dispatch_once(&once, ^{ s = [FOStore new]; }); return s; }
- (instancetype)init {
    if ((self = [super init])) {
        NSArray *saved = [[NSUserDefaults standardUserDefaults] arrayForKey:@"targets.v2"];
        _targets = [NSMutableArray array];
        for (NSDictionary *item in saved ?: @[]) [_targets addObject:[item mutableCopy]];
        _copyMode = [[NSUserDefaults standardUserDefaults] boolForKey:@"copyMode.v2"];
        _accentColor = FOAccentColor();
        if (_targets.count == 0) {
            NSArray *pairs = @[
                @[@"桌面", [NSHomeDirectory() stringByAppendingPathComponent:@"Desktop"]],
                @[@"下载", [NSHomeDirectory() stringByAppendingPathComponent:@"Downloads"]],
                @[@"文稿", [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"]]
            ];
            NSInteger color = 0;
            for (NSArray *pair in pairs) {
                [_targets addObject:[@{@"name": pair[0], @"path": pair[1], @"color": @(color++)} mutableCopy]];
            }
            [self save];
        }
    }
    return self;
}
- (void)save {
    [[NSUserDefaults standardUserDefaults] setObject:self.targets forKey:@"targets.v2"];
    [[NSUserDefaults standardUserDefaults] setBool:self.copyMode forKey:@"copyMode.v2"];
    NSData *colorData = [NSKeyedArchiver archivedDataWithRootObject:self.accentColor requiringSecureCoding:YES error:nil];
    if (colorData) [[NSUserDefaults standardUserDefaults] setObject:colorData forKey:@"accentColor.v4"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"FOStoreChanged" object:nil];
}
- (void)addURL:(NSURL *)url {
    for (NSDictionary *item in self.targets) if ([item[@"path"] isEqualToString:url.path]) return;
    [self.targets addObject:[@{@"name": url.lastPathComponent ?: @"文件夹",
                               @"path": url.path,
                               @"color": @(self.targets.count % FOPalette().count)} mutableCopy]];
    [self save];
}
@end

@interface FOOrganizer : NSObject
@property NSArray<NSDictionary *> *lastTransfers;
+ (instancetype)shared;
- (NSInteger)organizeURLs:(NSArray<NSURL *> *)urls folder:(NSURL *)folder error:(NSError **)error;
- (NSInteger)undo:(NSError **)error;
- (void)trashURLs:(NSArray<NSURL *> *)urls completion:(void (^)(NSInteger, NSError *))completion;
@end

@implementation FOOrganizer
+ (instancetype)shared { static FOOrganizer *s; static dispatch_once_t once; dispatch_once(&once, ^{ s = [FOOrganizer new]; }); return s; }
- (NSURL *)uniqueURLFor:(NSURL *)source inFolder:(NSURL *)folder {
    NSFileManager *fm = NSFileManager.defaultManager;
    NSURL *first = [folder URLByAppendingPathComponent:source.lastPathComponent];
    if (![fm fileExistsAtPath:first.path]) return first;
    NSString *ext = source.pathExtension;
    NSString *base = source.URLByDeletingPathExtension.lastPathComponent;
    for (NSInteger n = 2; ; n++) {
        NSString *name = ext.length ? [NSString stringWithFormat:@"%@ %ld.%@", base, (long)n, ext] : [NSString stringWithFormat:@"%@ %ld", base, (long)n];
        NSURL *candidate = [folder URLByAppendingPathComponent:name];
        if (![fm fileExistsAtPath:candidate.path]) return candidate;
    }
}
- (NSInteger)organizeURLs:(NSArray<NSURL *> *)urls folder:(NSURL *)folder error:(NSError **)error {
    NSFileManager *fm = NSFileManager.defaultManager;
    if (![fm createDirectoryAtURL:folder withIntermediateDirectories:YES attributes:nil error:error]) return 0;
    NSMutableArray *done = [NSMutableArray array];
    for (NSURL *source in urls) {
        NSURL *dest = [self uniqueURLFor:source inFolder:folder];
        BOOL ok = FOStore.shared.copyMode ? [fm copyItemAtURL:source toURL:dest error:error] : [fm moveItemAtURL:source toURL:dest error:error];
        if (!ok) { self.lastTransfers = done; return done.count; }
        [done addObject:@{@"source": source.path, @"dest": dest.path, @"copy": @(FOStore.shared.copyMode)}];
    }
    self.lastTransfers = done;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"FOUndoChanged" object:nil];
    return done.count;
}
- (NSInteger)undo:(NSError **)error {
    NSFileManager *fm = NSFileManager.defaultManager;
    NSInteger count = 0;
    for (NSDictionary *item in self.lastTransfers.reverseObjectEnumerator) {
        NSURL *dest = [NSURL fileURLWithPath:item[@"dest"]];
        if (![fm fileExistsAtPath:dest.path]) continue;
        BOOL ok;
        if ([item[@"trash"] boolValue]) {
            NSURL *original = [NSURL fileURLWithPath:item[@"source"]];
            NSURL *restore = [fm fileExistsAtPath:original.path] ? [self uniqueURLFor:original inFolder:original.URLByDeletingLastPathComponent] : original;
            ok = [fm moveItemAtURL:dest toURL:restore error:error];
        } else if ([item[@"copy"] boolValue]) {
            ok = [fm removeItemAtURL:dest error:error];
        } else {
            NSURL *original = [NSURL fileURLWithPath:item[@"source"]];
            NSURL *restore = [fm fileExistsAtPath:original.path] ? [self uniqueURLFor:original inFolder:original.URLByDeletingLastPathComponent] : original;
            ok = [fm moveItemAtURL:dest toURL:restore error:error];
        }
        if (!ok) return count;
        count++;
    }
    self.lastTransfers = @[];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"FOUndoChanged" object:nil];
    return count;
}
- (void)trashURLs:(NSArray<NSURL *> *)urls completion:(void (^)(NSInteger, NSError *))completion {
    NSMutableArray<NSDictionary *> *transfers = [NSMutableArray array];
    NSError *firstError = nil;
    for (NSURL *source in urls) {
        NSURL *trashURL = nil;
        NSError *itemError = nil;
        if (![NSFileManager.defaultManager trashItemAtURL:source resultingItemURL:&trashURL error:&itemError]) {
            firstError = itemError;
            break;
        }
        if (trashURL) [transfers addObject:@{@"source":source.path, @"dest":trashURL.path, @"trash":@YES}];
    }
    self.lastTransfers = transfers;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"FOUndoChanged" object:nil];
    completion(transfers.count, firstError);
}
@end

@class FOWheelPanel;
@interface FOWheelView : NSView <NSDraggingDestination>
@property NSInteger highlighted;
@property BOOL centerHighlighted;
@property BOOL dragActive;
@property NSArray<NSDictionary *> *visibleTargets;
@property NSMutableArray<NSURL *> *folderStack;
@property NSInteger page;
@property NSDate *hoverBegan;
@property NSTimer *hoverTimer;
@property NSInteger hoverIndex;
@property NSPoint transitionPoint;
@property BOOL awaitingReposition;
- (void)reloadTargets;
- (void)resetNavigation;
@end

@interface FOWheelPanel : NSPanel
@property FOWheelView *wheel;
@property BOOL manualVisible;
- (void)showNear:(NSPoint)point;
- (void)hideWheel;
@end

@interface FOSettingsController : NSWindowController <NSTableViewDataSource, NSTableViewDelegate>
@property NSTableView *table;
@property NSSegmentedControl *mode;
@property NSColorWell *colorWell;
@property NSButton *previewButton;
@property NSLayoutConstraint *folderHeight;
- (void)refresh;
@end

@interface FOAppDelegate : NSObject <NSApplicationDelegate>
@property NSStatusItem *statusItem;
@property FOWheelPanel *wheelPanel;
@property FOSettingsController *settings;
@property id globalMonitor;
@property id localMonitor;
@property id globalMouseMonitor;
@property id localKeyMonitor;
@property NSTimer *timer;
@property NSMenuItem *undoItem;
@property NSMenu *statusMenu;
+ (instancetype)shared;
- (void)toast:(NSString *)message;
- (void)showError:(NSString *)title message:(NSString *)message;
@end

@implementation FOWheelPanel
- (instancetype)init {
    NSRect rect = NSMakeRect(0, 0, 350, 350);
    if ((self = [super initWithContentRect:rect styleMask:NSWindowStyleMaskBorderless | NSWindowStyleMaskNonactivatingPanel backing:NSBackingStoreBuffered defer:NO])) {
        self.level = NSFloatingWindowLevel;
        self.opaque = NO;
        self.backgroundColor = NSColor.clearColor;
        self.hasShadow = YES;
        self.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces | NSWindowCollectionBehaviorFullScreenAuxiliary | NSWindowCollectionBehaviorTransient;
        _wheel = [[FOWheelView alloc] initWithFrame:rect];
        NSVisualEffectView *material = [[NSVisualEffectView alloc] initWithFrame:rect];
        material.material = NSVisualEffectMaterialPopover;
        material.blendingMode = NSVisualEffectBlendingModeBehindWindow;
        material.state = NSVisualEffectStateActive;
        material.wantsLayer = YES;
        material.layer.cornerRadius = 175;
        material.layer.masksToBounds = YES;
        _wheel.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        [material addSubview:_wheel];
        self.contentView = material;
    }
    return self;
}
- (void)showNear:(NSPoint)p {
    NSScreen *screen = NSScreen.mainScreen;
    for (NSScreen *candidate in NSScreen.screens) if (NSPointInRect(p, candidate.frame)) screen = candidate;
    NSRect visible = NSInsetRect(screen.visibleFrame, 12, 12);
    NSPoint o = NSMakePoint(p.x - 175, p.y - 175);
    o.x = MIN(MAX(o.x, NSMinX(visible)), NSMaxX(visible) - 350);
    o.y = MIN(MAX(o.y, NSMinY(visible)), NSMaxY(visible) - 350);
    [self setFrameOrigin:o];
    [self.wheel resetNavigation];
    [self.wheel reloadTargets];
    BOOL reduceMotion = NSWorkspace.sharedWorkspace.accessibilityDisplayShouldReduceMotion;
    if (reduceMotion) {
        self.alphaValue = 1;
        [self orderFrontRegardless];
    } else {
        self.alphaValue = 0;
        [self orderFrontRegardless];
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
            context.duration = .16;
            context.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
            self.animator.alphaValue = 1;
        } completionHandler:nil];
    }
}
- (void)hideWheel { self.manualVisible=NO; self.wheel.highlighted = -1; self.wheel.centerHighlighted = NO; self.wheel.dragActive = NO; [self orderOut:nil]; [[NSNotificationCenter defaultCenter] postNotificationName:@"FOWheelVisibilityChanged" object:nil]; }
@end

@implementation FOWheelView
- (instancetype)initWithFrame:(NSRect)frame {
    if ((self = [super initWithFrame:frame])) {
        _highlighted = -1;
        _hoverIndex = -1;
        _folderStack = [NSMutableArray array];
        [self registerForDraggedTypes:@[NSPasteboardTypeFileURL]];
        [self reloadTargets];
    }
    return self;
}
- (BOOL)isOpaque { return NO; }
- (void)resetNavigation {
    [self.folderStack removeAllObjects];
    self.page = 0;
    self.highlighted = -1;
    self.hoverIndex = -1;
    self.centerHighlighted = NO;
    self.awaitingReposition = NO;
    [self reloadTargets];
}
- (void)reloadTargets {
    NSMutableArray *items = [NSMutableArray array];
    if (!self.folderStack.count) {
        NSUInteger count = MIN((NSUInteger)7, FOStore.shared.targets.count);
        for (NSUInteger i = 0; i < count; i++) {
            NSMutableDictionary *target = [FOStore.shared.targets[i] mutableCopy];
            target[@"kind"] = @"folder";
            [items addObject:target];
        }
        [items addObject:@{@"kind":FOTrashKind, @"name":@"废纸篓"}];
    } else {
        NSURL *folder = self.folderStack.lastObject;
        NSArray<NSURL *> *contents = [NSFileManager.defaultManager contentsOfDirectoryAtURL:folder includingPropertiesForKeys:@[NSURLIsDirectoryKey] options:NSDirectoryEnumerationSkipsHiddenFiles error:nil] ?: @[];
        NSMutableArray<NSURL *> *children = [NSMutableArray array];
        for (NSURL *url in contents) {
            NSNumber *isDirectory = nil;
            [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil];
            if (isDirectory.boolValue && ![url.path isEqualToString:folder.path]) [children addObject:url];
        }
        [children sortUsingComparator:^NSComparisonResult(NSURL *a, NSURL *b) { return [a.lastPathComponent localizedStandardCompare:b.lastPathComponent]; }];
        NSUInteger start = MIN((NSUInteger)(self.page * 6), children.count);
        NSUInteger count = MIN((NSUInteger)6, children.count - start);
        for (NSUInteger i = start; i < start + count; i++) {
            [items addObject:@{@"kind":@"folder", @"name":children[i].lastPathComponent, @"path":children[i].path}];
        }
        if (start + count < children.count) [items addObject:@{@"kind":@"more", @"name":@"下一页"}];
        else if (self.page > 0) [items addObject:@{@"kind":@"more", @"name":@"第一页"}];
        [items addObject:@{@"kind":@"back", @"name":@"返回"}];
    }
    self.visibleTargets = items;
    [self setNeedsDisplay:YES];
}
- (NSBezierPath *)segmentAt:(NSInteger)i count:(NSInteger)count center:(NSPoint)c {
    CGFloat slice = 360.0 / count;
    CGFloat start = 90 + slice * i + 1;
    CGFloat end = 90 + slice * (i + 1) - 1;
    NSBezierPath *p = [NSBezierPath bezierPath];
    [p appendBezierPathWithArcWithCenter:c radius:154 startAngle:start endAngle:end];
    [p appendBezierPathWithArcWithCenter:c radius:57 startAngle:end endAngle:start clockwise:YES];
    [p closePath];
    return p;
}
- (void)drawRect:(NSRect)dirtyRect {
    NSPoint c = NSMakePoint(NSMidX(self.bounds), NSMidY(self.bounds));
    NSBezierPath *shell = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(c.x-171, c.y-171, 342, 342)];
    [[NSColor colorWithRed:.96 green:.97 blue:.97 alpha:.96] setFill]; [shell fill];
    [[FOStore.shared.accentColor colorWithAlphaComponent:.30] setStroke]; shell.lineWidth = 1; [shell stroke];
    NSInteger count = self.visibleTargets.count;
    if (!count) {
        NSDictionary *a = @{NSFontAttributeName:[NSFont systemFontOfSize:16 weight:NSFontWeightSemibold], NSForegroundColorAttributeName:NSColor.darkGrayColor};
        NSString *s = @"请先添加目标文件夹"; NSSize z = [s sizeWithAttributes:a];
        [s drawAtPoint:NSMakePoint(c.x-z.width/2,c.y-z.height/2) withAttributes:a]; return;
    }
    for (NSInteger i=0; i<count; i++) {
        NSDictionary *t = self.visibleTargets[i];
        NSBezierPath *p = [self segmentAt:i count:count center:c];
        NSString *kind=t[@"kind"];
        NSColor *accent=FOStore.shared.accentColor;
        BOOL selected=i==self.highlighted;
        NSColor *tint=[kind isEqualToString:FOTrashKind]?NSColor.systemRedColor:accent;
        NSColor *base=selected?[tint colorWithAlphaComponent:.24]:[accent colorWithAlphaComponent:(i%2==0?.10:.055)];
        [base setFill]; [p fill];
        NSColor *border=selected?[tint colorWithAlphaComponent:.68]:[NSColor colorWithRed:.22 green:.29 blue:.31 alpha:.13];
        [border setStroke]; p.lineWidth = selected ? 1.5 : .75; [p stroke];
        CGFloat angle = (90 + 360.0/count*(i+.5)) * M_PI / 180.0;
        NSPoint q = NSMakePoint(c.x+cos(angle)*108, c.y+sin(angle)*108);
        NSString *name = t[@"name"];
        if (name.length > 6) name = [[name substringToIndex:6] stringByAppendingString:@"…"];
        NSString *symbol=[kind isEqualToString:FOTrashKind]?@"trash":([kind isEqualToString:@"back"]?@"arrow.uturn.backward":([kind isEqualToString:@"more"]?@"arrow.right":@"folder.fill"));
        NSImage *folder = [NSImage imageWithSystemSymbolName:symbol accessibilityDescription:nil];
        NSImageSymbolConfiguration *folderSize=[NSImageSymbolConfiguration configurationWithPointSize:13 weight:NSFontWeightMedium];
        NSColor *ink=selected?[tint blendedColorWithFraction:.22 ofColor:NSColor.blackColor]:[NSColor colorWithRed:.21 green:.27 blue:.28 alpha:1];
        NSImageSymbolConfiguration *folderColor=[NSImageSymbolConfiguration configurationWithHierarchicalColor:ink];
        folder = [folder imageWithSymbolConfiguration:[folderSize configurationByApplyingConfiguration:folderColor]];
        [folder drawInRect:NSMakeRect(q.x-8,q.y+4,16,16) fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:(i==self.highlighted?1:.80) respectFlipped:YES hints:nil];
        NSDictionary *attrs = @{NSFontAttributeName:[NSFont systemFontOfSize:11 weight:NSFontWeightSemibold], NSForegroundColorAttributeName:ink};
        NSSize z = [name sizeWithAttributes:attrs]; [name drawAtPoint:NSMakePoint(q.x-z.width/2,q.y-15) withAttributes:attrs];
    }
    NSRect centerRect = NSMakeRect(c.x-55,c.y-55,110,110);
    NSBezierPath *hub=[NSBezierPath bezierPathWithOvalInRect:centerRect];
    [[FOStore.shared.accentColor colorWithAlphaComponent:(self.centerHighlighted?.22:.11)] setFill]; [hub fill];
    [(self.centerHighlighted ? [FOStore.shared.accentColor colorWithAlphaComponent:.66] : [NSColor colorWithRed:.22 green:.29 blue:.31 alpha:.16]) setStroke]; hub.lineWidth=1; [hub stroke];
    BOOL nested=self.folderStack.count>0;
    NSImage *addFolder=[NSImage imageWithSystemSymbolName:(nested?@"tray.and.arrow.down.fill":@"folder.badge.plus") accessibilityDescription:nil];
    NSImageSymbolConfiguration *addSize=[NSImageSymbolConfiguration configurationWithPointSize:21 weight:NSFontWeightMedium];
    NSImageSymbolConfiguration *addColor=[NSImageSymbolConfiguration configurationWithHierarchicalColor:[FOStore.shared.accentColor blendedColorWithFraction:.20 ofColor:NSColor.blackColor]];
    addFolder=[addFolder imageWithSymbolConfiguration:[addSize configurationByApplyingConfiguration:addColor]];
    [addFolder drawInRect:NSMakeRect(c.x-14,c.y+1,28,26) fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1 respectFlipped:YES hints:nil];
    NSDictionary *ca=@{NSFontAttributeName:[NSFont systemFontOfSize:11 weight:NSFontWeightMedium],NSForegroundColorAttributeName:[NSColor colorWithRed:.21 green:.27 blue:.28 alpha:1]};
    NSString *cap=nested?@"放到此处":@"新建文件夹"; NSSize cz=[cap sizeWithAttributes:ca]; [cap drawAtPoint:NSMakePoint(c.x-cz.width/2,c.y-23) withAttributes:ca];
    if (nested) {
        NSString *location=self.folderStack.lastObject.lastPathComponent;
        if(location.length>10) location=[[location substringToIndex:10] stringByAppendingString:@"…"];
        NSDictionary *la=@{NSFontAttributeName:[NSFont systemFontOfSize:11 weight:NSFontWeightSemibold],NSForegroundColorAttributeName:[NSColor colorWithRed:.21 green:.27 blue:.28 alpha:.85]};
        NSSize lz=[location sizeWithAttributes:la]; [location drawAtPoint:NSMakePoint(c.x-lz.width/2,328) withAttributes:la];
    }
    NSString *mode = FOStore.shared.copyMode ? @"复制" : @"移动";
    NSDictionary *ma=@{NSFontAttributeName:[NSFont systemFontOfSize:11 weight:NSFontWeightMedium],NSForegroundColorAttributeName:[NSColor colorWithRed:.21 green:.27 blue:.28 alpha:.62]};
    NSSize mz=[mode sizeWithAttributes:ma]; [mode drawAtPoint:NSMakePoint(c.x-mz.width/2,7) withAttributes:ma];
}
- (void)updateHighlight:(NSPoint)p {
    if (self.awaitingReposition) {
        if (hypot(p.x-self.transitionPoint.x,p.y-self.transitionPoint.y)<28) return;
        self.awaitingReposition=NO;
    }
    NSPoint c=NSMakePoint(NSMidX(self.bounds),NSMidY(self.bounds)); CGFloat dx=p.x-c.x,dy=p.y-c.y,dist=hypot(dx,dy);
    self.centerHighlighted=dist<57; self.highlighted=-1;
    if (!self.centerHighlighted && dist<=157 && dist>=57 && self.visibleTargets.count) {
        CGFloat deg=atan2(dy,dx)*180/M_PI-90; while(deg<0)deg+=360;
        self.highlighted=(NSInteger)floor(deg/(360.0/self.visibleTargets.count))%self.visibleTargets.count;
    }
    if (self.highlighted != self.hoverIndex) {
        [self.hoverTimer invalidate]; self.hoverTimer=nil;
        self.hoverIndex=self.highlighted; self.hoverBegan=NSDate.date;
        if (self.dragActive && self.highlighted>=0 && self.highlighted<self.visibleTargets.count) {
            NSDictionary *target=self.visibleTargets[self.highlighted];
            NSString *kind=target[@"kind"];
            BOOL navigable=[kind isEqualToString:@"back"] || [kind isEqualToString:@"more"] || ([kind isEqualToString:@"folder"] && [self hasChildFolders:[NSURL fileURLWithPath:target[@"path"]]]);
            if (navigable) {
                NSInteger expected=self.highlighted;
                NSPoint hoverPoint=p;
                __weak typeof(self) weakSelf=self;
                self.hoverTimer=[NSTimer scheduledTimerWithTimeInterval:.55 repeats:NO block:^(NSTimer *timer) {
                    FOWheelView *wheel=weakSelf;
                    if (wheel && wheel.dragActive && wheel.highlighted==expected && !wheel.awaitingReposition && expected<wheel.visibleTargets.count && wheel.window.visible) {
                        [wheel navigateToTarget:wheel.visibleTargets[expected] fromPoint:hoverPoint];
                    }
                }];
            }
        }
    }
    [self setNeedsDisplay:YES];
}
- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender { self.dragActive=YES; [self updateHighlight:sender.draggingLocation]; return FOStore.shared.copyMode?NSDragOperationCopy:NSDragOperationMove; }
- (NSDragOperation)draggingUpdated:(id<NSDraggingInfo>)sender {
    NSPoint point=sender.draggingLocation;
    [self updateHighlight:point];
    if (self.highlighted>=0 && self.highlighted<self.visibleTargets.count && [self.visibleTargets[self.highlighted][@"kind"] isEqualToString:FOTrashKind]) return NSDragOperationMove;
    return FOStore.shared.copyMode?NSDragOperationCopy:NSDragOperationMove;
}
- (void)draggingExited:(id<NSDraggingInfo>)sender { [self.hoverTimer invalidate]; self.hoverTimer=nil; self.dragActive=NO; self.highlighted=-1; self.centerHighlighted=NO; [self setNeedsDisplay:YES]; }
- (BOOL)hasChildFolders:(NSURL *)folder {
    NSArray<NSURL *> *contents=[NSFileManager.defaultManager contentsOfDirectoryAtURL:folder includingPropertiesForKeys:@[NSURLIsDirectoryKey] options:NSDirectoryEnumerationSkipsHiddenFiles error:nil];
    for(NSURL *url in contents){NSNumber *isDir=nil;[url getResourceValue:&isDir forKey:NSURLIsDirectoryKey error:nil];if(isDir.boolValue)return YES;}
    return NO;
}
- (void)navigateToTarget:(NSDictionary *)target fromPoint:(NSPoint)point {
    [self.hoverTimer invalidate]; self.hoverTimer=nil;
    NSString *kind=target[@"kind"];
    if ([kind isEqualToString:@"back"] && self.folderStack.count) {
        [self.folderStack removeLastObject]; self.page=0;
    } else if ([kind isEqualToString:@"more"]) {
        self.page=[target[@"name"] isEqualToString:@"第一页"]?0:self.page+1;
    } else if ([kind isEqualToString:@"folder"] && target[@"path"]) {
        [self.folderStack addObject:[NSURL fileURLWithPath:target[@"path"]]]; self.page=0;
    } else return;
    self.highlighted=-1; self.hoverIndex=-1; self.hoverBegan=nil;
    self.centerHighlighted=NO; self.transitionPoint=point; self.awaitingReposition=YES;
    [self reloadTargets];
}
- (NSArray<NSURL *> *)URLsFrom:(id<NSDraggingInfo>)sender {
    return [sender.draggingPasteboard readObjectsForClasses:@[NSURL.class] options:@{NSPasteboardURLReadingFileURLsOnlyKey:@YES}] ?: @[];
}
- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender {
    NSArray<NSURL *> *urls=[self URLsFrom:sender]; if(!urls.count)return NO;
    if(self.centerHighlighted){
        if(self.folderStack.count) [self organize:urls folder:self.folderStack.lastObject];
        else dispatch_async(dispatch_get_main_queue(), ^{ [self createFolderForURLs:urls]; });
        return YES;
    }
    if(self.highlighted<0 || self.highlighted>=self.visibleTargets.count)return NO;
    NSDictionary *target=self.visibleTargets[self.highlighted];
    NSString *kind=target[@"kind"];
    if ([kind isEqualToString:FOTrashKind]) {
        dispatch_async(dispatch_get_main_queue(), ^{ [self confirmTrash:urls]; });
        return YES;
    }
    if (![kind isEqualToString:@"folder"]) return NO;
    [self organize:urls folder:[NSURL fileURLWithPath:target[@"path"]]]; return YES;
}
- (void)concludeDragOperation:(id<NSDraggingInfo>)sender { [self.hoverTimer invalidate]; self.hoverTimer=nil; self.dragActive=NO; [(FOWheelPanel *)self.window hideWheel]; }
- (void)mouseDown:(NSEvent *)event {
    FOWheelPanel *panel=(FOWheelPanel *)self.window;
    if(!panel.manualVisible)return;
    NSPoint point=[self convertPoint:event.locationInWindow fromView:nil];
    [self updateHighlight:point];
    if(self.highlighted>=0 && self.highlighted<self.visibleTargets.count){
        NSDictionary *target=self.visibleTargets[self.highlighted];
        NSString *kind=target[@"kind"];
        if([kind isEqualToString:@"back"] || [kind isEqualToString:@"more"] || ([kind isEqualToString:@"folder"] && [self hasChildFolders:[NSURL fileURLWithPath:target[@"path"]]])){
            [self navigateToTarget:target fromPoint:point]; self.awaitingReposition=NO; return;
        }
    }
    [panel hideWheel];
}
- (void)confirmTrash:(NSArray<NSURL *> *)urls {
    [NSApp activateIgnoringOtherApps:YES];
    NSAlert *alert=[NSAlert new];
    alert.messageText=[NSString stringWithFormat:@"将 %ld 个项目移到废纸篓？",(long)urls.count];
    alert.informativeText=@"可在 FileOrbit 菜单栏撤销上一次整理。";
    [alert addButtonWithTitle:@"移到废纸篓"];
    [alert addButtonWithTitle:@"取消"];
    if([alert runModal]!=NSAlertFirstButtonReturn)return;
    [FOOrganizer.shared trashURLs:urls completion:^(NSInteger count,NSError *error){
        if(error)[FOAppDelegate.shared showError:@"移到废纸篓失败" message:error.localizedDescription];
        else [FOAppDelegate.shared toast:[NSString stringWithFormat:@"已移到废纸篓：%ld 个项目",(long)count]];
    }];
}
- (void)organize:(NSArray<NSURL *> *)urls folder:(NSURL *)folder {
    NSError *error=nil; NSInteger n=[FOOrganizer.shared organizeURLs:urls folder:folder error:&error];
    if(error)[FOAppDelegate.shared showError:@"整理失败" message:error.localizedDescription];
    else [FOAppDelegate.shared toast:[NSString stringWithFormat:@"已%@ %ld 个项目",FOStore.shared.copyMode?@"复制":@"移动",(long)n]];
}
- (void)createFolderForURLs:(NSArray<NSURL *> *)urls {
    [NSApp activateIgnoringOtherApps:YES];
    NSURL *parent=self.folderStack.lastObject;
    if (!parent) {
        NSOpenPanel *panel=NSOpenPanel.openPanel; panel.title=@"选择新文件夹的位置"; panel.prompt=@"选择"; panel.canChooseDirectories=YES; panel.canChooseFiles=NO;
        if([panel runModal]!=NSModalResponseOK)return;
        parent=panel.URL;
    }
    NSAlert *a=[NSAlert new]; a.messageText=@"新建文件夹"; a.informativeText=@"输入名称，文件会立即整理进去。"; [a addButtonWithTitle:@"创建并整理"]; [a addButtonWithTitle:@"取消"];
    NSTextField *field=[[NSTextField alloc]initWithFrame:NSMakeRect(0,0,280,24)]; field.placeholderString=@"例如：项目资料"; a.accessoryView=field;
    if([a runModal]!=NSAlertFirstButtonReturn)return; NSString *name=[field.stringValue stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if(!name.length || [name containsString:@"/"]){[FOAppDelegate.shared showError:@"名称无效" message:@"名称不能为空，也不能包含 /。"];return;}
    NSURL *folder=[parent URLByAppendingPathComponent:name isDirectory:YES]; NSError *error=nil;
    if(![NSFileManager.defaultManager createDirectoryAtURL:folder withIntermediateDirectories:NO attributes:nil error:&error]){[FOAppDelegate.shared showError:@"无法创建文件夹" message:error.localizedDescription];return;}
    [FOStore.shared addURL:folder]; [self organize:urls folder:folder];
}
@end

@implementation FOSettingsController
- (instancetype)init {
    NSWindow *w=[[NSWindow alloc]initWithContentRect:NSMakeRect(0,0,680,FOStore.shared.targets.count<=3?520:560) styleMask:NSWindowStyleMaskTitled|NSWindowStyleMaskClosable|NSWindowStyleMaskMiniaturizable|NSWindowStyleMaskResizable|NSWindowStyleMaskFullSizeContentView backing:NSBackingStoreBuffered defer:NO];
    w.title=@"FileOrbit"; w.titlebarAppearsTransparent=YES; w.titleVisibility=NSWindowTitleHidden; w.minSize=NSMakeSize(620,480); [w center]; w.releasedWhenClosed=NO;
    if((self=[super initWithWindow:w])){[self buildUI];[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshPreviewButton:) name:@"FOWheelVisibilityChanged" object:nil];} return self;
}
- (void)buildUI {
    NSVisualEffectView *v=[[NSVisualEffectView alloc]initWithFrame:self.window.contentView.bounds];
    v.material=NSVisualEffectMaterialWindowBackground; v.blendingMode=NSVisualEffectBlendingModeBehindWindow; v.state=NSVisualEffectStateFollowsWindowActiveState; v.autoresizingMask=NSViewWidthSizable|NSViewHeightSizable; self.window.contentView=v;

    NSImageView *mark=[[NSImageView alloc]init]; mark.image=[NSImage imageNamed:@"AppIcon"]; mark.imageScaling=NSImageScaleProportionallyUpOrDown;
    NSTextField *title=[NSTextField labelWithString:@"FileOrbit"]; title.font=[NSFont systemFontOfSize:24 weight:NSFontWeightBold];
    NSTextField *sub=[NSTextField labelWithString:@"拖动文件，快速归档"]; sub.font=[NSFont systemFontOfSize:13]; sub.textColor=NSColor.secondaryLabelColor;
    NSStackView *titles=[NSStackView stackViewWithViews:@[title,sub]]; titles.orientation=NSUserInterfaceLayoutOrientationVertical; titles.alignment=NSLayoutAttributeLeading; titles.spacing=2;
    NSStackView *header=[NSStackView stackViewWithViews:@[mark,titles,[NSView new]]]; header.orientation=NSUserInterfaceLayoutOrientationHorizontal; header.alignment=NSLayoutAttributeCenterY; header.spacing=12;
    [mark.widthAnchor constraintEqualToConstant:34].active=YES; [mark.heightAnchor constraintEqualToConstant:34].active=YES;

    NSTextField *section=[NSTextField labelWithString:@"转盘文件夹"]; section.font=[NSFont systemFontOfSize:13 weight:NSFontWeightSemibold];
    NSTextField *sectionHelp=[NSTextField labelWithString:@"前 7 个文件夹显示在首层；在扇区停留可进入子文件夹"]; sectionHelp.font=[NSFont systemFontOfSize:11]; sectionHelp.textColor=NSColor.tertiaryLabelColor;
    NSStackView *sectionTitles=[NSStackView stackViewWithViews:@[section,sectionHelp]]; sectionTitles.orientation=NSUserInterfaceLayoutOrientationVertical; sectionTitles.alignment=NSLayoutAttributeLeading; sectionTitles.spacing=2;

    self.table=[NSTableView new]; NSTableColumn *col=[[NSTableColumn alloc]initWithIdentifier:@"folder"]; [self.table addTableColumn:col]; self.table.headerView=nil; self.table.rowHeight=58; self.table.delegate=self; self.table.dataSource=self; self.table.backgroundColor=NSColor.clearColor; self.table.selectionHighlightStyle=NSTableViewSelectionHighlightStyleRegular; self.table.intercellSpacing=NSMakeSize(0,2);
    NSScrollView *scroll=[NSScrollView new]; scroll.documentView=self.table; scroll.hasVerticalScroller=YES; scroll.autohidesScrollers=YES; scroll.drawsBackground=YES; scroll.backgroundColor=[NSColor colorWithRed:.972 green:.976 blue:.980 alpha:1]; scroll.borderType=NSNoBorder; scroll.wantsLayer=YES; scroll.layer.cornerRadius=14; scroll.layer.borderWidth=.7; scroll.layer.borderColor=[NSColor colorWithRed:.25 green:.31 blue:.36 alpha:.14].CGColor;

    NSButton *add=[NSButton buttonWithTitle:@"添加" target:self action:@selector(addFolder:)]; add.image=[NSImage imageWithSystemSymbolName:@"folder.badge.plus" accessibilityDescription:nil]; add.imagePosition=NSImageLeading;
    NSButton *create=[NSButton buttonWithTitle:@"新建" target:self action:@selector(createFolder:)]; create.image=[NSImage imageWithSystemSymbolName:@"plus" accessibilityDescription:nil]; create.imagePosition=NSImageLeading;
    NSButton *rename=[NSButton buttonWithTitle:@"重命名" target:self action:@selector(renameFolder:)]; rename.image=[NSImage imageWithSystemSymbolName:@"pencil" accessibilityDescription:nil]; rename.imagePosition=NSImageLeading;
    NSButton *remove=[NSButton buttonWithTitle:@"移除" target:self action:@selector(removeFolder:)]; remove.image=[NSImage imageWithSystemSymbolName:@"minus" accessibilityDescription:nil]; remove.imagePosition=NSImageLeading;
    [add setAccessibilityLabel:@"添加文件夹"]; add.toolTip=@"选择现有文件夹";
    [create setAccessibilityLabel:@"新建文件夹"]; create.toolTip=@"创建新的归档文件夹";
    [rename setAccessibilityLabel:@"重命名显示名称"]; rename.toolTip=@"修改转盘中的显示名称";
    [remove setAccessibilityLabel:@"从转盘移除"]; remove.toolTip=@"仅从转盘移除，不删除文件夹";
    for(NSButton *button in @[add,create,rename,remove]){button.bezelStyle=NSBezelStyleRounded;button.controlSize=NSControlSizeRegular;}
    NSStackView *buttons=[NSStackView stackViewWithViews:@[add,create,rename,remove,[NSView new]]]; buttons.orientation=NSUserInterfaceLayoutOrientationHorizontal; buttons.spacing=8;

    NSTextField *modeLabel=[NSTextField labelWithString:@"归档方式"]; modeLabel.font=[NSFont systemFontOfSize:13 weight:NSFontWeightSemibold];
    NSTextField *modeHelp=[NSTextField labelWithString:@"“移动”可通过菜单栏撤销"]; modeHelp.font=[NSFont systemFontOfSize:11]; modeHelp.textColor=NSColor.tertiaryLabelColor;
    NSStackView *modeTitles=[NSStackView stackViewWithViews:@[modeLabel,modeHelp]]; modeTitles.orientation=NSUserInterfaceLayoutOrientationVertical; modeTitles.alignment=NSLayoutAttributeLeading; modeTitles.spacing=2;
    self.mode=[NSSegmentedControl segmentedControlWithLabels:@[@"移动",@"复制"] trackingMode:NSSegmentSwitchTrackingSelectOne target:self action:@selector(modeChanged:)]; self.mode.selectedSegment=FOStore.shared.copyMode?1:0; self.mode.controlSize=NSControlSizeLarge;
    self.previewButton=[NSButton buttonWithTitle:@"预览转盘" target:self action:@selector(previewWheel:)]; self.previewButton.image=[NSImage imageWithSystemSymbolName:@"eye" accessibilityDescription:nil]; self.previewButton.imagePosition=NSImageLeading; self.previewButton.bezelStyle=NSBezelStyleRounded; self.previewButton.controlSize=NSControlSizeLarge;
    [self.previewButton setAccessibilityLabel:@"预览或关闭归档转盘"];
    NSStackView *modeRow=[NSStackView stackViewWithViews:@[modeTitles,[NSView new],self.mode,self.previewButton]]; modeRow.orientation=NSUserInterfaceLayoutOrientationHorizontal; modeRow.alignment=NSLayoutAttributeCenterY; modeRow.spacing=12;

    NSTextField *colorLabel=[NSTextField labelWithString:@"转盘颜色"]; colorLabel.font=[NSFont systemFontOfSize:13 weight:NSFontWeightSemibold];
    NSTextField *colorHelp=[NSTextField labelWithString:@"点击色块，自由选择转盘颜色"]; colorHelp.font=[NSFont systemFontOfSize:11]; colorHelp.textColor=NSColor.tertiaryLabelColor;
    NSStackView *colorTitles=[NSStackView stackViewWithViews:@[colorLabel,colorHelp]]; colorTitles.orientation=NSUserInterfaceLayoutOrientationVertical; colorTitles.alignment=NSLayoutAttributeLeading; colorTitles.spacing=2;
    self.colorWell=[[NSColorWell alloc]initWithFrame:NSMakeRect(0,0,56,32)]; self.colorWell.color=FOStore.shared.accentColor; self.colorWell.target=self; self.colorWell.action=@selector(colorChanged:); self.colorWell.continuous=YES; [self.colorWell setAccessibilityLabel:@"自定义转盘颜色"];
    [self.colorWell.widthAnchor constraintEqualToConstant:56].active=YES; [self.colorWell.heightAnchor constraintEqualToConstant:32].active=YES;
    NSStackView *colorRow=[NSStackView stackViewWithViews:@[colorTitles,[NSView new],self.colorWell]]; colorRow.orientation=NSUserInterfaceLayoutOrientationHorizontal; colorRow.alignment=NSLayoutAttributeCenterY; colorRow.spacing=8;

    NSView *separator=[NSView new]; separator.wantsLayer=YES; separator.layer.backgroundColor=[NSColor colorWithRed:.25 green:.31 blue:.36 alpha:.12].CGColor;
    NSStackView *preferences=[NSStackView stackViewWithViews:@[modeRow,separator,colorRow]]; preferences.orientation=NSUserInterfaceLayoutOrientationVertical; preferences.alignment=NSLayoutAttributeLeading; preferences.spacing=12; preferences.translatesAutoresizingMaskIntoConstraints=NO;
    NSView *preferencesCard=[NSView new]; preferencesCard.wantsLayer=YES; preferencesCard.layer.cornerRadius=15; preferencesCard.layer.backgroundColor=[NSColor colorWithRed:.965 green:.971 blue:.977 alpha:1].CGColor; preferencesCard.layer.borderWidth=.7; preferencesCard.layer.borderColor=[NSColor colorWithRed:.25 green:.31 blue:.36 alpha:.12].CGColor; [preferencesCard addSubview:preferences];
    [NSLayoutConstraint activateConstraints:@[[preferences.leadingAnchor constraintEqualToAnchor:preferencesCard.leadingAnchor constant:16],[preferences.trailingAnchor constraintEqualToAnchor:preferencesCard.trailingAnchor constant:-16],[preferences.topAnchor constraintEqualToAnchor:preferencesCard.topAnchor constant:14],[preferences.bottomAnchor constraintEqualToAnchor:preferencesCard.bottomAnchor constant:-14],[modeRow.widthAnchor constraintEqualToAnchor:preferences.widthAnchor],[separator.widthAnchor constraintEqualToAnchor:preferences.widthAnchor],[separator.heightAnchor constraintEqualToConstant:.7],[colorRow.widthAnchor constraintEqualToAnchor:preferences.widthAnchor]]];

    NSStackView *stack=[NSStackView stackViewWithViews:@[header,sectionTitles,scroll,buttons,preferencesCard]]; stack.orientation=NSUserInterfaceLayoutOrientationVertical; stack.alignment=NSLayoutAttributeLeading; stack.spacing=12; stack.translatesAutoresizingMaskIntoConstraints=NO; [v addSubview:stack];
    [stack setCustomSpacing:22 afterView:header]; [stack setCustomSpacing:8 afterView:sectionTitles]; [stack setCustomSpacing:16 afterView:buttons];
    NSLayoutConstraint *preferredWidth=[stack.widthAnchor constraintEqualToAnchor:v.widthAnchor constant:-60]; preferredWidth.priority=750;
    self.folderHeight=[scroll.heightAnchor constraintEqualToConstant:MAX(164,MIN(234,FOStore.shared.targets.count*60+12))]; self.folderHeight.priority=750;
    [NSLayoutConstraint activateConstraints:@[preferredWidth,self.folderHeight,[stack.centerXAnchor constraintEqualToAnchor:v.centerXAnchor],[stack.leadingAnchor constraintGreaterThanOrEqualToAnchor:v.leadingAnchor constant:30],[stack.trailingAnchor constraintLessThanOrEqualToAnchor:v.trailingAnchor constant:-30],[stack.widthAnchor constraintLessThanOrEqualToConstant:760],[stack.topAnchor constraintEqualToAnchor:v.topAnchor constant:38],[stack.bottomAnchor constraintLessThanOrEqualToAnchor:v.bottomAnchor constant:-24],[header.widthAnchor constraintEqualToAnchor:stack.widthAnchor],[sectionTitles.widthAnchor constraintEqualToAnchor:stack.widthAnchor],[scroll.widthAnchor constraintEqualToAnchor:stack.widthAnchor],[scroll.heightAnchor constraintGreaterThanOrEqualToConstant:110],[buttons.widthAnchor constraintEqualToAnchor:stack.widthAnchor],[preferencesCard.widthAnchor constraintEqualToAnchor:stack.widthAnchor]]];
}
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{return FOStore.shared.targets.count;}
- (NSView *)tableView:(NSTableView *)tv viewForTableColumn:(NSTableColumn *)tc row:(NSInteger)row {
    NSDictionary *t=FOStore.shared.targets[row]; NSTableCellView *cell=[NSTableCellView new];
    NSImageView *icon=[NSImageView new]; icon.image=[NSImage imageWithSystemSymbolName:@"folder.fill" accessibilityDescription:nil]; icon.contentTintColor=FOStore.shared.accentColor; icon.symbolConfiguration=[NSImageSymbolConfiguration configurationWithPointSize:19 weight:NSFontWeightMedium]; icon.translatesAutoresizingMaskIntoConstraints=NO; [icon setAccessibilityElement:NO];
    NSTextField *name=[NSTextField labelWithString:t[@"name"]]; name.font=[NSFont systemFontOfSize:14 weight:NSFontWeightSemibold]; name.translatesAutoresizingMaskIntoConstraints=NO;
    NSTextField *path=[NSTextField labelWithString:t[@"path"]]; path.font=[NSFont systemFontOfSize:11]; path.textColor=NSColor.secondaryLabelColor; path.lineBreakMode=NSLineBreakByTruncatingMiddle; path.translatesAutoresizingMaskIntoConstraints=NO;
    [cell addSubview:icon];[cell addSubview:name];[cell addSubview:path];
    [NSLayoutConstraint activateConstraints:@[[icon.leadingAnchor constraintEqualToAnchor:cell.leadingAnchor constant:14],[icon.centerYAnchor constraintEqualToAnchor:cell.centerYAnchor],[icon.widthAnchor constraintEqualToConstant:24],[icon.heightAnchor constraintEqualToConstant:24],[name.leadingAnchor constraintEqualToAnchor:icon.trailingAnchor constant:10],[name.topAnchor constraintEqualToAnchor:cell.topAnchor constant:9],[path.leadingAnchor constraintEqualToAnchor:name.leadingAnchor],[path.trailingAnchor constraintEqualToAnchor:cell.trailingAnchor constant:-12],[path.topAnchor constraintEqualToAnchor:name.bottomAnchor constant:3]]]; return cell;
}
- (void)refresh{[self.table reloadData];self.folderHeight.constant=MAX(164,MIN(234,FOStore.shared.targets.count*60+12));self.mode.selectedSegment=FOStore.shared.copyMode?1:0;self.colorWell.color=FOStore.shared.accentColor;}
- (void)addFolder:(id)sender { NSOpenPanel *p=NSOpenPanel.openPanel;p.title=@"添加到归档转盘";p.prompt=@"添加";p.canChooseDirectories=YES;p.canChooseFiles=NO;p.allowsMultipleSelection=YES;if([p runModal]==NSModalResponseOK){for(NSURL*u in p.URLs)[FOStore.shared addURL:u];[self refresh];}}
- (void)createFolder:(id)sender { NSOpenPanel *p=NSOpenPanel.openPanel;p.title=@"选择新文件夹的位置";p.prompt=@"选择";p.canChooseDirectories=YES;p.canChooseFiles=NO;if([p runModal]!=NSModalResponseOK)return;NSAlert*a=[NSAlert new];a.messageText=@"新建归档文件夹";[a addButtonWithTitle:@"创建"];[a addButtonWithTitle:@"取消"];NSTextField*f=[[NSTextField alloc]initWithFrame:NSMakeRect(0,0,280,24)];f.placeholderString=@"文件夹名称";a.accessoryView=f;if([a runModal]!=NSAlertFirstButtonReturn)return;NSString*n=[f.stringValue stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];if(!n.length||[n containsString:@"/"])return;NSURL*u=[p.URL URLByAppendingPathComponent:n isDirectory:YES];NSError*e=nil;if([NSFileManager.defaultManager createDirectoryAtURL:u withIntermediateDirectories:NO attributes:nil error:&e]){[FOStore.shared addURL:u];[self refresh];}else[FOAppDelegate.shared showError:@"无法创建文件夹" message:e.localizedDescription];}
- (void)removeFolder:(id)sender{NSInteger r=self.table.selectedRow;if(r>=0&&r<FOStore.shared.targets.count){[FOStore.shared.targets removeObjectAtIndex:r];[FOStore.shared save];[self refresh];}}
- (void)renameFolder:(id)sender{NSInteger r=self.table.selectedRow;if(r<0||r>=FOStore.shared.targets.count)return;NSAlert*a=[NSAlert new];a.messageText=@"修改转盘显示名称";[a addButtonWithTitle:@"保存"];[a addButtonWithTitle:@"取消"];NSTextField*f=[[NSTextField alloc]initWithFrame:NSMakeRect(0,0,280,24)];f.stringValue=FOStore.shared.targets[r][@"name"];a.accessoryView=f;if([a runModal]==NSAlertFirstButtonReturn&&f.stringValue.length){FOStore.shared.targets[r][@"name"]=f.stringValue;[FOStore.shared save];[self refresh];}}
- (void)modeChanged:(id)sender{FOStore.shared.copyMode=self.mode.selectedSegment==1;[FOStore.shared save];}
- (void)colorChanged:(NSColorWell *)sender{FOStore.shared.accentColor=sender.color;[FOStore.shared save];}
- (void)refreshPreviewButton:(NSNotification *)n{BOOL visible=FOAppDelegate.shared.wheelPanel.manualVisible;self.previewButton.title=visible?@"关闭预览":@"预览转盘";self.previewButton.image=[NSImage imageWithSystemSymbolName:(visible?@"eye.slash":@"eye") accessibilityDescription:nil];}
- (void)previewWheel:(id)sender{
    FOWheelPanel *panel=FOAppDelegate.shared.wheelPanel;
    if(panel.manualVisible){[panel hideWheel];return;}
    NSScreen *screen=self.window.screen ?: NSScreen.mainScreen;
    NSRect window=self.window.frame, visible=screen.visibleFrame;
    CGFloat x=NSMaxX(window)+350<=NSMaxX(visible)?NSMaxX(window)+175:(NSMinX(window)-350>=NSMinX(visible)?NSMinX(window)-175:NSMidX(visible));
    [panel showNear:NSMakePoint(x,NSMidY(window))];panel.manualVisible=YES;[self refreshPreviewButton:nil];
}
@end

@implementation FOAppDelegate
static FOAppDelegate *SharedDelegate;
+ (instancetype)shared{return SharedDelegate;}
- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    SharedDelegate=self; self.wheelPanel=[FOWheelPanel new]; self.settings=[FOSettingsController new];
    self.statusItem=[NSStatusBar.systemStatusBar statusItemWithLength:NSSquareStatusItemLength]; self.statusItem.button.image=FOStatusIcon(); self.statusItem.button.toolTip=@"左键打开设置 · 右键更多操作"; self.statusItem.button.target=self; self.statusItem.button.action=@selector(statusClick:); [self.statusItem.button sendActionOn:NSEventMaskLeftMouseUp|NSEventMaskRightMouseUp];
    NSMenu *m=[NSMenu new]; [m addItemWithTitle:@"打开设置…" action:@selector(showSettings:) keyEquivalent:@","];
    self.undoItem=[m addItemWithTitle:@"撤销上一次整理" action:@selector(undo:) keyEquivalent:@"z"]; [m addItem:NSMenuItem.separatorItem];
    NSMenuItem *mode=[m addItemWithTitle:@"整理模式" action:nil keyEquivalent:@""]; NSMenu *sm=[NSMenu new]; NSMenuItem *mv=[sm addItemWithTitle:@"移动文件" action:@selector(moveMode:) keyEquivalent:@""];mv.tag=1001;NSMenuItem*cp=[sm addItemWithTitle:@"复制文件" action:@selector(copyMode:) keyEquivalent:@""];cp.tag=1002;mode.submenu=sm;
    [m addItem:NSMenuItem.separatorItem]; [m addItemWithTitle:@"退出 FileOrbit" action:@selector(quit:) keyEquivalent:@"q"]; for(NSMenuItem*i in m.itemArray)i.target=self;for(NSMenuItem*i in sm.itemArray)i.target=self;self.statusMenu=m;[self refreshMenu];
    __weak typeof(self) weakSelf=self; self.globalMonitor=[NSEvent addGlobalMonitorForEventsMatchingMask:NSEventMaskFlagsChanged handler:^(NSEvent*e){[weakSelf flags:e.modifierFlags];}]; self.localMonitor=[NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskFlagsChanged handler:^NSEvent*(NSEvent*e){[weakSelf flags:e.modifierFlags];return e;}];
    self.globalMouseMonitor=[NSEvent addGlobalMonitorForEventsMatchingMask:NSEventMaskLeftMouseDown|NSEventMaskRightMouseDown handler:^(NSEvent*e){if(weakSelf.wheelPanel.manualVisible)[weakSelf.wheelPanel hideWheel];}];
    self.localKeyMonitor=[NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskKeyDown handler:^NSEvent*(NSEvent*e){if(e.keyCode==53&&weakSelf.wheelPanel.manualVisible){[weakSelf.wheelPanel hideWheel];return nil;}return e;}];
    self.timer=[NSTimer scheduledTimerWithTimeInterval:.08 repeats:YES block:^(NSTimer*t){[weakSelf poll];}];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(storeChanged:) name:@"FOStoreChanged" object:nil];[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshMenu) name:@"FOUndoChanged" object:nil];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,.35*NSEC_PER_SEC),dispatch_get_main_queue(),^{[weakSelf showSettings:nil];});
}
- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag{[self showSettings:nil];return YES;}
- (void)flags:(NSEventModifierFlags)f{if(!(f&NSEventModifierFlagShift)&&self.wheelPanel.visible&&!self.wheelPanel.wheel.dragActive&&!self.wheelPanel.manualVisible)[self.wheelPanel hideWheel];}
- (void)poll{BOOL shift=(CGEventSourceFlagsState(kCGEventSourceStateCombinedSessionState)&kCGEventFlagMaskShift)!=0;BOOL mouse=CGEventSourceButtonState(kCGEventSourceStateCombinedSessionState,kCGMouseButtonLeft);if(shift&&mouse&&!self.wheelPanel.visible)[self.wheelPanel showNear:NSEvent.mouseLocation];else if((!shift||!mouse)&&self.wheelPanel.visible&&!self.wheelPanel.wheel.dragActive&&!self.wheelPanel.manualVisible)[self.wheelPanel hideWheel];}
- (void)storeChanged:(NSNotification*)n{[self.wheelPanel.wheel reloadTargets];[self.settings refresh];[self refreshMenu];}
- (void)refreshMenu{self.undoItem.enabled=FOOrganizer.shared.lastTransfers.count>0;[self.statusMenu itemWithTag:1001].state=FOStore.shared.copyMode?NSControlStateValueOff:NSControlStateValueOn;[self.statusMenu itemWithTag:1002].state=FOStore.shared.copyMode?NSControlStateValueOn:NSControlStateValueOff;}
- (void)statusClick:(id)sender{NSEventType type=NSApp.currentEvent.type;if(type==NSEventTypeRightMouseUp||type==NSEventTypeRightMouseDown||NSApp.currentEvent.modifierFlags&NSEventModifierFlagControl)[NSMenu popUpContextMenu:self.statusMenu withEvent:NSApp.currentEvent forView:self.statusItem.button];else[self showSettings:nil];}
- (void)showSettings:(id)sender{if(self.wheelPanel.manualVisible)[self.wheelPanel hideWheel];[NSApp activateIgnoringOtherApps:YES];[self.settings showWindow:nil];[self.settings.window makeKeyAndOrderFront:nil];}
- (void)moveMode:(id)sender{FOStore.shared.copyMode=NO;[FOStore.shared save];}
- (void)copyMode:(id)sender{FOStore.shared.copyMode=YES;[FOStore.shared save];}
- (void)undo:(id)sender{NSError*e=nil;NSInteger n=[FOOrganizer.shared undo:&e];if(e)[self showError:@"撤销失败" message:e.localizedDescription];else[self toast:[NSString stringWithFormat:@"已撤销 %ld 个项目",(long)n]];}
- (void)quit:(id)sender{[NSApp terminate:nil];}
- (void)showError:(NSString*)title message:(NSString*)message{[NSApp activateIgnoringOtherApps:YES];NSAlert*a=[NSAlert new];a.alertStyle=NSAlertStyleWarning;a.messageText=title;a.informativeText=message;[a runModal];}
- (void)toast:(NSString*)message{NSPanel*p=[[NSPanel alloc]initWithContentRect:NSMakeRect(0,0,260,46) styleMask:NSWindowStyleMaskBorderless|NSWindowStyleMaskNonactivatingPanel backing:NSBackingStoreBuffered defer:NO];p.opaque=NO;p.backgroundColor=[NSColor colorWithWhite:.08 alpha:.92];p.level=NSFloatingWindowLevel;p.contentView.wantsLayer=YES;p.contentView.layer.cornerRadius=13;NSTextField*l=[NSTextField labelWithString:message];l.frame=NSMakeRect(18,12,224,22);l.font=[NSFont systemFontOfSize:14 weight:NSFontWeightSemibold];l.textColor=NSColor.whiteColor;l.alignment=NSTextAlignmentCenter;[p.contentView addSubview:l];NSRect s=NSScreen.mainScreen.visibleFrame;[p setFrameOrigin:NSMakePoint(NSMidX(s)-130,NSMaxY(s)-90)];[p orderFrontRegardless];dispatch_after(dispatch_time(DISPATCH_TIME_NOW,1.8*NSEC_PER_SEC),dispatch_get_main_queue(),^{[p orderOut:nil];});}
@end

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        if (argc > 2 && strcmp(argv[1], "--render-icon") == 0) return FORenderAppIcon([NSString stringWithUTF8String:argv[2]]) ? 0 : 1;
        if (argc > 2 && strcmp(argv[1], "--render-wheel") == 0) {
            [NSApplication sharedApplication];
            NSBitmapImageRep *bitmap=[[NSBitmapImageRep alloc]initWithBitmapDataPlanes:NULL pixelsWide:350 pixelsHigh:350 bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSCalibratedRGBColorSpace bytesPerRow:0 bitsPerPixel:0];
            NSGraphicsContext *context=[NSGraphicsContext graphicsContextWithBitmapImageRep:bitmap];
            FOWheelView *wheel=[[FOWheelView alloc]initWithFrame:NSMakeRect(0,0,350,350)];
            [NSGraphicsContext saveGraphicsState];[NSGraphicsContext setCurrentContext:context];[wheel drawRect:wheel.bounds];[context flushGraphics];[NSGraphicsContext restoreGraphicsState];
            NSData *png=[bitmap representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
            return [png writeToFile:[NSString stringWithUTF8String:argv[2]] atomically:YES]?0:1;
        }
        if (argc > 1 && strcmp(argv[1], "--self-test") == 0) {
            NSFileManager *fm = NSFileManager.defaultManager;
            NSURL *root = [[NSURL fileURLWithPath:NSTemporaryDirectory()] URLByAppendingPathComponent:[NSString stringWithFormat:@"FileOrbit-%@", NSUUID.UUID.UUIDString] isDirectory:YES];
            NSURL *sourceFolder = [root URLByAppendingPathComponent:@"source" isDirectory:YES];
            NSURL *targetFolder = [root URLByAppendingPathComponent:@"target" isDirectory:YES];
            NSError *error = nil;
            [fm createDirectoryAtURL:sourceFolder withIntermediateDirectories:YES attributes:nil error:&error];
            [fm createDirectoryAtURL:targetFolder withIntermediateDirectories:YES attributes:nil error:&error];
            NSURL *source = [sourceFolder URLByAppendingPathComponent:@"sample.txt"];
            [@"FileOrbit self test" writeToURL:source atomically:YES encoding:NSUTF8StringEncoding error:&error];
            BOOL originalMode = FOStore.shared.copyMode;
            FOStore.shared.copyMode = NO;
            NSInteger moved = [FOOrganizer.shared organizeURLs:@[source] folder:targetFolder error:&error];
            BOOL moveOK = moved == 1 && ![fm fileExistsAtPath:source.path] && [fm fileExistsAtPath:[targetFolder URLByAppendingPathComponent:@"sample.txt"].path];
            NSInteger undone = [FOOrganizer.shared undo:&error];
            BOOL undoOK = undone == 1 && [fm fileExistsAtPath:source.path];
            FOStore.shared.copyMode = YES;
            NSInteger copied = [FOOrganizer.shared organizeURLs:@[source] folder:targetFolder error:&error];
            BOOL copyOK = copied == 1 && [fm fileExistsAtPath:source.path] && [fm fileExistsAtPath:[targetFolder URLByAppendingPathComponent:@"sample.txt"].path];
            NSURL *trashSource = [sourceFolder URLByAppendingPathComponent:@"trash-test.txt"];
            [@"Recoverable test item" writeToURL:trashSource atomically:YES encoding:NSUTF8StringEncoding error:&error];
            __block NSInteger trashed = 0;
            __block NSError *trashError = nil;
            [FOOrganizer.shared trashURLs:@[trashSource] completion:^(NSInteger count, NSError *itemError) { trashed = count; trashError = itemError; }];
            BOOL trashOK = trashed == 1 && ![fm fileExistsAtPath:trashSource.path] && trashError == nil;
            NSInteger restored = [FOOrganizer.shared undo:&error];
            BOOL restoreOK = restored == 1 && [fm fileExistsAtPath:trashSource.path];
            FOStore.shared.copyMode = originalMode;
            [fm removeItemAtURL:root error:nil];
            BOOL trashSkipped = [trashError.domain isEqualToString:NSCocoaErrorDomain] && trashError.code == NSFileWriteNoPermissionError;
            BOOL passed = moveOK && undoOK && copyOK && ((trashOK && restoreOK) || trashSkipped) && error == nil;
            if (trashSkipped) fprintf(stdout, "FileOrbit trash self-test: SKIP (sandbox denied Trash access)\n");
            if (!passed) fprintf(stderr, "move=%d undo=%d copy=%d trash=%d restore=%d error=%s trashError=%s [%s:%ld]\n", moveOK, undoOK, copyOK, trashOK, restoreOK, error.localizedDescription.UTF8String ?: "none", trashError.localizedDescription.UTF8String ?: "none", trashError.domain.UTF8String ?: "none", (long)trashError.code);
            fprintf(stdout, "%s\n", passed ? "FileOrbit self-test: PASS" : "FileOrbit self-test: FAIL");
            return passed ? 0 : 1;
        }
        NSApplication *app=NSApplication.sharedApplication;
        FOAppDelegate *delegate=[FOAppDelegate new];
        app.delegate=delegate;
        [app setActivationPolicy:NSApplicationActivationPolicyAccessory];
        [app run];
    }
    return 0;
}
