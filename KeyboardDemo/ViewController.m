//
//  ViewController.m
//  KeyboardDemo
//
//  Created by __无邪_ on 2017/10/24.
//  Copyright © 2017年 __无邪_. All rights reserved.
//

#import "ViewController.h"
#import "QMUIKeyboardManager.h"
#import "QMUITextView.h"

static const CGFloat kBotKeyboardTextViewMinHeight = 40;
static const CGFloat kBotKeyboardTextViewMaxHeight = 200;


typedef enum : NSUInteger {
    min = 40,
    max = 200
} BotKeyboardTextViewHeight;


@interface NSMutableParagraphStyle (QMUI)

/**
 *  快速创建一个NSMutableParagraphStyle，等同于`qmui_paragraphStyleWithLineHeight:lineBreakMode:NSLineBreakByWordWrapping textAlignment:NSTextAlignmentLeft`
 *  @param  lineHeight      行高
 *  @return 一个NSMutableParagraphStyle对象
 */
+ (instancetype)qmui_paragraphStyleWithLineHeight:(CGFloat)lineHeight;

/**
 *  快速创建一个NSMutableParagraphStyle，等同于`qmui_paragraphStyleWithLineHeight:lineBreakMode:textAlignment:NSTextAlignmentLeft`
 *  @param  lineHeight      行高
 *  @param  lineBreakMode   换行模式
 *  @return 一个NSMutableParagraphStyle对象
 */
+ (instancetype)qmui_paragraphStyleWithLineHeight:(CGFloat)lineHeight lineBreakMode:(NSLineBreakMode)lineBreakMode;

/**
 *  快速创建一个NSMutableParagraphStyle
 *  @param  lineHeight      行高
 *  @param  lineBreakMode   换行模式
 *  @param  textAlignment   文本对齐方式
 *  @return 一个NSMutableParagraphStyle对象
 */
+ (instancetype)qmui_paragraphStyleWithLineHeight:(CGFloat)lineHeight lineBreakMode:(NSLineBreakMode)lineBreakMode textAlignment:(NSTextAlignment)textAlignment;
@end

@implementation NSMutableParagraphStyle (QMUI)

+ (instancetype)qmui_paragraphStyleWithLineHeight:(CGFloat)lineHeight {
    return [self qmui_paragraphStyleWithLineHeight:lineHeight lineBreakMode:NSLineBreakByWordWrapping textAlignment:NSTextAlignmentLeft];
}

+ (instancetype)qmui_paragraphStyleWithLineHeight:(CGFloat)lineHeight lineBreakMode:(NSLineBreakMode)lineBreakMode {
    return [self qmui_paragraphStyleWithLineHeight:lineHeight lineBreakMode:lineBreakMode textAlignment:NSTextAlignmentLeft];
}

+ (instancetype)qmui_paragraphStyleWithLineHeight:(CGFloat)lineHeight lineBreakMode:(NSLineBreakMode)lineBreakMode textAlignment:(NSTextAlignment)textAlignment {
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.minimumLineHeight = lineHeight;
    paragraphStyle.maximumLineHeight = lineHeight;
    paragraphStyle.lineBreakMode = lineBreakMode;
    paragraphStyle.alignment = textAlignment;
    return paragraphStyle;
}
@end

@interface ViewController ()<QMUIKeyboardManagerDelegate,QMUITextViewDelegate>

@property(nonatomic, strong) QMUIKeyboardManager *botKeyboardManager;
@property(nonatomic, strong) UIView *botKeyboardContainerView;
@property(nonatomic, strong) QMUITextView *botKeyboardTextView;
@property(nonatomic, assign) CGFloat botKeyboardHeight;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    
    [self.view addSubview:self.botKeyboardContainerView];
    self.botKeyboardManager = [[QMUIKeyboardManager alloc] initWithDelegate:self];
    // 设置键盘只接受 self.textView 的通知事件，如果当前界面有其他 UIResponder 导致键盘产生通知事件，则不会被接受
    [self.botKeyboardManager addTargetResponder:self.botKeyboardTextView];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)senderAction:(id)sender {
    if (self.botKeyboardTextView.isFirstResponder) {
        [self.botKeyboardTextView resignFirstResponder];
    }else{
        [self.botKeyboardTextView becomeFirstResponder];
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self.view endEditing:YES];
    self.botKeyboardTextView.text = nil;
}

#pragma mark - <QMUIKeyboardManagerDelegate>

- (void)keyboardWillChangeFrameWithUserInfo:(QMUIKeyboardUserInfo *)keyboardUserInfo {
    __weak __typeof(self)weakSelf = self;
    [QMUIKeyboardManager handleKeyboardNotificationWithUserInfo:keyboardUserInfo showBlock:^(QMUIKeyboardUserInfo *keyboardUserInfo) {
        [QMUIKeyboardManager animateWithAnimated:YES keyboardUserInfo:keyboardUserInfo animations:^{
            CGFloat distanceFromBottom = [QMUIKeyboardManager distanceFromMinYToBottomInView:weakSelf.view keyboardRect:keyboardUserInfo.endFrame];
            weakSelf.botKeyboardHeight = distanceFromBottom;
            weakSelf.botKeyboardContainerView.layer.transform = CATransform3DMakeTranslation(0, - distanceFromBottom - CGRectGetHeight(self.botKeyboardContainerView.bounds), 0);
        } completion:NULL];
    } hideBlock:^(QMUIKeyboardUserInfo *keyboardUserInfo) {
        [QMUIKeyboardManager animateWithAnimated:YES keyboardUserInfo:keyboardUserInfo animations:^{
            weakSelf.botKeyboardContainerView.layer.transform = CATransform3DIdentity;
            weakSelf.botKeyboardHeight = -kBotKeyboardTextViewMinHeight;
        } completion:NULL];
    }];
}

#pragma mark - <QMUITextViewDelegate>

- (void)textView:(QMUITextView *)textView newHeightAfterTextChanged:(CGFloat)height {
    height = fmin(kBotKeyboardTextViewMaxHeight, fmax(height, kBotKeyboardTextViewMinHeight));
    BOOL needsChangeHeight = CGRectGetHeight(textView.frame) != height;
    if (needsChangeHeight) {
        self.botKeyboardContainerView.frame = CGRectMake(0, CGRectGetHeight(self.view.frame) - self.botKeyboardHeight - height - 10, CGRectGetWidth(self.botKeyboardContainerView.frame), height + 10);
        self.botKeyboardTextView.frame = CGRectMake(CGRectGetMinX(self.botKeyboardTextView.frame), CGRectGetMinY(self.botKeyboardTextView.frame), CGRectGetWidth(self.botKeyboardTextView.frame), height);
    }
}

- (void)textView:(QMUITextView *)textView didPreventTextChangeInRange:(NSRange)range replacementText:(NSString *)replacementText {
   //文字不能超过 %@ 个字符
}

// 可以利用这个 delegate 来监听发送按钮的事件，当然，如果你习惯以前的方式的话，也可以继续在 textView:shouldChangeTextInRange:replacementText: 里处理
- (BOOL)textViewShouldReturn:(QMUITextView *)textView {

    textView.text = nil;
    
    // return YES 表示这次 return 按钮的点击是为了触发“发送”，而不是为了输入一个换行符
    return YES;
}


#pragma mark -

- (UIView *)botKeyboardContainerView {
    if (!_botKeyboardContainerView) {
        _botKeyboardContainerView = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, kBotKeyboardTextViewMinHeight + 10)];
        _botKeyboardContainerView.backgroundColor = [UIColor groupTableViewBackgroundColor];
        _botKeyboardContainerView.layer.borderWidth = 1;
        _botKeyboardContainerView.layer.borderColor = [UIColor groupTableViewBackgroundColor].CGColor;
        self.botKeyboardTextView = ({
            _botKeyboardTextView = [[QMUITextView alloc] initWithFrame:CGRectMake(5, 5, self.view.frame.size.width - 10, kBotKeyboardTextViewMinHeight)];
            _botKeyboardTextView.backgroundColor = [UIColor whiteColor];
            _botKeyboardTextView.font = [UIFont systemFontOfSize:16];
            _botKeyboardTextView.layer.cornerRadius = 8;
            _botKeyboardTextView.clipsToBounds = YES;
            _botKeyboardTextView.textContainerInset = UIEdgeInsetsMake(8, 7, 8, 7);
            _botKeyboardTextView.returnKeyType = UIReturnKeySend;
            _botKeyboardTextView.enablesReturnKeyAutomatically = YES;
            _botKeyboardTextView.typingAttributes = @{NSFontAttributeName: [UIFont systemFontOfSize:15],
                                               NSForegroundColorAttributeName: [UIColor grayColor],
                                               NSParagraphStyleAttributeName: [NSMutableParagraphStyle qmui_paragraphStyleWithLineHeight:20]};
            _botKeyboardTextView.autoResizable = YES;
            _botKeyboardTextView.placeholder = @"想法...";
            _botKeyboardTextView.maximumTextLength = 100;
            _botKeyboardTextView.delegate = self;
            _botKeyboardTextView;
        });
        [_botKeyboardContainerView addSubview:self.botKeyboardTextView];
    }
    return _botKeyboardContainerView;
}


@end
