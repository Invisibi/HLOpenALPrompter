//
//  HLOpenALPrompter.h
//  Hedwig
//
//  Created by saiday on 5/5/14.
//  Copyright (c) 2014 invisibi. All rights reserved.
//
#import <Foundation/Foundation.h>

typedef void(^HLOpenALPrompterCompletion)();

@interface HLOpenALPrompter : NSObject

- (void)playSoundNamed:(NSString *)name;

- (void)playSoundNamed:(NSString *)name looping:(BOOL)looping;

- (void)playSoundNamed:(NSString *)name completion:(HLOpenALPrompterCompletion)completion;

- (void)playSoundNamed:(NSString *)name after:(CGFloat)time looping:(BOOL)looping completion:(HLOpenALPrompterCompletion)completion;

- (void)stopSound;

@end
