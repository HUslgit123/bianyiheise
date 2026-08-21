#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>

// ==========================================
// 内存地址计算辅助宏 (基地址 0x100000000)
// ==========================================
static uintptr_t get_slide(void) {
    return _dyld_get_image_vmaddr_slide(0);
}

static uintptr_t get_addr(uintptr_t offset) {
    return get_slide() + (offset - 0x100000000);
}

// ==========================================
// 函数指针定义
// ==========================================
// 灵石发奖
typedef void (*FUN_1000703e8_t)(void);
// 制造倒计时判定
typedef void (*FUN_10031f14c_t)(long param_1);
// 强化材料扣减
typedef void (*FUN_10035f1e4_t)(long param_1);
// 宠物免费洗练
typedef void (*FUN_10077a7f4_t)(void);
// 充值/GM按钮处理
typedef void (*FUN_1005e7944_t)(void *param_1);

static FUN_1000703e8_t orig_FUN_1000703e8 = NULL;
static FUN_10031f14c_t orig_FUN_10031f14c = NULL;
static FUN_10035f1e4_t orig_FUN_10035f1e4 = NULL;
static FUN_1005e7944_t orig_FUN_1005e7944 = NULL;

// 全局功能开关（功能六独立开关）
static BOOL g_feature6_enabled = NO;

// ==========================================
// 功能一：绝对拦截 Bmob 全服系统公告广播
// ==========================================
%hook BmobCloud

+ (void)callFunctionInBackground:(NSString *)functionName withParameters:(NSDictionary *)parameters block:(void (^)(id result, NSError *error))block {
    if ([functionName isEqualToString:@"SendSystemMessage"]) {
        // 彻底阻断发送，伪造成功回调，防止游戏逻辑挂起
        if (block) {
            block(@"success", nil);
        }
        return;
    }
    %orig(functionName, parameters, block);
}

%end

// ==========================================
// 功能三：强化升星零消耗 (拦截扣材料函数)
// ==========================================
void hook_FUN_10035f1e4(long param_1) {
    // 空实现，不执行任何材料和代币扣除
    return;
}

// ==========================================
// 功能四：制造 0 秒秒完成 (强制入参满足完成阈值 4 < param_1)
// ==========================================
void hook_FUN_10031f14c(long param_1) {
    if (orig_FUN_10031f14c) {
        orig_FUN_10031f14c(5); // 恒定传入 5，立即触发完成分支
    }
}

// ==========================================
// 功能五：劫持 arc4random 保证 100% 突破成功
// ==========================================
%hookf(uint32_t, arc4random) {
    // 恒定返回 0，突破成功率与极品判定必过
    return 0;
}

%hookf(uint32_t, arc4random_uniform, uint32_t upper_bound) {
    return 0;
}

// ==========================================
// 业务调度管理类
// ==========================================
@interface ModManager : NSObject
+ (instancetype)shared;
- (void)claimSpiritStonesLoop;
- (void)freePetRebirth;
- (void)triggerFeature6_InjectGear;
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

// 功能二：领取灵石间隔 0.5 秒，循环执行 20 次
- (void)claimSpiritStonesLoop {
    FUN_1000703e8_t claimFunc = (FUN_1000703e8_t)get_addr(0x1000703e8);
    for (int i = 0; i < 20; i++) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(i * 0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            claimFunc();
        });
    }
}

// 功能五：直接调用 10 万灵石洗练函数 (0 消耗)
- (void)freePetRebirth {
    FUN_10077a7f4_t rebirthFunc = (FUN_10077a7f4_t)get_addr(0x10077a7f4);
    rebirthFunc();
}

// 功能六：方案一直接触发 LPCZButton[6] 全神装注入
- (void)triggerFeature6_InjectGear {
    if (!g_feature6_enabled) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:@"功能六开关当前处于关闭状态，请先开启！" preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
        return;
    }

    // 遍历抓取内存中的 BagViewController
    // 获取 LPCZButton 数组的索引 6
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    UIViewController *rootVC = keyWindow.rootViewController;
    
    FUN_1005e7944_t czFunc = (FUN_1005e7944_t)get_addr(0x1005e7944);
    
    // 如果无法直接获取到按钮实例，构造临时指针或直接以 NULL 触发
    czFunc(NULL);
}

- (void)toggleFeature6:(BOOL)enable {
    g_feature6_enabled = enable;
}

@end

// ==========================================
// 悬浮作弊控制面板 UI
// ==========================================
@interface FloatingMenuUI : UIView
@end

@implementation FloatingMenuUI

+ (void)showMenu {
    static UIWindow *menuWindow = nil;
    if (!menuWindow) {
        menuWindow = [[UIWindow alloc] initWithFrame:CGRectMake(20, 100, 60, 60)];
        menuWindow.windowLevel = UIWindowLevelStatusBar + 100;
        menuWindow.backgroundColor = [UIColor clearColor];
        
        UIButton *floatBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        floatBtn.frame = CGRectMake(0, 0, 60, 60);
        floatBtn.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.7];
        floatBtn.layer.cornerRadius = 30;
        floatBtn.layer.borderWidth = 1.5;
        floatBtn.layer.borderColor = [UIColor greenColor].CGColor;
        [floatBtn setTitle:@"作弊" forState:UIControlStateNormal];
        [floatBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        floatBtn.titleLabel.font = [UIFont boldSystemFontOfSize:14];
        
        [floatBtn addTarget:self action:@selector(openActionSheet) forControlEvents:UIControlEventTouchUpInside];
        [menuWindow addSubview:floatBtn];
        menuWindow.hidden = NO;
    }
}

+ (void)openActionSheet {
    UIViewController *root = [UIApplication sharedApplication].keyWindow.rootViewController;
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
    
    [alert addAction:[UIAlertAction actionWithTitle:@"🎁 执行功能六：一键全装备注入 (LPCZ[6])" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [[ModManager shared] triggerFeature6_InjectGear];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    
    [root presentViewController:alert animated:YES completion:nil];
}

@end

// ==========================================
// 初始化构造器
// ==========================================
%ctor {
    @autoreleasepool {
        // 绑定 C 函数 Inline Hook
        MSHookFunction((void *)get_addr(0x10035f1e4), (void *)hook_FUN_10035f1e4, (void **)&orig_FUN_10035f1e4);
        MSHookFunction((void *)get_addr(0x10031f14c), (void *)hook_FUN_10031f14c, (void **)&orig_FUN_10031f14c);
        
        // 游戏启动 3 秒后显示悬浮作弊球
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [FloatingMenuUI showMenu];
        });
    }
}
