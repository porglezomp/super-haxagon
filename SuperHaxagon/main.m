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
    int point = (y*bpr + x*bytes_per_pixel);
    c.b = bytes[point+0];
    c.g = bytes[point+1];
    c.r = bytes[point+2];
    return c;
}

int main(int argc, const char * argv[])
{

    @autoreleasepool {
//        [NSThread sleepForTimeInterval:5.0f];
        CGImageRef image = CGDisplayCreateImage(CGMainDisplayID());
        NSData *data = (NSData *)CFBridgingRelease(CGDataProviderCopyData(CGImageGetDataProvider(image)));
        
        bytes = [data bytes];
        
        int width = (int) CGImageGetWidth(image);
        int height = (int) CGImageGetHeight(image);
        bpr = (int) CGImageGetBytesPerRow(image);
        size_t bpp = CGImageGetBitsPerPixel(image);
        size_t bpc = CGImageGetBitsPerComponent(image);
        bytes_per_pixel = (int) bpp / bpc;
        
        int downsample_by = 10;
        int w = width/downsample_by; int h = height/downsample_by;
        
        UInt8 pixelData[w * h * 3];
        
        // fill the raw pixel buffer with arbitrary gray color for test
        int dx = width/w;
        int dy = height/h;
        
        int i = 0;
        int r = 0; int g = 0; int b = 0;
        for (int y = 0; y < h; y++) {
            for(int x = 0; x < w; x++) {
                int dest = (y*w + x)*3;
                color c = getColorAtPoint(x*dx, y*dy);
                pixelData[dest+0] = c.r;
                pixelData[dest+1] = c.g;
                pixelData[dest+2] = c.b;
                i++;
            }
        }
        NSLog(@"%i", i);
        
        savePixelsToFile(pixelData, @"/Users/caleb/Desktop/stuff.png", w, h);
    
        CGImageRelease(image);
        
    }
    return 0;
}

