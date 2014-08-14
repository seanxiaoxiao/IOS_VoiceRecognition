//
//  VoiceApi.h
//  SpeakHere
//
//  Created by Xiao Xiao on 8/12/14.
//
//

#import <Foundation/Foundation.h>

@interface VoiceApi : NSObject

+ (VoiceApi *)sharedApi;

- (NSString *)sendVoice;

@end
