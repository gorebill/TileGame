//
//  HelloWorldLayer.m
//  TileGame
//
//  Created by Bill on 19/2/13.
//  Copyright Oopz 2013. All rights reserved.
//


// Import the interfaces
#import "HelloWorldLayer.h"

// Needed to obtain the Navigation Controller
#import "AppDelegate.h"

#import "SimpleAudioEngine.h"

#import "GameOverScene.h"

@interface HelloWorldHud()
// if you are setting your deployment target for iOS 5.0 or later then
// replace "unsafe_unretained" with "weak" which is then auto set to nil by
// the runtime. Not supported before 5.0 thoug.
@property (unsafe_unretained) HelloWorldLayer *gameLayer;
@end

#pragma mark - HelloWorldHud
@implementation HelloWorldHud
- (id) init {
	if((self = [super init])) {
		CCMenuItem *on;
		CCMenuItem *off;
		
		on = [CCMenuItemImage itemWithNormalImage:@"projectile-button-on.png" selectedImage:@"projectile-button-on.png" target:nil selector:nil];
		off = [CCMenuItemImage itemWithNormalImage:@"projectile-button-off.png" selectedImage:@"projectile-button-off.png" target:nil selector:nil];
		
		CCMenuItemToggle *toggleItem = [CCMenuItemToggle itemWithTarget:self selector:@selector(projectileButtonTapped:) items:off, on, nil];
		CCMenu *toggleMenu = [CCMenu menuWithItems:toggleItem, nil];
		toggleMenu.position = ccp(100, 32);
		[self addChild:toggleMenu];
		
		
		CGSize winSize = [[CCDirector sharedDirector] winSize];
		label = [CCLabelTTF labelWithString:@"0" fontName:@"Verdana-Bold" fontSize:18.0];
		label.color = ccc3(0, 0, 0);
		int margin = 10;
		label.position = ccp(winSize.width - (label.contentSize.width/2) - margin, label.contentSize.height/2 + margin);
		[self addChild:label];
	}
	return self;
}

- (void) projectileButtonTapped:(id)sender {
	if(_gameLayer.mode == 1) {
		_gameLayer.mode = 0;
	}else{
		_gameLayer.mode = 1;
	}
}

- (void) numCollectedChanged:(int)numCollected {
	[label setString:[NSString stringWithFormat:@"%d", numCollected]];
}

@end




#pragma mark - HelloWorldLayer

// HelloWorldLayer implementation
@implementation HelloWorldLayer

@synthesize tileMap = _tileMap;
@synthesize background = _background;
@synthesize player = _player;
@synthesize meta = _meta;
@synthesize foreground = _foreground;
@synthesize numCollected = _numCollected;
@synthesize hud = _hud;

// Helper class method that creates a Scene with the HelloWorldLayer as the only child.
+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	HelloWorldLayer *layer = [HelloWorldLayer node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	HelloWorldHud *hud = [HelloWorldHud node];
	[scene addChild:hud];
	
	layer.hud = hud;
	hud.gameLayer = layer;
	
	// return the scene
	return scene;
}

// callback. starts another iteration of enemy movement
- (void) enemyMoveFinished:(id)sender {
	CCSprite *enemy = (CCSprite *)sender;
	
	[self animateEnemy:enemy];
}

// a method to move the enemy 10 pixels toward the player
- (void) animateEnemy:(CCSprite *)enemy {
	// speed of the enemy
	ccTime actualDuration = 0.3;
	
	// rotate to face the player
	CGPoint diff = ccpSub(_player.position, enemy.position);
	float angleRadians = atanf((float)diff.y / (float)diff.x);
	float angleDegrees = CC_RADIANS_TO_DEGREES(angleRadians);
	float cocosAngle = -1 * angleDegrees;
	if (diff.x < 0) {
		cocosAngle += 180;
	}
	enemy.rotation = cocosAngle;
	
	// Create the actions
	id actionMove = [CCMoveBy actionWithDuration:actualDuration position:ccpMult(ccpNormalize(ccpSub(_player.position, enemy.position)), 2)];
	
	id actionMoveDone = [CCCallFuncN actionWithTarget:self selector:@selector(enemyMoveFinished:)];
	
	[enemy runAction:[CCSequence actions:actionMove, actionMoveDone, nil]];
}

// on "init" you need to initialize your instance
-(id) init
{
	// always call "super" init
	// Apple recommends to re-assign "self" with the "super's" return value
	if( (self=[super init]) ) {
		[[SimpleAudioEngine sharedEngine] preloadEffect:@"pickup.caf"];
		[[SimpleAudioEngine sharedEngine] preloadEffect:@"hit.caf"];
		[[SimpleAudioEngine sharedEngine] preloadEffect:@"move.caf"];
		[[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"TileMap.caf"];
		
		_mode = 0;
		
		self.enemies = [[NSMutableArray alloc] init];
		self.projectiles = [[NSMutableArray alloc] init];
		[self schedule:@selector(testCollisions:)];
		
		
		self.tileMap = [CCTMXTiledMap tiledMapWithTMXFile:@"TileMap.tmx"];
		self.background = [_tileMap layerNamed:@"Background"];
		
		self.foreground = [_tileMap layerNamed:@"Foreground"];
		
		self.meta = [_tileMap layerNamed:@"Meta"];
		_meta.visible = NO;
		
		CCTMXObjectGroup *objects = [_tileMap objectGroupNamed:@"Objects"];
		NSAssert(objects != nil, @"'Objects' object group not found");
		NSMutableDictionary *spawnPoint = [objects objectNamed:@"SpawnPoint"];
		NSAssert(spawnPoint != nil, @"SpawnPoint object not found");
		int x = [[spawnPoint valueForKey:@"x"] intValue];
		int y = [[spawnPoint valueForKey:@"y"] intValue];
		
		self.player = [CCSprite spriteWithFile:@"Player.png"];
		_player.position = ccp(x, y);
		[self addChild:_player];
		
		[self setViewpointCenter:_player.position];
		
		[self addChild:_tileMap z:-1];
		
		
		// iterate through objects, finding all enemy spawn points
		// create an enemy for each one
		for(spawnPoint in [objects objects]) {
			if ([[spawnPoint valueForKey:@"Enemy"] intValue] == 1) {
				x = [[spawnPoint valueForKey:@"x"] intValue];
				y = [[spawnPoint valueForKey:@"y"] intValue];
				[self addEnemyAtX:x y:y];
			}
		}
		
		

		[self setTouchEnabled:YES];
	}
	return self;
}

- (CGPoint) tileCoordForPosition:(CGPoint)position {
	int x = position.x / _tileMap.tileSize.width;
	int y = ((_tileMap.mapSize.height * _tileMap.tileSize.height) - position.y) / _tileMap.tileSize.height;
	return ccp(x, y);
}

- (void) registerWithTouchDispatcher {
	
	[[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self priority:0 swallowsTouches:YES];
	
	//[[CCTouchDispatcher sharedDispatcher] addTargetedDelegate:self priority:0 swallowsTouches:YES];
	
}

- (BOOL) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event {
	return YES;
}

- (void) win {
	GameOverScene *gameOverScene = [GameOverScene node];
	[gameOverScene.layer.label setString:@"You Win!"];
	[[CCDirector sharedDirector] replaceScene:gameOverScene];
}

- (void) setPlayerPosition:(CGPoint)position {
	
	CGPoint tileCoord = [self tileCoordForPosition:position];
	int tileGid = [_meta tileGIDAt:tileCoord];
	if(tileGid) {
		NSDictionary *properties = [_tileMap propertiesForGID:tileGid];
		if(properties) {
			NSString *collision = [properties valueForKey:@"Collidable"];
			if(collision && [collision compare:@"True"] == NSOrderedSame) {
				[[SimpleAudioEngine sharedEngine] playEffect:@"hit.caf"];
				return;
			}
			
			NSString *collectable = [properties valueForKey:@"Collectable"];
			if(collectable && [collectable compare:@"True"] == NSOrderedSame) {
				[[SimpleAudioEngine sharedEngine] playEffect:@"pickup.caf"];
				
				[_meta removeTileAt:tileCoord];
				[_foreground removeTileAt:tileCoord];
				
				self.numCollected++;
				[_hud numCollectedChanged:_numCollected];
				
				if(self.numCollected == 3) {
					[self win];
				}
			}
		}
	}
	
	
	_player.position = position;
}

- (void) ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event {
	
	if(_mode == 0) {		
		CGPoint touchLocation = [touch locationInView:[touch view]];
		touchLocation = [[CCDirector sharedDirector] convertToGL:touchLocation];
		touchLocation = [self convertToNodeSpace:touchLocation];
		
		CGPoint playerPos = _player.position;
		CGPoint diff = ccpSub(touchLocation, playerPos);
		if(abs(diff.x) >abs(diff.y)) {
			if(diff.x > 0) {
				playerPos.x += _tileMap.tileSize.width;
			} else {
				playerPos.x -= _tileMap.tileSize.width;
			}
		}else{
			if(diff.y > 0) {
				playerPos.y += _tileMap.tileSize.height;
			}else {
				playerPos.y -= _tileMap.tileSize.height;
			}
		}
		
		if(playerPos.x <= (_tileMap.mapSize.width * _tileMap.tileSize.width) &&
		   playerPos.y <= (_tileMap.mapSize.height * _tileMap.tileSize.height) &&
		   playerPos.y >= 0 &&
		   playerPos.x >= 0) {
			
			[[SimpleAudioEngine sharedEngine] playEffect:@"move.caf"];
			[self setPlayerPosition:playerPos];
		}
		
		[self setViewpointCenter:_player.position];
	}else {
		// code to throw ninja stars will go here
		
		// Find where the touch is
		CGPoint touchLocation = [touch locationInView:[touch view]];
		touchLocation = [[CCDirector sharedDirector] convertToGL:touchLocation];
		touchLocation = [self convertToNodeSpace:touchLocation];
		
		// Create a projectile and put it at the player's location
		CCSprite *projectile = [CCSprite spriteWithFile:@"Projectile.png"];
		projectile.position = _player.position;
		[self addChild:projectile];
		
		// Determine where we wish to shoot the projectile to
		int realX;
		
		// Are we shooting to the left or right?
		CGPoint diff = ccpSub(touchLocation, _player.position);
		if(diff.x > 0) {
			realX = (_tileMap.mapSize.width * _tileMap.tileSize.width) + (projectile.contentSize.width / 2);
		}else {
			realX = -(_tileMap.mapSize.width * _tileMap.tileSize.width) - (projectile.contentSize.width / 2);
		}
		float ratio = (float) diff.y / (float) diff.x;
		int realY = ((realX - projectile.position.x) * ratio) + projectile.position.y;
		CGPoint realDest = ccp(realX, realY);
		
		// Determine the length of how far we're shooting
		int offRealX = realX - projectile.position.x;
		int offRealY = realY - projectile.position.y;
		float length = sqrtf((offRealX * offRealX) + (offRealY * offRealY));
		float velocity = 480/1; /// 480 pixels/1sec
		float realMoveDuration = length / velocity;
		
		// Move projectile to actual endpoint
		id actionMoveDone = [CCCallFuncN actionWithTarget:self selector:@selector(projectileMoveFinished:)];
		[projectile runAction:
		 [CCSequence actionOne:[CCMoveTo actionWithDuration:realMoveDuration
												   position:realDest]
						   two:actionMoveDone]];		
		
		[self.projectiles addObject:projectile];
		
	}
}

- (void) projectileMoveFinished:(id)sender {
	CCSprite *sprite = (CCSprite *)sender;
	[self removeChild:sprite cleanup:YES];
	
	[self.projectiles removeObject:sprite];
}

- (void) setViewpointCenter:(CGPoint)position {
	CGSize winSize = [[CCDirector sharedDirector] winSize];
	
	int x = MAX(position.x, winSize.width / 2);
	int y = MAX(position.y, winSize.height / 2);
	x = MIN(x, (_tileMap.mapSize.width * _tileMap.tileSize.width) - winSize.width / 2);
	y = MIN(y, (_tileMap.mapSize.height * _tileMap.tileSize.height) - winSize.height /2);
	CGPoint actualPosition = ccp(x, y);
	
	CGPoint centerOfView = ccp(winSize.width/2, winSize.height/2);
	CGPoint viewPoint = ccpSub(centerOfView, actualPosition);
	self.position = viewPoint;
	
}

- (void) addEnemyAtX:(int)x y:(int)y {
	CCSprite *enemy = [CCSprite spriteWithFile:@"enemy1.png"];
	enemy.position = ccp(x, y);
	[self addChild:enemy];
	
	// Use our animation method and
	// start the enemy moving toward the player
	[self animateEnemy:enemy];
	
	[self.enemies addObject:enemy];
}

- (void) testCollisions:(ccTime)dt {
	NSMutableArray *projectilesToDelete = [[NSMutableArray alloc] init];
	
	// iterate through projectiles
	for(CCSprite *projectile in self.projectiles) {
		CGRect projectileRect = CGRectMake(
			projectile.position.x - (projectile.contentSize.width/2),
			projectile.position.y - (projectile.contentSize.height/2),
			projectile.contentSize.width,
			projectile.contentSize.height);
		
		NSMutableArray *targetsToDelete = [[NSMutableArray alloc] init];
		
		// iterate through enemies, see if any intersect with current projectile
		for(CCSprite *target in self.enemies) {
			CGRect targetRect = CGRectMake(
				target.position.x - (target.contentSize.width/2),
				target.position.y - (target.contentSize.height/2),
				target.contentSize.width,
				target.contentSize.height);
			
			if(CGRectIntersectsRect(projectileRect, targetRect)) {
				[targetsToDelete addObject:target];
			}
		}
		
		// delete all hit enemies
		for (CCSprite *target in targetsToDelete) {
			[self.enemies removeObject:target];
			[self removeChild:target cleanup:YES];
		}
		
		if (targetsToDelete.count > 0) {
			// add the projectile to the list of one to remove
			[projectilesToDelete addObject:projectile];
		}
	}
	
	// remove all the projectiles that hit.
	for(CCSprite *projectile in projectilesToDelete) {
		[self.projectiles removeObject:projectile];
		[self removeChild:projectile cleanup:YES];
	}
	
	for(CCSprite *target in _enemies) {
		CGRect targetRect = CGRectMake(
			target.position.x - (target.contentSize.width / 2),
			target.position.y - (target.contentSize.height / 2),
			target.contentSize.width,
			target.contentSize.height);
		
		if(CGRectContainsPoint(targetRect, _player.position)) {
			[self lose];
		}
	}
	
}

- (void) lose {
	GameOverScene *gameOverScene = [GameOverScene node];
	[gameOverScene.layer.label setString:@"You Lose"];
	[[CCDirector sharedDirector] replaceScene:gameOverScene];
}

// on "dealloc" you need to release all your retained objects
- (void) dealloc
{
	// in case you have something to dealloc, do it in this method
	// in this particular example nothing needs to be released.
	// cocos2d will automatically release all the children (Label)
	self.tileMap = nil;
	self.background = nil;
	
	self.player = nil;
	
	self.meta = nil;
	
	self.foreground = nil;
	
	self.hud = nil;
	
	// don't forget to call "super dealloc"
	[super dealloc];
}

#pragma mark GameKit delegate

-(void) achievementViewControllerDidFinish:(GKAchievementViewController *)viewController
{
	AppController *app = (AppController*) [[UIApplication sharedApplication] delegate];
	[[app navController] dismissModalViewControllerAnimated:YES];
}

-(void) leaderboardViewControllerDidFinish:(GKLeaderboardViewController *)viewController
{
	AppController *app = (AppController*) [[UIApplication sharedApplication] delegate];
	[[app navController] dismissModalViewControllerAnimated:YES];
}
@end
