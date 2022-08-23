//
//  ViewController.m
//  Badminton Ranking
//
//  Created by fanmuyao on 2022/8/21.
//

#import "ViewController.h"
#import <math.h>
#import "LineChartViewController.h"
#import "Badminton Ranking-Bridging-Header.h"

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
@property (weak, nonatomic) IBOutlet UIButton *winnerScoreBtn;
@property (weak, nonatomic) IBOutlet UIButton *loserScoreBtn;
@property (weak, nonatomic) IBOutlet UIStackView *stackViewForHistory;

@property (nonatomic,strong)LineChartView *lineChart;




@end

@implementation ViewController

- (void)viewDidLoad {
    //设置四个 player 按钮到 playersInGame 中去
    self.playersInGame = @[self.Player1, self.Player2, self.Player3, self.Player4];
    
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    // 判断是否存在 players.plist 文件,如果存在的话,加载排名
    self.docPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    self.filePath = [self.docPath stringByAppendingPathComponent:@"players.plist"];
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
    [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    // 设置段位图片
    int rankLevel = score.intValue/100 -10;
    NSString *rankLevelString;
    if(rankLevel == 0){
        rankLevelString = @"";
    }else{
        rankLevelString = [NSString stringWithFormat: @"%d",rankLevel-1];
    }
    cell.imageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"guild_match_rank%@",rankLevelString]];
    
    return cell;
    
}

//代理的方法,在选中某一行时,显示历史数据分析的结果
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    //NSLog(@"%lu",[indexPath indexAtPosition:1]);
    
    NSString *historyFilePath = [self.docPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist",self.players[[indexPath indexAtPosition:1]][@"name"]]];
    NSArray *historyRecord = [NSArray arrayWithContentsOfFile:historyFilePath];
    //NSLog(@"history record %@",[NSString stringWithFormat:@"%@.plist",self.players[[indexPath indexAtPosition:1]][@"name"]]);
    
    NSNumber *winRate = [NSNumber numberWithDouble:0.0];
    NSNumber *winGames = [NSNumber numberWithInt:0];
    NSNumber *totalScore = [NSNumber numberWithInt:0];
    NSNumber *totalOpntScore = [NSNumber numberWithInt:0];
    NSNumber *averageScore = [NSNumber numberWithInt:0];
    NSNumber *averageOpntScore = [NSNumber numberWithInt:0];
    
    NSMutableArray *partnerWin = [NSMutableArray arrayWithCapacity:self.players.count];
    NSMutableArray *opntStrong = [NSMutableArray arrayWithCapacity:self.players.count];
    NSMutableArray *opntWeak = [NSMutableArray arrayWithCapacity:self.players.count];
    for (int i=0 ;i < self.players.count;i++){
        //NSLog(@"add one number");
        [partnerWin addObject:[NSNumber numberWithInt:0]];
        [opntStrong addObject:[NSNumber numberWithInt:0]];
        [opntWeak addObject:[NSNumber numberWithInt:0]];
        
        //NSLog(@"%@",partnerWin[i]);
        
    }
    // 遍历记录计算数据
    for (NSDictionary *dict in historyRecord){
        //清空之前的显示
        NSArray *subviewsOld = [self.stackViewForHistory subviews];
        for (UIView * subview in subviewsOld){
            [self.stackViewForHistory removeArrangedSubview:subview];
            [subview removeFromSuperview];
        }
        
        
        
        //记录得分和失分
        //NSLog(@"dict = %@",dict);
        
        NSNumber *scoreget = dict[@"score"];
        totalScore = [NSNumber numberWithInt:scoreget.intValue + totalScore.intValue];
        NSNumber *scorelost = dict[@"opntScore"];
        totalOpntScore = [NSNumber numberWithInt:scorelost.intValue + totalOpntScore.intValue];
        NSNumber *isWinner = dict[@"isWinner"];
        if (isWinner.boolValue){
            
            winGames =[NSNumber numberWithInt:1+winGames.intValue];
            NSString *pw = dict[@"partnerName"];
            NSString *weakopnt1 = dict[@"opnt1Name"];
            NSString *weakopnt2 = dict[@"opnt2Name"];
            for(int i = 0; i < self.players.count;i++){
                if ([self.players[i][@"name"] isEqual:pw]){
                    NSNumber *goodPartner = partnerWin[i];
                    partnerWin[i] = [NSNumber numberWithInt:1+goodPartner.intValue];
                }
                if ([self.players[i][@"name"] isEqual:weakopnt1]){
                    NSNumber *weakPartner = opntWeak[i];
                    opntWeak[i] = [NSNumber numberWithInt:1+weakPartner.intValue];
                }
                if ([self.players[i][@"name"] isEqual:weakopnt2]){
                    NSNumber *weakPartner = opntWeak[i];
                    opntWeak[i] = [NSNumber numberWithInt:1+weakPartner.intValue];
                }
                
            }
        }
        else{
            
            NSString *strongopnt1 = dict[@"opnt1Name"];
            NSString *strongopnt2 = dict[@"opnt2Name"];
            for(int i = 0; i < self.players.count;i++){
                if ([self.players[i][@"name"] isEqual:strongopnt1]){
                    NSNumber *weakPartner = opntStrong[i];
                    opntStrong[i] = [NSNumber numberWithInt:1+weakPartner.intValue];
                }
                if ([self.players[i][@"name"] isEqual:strongopnt2]){
                    NSNumber *weakPartner = opntStrong[i];
                    opntStrong[i] = [NSNumber numberWithInt:1+weakPartner.intValue];
                }
                
            }
            
        }
    }
    
    NSLog(@"partner%@",partnerWin);
    NSLog(@"os%@",opntStrong);
    NSLog(@"ow%@",opntWeak);
    
    averageScore = [NSNumber numberWithDouble: totalScore.doubleValue / historyRecord.count];
    averageOpntScore = [NSNumber numberWithDouble: totalOpntScore.doubleValue / historyRecord.count];
    winRate = [NSNumber numberWithDouble: winGames.doubleValue / historyRecord.count];
    
    UIFont *labelFont = [UIFont fontWithName:@"PingFang TC" size:25];
    UIColor *labelColor = [UIColor systemMintColor];
    self.stackViewForHistory.layoutMargins = UIEdgeInsetsMake(30, 30, 30, 30);
    self.stackViewForHistory.layoutMarginsRelativeArrangement = YES;
    
    //展示胜率
    UILabel *label1 = [[UILabel alloc] init];
    [label1 setText:[NSString stringWithFormat:@"Your win rate is %.2f%%",winRate.doubleValue*100]];
    [label1 setFont:labelFont];
    [label1 setTextColor:labelColor];
    [label1 setAdjustsFontSizeToFitWidth:YES];
    [label1 setFrame:self.stackViewForHistory.bounds];
    [self.stackViewForHistory addArrangedSubview:label1];
    
    //展示每局平均得分
    UILabel *label2 = [[UILabel alloc] init];
    [label2 setText:[NSString stringWithFormat:@"Your average score per game is %.1f",averageScore.doubleValue]];
    [label2 setFont:labelFont];
    [label2 setTextColor:labelColor];
    [label2 setAdjustsFontSizeToFitWidth:YES];
    [label2 setFrame:self.stackViewForHistory.bounds];
    [self.stackViewForHistory addArrangedSubview:label2];
    
    //展示每局平均失分
    UILabel *label3 = [[UILabel alloc] init];
    [label3 setText:[NSString stringWithFormat:@"Your average lost score per game is %.1f",averageOpntScore.doubleValue]];
    [label3 setFont:labelFont];
    [label3 setTextColor:labelColor];
    [label3 setAdjustsFontSizeToFitWidth:YES];
    [label3 setFrame:self.stackViewForHistory.bounds];
    [self.stackViewForHistory addArrangedSubview:label3];

    
    
    
    //展示最佳队友(胜场最多)
    
    int maxNumber = 0;
    int maxNumberIndex = 0;
    for(int i = 0; i < partnerWin.count;i++){
        NSNumber *numberNow = partnerWin[i];
        if(numberNow.intValue > maxNumber){
            maxNumber = numberNow.intValue;
            maxNumberIndex = i;
        }
    }
    if(maxNumber){
        UILabel *label4 = [[UILabel alloc] init];
        [label4 setText:[NSString stringWithFormat:@"Your best partner is %@, you have won %d games together.",self.players[maxNumberIndex][@"name"],maxNumber]];
        [label4 setFont:labelFont];
        [label4 setTextColor:labelColor];
        [label4 setAdjustsFontSizeToFitWidth:YES];
        [label4 setFrame:self.stackViewForHistory.bounds];
        [self.stackViewForHistory addArrangedSubview:label4];
    }
    
    //展示最强对手(负场最多)
    
    maxNumber = 0;
    maxNumberIndex = 0;
    for(int i = 0; i < opntStrong.count;i++){
        NSNumber *numberNow = opntStrong[i];
        if(numberNow.intValue > maxNumber){
            maxNumber = numberNow.intValue;
            maxNumberIndex = i;
        }
    }
    if(maxNumber){
        UILabel *label5 = [[UILabel alloc] init];
        [label5 setText:[NSString stringWithFormat:@"Your biggest enemy is %@, you have lost %d games against him/her.",self.players[maxNumberIndex][@"name"],maxNumber]];
        [label5 setFont:labelFont];
        [label5 setTextColor:labelColor];
        [label5 setAdjustsFontSizeToFitWidth:YES];
        [label5 setFrame:self.stackViewForHistory.bounds];
        [self.stackViewForHistory addArrangedSubview:label5];
    }
    
    //展示最常击败的对手(胜场最多)
    maxNumber = 0;
    maxNumberIndex = 0;
    for(int i = 0; i < opntWeak.count;i++){
        NSNumber *numberNow = opntWeak[i];
        if(numberNow.intValue > maxNumber){
            maxNumber = numberNow.intValue;
            maxNumberIndex = i;
        }
    }
    if(maxNumber){
        UILabel *label6 = [[UILabel alloc] init];
        [label6 setText:[NSString stringWithFormat:@"Your favorite enemy is %@, you have won %d games against him/her.",self.players[maxNumberIndex][@"name"],maxNumber]];
        [label6 setFont:labelFont];
        [label6 setTextColor:labelColor];
        [label6 setAdjustsFontSizeToFitWidth:YES];
        [label6 setFrame:self.stackViewForHistory.bounds];
        [self.stackViewForHistory addArrangedSubview:label6];
    }
    //展示图表1(十场分数变化)
    
    //展示图表2(十场得分变化)
    
    
    
}

- (IBAction)addMember:(UIButton *)sender {
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
            NSArray *playersArray = @[@{@"name":userName.text,@"score":@1000.0}];
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
    NSMutableArray* playerDictArray = [NSMutableArray arrayWithObjects:@-1,@-1,@-1,@-1,nil];
    for (int i = 0; i < self.players.count; i++) {
        
        for (int j = 0;j < 4;j++)
        {
            UIButton *player_j = self.playersInGame[j];
            NSString *playername_j = player_j.titleLabel.text;
            if ([self.players[i][@"name"] isEqualToString:playername_j]){
                playerDictArray[j]  = self.players[i];
                
            }
        }
    
    }
    
    //计算分数变化
    NSNumber *play1p = playerDictArray[0][@"score"];
    NSNumber *play2p = playerDictArray[1][@"score"];
    NSNumber *play3p = playerDictArray[2][@"score"];
    NSNumber *play4p = playerDictArray[3][@"score"];
    double team1p = play1p.doubleValue + play2p.doubleValue;
    double team2p = play3p.doubleValue + play4p.doubleValue;
    
    
    CGFloat winRateTeam1 = 1 / (1+pow(10, (team2p - team1p) / 1000));
    CGFloat winRateTeam2 = 1 - winRateTeam1;
    
    CGFloat changeTeam1 = 50 * (winRateTeam2);
    CGFloat changeTeam2 = 50 * (-winRateTeam2) * 0.7;
    
    //改变分数
    playerDictArray[0][@"score"] = [[NSNumber alloc] initWithDouble:play1p.doubleValue + 0.5*changeTeam1];
    playerDictArray[1][@"score"] = [[NSNumber alloc] initWithDouble:play2p.doubleValue + 0.5*changeTeam1];
    playerDictArray[2][@"score"] = [[NSNumber alloc] initWithDouble:MAX(play3p.doubleValue + 0.5*changeTeam2,1000)];
    playerDictArray[3][@"score"] = [[NSNumber alloc] initWithDouble:MAX(play4p.doubleValue + 0.5*changeTeam2,1000)];
    
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
    
    NSNumber *winnerScore = [NSNumber numberWithInt:[self.winnerScoreBtn.titleLabel.text intValue]];
    NSNumber *loserScore = [NSNumber numberWithInt:[self.loserScoreBtn.titleLabel.text intValue]];
    
    [self recordMatchHistoryTo:playerDictArray andWinnerScore:winnerScore andLoserScore:loserScore];
    
}

- (void)recordMatchHistoryTo:(NSArray *)playerDictArray andWinnerScore:(NSNumber *)winnerScore andLoserScore:(NSNumber *)loserScore{
    for (int i = 0; i < playerDictArray.count; i++) {
        int playerIndex = i;
        int partnerIndex = -1,opnt1Index = -1,opnt2Index = -1;
        NSNumber *score;
        NSNumber *opntScore;
        NSNumber *isWinner;
        switch (playerIndex) {
            case 0:
                partnerIndex = 1;
                opnt1Index = 2;
                opnt2Index = 3;
                score = winnerScore;
                opntScore = loserScore;
                isWinner = [NSNumber numberWithBool:YES];
                break;
            case 1:
                partnerIndex = 0;
                opnt1Index = 2;
                opnt2Index = 3;
                score = winnerScore;
                opntScore = loserScore;
                isWinner = [NSNumber numberWithBool:YES];
                break;
            case 2:
                partnerIndex = 3;
                opnt1Index = 0;
                opnt2Index = 1;
                score = loserScore;
                opntScore = winnerScore;
                isWinner = [NSNumber numberWithBool:NO];
                break;
            case 3:
                partnerIndex = 2;
                opnt1Index = 0;
                opnt2Index = 1;
                score = loserScore;
                opntScore = winnerScore;
                isWinner = [NSNumber numberWithBool:NO];
                break;
                
                
            default:
                NSLog(@"something wrong with history recording.");
                break;
        }
        
        NSString *historyFilePath = [self.docPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist",playerDictArray[playerIndex][@"name"]]];
        
        if ([self.filemanager fileExistsAtPath:historyFilePath]){
            //文件存在,追加元素
            NSMutableArray *playersArray = [NSMutableArray arrayWithContentsOfFile:historyFilePath];
            [playersArray addObject:@{@"partnerName":playerDictArray[partnerIndex][@"name"],
                                      @"opnt1Name":playerDictArray[opnt1Index][@"name"],
                                      @"opnt2Name":playerDictArray[opnt2Index][@"name"],
                                      @"score":score,
                                      @"opntScore":opntScore,
                                      @"personalScore":playerDictArray[playerIndex][@"score"],
                                      @"isWinner":isWinner,
                                                    
                                    }];
            [playersArray writeToFile:historyFilePath atomically:YES];
            NSLog(@"history of %@ recorded to %@",playerDictArray[playerIndex][@"name"],historyFilePath);
            

        } else{
            //文件不存在,创建文件
            NSArray *playersArray =@[ @{@"partnerName":playerDictArray[partnerIndex][@"name"],
                                      @"opnt1Name":playerDictArray[opnt1Index][@"name"],
                                      @"opnt2Name":playerDictArray[opnt2Index][@"name"],
                                      @"score":score,
                                      @"opntScore":opntScore,
                                      @"personalScore":playerDictArray[playerIndex][@"score"],
                                      @"isWinner":isWinner,
                                                    
                                    }];
            [playersArray writeToFile:historyFilePath atomically:YES];
            NSLog(@"history of %@ recorded to %@",playerDictArray[playerIndex][@"name"],historyFilePath);
            
        }
    }
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
