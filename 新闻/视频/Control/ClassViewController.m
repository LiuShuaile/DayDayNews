//
//  ClassViewController.m
//  新闻
//
//  Created by gyh on 15/9/29.
//  Copyright © 2015年 apple. All rights reserved.
//


#import "ClassViewController.h"
#import "VideoCell.h"
#import "VideoData.h"
#import "VideoDataFrame.h"
#import "DetailViewController.h"

#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "GYHCircleLoadingView.h"
#import <Masonry/Masonry.h>

@interface ClassViewController ()<UITableViewDelegate,UITableViewDataSource>
@property (nonatomic , strong) NSMutableArray *videoArray;
@property (nonatomic , weak) UITableView *tableview;
@property (nonatomic , assign)int count;

@property (nonatomic, strong) MPMoviePlayerController *mpc;
//@property (nonatomic, strong) MPMoviePlayerController *hpmpc;
@property (nonatomic , strong) UIView *cbfxView;
@property (nonatomic , strong) UIView *controlView;
@property (nonatomic , assign) int currtRow;

@property (nonatomic, assign) CGRect curCellRect;

@property (nonatomic , assign) BOOL smallmpc;
@property (nonatomic , strong) GYHCircleLoadingView *circleLoadingV;

@property (nonatomic, strong) UIButton *btnDownload;

@end

@implementation ClassViewController

- (UIButton *)btnDownload {
    if (!_btnDownload) {
        _btnDownload = [UIButton buttonWithType:1];
        [_btnDownload setTitle:@"下载" forState:0];
        [_btnDownload setTitleColor:[UIColor whiteColor] forState:0];
        _btnDownload.titleLabel.font = [UIFont systemFontOfSize:13];
        [_btnDownload addTarget:self action:@selector(clickDownload) forControlEvents:UIControlEventTouchUpInside];
    }
    return _btnDownload;
}

-(NSMutableArray *)videoArray
{
    if (!_videoArray) {
        _videoArray = [NSMutableArray array];
    }
    return _videoArray;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor colorWithRed:239/255.0f green:239/255.0f blue:244/255.0f alpha:1];
    [self initUI];
    
    //监听屏幕改变
    UIDevice *device = [UIDevice currentDevice]; //Get the device object
    [device beginGeneratingDeviceOrientationNotifications]; //Tell it to start monitoring the accelerometer for orientation
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter]; //Get the notification centre for the app
    [nc addObserver:self selector:@selector(orientationChanged:) name:UIDeviceOrientationDidChangeNotification  object:device];

}

-(void)initUI
{
    UITableView *tableview = [[UITableView alloc]init];
    tableview.backgroundColor = [UIColor clearColor];
    tableview.delegate = self;
    tableview.dataSource = self;
    tableview.frame = self.view.frame;
    [self.view addSubview:tableview];
    self.tableview = tableview;
    self.tableview.tableFooterView = [[UIView alloc]init];
    
    IMP_BLOCK_SELF(ClassViewController);
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
}

- (void)initNetWork
{
    IMP_BLOCK_SELF(ClassViewController);
    NSString *getstr = [NSString stringWithFormat:@"http://c.3g.163.com/nc/video/list/%@/y/%d-10.html",_url,self.count];

    [[BaseEngine shareEngine] runRequestWithPara:nil path:getstr success:^(id responseObject) {
        NSArray *dataarray = [VideoData mj_objectArrayWithKeyValuesArray:responseObject[_url]];
        // 创建frame模型对象
        NSMutableArray *statusFrameArray = [NSMutableArray array];
        for (VideoData *videodata in dataarray) {
            VideoDataFrame *videodataFrame = [[VideoDataFrame alloc] init];
            videodataFrame.videodata = videodata;
            [statusFrameArray addObject:videodataFrame];
        }
        
        if (block_self.videoArray.count == 0) {
            block_self.videoArray = statusFrameArray;
        }else{
            [block_self.videoArray addObjectsFromArray:statusFrameArray];
        }
        
        block_self.count += 10;
        [block_self.tableview reloadData];
        [block_self.tableview.mj_header endRefreshing];
        [block_self.tableview.mj_footer endRefreshing];
        block_self.tableview.mj_footer.hidden = block_self.videoArray.count < 10;
    } failure:^(id error) {
        [block_self.tableview.mj_header endRefreshing];
        [block_self.tableview.mj_header endRefreshing];
    }];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.videoArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    VideoCell *cell = [VideoCell cellWithTableView:tableView];
    cell.videodataframe = self.videoArray[indexPath.row];
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    VideoCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    self.curCellRect = cell.frame;
    
    VideoDataFrame *videoframe = self.videoArray[indexPath.row];
    VideoData *videodata = videoframe.videodata;

    if (self.mpc) {
        [self.mpc.view removeFromSuperview];
    }
    self.currtRow = (int)indexPath.row;
    // 创建播放器对象
    self.mpc = [[MPMoviePlayerController alloc] init];
    
    //检查本地播放地址
    NSString *palyPath = [[AVCacheManager sharedInstance] isExistLocalFile:videodata.mp4_url];
    NSURL *playURL = [NSURL URLWithString:palyPath];
    if (![palyPath hasPrefix:@"http"]) {
        playURL = [NSURL fileURLWithPath:palyPath];
        //
        [self clickDownload];
    }
    
    NSLog(@"%@",playURL);
    self.mpc.contentURL = playURL;
    // 添加播放器界面到控制器的view上面
    self.mpc.view.frame = CGRectMake(0, videoframe.cellH*indexPath.row+videoframe.coverF.origin.y, SCREEN_WIDTH, videoframe.coverF.size.height);
    //设置加载指示器
    [self setupLoadingView];
   
    [self.tableview addSubview:self.mpc.view];
    
    // 隐藏自动自带的控制面板
    self.mpc.controlStyle = 0;
    
    [self.mpc.view addSubview:self.btnDownload];
    [self.btnDownload mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(0);
        make.right.mas_equalTo(0);
        make.width.mas_equalTo(33);
        make.height.mas_equalTo(33);
    }];
    
    // 监听播放器
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(movieDidFinish) name:MPMoviePlayerPlaybackDidFinishNotification object:self.mpc];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(movieStateDidChange) name:MPMoviePlayerPlaybackStateDidChangeNotification object:self.mpc];
    
    [self.mpc play];
    
}

#pragma mark- methods
- (void)clickDownload {
    VideoDataFrame *videoframe = self.videoArray[self.currtRow];
    VideoData *videodata = videoframe.videodata;
    [AVDownloadManager sharedInstance].videodata = videodata;
    [[AVDownloadManager sharedInstance] download:videodata.mp4_url progress:nil state:nil];
}

#pragma mark - 设置加载指示器
- (void)setupLoadingView
{
    self.circleLoadingV = [[GYHCircleLoadingView alloc]initWithViewFrame:CGRectMake(self.mpc.view.frame.size.width/2-20, self.mpc.view.frame.size.height/2-20, 40, 40)];
    self.circleLoadingV.isShowProgress = YES;   //设置中间label进度条
    [self.mpc.view addSubview:self.circleLoadingV];
    [self.circleLoadingV startAnimating];
}



- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    VideoDataFrame *videoFrame = self.videoArray[indexPath.row];
    return videoFrame.cellH;
}



#pragma mark - 监听播放完毕
- (void)movieDidFinish
{
    DLog(@"----播放完毕");
    if (self.mpc) {
        [self.mpc.view removeFromSuperview];
        self.mpc = nil;
    }
}

#pragma mark - 监听播放状态
- (void)movieStateDidChange
{
    DLog(@"----播放状态--%ld", (long)self.mpc.playbackState);
    if (self.mpc.playbackState == 1) {
        [self.circleLoadingV stopAnimating];
    }
    
}


#pragma mark - 屏幕改变
- (void)orientationChanged:(NSNotification *)note  {
    
    UIDeviceOrientation o = [[UIDevice currentDevice] orientation];
    switch (o) {
        case UIDeviceOrientationPortrait:            // 屏幕变正
            DLog(@"屏幕变正");
            [self up];
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            break;
        case UIDeviceOrientationLandscapeLeft:       //屏幕左转
            DLog(@"屏幕变左");
            [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationLandscapeRight animated:YES];
            [self left];
            
            break;
        case UIDeviceOrientationLandscapeRight:   //屏幕右转
            DLog(@"屏幕变右");
            [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationLandscapeLeft animated:YES];
            
            
            break;
        default:
            break;
    }
}

- (void)up
{
    if(self.mpc){
        
        if (self.smallmpc) {
        }else{
            [[UIApplication sharedApplication] setStatusBarHidden:NO];
            [UIView animateKeyframesWithDuration:0.3 delay:0 options:UIViewKeyframeAnimationOptionAllowUserInteraction animations:^{
                
                VideoDataFrame *videoframe = self.videoArray[self.currtRow];
                self.mpc.view.transform = CGAffineTransformIdentity;
                self.mpc.view.frame = CGRectMake(0, videoframe.cellH*self.currtRow+videoframe.coverF.origin.y, SCREEN_WIDTH, videoframe.coverF.size.height);
                [self.tableview addSubview:self.mpc.view];
            } completion:^(BOOL finished) {
                
            }];
        }
    
    }
    
}

- (void)left
{
        if (self.mpc) {
            
            if (self.smallmpc) {
            }else{
                [[UIApplication sharedApplication] setStatusBarHidden:YES];
                [UIView animateKeyframesWithDuration:0.3 delay:0 options:UIViewKeyframeAnimationOptionAllowUserInteraction animations:^{
                    
                    self.mpc.view.transform = CGAffineTransformMakeRotation(M_PI / 2);
                    
                    self.mpc.view.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);

                    [theWindow addSubview:self.mpc.view];
                    
                } completion:^(BOOL finished) {
                    
                }];
            }
        }

   
}
#pragma mark - 判断滚动事件，如何超出播放界面，停止播放
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (self.mpc) {

        //scrollview偏移量 由于navigattionBar的存在，scrollview默认初始化偏移量-64
        CGFloat scrollviewOffSetY = scrollView.contentOffset.y;
        //scrollview在屏幕上显示的尺寸高度
        CGFloat scrollviewShowHeight = scrollviewOffSetY + CGRectGetMaxY(scrollView.frame);
        //player最低点
        CGFloat playerMinY = CGRectGetMinY(self.curCellRect);
        //player最高点
        CGFloat playerMaxY = CGRectGetMaxY(self.curCellRect);
        if ((scrollviewOffSetY+64 > playerMaxY)||(scrollviewShowHeight < playerMinY)) {
            //检测到视图已经发生位置变换，则拒绝更新
            if (CGRectGetWidth(self.mpc.view.bounds) == 200) {
                return;
            }
            self.btnDownload.hidden = YES;
            [self setupSmallmpc];
        } else {
            //检测到视图已经发生位置变换，则拒绝更新
            if (CGRectGetWidth(self.mpc.view.bounds) == SCREEN_WIDTH) {
                return;
            }
            self.smallmpc = NO;
            self.btnDownload.hidden = NO;
            VideoDataFrame *videoframe = self.videoArray[self.currtRow];
//            self.mpc.view.transform = CGAffineTransformIdentity;
            self.mpc.view.frame = CGRectMake(0, videoframe.cellH*self.currtRow+videoframe.coverF.origin.y, SCREEN_WIDTH, videoframe.coverF.size.height);
            [self.tableview addSubview:self.mpc.view];
        }

    }
}

- (void)setupSmallmpc
{
    self.smallmpc = YES;
    self.mpc.view.frame = CGRectMake(SCREEN_WIDTH-20-200, SCREEN_HEIGHT - 120, 200, 200*0.56);
    [self.view addSubview:self.mpc.view];
}



- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (self.mpc) {
        DLog(@"销毁了");
        [self.mpc stop];
        [self.mpc.view removeFromSuperview];
        self.mpc = nil;
    }
    self.tableview.delegate = nil;
}

@end
