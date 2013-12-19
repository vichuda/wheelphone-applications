//
//  FirstViewController.m
//  WheelphoneMonitor
//
//  Created by Stefano Morgani on 14.05.13.
//  Copyright (c) 2013 Stefano Morgani. All rights reserved.
//

#import "FirstViewController.h"

@interface FirstViewController ()

@end

@implementation FirstViewController

@synthesize prox0;
@synthesize prox1;
@synthesize prox2;
@synthesize prox3;
@synthesize proxAmb0;
@synthesize proxAmb1;
@synthesize proxAmb2;
@synthesize proxAmb3;
@synthesize ground0;
@synthesize ground1;
@synthesize ground2;
@synthesize ground3;
@synthesize leftSpeed;
@synthesize rightSpeed;
@synthesize prox0txt;
@synthesize prox1txt;
@synthesize prox2txt;
@synthesize prox3txt;
@synthesize prox0AmbTxt;
@synthesize prox1AmbTxt;
@synthesize prox2AmbTxt;
@synthesize prox3AmbTxt;
@synthesize ground0txt;
@synthesize ground1txt;
@synthesize ground2txt;
@synthesize ground3txt;
@synthesize batteryValueTxt;
@synthesize batteryStatusTxt;
@synthesize btnFollowing;
@synthesize behaviorStat;
@synthesize threshold;
@synthesize lineLostTx;
@synthesize lineSpeedTxt;
@synthesize btnCliffDetection;
@synthesize btnStayOnTable;
@synthesize imageState;

- (void)viewDidLoad
{
    
    printf("FirstViewController didLoad\n");
    
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.

    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(robotUpdateNotification:) name: @"WPUpdate" object: nil];
    
    
    CGAffineTransform transform = CGAffineTransformMakeScale(1.0f, 3.0f);
    prox0.transform = transform;
    prox1.transform = transform;
    prox2.transform = transform;
    prox3.transform = transform;
    proxAmb0.transform = transform;
    proxAmb1.transform = transform;
    proxAmb2.transform = transform;
    proxAmb3.transform = transform;
    ground0.transform = transform;
    ground1.transform = transform;
    ground2.transform = transform;
    ground3.transform = transform;
    
    imgDriveNormal = [UIImage imageNamed: @"drive_00.png"];
    imgDriveFear = [UIImage imageNamed: @"drive_01.png"];
    imgDriveAngry = [UIImage imageNamed: @"drive_02.png"];
    imgDriveLeft = [UIImage imageNamed: @"drive_sx.png"];
    imgDriveRight = [UIImage imageNamed: @"drive_dx.png"];
    
    [imageState setImage:imgDriveNormal];
    
    threshold.delegate = self;
    lineLostTx.delegate = self;
    lineSpeedTxt.delegate = self;    
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)calibrateSensors:(id)sender {
    [robot calibrateSensors];
}

- (IBAction)fwTapped:(id)sender {
    
    if(isFollowing) {
        isFollowing = false;
        [btnFollowing setTitle:@"Start line following" forState:UIControlStateNormal];
    } else {
        isFollowing = true;
        globalState = LINE_SEARCH;
        [btnFollowing setTitle:@"Stop line following" forState:UIControlStateNormal];
    }
    
}
- (IBAction)cliffDetectionPressed:(UIButton *)sender {
    if(isCliffDetecting) {
        isCliffDetecting = false;
        [btnCliffDetection setTitle:@"Cliff detection ON" forState:UIControlStateNormal];
    } else {
        isCliffDetecting = true;
        globalState = MOVE_AROUND;
        [btnCliffDetection setTitle:@"Cliff detection OFF" forState:UIControlStateNormal];
    }
}

- (IBAction)stayOnTablePressed:(UIButton *)sender {
    if(stayingOnTable) {
        stayingOnTable = false;
        [btnStayOnTable setTitle:@"Start stay on the table" forState:UIControlStateNormal];
    } else {
        stayingOnTable = true;
        globalState = ENABLE_OBSTACLE_AVOIDANCE;
        initCounter = 20;
        [btnStayOnTable setTitle:@"Stop stay on the table" forState:UIControlStateNormal];
    }
}

-(BOOL) textFieldShouldReturn: (UITextField *) textField
{
    //printf("textFieldShouldReturn\n");
    
    [textField resignFirstResponder];
    
    // You can access textField.text and do what you need to do with the text here
    
    return YES; // We'll let the textField handle the rest!
}
- (IBAction)textFieldDidBeginEditing:(id)sender {
    UITextField *textField = (UITextField*)sender;

[self animateTextField: textField up: YES];
}

- (IBAction)textFieldDidEndEditing:(id)sender {
    UITextField *textField = (UITextField*)sender;
    
    //printf("textFieldDidEndEditing\n");
        
        switch (textField.tag) {
            case 0:
                if ([textField.text isEqualToString:@""]) {
                    [textField setText:[NSString stringWithFormat:@"%d",180]];
                    groundThreshold = 180;
                    return;
                }
                groundThreshold = [textField.text intValue];
                break;
                
            case 1:
                if ([textField.text isEqualToString:@""]) {
                    [textField setText:[NSString stringWithFormat:@"%d",15]];
                    lineLostThr = 15;
                    return;
                }
                lineLostThr = [textField.text intValue];
                break;
            case 2:
                if ([textField.text isEqualToString:@""]) {
                    [textField setText:[NSString stringWithFormat:@"%d",INIT_SPEED]];
                    desiredSpeed = INIT_SPEED;
                    maxSpeed = desiredSpeed*1.5;
                    return;
                }
                desiredSpeed = [textField.text intValue];
                maxSpeed = desiredSpeed*1.5;
                break;
                                
        }

     [self animateTextField: textField up: NO];
    
}

- (void) animateTextField: (UITextField*) textField up: (BOOL) up
{
    const int movementDistance = 100; // tweak as needed
    const float movementDuration = 0.3f; // tweak as needed
    
    int movement = (up ? -movementDistance : movementDistance);
    
    [UIView beginAnimations: @"anim" context: nil];
    [UIView setAnimationBeginsFromCurrentState: YES];
    [UIView setAnimationDuration: movementDuration];
    self.view.frame = CGRectOffset(self.view.frame, 0, movement);
    [UIView commitAnimations];
}

 -(void)robotUpdateNotification: (NSNotification*)notification {
     
     //NSDate *start = [NSDate date];
     
     [self updateUI];
     [self executeBehaviors];

     //NSDate *stop = [NSDate date];
     //NSTimeInterval executionTime = [stop timeIntervalSinceDate:start];
     //printf("execution time update = %f\n", executionTime);
     
}

- (void)updateUI {
    
    [robot getGroundProxs:robGroundValues];
    [robot getFrontProxs: robProxValues];
    [robot getFrontAmbients: robProxAmbValues];
    robBattery = [robot getBatteryRaw];
    robLeftSpeed = [robot getLeftSpeed];
    robRightSpeed = [robot getRightSpeed];
    
    prox0.progress = (float)robProxValues[0]/255.0;
    [prox0txt setText:[NSString stringWithFormat:@"%d", robProxValues[0]]];
    prox1.progress = (float)robProxValues[1]/255.0;
    [prox1txt setText:[NSString stringWithFormat:@"%d", robProxValues[1]]];
    prox2.progress = (float)robProxValues[2]/255.0;
    [prox2txt setText:[NSString stringWithFormat:@"%d", robProxValues[2]]];
    prox3.progress = (float)robProxValues[3]/255.0;
    [prox3txt setText:[NSString stringWithFormat:@"%d", robProxValues[3]]];
    
    ground0.progress = (float)robGroundValues[0]/255.0;
    [ground0txt setText:[NSString stringWithFormat:@"%d", robGroundValues[0]]];
    ground1.progress = (float)robGroundValues[1]/255.0;
    [ground1txt setText:[NSString stringWithFormat:@"%d", robGroundValues[1]]];
    ground2.progress = (float)robGroundValues[2]/255.0;
    [ground2txt setText:[NSString stringWithFormat:@"%d", robGroundValues[2]]];
    ground3.progress = (float)robGroundValues[3]/255.0;
    [ground3txt setText:[NSString stringWithFormat:@"%d", robGroundValues[3]]];
    
    proxAmb0.progress = (float)robProxAmbValues[0]/255.0;
    [prox0AmbTxt setText:[NSString stringWithFormat:@"%d", robProxAmbValues[0]]];
    proxAmb1.progress = (float)robProxAmbValues[1]/255.0;
    [prox1AmbTxt setText:[NSString stringWithFormat:@"%d", robProxAmbValues[1]]];
    proxAmb2.progress = (float)robProxAmbValues[2]/255.0;
    [prox2AmbTxt setText:[NSString stringWithFormat:@"%d", robProxAmbValues[2]]];
    proxAmb3.progress = (float)robProxAmbValues[3]/255.0;
    [prox3AmbTxt setText:[NSString stringWithFormat:@"%d", robProxAmbValues[3]]];
    
    [batteryValueTxt setText:[NSString stringWithFormat:@"%d", robBattery]];
    
    [leftSpeed setText:[NSString stringWithFormat:@"%d", robLeftSpeed]];
    [rightSpeed setText:[NSString stringWithFormat:@"%d", robRightSpeed]];
    
    unsigned int temp = [robot getFlagStatus];
    if((temp&0x20)==0x20) {
        if((temp&0x40)==0x40) {
            [batteryStatusTxt setText:@"CHARGED"];
        } else {
            [batteryStatusTxt setText:@"CHARGING"];
        }
    } else {
        // not charging
        [batteryStatusTxt setText:@""];
    }
}

- (void)executeBehaviors {
    
    if(isFollowing) {
        
        // ground sensors position:
        //      G1  G2
        // G0           G3
        
        // robot->getGroundProxs(robGroundValues);  // done in updateUI()
        
        if(globalState == LINE_SEARCH) {
            
            lSpeed = desiredSpeed; // move around
            rSpeed = desiredSpeed;
            
            if(robGroundValues[0]<groundThreshold || robGroundValues[1]<groundThreshold || robGroundValues[2]<groundThreshold || robGroundValues[3]<groundThreshold) {
                lineFound++;
                if(lineFound >= 2) {        // be sure to find a line to follow (avoid noise)
                    globalState = LINE_FOLLOW;
                    globalStatePrev = LINE_SEARCH;
                }
            } else {
                lineFound = 0;
            }
            
            [behaviorStat setText:[NSString stringWithFormat:@"LINE SEARCH (%d,%d)", lSpeed, rSpeed]];
            
            if(robProxValues[0]>=OBJECT_THR || robProxValues[1]>=OBJECT_THR || robProxValues[2]>=OBJECT_THR || robProxValues[3]>=OBJECT_THR) {
                stopAvoidTime = [NSDate date];
                avoidTime = [stopAvoidTime timeIntervalSinceDate:startAvoidTime];
                if(avoidTime < 1) {   // if an object is encountered soon (within 0.5 seconds) then we can suppose
                                        // this is the same object as before still not overcome
                    sameObjDetectCount++;
                } else {
                    sameObjDetectCount = 0;
                }
                printf("avoid time = %f\n", avoidTime);
                printf("sameObjCount = %d\n", sameObjDetectCount);
                if(sameObjDetectCount >= 4) {   // if after four times the same object cannot be overcome it means the
                                                // robot is somehow blocked, thus pivot turn
                    lSpeed = -desiredSpeed;
                    rSpeed = desiredSpeed;
                    globalState = PIVOT_ROTATION;
                    globalStatePrev = LINE_SEARCH;
                    
                } else {
                    lSpeed = desiredSpeed*2;
                    rSpeed = desiredSpeed*2;
                    globalState = AVOID_OBJECT;
                    globalStatePrev = LINE_SEARCH;
                }               
                startAvoidTime = [NSDate date];
            }
            
        } else if(globalState == LINE_FOLLOW) {
            
            if(robGroundValues[1]>(groundThreshold+lineLostThr) && robGroundValues[2]>(groundThreshold+lineLostThr) && robGroundValues[0]>(groundThreshold+lineLostThr) && robGroundValues[3]>(groundThreshold+lineLostThr)) {        // i'm going to go out of the line
                outOfLine++;
                if(outOfLine >= 2) {
                    globalState = LINE_SEARCH;
                    globalStatePrev = LINE_FOLLOW;
                }
            } else {
                outOfLine = 0;
            }
            /*
            lSpeed = -(groundThreshold-robGroundValues[0])/10 - (groundThreshold-robGroundValues[1])/5 + (groundThreshold-robGroundValues[2])/5 + (groundThreshold-robGroundValues[3])/10 + desiredSpeed;
            rSpeed = (groundThreshold-robGroundValues[0])/10 + (groundThreshold-robGroundValues[1])/5 - (groundThreshold-robGroundValues[2])/5 - (groundThreshold-robGroundValues[3])/10 + desiredSpeed;
            */
            
            if(robGroundValues[0]<groundThreshold && robGroundValues[1]>groundThreshold && robGroundValues[2]>groundThreshold && robGroundValues[3]>groundThreshold) { // left ground inside line, turn left
                lSpeed = 0;
                rSpeed = desiredSpeed*4;
                if(rSpeed > MAX_SPEED) {
                    rSpeed = MAX_SPEED;
                }
            } else if(robGroundValues[3]<groundThreshold && robGroundValues[0]>groundThreshold && robGroundValues[1]>groundThreshold && robGroundValues[2]>groundThreshold) {        // right ground inside line, turn right
                lSpeed = desiredSpeed*4;
                rSpeed = 0;
                if(lSpeed > MAX_SPEED) {
                    lSpeed = MAX_SPEED;
                }
            } else if(robGroundValues[1]>groundThreshold) { // we are on the black line but pointing out to the left => turn right
                tempSpeed = (robGroundValues[1]-groundThreshold);
                if(tempSpeed > MAX_SPEED) {
                    tempSpeed = MAX_SPEED;
                }
                if(tempSpeed < minSpeedLineFollow) {
                    tempSpeed = minSpeedLineFollow;
                }
                lSpeed = tempSpeed;
                rSpeed = 0;
                //lSpeed = desiredSpeed+tempSpeed;
                //rSpeed = 0;

            } else if(robGroundValues[2]>groundThreshold) { // we are on the black line but pointing out to the right => turn left
                tempSpeed = (robGroundValues[2]-groundThreshold);
                if(tempSpeed > MAX_SPEED) {
                    tempSpeed = MAX_SPEED;
                }
                if(tempSpeed < minSpeedLineFollow) {
                    tempSpeed = minSpeedLineFollow;
                }
                lSpeed = 0;
                rSpeed = tempSpeed;
                //lSpeed = 0;
                //rSpeed = desiredSpeed+tempSpeed;

            } else {        // within the line
                lSpeed = desiredSpeed;
                rSpeed = desiredSpeed;
            }
            
            /*
            if(lSpeed > maxSpeed) {
                lSpeed = maxSpeed;
            }
            if(lSpeed < -maxSpeed) {
                lSpeed = -maxSpeed;
            }
            if(rSpeed > maxSpeed) {
                rSpeed = maxSpeed;
            }
            if(rSpeed < -maxSpeed) {
                rSpeed = -maxSpeed;
            }
            */
            
            [behaviorStat setText:[NSString stringWithFormat:@"LINE FOLLOW (%d,%d)", lSpeed, rSpeed]];
            
            if(robProxValues[0]>=OBJECT_THR || robProxValues[1]>=OBJECT_THR || robProxValues[2]>=OBJECT_THR || robProxValues[3]>=OBJECT_THR) {
                stopAvoidTime = [NSDate date];
                avoidTime = [stopAvoidTime timeIntervalSinceDate:startAvoidTime];
                if(avoidTime < 1) {   // if an object is encountered soon (within 0.5 seconds) then we can suppose
                                        // this is the same object as before still not overcome
                    sameObjDetectCount++;
                } else {
                    sameObjDetectCount = 0;
                }
                if(sameObjDetectCount >= 4) {   // if after four times the same object cannot be overcome it means the
                                                // robot is somehow blocked, thus pivot turn
                    lSpeed = -desiredSpeed;
                    rSpeed = desiredSpeed;
                    globalState = PIVOT_ROTATION;
                    globalStatePrev = LINE_SEARCH;
                } else {
                    lSpeed = desiredSpeed*2;
                    rSpeed = desiredSpeed*2;
                    globalState = AVOID_OBJECT;
                    globalStatePrev = LINE_FOLLOW;
                }                
                startAvoidTime = [NSDate date];
            }
            
        } else if(globalState == AVOID_OBJECT) {
            [behaviorStat setText:@"AVOID OBJECT"];
            stopAvoidTime = [NSDate date];
            avoidTime = [stopAvoidTime timeIntervalSinceDate:startAvoidTime];
            if(avoidTime >= 4) {
                globalState = LINE_SEARCH;
                globalStatePrev = AVOID_OBJECT;
                startAvoidTime = [NSDate date];
            }
        } else if(globalState == PIVOT_ROTATION) {
            [behaviorStat setText:@"PIVOT ROTATION"];
            stopAvoidTime = [NSDate date];
            avoidTime = [stopAvoidTime timeIntervalSinceDate:startAvoidTime];
            if(avoidTime >= 4) {
                globalState = LINE_SEARCH;
                globalStatePrev = PIVOT_ROTATION;
            }
        }
        
        //if((lSpeed!=lSpeedPrev) || (rSpeed!=rSpeedPrev)) {
        if((lSpeed==0 && lSpeedPrev>0) || (rSpeed==0 && rSpeedPrev>0)) {
            rSpeedPrev = rSpeed;
            lSpeedPrev = lSpeed;
            lSpeed = 0;
            rSpeed = 0;
        } else {
            rSpeedPrev = rSpeed;
            lSpeedPrev = lSpeed;
        }
        
    } else if(isCliffDetecting) {

        if([robot isCalibrating]) {
            return;
        }
			
        if(globalState == MOVE_AROUND) {
            lSpeed = desiredSpeed;
            rSpeed = desiredSpeed;
            [behaviorStat setText:[NSString stringWithFormat:@"CLIFF NOT DETECTED"]];
				
            if(robGroundValues[0]<groundThreshold || robGroundValues[1]<groundThreshold || robGroundValues[2]<groundThreshold || robGroundValues[3]<groundThreshold) {
            
                minSensorValue = robGroundValues[0];
                minSensor = GROUND_LEFT;
                if(robGroundValues[1] < minSensorValue) {
                    minSensorValue = robGroundValues[1];
                    minSensor = GROUND_CENTER_LEFT;
                }
                if(robGroundValues[2] < minSensorValue) {
                    minSensorValue = robGroundValues[2];
                    minSensor = GROUND_CENTER_RIGHT;
                }
                if(robGroundValues[3] < minSensorValue) {
                    minSensorValue = robGroundValues[3];
                    minSensor = GROUND_RIGHT;
                }
                
                lSpeed = -30;
                rSpeed = -30;
                globalState = COME_BACK;
                moveBackCounter = 0;
                //[robot disableObstacleAvoidance];
                
                [behaviorStat setText:[NSString stringWithFormat:@"CLIFF DETECTED (%d,%d)", lSpeed, rSpeed]];
                
            }
            
            if(robProxValues[0]>=OBJECT_THR || robProxValues[1]>=OBJECT_THR || robProxValues[2]>=OBJECT_THR || robProxValues[3]>=OBJECT_THR) {
                stopAvoidTime = [NSDate date];
                avoidTime = [stopAvoidTime timeIntervalSinceDate:startAvoidTime];
                if(avoidTime < 1) {   // if an object is encountered soon (within 0.5 seconds) then we can suppose
                    // this is the same object as before still not overcome
                    sameObjDetectCount++;
                } else {
                    sameObjDetectCount = 0;
                }
                printf("avoid time = %f\n", avoidTime);
                printf("sameObjCount = %d\n", sameObjDetectCount);
                if(sameObjDetectCount >= 4) {   // if after four times the same object cannot be overcome it means the
                    // robot is somehow blocked, thus pivot turn
                    lSpeed = -desiredSpeed;
                    rSpeed = desiredSpeed;
                    globalState = PIVOT_ROTATION_2;
                    globalStatePrev = MOVE_AROUND;
                    
                } else {
                    lSpeed = desiredSpeed*2;
                    rSpeed = desiredSpeed*2;
                    globalState = AVOID_OBJECT_2;
                    globalStatePrev = MOVE_AROUND;
                }
                startAvoidTime = [NSDate date];
            }
            
        } else if(globalState == COME_BACK) {
				
            moveBackCounter++;
            if(moveBackCounter >= 11) {	// about 750 msec
                stoppedCounter = 0;
                lSpeed = 0;
                rSpeed = 0;
                globalState = STOPPED;
            }
            
            [behaviorStat setText:[NSString stringWithFormat:@"COME BACK (%d,%d)", lSpeed, rSpeed]];
				
        } else if(globalState == STOPPED) {
            
            stoppedCounter++;
            if(stoppedCounter >= 5) {
                rotateCounter = 0;
                switch(minSensor) {
                    case GROUND_LEFT:
                    case GROUND_CENTER_LEFT:
                        lSpeed = 20;
						rSpeed = -20;
                        break;
                        
                    case GROUND_RIGHT:
                    case GROUND_CENTER_RIGHT:
						lSpeed = -20;
						rSpeed = 20;
                        break;
                        
                }
                globalState = ROTATE;
            }
            [behaviorStat setText:[NSString stringWithFormat:@"STOPPED (%d,%d)", lSpeed, rSpeed]];
        
        } else if(globalState == ROTATE) {
            
            rotateCounter++;
            if(rotateCounter >= 16) {
                globalState = MOVE_AROUND;
                //[robot enableObstacleAvoidance];
            }
            
            [behaviorStat setText:[NSString stringWithFormat:@"ROTATE (%d,%d)", lSpeed, rSpeed]];
            
        } else if(globalState == AVOID_OBJECT_2) {
            [behaviorStat setText:@"AVOID OBJECT"];
            stopAvoidTime = [NSDate date];
            avoidTime = [stopAvoidTime timeIntervalSinceDate:startAvoidTime];
            if(avoidTime >= 4) {
                globalState = MOVE_AROUND;
                globalStatePrev = AVOID_OBJECT_2;
                startAvoidTime = [NSDate date];
            }
            if(robGroundValues[0]<groundThreshold || robGroundValues[1]<groundThreshold || robGroundValues[2]<groundThreshold || robGroundValues[3]<groundThreshold) {
                globalState = MOVE_AROUND;
                lSpeed = 0;
                rSpeed = 0;
            }
        } else if(globalState == PIVOT_ROTATION_2) {
            [behaviorStat setText:@"PIVOT ROTATION"];
            stopAvoidTime = [NSDate date];
            avoidTime = [stopAvoidTime timeIntervalSinceDate:startAvoidTime];
            if(avoidTime >= 4) {
                globalState = MOVE_AROUND;
                globalStatePrev = PIVOT_ROTATION_2;
            }
            if(robGroundValues[0]<groundThreshold || robGroundValues[1]<groundThreshold || robGroundValues[2]<groundThreshold || robGroundValues[3]<groundThreshold) {
                globalState = MOVE_AROUND;
                lSpeed = 0;
                rSpeed = 0;
            }
        }
        
        /*}
        
        if(robGroundValues[0]<groundThreshold || robGroundValues[1]<groundThreshold || robGroundValues[2]<groundThreshold || robGroundValues[3]<groundThreshold) {
            lSpeed = 0;
            rSpeed = 0;
            [behaviorStat setText:[NSString stringWithFormat:@"CLIFF DETECTED"]];
        } else {
            lSpeed = desiredSpeed;
            rSpeed = desiredSpeed;
            [behaviorStat setText:[NSString stringWithFormat:@"CLIFF NOT DETECTED"]];
        }
        */
            
    } else if(stayingOnTable) {
        
        if([robot isCalibrating]) {
            return;
        }
        
        if(globalState == ENABLE_OBSTACLE_AVOIDANCE) {
            [robot enableObstacleAvoidance];
            globalState = CHECK_OA_ENABLED;
            robotStoppedCounter = 0;
            [behaviorStat setText:[NSString stringWithFormat:@"ENABLE OA"]];
        } else if(globalState == CHECK_OA_ENABLED) {
            robotStoppedCounter++;
            if(robotStoppedCounter >= 5) {
                if([robot isObstacleAvoidanceEnabled]) {
                    globalState = ENABLE_CLIFF_AVOIDANCE;
                } else {
                    globalState = ENABLE_OBSTACLE_AVOIDANCE;
                }
            }
            [behaviorStat setText:[NSString stringWithFormat:@"CHECK OA"]];
        } else if(globalState == ENABLE_CLIFF_AVOIDANCE) {
            [robot enableCliffAvoidance];
            globalState = CHECK_CA_ENABLED;
            robotStoppedCounter = 0;
            [behaviorStat setText:[NSString stringWithFormat:@"ENABLE CA"]];
        } else if(globalState == CHECK_CA_ENABLED) {
            robotStoppedCounter++;
            if(robotStoppedCounter >= 5) {
                if([robot isCliffAvoidanceEnabled]) {
                    globalState = MOVE_AROUND;
                } else {
                    globalState = ENABLE_CLIFF_AVOIDANCE;
                }
            }
            [behaviorStat setText:[NSString stringWithFormat:@"CHECK CA"]];
        } else if(globalState == MOVE_AROUND) {
            lSpeed = desiredSpeed;
            rSpeed = desiredSpeed;
            [behaviorStat setText:[NSString stringWithFormat:@"MOVE AROUND"]];
            
            if(initCounter > 0) { 	// let the robot start moving forward before beginning the behavior otherwise
                initCounter--;		// a false cliff is detected (vel=0 for both motors)
                [robot setLeftSpeed:lSpeed];
                [robot setRightSpeed:rSpeed];
                return;
            }
            
            if([robot getRightSpeed]==0 && [robot getLeftSpeed]==0) {   // cliff detected
                robotStoppedCounter++;
            } else {
                robotStoppedCounter = 0;
            }
            
            if(robotStoppedCounter >= 5) {	//5*50  about 250 ms
                
                [imageState setImage:imgDriveFear];
                
                robotStoppedCounter = 0;
                
                minSensorValue = robGroundValues[0];
                minSensor = GROUND_LEFT;
                if(robGroundValues[1] < minSensorValue) {
                    minSensorValue = robGroundValues[1];
                    minSensor = GROUND_CENTER_LEFT;
                }
                if(robGroundValues[2] < minSensorValue) {
                    minSensorValue = robGroundValues[2];
                    minSensor = GROUND_CENTER_RIGHT;
                }
                if(robGroundValues[3] < minSensorValue) {
                    minSensorValue = robGroundValues[3];
                    minSensor = GROUND_RIGHT;
                }
                
                lSpeed = 0;
                rSpeed = 0;
                stoppedCounter = 0;
                globalState = STOPPED2;
                moveBackCounter = 0;
                
                [behaviorStat setText:[NSString stringWithFormat:@"CLIFF DETECTED (%d,%d)", lSpeed, rSpeed]];

            }
            
        } else if(globalState == STOPPED2) {
            
            stoppedCounter++;
            if(stoppedCounter >= 5) {
                globalState = CHECK_CA_DISABLED;
                [robot disableCliffAvoidance];	// disable cliff avoidance to let the robot move backward
            }
            [behaviorStat setText:[NSString stringWithFormat:@"STOPPED2 (%d,%d)", lSpeed, rSpeed]];
            
        } else if(globalState == DISABLE_CLIFF_AVOIDANCE) {
            [robot disableCliffAvoidance];
            globalState = CHECK_CA_DISABLED;
        } else if(globalState == CHECK_CA_DISABLED) {
            if([robot isCliffAvoidanceEnabled] == false) {
                globalState = COME_BACK;
                lSpeed = -30;
                rSpeed = -30;
            } else {
                globalState = DISABLE_CLIFF_AVOIDANCE;
            }
        } else if(globalState == COME_BACK) {
            
            moveBackCounter++;
            if(moveBackCounter >= 11) {	// about 750 msec
                stoppedCounter = 0;
                lSpeed = 0;
                rSpeed = 0;
                globalState = STOPPED;
            }
            
            [behaviorStat setText:[NSString stringWithFormat:@"COME BACK (%d,%d)", lSpeed, rSpeed]];
            
        } else if(globalState == STOPPED) {
            
            stoppedCounter++;
            if(stoppedCounter >= 5) {
                rotateCounter = 0;
                switch(minSensor) {
                    case GROUND_LEFT:
                    case GROUND_CENTER_LEFT:
                        lSpeed = 20;
						rSpeed = -20;
                        [imageState setImage:imgDriveRight];
                        break;
                        
                    case GROUND_RIGHT:
                    case GROUND_CENTER_RIGHT:
						lSpeed = -20;
						rSpeed = 20;
                        [imageState setImage:imgDriveLeft];
                        break;
                        
                }
                globalState = ROTATE;
            }
            [behaviorStat setText:[NSString stringWithFormat:@"STOPPED (%d,%d)", lSpeed, rSpeed]];
            
        } else if(globalState == ROTATE) {
            
            rotateCounter++;
            if(rotateCounter >= 16) {
                globalState = ENABLE_CLIFF_AVOIDANCE;
                [imageState setImage:imgDriveNormal];
            }
            
            [behaviorStat setText:[NSString stringWithFormat:@"ROTATE (%d,%d)", lSpeed, rSpeed]];
            
        }
        
    } else {
        
        lSpeed = 0;
        rSpeed = 0;
        [behaviorStat setText:[NSString stringWithFormat:@"READY"]];
        
    }

    [robot setLeftSpeed:lSpeed];
    [robot setRightSpeed:rSpeed];

}

#pragma mark Initialization routines
- (void)awakeFromNib {
    
    NSLog(@"awakeFromNib called!");
    
	robot = [WheelphoneRobot new];
    
    isFollowing = false;
    isCliffDetecting = false;
    globalState = LINE_SEARCH;
    globalStatePrev = LINE_SEARCH;
    groundThreshold = INIT_GROUND_THR;
    robGroundValues[0]=robGroundValues[1]=robGroundValues[2]=robGroundValues[3]=1023;
    lineFound = 0;
    outOfLine = 0;
    minSpeedLineFollow = 10;
    tempSpeed = 0;
    desiredSpeed = INIT_SPEED;
    maxSpeed = desiredSpeed*1.5;
    lineLostThr = INIT_LOST_THR;
    lSpeed = 0;
    rSpeed = 0;
    lSpeedPrev = 0;
    rSpeedPrev = 0;
    isNearObject = false;
    stayingOnTable = false;
    
    [robot enableObstacleAvoidance];
    
}


@end
