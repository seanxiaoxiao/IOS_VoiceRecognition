//
//  ViewController.m
//  VoiceRecognition
//
//  Created by Xiao Xiao on 8/12/14.
//  Copyright (c) 2014 SeanLionheart. All rights reserved.
//
#import <AVFoundation/AVFoundation.h>
#import "ViewController.h"
#import "VoiceApi.h"
#import "AQRecorder.h"

@interface ViewController ()

@end

@implementation ViewController {
    IBOutlet UITextView *statusTextView;
    AVAudioPlayer *player;
    AQRecorder *recorder;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self setupAudioSession];
    
    // The song is https://www.youtube.com/watch?v=XDvZ3Ye48rE
    NSURL *resourceURL = [[NSBundle mainBundle] URLForResource:@"song" withExtension:@"mp3"];
    player = [[AVAudioPlayer alloc] initWithContentsOfURL:resourceURL error:nil];
    
    // The recorder is from an Apple Sample app SpeakHere, https://developer.apple.com/library/ios/samplecode/SpeakHere/Introduction/Intro.html
    recorder = new AQRecorder();
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupAudioSession
{
    // Configure audio unit with kAudioUnitSubType_VoiceProcessingIO, which has the echo cancellation feature.
    AudioUnit _rioUnit;
    AudioComponentDescription desc;
    desc.componentType = kAudioUnitType_Output;
    desc.componentSubType = kAudioUnitSubType_VoiceProcessingIO;
    desc.componentManufacturer = kAudioUnitManufacturer_Apple;
    desc.componentFlags = 0;
    desc.componentFlagsMask = 0;
    
    AudioComponent comp = AudioComponentFindNext(NULL, &desc);
    AudioComponentInstanceNew(comp, &_rioUnit);
    
    UInt32 one = 1;
    AudioUnitSetProperty(_rioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, 1, &one, sizeof(one));
    AudioUnitSetProperty(_rioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Output, 0, &one, sizeof(one));
    AudioUnitInitialize(_rioUnit);
    
    // Configure the audio session
    AVAudioSession *sessionInstance = [AVAudioSession sharedInstance];
    [sessionInstance setCategory:AVAudioSessionCategoryPlayAndRecord
                     withOptions:AVAudioSessionCategoryOptionMixWithOthers
                           error:NULL];
    [sessionInstance overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:NULL];
    statusTextView.text = @"Done Configuring the Audio Session";
}

- (IBAction)playBackgroundMusic:(id)sender
{
    if ([player isPlaying]) {
        [player pause];
        statusTextView.text = @"Background Music Paused";
    } else {
        [player play];
        statusTextView.text = @"Background Music Playing";
    }
}

- (IBAction)pressRecording:(id)sender
{
    if (recorder->IsRunning()) {
        recorder->StopRecord();
        statusTextView.text = @"Done Recording";
    } else {
        recorder->StartRecord(CFSTR("recordedFile.wav"));
        statusTextView.text = @"Recording";
    }
}

- (IBAction)voiceRecognition:(id)sender
{
    statusTextView.text = [[VoiceApi sharedApi] sendVoice];
}


@end
