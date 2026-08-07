# osc hacks
## edit your bashrc to add shortcuts for common commands
```bash
alias q='squeue -u <USERNAME>'
```
# important

- any jobs you run **must be run on the Ascend cluster** (perks of being [COM](https://www.osc.edu/resources/technical_support/supercomputers/ascend/osu_college_of_medicine_compute_service))


# navigating the hpc

## logging in via ssh

1. In terminal/command line run: 
  `` $ ssh username@ascend.osc.edu ``
  and then enter your OSC password when prompted
2. You will initially be dumped in your home dir (ex. ``/users/ACCOUNT_NUMBER/username``)

# links and resources

## very helpful !

- [available software](https://www.osc.edu/resources/available_software/browse_software)
  - list of all of the available software on OSC, make sure to filter by system (Ascend)!
- [job script info](https://www.osc.edu/supercomputing/batch-processing-at-osc/job-scripts)
  - info to correctly build your job's bash script
-  [ascend cluster partition and job submission info](https://www.osc.edu/resources/technical_support/supercomputers/ascend/batch_limit_rules)
   -  info on the different partitions and job submission limits on Ascend
-  [ascend GPU computing](https://www.osc.edu/resources/technical_support/supercomputers/ascend/batch_limit_rules)
   -  specific info for using GPUs on the ascend cluster
-  [gpu computing](https://www.osc.edu/resources/technical_support/supercomputers/gpu_computing)
   -  general OSC gpu computing information

## basic management

- [my.osc.edu](https://my.osc.edu/)
  - general account management (change password, monitor job activity, get project info etc)
- [ondemand.osc.edu](https://ondemand.osc.edu/)
  - online access to HPC (download and upload files, manage jobs, SSH, start interactive GUI sessions, look at system status)
  - tbh i only use this to start interactive sessions, other than that i find it pretty clunky to use
- [osc.edu](https://www.osc.edu/)
  - documentation and resources for OSC
