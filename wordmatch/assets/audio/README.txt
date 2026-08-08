真人发音资源目录
====================

Pro 用户播放真人音频时会在本目录查找发音文件：
- 命名：<单词小写>.mp3，特殊字符替换为下划线 _
  例如：hello → hello.mp3，ice-cream → ice_cream.mp3，don't → don_t.mp3
- 格式：MP3 单声道 64kbps 44.1kHz（最优体积）
- 找不到资源时，会自动回退到系统 TTS（flutter_tts）

首批建议配置的高频词（前 100 词就能覆盖 50% 用户场景）：
hello.mp3, world.mp3, apple.mp3, banana.mp3, study.mp3, work.mp3,
book.mp3, water.mp3, time.mp3, good.mp3, new.mp3, day.mp3, ...

注意：本目录下的音频资源会随 App 打包安装到用户设备，注意总体积（建议<30MB）。
如果需要更多词真人发音，可改为「按需云端下载 + 本地缓存」模式。
