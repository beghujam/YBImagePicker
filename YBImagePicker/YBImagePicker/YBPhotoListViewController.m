//
//  YBPhotoListViewController.m
//  YBImagePicker
//
//  Created by 杨彬 on 15/5/15.
//  Copyright (c) 2015年 macbook air. All rights reserved.
//

#import "YBPhotoListViewController.h"

#import <AssetsLibrary/AssetsLibrary.h>

#import "YBPhotoModel.h"

#import "YBPhotoThumbanilCell.h"
#import "YBSeletedPotoNumberLabel.h"

#import "YBPhotoThumbnailLayout.h"

#import "YBOriginalPhotoVC.h"

#import "YBPhotePickerManager.h"

@interface YBPhotoListViewController ()<UICollectionViewDataSource,UICollectionViewDelegate,UIAlertViewDelegate,YBPhotoThumbanilCellDelegate,YBOriginalPhotoVCDelegate>


@property (weak, nonatomic) IBOutlet UICollectionView *photo_collectionView;

@property (strong, nonatomic) ALAssetsLibrary *libray;

@property (strong, nonatomic) NSMutableArray * photo_model_array;

@property (strong, nonatomic) YBPhotoThumbnailLayout *layout;

@property (assign, nonatomic) BOOL isScrollToBottom;


@property (weak, nonatomic) IBOutlet UIButton *done_button;

@property (weak, nonatomic) IBOutlet YBSeletedPotoNumberLabel *selectedPhotoNumber_label;

@property (weak, nonatomic) IBOutlet UIButton *preview_buttom;

@end

@implementation YBPhotoListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self prepareData];
    
    [self uiConfig];

}


-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self changeSelectedState];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    if (!self.isScrollToBottom){
        [self.photo_collectionView reloadData];
    }
}

- (void)prepareData{
    
    self.isScrollToBottom = NO;
}

- (void)changeSelectedState{
    NSInteger selected_photo_count = [YBPhotePickerManager sharedYBPhotePickerManager].selected_photo_count;
    self.selectedPhotoNumber_label.text = [NSString stringWithFormat:@"%ld",selected_photo_count];
    
    if (selected_photo_count == 0){
        self.done_button.enabled = NO;
        self.preview_buttom.enabled = NO;
    }else{
        self.done_button.enabled = YES;
        self.preview_buttom.enabled = YES;
    }
    
}


- (void)uiConfig{
    
    self.title = @"相册";
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(cancel)];
    
    YBPhotoThumbnailLayout *layout = [[YBPhotoThumbnailLayout alloc]init];
    
    CGFloat item_width = ([UIScreen mainScreen].bounds.size.width - 25)/4.0;
    
    layout.itemSize = CGSizeMake(item_width , item_width);
    layout.section_Spacing = 5;
    layout.row_Spacing = 5;
    self.photo_collectionView.collectionViewLayout = layout;
    
    self.layout = layout;
    
    [self.photo_collectionView registerNib:[UINib nibWithNibName:@"YBPhotoThumbanilCell" bundle:nil] forCellWithReuseIdentifier:@"YBPhotoThumbanilCell"];
}

- (void)cancel{
    if ([self.delegate respondsToSelector:@selector(didCancelwithYBPhotoListViewController:)]){
        [self.delegate didCancelwithYBPhotoListViewController:self];
    }
}


- (IBAction)doneAction:(id)sender {
     [[NSNotificationCenter defaultCenter] postNotificationName:GetSelectedPhotoArray object:nil];
}

- (IBAction)previewAction:(id)sender {
    YBOriginalPhotoVC *originalPhotoVC = [[YBOriginalPhotoVC alloc]initWithNibName:@"YBOriginalPhotoVC" bundle:nil];
    NSMutableArray *photo_model_array = [[NSMutableArray alloc]initWithArray:[YBPhotePickerManager sharedYBPhotePickerManager].photo_array];
    [photo_model_array sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        YBPhotoModel *model1 = (YBPhotoModel *)obj1;
        YBPhotoModel *model2 = (YBPhotoModel *)obj2;
        
        return model1.indexPath.row > model2.indexPath.row;
    }];
    
    originalPhotoVC.photo_model_array = photo_model_array;
    originalPhotoVC.selected_indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    originalPhotoVC.delegate = self;
    [self.navigationController pushViewController:originalPhotoVC animated:YES];
}



#pragma mark - UICollectionViewDataSource

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    YBPhotoThumbanilCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"YBPhotoThumbanilCell" forIndexPath:indexPath];
    YBPhotoModel *photo_model = self.photo_model_array[indexPath.row];
    photo_model.indexPath = indexPath;
    cell.photo_model = photo_model;
    cell.delegate = self;
    if (!self.isScrollToBottom){
        [self.photo_collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:self.photo_model_array.count - 1 inSection:0] atScrollPosition:UICollectionViewScrollPositionBottom animated:NO];
        self.isScrollToBottom = YES;
    }
    
    return cell;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return self.photo_model_array.count;
}




#pragma mark - UICollectionViewDelegate

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    YBOriginalPhotoVC *originalPhotoVC = [[YBOriginalPhotoVC alloc]initWithNibName:@"YBOriginalPhotoVC" bundle:nil];
    originalPhotoVC.photo_model_array = self.photo_model_array;
    originalPhotoVC.selected_indexPath = indexPath;
    originalPhotoVC.delegate = self;
    [self.navigationController pushViewController:originalPhotoVC animated:YES];
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex != alertView.cancelButtonIndex){
        NSURL *settingsURL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        [[UIApplication sharedApplication] openURL:settingsURL];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - YBPhotoThumbanilCellDelegate

- (void)YBPhotoThumbanilCell:(YBPhotoThumbanilCell *)thumbanilCell didClickSelectedViewWithSelectedState:(BOOL)selected WithPhotoModel:(YBPhotoModel *)photoModel{
    NSLog(@"%@ 第%ld张", selected ?@"选中" :@"取消",photoModel.indexPath.row);
    [self changeSelectedState];
    
}



-(NSMutableArray *)photo_model_array{
    if (_photo_model_array == nil){
        _photo_model_array = [[NSMutableArray alloc]init];
        
        self.libray = [[ALAssetsLibrary alloc] init];
        
        
        [self.libray enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
            
            if (stop){
                NSLog(@"STOP");
            }else{
                NSLog(@"CONTINUE");
            }
            
            if (group != nil) {
                
                //设置过滤对象
                ALAssetsFilter *filter = [ALAssetsFilter allPhotos];
                [group setAssetsFilter:filter];
                
                //通过文件夹枚举遍历所有的相片ALAsset对象，有多少照片，则调用多少次block
                [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                    if (result != nil) {
                        //将result对象存储到数组中
                        YBPhotoModel *photo_model = [[YBPhotoModel alloc]init];
                        photo_model.url = result.defaultRepresentation.url;
                        photo_model.isSelected = NO;
                        [_photo_model_array addObject:photo_model];
                    }
                }];
                [self.photo_collectionView reloadData];
                
            }
        } failureBlock:^(NSError *error) {
            UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"提示",nil) message:NSLocalizedString(@"请允许访问相册,方可使用此功能!\n您可以在\"设置->隐私->照片\"中启用",nil) delegate:self cancelButtonTitle:NSLocalizedString(@"取消",nil) otherButtonTitles:NSLocalizedString(@"设置",nil), nil];
            [alertView show];
        }];
        
        
    }
    
    
    return _photo_model_array;
}

#pragma mark - YBOriginalPhotoVCDelegate


-(void)YBOriginalPhotoVC:(YBOriginalPhotoVC *)originalPhotoVC changePhotoSelectedStatewithIndexx:(int)index{
    [self changeSelectedState];
    
    [self.photo_collectionView reloadData];
    
}



@end
