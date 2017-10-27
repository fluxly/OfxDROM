//
//
//

#import "MyAppDelegate.h"
#import "ofApp.h"

static NSString *const AUDIOBUS_API_KEY= @"H4sIAAAAAAAAA0WNwQ6CMBAF/2XPSAGjh569GhOv1pBCV22Uttl2jYTw71ZC4nV25u0E+AmWRpBVAR0788LW6QFBwuF8OkIBTK829g9cmCE/bJqyKjUb6zuOUgklshU8pQjyMkEaw8/UTPfM162l85wyMRh7siFZ7/5PIndrl6U6g0E7vuk+MSGtfaZvpLh0zXwtwJp8UWKFUYknjkps6/0O5i8ztEgK2AAAAA==:swKmUoN18FmHAvHWikMNNeFJIDTqsB2zI46mp5jJ+050Na9y6W9oJ6GegfNM4mhOXtEnMeIJTgjBGImQfzPAMvZLjqjhKK+bs4G1xki2Q0pBnpkGcV7z4tJKzQWCM079";

@implementation MyAppDelegate 

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
        ofLog(OF_LOG_VERBOSE, "Foo1");
   
    [super applicationDidFinishLaunching:application];
    if (DEBUG_MODE == 1) ofSetLogLevel(OF_LOG_VERBOSE);
    
    ofApp *app = new ofApp();
        ofLog(OF_LOG_VERBOSE, "Foo2");
    self.glViewController = [[ofxiOSViewController alloc] initWithFrame:[[UIScreen mainScreen] bounds] app:app ];
    [self.window setRootViewController:self.glViewController];
    ofLog(OF_LOG_VERBOSE, "Foo3");
    ofOrientation requested = ofGetOrientation();
    UIInterfaceOrientation interfaceOrientation = UIInterfaceOrientationPortrait;
    interfaceOrientation = UIInterfaceOrientationLandscapeLeft;
    switch (requested) {
        case OF_ORIENTATION_DEFAULT:
            interfaceOrientation = UIInterfaceOrientationLandscapeLeft;
            break;
        case OF_ORIENTATION_180:
            interfaceOrientation = UIInterfaceOrientationLandscapeRight;
            break;
        case OF_ORIENTATION_90_RIGHT:
            interfaceOrientation = UIInterfaceOrientationLandscapeLeft;
            break;
        case OF_ORIENTATION_90_LEFT:
            interfaceOrientation = UIInterfaceOrientationLandscapeRight;
            break;
        case OF_ORIENTATION_UNKNOWN:
            interfaceOrientation = UIInterfaceOrientationLandscapeLeft;
            break;
    }
    
    [self.glViewController rotateToInterfaceOrientation:UIInterfaceOrientationPortrait animated:false];
    
    app->setupAudioStream();
    SoundOutputStream *stream = app->getSoundStream()->getSoundOutStream();
    /* You need to set the AudioSession settings again, setupSoundStream() I think sets it to AVAudioSessionCategoryPlayAndRecord? In any case, without calling this after setupSoundStream i could not start from within Audiobus without sound issues. */

    [[AVAudioSession sharedInstance] setActive:YES error:NULL];
    AudioOutputUnitStart(stream.audioUnit);
    [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback
                                     withOptions: AVAudioSessionCategoryOptionMixWithOthers
                                     error:  NULL];
   
    self.audiobusController = [[ABAudiobusController alloc] initWithApiKey:AUDIOBUS_API_KEY];

    self.audiobusSender = [[ABAudioSenderPort alloc]
                                   initWithName:@"drom-out"
                                   title:NSLocalizedString(@"drom-out", @"")
                                   audioComponentDescription:(AudioComponentDescription) {
                                        .componentType = kAudioUnitType_RemoteGenerator,
                                        .componentSubType = 'out1', // Note single quotes
                                        //this needs to match the audioComponents entry
                                        .componentManufacturer = 'drom' }
                                   audioUnit:stream.audioUnit];
    [_audiobusController addAudioSenderPort:_audiobusSender];
    self.audiobusController.connectionPanelPosition = ABConnectionPanelPositionRight;
    ofLog(OF_LOG_VERBOSE, "Finished Audiobus Controller");
    return YES;
    
}

//- (void)applicationDidEnterBackground:(UIApplication *)application {
-(void)applicationDidEnterBackground:(NSNotification *)notification {
    [ofxiOSGetGLView() stopAnimation];
    glFinish();
    //only continue to generate sound when not connected to anything, maybe this needs a check for inter app audio too, but it works with garageband
    if ((dynamic_cast<ofApp*>(ofGetAppPtr())->instrumentIsOff())
        && !_audiobusController.connected && !_audiobusController.memberOfActiveAudiobusSession) {
        AudioOutputUnitStop(dynamic_cast<ofApp*>(ofGetAppPtr())->getSoundStream()->getSoundOutStream().audioUnit);
        [[AVAudioSession sharedInstance] setActive:NO error:NULL];
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application {

    [[AVAudioSession sharedInstance] setActive:YES error:NULL];
    AudioOutputUnitStart(_audiobusSender.audioUnit);
    [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback withOptions: AVAudioSessionCategoryOptionMixWithOthers error:  NULL];
    
}

//check for iia connection, i had a problem with fbos not working when started from inside garageband...
-(void) checkIAACon:(int *)iaaCon{
    UInt32 connected;
    UInt32 dataSize = sizeof(UInt32);
    AudioUnitGetProperty(_audiobusSender.audioUnit,
                         kAudioUnitProperty_IsInterAppConnected,
                         kAudioUnitScope_Global, 0, &connected, &dataSize);
    *iaaCon = connected;
}

//can be called from controlThread.h to test for connection
-(void) checkCon:(bool *)iaaCon{
    UInt32 connected;
    UInt32 dataSize = sizeof(UInt32);
    AudioUnitGetProperty(_audiobusSender.audioUnit,
                         kAudioUnitProperty_IsInterAppConnected,
                         kAudioUnitScope_Global, 0, &connected, &dataSize);
    if(_audiobusController.connected || connected == 1){
        *iaaCon = true;
    } else {
        *iaaCon = false;
    }
}
-(void)applicationWillTerminate:(UIApplication *)application {
    [super applicationWillTerminate:application];
}


@end

