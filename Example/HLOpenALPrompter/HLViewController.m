//
//  HLViewController.m
//  HLOpenALPrompter
//
//  Created by KenKuan on 04/27/2015.
//  Copyright (c) 2014 KenKuan. All rights reserved.
//

#import "HLViewController.h"
#import <HLOpenALPrompter/HLOpenALPrompter.h>

@interface HLViewController ()

@property (nonatomic) HLOpenALPrompter *openALPrompter;

@end

@implementation HLViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.openALPrompter = [[HLOpenALPrompter alloc] init];
}

- (IBAction)play:(id)sender {
    [self.openALPrompter playSoundNamed:@"recording_start"];
}

@end
