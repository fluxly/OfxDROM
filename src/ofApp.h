#pragma once

#include "ofxiOS.h"
#include "controlThread.h"
#include "ABiOSSoundStream.h"
#include "ofxiOSExtras.h"
#include "ofxPd.h"
#include "PdExternals.h"

#define DEBUG_MODE (0)
#define nControls (33)
#define nInstruments (3)
#define nControlsPerInstrument (11)
#define nScenes (6)
#define maxTouches (11)
#define nPots (9)
#define nButtons (5)
#define touchMargin (5)
#define TOUCH_PAD (14)      // Why 14? Just to match numbers in version 1
#define POT_CONTROL (1)
#define BROKEN_POT_CONTROL (2)
#define SWITCH_CONTROL (3)
#define SLIDER_CONTROL (4)
#define ON_OFF_SWITCH (5)

//  Determine device
#define IS_IPAD (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#define IS_IPHONE (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
#define IS_IPHONE_5 (IS_IPHONE && [[UIScreen mainScreen] bounds].size.height == 568)
#define IS_IPHONE_6 (IS_IPHONE && [[UIScreen mainScreen] bounds].size.height == 667)
#define IS_IPHONE_6_PLUS (IS_IPHONE && [[UIScreen mainScreen] bounds].size.height == 736)
#define IS_IPHONE_X (IS_IPHONE && [[UIScreen mainScreen] bounds].size.height == 812)

// Defines for translating iPhone positioning to iPad
// 480 point wide -> 1024 points wide
// = 2.13 multiplier
#define IPAD_BOT_TRIM (45)

// a namespace for the Pd types
using namespace pd;

// derive from Pd receiver classes to receieve message and midi events

class ofApp : public ofxiOSApp, public PdReceiver, public PdMidiReceiver {
	
  public:
    void setup();
    void update();
    void draw();
    void exit();
	
    void touchDown(ofTouchEventArgs & touch);
    void touchMoved(ofTouchEventArgs & touch);
    void touchUp(ofTouchEventArgs & touch);
    void touchDoubleTap(ofTouchEventArgs & touch);
    void touchCancelled(ofTouchEventArgs & touch);

    void lostFocus();
    void gotFocus();
    void gotMemoryWarning();
    void deviceOrientationChanged(int newOrientation);
    void turnOnInstrument();
    void turnOffInstrument();
    Boolean instrumentIsOff();
    void setupAudioStream();
    
    ABiOSSoundStream* stream;
    ABiOSSoundStream* getSoundStream();
    
    float volume;
    Boolean instrumentOn;
    
    controlThread myControlThread;
    
    // audio callbacks
    void audioReceived(float * input, int bufferSize, int nChannels);
    void audioRequested(float * output, int bufferSize, int nChannels);
    
    // sets the preferred sample rate, returns the *actual* samplerate
    // which may be different ie. iPhone 6S only wants 48k
    float setAVSessionSampleRate(float preferredSampleRate);
    
    void loadInstrument(int n);
    void loadMenu();
    int toggleIt(int n);
    Boolean inBounds(int controlId, int x1, int y1);
    int checkButtons(int x1, int y1);
    Boolean inBoundsExit(int x1, int y1);
    Boolean calculatePotAngle(int id);
    void changeState(int s);
    
    ofxPd pd;
    vector<float> scopeArray;
    vector<float> scopeArray2;
    vector<Patch> instances;
    
    int midiChan;
    
    int menuState = 0;
    int state = 1;
    int prevState = 1;
    int scene = 0;
    int startBackgroundX = 0;
    int startTouchId = 0;
    int startTouchX = 0;
    int startTouchY = 0;
    int menuMoveStep = 10;
    
    int ledCount = 0;
    int ledTempo = 30;
    
    ofColor channelColor[13];
    
    int SCREEN_WIDTH;
    int SCREEN_HEIGHT;
    int INSTRUMENT_WIDTH;
    int INSTRUMENT_HEIGHT;
    int X_OFFSET;
    int Y_OFFSET;
    int HITSPOT_X;
    int HITSPOT_Y;
    int HITSPOT_W;
    float SCALING;
    int IPAD_MARGIN;
    
    float backgroundX = 0;
    float prevBackgroundX = 0;
    float backgroundY = 0;
    float backgroundXCenter[nScenes] = { 0,0,-460,-460*2,-460*3,-460*4-54 };
    float instrumentWidth[nScenes];
    float instrumentHeight[nScenes];
    
    int instrumentBase = 0;
    
    int controlType[nControls] = {
        // Instrument 1:
        SLIDER_CONTROL, SWITCH_CONTROL, POT_CONTROL, POT_CONTROL, POT_CONTROL, POT_CONTROL, POT_CONTROL, POT_CONTROL, POT_CONTROL, POT_CONTROL, POT_CONTROL,
        // Instrument 2:
        SLIDER_CONTROL, SWITCH_CONTROL, POT_CONTROL, POT_CONTROL, POT_CONTROL, BROKEN_POT_CONTROL, POT_CONTROL, POT_CONTROL, POT_CONTROL, POT_CONTROL, POT_CONTROL,
        // Instrument 3:
        SLIDER_CONTROL, SWITCH_CONTROL, POT_CONTROL, POT_CONTROL, POT_CONTROL, POT_CONTROL, POT_CONTROL, POT_CONTROL, POT_CONTROL, POT_CONTROL, POT_CONTROL,
    };
    float controlValue[nControls] = {
        0.5, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.75,
        0.5, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.75,
        0.5, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.75,
    };
    
    float controlAngle[nControls] = {
         0, 0, 5, 5, 5, 5, 5, 5, 5, 5, 2.67,
         0, 0, 5, 5, 5, 5, 5, 5, 5, 5, 2.67,
         0, 0, 5, 5, 5, 5, 5, 5, 5, 5, 2.67
    };
    
    float prevControlAngle[nControls] = {
        0, 0, 5, 5, 5, 5, 5, 5, 5, 5, 5,
        0, 0, 5, 5, 5, 5, 5, 5, 5, 5, 5,
        0, 0, 5, 5, 5, 5, 5, 5, 5, 5, 5,
    };
    
    float controlX[nControls] = {
        246, 244, 59, 156, 325, 421, 59, 148, 236, 325, 421,   // Instrument 1
        246, 244, 59, 156, 325, 422, 59, 148, 236, 325, 421,   // Instrument 2
        246, 244, 59, 156, 325, 421, 59, 148, 236, 325, 421,    // Instrument 3
    };
    
    float controlY[nControls] = {
        155, 41, 45, 45, 45, 45, 223, 223, 223, 223, 223,
        155, 41, 45, 45, 45, 45, 223, 223, 223, 223, 223,  // Instrument 2
        155, 41, 45, 45, 45, 45, 223, 223, 223, 223, 223,   // Instrument 3
    };
    
    float controlW[nControls] = {
        93, 48, 46, 46, 46, 46, 46, 46, 46, 46, 46,   // Instrument 1
        93, 48, 46, 46, 46, 24, 46, 46, 46, 46, 46,   // Instrument 2
        93, 48, 46, 46, 46, 46, 46, 46, 46, 46, 46,   // Instrument 3
    };
    
    float controlH[nControls] = {
         58, 34, 46, 46, 46, 46, 46, 46, 46, 46, 46,
         58, 34, 46, 46, 46, 24, 46, 46, 46, 46, 46,
         58, 34, 46, 46, 46, 46, 46, 46, 46, 46, 46
    };
    
    float buttonX[nButtons] = { 103, 272, 441, 179, 363 };
    float buttonY[nButtons] = { 72,  72, 72, 220, 220 };
    float buttonW[nButtons] = { 116, 116, 116, 116, 116 };
    float buttonH[nButtons] = { 116, 116, 116, 116, 116 };
    
    string instrumentImages[nInstruments+2] = {
        "Drom", "Drom2", "Drom3", "AboutLayer1", "devnull"
    };
    
    string patchInput[nControls] = {
         "dc3a", "dc11a","dc1a", "dc2a", "dc4a", "dc5a", "dc6a", "dc7a", "dc8a", "dc9a", "dc10a",
         "dc3b", "dc11b","dc1b", "dc2b", "dc4b", "dc5b", "dc6b", "dc7b", "dc8b", "dc9b", "dc10b",
         "dc3c", "dc11c", "dc1c", "dc2c", "dc4c", "dc5c", "dc6c", "dc7c", "dc8c", "dc9c", "dc10c"
    };
    
    Boolean controlChanged[nControls];
    Boolean pinnedHigh[nControls];
    Boolean pinnedLow[nControls];
    Boolean crossedHighCW[nControls];
    Boolean crossedHighCC[nControls];
    Boolean crossedLowCW[nControls];
    Boolean crossedLowCC[nControls];
    Boolean showHighlight[nControls];
    
    Boolean exitHit = NO;
    int buttonHit = -1;
    
    int buttonState[3] = {0, 0, 0};
    int masterTempo = 1;
    int masterTempoX = 160;
    float sliderMax = 440.0;
    float sliderMin = 140.0;
    
    int width;
    int height;
    
    ofImage background;
    ofImage background2;
    ofImage pot;
    ofImage potHighlight;
    ofImage brokenPot;
    ofImage slider;
    ofImage holdUp;
    ofImage holdDown;
    ofImage exitButton;
    ofImage ledImage;
    ofImage holdOff;
    ofImage holdOn;
    
    ofTrueTypeFont lcdFont;
    
    Patch patch;
    ofDirectory dir;
    int numFiles;
    
    //The iPhone supports 5 simultaneous touches, and cancels them all on the 6th touch.
    //Current iPad models (through Air 2) support 11 simultaneous touches, and do nothing on a 12th
    //iPad Pro has 17?
    
    int touchX[maxTouches] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
    int touchY[maxTouches] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
    int touchControl[maxTouches] = {-1, -1,-1,-1,-1,-1,-1,-1,-1,-1,-1};
    
    int lineSelected = 0;
    int menuLow = 0;
    int menuHigh = 3;
    int menuLines = 7;
    int menuOffset = 0;
    int patchLoaded = -1;

};


