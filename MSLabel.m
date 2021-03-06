//
//  MSLabel.m
//  Miso
//
//  Created by Joshua Wu on 11/15/11.
//  Copyright (c) 2011 Miso. All rights reserved.
//

#import "MSLabel.h"

// small buffer to allow for characters like g,y etc
static const int kAlignmentBuffer = 5;

@interface MSLabel ()

@property (nonatomic, assign) int drawX;

- (void)setup;
- (NSArray *)stringsFromText:(NSString *)string;
- (NSMutableArray *)stringsWithWordsWrappedFromArray:(NSArray *)strings;
- (NSMutableArray *)arrayOfCharactersInString:(NSString *)string;
- (NSString *)lastWordInString:(NSString *)string;

@end

@implementation MSLabel

@synthesize lineHeight = _lineHeight;
@synthesize verticalAlignment = _verticalAlignment;
@synthesize drawX = _drawX;

#pragma mark - Initilisation

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        [self setup];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if(self)
    {
        [self setup];
    }
    
    return self;
}


#pragma mark - Drawing

- (void)drawTextInRect:(CGRect)rect
{
    NSArray *slicedStrings = [self stringsFromText:self.text];
    [self.textColor set];
    
    int numLines = slicedStrings.count;
    if (numLines > self.numberOfLines && self.numberOfLines != 0)
    {
        numLines = self.numberOfLines;
    }
    
    int drawY = (self.frame.size.height / 2 - (_lineHeight * numLines) / 2) - kAlignmentBuffer;
    
    for (int i = 0; i < numLines; i++)
    {
        
        NSString *line = [slicedStrings objectAtIndex:i];
        
        // calculate draw Y based on alignment
        switch (_verticalAlignment)
        {
            case MSLabelVerticalAlignmentTop:
            {
                drawY = i * _lineHeight;
            }
                break;
            case MSLabelVerticalAlignmentMiddle:
            {
                if(i > 0)
                {
                    drawY += _lineHeight;
                }
            }
                break;
            case MSLabelVerticalAlignmentBottom:
            {
                drawY = (self.frame.size.height - ((i + 1) * _lineHeight)) - kAlignmentBuffer;
            }
                break;
            default:
            {
                if(i > 0)
                {
                    drawY += _lineHeight;
                }
            }
                break;
        }
        
        // calculate draw X based on textAlignmentment
        if (self.textAlignment == UITextAlignmentCenter)
        {
            _drawX = floorf((self.frame.size.width - [line sizeWithFont:self.font].width) / 2);
        }
        else if (self.textAlignment == UITextAlignmentRight)
        {
            _drawX = (self.frame.size.width - [line sizeWithFont:self.font].width);
        }
        
        if(_drawX < 0)
        {
            _drawX = 0;
        }
        
        [line drawAtPoint:CGPointMake(_drawX, drawY) forWidth:self.frame.size.width withFont:self.font fontSize:self.font.pointSize lineBreakMode:UILineBreakModeClip baselineAdjustment:UIBaselineAdjustmentNone];
    }
}


#pragma mark - Properties

- (void)setLineHeight:(int)lineHeight
{
    if (_lineHeight == lineHeight)
    {
        return;
    }
    
    _lineHeight = lineHeight;
    [self setNeedsDisplay];
}


#pragma mark - Private Methods

- (void)setup
{
    _lineHeight = 12;
    self.minimumFontSize = 12;
    _verticalAlignment = MSLabelVerticalAlignmentMiddle;
}

- (NSArray *)stringsFromText:(NSString *)string
{
    NSMutableArray *characterArray = [self arrayOfCharactersInString:string];
    NSMutableArray *slicedString = [NSMutableArray array];
    
    while (characterArray.count != 0)
    {
        NSString *line = @"";
        NSMutableIndexSet *charsToRemove = [NSMutableIndexSet indexSet];
        
        for (int i = 0; i < [characterArray count]; i++)
        {
            NSString *character = [characterArray objectAtIndex:i];
            CGFloat stringWidth = [[line stringByAppendingFormat:@"%@", character] sizeWithFont:self.font].width;
            
            // shrink font to fit text as best as we can
            if(stringWidth > (self.frame.size.width - 10))
            {
                CGFloat fontSize = self.font.pointSize;
                
                while(stringWidth > (self.frame.size.width - 10) && fontSize >= self.minimumFontSize)
                {
                    self.font = [UIFont fontWithName:self.font.fontName size:fontSize--];
                    _lineHeight = self.font.pointSize;
                    stringWidth = [[line stringByAppendingFormat:@"%@", character] sizeWithFont:self.font].width;
                }
            }
            
            if (stringWidth <= (self.frame.size.width - 10))
            {
                line = [line stringByAppendingFormat:@"%@", character];
                [charsToRemove addIndex:i];
            }
            else
            {
                if (line.length == 0)
                {
                    line = [line stringByAppendingFormat:@"%@", character];
                    [charsToRemove addIndex:i];
                }
                
                break;
            }
        }
        
        [slicedString addObject:line];
        [characterArray removeObjectsAtIndexes:charsToRemove];
    }
    
    slicedString = [self stringsWithWordsWrappedFromArray:slicedString];
    
    return slicedString;
}

- (NSMutableArray *)stringsWithWordsWrappedFromArray:(NSArray *)strings
{
    NSMutableArray *newStrings = [NSMutableArray arrayWithArray:strings];
    
    for (int i = 0; i < strings.count; i++)
    {
        if(i != 0)
        {
            NSString *lastWord = [self lastWordInString:[strings objectAtIndex:i - 1]];
            
            // Fix word wrapping
            if(lastWord.length > 0)
            {
                NSString *lastString = [newStrings objectAtIndex:i - 1];
                NSString *updatedString = [lastString substringToIndex:lastString.length - (lastWord.length + 1)];
                [newStrings replaceObjectAtIndex:i-1 withObject:updatedString];
                
                NSString *currentString = [newStrings objectAtIndex:i];
                
                currentString = [NSString stringWithFormat:@"%@%@",lastWord,currentString];
                
                [newStrings replaceObjectAtIndex:i withObject:currentString];
            }
        }
        
    }
    
    if (newStrings.count > self.numberOfLines && self.numberOfLines != 0)
    {
        NSString *line = [newStrings objectAtIndex:(self.numberOfLines - 1)];
        line = [line stringByReplacingCharactersInRange:NSMakeRange(line.length - 3, 3) withString:@"..."];
        [newStrings removeObjectAtIndex:(self.numberOfLines - 1)];
        [newStrings insertObject:line atIndex:(self.numberOfLines - 1)];
    }
    
    return newStrings;
}

- (NSString *)lastWordInString:(NSString *)string
{
    NSString *lastWord;
    
    // Check for whole words
    NSArray *wordArray = [string componentsSeparatedByString:@" "];
    
    if(wordArray.count > 1)
    {
        lastWord = [wordArray lastObject];
    }
    else
    {
        lastWord = @"";
    }
    
    return lastWord;
}

- (NSMutableArray *)arrayOfCharactersInString:(NSString *)string
{
    NSRange theRange = {0, 1};
    
    NSMutableArray *stringsArray  = [NSMutableArray array];
    
    for ( NSInteger i = 0; i < [string length]; i++)
    {
        theRange.location = i;
        [stringsArray addObject:[string substringWithRange:theRange]];
    }
    
    return stringsArray;
}

@end
