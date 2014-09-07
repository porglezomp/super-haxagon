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

int main(int argc, const char * argv[])
{

    @autoreleasepool {
        [NSThread sleepForTimeInterval:5.0f];
        CGImageRef image = CGDisplayCreateImage(CGMainDisplayID());
        NSData *data = (NSData *)CFBridgingRelease(CGDataProviderCopyData(CGImageGetDataProvider(image)));
        
        const uint8_t *bytes = [data bytes];
        
        size_t width = CGImageGetWidth(image);
        size_t height = CGImageGetHeight(image);
        size_t bpr = CGImageGetBytesPerRow(image);
        size_t bpp = CGImageGetBitsPerPixel(image);
        size_t bpc = CGImageGetBitsPerComponent(image);
        size_t bytes_per_pixel = bpp / bpc;
        size_t pixels_per_row = bpr / bpp;
    
        NSUInteger len = [data length];
        
//        68*38
        
        int w = width/5; int h = height/5;
        
        UInt8 pixelData[w * h * 3];
        
        // fill the raw pixel buffer with arbitrary gray color for test
        int dx = width/w;
        int dy = height/h;
        
        for (int y = 0; y < h; y++) {
            for(int x = 0; x < w; x++) {
                int dest = (y*w + x)*3;
                int src = (y*bpr*5 + x*bytes_per_pixel*5);
                pixelData[dest+0] = bytes[src+2];
                pixelData[dest+1] = bytes[src+1];
                pixelData[dest+2] = bytes[src+0];
            }
        }
        
        CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
        
        CFDataRef rgbData = CFDataCreate(NULL, pixelData, w * h * 3);
        
        CGDataProviderRef provider = CGDataProviderCreateWithCFData(rgbData);
        
        CGImageRef rgbImageRef = CGImageCreate(w, h, 8, 24, w * 3, colorspace, kCGBitmapByteOrderDefault, provider, NULL, true, kCGRenderingIntentDefault);
        
        CFRelease(rgbData);
        
        CGDataProviderRelease(provider);
        
        CGColorSpaceRelease(colorspace);
        
        CGImageWriteToFile(rgbImageRef, @"/Users/caleb/Desktop/stuff.png");
        
        CGImageRelease(rgbImageRef);
        
        NSLog(@"%li %li", width, height);
        
        CGImageRelease(image);
        
    }
    return 0;
}

