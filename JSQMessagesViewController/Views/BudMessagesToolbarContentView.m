//
//  Created by Jesse Squires
//  http://www.jessesquires.com
//
//
//  Documentation
//  http://cocoadocs.org/docsets/JSQMessagesViewController
//
//
//  GitHub
//  https://github.com/jessesquires/JSQMessagesViewController
//
//
//  License
//  Copyright (c) 2014 Jesse Squires
//  Released under an MIT license: http://opensource.org/licenses/MIT
//

#import "BudMessagesToolbarContentView.h"
#import "UIView+JSQMessages.h"
#import "UIImage+JSQMessages.h"

CGFloat const kMaximumRecordingTimeInSeconds = 180.0;
const int kButtonSend = 0;
const int kButtonRegister = 1;

@interface BudMessagesToolbarContentView () <AVAudioRecorderDelegate>


@property (weak, nonatomic) IBOutlet JSQMessagesComposerTextView *textView;

@property (weak, nonatomic) IBOutlet UIView *leftBarButtonContainerView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *leftBarButtonContainerViewWidthConstraint;

@property (weak, nonatomic) IBOutlet UIView *rightBarButtonContainerView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *rightBarButtonContainerViewWidthConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *leftHorizontalSpacingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *rightHorizontalSpacingConstraint;

@property (weak, nonatomic) IBOutlet UIView *recordingView;
@property (weak, nonatomic) IBOutlet UIButton *cancelRecordingButton;
@property (weak, nonatomic) IBOutlet UIImageView *recordingImageView;
@property (weak, nonatomic) IBOutlet UILabel *lblRecordingTime;


@property(nonatomic,strong) AVAudioRecorder *recorder;
@property(nonatomic,strong) NSMutableDictionary *recorderSettings;
@property(nonatomic,strong) NSString *recorderFilePath;
@property(nonatomic,strong) AVAudioPlayer *audioPlayer;
@property(nonatomic,strong) NSString *audioFileName;

@end


@implementation BudMessagesToolbarContentView {
    completionBlockType successRecordingBlock;
    NSTimer *myTimer;
}

#pragma mark - Class methods

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass([BudMessagesToolbarContentView class])
                          bundle:[NSBundle bundleForClass:[BudMessagesToolbarContentView class]]];
}

#pragma mark - Initialization

- (void)awakeFromNib
{
    [super awakeFromNib];

    [self setTranslatesAutoresizingMaskIntoConstraints:NO];

    self.leftHorizontalSpacingConstraint.constant = 0;
    self.rightHorizontalSpacingConstraint.constant = 0;

    self.backgroundColor = [UIColor clearColor];
}

-(void)customizeForBud {
    [self.cancelRecordingButton setHidden:NO];
    
    [self.recordingImageView setImage:[UIImage jsq_bubbleImageFromBundleWithName:@"btnMicRed"]];

    [self showRecordingView:NO];
    [self setRightButton];
    [self setLeftButton];
    self.inMicMode = YES;
    self.textView.layer.cornerRadius = 15.f;
    self.textView.placeHolder = @"";
    
    self.textView.textContainerInset = UIEdgeInsetsMake(4, 8, 4, 8);    
}

-(void)setLeftButton {
    UIButton *leftButton = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *imgPlus = [UIImage jsq_bubbleImageFromBundleWithName:@"btnAddItemToChat"];
    [leftButton setImage:imgPlus forState:UIControlStateHighlighted];
    [leftButton setImage:imgPlus forState:UIControlStateDisabled];
    [leftButton setImage:imgPlus forState:UIControlStateNormal];
    [self setLeftBarButtonItem:leftButton];
}

-(void)showRecordingView:(BOOL)showit {
    [self.recordingView setHidden:!showit];
    [self.textView setHidden:showit];
    [self.leftBarButtonContainerView setHidden:showit];
    [self enableMicrophoneAnimation:showit];
    self.lblRecordingTime.text = @"0:00";
}

-(void)setRightButton {
    
    BOOL hasText = [self.textView hasText];
//    [self.recordingView setHidden:hasText];
    UIButton *btnRight;
    
    if (hasText) {
        btnRight = [self getRightButtonToSend];
        self.inMicMode = NO;
    }
    else {
        btnRight = [self getRightButtonToMic];
    }
    [btnRight.layer addAnimation:[CATransition animation] forKey:kCATransition];
    [btnRight setContentMode:UIViewContentModeCenter];
    [self setRightBarButtonItem:btnRight];
}

-(UIButton*)getRightButtonToMic {
    UIButton *returnButton = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *imgMic = [UIImage jsq_bubbleImageFromBundleWithName:@"btnMic"];
    [returnButton setImage:imgMic forState:UIControlStateHighlighted];
    [returnButton setImage:imgMic forState:UIControlStateDisabled];
    [returnButton setImage:imgMic forState:UIControlStateNormal];
    returnButton.tag = kButtonRegister;
    return returnButton;
}

-(UIButton*)getRightButtonToSend {
    UIButton *returnButton = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *normalImage = [UIImage jsq_bubbleImageFromBundleWithName:@"btnSend"];
    [returnButton setImage:normalImage forState:UIControlStateNormal];
    
    UIImage *imgSendOff = [UIImage jsq_bubbleImageFromBundleWithName:@"btnSendOff"];
    [returnButton setImage:imgSendOff forState:UIControlStateHighlighted];
    [returnButton setImage:imgSendOff forState:UIControlStateDisabled];
    
    returnButton.tag = kButtonSend;

    return returnButton;
}

-(void)setRightButtonToSend {
   [self setRightBarButtonItem:[self getRightButtonToSend]];
}

- (IBAction)actCancelRecording:(id)sender {
    [self showRecordingView:NO];
    [self setRightButton];
    self.inMicMode = YES;
    [_recorder stop];
    [_recorder deleteRecording];
    [myTimer invalidate];
    self.voiceMessage = nil;
}

-(void)startRecording {
    [self showRecordingView:YES];
    [self setRightButtonToSend];
    self.inMicMode = NO;
    self.voiceMessage = nil;
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *err = nil;
    [audioSession setCategory :AVAudioSessionCategoryPlayAndRecord error:&err];
    if (err) {
        NSLog(@"audioSession: %@ %ld %@", [err domain], (long)[err code], [[err userInfo] description]);
        return; }
    [audioSession setActive:YES error:&err];
    err = nil;
    if (err) {
        NSLog(@"audioSession: %@ %ld %@", [err domain], (long)[err code], [[err userInfo] description]);
        return; }
    
    _recorderSettings = [[NSMutableDictionary alloc] init];
    [_recorderSettings setValue :[NSNumber numberWithInt:kAudioFormatMPEG4AAC] forKey:AVFormatIDKey];
//    [_recorderSettings setValue:[NSNumber numberWithInt:AVAudioQualityMin] forKey:AVEncoderAudioQualityKey];
//    [_recorderSettings setValue :[NSNumber numberWithInt:16] forKey:AVEncoderBitRateKey];
    [_recorderSettings setValue:[NSNumber numberWithFloat:16000] forKey:AVSampleRateKey];
    [_recorderSettings setValue:[NSNumber numberWithInt: 1] forKey:AVNumberOfChannelsKey];
//    [_recorderSettings setValue:[NSNumber numberWithInt: 16] forKey:AVLinearPCMBitDepthKey];
    
//    [_recorderSettings setValue :[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsBigEndianKey];
//    [_recorderSettings setValue :[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsFloatKey];
    
    CFUUIDRef uuidRef = CFUUIDCreate(kCFAllocatorDefault);
    NSString *uuid = CFBridgingRelease(CFUUIDCreateString(kCFAllocatorDefault, uuidRef));
    CFRelease(uuidRef);
    _audioFileName = [NSString stringWithFormat:@"%@.m4a",uuid];
    
    _recorderFilePath = [self.voiceMessagesPath stringByAppendingPathComponent:_audioFileName];
    
    NSURL *url = [NSURL fileURLWithPath:_recorderFilePath];
    err = nil;
    _recorder = [[AVAudioRecorder alloc] initWithURL:url settings:_recorderSettings error:&err];
    if(!_recorder){
        NSLog(@"recorder: %@ %ld %@", [err domain], (long)[err code], [[err userInfo] description]);
        return;
    }
    
    //prepare to record
    [_recorder setDelegate:self];
    [_recorder prepareToRecord];
    _recorder.meteringEnabled = YES;
    
    BOOL audioHWAvailable = audioSession.inputAvailable;
    if (! audioHWAvailable) {
        NSLog(@"Error: there is no microphone hardware present!");
        return;
    }

    [_recorder recordForDuration:(NSTimeInterval) kMaximumRecordingTimeInSeconds];
    myTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateRecordingTime) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:myTimer forMode:NSDefaultRunLoopMode];
}

-(void)stopRecordingWithSuccessBlock:(completionBlockType)success {
    [self showRecordingView:NO];
    self.inMicMode = YES;
    [_recorder stop];
    [myTimer invalidate];
    if (success) {
        successRecordingBlock = success;
    }
}

-(BOOL)recordingInProgress {
    return [_recorder isRecording];
}

-(void)updateRecordingTime {
    if([_recorder isRecording])
    {
//        let min = Int(recorder.currentTime / 60)
//
//        let sec = Int(recorder.currentTime.truncatingRemainder(dividingBy: 60))
//        let playinTime = String(format: "%02d:%02d", min, sec)
//        audioTimer.text = playinTime
        
        int minutes = floor(_recorder.currentTime/60);
        int seconds = _recorder.currentTime - (minutes * 60);
        
        NSString *time = [[NSString alloc]
                          initWithFormat:@"%01d:%02d",
                          minutes, seconds];
        _lblRecordingTime.text = time;
    }
}

-(void)enableMicrophoneAnimation:(BOOL)animateit {
    if (animateit) {
        CABasicAnimation *theAnimation;
        theAnimation=[CABasicAnimation animationWithKeyPath:@"opacity"];
        theAnimation.duration=0.6;
        theAnimation.repeatCount= FLT_MAX;
        theAnimation.autoreverses=YES;
        theAnimation.fromValue=[NSNumber numberWithFloat:1.0];
        theAnimation.toValue=[NSNumber numberWithFloat:0.1];
        
        [self.recordingImageView.layer addAnimation:theAnimation forKey:@"animateOpacity"];
    }
    else {
        [self.recordingImageView.layer removeAllAnimations];
    }
}


#pragma mark - AVAudioRecorder delegate

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag {
    if (flag) {
        self.voiceMessage = recorder.url;
        AVAudioSession *session = [AVAudioSession sharedInstance];
        NSError *error;
        [session setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&error];
        if (successRecordingBlock) successRecordingBlock();
        self.voiceMessage = nil;
    }
    else {
        self.voiceMessage = nil;
    }
}

/* if an error occurs while encoding it will be reported to the delegate. */
- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError * __nullable)error {
    if (error) {
        NSLog(@"error encoding file");
        self.voiceMessage = nil;
    }
    else {
        NSLog(@"file encoded successfullly");
    }
}

#pragma mark - Setters

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    [super setBackgroundColor:backgroundColor];
    self.leftBarButtonContainerView.backgroundColor = backgroundColor;
    self.rightBarButtonContainerView.backgroundColor = backgroundColor;
}

- (void)setLeftBarButtonItem:(UIButton *)leftBarButtonItem
{
    if (_leftBarButtonItem) {
        [_leftBarButtonItem removeFromSuperview];
    }

    if (!leftBarButtonItem) {
        _leftBarButtonItem = nil;
        self.leftHorizontalSpacingConstraint.constant = 0.0f;
        self.leftBarButtonItemWidth = 0.0f;
        self.leftBarButtonContainerView.hidden = YES;
        return;
    }

    if (CGRectEqualToRect(leftBarButtonItem.frame, CGRectZero)) {
        leftBarButtonItem.frame = self.leftBarButtonContainerView.bounds;
    }

    self.leftBarButtonContainerView.hidden = NO;
    self.leftHorizontalSpacingConstraint.constant = 0;
    self.leftBarButtonItemWidth = CGRectGetWidth(leftBarButtonItem.frame);

    [leftBarButtonItem setTranslatesAutoresizingMaskIntoConstraints:NO];

    [self.leftBarButtonContainerView addSubview:leftBarButtonItem];
    [self.leftBarButtonContainerView jsq_pinAllEdgesOfSubview:leftBarButtonItem];
    [self setNeedsUpdateConstraints];

    _leftBarButtonItem = leftBarButtonItem;
}

- (void)setLeftBarButtonItemWidth:(CGFloat)leftBarButtonItemWidth
{
    self.leftBarButtonContainerViewWidthConstraint.constant = leftBarButtonItemWidth;
    [self setNeedsUpdateConstraints];
}

- (void)setRightBarButtonItem:(UIButton *)rightBarButtonItem
{
    if (_rightBarButtonItem) {
        [_rightBarButtonItem removeFromSuperview];
    }

    if (!rightBarButtonItem) {
        _rightBarButtonItem = nil;
        self.rightHorizontalSpacingConstraint.constant = 0.0f;
        self.rightBarButtonItemWidth = 0.0f;
        self.rightBarButtonContainerView.hidden = YES;
        return;
    }

    if (CGRectEqualToRect(rightBarButtonItem.frame, CGRectZero)) {
        rightBarButtonItem.frame = self.rightBarButtonContainerView.bounds;
    }
    [rightBarButtonItem setContentEdgeInsets:UIEdgeInsetsMake(0, 8, 0, 8)];
    self.rightBarButtonContainerView.hidden = NO;
    self.rightBarButtonItemWidth = CGRectGetWidth(rightBarButtonItem.frame);

    [rightBarButtonItem setTranslatesAutoresizingMaskIntoConstraints:NO];

    [self.rightBarButtonContainerView addSubview:rightBarButtonItem];
    [self.rightBarButtonContainerView jsq_pinAllEdgesOfSubview:rightBarButtonItem];
    [self setNeedsUpdateConstraints];

    _rightBarButtonItem = rightBarButtonItem;
}

- (void)setRightBarButtonItemWidth:(CGFloat)rightBarButtonItemWidth
{
    self.rightBarButtonContainerViewWidthConstraint.constant = rightBarButtonItemWidth;
    [self setNeedsUpdateConstraints];
}

- (void)setRightContentPadding:(CGFloat)rightContentPadding
{
    self.rightHorizontalSpacingConstraint.constant = rightContentPadding;
    [self setNeedsUpdateConstraints];
}

- (void)setLeftContentPadding:(CGFloat)leftContentPadding
{
    self.leftHorizontalSpacingConstraint.constant = leftContentPadding;
    [self setNeedsUpdateConstraints];
}

#pragma mark - Getters

- (CGFloat)leftBarButtonItemWidth
{
    return self.leftBarButtonContainerViewWidthConstraint.constant;
}

- (CGFloat)rightBarButtonItemWidth
{
    return self.rightBarButtonContainerViewWidthConstraint.constant;
}

- (CGFloat)rightContentPadding
{
    return self.rightHorizontalSpacingConstraint.constant;
}

- (CGFloat)leftContentPadding
{
    return self.leftHorizontalSpacingConstraint.constant;
}

#pragma mark - UIView overrides

- (void)setNeedsDisplay
{
    [super setNeedsDisplay];
    [self.textView setNeedsDisplay];
}

@end
