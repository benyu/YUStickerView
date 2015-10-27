//
//  YUStickerView.h
//  Babe
//
//  Created by Yu Jiang on 6/4/15.
//  Copyright (c) 2015 Benyu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface YUStickerView : UIView
@property(nonatomic, strong) UIImage *image;
@property(nonatomic, assign, getter= isEditing)  BOOL editable;

- (void)hideEditingHandlers: (BOOL)hidden;
@end
