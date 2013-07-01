//
//  TitleSprite.h
//  Hello World
//
//  Created by Andreas Wålm on 2012-10-31.
//  Copyright (c) 2012 WalmNET. All rights reserved.
//

#import "BaseSprite.h"

@interface TitleSprite : BaseSprite {
  
  @private
    SPImage *mImage;
    OnCompletionBlock mCompletionBlock;
}

+ (TitleSprite*)title;

- (void)fadeIn:(OnCompletionBlock)completion;
- (void)fadeOut:(OnCompletionBlock)completion;
- (void)moveSlowUpAndDown;

@end
