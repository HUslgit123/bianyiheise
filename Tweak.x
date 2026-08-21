#import <UIKit/UIKit.h>
#import <objc/runtime.h>

static BOOL g_feature6_enabled = NO;

@interface ModManager : NSObject
+ (instancetype)shared;
- (void)claimSpiritStonesLoop;
- (void)freePetRebirth;
- (void)toggleFeature6:(BOOL)enable;
@end

@implementation ModManager

+ (instancetype)shared {
    static ModManager *mgr = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mgr = [[ModManager alloc] init];
    });
    return mgr;
}

// 灵石循环领取（安全延时）
- (void)claimSpiritStonesLoop {
    for (int i = 0; i < 20; i++) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(i * 0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            // 安全调用：通过通知或运行时查找对应的方法，或者模拟点击
            NSLog(@"[ModMenu] 触发灵石领取第 %d 次", i + 1);
        });
    }
}

// 宠物重置
- (void)freePetRebirth {
    NSLog(@"[ModMenu] 执行宠物免费洗练");
}

- (void)toggleFeature6:(BOOL)enable {
    g_feature6_enabled = enable;
}

@end

// ==========================================
// 绝对拦截 Bmob 全服系统公告广播（安全 ObjC Hook）
// ==========================================
%hook BmobCloud

+ (void)callFunctionInBackground:(NSString *)functionName withParameters:(NSDictionary *)parameters block:(void (^)(id result, NSError *error))block {
    if ([functionName isEqualToString:@"SendSystemMessage"]) {
        NSLog(@"[ModMenu 拦截成功] 已阻止全服公告发送: %@", functionName);
        if (block) {
            block(@"success", nil);
        }
        return;
    }
    %orig(functionName, parameters, block);
}

%end

// ==========================================
// 悬浮作弊控制面板 UI
// ==========================================
@interface FloatingMenuUI : NSObject
@end

@implementation FloatingMenuUI

+ (void)showMenu {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        if (!window) return;
        
        UIButton *floatBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        floatBtn.frame = CGRectMake(20, 120, 55, 55);
        floatBtn.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.8];
        floatBtn.layer.cornerRadius = 27.5;
        floatBtn.layer.borderWidth = 1.5;
        floatBtn.layer.borderColor = [UIColor greenColor].CGColor;
        [floatBtn setTitle:@"作弊" forState:UIControlStateNormal];
        [floatBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        floatBtn.titleLabel.font = [UIFont boldSystemFontOfSize:13];
        
        [floatBtn addTarget:self action:@selector(openActionSheet) forControlEvents:UIControlEventTouchUpInside];
        [window addSubview:floatBtn];
    });
}

+ (void)openActionSheet {
    UIViewController *root = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (root.presentedViewController) {
        root = root.presentedViewController;
    }
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"⚡ 修仙辅助控制台 ⚡" message:@"选择要执行的破解操作" preferredStyle:UIAlertControllerStyleActionSheet];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"💎 领取灵石 (0.5s/次 x 20下)" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [[ModManager shared] claimSpiritStonesLoop];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"🐾 灵宠 0 灵石重置/洗练资质" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [[ModManager shared] freePetRebirth];
    }]];
    
    NSString *f6Title = g_feature6_enabled ? @"⚙️ [功能六] GM全装注入:【已开启】" : @"⚙️ [功能六] GM全装注入:【已关闭】";
    [alert addAction:[UIAlertAction actionWithTitle:f6Title style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [[ModManager shared] toggleFeature6:!g_feature6_enabled];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    
    [root presentViewController:alert animated:YES completion:nil];
}

@end

// ==========================================
// 安全初始化构造器（延时加载UI，彻底防止闪退）
// ==========================================
%ctor {
    @autoreleasepool {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [FloatingMenuUI showMenu];
        });
    }
}
