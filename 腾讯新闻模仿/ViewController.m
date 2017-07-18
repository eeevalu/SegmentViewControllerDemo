//
//  ViewController.m
//  腾讯新闻模仿
//
//  Created by Eva on 2017/7/7.
//  Copyright © 2017年 shanghaiWOW. All rights reserved.
//

#import "ViewController.h"
#import "TabViewController.h"
#import "Masonry.h"

#define WIDTH   [UIScreen mainScreen].bounds.size.width
#define HEIGHT   [UIScreen mainScreen].bounds.size.height
#define randomColor [UIColor colorWithRed:arc4random_uniform(255)/255.0 green:arc4random_uniform(255)/255.0 blue:arc4random_uniform(255)/255.0 alpha:1]

@interface ViewController ()<UIScrollViewDelegate>
{
    //标识当前页数
    NSInteger _curPage;
    NSInteger _selectPage;
    //记录停下时的offset
    CGFloat contentOffsetX;
}

@property (nonatomic, strong)UIScrollView *topScroll;   //顶部滚动视图

@property (nonatomic, strong)UIView * indicatorView;    //遮罩

@property (weak, nonatomic) IBOutlet UIScrollView *mainScrollView;
@property (nonatomic, strong) NSMutableArray *tagArray;
@property (nonatomic, strong) NSMutableArray *vcArray;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initTopScroll];
    [self initBottomController];
}


//布局顶部滚动视图
- (void)initTopScroll
{
    [self.view addSubview:self.topScroll];
    //添加顶部tag的button,并创建对应的VC存入数组
    for (NSInteger i = 0; i < self.tagArray.count; i ++) {
        [self addTagBtn:i];
        TabViewController *vc = [[TabViewController alloc] init];
        vc.index = i;
        vc.titleString = _tagArray[i];
        [self.vcArray addObject:vc];
    }
    [self.topScroll addSubview:self.indicatorView];
    
    [_indicatorView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_topScroll).offset(40);
        make.left.equalTo(_topScroll).offset(12);
        make.height.equalTo(@1);
        make.width.equalTo(@31);
    }];
    
}
- (void)initBottomController {
    self.mainScrollView.contentSize = CGSizeMake(WIDTH * self.tagArray.count, HEIGHT);
    self.mainScrollView.pagingEnabled = YES;
    self.mainScrollView.delegate = self;
    _curPage = 0;
    _selectPage = 0;
    
    //先添加第一个
    NSInteger tag = 0;
    [self addController:tag];
}


- (void)addTagBtn:(NSInteger)index {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    CGFloat strWidth = [self getWidthWithTitle:WIDTH andFont:15 andStr:_tagArray[index]];
    [btn setTitle:_tagArray[index]forState:UIControlStateNormal];
    btn.frame = CGRectMake(_topScroll.contentSize.width, 0, strWidth + 25, 50);
    btn.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Light" size:15];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_topScroll addSubview:btn];
    [btn addTarget:self action:@selector(didClickTopTag:) forControlEvents:UIControlEventTouchUpInside];
    btn.tag = 200 + index;
    btn.backgroundColor = randomColor;
    _topScroll.contentSize = CGSizeMake(CGRectGetMaxX(btn.frame) , 30);

}

- (void)didClickTopTag:(UIButton *)btn {
    [self changeToPage:btn.tag - 200];
}

- (void)changeToPage:(NSInteger)toPage {
    _selectPage = toPage;
    [self addController:toPage];
    [self configScrollOffset];
}

//添加视图
- (void)addController:(NSInteger)tag{
    TabViewController *vc = self.vcArray[tag];
    vc.view.frame = CGRectMake(WIDTH * tag, 0, WIDTH, HEIGHT);
    [self.mainScrollView setContentOffset:CGPointMake(tag *WIDTH, 0) animated:YES];
    if ([self.mainScrollView.subviews containsObject:vc.view]) {
        return;
    }else {
        vc.view.backgroundColor = randomColor;
        [self.mainScrollView addSubview:vc.view];
    }
}

//点击顶部切换滚动位置
- (void)configScrollOffset {
    self.mainScrollView.userInteractionEnabled = YES;
    CGFloat width = _topScroll.frame.size.width;
    //向右移动 后面留出下一个btn+60 的位置
    if ( _selectPage > _curPage) {
        if ( _selectPage < self.tagArray.count - 1) {
            UIButton * nextBtn = [_topScroll viewWithTag:200 + _selectPage + 1];
            CGFloat nextPoint = CGRectGetMaxX(nextBtn.frame);
            if (nextPoint - width >0) {//当在前面两页的时候可能offset会变负值
                // && (nextPoint - width > contentOffset || contentOffset - nextPoint + width > width - seleBtn.width)
                [UIView animateWithDuration:0.4 animations:^{
                    [_topScroll setContentOffset:CGPointMake(nextPoint -width, 0)];
                }];
            }
        }
        else if (_selectPage == self.tagArray.count - 1){
            [UIView animateWithDuration:0.4 animations:^{
                [_topScroll setContentOffset: CGPointMake(_topScroll.contentSize.width - width, 0)];
            }];
            
        }
    }
    //向左 前面留出上一个btn的位置
    else if ( _selectPage < _curPage) {
        if (_selectPage > 0) {
            UIButton *lastBtn = [_topScroll viewWithTag:200 + _selectPage -1];
            CGFloat lastPoint = CGRectGetMinX(lastBtn.frame);
            if (lastPoint  < _topScroll.contentSize.width - width ) {//当最后一页上翻时offset可能超过contentsize
                [UIView animateWithDuration:0.4 animations:^{
                    [_topScroll setContentOffset:CGPointMake(lastPoint , 0)];
                }];
            }
        }
        else {
            [UIView animateWithDuration:0.4 animations:^{
                [_topScroll setContentOffset:CGPointMake(0, 0)];
                
            }];
        }
    }
    
}


#pragma mark - ScrollViewDelegate
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    CGFloat offsetX = scrollView.contentOffset.x;
    NSInteger currentPag = offsetX / WIDTH;

    [self changeToPage:currentPag];
    _curPage = currentPag;
    contentOffsetX = scrollView.contentOffset.x;
}
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    NSLog(@"**********停止拖拽***********");
}
//非手动触发时的停止滚动
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView{
    NSLog(@"**********停止滚动***********");
    self.mainScrollView.userInteractionEnabled = YES;
}
//根据滚动的offset调整_indicatorView指示条的位置
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView.tag == 500) {return;}
    CGFloat contentOffset = scrollView.contentOffset.x;
    NSLog(@"当前页===%f====%td===%td,偏移量相差%f", contentOffset,_curPage,_selectPage,contentOffset - contentOffsetX);
    CGFloat width = scrollView.frame.size.width;
    NSInteger offIndex = (contentOffset - contentOffsetX)/WIDTH;
    
    if ((contentOffset - contentOffsetX) > 1.0f) {  // 向左拖拽
        //最后一页
        if (contentOffset > ( _tagArray.count - 1) * WIDTH ) {
            return;
        }
        NSLog(@"=====偏移到第%td页",offIndex);
        NSInteger currentPage = _curPage + offIndex;
        UIButton *curBtn = [_topScroll viewWithTag:200 + currentPage];
        CGFloat curBtnMinX =  CGRectGetMinX(curBtn.frame);
        UIButton *nextBtn = [_topScroll viewWithTag:200 + _curPage + offIndex + 1];
        CGFloat nextBtnMinX =  CGRectGetMinX(nextBtn.frame);
        CGFloat space = (nextBtnMinX - curBtnMinX);
        CGFloat widthSpace = (nextBtn.frame.size.width- curBtn.frame.size.width);
        CGFloat offsetXIndicator = (contentOffset - (_curPage + offIndex)* width)/width * space;
        CGFloat offsetWidth = (contentOffset - (_curPage + offIndex) * width)/width * widthSpace;
        NSLog(@"x向右的位移 === %f ",offsetXIndicator);
        
        [_indicatorView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(_topScroll.mas_left).offset(curBtnMinX + 13 + offsetXIndicator);
            make.width.equalTo(@(curBtn.frame.size.width - 25 + offsetWidth));
        }];
    }
    else if ((contentOffsetX - contentOffset) > 1.0f ) {   // 向右拖拽
        if (contentOffset < -1 ) {
            return;
        }
        NSLog(@"=====偏移到第%td页",offIndex);
        NSInteger currentPage = _curPage + offIndex;
        UIButton *curBtn = [_topScroll viewWithTag:200 + currentPage];
        CGFloat curBtnMinX =  CGRectGetMinX(curBtn.frame);
        UIButton *nextBtn = [_topScroll viewWithTag:200 +_curPage + offIndex - 1];
        CGFloat nextBtnMinX =  CGRectGetMinX(nextBtn.frame);
        CGFloat space = (curBtnMinX - nextBtnMinX);
        
        CGFloat widthSpace = (curBtn.frame.size.width- nextBtn.frame.size.width);
        CGFloat offsetXIndicator = (contentOffset - (_curPage + offIndex)* width)/width * space;
        CGFloat offsetWidth = (contentOffset - (_curPage + offIndex) * width)/width * widthSpace;
        NSLog(@"x向左的位移 === %f ",offsetXIndicator);
        
        [_indicatorView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(_topScroll.mas_left).offset(curBtnMinX+ 13 +offsetXIndicator);
            make.width.equalTo(@(curBtn.frame.size.width - 25 + offsetWidth ));
        }];
    }
    //当手指滑动速度过快就关闭手势，等停止滚动再打开手势
    if (offIndex <= -1 || offIndex >= 1) {
        self.mainScrollView.userInteractionEnabled = NO;
    }
    
}
- (NSMutableArray *)tagArray {
    if (!_tagArray) {
        _tagArray = [NSMutableArray arrayWithObjects:@"美食",@"小吃快餐",@"夜生活",@"住宿",@"购物",@"展览",@"运动",@"体验",@"餐厅",@"文娱活动"@"兴趣",@"酒吧&夜生活",@"酒店",@"景点",@"夜生活", nil];
    }
    return _tagArray;
}
- (NSMutableArray *)vcArray {
    if (!_vcArray) {
        _vcArray = [NSMutableArray array];
    }
    return _vcArray;
}

- (UIScrollView *)topScroll {
    if (!_topScroll) {
        _topScroll =  [[UIScrollView alloc]initWithFrame:CGRectMake(0, 20, self.view.frame.size.width, 44)];
        _topScroll.contentSize = CGSizeMake(0, 0);
    }
    return _topScroll;
}

- (UIView *)indicatorView {
    if (!_indicatorView) {
        _indicatorView = [[UIView alloc] init];
        _indicatorView.backgroundColor = [UIColor blackColor];
    }
    return _indicatorView;
}

- (float)getWidthWithTitle:(NSInteger)width andFont:(NSInteger)font andStr:(NSString *)str{
    CGRect rectContent = [str boundingRectWithSize:CGSizeMake(width, 10000) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:font]} context:nil];
    return rectContent.size.width;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
