//
//  ViewController.h
//  My_Camera_IB_App
//
//  Created by Judy Chang on 9/12/16.
//  Copyright © 2016 Judy Chang. All rights reserved.
//

#import <UIKit/UIKit.h>
#ifdef __cplusplus
#import <opencv2/opencv.hpp>
#import "opencv2/highgui/ios.h"
#endif

@interface ViewController : UIViewController<CvPhotoCameraDelegate>

@end

