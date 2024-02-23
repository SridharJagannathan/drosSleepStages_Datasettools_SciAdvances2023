[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.10277443.svg)](https://doi.org/10.5281/zenodo.10277443)

Repository for extracting and using dataset described in the paper:   [![DOI:10.1126/sciadv.adj4399](https://zenodo.org/badge/DOI/10.1126/sciadv.adj4399.svg)](https://doi.org/10.1126/sciadv.adj4399)

## Dataset location
The original dataset location is present as a multi-part series in `dryad`
To get the location of individual flies they are present in the [dataset_details](https://github.com/SridharJagannathan/drosSleepStages_Datasettools_SciAdvances2023/blob/main/dataset_details.csv)
Data for each fly is organised in 16 DOI(s) corresponding to 16 flies.

## Dataset description
This multi-part dataset contains local field potential (lfp) recordings and video data of 16 _`drosophila melanogaster`_ flies. The folder structure(s) should be arranged as follows:

```

├── 02_27072018_SponSleep_LFP
│   ├── lfp
│   │   ├── 27072018_SponSleep_Calib
│   │   │   
│   │   └── 27072018_SponSleep_LFP
│   └── video

├── 03_14092018_SponSleep_LFP
│   ├── lfp
│   │   ├── 14092018_SponSleep_Calib
│   │   │   
│   │   └── 14092018_SponSleep_LFP
│   └── video

├── 04_17092018_SponSleep_LFP
│   ├── lfp
│   │   ├── 17092018_SponSleep_Calib
│   │   │   
│   │   └── 17092018_SponSleep_LFP
│   └── video

├── 06_30102018_SponSleep_LFP
│   ├── lfp
│   │   ├── 30102018_SponSleep_Calib
│   │   │   
│   │   └── 30102018_SponSleep_LFP
│   └── video

├── 07_01112018_SponSleep_LFP
│   ├── lfp
│   │   ├── 01112018_SponSleep_Calib
│   │   │   
│   │   └── 01112018_SponSleep_LFP
│   └── video

├── 08_03112018_SponSleep_LFP
│   ├── lfp
│   │   ├── 03112018_SponSleep_Calib
│   │   │   
│   │   └── 03112018_SponSleep_LFP
│   └── video

├── 09_13112018_SponSleep_LFP
│   ├── lfp
│   │   ├── 13112018_SponSleep_Calib
│   │   │   
│   │   └── 13112018_SponSleep_LFP
│   └── video

├── 12_28112018_SponSleep_LFP
│   ├── lfp
│   │   ├── 28112018_SponSleep_Calib
│   │   │   
│   │   └── 28112018_SponSleep_LFP
│   └── video

├── 14_11122018_SponSleep_LFP
│   ├── lfp
│   │   ├── 11122018_SponSleep_Calib
│   │   │   
│   │   └── 11122018_SponSleep_LFP
│   └── video

├── 15_13122018_SponSleep_LFP
│   ├── lfp
│   │   ├── 13122018_SponSleep_Calib
│   │   │   
│   │   └── 13122018_SponSleep_LFP
│   └── video

├── 16_18122018_SponSleep_LFP
│   ├── lfp
│   │   ├── 18122018_SponSleep_Calib
│   │   │   
│   │   └── 18122018_SponSleep_LFP
│   └── video

├── 17_10012019_SponSleep_LFP
│   ├── lfp
│   │   ├── 10012019_SponSleep_Calib
│   │   │   
│   │   └── 10012019_SponSleep_LFP
│   └── video

├── 18_17012019_SponSleep_LFP
│   ├── lfp
│   │   ├── 17012019_SponSleep_Calib
│   │   │   
│   │   └── 17012019_SponSleep_LFP
│   └── video

├── 19_22012019_SponSleep_LFP
│   ├── lfp
│   │   ├── 22012019_SponSleep_Calib
│   │   │   
│   │   └── 22012019_SponSleep_LFP
│   └── video

├── 21_20022019_SponSleep_LFP
│   ├── lfp
│   │   ├── 20022019_SponSleep_Calib
│   │   │   
│   │   └── 20022019_SponSleep_LFP
│   └── video

├── 23_13032019_SponSleep_LFP
│   ├── lfp
│   │   ├── 13032019_SponSleep_Calib
│   │   │   
│   │   └── 13032019_SponSleep_LFP
│   └── video

```

## Dataset collation
To collate data for each fly follow the below steps:
1. For e.g. lets take the data for the fly `23_13032019_SponSleep_LFP`, using the [dataset_details](https://github.com/SridharJagannathan/drosSleepStages_Datasettools_SciAdvances2023/blob/main/dataset_details.csv) we gather the specific DOI for the fly.
2. Download the zip files: DrosSponSleep_SciAdvances2023_16_lfp_01.zip, DrosSponSleep_SciAdvances2023_16_lfp_02.zip, DrosSponSleep_SciAdvances2023_16_video_01.zip, DrosSponSleep_SciAdvances2023_16_video_02.zip
3. Create a basefolder named as: `23_13032019_SponSleep_LFP`
4. Within the basefolder create a LFP folder named as: `lfp`
   * Create a calibfolder named as `13032019_SponSleep_Calib` within the LFP folder.
   * Copy the contents of the folder `13032019_SponSleep_Calib` within the `DrosSponSleep_SciAdvances2023_16_lfp_01.zip` and put the same to the calibfolder.
   * Create a sublfpfolder named as `13032019_SponSleep_LFP` within the LFP folder.
   * Copy the contents of the folder `13032019_SponSleep_LFP` within the `DrosSponSleep_SciAdvances2023_16_lfp_01.zip` and put the same to the sublfpfolder.
   * Copy the contents of the folder `13032019_SponSleep_LFP` within the `DrosSponSleep_SciAdvances2023_16_lfp_02.zip` and put the same to the sublfpfolder.

5. Within the basefolder create a videofolder named as: `video`
   * Copy the contents of the folder `23_13032019_SponSleep_LFP` within the `DrosSponSleep_SciAdvances2023_16_video_01.zip` and put the same to the videofolder.
   * Copy the contents of the folder `23_13032019_SponSleep_LFP` within the `DrosSponSleep_SciAdvances2023_16_video_02.zip` and put the same to the videofolder.
6. Thus, you will end up with a folder structure like below:
   ```
   ├── 23_13032019_SponSleep_LFP
   │   ├── lfp
   │   │   ├── 13032019_SponSleep_Calib
   │   │   │   
   │   │   └── 13032019_SponSleep_LFP
   │   └── video

   ```
   
## Dataset contents

After the collation for individual fly, each folder consists of a specific spontaneous sleep recording. For e.g. 23_13032019_SponSleep_LFP contains
lfp and video recorded from a particular drosophila on 13-03-2019. Within each folder there are two subfolders.
* lfp: contains two further subfolders:
  * folder ending with `_Calib` contains lfp data recorded when calibration (electrode insertion) was performed as a single block.
  * folder ending with `_LFP` contains lfp data of the full recording, either as a single block or as multiple blocks (1 block per
     recording hour).
* video: contains movies in the form of `.avi` files and for each frame of the corresponding movie a `.csv` file containing recorded time of each frame. The columns of the `.csv` file contain: year, month, date, hour, date, hour, minutes, seconds, microseconds and number of the frame in the corresponding columns `Year,Month,Date,Hour,Mins,Seconds,usec,nFrames`. Some recordings also contain files with `_Setup` and `_Calib` indicating videos recorded during setup and calibration of the experiment.

## Data extraction

* LFP data:
   To extract the LFP data follow the below steps:
   1. Convert tdt tank files to eeglab format [preprocess_converttdt.m](https://github.com/SridharJagannathan/drosSleepStages_Datasettools_SciAdvances2023/blob/main/Scripts/dataextraction/preprocess_converttdt.m)
   2. Interpolate the data between adjacent recording hours [preprocess_interpolation.m](https://github.com/SridharJagannathan/drosSleepStages_Datasettools_SciAdvances2023/blob/main/Scripts/dataextraction/preprocess_interpolation.m)

* Calibration data:
   To extract the calibration data follow the below steps:
   1. Convert tdt tank files of the calibration to eeglab format [preprocess_converttdt.m](https://github.com/SridharJagannathan/drosSleepStages_Datasettools_SciAdvances2023/blob/main/Scripts/dataextraction/preprocess_converttdt.m)
   2. Extract the calibration data from the eeglab format [preprocess_calibration.m](https://github.com/SridharJagannathan/drosSleepStages_Datasettools_SciAdvances2023/blob/main/Scripts/dataextraction/preprocess_calibration.m)

* Video data:
   Some example usage of the video data is given below:
   1. Check the data integrity to ensure video frames and csv file contain data of similar dimensions [check_videodataintegrity.ipynb](https://github.com/SridharJagannathan/drosSleepStages_Datasettools_SciAdvances2023/blob/main/Scripts/datachecks/check_videodataintegrity.ipynb)
   2. Example dataprocessing of movement detection between adjacent frames [motiondetection_thread.ipynb](https://github.com/SridharJagannathan/drosSleepStages_Datasettools_SciAdvances2023/blob/main/Scripts/dataextraction/motiondetection_thread.ipynb)

## Software
* Matlab 2021b
* Python 3.6.x

## Support
* Please raise an issue incase you face any difficulty of extracting/utilising the dataset and I will try and get back to you in a few days.
