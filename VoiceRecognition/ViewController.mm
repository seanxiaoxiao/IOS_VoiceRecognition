//
//  ViewController.m
//  VoiceRecognition
//
//  Created by Xiao Xiao on 8/12/14.
//  Copyright (c) 2014 SeanLionheart. All rights reserved.
//
#import <AVFoundation/AVFoundation.h>
#include <pthread.h>

#import "ViewController.h"
#import "VoiceApi.h"

#define kOutputBus 0
#define kInputBus 1
#define kSampleRate 44100

static pthread_mutex_t outputAudioFileLock;

@interface ViewController ()

@property (nonatomic, assign) ExtAudioFileRef mAudioFileRef;

@property (nonatomic, assign) BOOL recording;

@property (nonatomic, assign) AudioUnit audioUnit;

@end

@implementation ViewController {
    IBOutlet UITextView *statusTextView;
    AVAudioPlayer *player;
    NSTimer *timer;
    AudioStreamBasicDescription _audioFormat;
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
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

static OSStatus recordingCallback(void *inRefCon, AudioUnitRenderActionFlags *ioActionFlags,
                                  const AudioTimeStamp *inTimeStamp,
                                  UInt32 inBusNumber,
                                  UInt32 inNumberFrames,
                                  AudioBufferList *ioData)  {
    AudioBufferList bufferList;
    
    SInt16 samples[inNumberFrames];
    memset(&samples, 0, sizeof(samples));
    
    bufferList.mNumberBuffers = 1;
    bufferList.mBuffers[0].mData = samples;
    bufferList.mBuffers[0].mNumberChannels = 1;
    bufferList.mBuffers[0].mDataByteSize = inNumberFrames * sizeof(SInt16);
    
    ViewController* THIS = THIS = (__bridge ViewController *)inRefCon;
    
    OSStatus status = AudioUnitRender(THIS.audioUnit,
                                      ioActionFlags,
                                      inTimeStamp,
                                      kInputBus,
                                      inNumberFrames, &bufferList);
    if (noErr != status) {
        return noErr;
    }
    
    pthread_mutex_lock(&outputAudioFileLock);
    {
        ExtAudioFileWriteAsync(THIS.mAudioFileRef, inNumberFrames, &bufferList);
    }
    pthread_mutex_unlock(&outputAudioFileLock);
    
    return noErr;
}


- (void)setupAudioSession
{
    // Configure audio unit with kAudioUnitSubType_VoiceProcessingIO, which has the echo cancellation feature.
    pthread_mutex_init(&outputAudioFileLock, NULL);
    
    AudioComponentDescription desc;
    desc.componentType = kAudioUnitType_Output;
    desc.componentSubType = kAudioUnitSubType_VoiceProcessingIO;
    desc.componentManufacturer = kAudioUnitManufacturer_Apple;
    desc.componentFlags = 0;
    desc.componentFlagsMask = 0;
    
    AudioComponent comp = AudioComponentFindNext(NULL, &desc);
    AudioComponentInstanceNew(comp, &_audioUnit);
    
    UInt32 one = 1;
    
    AURenderCallbackStruct callbackStruct;
    callbackStruct.inputProc = recordingCallback;
    callbackStruct.inputProcRefCon = (__bridge void *)self;
    
    AudioUnitSetProperty(_audioUnit, kAudioOutputUnitProperty_SetInputCallback,
                         kAudioUnitScope_Global,
                         kInputBus,
                         &callbackStruct,
                         sizeof(callbackStruct));
    
    _audioFormat.mSampleRate = kSampleRate;
    _audioFormat.mFormatID = kAudioFormatLinearPCM;
    _audioFormat.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    _audioFormat.mFramesPerPacket = 1;
    _audioFormat.mChannelsPerFrame = 1;
    _audioFormat.mBitsPerChannel = 16;
    _audioFormat.mBytesPerPacket = 2;
    _audioFormat.mBytesPerFrame = 2;
    
    AudioUnitSetProperty(_audioUnit, kAudioUnitProperty_StreamFormat,
                         kAudioUnitScope_Output,
                         kInputBus,
                         &_audioFormat,
                         sizeof(_audioFormat));
    AudioUnitSetProperty(_audioUnit, kAudioUnitProperty_StreamFormat,
                         kAudioUnitScope_Input,
                         kOutputBus,
                         &_audioFormat,
                         sizeof(_audioFormat));
    AudioUnitSetProperty(_audioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, 1, &one, sizeof(one));
    AudioUnitSetProperty(_audioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Output, 0, &one, sizeof(one));
    
    
    // Configure the audio session
    AVAudioSession *sessionInstance = [AVAudioSession sharedInstance];
    [sessionInstance setCategory:AVAudioSessionCategoryPlayAndRecord
                     withOptions:AVAudioSessionCategoryOptionDuckOthers | AVAudioSessionCategoryOptionAllowBluetooth | AVAudioSessionCategoryOptionDefaultToSpeaker
                           error:NULL];
    
    [sessionInstance overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
    
    [[AVAudioSession sharedInstance] setActive:YES error:NULL];
    AudioUnitInitialize(_audioUnit);
    AudioOutputUnitStart(_audioUnit);

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
    if (self.recording) {
        statusTextView.text = @"Done Recording";
        self.recording = NO;
        
    } else {
        statusTextView.text = @"Recording";
        self.recording = YES;
        pthread_mutex_lock(&outputAudioFileLock);
        {
            NSString *recordFile = [NSTemporaryDirectory() stringByAppendingPathComponent:@"recordedFile.wav"];
            CFURLRef destinationURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)recordFile, kCFURLPOSIXPathStyle, false);

            OSStatus setupErr = ExtAudioFileCreateWithURL(destinationURL, kAudioFileWAVEType, &_audioFormat, NULL, kAudioFileFlags_EraseFile, &_mAudioFileRef);
            setupErr = ExtAudioFileSetProperty(_mAudioFileRef, kExtAudioFileProperty_ClientDataFormat, sizeof(AudioStreamBasicDescription), &_audioFormat);
            
        }
        pthread_mutex_unlock(&outputAudioFileLock);
    }
}

- (IBAction)voiceRecognition:(id)sender
{
    statusTextView.text = [[VoiceApi sharedApi] sendVoice];
}


@end
