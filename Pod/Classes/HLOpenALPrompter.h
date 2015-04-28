//
//  HLOpenALPrompter.h
//  Hedwig
//
//  Created by saiday on 5/5/14.
//  Copyright (c) 2014 invisibi. All rights reserved.
//

typedef void(^IVOpenALPrompterCompletion)();

@interface HLOpenALPrompter : NSObject

- (void)playSoundNamed:(NSString *)name;

- (void)playSoundNamed:(NSString *)name looping:(BOOL)looping;

- (void)playSoundNamed:(NSString *)name completion:(IVOpenALPrompterCompletion)completion;

- (void)playSoundNamed:(NSString *)name after:(CGFloat)time looping:(BOOL)looping completion:(IVOpenALPrompterCompletion)completion;

- (void)stopSound;

@end
