//
//  ViewController.m
//  My_Camera_App
//
//  Created by Judy Chang on 9/10/16.
//  Copyright © 2016 Judy Chang. All rights reserved.
//

#import "ViewController.h"

// Include stdlib.h and std namespace so we can mix C++ code in here
#include <stdlib.h>
using namespace std;

@interface ViewController()
{
    UIImageView *liveView_; // Live output from the camera
    UIImageView *resultView_; // Preview view of everything...
    UIButton *takephotoButton_, *goliveButton_; // Button to initiate OpenCV processing of image
    CvPhotoCamera *photoCamera_; // OpenCV wrapper class to simplfy camera access through AVFoundation
}
@end

@implementation ViewController


//===============================================================================================
// Setup view for excuting App
- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view, typically from a nib.
    
    // 1. Setup the your OpenCV view, so it takes up the entire App screen......
    int view_width = self.view.frame.size.width;
    int view_height = (640*view_width)/480; // Work out the viw-height assuming 640x480 input
    int view_offset = (self.view.frame.size.height - view_height)/2;
    cout << view_width << " " << view_height << " " << view_offset << endl;
    liveView_ = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, view_offset, view_width, view_height)];
    [self.view addSubview:liveView_]; // Important: add liveView_ as a subview
    //resultView_ = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, 960, 1280)];
    resultView_ = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, view_offset, view_width, view_height)];
    [self.view addSubview:resultView_]; // Important: add resultView_ as a subview
    resultView_.hidden = true; // Hide the view
    
    // 2. First setup a button to take a single picture
    takephotoButton_ = [self simpleButton:@"Take Photo" buttonColor:[UIColor redColor]];
    // Important part that connects the action to the member function buttonWasPressed
    [takephotoButton_ addTarget:self action:@selector(buttonWasPressed) forControlEvents:UIControlEventTouchUpInside];
    
    // 3. Setup another button to go back to live video
    goliveButton_ = [self simpleButton:@"Go Live" buttonColor:[UIColor greenColor]];
    // Important part that connects the action to the member function buttonWasPressed
    [goliveButton_ addTarget:self action:@selector(liveWasPressed) forControlEvents:UIControlEventTouchUpInside];
    [goliveButton_ setHidden:true]; // Hide the button
    
    // 4. Initialize the camera parameters and start the camera (inside the App)
    photoCamera_ = [[CvPhotoCamera alloc] initWithParentView:liveView_];
    photoCamera_.delegate = self;
    
    // This chooses whether we use the front or rear facing camera
    photoCamera_.defaultAVCaptureDevicePosition = AVCaptureDevicePositionFront;
    
    // This is used to set the image resolution
    photoCamera_.defaultAVCaptureSessionPreset = AVCaptureSessionPreset640x480;
    
    // This is used to determine the device orientation
    photoCamera_.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    
    // This starts the camera capture
    [photoCamera_ start];
    
}

//===============================================================================================
// This member function is executed when the button is pressed
- (void)buttonWasPressed {
    [photoCamera_ takePicture];
}
//===============================================================================================
// This member function is executed when the button is pressed
- (void)liveWasPressed {
    [takephotoButton_ setHidden:false]; [goliveButton_ setHidden:true]; // Switch visibility of buttons
    resultView_.hidden = true; // Hide the result view again
    [photoCamera_ start];
}
//===============================================================================================
// To be compliant with the CvPhotoCameraDelegate we need to implement these two methods
- (void)photoCamera:(CvPhotoCamera *)photoCamera capturedImage:(UIImage *)image
{
//    cout << "capture image_size: " <<  << endl;
    [photoCamera_ stop];
    resultView_.hidden = false; // Turn the hidden view on
    
    // You can apply your OpenCV code HERE!!!!!
    // If you want, you can ignore the rest of the code base here, and simply place
    // your OpenCV code here to process images.
    
    // First load the face detector
    NSString *faceCascadePath = [[NSBundle mainBundle] pathForResource:@"haarcascade_frontalface_alt" ofType:@"xml"];
    cv::CascadeClassifier face_cascade;
    if(!face_cascade.load([faceCascadePath UTF8String])) {
        cout << "Unable to load the face detector!!!!" << endl;
    }
    
    NSString *eyeCascadePath = [[NSBundle mainBundle] pathForResource:@"haarcascade_eye" ofType:@"xml"];
    cv::CascadeClassifier eye_cascade;
    if(!eye_cascade.load([eyeCascadePath UTF8String])) {
        cout << "Unable to load the face detector!!!!" << endl;
    }
    
//    cv::Mat cvImage; UIImageToMat(image, cvImage);
//    cout << "cvImage" << cvImage.size() << endl;
    
    UIImage *imageToDisplay = [UIImage imageWithCGImage:[image CGImage]
                        scale:[image scale]
                  orientation: UIImageOrientationUp];
//    cv::resize(cvImage,cvImage,cv::Size())
//    cv::flip(cvImage,cvImage,0);
    
    cv::Mat cvImage; UIImageToMat(imageToDisplay, cvImage);
    cout << "cvImage" << cvImage.size() << endl;

//    cout << "cvImage2 "  << cvImage2.size() << endl;
//    cout << "rotate cvImage" << UIImageToMat(imageToDisplay,cvImage2).size() << endl;
    cv::transpose(cvImage,cvImage);

    vector<cv::Rect> faces;
    face_cascade.detectMultiScale( cvImage, faces, 1.1, 2, 0 | CV_HAAR_SCALE_IMAGE, cv::Size(30, 30));
    cout << "Detected " << faces.size() << " faces!!!! " << endl;
    
    vector<cv::Rect> eyes;
    eye_cascade.detectMultiScale( cvImage, eyes, 1.1, 10, 0 | CV_HAAR_SCALE_IMAGE, cv::Size(50, 50));
    cout << "Detected " << eyes.size() << " eyes!!!! " << endl;
    
    // Next step is to display the result
    cv::Mat display_im;
    if(cvImage.channels() == 4) display_im = cvImage.clone();
    else {
        cout << cvImage.channels() << endl;
        cv::cvtColor(cvImage, display_im, CV_GRAY2RGB);
    }
//    cout << "display_img"
    
    // If faces are detected then loop through and display bounding boxes
    if(faces.size() > 0) {
        for(int i=0; i<faces.size(); i++) {
            rectangle(display_im, faces[i], cv::Scalar(255,0,0));
        }
    }
    
    // If eyes are detected then loop through and display
    if(eyes.size() > 0) {
        for(int i=0; i<eyes.size(); i++) {
            cout << eyes[i] << endl;
            cv::Point center(eyes[i].x+eyes[i].width*0.5, eyes[i].y+eyes[i].height*0.5);
            int radius = (eyes[i].width + eyes[i].height)*0.25;
            circle(display_im, center, radius, cv::Scalar(0,255,0));
        }
    }
    
    cout << display_im.cols << " " << display_im.rows << endl;
    string name = "yufangc";
    int font = cv::FONT_HERSHEY_DUPLEX;
    double fontScale = 0.5;
    int thickness = 0;
    
    cv::Size textSize = cv::getTextSize(name, font, fontScale, thickness, 0);
    cv::Point pos((display_im.cols-textSize.width)/2, (display_im.rows-textSize.height));
    
//    cv::Point pos(display_im.cols/2, display_im.rows-15);
    cout << pos << endl;
    putText(display_im, name, pos, font, fontScale, cv::Scalar(230,130,255));
    
    
    cv::transpose(display_im,display_im);

    UIImage *resImage = MatToUIImage(display_im);
//    resultView_.image = resImage;
    
    // Special part to ensure the image is rotated properly when the image is converted back
    resultView_.image =  [UIImage imageWithCGImage:[resImage CGImage]
                                             scale:1.0
                                       orientation: UIImageOrientationLeftMirrored];
//    cout << resultView_.image.size.height << " " << resultView_.image.size.width <<  endl;
    [takephotoButton_ setHidden:true]; [goliveButton_ setHidden:false]; // Switch visibility of buttons
}
- (void)photoCameraCancel:(CvPhotoCamera *)photoCamera
{
    
}
//===============================================================================================
// Simple member function to initialize buttons in the bottom of the screen so we do not have to
// bother with storyboard, and can go straight into vision on mobiles
//
- (UIButton *) simpleButton:(NSString *)buttonName buttonColor:(UIColor *)color
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom]; // Initialize the button
    // Bit of a hack, but just positions the button at the bottom of the screen
    int button_width = 200; int button_height = 50; // Set the button height and width (heuristic)
    // Botton position is adaptive as this could run on a different device (iPAD, iPhone, etc.)
    int button_x = (self.view.frame.size.width - button_width)/2; // Position of top-left of button
    int button_y = self.view.frame.size.height - 80; // Position of top-left of button
    button.frame = CGRectMake(button_x, button_y, button_width, button_height); // Position the button
    [button setTitle:buttonName forState:UIControlStateNormal]; // Set the title for the button
    [button setTitleColor:color forState:UIControlStateNormal]; // Set the color for the title
    
    [self.view addSubview:button]; // Important: add the button as a subview
    //[button setEnabled:bflag]; [button setHidden:(!bflag)]; // Set visibility of the button
    return button; // Return the button pointer
}

//===============================================================================================
// Standard memory warning component added by Xcode
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end