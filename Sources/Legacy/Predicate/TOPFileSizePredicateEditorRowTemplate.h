//
//  FileSizePredicateEditorRowTemplate.h
//  VisualDiffer
//
//  Created by davide ficano on 07/03/12.
//  Copyright (c) 2012 visualdiffer.com
//

#import <AppKit/AppKit.h>
#import "TitlePredicateEditorRowTemplate.h"

@interface TOPFileSizePredicateEditorRowTemplate : TitlePredicateEditorRowTemplate

@property (strong) NSPopUpButton* sizePopupButton;
@end
