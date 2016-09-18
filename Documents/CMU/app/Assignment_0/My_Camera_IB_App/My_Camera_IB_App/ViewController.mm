//
//  ViewController.m
//  My_Camera_IB_App
//
//  Created by Judy Chang on 9/12/16.
//  Copyright © 2016 Judy Chang. All rights reserved.
//

#import "ViewController.h"
using namespace::std;
@interface ViewController () {
    CvPhotoCamera *photoCamera_; // OpenCV wrapper class to simplfy camera access through AVFoundation
}
@property (strong, nonatomic) IBOutlet UIImageView *liveView_;

@property (strong, nonatomic) IBOutlet UIImageView *resultView_;

@property (weak, nonatomic) IBOutlet UIButton *goliveButton_;

@property (weak, nonatomic) IBOutlet UIButton *takephotoButton_;
@property (weak, nonatomic) IBOutlet UILabel *name;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    cout << "inViewDidLoad" << endl;
    int view_width = self.view.frame.size.width;
    int view_height = (640*view_width)/480; // Work out the viw-height assuming 640x480 input
    int view_offset = (self.view.frame.size.height - view_height)/2;
    cout << view_width << " " << view_height << " " << view_offset << endl;
    
//    self.liveView_ = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, view_offset, view_width, view_height)];
    [self.view addSubview:self.liveView_]; // Important: add liveView_ as a subview
    //resultView_ = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, 960, 1280)];
//    self.resultView_ = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, view_offset, view_width, view_height)];
    [self.view addSubview:self.resultView_]; // Important: add resultView_ as a subview
    self.resultView_.hidden = YES; // Hide the view
    
    [self.view addSubview:self.takephotoButton_];
    [self.view addSubview:self.goliveButton_];
    [self.view addSubview:self.name];
    self.goliveButton_.hidden = YES;
    
    // 4. Initialize the camera parameters and start the camera (inside the App)
    photoCamera_ = [[CvPhotoCamera alloc] initWithParentView:self.liveView_];
    photoCamera_.delegate = self;
    
    // This chooses whether we use the front or rear facing camera
    photoCamera_.defaultAVCaptureDevicePosition = AVCaptureDevicePositionFront;
    
    // This is used to set the image resolution
    photoCamera_.defaultAVCaptureSessionPreset = AVCaptureSessionPreset640x480;
    
    // This is used to determine the device orientation
    photoCamera_.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    
    // This starts the camera capture
    [photoCamera_ start];

    
    // Do any additional setup after loading the view, typically from a nib.
}
- (IBAction)buttonWasPressed:(id)sender {
    [photoCamera_ takePicture];
}

- (IBAction)liveWasPressed:(id)sender {
    self.takephotoButton_.hidden= NO;
    self.goliveButton_.hidden= YES ;// Switch visibility of buttons
    self.resultView_.hidden = YES; // Hide the result view again
    [photoCamera_ start];
}

//===============================================================================================
// To be compliant with the CvPhotoCameraDelegate we need to implement these two methods
- (void)photoCamera:(CvPhotoCamera *)photoCamera capturedImage:(UIImage *)image
{
    //    cout << "capture image_size: " <<  << endl;
    [photoCamera_ stop];
    self.resultView_.hidden = NO;
    
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
    
//    cout << display_im.cols << " " << display_im.rows << endl;
//    string name = "yufangc";
//    int font = cv::FONT_HERSHEY_DUPLEX;
//    double fontScale = 0.2;
//    int thickness = 0;
//    
//    cv::Size textSize = cv::getTextSize(name, font, fontScale, thickness, 0);
//    cv::Point pos((display_im.cols-textSize.width)/2, (display_im.rows-textSize.height));
//    
//    //    cv::Point pos(display_im.cols/2, display_im.rows-15);
//    cout << pos << endl;
//    putText(display_im, name, pos, font, fontScale, cv::Scalar(230,130,255));
    
    
    cv::transpose(display_im,display_im);
    
    UIImage *resImage = MatToUIImage(display_im);
    //    resultView_.image = resImage;
    
    // Special part to ensure the image is rotated properly when the image is converted back
    self.resultView_.image =  [UIImage imageWithCGImage:[resImage CGImage]
                                             scale:1.0
                                       orientation: UIImageOrientationLeftMirrored];
    //    cout << resultView_.image.size.height << " " << resultView_.image.size.width <<  endl;
    self.takephotoButton_.hidden = YES;
    self.goliveButton_.hidden = NO; // Switch visibility of buttons
}
- (void)photoCameraCancel:(CvPhotoCamera *)photoCamera
{
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
