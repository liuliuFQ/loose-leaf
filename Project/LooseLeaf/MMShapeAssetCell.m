//
//  MMShapeAssetCell.m
//  LooseLeaf
//
//  Created by Adam Wulf on 7/21/18.
//  Copyright © 2018 Milestone Made, LLC. All rights reserved.
//

#import "MMShapeAssetCell.h"
#import "MMBufferedImageView.h"
#import "MMShapeAsset.h"
#import "Constants.h"


@implementation MMShapeAssetCell {
    UILabel* shapeNameLabel;
    MMBufferedImageView* bufferedImage;
}

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        shapeNameLabel = [[UILabel alloc] init];
        [shapeNameLabel setBackgroundColor:[UIColor whiteColor]];
        [shapeNameLabel setTextColor:[UIColor blackColor]];

        bufferedImage = [[MMBufferedImageView alloc] initWithFrame:CGRectInset(self.bounds, 2, 2)];
        bufferedImage.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        [self addSubview:bufferedImage];
        [self addSubview:shapeNameLabel];

        UITapGestureRecognizer* tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)];
        [bufferedImage addGestureRecognizer:tapGesture];
    }
    return self;
}

#pragma mark - Gesture

- (void)tapped:(id)gesture {
    [[self album] loadPhotosAtIndexes:[[NSIndexSet alloc] initWithIndex:[self index]] usingBlock:^(MMDisplayAsset* result, NSUInteger _index, BOOL* stop) {
        if (result) {
            [[self delegate] assetWasTapped:result fromView:bufferedImage withRotation:bufferedImage.rotation];
        }
    }];
}

#pragma mark - Notification

- (void)assetUpdated:(NSNotification*)note {
    [super assetUpdated:note];

    // called when the underlying asset is updated.
    // this may or may not ever be called depending
    // on the asset (PDFs in particular use
    // this to update their thumbnail)
    dispatch_async(dispatch_get_main_queue(), ^{
        MMDisplayAsset* asset = [note object];
        bufferedImage.image = asset.aspectRatioThumbnail;
    });
}

#pragma mark - Properties

- (void)loadPhotoFromAlbum:(MMDisplayAssetGroup*)album atIndex:(NSInteger)photoIndex {
    @try {
        [super loadPhotoFromAlbum:album atIndex:photoIndex];

        NSIndexSet* assetsToLoad = [[NSIndexSet alloc] initWithIndex:photoIndex];

        [album loadPhotosAtIndexes:assetsToLoad usingBlock:^(MMDisplayAsset* result, NSUInteger index, BOOL* stop) {
            if ([result isKindOfClass:[MMShapeAsset class]]) {
                shapeNameLabel.text = [[result fullResolutionURL] lastPathComponent];
                [shapeNameLabel sizeToFit];
                shapeNameLabel.center = CGRectGetMidPoint([self bounds]);

                [bufferedImage setPreferredAspectRatioForEmptyImage:result.fullResolutionSize];
                bufferedImage.image = result.aspectRatioThumbnail;
                bufferedImage.rotation = RandomPhotoRotation(photoIndex) + [result defaultRotation];
            } else {
                // was an error. possibly syncing the ipad to iphoto,
                // so the album is updated faster than we can enumerate.
                // just noop.
                // https://github.com/adamwulf/loose-leaf/issues/529
            }
        }];
    }
    @catch (NSException* exception) {
        DebugLog(@"gotcha");
    }
}

- (CGFloat)rotation {
    return bufferedImage.rotation;
}

- (void)setRotation:(CGFloat)rotation {
    bufferedImage.rotation = rotation;

    [super setRotation:rotation];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
