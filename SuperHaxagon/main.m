//
//  main.m
//  SuperHaxagon
//
//  Created by Caleb Jones on 9/6/14.
//  Copyright (c) 2014 Caleb Jones. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ApplicationServices/ApplicationServices.h>

BOOL CGImageWriteToFile(CGImageRef image, NSString *path) {
    CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:path];
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL(url, kUTTypePNG, 1, NULL);
    if (!destination) {
        NSLog(@"Failed to create CGImageDestination for %@", path);
        return NO;
    }
    
    CGImageDestinationAddImage(destination, image, nil);
    
    if (!CGImageDestinationFinalize(destination)) {
        NSLog(@"Failed to write image to %@", path);
    }
    
    CFRelease(destination);
    
    return YES;
}

void savePixelsToFile(uint8 pixels[], NSString *filename, int width, int height) {
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    CFDataRef rgbData = CFDataCreate(NULL, pixels, width * height * 3);
    CGDataProviderRef provider = CGDataProviderCreateWithCFData(rgbData);
    CGImageRef rgbImageRef = CGImageCreate(width, height, 8, 24, width * 3, colorspace, kCGBitmapByteOrderDefault, provider, NULL, true, kCGRenderingIntentDefault);
    CFRelease(rgbData);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorspace);
    
    CGImageWriteToFile(rgbImageRef, filename);
    
    CGImageRelease(rgbImageRef);
}

struct color {
    uint8 r;
    uint8 g;
    uint8 b;
}; typedef struct color color;

const uint8_t *bytes;
int bpr, bytes_per_pixel;


color getColorAtPoint(int x, int y) {
    color c;
    if (x < 0 || y < 0 ) return c;
    int point = (y*bpr + x*bytes_per_pixel);
    c.b = bytes[point+0];
    c.g = bytes[point+1];
    c.r = bytes[point+2];
    return c;
}

BOOL colorEqual(color a, color b) {
    return a.r == b.r && a.g == b.g && a.b == b.b;
}

#define SPACE_KEY_CODE  49
#define LEFT_KEY_CODE   123
#define RIGHT_KEY_CODE  124

#define DEG2RAD M_PI/180

int main(int argc, const char * argv[])
{

    @autoreleasepool {
        [NSThread sleepForTimeInterval:5.0];
        
        CGEventRef sd = CGEventCreateKeyboardEvent(NULL, SPACE_KEY_CODE, YES);
        CGEventRef su = CGEventCreateKeyboardEvent(NULL, SPACE_KEY_CODE, NO);
        CGEventRef ld = CGEventCreateKeyboardEvent(NULL, LEFT_KEY_CODE, YES);
        CGEventRef lu = CGEventCreateKeyboardEvent(NULL, LEFT_KEY_CODE, NO);
        CGEventRef rd = CGEventCreateKeyboardEvent(NULL, RIGHT_KEY_CODE, YES);
        CGEventRef ru = CGEventCreateKeyboardEvent(NULL, RIGHT_KEY_CODE, NO);
        
        CGEventPost(kCGAnnotatedSessionEventTap, sd);
        [NSThread sleepForTimeInterval:0.1];
        CGEventPost(kCGAnnotatedSessionEventTap, su);
        
        int timesteps = 100;
        int downsample_by = 3;
        int angles = 100;
        uint8_t pixelData[angles*timesteps*3];
        for (int t = 0; t < timesteps; t++) {
            [NSThread sleepForTimeInterval:0.1];
            CGImageRef image = CGDisplayCreateImage(CGMainDisplayID());
            NSData *data = (NSData *)CFBridgingRelease(CGDataProviderCopyData(CGImageGetDataProvider(image)));
            
            bytes = [data bytes];
            
            int width = (int) CGImageGetWidth(image);
            int height = (int) CGImageGetHeight(image);
            bpr = (int) CGImageGetBytesPerRow(image);
            size_t bpp = CGImageGetBitsPerPixel(image);
            size_t bpc = CGImageGetBitsPerComponent(image);
            bytes_per_pixel = (int) bpp / bpc;
            
//            int w = width/downsample_by;
//            int h = height/downsample_by;
            
            int da = 360/angles;
            
            for (int a = 0; a < angles; a++) {
                int pixel = (t*angles + a)*3;
                pixelData[pixel+0] = 0;
                pixelData[pixel+1] = 0;
                pixelData[pixel+2] = 0;
                
                float rangle = a*da*DEG2RAD;
                float rangle2 = (a-1)*da*DEG2RAD;
                int x1 = cos(rangle)*100;
                int y1 = sin(rangle)*100;
                int x1b = cos(rangle2)*100;
                int y1b = sin(rangle2)*100;
                if (colorEqual(getColorAtPoint(x1+width/2, y1+height/2),
                               getColorAtPoint(x1b+width/2, y1b+height/2))) {
                    continue;
                }
                
                int x2 = x1*2; int y2 = y1*2;
                x2 += width/2; y2 += height/2;
                int x2b = x1b*2; int y2b = y1b*2;
                x2b += width/2; y2b += height/2;
                if (colorEqual(getColorAtPoint(x2, y2),
                               getColorAtPoint(x2b, y2b))) {
                    pixelData[pixel+0] = 255;
                    continue;
                }
                
                int x3 = x1*3; int y3 = y1*3;
                x3 += width/2; y3 += height/2;
                int x3b = x1b*3; int y3b = y1b*3;
                x3b += width/2; y3b += height/2;
                if (colorEqual(getColorAtPoint(x3, y3),
                               getColorAtPoint(x3b, y3b))) {
                    pixelData[pixel+1] = 255;
                    continue;
                }
                
                pixelData[pixel+0] = 255;
                pixelData[pixel+1] = 255;
                pixelData[pixel+2] = 255;
            }
        
            CGImageRelease(image);
        }
        
        NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:
                         [NSString stringWithFormat:@"Desktop/Haxagon/gradient.png"]];
        savePixelsToFile(pixelData, path, angles, timesteps);
        
        CGEventPost(kCGAnnotatedSessionEventTap, ru);
        CGEventPost(kCGAnnotatedSessionEventTap, lu);
        CFRelease(su);
        CFRelease(sd);
        CFRelease(ld);
        CFRelease(lu);
        CFRelease(rd);
        CFRelease(ru);
    }
    return 0;
}

