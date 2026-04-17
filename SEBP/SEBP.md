# SEBP Overview And Workflow

## 1. What SEBP Is
`SEBP` is a standalone workflow reorganized from the tutorial-style `MUSICBP` implementation in the repository root. It is used for:

- standard MUSIC / BMFM back-projection of the 2021 Maduo mainshock
- aftershock-based slowness correction
- slowness-enhanced back-projection of both aftershocks and the mainshock

The main public entry points are:

- `SEBP_step1.m`: mainshock standard MUSIC / BMFM BP
- `SEBP_step2.m`: aftershock SAC reading, station matching, and mainshock `timeshift` transfer
- `SEBP_step3.m`: aftershock MUSIC BP
- `SEBP_step4.m`: aftershock slowness-term inversion and regenerated calibrated aftershock results
- `SEBP_step5.m`: application of the same slowness terms back to the mainshock
- `create_ev.m`: aftershock event list maintenance
- `create_ca.m`: aftershock apparent / catalog location maintenance

The only configuration entry point is:

- `SEBP/common/musicbp_config.m`

The currently supported profile is:

- `maduo_2021`

## 2. Relation To `SEBP_v0`
The current `SEBP` combines the two historical parts of `SEBP_v0` into one standalone workflow:

- `SEBP_v0/AU_workshop`: standard mainshock MUSIC BP workflow
- `SEBP_v0/Calibrate`: aftershock matching, aftershock correction, and mainshock recalibration workflow

Script mapping:

| `SEBP_v0` | Current `SEBP` |
| --- | --- |
| `SEBP_v0/AU_workshop/General_BP.m` | `SEBP/SEBP_step1.m` |
| `SEBP_v0/Calibrate/AU102_Auto_read_and_match.m` | `SEBP/SEBP_step2.m` |
| `SEBP_v0/Calibrate/AU103_Auto_run_music.m` | `SEBP/SEBP_step3.m` |
| `SEBP_v0/Calibrate/AU104_Auto_cali_music.m` | `SEBP/SEBP_step4.m` |
| `SEBP_v0/Calibrate/AU105_Main_cali_music.m` | `SEBP/SEBP_step5.m` |
| `SEBP_v0/Calibrate/create_ev.m` | `SEBP/create_ev.m` |
| `SEBP_v0/Calibrate/create_ca.m` | `SEBP/create_ca.m` |

This correspondence is workflow-level only. It does not claim point-by-point numerical identity unless separately verified.

## 3. Engineering Changes Relative To `SEBP_v0`

### 3.1 Single-root standalone layout
The old split between `AU_workshop` and `Calibrate` has been reorganized into one `SEBP/` root directory.

Top-level structure:

- `SEBP/common`: configuration and workflow helpers
- `SEBP/funcLib`: BP / MUSIC dependency library
- `SEBP/mainshock`: mainshock working directory
- `SEBP/<event_name>`: aftershock working directories such as `SEBP/af04_M51`
- `SEBP/SEBP_step1.m` to `SEBP/SEBP_step5.m`

### 3.2 Explicit step scripts
Historical controller names such as `General_BP.m` and `AU102_Auto_read_and_match.m` were replaced by `SEBP_step1.m` to `SEBP_step5.m`. This makes the execution order explicit without changing the scientific workflow.

### 3.3 Path cleanup
Hard-coded absolute paths from `SEBP_v0` were replaced by:

- `fileparts(mfilename('fullpath'))`
- `fullfile(...)`
- centralized configuration from `musicbp_config('maduo_2021')`

Each step now initializes its own path context. No separate startup script is required before running `SEBP_step1.m` to `SEBP_step5.m`.

### 3.4 Centralized configuration
Event parameters, alignment settings, BP parameters, and key file paths are now managed in:

- `SEBP/common/musicbp_config.m`

This file defines:

- mainshock working directories
- read / alignment / BP parameters
- aftershock BP parameters
- paths to `evtlst.mat`, `ca_ap_loc.mat`, `Ptimesdepth.mat`, and related files
- the reference station index

### 3.5 Helper functions for workflow robustness
Current engineering helpers include:

- `musicbp_require.m`: explicit file / directory checks with clear errors
- `musicbp_log.m`: step-level logging
- `musicbp_prepare_data_dir.m`: `Data` directory validation and `filelist` generation
- `musicbp_step_setup.m`: common path setup, configuration loading, and step log initialization

### 3.6 Cleaner logging and terminal output
The workflow now separates:

- concise terminal summaries for step-level progress
- detailed logs in `SEBP/SEBP_step1.log` to `SEBP/SEBP_step5.log`

This is an engineering change only. It does not imply any change to the BP / MUSIC / slowness-correction formulas.

### 3.7 Fixed directory convention
The standalone workflow consistently uses:

- `Data`: raw waveform inputs
- `Input`: intermediate data, parameter files, BP result directories
- `Fig`: generated figures and image products

For the mainshock:

- `SEBP/mainshock/Data`
- `SEBP/mainshock/Input`
- `SEBP/mainshock/Fig`

For each aftershock:

- `SEBP/<event>/Data`
- `SEBP/<event>/Input`
- `SEBP/<event>/Fig`

### 3.8 Manual interpretation is still preserved
The engineering refactor does not replace the original manual interpretation steps. Important manual actions still include:

- checking `alignpara` suggestions before updating `align`
- manually preparing apparent / catalog aftershock locations for `create_ca.m`

## 4. Scientific Workflow That Remains The Same
At the workflow level, the current implementation still follows the same sequence as the original method chain:

1. standard mainshock MUSIC BP
2. aftershock SAC reading and mainshock station matching
3. transfer of mainshock `timeshift` to aftershocks
4. aftershock MUSIC BP and apparent-location extraction
5. inversion of slowness terms from apparent / catalog aftershock locations
6. regeneration of calibrated aftershock and mainshock results using the same slowness terms

This statement is limited to workflow structure. It does not claim any unverified change in formulas, travel-time handling, station ordering, or correction logic.

Scientifically sensitive parts still include:

- waveform alignment
- `timeshift` transfer
- apparent / catalog location preparation
- `get_dS_2Dplus` and related slowness-term estimation
- BP parameter selection

## 5. Current Key Paths

- configuration: `SEBP/common/musicbp_config.m`
- mainshock directory: `SEBP/mainshock`
- aftershock list: `SEBP/evtlst.mat`
- aftershock apparent / catalog locations: `SEBP/ca_ap_loc.mat`
- travel-time table: `SEBP/funcLib/libBP/Ptimesdepth.mat`
- step logs: `SEBP/SEBP_step1.log` to `SEBP/SEBP_step5.log`

Under the default Maduo profile, typical parameter files are:

- `SEBP/mainshock/Input/Par0.5_2_10.mat`
- `SEBP/mainshock/Input/Par0.5_2_10_cali.mat`
- `SEBP/<event>/Input/data5.mat`
- `SEBP/<event>/Input/Par0.5_2_10.mat`
- `SEBP/<event>/Input/Par0.5_2_10_cali.mat`

## 6. Current Execution Order

### 6.1 Load configuration
From the `SEBP` root in MATLAB:

```matlab
cfg = musicbp_config('maduo_2021');
```

Running `SEBP_step1.m` to `SEBP_step5.m` directly is also fine. Each step now initializes its own path context automatically.

### 6.2 Mainshock BP: `SEBP_step1.m`
Typical order:

1. put mainshock SAC files in `SEBP/mainshock/Data`
2. set `readBP_flag=1` to generate `filelist` and `data0.mat`
3. choose `Band_for_align`
4. set `alignpara_flag=1` if suggestions are needed
5. manually update `align` values if needed
6. set `alignBP_flag=1` for the chosen manual alignment pass
7. run `runBPmusic_flag=1` or `runBPbmfm_flag=1` after the required alignment passes are complete

Detailed engineering logs are written to:

- `SEBP/SEBP_step1.log`

### 6.3 Maintain aftershock list: `create_ev.m`
Keep aftershock event directories such as:

- `SEBP/af04_M51`
- `SEBP/af06_M52`
- `SEBP/af08_M52`

Each one should contain its own `Data/` directory. Then run:

```matlab
create_ev
```

This generates:

- `SEBP/evtlst.mat`

### 6.4 Aftershock reading and `timeshift` transfer: `SEBP_step2.m`

```matlab
SEBP_step2
```

This step:

- reads aftershock SAC files
- matches stations against the mainshock result
- transfers the aligned mainshock `timeshift`
- writes `Input/data5.mat` for each aftershock

### 6.5 Aftershock MUSIC BP: `SEBP_step3.m`

```matlab
SEBP_step3
```

This step runs MUSIC BP for each aftershock using `data5.mat` and generates the corresponding parameter files and result directories.

### 6.6 Manual apparent / catalog location preparation: `create_ca.m`
This step remains manual. A typical workflow is:

1. inspect the corresponding `movieBP.mat`
2. choose the imaged time interval based on `Power`
3. read the apparent location from that interval
4. enter both apparent and catalog locations in `create_ca.m`

Then run:

```matlab
create_ca
```

This generates:

- `SEBP/ca_ap_loc.mat`

### 6.7 Aftershock slowness correction: `SEBP_step4.m`

```matlab
SEBP_step4
```

This step:

- reads `ca_ap_loc.mat`
- estimates slowness terms from apparent / catalog aftershock locations
- generates calibrated parameter files and calibrated result directories for each aftershock

### 6.8 Mainshock recalibration: `SEBP_step5.m`

```matlab
SEBP_step5
```

This step applies the same slowness terms estimated from aftershocks back to the mainshock result.

## 7. Current Scope And Limits

- only the `maduo_2021` profile is currently supported
- `SEBP_v0/` is the comparison baseline used in this repository
- the documentation describes the current code state only
- engineering cleanup is not presented as an algorithmic upgrade

If this workflow is migrated to another event, the recommended first edit point is:

- `SEBP/common/musicbp_config.m`

rather than rewriting absolute paths inside `SEBP_step1.m` to `SEBP_step5.m`.

## 8. References
Relevant papers and background material are stored under `Paper/` at the repository root.

- `Paper/MUSICBP.pdf`
  - background for standard mainshock MUSIC back-projection
- `Paper/SEBP.pdf`
  - background for slowness-enhanced back-projection
- `Paper/Zhang et al. - 2023 - Understanding and Mitigating the Spatial Bias of Earthquake Source Imaging With Regional Slowness En.pdf`
  - background on spatial bias and regional slowness enhancement
- `Paper/Xu et al. - 2023 - Understanding the Rupture Kinematics and Slip Model of the 2021 Mw 7.4 Maduo Earthquake A Bilateral.pdf`
  - Maduo event application background
- `Paper/Bao_NatGeo2019.pdf`
- `Paper/Meng et al. - Improving back projection imaging with a novel physics-based aftershock calibration approach A case.pdf`

These references are useful for understanding the method and the application context. The implementation details in the current repository should still be interpreted from the actual scripts and configuration under `SEBP/`.
