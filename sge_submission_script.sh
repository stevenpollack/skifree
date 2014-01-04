#!/bin/bash

# To have grid engine attempt to allocate 11-21 slots
# for this particular job, run this script via
# qsub -pe orte 11-21 -R y engine_submission_script.sh

# Make sure that the .e and .o file arrive in the
# working directory
#$ -cwd

# Merge the std out and std error to one file
#$ -j y

# Work in current directory
#$ -cwd

# Make sure your current environment variables
# are used on your SGE jobs
#$ -V

# Set shell to /bin/bash
#$ -S /bin/bash

# Email provided address when job status changes
#$ -M your.email@whatever.domain
#$ -m beas


# Manually set the displayed job name
#$ -N exampleYeti

mpirun -v -n 1 R --vanilla < exampleYetiScript.R > exampleYetiScript.Rout