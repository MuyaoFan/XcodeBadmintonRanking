//
//  ViewController.m
//  Badminton Ranking
//
//  Created by fanmuyao on 2022/8/21.
//

#import "ViewController.h"
#import <math.h>

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource>

@property(strong,nonatomic) NSArray *	players;
@property(nonatomic,copy) NSString* docPath;
@property(nonatomic,copy) NSString* filePath;
@property(nonatomic,strong) NSFileManager *filemanager;
@property (weak, nonatomic) IBOutlet UITableView *table;
@property(nonatomic,strong) UIView* namesView;
@property(nonatomic,strong) UIButton *playerBtnPressed;
@property(nonatomic,strong) UIView *cover;
@property(nonatomic,strong) NSArray *playersInGame;
@property (weak, nonatomic) IBOutlet UIButton *Player1;
@property (weak, nonatomic) IBOutlet UIButton *Player2;
@property (weak, nonatomic) IBOutlet UIButton *Player3;
@property (weak, nonatomic) IBOutlet UIButton *Player4;
@property (weak, nonatomic) IBOutlet UIButton *recordBtn;
@property (nonatomic,strong) UIButton *scoreBtnPressed;
@property(nonatomic,strong) UIView* scoreView;
@end

@implementation ViewController

- (void)viewDidLoad {
    //设置四个 player 按钮到 playersInGame 中去
    self.playersInGame = @[self.Player1, self.Player2, self.Player3, self.Player4];
    
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    // 判断是否存在 players.plist 文件,如果存在的话,加载排名
    self.docPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    self.filePath = [self.docPath stringByAppendingPathComponent:@"players.list"];
    //建立文件管理器
    self.filemanager = [NSFileManager defaultManager];
    if ([self.filemanager fileExistsAtPath:self.filePath]){
        //加载数据
        [self loadAndSortData];
    }
}

// UI Table View data source 协议
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _players.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    // 获得这一单元格的数据
    NSDictionary *player = self.players[indexPath.row];
    // 创建单元格
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
    cell.textLabel.text = [NSString stringWithFormat:@"%ld.  %@",indexPath.row+1,player[@"name"] ];
    NSNumber *score = player[@"score"];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"Score  %.2f",score.floatValue];
    
    return cell;
    
}

- (IBAction)addNumber:(UIButton *)sender {
    //弹出一个窗口,请求新成员的名字
    NSString *title = @"Input Your Name";
    NSString *okButtonTitle = @"OK";
    NSString *cancelButtonTitle = @"cancel";
    UIAlertController *alertName = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    
    // 创建文本框
    [alertName addTextFieldWithConfigurationHandler:^(UITextField *textField){
            textField.placeholder = @"Your Name";
            textField.secureTextEntry = NO;
        }];
          
        // 创建操作
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:okButtonTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        // 读取文本框的值显示出来
        UITextField *userName = alertName.textFields.firstObject;
        NSLog(@"%@",userName.text);
        
        // 检查文件路径是否存在需要的 player.list 文件,如果不存在的话就创建新的文件

        if ([self.filemanager fileExistsAtPath:self.filePath]){
            //文件存在,追加元素
            NSMutableArray *playersArray = [NSMutableArray arrayWithContentsOfFile:self.filePath];
            [playersArray addObject:@{@"name":userName.text,@"score":@1000.0}];
            [playersArray writeToFile:self.filePath atomically:YES];
            NSLog(@"append name");
            

        } else{
            //文件不存在,创建文件
            NSArray *playersArray = @[@{@"name":userName.text,@"score":@500.0}];
            [playersArray writeToFile:self.filePath atomically:YES];
            NSLog(@"Create file");
            
        }
        //加载数据
        
        [self loadAndSortData];
        
        
        }];
          
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:cancelButtonTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    }];
        // 添加操作（顺序就是呈现的上下顺序）
    [alertName addAction:okAction];
    [alertName addAction:cancelAction];
    [self presentViewController:alertName animated:YES completion:nil];
}

- (void)loadAndSortData{
    
    self.players = [NSArray arrayWithContentsOfFile:self.filePath];
    //对数据排序
    NSSortDescriptor *scoreDescriptor = [[NSSortDescriptor alloc] initWithKey:@"score" ascending:NO];
    NSArray *sortDescriptors = [NSArray arrayWithObject:scoreDescriptor];
    NSArray *sortedArray = [self.players sortedArrayUsingDescriptors:sortDescriptors];
    self.players = sortedArray;
    [self.table reloadData];
}

-(NSArray *) nameSortedPlayers{
    self.players = [NSArray arrayWithContentsOfFile:self.filePath];
    //对数据排序
    NSSortDescriptor *scoreDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObject:scoreDescriptor];
    NSArray *sortedArray = [self.players sortedArrayUsingDescriptors:sortDescriptors];
    return sortedArray;

}

-(IBAction)nameBtnClicked:(UIButton *)sender{
    NSLog(@"clicked name button");
    [self.playerBtnPressed setTitle:sender.titleLabel.text forState:UIControlStateNormal];
    self.playerBtnPressed.tag = 1;
    BOOL flagReadyToRecord = NO;
    for (UIButton *player in self.playersInGame) {
        if (player.tag != 1) {
            flagReadyToRecord = NO;
            break;
        }
        else{
            flagReadyToRecord = YES;
        }
    }
    if(flagReadyToRecord){
        [self.recordBtn setEnabled:flagReadyToRecord];
    }
    [self.namesView removeFromSuperview];
    [self.cover removeFromSuperview];
    return;
}
- (IBAction)recordBtnClicked:(UIButton *)sender {
    //找出需要的 player
    NSMutableArray* playerIndexArray = [NSMutableArray arrayWithObjects:@-1,@-1,@-1,@-1,nil];
    for (int i = 0; i < self.players.count; i++) {
        
        for (int j = 0;j < 4;j++)
        {
            UIButton *player_j = self.playersInGame[j];
            NSString *playername_j = player_j.titleLabel.text;
            if ([self.players[i][@"name"] isEqualToString:playername_j]){
                playerIndexArray[j]  = self.players[i];
                
            }
        }
    
    }
    
    //计算分数变化
    NSNumber *play1p = playerIndexArray[0][@"score"];
    NSNumber *play2p = playerIndexArray[1][@"score"];
    NSNumber *play3p = playerIndexArray[2][@"score"];
    NSNumber *play4p = playerIndexArray[3][@"score"];
    double team1p = play1p.doubleValue + play2p.doubleValue;
    double team2p = play3p.doubleValue + play4p.doubleValue;
    
    
    CGFloat winRateTeam1 = 1 / (1+pow(10, (team2p - team1p) / 1000));
    CGFloat winRateTeam2 = 1 - winRateTeam1;
    
    CGFloat changeTeam1 = 50 * (winRateTeam2);
    CGFloat changeTeam2 = 50 * (-winRateTeam2) * 0.7;
    
    //改变分数
    playerIndexArray[0][@"score"] = [[NSNumber alloc] initWithDouble:play1p.doubleValue + 0.5*changeTeam1];
    playerIndexArray[1][@"score"] = [[NSNumber alloc] initWithDouble:play2p.doubleValue + 0.5*changeTeam1];
    playerIndexArray[2][@"score"] = [[NSNumber alloc] initWithDouble:play3p.doubleValue + 0.5*changeTeam2];
    playerIndexArray[3][@"score"] = [[NSNumber alloc] initWithDouble:play4p.doubleValue + 0.5*changeTeam2];
    //保存到文件中
    [self.players writeToFile:self.filePath atomically:YES];
    //重新加载 tableview
    [self loadAndSortData];
    
    //设置四个按钮为默认值
    [self.Player1 setTitle:@"Set Player1" forState:UIControlStateNormal];
    [self.Player2 setTitle:@"Set Player2" forState:UIControlStateNormal];
    [self.Player3 setTitle:@"Set Player3" forState:UIControlStateNormal];
    [self.Player4 setTitle:@"Set Player4" forState:UIControlStateNormal];
    self.Player1.tag = 0;
    self.Player2.tag = 0;
    self.Player3.tag = 0;
    self.Player4.tag = 0;
    [self.recordBtn setEnabled:NO];
    //创建一个新方法,用来记录对局历史
    
}

- (void)recordMatchHistoryTo:(NSString *)name withPlayers:(NSArray *)playerIndex andScore:(NSNumber *)score{
    
}

-(IBAction)coverClicked:(UIButton *)sender{
    [self.namesView removeFromSuperview];
    [self.cover removeFromSuperview];
    return;
}

- (IBAction)setPlayer:(UIButton *)sender {
    self.playerBtnPressed = sender;
    //创建一个阴影按钮
    UIButton *btnCover = [UIButton new];
    btnCover.frame = self.view.bounds;
    btnCover.backgroundColor = [UIColor blackColor];
    btnCover.alpha = 0.5;
    [self.view addSubview:btnCover];
    [btnCover addTarget:self action:@selector(coverClicked:) forControlEvents:UIControlEventTouchUpInside];
    self.cover = btnCover;
    
    //创建一个 view 用来放置姓名按钮
    UIView *namesView = [UIView new];
    namesView.frame = CGRectMake(btnCover.frame.origin.x+50, btnCover.frame.origin.y+50, btnCover.frame.size.width-100, btnCover.frame.size.height-100);
    namesView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:namesView];
    [self.view bringSubviewToFront:namesView];
    self.namesView = namesView;
    //动态创建姓名按钮
    NSArray *playersNameSorted = [self nameSortedPlayers];
    for (int i = 0;i < self.players.count;i++){
        UIButton *btnName = [UIButton buttonWithType:UIButtonTypeSystem ];
        btnName.backgroundColor = [UIColor systemGray5Color];
        [btnName setTitle:playersNameSorted[i][@"name"] forState:UIControlStateNormal];
        NSLog(@"%@",btnName.titleLabel.text);
        btnName.titleLabel.textColor = [UIColor blackColor];
        btnName.titleLabel.font = [UIFont systemFontOfSize:15.0];
        CGFloat margin = 50;
        CGFloat gap = 30;
        
        CGFloat w = (self.namesView.frame.size.width - 2 * margin - 6 * gap)/7;
        CGFloat h = w * 0.7;
        CGFloat y = margin + (i/7) * (h +gap);
        CGFloat x = margin + (i%7) * (w +gap);
        
        btnName.frame = CGRectMake(x, y, w, h);
        [self.namesView addSubview:btnName];
        
        [btnName addTarget:self action:@selector(nameBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
        
    }
    
}
- (IBAction)setScore:(UIButton *)sender {
    self.scoreBtnPressed = sender;
    //创建一个阴影按钮
    UIButton *btnCover = [UIButton new];
    btnCover.frame = self.view.bounds;
    btnCover.backgroundColor = [UIColor blackColor];
    btnCover.alpha = 0.5;
    [self.view addSubview:btnCover];
    [btnCover addTarget:self action:@selector(coverClicked:) forControlEvents:UIControlEventTouchUpInside];
    self.cover = btnCover;
    
    //创建一个 view 用来放置比分按钮
    UIView *scoreView = [UIView new];
    scoreView.frame = CGRectMake(btnCover.frame.origin.x+50, btnCover.frame.origin.y+50, btnCover.frame.size.width-100, btnCover.frame.size.height-100);
    scoreView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:scoreView];
    [self.view bringSubviewToFront:scoreView];
    self.scoreView = scoreView;
    //动态创建score按钮
    for (int i = 0;i < 30;i++){
        UIButton *btnscore = [UIButton buttonWithType:UIButtonTypeSystem ];
        btnscore.backgroundColor = [UIColor systemGray5Color];
        [btnscore setTitle:[NSString stringWithFormat:@"%d",i+1] forState:UIControlStateNormal];
        btnscore.titleLabel.textColor = [UIColor blackColor];
        btnscore.titleLabel.font = [UIFont systemFontOfSize:25.0];
        btnscore.tag = i+1;
        CGFloat margin = 50;
        CGFloat gap = 30;
        
        CGFloat w = (self.scoreView.frame.size.width - 2 * margin - 6 * gap)/7;
        CGFloat h = w * 0.7;
        CGFloat y = margin + (i/7) * (h +gap);
        CGFloat x = margin + (i%7) * (w +gap);
        
        btnscore.frame = CGRectMake(x, y, w, h);
        [self.scoreView addSubview:btnscore];
        
        [btnscore addTarget:self action:@selector(scoreBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
        
    }
}
- (IBAction)scoreBtnClicked:(UIButton *)sender{
    [self.scoreBtnPressed setTitle:[NSString stringWithFormat:@"%ld",sender.tag] forState:UIControlStateNormal];
    [self.scoreView removeFromSuperview];
    [self.cover removeFromSuperview];
    return;
}


@end
