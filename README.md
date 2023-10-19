# drosSleepStages_Datasettools_SciAdvances2023
Repository for extracting and using dataset described in the paper drosSleepStages_SciAdvances2023

## Dataset location
The original dataset location is present as a multi-part series in `dryad`
To get the location of individual flies they are present in the [dataset_details](https://github.com/SridharJagannathan/drosSleepStages_Datasettools_SciAdvances2023/blob/main/dataset_details.csv)

## Dataset description
This is a part of the multi-part dataset containing local field potential (lfp) recordings and video data of 16 _`drosophila melanogaster`_ flies. This part contains:

```
├── DrosSponSleep_SciAdvances2023_01
│   ├── 02_27072018_SponSleep_LFP
│   │   ├── lfp
│   │   │   ├── 27072018_SponSleep_Calib
│   │   │   │   └── Block-1
│   │   │   └── 27072018_SponSleep_LFP
│   │   └── video
│   └── 03_14092018_SponSleep_LFP
│       ├── lfp
│       │   ├── 14092018_SponSleep_Calib
│       │   │   └── Block-1
│       │   └── 14092018_SponSleep_LFP
│       └── video
├── DrosSponSleep_SciAdvances2023_02
│   ├── 04_17092018_SponSleep_LFP
│   │   ├── lfp
│   │   │   ├── 17092018_SponSleep_Calib
│   │   │   │   └── Block-1
│   │   │   └── 17092018_SponSleep_LFP
│   │   └── video
│   └── 06_30102018_SponSleep_LFP
│       ├── lfp
│       │   ├── 30102018_SponSleep_Calib
│       │   │   └── Block-1
│       │   └── 30102018_SponSleep_LFP
│       └── video
├── DrosSponSleep_SciAdvances2023_03
│   ├── 07_01112018_SponSleep_LFP
│   │   ├── lfp
│   │   │   ├── 01112018_SponSleep_Calib
│   │   │   │   └── Block-1
│   │   │   └── 01112018_SponSleep_LFP
│   │   └── video
│   └── 08_03112018_SponSleep_LFP
│       ├── lfp
│       │   ├── 03112018_SponSleep_Calib
│       │   │   └── Block-1
│       │   └── 03112018_SponSleep_LFP
│       └── video
├── DrosSponSleep_SciAdvances2023_04
│   ├── 09_13112018_SponSleep_LFP
│   │   ├── lfp
│   │   │   ├── 13112018_SponSleep_Calib
│   │   │   │   └── Block-1
│   │   │   └── 13112018_SponSleep_LFP
│   │   └── video
│   └── 12_28112018_SponSleep_LFP
│       ├── lfp
│       │   ├── 28112018_SponSleep_Calib
│       │   │   └── Block-1
│       │   └── 28112018_SponSleep_LFP
│       └── video
├── DrosSponSleep_SciAdvances2023_05
│   ├── 14_11122018_SponSleep_LFP
│   │   ├── lfp
│   │   │   ├── 11122018_SponSleep_Calib
│   │   │   │   └── Block-1
│   │   │   └── 11122018_SponSleep_LFP
│   │   └── video
│   └── 15_13122018_SponSleep_LFP
│       ├── lfp
│       │   ├── 13122018_SponSleep_Calib
│       │   │   └── Block-1
│       │   └── 13122018_SponSleep_LFP
│       └── video
├── DrosSponSleep_SciAdvances2023_06
│   ├── 16_18122018_SponSleep_LFP
│   │   ├── lfp
│   │   │   ├── 18122018_SponSleep_Calib
│   │   │   │   └── Block-1
│   │   │   └── 18122018_SponSleep_LFP
│   │   └── video
│   └── 17_10012019_SponSleep_LFP
│       ├── lfp
│       │   ├── 10012019_SponSleep_Calib
│       │   │   └── Block-1
│       │   └── 10012019_SponSleep_LFP
│       └── video
├── DrosSponSleep_SciAdvances2023_07
│   ├── 18_17012019_SponSleep_LFP
│   │   ├── lfp
│   │   │   ├── 17012019_SponSleep_Calib
│   │   │   │   └── Block-1
│   │   │   └── 17012019_SponSleep_LFP
│   │   └── video
│   └── 19_22012019_SponSleep_LFP
│       ├── lfp
│       │   ├── 22012019_SponSleep_Calib
│       │   │   └── Block-1
│       │   └── 22012019_SponSleep_LFP
│       └── video
└── DrosSponSleep_SciAdvances2023_08
    ├── 21_20022019_SponSleep_LFP
    │   ├── lfp
    │   │   ├── 20022019_SponSleep_Calib
    │   │   │   └── Block-1
    │   │   └── 20022019_SponSleep_LFP
    │   └── video
    └── 23_13032019_SponSleep_LFP
        ├── lfp
        │   ├── 13032019_SponSleep_Calib
        │   │   └── Block-1
        │   └── 13032019_SponSleep_LFP
        └── video

```
Each folder consists of a specific spontaneous sleep recording. For e.g. 06_30102018_SponSleep_LFP contains
lfp and video recorded from a particular drosophila on 30-10-2018. Within each folder there are two subfolders.
* lfp: contains two further subfolders:
  * folder ending with `_Calib` contains lfp data recorded when calibration (electrode insertion) was performed as a single block.
  * folder ending with `_LFP` contains lfp data of the full recording, either as a single block or as multiple blocks (1 block per
     recording hour).
* video: contains movies in the form of `.avi` files and for each frame of the corresponding movie a `.csv` file containing recorded time of each frame. some recordings also contain files with `_Setup` and `_Calib` indicating videos recorded during setup and calibration of the experiment.

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
* Please e-mail me incase you face any difficulty of extracting/utilising the dataset and I will try and get back to you in a few days
