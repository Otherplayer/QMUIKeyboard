//
//  QMUITextView.m
//  qmui
//
//  Created by QQMail on 14-8-5.
//  Copyright (c) 2014年 QMUI Team. All rights reserved.
//
#import "QMUITextView.h"
//#import "QMUICore.h"
//#import "QMUILabel.h"
//#import "NSObject+QMUI.h"
//#import "NSString+QMUI.h"
//#import "UITextView+QMUI.h"

#pragma mark - UIEdgeInsets

/// 获取UIEdgeInsets在水平方向上的值
CG_INLINE CGFloat
UIEdgeInsetsGetHorizontalValue(UIEdgeInsets insets) {
    return insets.left + insets.right;
}

/// 获取UIEdgeInsets在垂直方向上的值
CG_INLINE CGFloat
UIEdgeInsetsGetVerticalValue(UIEdgeInsets insets) {
    return insets.top + insets.bottom;
}

/// 将两个UIEdgeInsets合并为一个
CG_INLINE UIEdgeInsets
UIEdgeInsetsConcat(UIEdgeInsets insets1, UIEdgeInsets insets2) {
    insets1.top += insets2.top;
    insets1.left += insets2.left;
    insets1.bottom += insets2.bottom;
    insets1.right += insets2.right;
    return insets1;
}

@interface NSString (QMUI)
/**
 *  按照中文 2 个字符、英文 1 个字符的方式来计算文本长度
 */
- (NSUInteger)qmui_lengthWhenCountingNonASCIICharacterAsTwo;

/**
 *  将字符串里指定 range 的子字符串裁剪出来，会避免将 emoji 等 "character sequences" 拆散（一个 emoji 表情占用1-4个长度的字符）。
 *
 *  例如对于字符串“😊😞”，它的长度为4，在 lessValue 模式下，裁剪 (0, 1) 得到的是空字符串，裁剪 (0, 2) 得到的是“😊”。
 *  在非 lessValue 模式下，裁剪 (0, 1) 或 (0, 2)，得到的都是“😊”。
 *
 *  @param range 要裁剪的文字位置
 *  @param lessValue 裁剪时若遇到“character sequences”，是向下取整还是向上取整。
 *  @param countingNonASCIICharacterAsTwo 是否按照 英文 1 个字符长度、中文 2 个字符长度的方式来裁剪
 *  @return 裁剪完的字符
 */
- (NSString *)qmui_substringAvoidBreakingUpCharacterSequencesWithRange:(NSRange)range lessValue:(BOOL)lessValue countingNonASCIICharacterAsTwo:(BOOL)countingNonASCIICharacterAsTwo;

/**
 *  相当于 `qmui_substringAvoidBreakingUpCharacterSequencesWithRange:lessValue:YES` countingNonASCIICharacterAsTwo:NO
 *  @see qmui_substringAvoidBreakingUpCharacterSequencesWithRange:lessValue:countingNonASCIICharacterAsTwo:
 */
- (NSString *)qmui_substringAvoidBreakingUpCharacterSequencesWithRange:(NSRange)range;

@end
@implementation NSString (QMUI)
- (NSRange)transformRangeToDefaultModeWithRange:(NSRange)range {
    CGFloat strlength = 0.f;
    NSRange resultRange = NSMakeRange(NSNotFound, 0);
    NSInteger i = 0;
    for (i = 0; i < self.length; i++) {
        unichar character = [self characterAtIndex:i];
        if (isascii(character)) {
            strlength += 1;
        } else {
            strlength += 2;
        }
        if (strlength >= range.location + 1) {
            if (resultRange.location == NSNotFound) {
                resultRange.location = i;
            }
            
            if (range.length > 0 && strlength >= NSMaxRange(range)) {
                resultRange.length = i - resultRange.location + (strlength == NSMaxRange(range) ? 1 : 0);
                return resultRange;
            }
        }
    }
    return resultRange;
}
- (NSRange)downRoundRangeOfComposedCharacterSequencesForRange:(NSRange)range {
    if (range.length == 0) {
        return range;
    }
    
    NSRange resultRange = [self rangeOfComposedCharacterSequencesForRange:range];
    if (NSMaxRange(resultRange) > NSMaxRange(range)) {
        return [self downRoundRangeOfComposedCharacterSequencesForRange:NSMakeRange(range.location, range.length - 1)];
    }
    return resultRange;
}

- (NSUInteger)qmui_lengthWhenCountingNonASCIICharacterAsTwo {
    NSUInteger characterLength = 0;
    char *p = (char *)[self cStringUsingEncoding:NSUnicodeStringEncoding];
    for (NSInteger i = 0, l = [self lengthOfBytesUsingEncoding:NSUnicodeStringEncoding]; i < l; i++) {
        if (*p) {
            characterLength++;
        }
        p++;
    }
    return characterLength;
}
- (NSString *)qmui_substringAvoidBreakingUpCharacterSequencesWithRange:(NSRange)range lessValue:(BOOL)lessValue countingNonASCIICharacterAsTwo:(BOOL)countingNonASCIICharacterAsTwo {
    range = countingNonASCIICharacterAsTwo ? [self transformRangeToDefaultModeWithRange:range] : range;
    NSRange characterSequencesRange = lessValue ? [self downRoundRangeOfComposedCharacterSequencesForRange:range] : [self rangeOfComposedCharacterSequencesForRange:range];
    NSString *resultString = [self substringWithRange:characterSequencesRange];
    return resultString;
}

- (NSString *)qmui_substringAvoidBreakingUpCharacterSequencesWithRange:(NSRange)range {
    return [self qmui_substringAvoidBreakingUpCharacterSequencesWithRange:range lessValue:YES countingNonASCIICharacterAsTwo:NO];
}
@end



@interface UITextView (QMUI)

/**
 *  convert UITextRange to NSRange, for example, [self qmui_convertNSRangeFromUITextRange:self.markedTextRange]
 */
- (NSRange)qmui_convertNSRangeFromUITextRange:(UITextRange *)textRange;

/**
 *  设置 text 会让 selectedTextRange 跳到最后一个字符，导致在中间修改文字后光标会跳到末尾，所以设置前要保存一下，设置后恢复过来
 */
- (void)qmui_setTextKeepingSelectedRange:(NSString *)text;

/**
 *  设置 attributedText 会让 selectedTextRange 跳到最后一个字符，导致在中间修改文字后光标会跳到末尾，所以设置前要保存一下，设置后恢复过来
 */
- (void)qmui_setAttributedTextKeepingSelectedRange:(NSAttributedString *)attributedText;

/**
 *  [UITextView scrollRangeToVisible:] 并不会考虑 textContainerInset.bottom，所以使用这个方法来代替
 */
- (void)qmui_scrollCaretVisibleAnimated:(BOOL)animated;

@end
@implementation UITextView (QMUI)

- (NSRange)qmui_convertNSRangeFromUITextRange:(UITextRange *)textRange {
    NSInteger location = [self offsetFromPosition:self.beginningOfDocument toPosition:textRange.start];
    NSInteger length = [self offsetFromPosition:textRange.start toPosition:textRange.end];
    return NSMakeRange(location, length);
}

- (void)qmui_setTextKeepingSelectedRange:(NSString *)text {
    UITextRange *selectedTextRange = self.selectedTextRange;
    self.text = text;
    self.selectedTextRange = selectedTextRange;
}

- (void)qmui_setAttributedTextKeepingSelectedRange:(NSAttributedString *)attributedText {
    UITextRange *selectedTextRange = self.selectedTextRange;
    self.attributedText = attributedText;
    self.selectedTextRange = selectedTextRange;
}

- (void)qmui_scrollCaretVisibleAnimated:(BOOL)animated {
    if (CGRectIsEmpty(self.bounds)) {
        return;
    }
    
    CGRect caretRect = [self caretRectForPosition:self.selectedTextRange.end];
    
    // scrollEnabled 为 NO 时可能产生不合法的 rect 值 https://github.com/QMUI/QMUI_iOS/issues/205
    if (isinf(CGRectGetMinX(caretRect)) || isinf(CGRectGetMinY(caretRect))) {
        return;
    }
    
    CGFloat contentOffsetY = self.contentOffset.y;
    
    if (CGRectGetMinY(caretRect) == self.contentOffset.y + self.textContainerInset.top) {
        // 命中这个条件说明已经不用调整了，直接 return，避免继续走下面的判断，会重复调整，导致光标跳动
        return;
    }
    
    if (CGRectGetMinY(caretRect) < self.contentOffset.y + self.textContainerInset.top) {
        // 光标在可视区域上方，往下滚动
        contentOffsetY = CGRectGetMinY(caretRect) - self.textContainerInset.top - self.contentInset.top;
    } else if (CGRectGetMaxY(caretRect) > self.contentOffset.y + CGRectGetHeight(self.bounds) - self.textContainerInset.bottom - self.contentInset.bottom) {
        // 光标在可视区域下方，往上滚动
        contentOffsetY = CGRectGetMaxY(caretRect) - CGRectGetHeight(self.bounds) + self.textContainerInset.bottom + self.contentInset.bottom;
    } else {
        // 光标在可视区域内，不用调整
        return;
    }
    [self setContentOffset:CGPointMake(self.contentOffset.x, contentOffsetY) animated:animated];
}

@end









/// 系统 textView 默认的字号大小，用于 placeholder 默认的文字大小。实测得到，请勿修改。
const CGFloat kSystemTextViewDefaultFontPointSize = 12.0f;

/// 当系统的 textView.textContainerInset 为 UIEdgeInsetsZero 时，文字与 textView 边缘的间距。实测得到，请勿修改（在输入框font大于13时准确，小于等于12时，y有-1px的偏差）。
const UIEdgeInsets kSystemTextViewFixTextInsets = {0, 5, 0, 5};

@interface QMUITextView ()

@property(nonatomic, assign) BOOL debug;
@property(nonatomic, assign) BOOL shouldRejectSystemScroll;// 如果在 handleTextChanged: 里主动调整 contentOffset，则为了避免被系统的自动调整覆盖，会利用这个标记去屏蔽系统对 setContentOffset: 的调用

@property(nonatomic, strong) UILabel *placeholderLabel;

@property(nonatomic, weak)   id<QMUITextViewDelegate> originalDelegate;

@end

@implementation QMUITextView

@dynamic delegate;

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self didInitialized];
        self.tintColor = [UIColor grayColor];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self didInitialized];
    }
    return self;
}

- (void)didInitialized {
    self.debug = NO;
    self.delegate = self;
    self.scrollsToTop = NO;
    self.placeholderColor = [UIColor grayColor];
    self.placeholderMargins = UIEdgeInsetsZero;
    self.autoResizable = NO;
    self.maximumTextLength = NSUIntegerMax;
    self.shouldResponseToProgrammaticallyTextChanges = YES;
    
    self.placeholderLabel = [[UILabel alloc] init];
    self.placeholderLabel.font = [UIFont systemFontOfSize:kSystemTextViewDefaultFontPointSize];
    self.placeholderLabel.textColor = self.placeholderColor;
    self.placeholderLabel.numberOfLines = 0;
    self.placeholderLabel.alpha = 0;
    [self addSubview:self.placeholderLabel];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleTextChanged:) name:UITextViewTextDidChangeNotification object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.delegate = nil;
    self.originalDelegate = nil;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@; text.length: %@ | %@; markedTextRange: %@", [super description], @(self.text.length), @([self lengthWithString:self.text]), self.markedTextRange];
}

- (BOOL)isCurrentTextDifferentOfText:(NSString *)text {
    NSString *textBeforeChange = self.text;// UITextView 如果文字为空，self.text 永远返回 @"" 而不是 nil（即便你设置为 nil 后立即 get 出来也是）
    if ([textBeforeChange isEqualToString:text] || (textBeforeChange.length == 0 && !text)) {
        return NO;
    }
    return YES;
}

- (void)setText:(NSString *)text {
    NSString *textBeforeChange = self.text;
    BOOL textDifferent = [self isCurrentTextDifferentOfText:text];
    
    // 如果前后文字没变化，则什么都不做
    if (!textDifferent) {
        [super setText:text];
        return;
    }
    
    // 前后文字发生变化，则要根据是否主动接管 delegate 来决定是否要询问 delegate
    if (self.shouldResponseToProgrammaticallyTextChanges) {
        BOOL shouldChangeText = YES;
        if ([self.delegate respondsToSelector:@selector(textView:shouldChangeTextInRange:replacementText:)]) {
            shouldChangeText = [self.delegate textView:self shouldChangeTextInRange:NSMakeRange(0, textBeforeChange.length) replacementText:text];
        }
        
        if (!shouldChangeText) {
            // 不应该改变文字，所以连 super 都不调用，直接结束方法
            return;
        }
        
        // 应该改变文字，则调用 super 来改变文字，然后主动调用 textViewDidChange:
        [super setText:text];
        if ([self.delegate respondsToSelector:@selector(textViewDidChange:)]) {
            [self.delegate textViewDidChange:self];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:UITextViewTextDidChangeNotification object:self];
        
    } else {
        [super setText:text];
        
        // 如果不需要主动接管事件，则只要触发内部的监听即可，不用调用 delegate 系列方法
        [self handleTextChanged:self];
    }
}

- (void)setAttributedText:(NSAttributedString *)attributedText {
    NSString *textBeforeChange = self.attributedText.string;
    BOOL textDifferent = [self isCurrentTextDifferentOfText:attributedText.string];
    
    // 如果前后文字没变化，则什么都不做
    if (!textDifferent) {
        [super setAttributedText:attributedText];
        return;
    }
    
    // 前后文字发生变化，则要根据是否主动接管 delegate 来决定是否要询问 delegate
    if (self.shouldResponseToProgrammaticallyTextChanges) {
        BOOL shouldChangeText = YES;
        if ([self.delegate respondsToSelector:@selector(textView:shouldChangeTextInRange:replacementText:)]) {
            shouldChangeText = [self.delegate textView:self shouldChangeTextInRange:NSMakeRange(0, textBeforeChange.length) replacementText:attributedText.string];
        }
        
        if (!shouldChangeText) {
            // 不应该改变文字，所以连 super 都不调用，直接结束方法
            return;
        }
        
        // 应该改变文字，则调用 super 来改变文字，然后主动调用 textViewDidChange:
        [super setAttributedText:attributedText];
        if ([self.delegate respondsToSelector:@selector(textViewDidChange:)]) {
            [self.delegate textViewDidChange:self];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:UITextViewTextDidChangeNotification object:self];
        
    } else {
        [super setAttributedText:attributedText];
        
        // 如果不需要主动接管事件，则只要触发内部的监听即可，不用调用 delegate 系列方法
        [self handleTextChanged:self];
    }
}

- (void)setTypingAttributes:(NSDictionary<NSString *,id> *)typingAttributes {
    [super setTypingAttributes:typingAttributes];
    [self updatePlaceholderStyle];
}

- (void)setFont:(UIFont *)font {
    [super setFont:font];
    [self updatePlaceholderStyle];
}

- (void)setTextColor:(UIColor *)textColor {
    [super setTextColor:textColor];
    [self updatePlaceholderStyle];
}

- (void)setTextAlignment:(NSTextAlignment)textAlignment {
    [super setTextAlignment:textAlignment];
    [self updatePlaceholderStyle];
}

- (void)setPlaceholder:(NSString *)placeholder {
    _placeholder = placeholder;
    if (!_placeholder) {
        _placeholder = @"";
    }
    self.placeholderLabel.attributedText = [[NSAttributedString alloc] initWithString:_placeholder attributes:self.typingAttributes];
    if (self.placeholderColor) {
        self.placeholderLabel.textColor = self.placeholderColor;
    }
    [self sendSubviewToBack:self.placeholderLabel];
    [self setNeedsLayout];
}

- (void)setPlaceholderColor:(UIColor *)placeholderColor {
    _placeholderColor = placeholderColor;
    self.placeholderLabel.textColor = _placeholderColor;
}

- (void)updatePlaceholderStyle {
    self.placeholder = self.placeholder;// 触发文字样式的更新
}

- (void)handleTextChanged:(id)sender {
    // 输入字符的时候，placeholder隐藏
    if(self.placeholder.length > 0) {
        [self updatePlaceholderLabelHidden];
    }
    
    QMUITextView *textView = nil;
    
    if ([sender isKindOfClass:[NSNotification class]]) {
        id object = ((NSNotification *)sender).object;
        if (object == self) {
            textView = (QMUITextView *)object;
        }
    } else if ([sender isKindOfClass:[QMUITextView class]]) {
        textView = (QMUITextView *)sender;
    }
    
    if (textView) {
        
        // 计算高度
        if (self.autoResizable) {
            
            CGFloat resultHeight = [textView sizeThatFits:CGSizeMake(CGRectGetWidth(self.bounds), CGFLOAT_MAX)].height;
            
            if (self.debug) NSLog(@"handleTextDidChange, text = %@, resultHeight = %f", textView.text, resultHeight);
            
            
            // 通知delegate去更新textView的高度
            if ([textView.originalDelegate respondsToSelector:@selector(textView:newHeightAfterTextChanged:)] && resultHeight != CGRectGetHeight(self.bounds)) {
                [textView.originalDelegate textView:self newHeightAfterTextChanged:resultHeight];
            }
        }
        
        // textView 尚未被展示到界面上时，此时过早进行光标调整会计算错误
        if (!textView.window) {
            return;
        }
        
        self.shouldRejectSystemScroll = YES;
        // 用 dispatch 延迟一下，因为在文字发生换行时，系统自己会做一些滚动，我们要延迟一点才能避免被系统的滚动覆盖
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.shouldRejectSystemScroll = NO;
            [self qmui_scrollCaretVisibleAnimated:NO];
        });
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (self.placeholder.length > 0) {
        UIEdgeInsets labelMargins = UIEdgeInsetsConcat(UIEdgeInsetsConcat(self.textContainerInset, self.placeholderMargins), kSystemTextViewFixTextInsets);
        CGFloat limitWidth = CGRectGetWidth(self.bounds) - UIEdgeInsetsGetHorizontalValue(self.contentInset) - UIEdgeInsetsGetHorizontalValue(labelMargins);
        CGFloat limitHeight = CGRectGetHeight(self.bounds) - UIEdgeInsetsGetVerticalValue(self.contentInset) - UIEdgeInsetsGetVerticalValue(labelMargins);
        CGSize labelSize = [self.placeholderLabel sizeThatFits:CGSizeMake(limitWidth, limitHeight)];
        labelSize.height = fmin(limitHeight, labelSize.height);
        self.placeholderLabel.frame = CGRectMake(labelMargins.left, labelMargins.top, limitWidth, labelSize.height);
    }
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    [self updatePlaceholderLabelHidden];
}

- (void)updatePlaceholderLabelHidden {
    if (self.text.length == 0 && self.placeholder.length > 0) {
        self.placeholderLabel.alpha = 1;
    } else {
        self.placeholderLabel.alpha = 0;// 用alpha来让placeholder隐藏，从而尽量避免因为显隐 placeholder 导致 layout
    }
}

- (NSUInteger)lengthWithString:(NSString *)string {
    return self.shouldCountingNonASCIICharacterAsTwo ? string.qmui_lengthWhenCountingNonASCIICharacterAsTwo : string.length;
}

#pragma mark - <QMUITextViewDelegate>

- (BOOL)textView:(QMUITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if (self.debug) NSLog(@"textView.text(%@ | %@) = %@\nmarkedTextRange = %@\nrange = %@\ntext = %@", @(textView.text.length), @(textView.text.qmui_lengthWhenCountingNonASCIICharacterAsTwo), textView.text, textView.markedTextRange, NSStringFromRange(range), text);
    
    if ([text isEqualToString:@"\n"]) {
        if ([self.delegate respondsToSelector:@selector(textViewShouldReturn:)]) {
            BOOL shouldReturn = [self.delegate textViewShouldReturn:self];
            if (shouldReturn) {
                return NO;
            }
        }
    }
    
    if (textView.maximumTextLength < NSUIntegerMax) {
        
        // 如果是中文输入法正在输入拼音的过程中（markedTextRange 不为 nil），是不应该限制字数的（例如输入“huang”这5个字符，其实只是为了输入“黄”这一个字符），所以在 shouldChange 这里不会限制，而是放在 didChange 那里限制。
        BOOL isDeleting = range.length > 0 && text.length <= 0;
        if (isDeleting || textView.markedTextRange) {
            
            if ([textView.originalDelegate respondsToSelector:_cmd]) {
                return [textView.originalDelegate textView:textView shouldChangeTextInRange:range replacementText:text];
            }
            
            return YES;
        }
        
        NSUInteger rangeLength = self.shouldCountingNonASCIICharacterAsTwo ? [textView.text substringWithRange:range].qmui_lengthWhenCountingNonASCIICharacterAsTwo : range.length;
        BOOL textWillOutofMaximumTextLength = [self lengthWithString:textView.text] - rangeLength + [self lengthWithString:text] > textView.maximumTextLength;
        if (textWillOutofMaximumTextLength) {
            // 当输入的文本达到最大长度限制后，此时继续点击 return 按钮（相当于尝试插入“\n”），就会认为总文字长度已经超过最大长度限制，所以此次 return 按钮的点击被拦截，外界无法感知到有这个 return 事件发生，所以这里为这种情况做了特殊保护
            if ([self lengthWithString:textView.text] - rangeLength == textView.maximumTextLength && [text isEqualToString:@"\n"]) {
                if ([textView.originalDelegate respondsToSelector:_cmd]) {
                    // 不管外面 return YES 或 NO，都不允许输入了，否则会超出 maximumTextLength。
                    [textView.originalDelegate textView:textView shouldChangeTextInRange:range replacementText:text];
                    return NO;
                }
            }
            // 将要插入的文字裁剪成多长，就可以让它插入了
            NSInteger substringLength = textView.maximumTextLength - [self lengthWithString:textView.text] + rangeLength;
            
            if (substringLength > 0 && [self lengthWithString:text] > substringLength) {
                NSString *allowedText = [text qmui_substringAvoidBreakingUpCharacterSequencesWithRange:NSMakeRange(0, substringLength) lessValue:YES countingNonASCIICharacterAsTwo:self.shouldCountingNonASCIICharacterAsTwo];
                if ([self lengthWithString:allowedText] <= substringLength) {
                    textView.text = [textView.text stringByReplacingCharactersInRange:range withString:allowedText];
                    textView.selectedRange = NSMakeRange(range.location + substringLength, 0);
                    
                    if (!textView.shouldResponseToProgrammaticallyTextChanges) {
                        [textView.originalDelegate textViewDidChange:textView];
                    }
                }
            }
            
            if ([self.originalDelegate respondsToSelector:@selector(textView:didPreventTextChangeInRange:replacementText:)]) {
                [self.originalDelegate textView:textView didPreventTextChangeInRange:range replacementText:text];
            }
            return NO;
        }
    }
    
    if ([textView.originalDelegate respondsToSelector:_cmd]) {
        return [textView.originalDelegate textView:textView shouldChangeTextInRange:range replacementText:text];
    }
    
    return YES;
}

- (void)textViewDidChange:(QMUITextView *)textView {
    // 1、iOS 10 以下的版本，从中文输入法的候选词里选词输入，是不会走到 textView:shouldChangeTextInRange:replacementText: 的，所以要在这里截断文字
    // 2、如果是中文输入法正在输入拼音的过程中（markedTextRange 不为 nil），是不应该限制字数的（例如输入“huang”这5个字符，其实只是为了输入“黄”这一个字符），所以在 shouldChange 那边不会限制，而是放在 didChange 这里限制。
    if (!textView.markedTextRange) {
        if ([self lengthWithString:textView.text] > textView.maximumTextLength) {
            
            textView.text = [textView.text qmui_substringAvoidBreakingUpCharacterSequencesWithRange:NSMakeRange(0, textView.maximumTextLength) lessValue:YES countingNonASCIICharacterAsTwo:self.shouldCountingNonASCIICharacterAsTwo];
            
            if ([self.originalDelegate respondsToSelector:@selector(textView:didPreventTextChangeInRange:replacementText:)]) {
                // 如果是在这里被截断，是无法得知截断前光标所处的位置及要输入的文本的，所以只能将当前的 selectedRange 传过去，而 replacementText 为 nil
                [self.originalDelegate textView:textView didPreventTextChangeInRange:textView.selectedRange replacementText:nil];
            }
            
            if (textView.shouldResponseToProgrammaticallyTextChanges) {
                return;
            }
        }
    }
    if ([textView.originalDelegate respondsToSelector:_cmd]) {
        [textView.originalDelegate textViewDidChange:textView];
    }
}

#pragma mark - Delegate Proxy

- (void)setDelegate:(id<QMUITextViewDelegate>)delegate {
    self.originalDelegate = delegate != self ? delegate : nil;
    [super setDelegate:delegate ? self : nil];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    NSMethodSignature *a = [super methodSignatureForSelector:aSelector];
    NSMethodSignature *b = [(id)self.originalDelegate methodSignatureForSelector:aSelector];
    NSMethodSignature *result = a ? a : b;
    return result;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    if ([(id)self.originalDelegate respondsToSelector:anInvocation.selector]) {
        [anInvocation invokeWithTarget:(id)self.originalDelegate];
    }
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    BOOL a = [super respondsToSelector:aSelector];
    BOOL c = [self.originalDelegate respondsToSelector:aSelector];
    BOOL result = a || c;
    return result;
}

// 下面这两个方法比较特殊，无法通过 forwardInvocation: 的方式把消息发送给 self.originalDelegate，只会直接被调用，所以只能在 QMUITextView 内部实现这连个方法然后调用 originalDelegate 的对应方法
// 注意，测过 UITextView 默认没有实现任何 UIScrollViewDelegate 方法 from 2016-11-01 in iOS 10.1 by molice

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if ([self.originalDelegate respondsToSelector:_cmd]) {
        [self.originalDelegate scrollViewDidScroll:scrollView];
    }
}

- (void)setContentOffset:(CGPoint)contentOffset animated:(BOOL)animated {
    if (!self.shouldRejectSystemScroll) {
        [super setContentOffset:contentOffset animated:animated];
        if (self.debug) NSLog(@"%@, contentOffset.y = %.2f", NSStringFromSelector(_cmd), contentOffset.y);
    } else {
        if (self.debug) NSLog(@"被屏蔽的 %@, contentOffset.y = %.2f", NSStringFromSelector(_cmd), contentOffset.y);
    }
}

- (void)setContentOffset:(CGPoint)contentOffset {
    if (!self.shouldRejectSystemScroll) {
        [super setContentOffset:contentOffset];
        if (self.debug) NSLog(@"%@, contentOffset.y = %.2f", NSStringFromSelector(_cmd), contentOffset.y);
    } else {
        if (self.debug) NSLog(@"被屏蔽的 %@, contentOffset.y = %.2f", NSStringFromSelector(_cmd), contentOffset.y);
    }
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    if ([self.originalDelegate respondsToSelector:_cmd]) {
        [self.originalDelegate scrollViewDidZoom:scrollView];
    }
}

@end
