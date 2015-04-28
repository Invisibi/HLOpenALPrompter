//
//  HLOpenALPrompter.m
//  Hedwig
//
//  Created by saiday on 5/5/14.
//  Copyright (c) 2014 invisibi. All rights reserved.
//

#import "HLOpenALPrompter.h"

#import <OpenAl/al.h>
#import <OpenAl/alc.h>
#import <AudioToolbox/AudioToolbox.h>

@interface HLOpenALOperation : NSOperation

+ (instancetype)operationWithSound:(NSString *)sound after:(NSTimeInterval)after looping:(BOOL)looping;

@end

@interface HLOpenALOperation () {
    ALCdevice *_device;
    ALCcontext *_context;
    ALuint _source;

    BOOL _executing;
    BOOL _finished;
}

@property (nonatomic) NSString *soundName;
@property (nonatomic) NSTimeInterval after;
@property (nonatomic) BOOL looping;

@end

@implementation HLOpenALOperation

+ (instancetype)operationWithSound:(NSString *)sound after:(NSTimeInterval)after looping:(BOOL)looping {
    HLOpenALOperation *op = [[HLOpenALOperation alloc] init];
    op.soundName = sound;
    op.after = after;
    op.looping = looping;
    return op;
}

- (BOOL)isAsynchronous {
    return YES;
}

- (void)start {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (self.after * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        [self _setExecuting:YES];

        [self playSound];

        [self _setExecuting:NO];
        [self _setFinished:YES];
    });
}

- (void)playSound {
    [self initOpenAL];

    [HLOpenALOperation loadSoundNamed:self.soundName andExtension:@"caf"];

    ALuint outputBuffer = (ALuint) [soundBuffers[self.soundName] intValue];
    alSourcei(_source, AL_BUFFER, outputBuffer);
    [HLOpenALOperation checkOpenAlError:@"attach buffer"];

    // looping
    alSourcei(_source, AL_LOOPING, self.looping ? AL_TRUE : AL_FALSE);
    [HLOpenALOperation checkOpenAlError:@"set looping"];

    // play the sound
    alSourcePlay(_source);
    [HLOpenALOperation checkOpenAlError:@"play source"];

    ALint state;
    alGetSourcei(_source, AL_SOURCE_STATE, &state);
    while (![self isCancelled] && state != AL_STOPPED) {
        alGetSourcei(_source, AL_SOURCE_STATE, &state);
        [NSThread sleepForTimeInterval:.05f];
    }

    alSourceStop(_source);
    [HLOpenALOperation checkOpenAlError:@"stop source"];
    [self cleanUpOpenAL];
}

- (void)_setExecuting:(BOOL)executing {
    [self willChangeValueForKey:@"isExecuting"];
    _executing = executing;
    [self didChangeValueForKey:@"isExecuting"];
}

- (void)_setFinished:(BOOL)finished {
    [self willChangeValueForKey:@"isFinished"];
    _finished = finished;
    [self didChangeValueForKey:@"isFinished"];
}

- (BOOL)isFinished {
    return _finished;
}

- (BOOL)isExecuting {
    return _executing;
}

#pragma mark - OpenAl

+ (void)checkOpenAlError:(NSString *)operation {
    ALenum error = alGetError();
    if (AL_NO_ERROR != error) {
        NSLog(@"Error %d when attemping to %@", error, operation);
    }
}

- (void)initOpenAL {
    _device = alcOpenDevice(NULL);
    [HLOpenALOperation checkOpenAlError:@"open devcie"];

    // create context and associate it with the device
    _context = alcCreateContext(_device, NULL);
    [HLOpenALOperation checkOpenAlError:@"create context"];

    // make the context the current context and we're good to start using OpenAL
    alcMakeContextCurrent(_context);
    [HLOpenALOperation checkOpenAlError:@"make context current"];

    // generate a single output source
    alGenSources(1, &_source);
    [HLOpenALOperation checkOpenAlError:@"gen source"];

    // set source parameters
    alSourcef(_source, AL_PITCH, 1.0f);
    [HLOpenALOperation checkOpenAlError:@"set pitch"];
    alSourcef(_source, AL_GAIN, 1.0f);
    [HLOpenALOperation checkOpenAlError:@"set gain"];
}

- (void)cleanUpOpenAL {
    alDeleteSources(1, &_source);
    alcDestroyContext(_context);
    alcCloseDevice(_device);
}

#pragma mark - SoundBuffer

static NSMutableDictionary *soundBuffers;

+ (void)initialize {
    soundBuffers = [[NSMutableDictionary alloc] init];
}

+ (void)loadSoundNamed:(NSString *)soundName andExtension:(NSString *)extension {
    if (soundBuffers[soundName]) {
        return;
    }

    NSString *filePath = [[NSBundle mainBundle] pathForResource:soundName ofType:extension];
    NSURL *fileUrl = [NSURL fileURLWithPath:filePath];
    AudioFileID afid;

    OSStatus openResult = AudioFileOpenURL((__bridge CFURLRef) fileUrl, kAudioFileReadPermission, 0, &afid);
    if (0 != openResult) {
        NSLog(@"An error occurred when attempting to open the audio file %@: %d", filePath, (int) openResult);
        return;
    }

    UInt64 fileSizeInBytes = 0;
    UInt32 propSize = sizeof(fileSizeInBytes);
    OSStatus getSizeResult = AudioFileGetProperty(afid, kAudioFilePropertyAudioDataByteCount, &propSize, &fileSizeInBytes);

    if (0 != getSizeResult) {
        NSLog(@"An error occurred when attempting to determine the size of audio file %@: %d", filePath, (int) getSizeResult);
    }

    UInt32 bytesRead = (UInt32) fileSizeInBytes;
    void *audioData = malloc(bytesRead);

    OSStatus readBytesResult = AudioFileReadBytes(afid, false, 0, &bytesRead, audioData);
    if (0 != readBytesResult) {
        NSLog(@"An error occurred when attempting to read data from audio file %@: %d", filePath, (int) readBytesResult);
    }

    AudioFileClose(afid);

    // buffers hold the audio data.
    ALuint outputBuffer;
    alGenBuffers(1, &outputBuffer);
    [self checkOpenAlError:@"gen buffer"];

    // copy the data into the output buffer
    alBufferData(outputBuffer, AL_FORMAT_MONO16, audioData, (ALsizei) bytesRead, 44100);
    [self checkOpenAlError:@"buffer data"];

    soundBuffers[soundName] = @(outputBuffer);

    // clean up audio data
    if (audioData) {
        free(audioData);
        audioData = NULL;
    }
}

@end

@interface HLOpenALPrompter ()

@property (nonatomic) NSOperationQueue *playingQueue;

@end

@implementation HLOpenALPrompter

- (instancetype)init {
    self = [super init];
    if (self) {
        self.playingQueue = [[NSOperationQueue alloc] init];
        self.playingQueue.maxConcurrentOperationCount = 1;
    }
    return self;
}

- (void)playSoundNamed:(NSString *)name {
    [self playSoundNamed:name looping:NO];
}

- (void)playSoundNamed:(NSString *)name looping:(BOOL)looping {
    [self playSoundNamed:name after:0.f looping:looping completion:nil];
}

- (void)playSoundNamed:(NSString *)name completion:(HLOpenALPrompterCompletion)completion {
    [self playSoundNamed:name after:0.f looping:NO completion:completion];
}

- (void)playSoundNamed:(NSString *)name after:(NSTimeInterval)time looping:(BOOL)looping completion:(HLOpenALPrompterCompletion)completion {
    HLOpenALOperation *op = [HLOpenALOperation operationWithSound:name after:time looping:looping];
    op.completionBlock = ^{
        dispatch_sync(dispatch_get_main_queue(), ^{
            if (completion) {
                completion();
            }
        });
    };

    [self.playingQueue cancelAllOperations];
    [self.playingQueue addOperation:op];
}

- (void)stopSound {
    [self.playingQueue cancelAllOperations];
}

@end

