# welcome to OSC!
# accessing and navigating OSC

## logging in via ssh in terminal

1. In terminal/command line run: 
  `` $ ssh username@ascend.osc.edu ``
  and then enter your OSC password when prompted
2. You will initially be dumped in your home dir (ex. ``/users/ACCOUNT_NUMBER/username``)

## logging in via OnDemand
https://ondemand.osc.edu/
- use for starting up JupyterLab instances! file browser is pretty clunky
- go to Interactive Apps -> Jupyter -> change hours, node type, cores as needed -> Launch!
- allows for file editing, terminal access, git access all through JupyterLab interface

## logging in via ssh in VSCode
1. Log into SSH remote directory username@ascend.osc.edu
- allows for file editing, terminal access, git access all through VSCode interface 

# osc hacks

## edit your bashrc to add shortcuts for common commands
your .bashrc 
```bash
alias q='squeue -u <USERNAME>'
foldername="/fs/ess/PAS2905"
```

- set up alias commands so that you don't have to type out entire commands for common ones
- can set up directory name variables in your .bashrc in your home directory and then in terminal use `cd $variablename` to change to directory


# important

- any batch jobs you run **must be run on the Ascend cluster on the nextgen partition** (perks of being [COM](https://www.osc.edu/resources/technical_support/supercomputers/ascend/osu_college_of_medicine_compute_service))



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
