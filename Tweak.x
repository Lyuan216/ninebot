// Tweak.x — 九号出行(cn.ninebot.segway) 本地信息Cell文字替换
// 目标: NBBaseUIKit.InfoCell 内部的 UILabel
//
// 与原始文档代码的差异(已修 bug):
// 1. 原代码 %hook UILabel 的 -setText: 中先调用 %orig; 又在循环里第二次调用
//    %orig(@"替换文字") —— 同一个方法里 %orig 只能调一次，第二次调用是未定义行为，
//    在 arm64e 上极易崩溃。此处改为「先判断父视图，再决定传入什么参数」，只调一次 %orig。
// 2. 原循环遍历 parent 时判断的是 parent.class，但 InfoCell 的 label 常常是
//    cell.contentView 的直接子视图，遍历正常可命中；这里额外加入
//    NBBaseUIKit 前缀宽松匹配 + 可配置类名，避免版本升级后类名微调直接失效。
// 3. 加入 attributedText 的兜底处理，且不再丢失原文本样式。
// 4. 加入开关宏，便于按需只替换某一项(如只替换序列号)。

#import <UIKit/UIKit.h>

// ======================= 用户配置区 =======================
// 目标 Cell 类名(完整类名或部分前缀都支持)
static NSString *const kTargetCellClass   = @"NBBaseUIKit.InfoCell";

// 是否启用调试日志(连接 Console.app / 越狱设备的 syslog 查看)
static BOOL const kDebugLog = YES;

// 替换策略：命中目标 Cell 后的新文字。
// 留空(nil) 表示不整体替换，改为走下方「按原文字内容」映射表。
static NSString *const kGlobalReplacementText = nil;

// 按「原文字 -> 新文字」映射，只替换命中的行，其余行显示原值。
// 例如只想改序列号，就把 "序列号" 对应那一行改成你的值。
static NSDictionary<NSString *, NSString *> *ReplacementMap(void) {
    return @{
        // @"原文字内容" : @"新文字内容",
        // 示例（按需取消注释并改成你自己的值）：
        @"序列号" : @"0WDDG2511J6347",
        @"车架号" : @"294822513008630",
    };
}
// =========================================================

static BOOL IsTargetCell(UIView *view) {
    if (!view) return NO;
    NSString *cls = NSStringFromClass(view.class);
    if (!cls) return NO;
    // 完整类名匹配 或 后缀匹配(防止命名空间前缀变化)
    if ([cls isEqualToString:kTargetCellClass]) return YES;
    if ([cls hasSuffix:@".InfoCell"] || [cls hasSuffix:@"InfoCell"]) {
        // 仅在包含 NBBaseUIKit 时认定，避免误伤其他 InfoCell
        if ([cls containsString:@"NBBaseUIKit"]) return YES;
    }
    return NO;
}

// 判断某个 Label 是否位于目标 Cell 内部
static BOOL LabelInsideTargetCell(UILabel *label) {
    UIView *parent = label.superview;
    int guard = 0;
    while (parent && guard++ < 32) {
        if (IsTargetCell(parent)) return YES;
        parent = parent.superview;
    }
    return NO;
}

// 计算替换后的文字；返回 nil 表示保持原样
static NSString *ReplacedTextFor(NSString *original) {
    if (kGlobalReplacementText.length > 0) {
        return kGlobalReplacementText;
    }
    NSDictionary *map = ReplacementMap();
    if (original && map[original]) {
        return map[original];
    }
    return nil;
}

%hook UILabel

- (void)setText:(NSString *)text {
    NSString *finalText = text;
    if (text && LabelInsideTargetCell(self)) {
        NSString *replaced = ReplacedTextFor(text);
        if (replaced) {
            finalText = replaced;
        }
        if (kDebugLog) {
            NSLog(@"[LabelPatch] setText cell=%@ old=%@ new=%@",
                  NSStringFromClass(((UIView *)self).superview.class), text, finalText);
        }
    }
    // 只调用一次 %orig
    %orig(finalText);
}

- (void)setAttributedText:(NSAttributedString *)text {
    NSAttributedString *finalText = text;
    if (text.length > 0 && LabelInsideTargetCell(self)) {
        NSString *replaced = ReplacedTextFor(text.string);
        if (replaced) {
            // 保留原有属性(字体/颜色)，只换字符内容
            NSMutableAttributedString *m =
                [[NSMutableAttributedString alloc] initWithString:replaced
                                                       attributes:nil];
            if (text.length > 0) {
                NSDictionary *attrs = [text attributesAtIndex:0 effectiveRange:NULL];
                if (attrs) [m setAttributes:attrs range:NSMakeRange(0, m.length)];
            }
            finalText = m;
        }
        if (kDebugLog) {
            NSLog(@"[LabelPatch] setAttributedText old=%@", text.string);
        }
    }
    %orig(finalText);
}

%end
