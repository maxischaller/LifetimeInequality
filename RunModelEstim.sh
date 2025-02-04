#!/bin/bash

#SBATCH --job-name=model_estim
#SBATCH --mail-user= <username>
#SBATCH --mail-type=end
#SBATCH --nodes=1
#SBATCH --ntasks=18
#SBATCH --mem-per-cpu=3000
#SBATCH --time=50:00:00
#SBATCH --qos=standard

module add MATLAB/2021a

cd <rootdiretory-of-repository>

matlab -nodisplay -nosplash < Master_Part2_ModelEstim.m
