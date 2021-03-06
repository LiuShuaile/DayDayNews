//
//  VideoViewController.m
//  新闻
//
//  Created by gyh on 15/9/21.
//  Copyright © 2015年 apple. All rights reserved.
//

#import "VideoViewController.h"
#import "testViewController.h"
#import "VideoCell.h"
#import "VideoData.h"
#import "VideoDataFrame.h"
#import "DetailViewController.h"
#import "TabbarButton.h"
#import "ClassViewController.h"

#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "GYHCircleLoadingView.h"
#import "CategoryView.h"
//#import "GYPlayer.h"
#import "HcdCacheVideoPlayer.h"

@interface VideoViewController ()<UITableViewDelegate,UITableViewDataSource>
@property (nonatomic , strong) NSMutableArray *             videoArray;
@property (nonatomic , weak) UITableView *                  tableview;
@property (nonatomic , assign)int                           count;
@property (nonatomic , strong) TabbarButton *               btn;

//@property (nonatomic , strong) GYPlayer     *               player;
@property (nonatomic, strong) HcdCacheVideoPlayer *playerII;
@property (nonatomic , assign) int                          currtRow;

@property (nonatomic)          CGFloat                      currentOriginY;

@property (nonatomic, strong) NSIndexPath* curIndexPath;
@property (nonatomic, assign) BOOL smallmpc;

@end

@implementation VideoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
//    self.title = @"下载列表";
    //监听夜间模式的改变
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(handleThemeChanged) name:Notice_Theme_Changed object:nil];
    //点击tabbar刷新tableview
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(mynotification) name:self.title object:nil];
    self.view.backgroundColor = RGBA(239, 239, 244, 1);
    
    ThemeManager *defaultManager = [ThemeManager sharedInstance];
    [self.navigationController.navigationBar setBackgroundImage:[defaultManager themedImageWithName:@"navigationBar"] forBarMetrics:UIBarMetricsDefault];

    [self initUI];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.playerII) {
        [self.playerII releasePlayer];
        self.playerII = nil;
    }
}

- (void)initUI
{
    UITableView *tableview = [[UITableView alloc]init];
    tableview.backgroundColor = [UIColor clearColor];
    tableview.delegate = self;
    tableview.dataSource = self;
    tableview.frame = self.view.frame;
    [self.view addSubview:tableview];
    self.tableview = tableview;
    self.tableview.tableFooterView = [[UIView alloc]init];
    
    IMP_BLOCK_SELF(VideoViewController);
    GYHHeadeRefreshController *header = [GYHHeadeRefreshController headerWithRefreshingBlock:^{
        block_self.count = 0;
        [block_self initNetWork];
    }];
    header.lastUpdatedTimeLabel.hidden = YES;
    header.stateLabel.hidden = YES;
    self.tableview.mj_header = header;
    [header beginRefreshing];
    
    self.tableview.mj_footer = [MJRefreshAutoNormalFooter footerWithRefreshingBlock:^{
        [block_self initNetWork];
    }];
    
    CategoryView *view = [[CategoryView alloc]init];
    view.SelectBlock = ^(NSString *tag, NSString *title) {
        NSArray *arr = @[@"VAP4BFE3U",
                         @"VAP4BFR16",
                         @"VAP4BG6DL",
                         @"VAP4BGTVD"];
        
        ClassViewController *classVC = [[ClassViewController alloc]init];
        classVC.url = arr[[tag intValue]];
        classVC.title = title;
        [block_self.navigationController pushViewController:classVC animated:YES];
    };
    self.tableview.tableHeaderView = view;
}

#pragma mark - tableview delegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.videoArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    VideoCell *cell = [VideoCell cellWithTableView:tableView];
    if ([[[ThemeManager sharedInstance] themeName] isEqualToString:@"高贵紫"]) {
        cell.backgroundColor = [[ThemeManager sharedInstance] themeColor];
    }else{
        cell.backgroundColor = [UIColor whiteColor];
    }
    cell.videodataframe = self.videoArray[indexPath.row];
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    VideoCell *cell = [tableView cellForRowAtIndexPath:indexPath];

    VideoDataFrame *videoframe = self.videoArray[indexPath.row];
    VideoData *videodata = videoframe.videodata;
//    self.currtRow = (int)indexPath.row;
    self.curIndexPath = indexPath;
    
    //创建播放器
    if (self.playerII) {
        [self.playerII releasePlayer];
        self.playerII = nil;
    }
    self.playerII = [[HcdCacheVideoPlayer alloc] init];
    self.playerII.cellRect = cell.frame;
    self.playerII.videodata = videodata;
    [self.playerII playWithVideoUrl:videodata.mp4_url
                           showView:[[UIView alloc] initWithFrame:videoframe.coverF]
                       andSuperView:cell.contentView];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    VideoDataFrame *videoFrame = self.videoArray[indexPath.row];
    return videoFrame.cellH;
}

//判断滚动事件，如何超出播放界面，停止播放
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (self.playerII) {
        /*
         向上👆向下👇滑动，当播放器视图消失，则清理播放器
         */
        //scrollview偏移量 由于navigattionBar的存在，scrollview默认初始化偏移量-64
        CGFloat scrollviewOffSetY = scrollView.contentOffset.y;
        //scrollview在屏幕上显示的尺寸高度
        CGFloat scrollviewShowHeight = scrollviewOffSetY + CGRectGetMaxY(scrollView.frame) - 49;
        //player最低点
        CGFloat playerMinY = CGRectGetMinY(self.playerII.cellRect);
        //player最高点
        CGFloat playerMaxY = CGRectGetMaxY(self.playerII.cellRect);
        if ((scrollviewOffSetY+64 > playerMaxY)||(scrollviewShowHeight < playerMinY)) {
            [self.playerII releasePlayer];
            self.playerII = nil;
//            if (CGRectGetWidth(self.playerII.showView.bounds) == 200) {
//                return;
//            }
//            self.smallmpc = YES;
//            self.playerII.showView.frame = CGRectMake(SCREEN_WIDTH-20-200, SCREEN_HEIGHT - 120, 200, 200*0.56);
//            [self.view addSubview:self.playerII.showView];
        } else {
//            if (CGRectGetWidth(self.playerII.showView.bounds) == SCREEN_WIDTH) {
//                return;
//            }
//            self.smallmpc = NO;
//            VideoCell *cell = [self.tableview cellForRowAtIndexPath:self.curIndexPath];
//            VideoDataFrame *videoframe = self.videoArray[self.curIndexPath.row];
//            self.playerII.showView.frame = videoframe.coverF;
//            [cell.contentView addSubview:self.playerII.showView];
        }
    }
}

#pragma mark - action

- (void)mynotification
{
    [self.tableview.mj_header beginRefreshing];
}

- (void)handleThemeChanged
{
    ThemeManager *defaultManager = [ThemeManager sharedInstance];
    self.tableview.backgroundColor = [defaultManager themeColor];
    [self.navigationController.navigationBar setBackgroundImage:[defaultManager themedImageWithName:@"navigationBar"] forBarMetrics:UIBarMetricsDefault];
    [self.tableview reloadData];
}

- (void)dealloc {
    if (self.playerII) {
        [self.playerII releasePlayer];
        self.playerII = nil;
    }
}

#pragma mark - load data
- (void)initNetWork
{
    IMP_BLOCK_SELF(VideoViewController);
    self.count = 10;
    NSString *getstr = [NSString stringWithFormat:@"http://c.m.163.com/nc/video/home/%d-10.html",self.count];
    
    [[BaseEngine shareEngine] runRequestWithPara:nil path:getstr success:^(id responseObject) {
        
        NSArray *dataarray = [VideoData mj_objectArrayWithKeyValuesArray:responseObject[@"videoList"]];
        NSMutableArray *statusFrameArray = [NSMutableArray array];
        for (VideoData *videodata in dataarray) {
            VideoDataFrame *videodataFrame = [[VideoDataFrame alloc] init];
            videodataFrame.videodata = videodata;
            [statusFrameArray addObject:videodataFrame];
        }
        
        if (block_self.count == 0) {
            block_self.videoArray = statusFrameArray;
        }else{
            [block_self.videoArray addObjectsFromArray:statusFrameArray];
        }
        
        block_self.count += 10;
        [block_self.tableview reloadData];
        [block_self.tableview.mj_header endRefreshing];
        [block_self.tableview.mj_footer endRefreshing];
        block_self.tableview.mj_footer.hidden = dataarray.count < 10;

    } failure:^(id error) {
        [block_self.tableview.mj_header endRefreshing];
        [block_self.tableview.mj_footer endRefreshing];
    }];
}

#pragma mark - lazy
- (NSMutableArray *)videoArray
{
    if (!_videoArray) {
        _videoArray = [NSMutableArray array];
    }
    return _videoArray;
}
@end
