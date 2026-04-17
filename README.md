# MUSICBP
*Multi-taper MUSIC Back-projection Method for earthquake source imaging in Matlab.*

The MUSICBP repository root now keeps only the tutorial examples, with two standalone entry scripts:

- `General_BP_Palu.m`
- `General_BP_Tohoku.m`

The SEBP workflow is now organized independently under [`SEBP/SEBP.md`](SEBP/SEBP.md).

Recent root-level changes are limited to engineering cleanup for the tutorial scripts: path resolution, project directory creation, `filelist` generation, and output-directory checks. These changes do not modify the numerical back-projection kernels or the intended imaging results of the MUSICBP tutorial examples.

The Multiple Signal Classification (MUSIC) technique is a high-resolution technique designed to resolve closely spaced simultaneous sources. MUSIC enables back-projection imaging (BP) with superior resolution than the standard Beamforming techinque. MUSICBP is a tutorial code in Matlab that images the spatial-temporal evolution of high-frequency radiators (as a proxy of rupture front) for large earthquakes.

Please follow the instructions below for tutorial usage.

1.    Open `General_BP_Palu.m` or `General_BP_Tohoku.m` in the MUSICBP root directory and set `Initial_flag` as 1. Run the script to initialize the tutorial project folder.
2.    Copy the seismic data (ending with `.SAC`) into the generated project `Data/` folder.
3.    Set only `readBP_flag=1` to read the earthquake data into Matlab. As the code finishes, plots of waveforms and stations will pop out, and `data0.mat` will be created in the `Input/` folder.
4.    Set `alignBP_flag=1` and tune the parameters under "Parameters for Hypocenter alignment" to align the waveform. Several alignment passes are usually needed to obtain the best result.

Alignment tips:
The parameter `ts` is the start time of the cross-correlation window. Keep the window centered on the P arrival, meaning `ts = [P arrival time] - [0.5 * window length]`. Try to preserve as many stations with high cross-correlation coefficients as possible. A station set with better density, aperture, and azimuthal coverage generally gives more reliable BP results. When `refSta = 0`, the stacked waveform is used as the reference trace.

5.    Set `runBPbmfm_flag` or `runBPmusic_flag` as 1 and set up parameters of the back-projection runner to perform the Beamforming BP or Multiple Signal Classification BP. This step produces the BP movies (`movie.gif`) and summary plots (`summary.pdf`). The coordinates and power of the BP results are listed in the `HFdots` file.
