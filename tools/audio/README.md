# 逆潮电台原声

九首曲目的共同呼号在主音、五度及随后回落的短句间变化。结局以大调回应标题曲。曲目保留完整小节，跨越边界的音符、节拍延迟和混响在首拍接续。

| 文件 | 曲名 | BPM | 小节 | 主要声部 |
| --- | --- | ---: | ---: | --- |
| title | Carrier in the Rain | 88 | 24 | 簧管、钟琴、电钢、港湾雨声 |
| workshop | Solder & Salt | 98 | 24 | 木琴、切分电钢、边击 |
| market | Night Shift Arcade | 118 | 32 | 明亮合成独奏、闷音弦、拍手 |
| docks | Dry Dock Dub | 106 | 32 | 半拍军鼓、长低音、金属敲击、延迟和弦 |
| tower | Relay Ascent | 126 | 32 | 四拍底鼓、左右接力的琶音 |
| boss | Breaker at Blackwater | 145 | 32 | 铜管音色、失真低音、碎拍 |
| ending | The Lamps Answer | 82 | 24 | 大调电钢、人声质感长音、钟琴 |
| past | Side A, Under the Counter | 84 | 24 | 带周期性磁带颤动的电钢、边击、远处电机 |
| catwalk | Aerial Steps | 123 | 32 | 气鸣笛、木琴、攀升琶音与轻盈切分 |

配乐与音效的旋律、节奏、音色和录音均由本项目的源码合成。制作过程没有使用第三方乐曲、采样、声音字体、素材包、克隆嗓音或生成式音乐服务。游戏项目可使用、修改、发行这些音频及制作源。Python、NumPy、SciPy、SoundFile 和 FFmpeg 仅在制作阶段使用。

`score.py` 保存逐小节的和声与旋律，`synth.py` 定义振荡器、鼓组和乐器，`render.py` 负责配器、效果器、母带、编码、十四个动作音效和五首短波台标。本次使用 Python 3.12.16、NumPy 2.5.5、SciPy 1.18.1、SoundFile 0.14.0 和 libsndfile 1.2.2。下列命令在项目根目录执行。FFmpeg 需在 PATH 中。

```sh
python3.12 -m venv /tmp/undertow-audio
/tmp/undertow-audio/bin/pip install numpy==2.5.5 scipy==1.18.1 soundfile==0.14.0
/tmp/undertow-audio/bin/python tools/audio/render.py
/tmp/undertow-audio/bin/python tools/audio/check.py
```

也可按曲名重建，例如 `render.py boss ending`，或用 `render.py sfx` 重建音效。配乐为 44.1 kHz 双声道 Ogg Vorbis，供游戏启用循环。音效为 44.1 kHz、16 位单声道 PCM。交付文件已解码复测，总长 576.94 秒，综合响度 −19.3 至 −17.5 LUFS，四倍过采样真峰值最高 −7.85 dBTP。所有循环均保留与曲速匹配的精确采样帧数。

配线台的五条回传音分别为剧院的报幕钟、盐仓的敲击、海关的短促应答、天线阵的上行呼号和北堤的低声航标。每条回传都带有窄带扬声器和避难所墙面的短回声。
