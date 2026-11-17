# LabelPatch — 九号出行 InfoCell 文字替换 Tweak

## 文件清单
| 文件 | 作用 |
|---|---|
| `Tweak.x` | Hook 代码 |
| `Makefile` | Theos 编译配置 |
| `control` | deb 包描述 |

## 原始文档代码的 Bug（已修复）
1. **`%orig` 调用两次（严重，会崩溃）**
   原文在 `- (void)setText:` 里先 `%orig;`，再在循环里 `%orig(@"替换文字")`。
   同一方法内 `%orig` 只能调用一次，第二次在 arm64e 上属于未定义行为。
   修复方式：先判断父视图 → 计算最终字符串 → 只 `%orig(finalText)` 一次。

2. **原文本丢失 / 无法按行区分**
   原文无条件替换所有命中 Cell 的文字，无法只改序列号而不改车架号。
   修复：新增 `ReplacementMap()`，按「原文字 → 新文字」精确映射。

3. **`setAttributedText` 丢样式**
   原文 `[[NSAttributedString alloc] initWithString:@"替换文字"]` 会把颜色/字体全丢掉。
   修复：复制原文本的 attributes 再替换字符串。

4. **类名匹配过严**
   原文 `isEqualToString:@"NBBaseUIKit.InfoCell"`，前缀一变即失效。
   修复：完整匹配 + `NBBaseUIKit` 前缀宽松匹配。

5. **`INSTALL_TARGET_PROCESSES` 写成了 BundleID**
   该字段需要的是**可执行进程名**，不是 BundleID。

## 编译 & 安装
```bash
cd /data/data/com.termux/files/A1/LabelPatch
make package
make install THEOS_DEVICE_IP=<手机IP>
```

## 使用前必须确认
1. 安装 Theos 环境（含 SDK、`$THEOS` 环境变量）。
2. 用 FLEX 打开 App 的信息页，核对：
   - Cell 真实类名是否仍为 `NBBaseUIKit.InfoCell`
   - 序列号/车架号所在行的 `UILabel.text` 原文内容
3. 把核对到的原文填入 `Tweak.x` 的 `ReplacementMap()`。

## 注意
- 仅本地 UI 层替换，不影响服务器数据，重装/卸载即恢复。
- 依赖 Cydia Substrate / ElleKit（越狱环境）。
