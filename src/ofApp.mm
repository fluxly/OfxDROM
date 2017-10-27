#include "ofApp.h"
#include <AVFoundation/AVFoundation.h>


ABiOSSoundStream* ofApp::getSoundStream(){
    return stream;
}

//--------------------------------------------------------------
void ofApp::setupAudioStream(){
    stream = new ABiOSSoundStream();
    stream->setup(this, 2, 0, 44100, 1024, 2);
}

//--------------------------------------------------------------
void ofApp::setup(){
    // First set some constants
    SCREEN_WIDTH = [[UIScreen mainScreen] bounds].size.height;
    SCREEN_HEIGHT= [[UIScreen mainScreen] bounds].size.width;
    
    ofLog(OF_LOG_VERBOSE, "IS_IPAD %i", IS_IPAD);
    ofLog(OF_LOG_VERBOSE, "IS_IPHONE %i", IS_IPHONE);
    
    if (IS_IPAD) {
        INSTRUMENT_WIDTH = 1024;
        INSTRUMENT_HEIGHT = 768;
        HITSPOT_W = 32;
        SCALING = 2.13f;
        IPAD_MARGIN = 45;
    }
    if (IS_IPHONE) {
        INSTRUMENT_WIDTH = 480;
        INSTRUMENT_HEIGHT = 320;
        HITSPOT_W = 32;
        SCALING = 1.0f;
        IPAD_MARGIN = 0;
    }
    
    X_OFFSET = (SCREEN_WIDTH - INSTRUMENT_WIDTH)/2;
    Y_OFFSET = (SCREEN_HEIGHT - INSTRUMENT_HEIGHT)/2;
    
    ofLog(OF_LOG_VERBOSE, "X_OFFSET  %i", X_OFFSET );
    ofLog(OF_LOG_VERBOSE, "Y_OFFSET  %i", Y_OFFSET );
    
    // Hitspot is absolute coordinates (no offset)
    HITSPOT_X  = SCREEN_WIDTH - HITSPOT_W;
    HITSPOT_Y = SCREEN_HEIGHT - HITSPOT_W;

    // Correct the menu instrument placement
    for (int i=0; i<nScenes; i++) {
        instrumentWidth[i] = INSTRUMENT_WIDTH;
        instrumentHeight[i] = INSTRUMENT_HEIGHT;
        if (IS_IPAD) {
            backgroundXCenter[i] = backgroundXCenter[i]*1.5-X_OFFSET;
        } else {
            backgroundXCenter[i] = backgroundXCenter[i]-X_OFFSET;
        }
    }
    if (IS_IPAD) {
        instrumentWidth[0] = 3696;
        sliderMin = 155;
        sliderMax = 875;
    } else {
        instrumentWidth[0] = 2464;    // FIXME: For now the menu is a special instrument
    }
    
    // Correct all the X and Y control values for offsets and scaling
    for (int i=0; i<nControls; i++) {
        controlX[i] = (controlX[i]) * SCALING + X_OFFSET ;
        controlY[i] = (controlY[i]) * SCALING + Y_OFFSET + IPAD_MARGIN;
        controlW[i] = controlW[i] * SCALING;
        controlH[i] = controlH[i] * SCALING;
        ofLog(OF_LOG_VERBOSE, "%i: %f,%f,%f,%f)", i, controlX[i], controlY[i],controlW[i], controlH[i]);
    }
    float buttonScale = 1;
    int IPAD_TWEAK_X = 0;
    int IPAD_TWEAK_Y = 0;
    
    if (IS_IPAD) {
        buttonScale = 1.5;
        IPAD_TWEAK_X = 10;
        IPAD_TWEAK_Y = 95;
    }
    for (int i=0; i<nButtons; i++) {
        buttonX[i] = (buttonX[i]) * buttonScale +IPAD_TWEAK_X;
        buttonY[i] = (buttonY[i]) * buttonScale + Y_OFFSET + IPAD_MARGIN+ IPAD_TWEAK_Y;
        buttonW[i] = buttonW[i] * buttonScale;
        buttonH[i] = buttonH[i] * buttonScale;
    }
    volume = .50f;
    myControlThread.setup(&volume);
    
    ofSetFrameRate(60);
    //ofSetVerticalSync(true);

    ofSetOrientation(OF_ORIENTATION_90_RIGHT);

    ofEnableAntiAliasing();
    ofSetLogLevel("Pd", OF_LOG_VERBOSE); // see verbose info inside
    
    // register touch events NOTE: doesn't seem to be needed since triggers double events
    //ofRegisterTouchEvents(this);
    
    // initialize the accelerometer
    //ofxAccelerometer.setup();
    
    // iOSAlerts will be sent to this
    ofxiOSAlerts.addListener(this);
    
    // try to set the preferred iOS sample rate, but get the actual sample rate
    // being used by the AVSession since newer devices like the iPhone 6S only
    // want specific values (ie 48000 instead of 44100)
    //float sampleRate = setAVSessionSampleRate(44100);
    float sampleRate = 44100;
    
    // the number of libpd ticks per buffer,
    // used to compute the audio buffer len: tpb * blocksize (always 64)
    int ticksPerBuffer = 8; // 8 * 64 = buffer len of 512
    
    // setup OF sound stream using the current *actual* samplerate
    //ofSoundStreamSetup(2, 0, this, sampleRate, ofxPd::blockSize()*ticksPerBuffer, 2);
    
    // setup Pd
    //
    // set 4th arg to true for queued message passing using an internal ringbuffer,
    // this is useful if you need to control where and when the message callbacks
    // happen (ie. within a GUI thread)
    //
    // note: you won't see any message prints until update() is called since
    // the queued messages are processed there, this is normal
    //
    if(!pd.init(2, 0, sampleRate, ticksPerBuffer-1, false)) {
        OF_EXIT_APP(1);
    }
    
    // Setup externals
    moog_tilde_setup();
    
    midiChan = 1; // midi channels are 1-16
    
    // subscribe to receive source names
    pd.subscribe("toOF");
    pd.subscribe("env");
    
    // add message receiver, required if you want to receieve messages
    pd.addReceiver(*this);   // automatically receives from all subscribed sources
    pd.ignoreSource(*this, "env");      // don't receive from "env"

    // add midi receiver, required if you want to recieve midi messages
    pd.addMidiReceiver(*this);  // automatically receives from all channels

    // audio processing on
    pd.start();
    
    // -----------------------------------------------------
    cout << endl << "BEGIN DROM" << endl;
    cout << ofFilePath::getCurrentWorkingDirectory() << endl;
    pd.openPatch("pd-drom.pd");
    pd.sendFloat("kit_number", 0);
    
    backgroundX = -X_OFFSET;

    if (IS_IPAD) {
        background.load("DROMmenuImage-ipad.png");
        exitButton.load("ControlImages/navMenuExit-ipad.png");
        pot.load("ControlImages/KnobDot-ipad.png");
        potHighlight.load("ControlImages/RingWhiteNoDot-ipad.png");
        brokenPot.load("ControlImages/BrokenKnobPot-ipad.png");
        slider.load("ControlImages/Slider-ipad.png");
        ledImage.load("ControlImages/LedGlow-ipad.png");
        holdOff.load("ControlImages/twoPosSwitch0-ipad.png");
        holdOn.load("ControlImages/twoPosSwitch1-ipad.png");
    } else {
        background.load("DROMmenuImage.png");
        exitButton.load("ControlImages/navMenuExit.png");
        pot.load("ControlImages/KnobDot.png");
        potHighlight.load("ControlImages/RingWhiteNoDot.png");
        brokenPot.load("ControlImages/BrokenKnobPot.png");
        slider.load("ControlImages/Slider.png");
        ledImage.load("ControlImages/LedGlow.png");
        holdOff.load("ControlImages/twoPosSwitch0.png");
        holdOn.load("ControlImages/twoPosSwitch1.png");
    }
}

//--------------------------------------------------------------
void ofApp::update(){

    // since this is a test and we don't know if init() was called with
    // queued = true or not, we check it here
    if(pd.isQueued()) {
        // process any received messages, if you're using the queue and *do not*
        // call these, you won't receieve any messages or midi!
        pd.receiveMessages();
        pd.receiveMidi();
    }

    // MENU SCENE
    if (scene == 0) {
        if ((state > 0) && (backgroundX < backgroundXCenter[state])) {
          backgroundX+=menuMoveStep;
        }
        if ((state > 0) && (backgroundX > backgroundXCenter[state])) {
            backgroundX-=menuMoveStep;
        }
        if (abs(backgroundX-backgroundXCenter[state]) < menuMoveStep) {
            backgroundX = backgroundXCenter[state];
        }
    }
    
    // INSTRUMENT SCENE: Blinking LED
    if (scene > 0) {
        ledCount = (ledCount+1) % ledTempo;
    }
    
    // INSTRUMENT SCENE
    if ((scene > 0) && (scene <= nInstruments)) {
        for (int i=0; i < nControlsPerInstrument; i++) {
            if (controlChanged[i+instrumentBase]) {
                if ((controlType[i+instrumentBase] == POT_CONTROL) ||
                    (controlType[i+instrumentBase] == BROKEN_POT_CONTROL)) {
                    ofLog(OF_LOG_VERBOSE, "send " + ofToString(controlValue[i+instrumentBase]) + " to control " + patchInput[i+instrumentBase]);
                    if ((i == 8) && !instrumentOn) {
                        // don't send if volume knob changed when off
                    } else {
                        pd.sendFloat(patchInput[i+instrumentBase], controlValue[i+instrumentBase]);
                    }
                }
                controlChanged[i+instrumentBase] = NO;
            }
        }
    }
}

//--------------------------------------------------------------
void ofApp::draw(){
    ofBackground(0, 0, 0);
    ofSetRectMode(OF_RECTMODE_CORNER);
    ofSetHexColor(0xFFFFFF);
    background.draw(backgroundX+X_OFFSET, backgroundY+Y_OFFSET, instrumentWidth[scene], instrumentHeight[scene]);
    
    /*
    ofSetHexColor(0xFF0000);
    ofSetRectMode(OF_RECTMODE_CENTER);
    for (int i=0;i<nButtons; i++) {
        ofPushMatrix();
        ofTranslate(buttonX[i], buttonY[i]);
        ofDrawRectangle(0, 0, buttonW[i]+10, buttonH[i]+10);
        ofPopMatrix();
    }
    */
    ofSetHexColor(0xFFFFFF);
    
    // INSTRUMENT SCENE
    if (scene > 0) {
        // Place exit control
        exitButton.draw(HITSPOT_X, HITSPOT_Y, HITSPOT_W, HITSPOT_W);
        
        // For debugging outlines of controls
      /*
         ofSetHexColor(0xFF0000);
        ofSetRectMode(OF_RECTMODE_CENTER);
        for (int i=0;i<nControlsPerInstrument; i++) {
           ofPushMatrix();
           ofTranslate(controlX[instrumentBase+i], controlY[instrumentBase+i]);
           ofDrawRectangle(0, 0, controlW[instrumentBase+i]+10, controlH[instrumentBase+i]+10);
           ofPopMatrix();
        }
        */
        
        ofSetHexColor(0xFFFFFF);
        ofSetRectMode(OF_RECTMODE_CENTER);

        for (int i=0;i<nControlsPerInstrument; i++) {
            ofPushMatrix();
            ofTranslate(controlX[instrumentBase+i], controlY[instrumentBase+i]);
            
            if (controlType[instrumentBase+i] == POT_CONTROL) {
                ofRotateZ(controlAngle[instrumentBase+i]*57.2958);
                pot.draw(0, 0, controlW[instrumentBase+i], controlH[instrumentBase+i]);
                if (showHighlight[instrumentBase+i] == YES)
                    potHighlight.draw(0, 0, controlW[instrumentBase+i]*3,
                                      controlH[instrumentBase+i]*3);
            }
            if (controlType[instrumentBase+i] == BROKEN_POT_CONTROL) {
                glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
                ofRotateZ(controlAngle[instrumentBase+i]*57.2958);
                brokenPot.draw(0, 0, controlW[instrumentBase+i], controlH[instrumentBase+i]);
                if (showHighlight[instrumentBase+i] == YES)
                    potHighlight.draw(0, 0, controlW[instrumentBase+i]*6,
                                      controlH[instrumentBase+i]*6);
            }
            if (controlType[instrumentBase+i] == SWITCH_CONTROL) {
                glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
                if (controlValue[instrumentBase+i] == 0) {
                    holdOff.draw(0, 0, controlW[instrumentBase+i], controlH[instrumentBase+i]);
                } else {
                    holdOn.draw(0, 0, controlW[instrumentBase+i], controlH[instrumentBase+i]);
                }
            }
            if (controlType[instrumentBase+i] == SLIDER_CONTROL) {
                glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
                slider.draw(0, 0, controlW[instrumentBase+i], controlH[instrumentBase+i]);
            }
            
            ofPopMatrix();
        }
  
        glBlendFunc(GL_SRC_ALPHA, GL_ONE);
        if ((instrumentOn) && (ledCount > ledTempo/2))  ledImage.draw(241*SCALING+X_OFFSET, 83*SCALING+Y_OFFSET+IPAD_MARGIN, 52*SCALING, 51*SCALING);
       
    }
}

//--------------------------------------------------------------
void ofApp::exit(){
    myControlThread.stopThread();
    ofSoundStreamClose();
}

//--------------------------------------------------------------
void ofApp::touchDown(ofTouchEventArgs & touch){
   // ofLog(OF_LOG_VERBOSE, "touch %d down at (%i,%i)", touch.id, (int)touch.x, (int)touch.y);
    if ((scene == 0) && (state == 5) && (buttonHit == -1)) {
        buttonHit = checkButtons((int)touch.x, (int)touch.y);
        if (buttonHit >= 0) { startTouchId = touch.id; }
    }
    
    // MENU SCENE: Touched and not already moving: save touch down location and id
    if ((scene == 0) && (state > 0) && (buttonHit == -1)) {
        prevState = state;
        state = -1;  // wait for move state
        startBackgroundX = backgroundX;
        startTouchId = touch.id;
        startTouchX = (int)touch.x;
        startTouchY = (int)touch.y;
    }
    
    // INSTRUMENT SCENE: Check to see if exit button touched
    if ((scene > 0) && inBoundsExit((int)touch.x, (int)touch.y)) {
        startTouchId = touch.id;
        exitHit = YES;
        ofLog(OF_LOG_VERBOSE, "exitHit");
    }
    
    // INSTRUMENT SCENE: Check to see if controls are touched
    if (scene > 0) {
        for (int i=0; i < nControlsPerInstrument; i++) {
          if (inBounds(instrumentBase+i, touch.x, touch.y)) {
            touchX[touch.id] = touch.x;
            touchY[touch.id] = touch.y;
            touchControl[touch.id] = instrumentBase+i;
            showHighlight[touchControl[touch.id]] = YES;
          //  ofLog(OF_LOG_VERBOSE, "touched control %i", i);
            
            switch (controlType[instrumentBase+i]) {
                case POT_CONTROL:
                case BROKEN_POT_CONTROL:
                  if (calculatePotAngle(touch.id)) {
                      controlChanged[touchControl[touch.id]] = YES;
                  }
                break;
                case SWITCH_CONTROL:
                break;
                case SLIDER_CONTROL:
                break;
            }
          }
        }
    }
}

//--------------------------------------------------------------
void ofApp::touchMoved(ofTouchEventArgs & touch){
   // ofLog(OF_LOG_VERBOSE, "touch %d move at (%i,%i)", touch.id, (int)touch.x, (int)touch.y);
    
    // MENU SCENE: no longer in same place as touch down
    // added a bit to the bounds to account for higher res digitizers
    
    if ((scene == 0) && (state == -1) && (startTouchId == touch.id) && (buttonHit == -1)) {
        ofLog(OF_LOG_VERBOSE, ".");
        if ((touch.x < (startTouchX -touchMargin*2)) || (touch.x > (startTouchX + touchMargin*2))) {
            state = 0;
        }
    }
    
    // MENU SCENE: Moving with finger down: slide menu left and right
    if ((scene == 0) && (state == 0)  && (startTouchId == touch.id)  && (buttonHit == -1)) {
        backgroundX = startBackgroundX + ((int)touch.x - startTouchX);
    }
    
    // INSTRUMENT SCENE: Check controls
    if (scene > 0) {
        if (touchControl[touch.id] >=0){
            touchX[touch.id] = touch.x;
            touchY[touch.id] = touch.y;
           // ofLog(OF_LOG_VERBOSE, "tracking control %i", touchControl[touch.id]);
            
            switch (controlType[touchControl[touch.id]]) {
                case POT_CONTROL:
                case BROKEN_POT_CONTROL:
                    // Pots will always update unless pinned
                    if (calculatePotAngle(touch.id)) {
                        controlChanged[touchControl[touch.id]] = YES;
                    }
                    break;
                case SWITCH_CONTROL:
                    break;
                case SLIDER_CONTROL:
                    if ((touchX[touch.id] >= sliderMin) && (touchX[touch.id] <= sliderMax)) {
                        controlX[touchControl[touch.id]] = touchX[touch.id];
                        controlValue[touchControl[touch.id]] = (touchX[touch.id]-sliderMin)/(sliderMax-sliderMin);
                        ofLog(OF_LOG_VERBOSE, "Slider Value %f", controlValue[touchControl[touch.id]]);
                        pd.sendFloat(patchInput[touchControl[touch.id]], controlValue[touchControl[touch.id]]);
                    }
                    break;
            }
        }
    }
}

//--------------------------------------------------------------
void ofApp::touchUp(ofTouchEventArgs & touch){
   // ofLog(OF_LOG_VERBOSE, "touch %d up at (%i,%i)", touch.id, (int)touch.x, (int)touch.y);
    
    // MENU SCENE: Touched but not moved: load instrument
    if ((scene == 0) && (state == -1) && (startTouchId == touch.id)  && (buttonHit == -1)) {
        ofLog(OF_LOG_VERBOSE, "state? %i", prevState);
        // Also check if in image bounds before switching
        state = prevState;
        startTouchId = -1;
        startTouchX = 0;
        startTouchY = 0;
        if (prevState<5) {
          scene = prevState;
          loadInstrument(scene);
          ofLog(OF_LOG_VERBOSE, "Load Instrument (%i)", prevState);
        }
    }
    // MENU SCENE: Touch up after moving
    if ((scene == 0) && (state == 0) && (startTouchId == touch.id)  && (buttonHit == -1)) {
        
        // If moved sufficiently, switch to next or previous state
        if (((int)touch.x < startTouchX-75) && (prevState < 5)) {
          state = prevState + 1;
          prevState = state;
        } else {
          if (((int)touch.x > startTouchX+75) && (prevState > 1)) {
            state = prevState -1;
            prevState = state;
          } else {
              state = prevState;
          }
        }
        menuMoveStep = abs(backgroundX - backgroundXCenter[state])/8;
        startBackgroundX = backgroundX;
        startTouchId = -1;
        startTouchX = 0;
        startTouchY = 0;
     //   ofLog(OF_LOG_VERBOSE, "New State: %i", state);
    }
    
    if ((scene == 0) && (state == 5) && (buttonHit >= 0) && (startTouchId == touch.id)) {
        int b = checkButtons((int)touch.x, (int)touch.y);
        if (b == buttonHit) {
            switch (b) {
                case 0:
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.fluxama.com"]];
                    break;
                case 1:
                    [[UIApplication sharedApplication]
                         openURL:[NSURL URLWithString:@"itms-apps://itunes.apple.com/us/app/noisemusick/id513770094?mt=8"]];
                    break;
                case 2:
                    [[UIApplication sharedApplication]
                     openURL:[NSURL URLWithString:@"itms-apps://itunes.apple.com/us/apps/dr-om/id555409573?mt=8"]];
                    break;
                case 3:
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.facebook.com/fluxamacorp"]];
                    break;
                case 4:
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.twitter.com/fluxama"]];
                    break;
            }
        }
        buttonHit = -1;
        startTouchId = -1;
    }
    
    // INSTRUMENT SCENE: Touch up after touching in exit button
    if ((scene > 0) && inBoundsExit((int)touch.x, (int)touch.y)
          && exitHit && (touch.id == startTouchId)) {
        startTouchId = -1;
        exitHit = NO;
        loadMenu();
    }
    
    // INSTRUMENT SCENE: Check controls
    if (scene > 0) {
        switch (controlType[touchControl[touch.id]]) {
            case SWITCH_CONTROL:
                if (controlValue[touchControl[touch.id]] == 0) {
                    controlValue[touchControl[touch.id]] = 1;
                    instrumentOn = YES;
                } else {
                    controlValue[touchControl[touch.id]] = 0;
                    instrumentOn = NO;
                }
                ofLog(OF_LOG_VERBOSE, "Toggle On Off %i", touchControl[touch.id]);
                // toggle switch
                if (instrumentOn) {
                    turnOnInstrument();
                } else {
                    turnOffInstrument();
                }
                break;
        }
        touchX[touch.id] = 0;
        touchY[touch.id] = 0;
        pinnedHigh[touchControl[touch.id]] = NO;
        pinnedLow[touchControl[touch.id]] = NO;
        ofLog(OF_LOG_VERBOSE, "stopped tracking control %i", touchControl[touch.id]);
        showHighlight[touchControl[touch.id]] = NO;
        controlChanged[touchControl[touch.id]] = NO;
        touchControl[touch.id] = -1;
    }
}

//--------------------------------------------------------------
void ofApp::touchDoubleTap(ofTouchEventArgs & touch){

}

//--------------------------------------------------------------
void ofApp::touchCancelled(ofTouchEventArgs & touch){
    
}

//--------------------------------------------------------------
void ofApp::lostFocus(){

}

//--------------------------------------------------------------
void ofApp::gotFocus(){

}

//--------------------------------------------------------------
void ofApp::gotMemoryWarning(){

}

//--------------------------------------------------------------
void ofApp::deviceOrientationChanged(int newOrientation){
    if ((newOrientation == OF_ORIENTATION_90_RIGHT) || (newOrientation == OF_ORIENTATION_90_LEFT)) {
            ofSetOrientation((ofOrientation)newOrientation);
    }
}

void ofApp::audioReceived(float * input, int bufferSize, int nChannels) {
    pd.audioIn(input, bufferSize, nChannels);
}

//--------------------------------------------------------------
void ofApp::audioRequested(float * output, int bufferSize, int nChannels) {
    pd.audioOut(output, bufferSize, nChannels);
}

//--------------------------------------------------------------
// set the samplerate the Apple approved way since newer devices
// like the iPhone 6S only allow certain sample rates,
// the following code may not be needed once this functionality is
// incorporated into the ofxiOSSoundStream
// thanks to Seth aka cerupcat
float ofApp::setAVSessionSampleRate(float preferredSampleRate) {
    
    NSError *audioSessionError = nil;
    AVAudioSession *session = [AVAudioSession sharedInstance];
    
    // disable active
    [session setActive:NO error:&audioSessionError];
    if (audioSessionError) {
        NSLog(@"Error %ld, %@", (long)audioSessionError.code, audioSessionError.localizedDescription);
    }
    
    // set category
  //   [session setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionAllowBluetooth|AVAudioSessionCategoryOptionMixWithOthers|AVAudioSessionCategoryOptionDefaultToSpeaker error:&audioSessionError];
    
    [session setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionAllowBluetooth|AVAudioSessionCategoryOptionMixWithOthers|AVAudioSessionCategoryOptionDefaultToSpeaker error:&audioSessionError];
    if(audioSessionError) {
        NSLog(@"Error %ld, %@", (long)audioSessionError.code, audioSessionError.localizedDescription);
    }
    
    // try to set the preferred sample rate
    [session setPreferredSampleRate:preferredSampleRate error:&audioSessionError];
    if(audioSessionError) {
        NSLog(@"Error %ld, %@", (long)audioSessionError.code, audioSessionError.localizedDescription);
    }
    
    // *** Activate the audio session before asking for the "current" values ***
    [session setActive:YES error:&audioSessionError];
    if (audioSessionError) {
        NSLog(@"Error %ld, %@", (long)audioSessionError.code, audioSessionError.localizedDescription);
    }
    ofLogNotice() << "AVSession samplerate: " << session.sampleRate << ", I/O buffer duration: " << session.IOBufferDuration;
    
    // our actual samplerate, might be differnt aka 48k on iPhone 6S
    return session.sampleRate;
}

void ofApp::loadInstrument(int n) {
    instrumentBase = nControlsPerInstrument * (n-1);
    pd.sendFloat("kit_number", n);
 
    if (IS_IPAD) {
        background.load("InstrumentImages/" + instrumentImages[n-1] + "-ipad.png");
    } else {
        background.load("InstrumentImages/" + instrumentImages[n-1]+ ".png");
    }
    prevBackgroundX = backgroundX;
    backgroundX = 0;
    backgroundY = 0;

    for (int i=0; i<nControlsPerInstrument; i++) {
        ofLog(OF_LOG_VERBOSE, "send " + ofToString(controlValue[i+instrumentBase]) + " to control " + patchInput[i+instrumentBase]);
            pd.sendFloat(patchInput[i+instrumentBase], controlValue[i+instrumentBase]);
    }
    
    // Initialize touch tracking
    for (int i=0; i<nControls; i++) {
        controlChanged[i] = NO;
        pinnedHigh[i] = NO;
        pinnedLow[i] = NO;
        crossedHighCW[i] = NO;
        crossedHighCC[i] = NO;
        crossedLowCW[i] = NO;
        crossedLowCC[i] = NO;
        showHighlight[i] = NO;
    }
    ofLog(OF_LOG_VERBOSE, "Instrument On %f", controlValue[instrumentBase + 1]);
    if (controlValue[instrumentBase + 1] != 0) {
        instrumentOn = YES;
    } else {
        instrumentOn = NO;
    }
    if (instrumentOn) {
        turnOnInstrument();
    } else {
        turnOffInstrument();
    }
}

void ofApp::turnOnInstrument() {
    ofLog(OF_LOG_VERBOSE, "Turn ON %f", controlValue[instrumentBase + 10]);
    pd.sendFloat("masterVolume", controlValue[instrumentBase + 10]);
  
}

void ofApp::turnOffInstrument() {
    ofLog(OF_LOG_VERBOSE, "Turn OFF ");
    pd.sendFloat("masterVolume", 0.0);
}

void ofApp::loadMenu() {
    pd.sendFloat("kit_number", 0);
    if (IS_IPAD) {
        background.load("DROMmenuImage-ipad.png");
    } else {
        background.load("DROMmenuImage.png");
    }
    scene = 0;
    backgroundX = prevBackgroundX;
}

Boolean ofApp::instrumentIsOff() {
    return !instrumentOn;
}

int ofApp::toggleIt(int n) {
    if (n == 0) {
        return 1;
    } else {
        return 0;
    }
}

Boolean ofApp::inBounds(int controlId, int x1, int y1) {
    if ((x1 < (controlX[controlId]+controlH[controlId]/2+touchMargin)) &&
        (x1 > (controlX[controlId]-controlH[controlId]/2-touchMargin)) &&
        (y1 < (controlY[controlId]+controlW[controlId]/2+touchMargin)) &&
        (y1 > (controlY[controlId]-controlW[controlId]/2-touchMargin))) {
        return true;
    } else {
        return false;
    }
}

int ofApp::checkButtons(int x1, int y1) {
    int r = -1;
    for (int i=0; i<nButtons; i++) {
      if ((x1 < (buttonX[i]+buttonH[i]/2+touchMargin)) &&
          (x1 > (buttonX[i]-buttonH[i]/2-touchMargin)) &&
          (y1 < (buttonY[i]+buttonW[i]/2+touchMargin)) &&
          (y1 > (buttonY[i]-buttonW[i]/2-touchMargin))) {
          r = i;
      }
    }
    return r;
}

Boolean ofApp::inBoundsExit(int x1, int y1) {
    if ((x1 > HITSPOT_X-10) && (y1 > HITSPOT_Y-10)) {
        return true;
    } else {
        return false;
    }
}
                                 
Boolean ofApp::calculatePotAngle(int id) {
    float d1 = touchY[id]-controlY[touchControl[id]];
    float d2 = touchX[id]-controlX[touchControl[id]];
    ofLog(OF_LOG_VERBOSE, "d1, d2: %f, %f", d1, d2);
    float r = sqrt(pow(d1,2) + pow(d2,2));
    float angle=0;

    if (r>0) {
        angle = -asin(d1/r);
        ofLog(OF_LOG_VERBOSE, "angle: %f", angle);
        if (touchX[id] > controlX[touchControl[id]])  {
            angle = 3.14f - angle;
        }
        if ((touchX[id] < controlX[touchControl[id]]) && (touchY[id] > controlY[touchControl[id]]))  {
            angle = 6.28f + angle;
        }
        
        float prevAngle = prevControlAngle[touchControl[id]];
        ofLog(OF_LOG_VERBOSE, "prev, angle: %f, %f", prevAngle, angle);
        if ((prevAngle>3)&&(prevAngle<=4)&&(angle>4)&&(angle<5)) {
            crossedHighCW[touchControl[id]] = YES;
        }
        if ((prevAngle>=4)&&(prevAngle<5)&&(angle<4)&&(angle>3)) {
            crossedHighCC[touchControl[id]] = YES;
        }
        if ((prevAngle>4)&&(prevAngle<=5)&&(angle>5)&&(angle<6)) {
            crossedLowCW[touchControl[id]] = YES;
        }
        if ((prevAngle>=5)&&(prevAngle<6)&&(angle<5)&&(angle>4)) {
            crossedLowCC[touchControl[id]] = YES;
        }
        if (pinnedHigh[touchControl[id]] && crossedHighCC[touchControl[id]]) {
            pinnedHigh[touchControl[id]] = NO;
            crossedHighCC[touchControl[id]] = NO;
        }
        
        if (pinnedLow[touchControl[id]] && crossedLowCW[touchControl[id]]) {
            pinnedLow[touchControl[id]] = NO;
            crossedLowCW[touchControl[id]]=NO;
        }
        
        // Can't remember what cases these satisfy...
        if ((prevAngle>=5)&&(angle>5)&&(angle<6)) {
            pinnedLow[touchControl[id]] = NO;
        }
        if ((angle<4)&&(prevAngle<4)) {
            pinnedHigh[touchControl[id]] = NO;
        }
        
        // map value here
        
        if (pinnedHigh[touchControl[id]] || crossedHighCW[touchControl[id]]) {
            angle = 4;
            pinnedHigh[touchControl[id]] = YES;
            crossedHighCW[touchControl[id]]=NO;
        }
        
        if (pinnedLow[touchControl[id]] || crossedLowCC[touchControl[id]]) {
            angle = 5;
            pinnedLow[touchControl[id]] = YES;
            crossedLowCC[touchControl[id]] = NO;
        }
        
        prevControlAngle[touchControl[id]] = controlAngle[touchControl[id]];
        controlAngle[touchControl[id]] = angle;
        
        float value;
        if (angle >= 5) {
            value = angle-5;
        } else {
            value = (angle+1.283f);
        }
        
        ofLog(OF_LOG_VERBOSE, "value: %f", value);
        ofLog(OF_LOG_VERBOSE, "pinnedHIGH: %d", pinnedHigh[touchControl[id]]);
        ofLog(OF_LOG_VERBOSE, "pinnedLOW: %d", pinnedLow[touchControl[id]]);
        
        if (controlValue[touchControl[id]] != (value / 5.283f)) {
            controlValue[touchControl[id]] = (value / 5.283f);
        }
        return true;
    } else {
        return false;
    }
}


