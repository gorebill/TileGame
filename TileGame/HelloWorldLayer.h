//
//  HelloWorldLayer.h
//  TileGame
//
//  Created by Bill on 19/2/13.
//  Copyright Oopz 2013. All rights reserved.
//


#import <GameKit/GameKit.h>

// When you import this file, you import all the cocos2d classes
#import "cocos2d.h"

// HelloWorldLayer
@interface HelloWorldLayer : CCLayer <GKAchievementViewControllerDelegate, GKLeaderboardViewControllerDelegate>
{
	CCTMXTiledMap *_tileMap;
	CCTMXLayer *_background;
	
	CCSprite *_player;
	
	CCTMXLayer *_meta;
}

@property (nonatomic, retain) CCTMXTiledMap *tileMap;
@property (nonatomic, retain) CCTMXLayer *background;

@property (nonatomic, retain) CCSprite *player;

@property (nonatomic, retain) CCTMXLayer *meta;

// returns a CCScene that contains the HelloWorldLayer as the only child
+(CCScene *) scene;

@end
