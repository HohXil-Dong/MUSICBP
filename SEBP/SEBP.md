# SEBP 运行说明

## 1. 当前结构
`SEBP` 已重组为独立工作流，所有主控脚本、配置和数据目录都放在 `SEBP` 根目录下。

一级结构如下：

- `SEBP/common`：配置与工程辅助函数
- `SEBP/funcLib`：BP/MUSIC 与相关依赖函数库
- `SEBP/mainshock`：主震目录，包含 `Data/Input/Fig`
- `SEBP/<event_name>`：每个余震目录，例如 `SEBP/af04_M51`
- `SEBP/SEBP_step1.m` 到 `SEBP/SEBP_step5.m`
- `SEBP/create_ev.m`
- `SEBP/create_ca.m`

默认只保留 `maduo_2021` 配置，配置入口为：

- `SEBP/common/musicbp_config.m`

## 2. 新入口对应关系
当前 SEBP 入口固定为：

- `SEBP_step1.m`：主震读取、对齐、MUSIC/BMFM BP
- `SEBP_step2.m`：读取余震并匹配主震台站/迁移 `timeshift`
- `SEBP_step3.m`：运行余震 MUSIC BP
- `SEBP_step4.m`：使用 `ca_ap_loc.mat` 校正余震
- `SEBP_step5.m`：使用同一套慢度项校正主震

人工步骤脚本保留原名：

- `create_ev.m`
- `create_ca.m`

## 3. 目录约定
主震目录固定为：

- `SEBP/mainshock/Data`
- `SEBP/mainshock/Input`
- `SEBP/mainshock/Fig`

余震目录固定为：

- `SEBP/af04_M51/Data`
- `SEBP/af04_M51/Input`
- `SEBP/af04_M51/Fig`

其他余震按相同方式平铺在 `SEBP` 根目录下。

默认玛多配置中的关键文件：

- 主震 BP 参数文件：`SEBP/mainshock/Input/Par0.5_2_10.mat`
- 主震校正参数文件：`SEBP/mainshock/Input/Par0.5_2_10_cali.mat`
- 余震列表：`SEBP/evtlst.mat`
- 余震 apparent/catalog 位置：`SEBP/ca_ap_loc.mat`
- 走时表：`SEBP/funcLib/libBP/Ptimesdepth.mat`

## 4. 主震流程
主震入口脚本：

- `SEBP/SEBP_step1.m`

常用步骤如下：

1. 如需创建 `mainshock/Input`、`mainshock/Data`、`mainshock/Fig`，设置 `Initial_flag=1`
2. 将主震 SAC 数据放入 `SEBP/mainshock/Data`
3. 设置 `readBP_flag=1`，自动生成 `filelist`，并输出 `SEBP/mainshock/Input/data0.mat`
4. 手动设置 `Band_for_align`
5. 如需参考自动建议，先设置 `alignpara_flag=1`。  
   `Band_for_align=1` 时读取 `data0.mat`；更高频带时读取上一轮的 `data(Band_for_align-1).mat`，并打印建议的 `ts11/refst`
6. 根据 `alignpara_flag` 的输出，手动修改 `align` 数组中的 `ts11/refst/cutoff`
7. 设置 `alignBP_flag=1`，只对当前 `Band_for_align` 执行一轮手动对齐，并生成对应的 `data1.mat`、`data2.mat` 等
8. 完成所需对齐轮次后，再设置 `runBPmusic_flag=1` 或 `runBPbmfm_flag=1`，输出 `Par*.mat` 和对应的结果目录

`SEBP_step1.m` 会把详细运行信息追加写入：

- `SEBP/mainshock/Input/SEBP_step1.log`

终端只保留高层摘要；逐台站读入、`alignpara` 推荐值、每轮对齐的 cut 台站列表和 BP 输出目录写入该日志文件。

主震阶段关键输出：

- `data0.mat`
- `dataN.mat`
- `Par*.mat`
- `*_MUSIC_Dir`
- `*_bmfm_Dir`

## 5. 余震与校正流程
### 5.1 生成余震列表
在 `SEBP` 根目录下维护余震目录，例如：

- `SEBP/af04_M51`
- `SEBP/af06_M52`
- `SEBP/af08_M52`

每个目录下应放置对应余震的 `Data/`。

运行：

- `SEBP/create_ev.m`

输出：

- `SEBP/evtlst.mat`

### 5.2 匹配主震台站与时间校正
运行：

- `SEBP/SEBP_step2.m`

输出：

- `SEBP/<event>/Input/data5.mat`

### 5.3 运行余震 MUSIC BP
运行：

- `SEBP/SEBP_step3.m`

输出：

- `SEBP/<event>/Input/Par0.5_2_10.mat`
- `SEBP/<event>/Input/Par0.5_2_10_MUSIC_Dir/`

### 5.4 人工整理余震 apparent 位置
对每个余震：

1. 打开对应 `movieBP.mat`
2. 根据 `Power` 判读显像时间窗
3. 读取该时间窗内 `bux` / `buy` 的均值
4. 将 apparent 与 catalog 位置填入 `SEBP/create_ca.m`

运行：

- `SEBP/create_ca.m`

输出：

- `SEBP/ca_ap_loc.mat`

### 5.5 校正余震
运行：

- `SEBP/SEBP_step4.m`

输出：

- `SEBP/<event>/Input/Par0.5_2_10_cali.mat`
- `SEBP/<event>/Input/Par0.5_2_10_music_Cali2Dplus_Dir/`

### 5.6 校正主震
运行：

- `SEBP/SEBP_step5.m`

输出：

- `SEBP/mainshock/Input/Par0.5_2_10_cali.mat`
- `SEBP/mainshock/Input/Par0.5_2_10_music_Cali2Dplus_Dir/`

## 6. 常见问题
### 缺少目录或文件
优先检查：

- `SEBP/mainshock/Data` 是否有主震 SAC
- `SEBP/<event>/Data` 是否有余震 SAC
- `SEBP/evtlst.mat` 是否已生成
- `SEBP/ca_ap_loc.mat` 是否已生成
- `SEBP/mainshock/Input/Par*.mat` 是否已由 `SEBP_step1.m` 生成

### 找不到 `Par0.5_2_10.mat`
当前默认玛多配置仍会生成这个基名。如果修改了 `SEBP/common/musicbp_config.m` 中的频带或窗口，需要重新运行上游步骤生成新的 `Par*.mat`。

### 找不到 `Ptimesdepth.mat`
检查：

- `SEBP/funcLib/libBP/Ptimesdepth.mat`

### 没有匹配台站
说明某个余震与主震读入后的台站集合没有交集。优先检查：

- 余震台站是否与主震来自同一阵列
- SAC 命名和台站代码是否一致
- 是否误删数据

## 7. 最小测试流程
建议按下面顺序验证：

1. 在 MATLAB 中切到 `SEBP` 根目录
2. 运行 `startup_sebp`
3. 运行 `cfg = musicbp_config('maduo_2021');`
4. 检查 `cfg.active.mainshock_dir` 是否指向 `SEBP/mainshock`
5. 运行 `SEBP_step1.m` 的 `readBP_flag=1`
6. 在 `SEBP_step1.m` 中手动设置 `Band_for_align=1`，按需运行 `alignpara_flag=1` 和 `alignBP_flag=1`
7. 将 `Band_for_align` 依次改为 `2`、`3`、`4`，重复手动对齐流程
8. 运行 `SEBP_step1.m` 的 `runBPmusic_flag=1`
9. 运行 `create_ev.m`
10. 运行 `SEBP_step2.m`
11. 运行 `SEBP_step3.m`
12. 完成人工整理后运行 `create_ca.m`
13. 运行 `SEBP_step4.m`
14. 运行 `SEBP_step5.m`

如果第 1 步到第 8 步都能在新目录结构下正常生成文件，说明主震流程迁移已经成功。

如果你不能在 MATLAB 图形界面里使用 `Set Path`，不影响运行。直接在命令行执行：

```matlab
cd /path/to/MUSICBP/SEBP
startup_sebp
cfg = musicbp_config('maduo_2021');
```

## 8. 修改到其他事件时优先改哪里
如果后续切换到其他事件，优先修改：

- `SEBP/common/musicbp_config.m`

重点字段包括：

- 主震目录和主震参数
- 对齐频带与窗口参数
- 主震 BP 和余震 BP 的频带、网格、时窗参数
- `ref_station`
- `max_events`

不建议再直接在 `SEBP_step1-5.m` 中硬改绝对路径。
