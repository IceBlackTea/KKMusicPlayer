# KKMusicPlayer
一款轻量级的音乐播放器，可读取itnues和本地音乐，可设置音乐播放锁频界面，后台播放等,将音乐的信息保存到sqlite数据库中，提高界面的显示效率(适用于音乐数量比较多的情况)



//设置后台播放
[[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
[[AVAudioSession sharedInstance] setActive:YES error:nil];

添加sqilte数据库：

![image](https://github.com/WUYUJIAN/KKMusicPlayer/blob/master/截图/1.png)

在info.plist中添加Required background modes

![image](https://github.com/WUYUJIAN/KKMusicPlayer/blob/master/截图/2.png)

在info.plist中添加Privacy - Media Library Usage Description，允许app加载itnues中的音乐

![image](https://github.com/WUYUJIAN/KKMusicPlayer/blob/master/截图/3.png)

运行截图：

![image](https://github.com/WUYUJIAN/KKMusicPlayer/blob/master/截图/4.png)
![image](https://github.com/WUYUJIAN/KKMusicPlayer/blob/master/截图/5.png)
![image](https://github.com/WUYUJIAN/KKMusicPlayer/blob/master/截图/6.png)
