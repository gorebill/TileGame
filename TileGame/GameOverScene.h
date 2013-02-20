//
//  GameOverScene.h
//  TileGame
//
//  Created by Bill on 20/2/13.
//  Copyright (c) 2013 Oopz. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "cocos2d.h"

@interface GameOverLayer : CCLayerColor {
	
}
@property (nonatomic, strong) CCLabelTTF *label;
@end




@interface GameOverScene : CCScene {
	
}
@property (nonatomic, strong) GameOverLayer *layer;

@end
