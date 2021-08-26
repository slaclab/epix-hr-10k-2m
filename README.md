# epix-hr-dev

# Before you clone the GIT repository

1) Create a github account:
> https://github.com/

2) On the Linux machine that you will clone the github from, generate a SSH key (if not already done)
> https://help.github.com/articles/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent/

3) Add a new SSH key to your GitHub account
> https://help.github.com/articles/adding-a-new-ssh-key-to-your-github-account/

4) Setup for large filesystems on github (one-time operation)
> $ git lfs install

# Clone the GIT repository
``` $ git clone --recursive git@github.com:slaclab/epix-hr-dev```


# Program camera mcs file

1) go to folder
cd epix-hr-single-10k/software

2) source the environment
source setup_env_slac.sh

3) run script (substitute "EpixHr10kT-0x03010000-20210823153944-ddoering-20f1553.mcs" with your file
python ./scripts/updateEpixHr  --mcs   ../firmware/targets/EpixHr10kT/images/EpixHr10kT-0x03010000-20210823153944-ddoering-20f1553.mcs --lane 0


# Running the camera

1) go to folder
cd epix-hr-single-10k/software

2) source the environment
source setup_env_slac.sh

3) run the main script

   3.1 when using PCIe card without timing receiver
       python scripts/ePixHr10kTDaq.py --type=kcu1500

   3.2 when using PCIe card with timing receiver
       python scripts/ePixHr10kTDaqLCLSII.py --type=kcu1500

4) configure the available ASICs

   go to Commands->EpixHr and execute
   initASIC [routine, ASIC0, ASIC1, ASIC2, ASIC3]
      routine reffers to the initialization script
      ASICx should be set to one if ASIC is present or zero if not.

5) check trigger setting

   go to Variable->EpixHr->TriggerRegisters
   
   5.1 when using PCIe card without timing receiver
   
       set PgpTrigEn False

       set AutoTrigPeriod to 100000 for 1kfps
          period is the value set *10ns

       set AutoDatEn True

       set AutoRunEn True

       set RunTriggerEn True

       At this point triggers will be issued at the requested rate
       Similar trigger can be generated by the Run Control in the System tab

   5.2 when using PCIe card with timing receiver

       set PgpTrigEn True

       set AutoTrigPeriod to any value since it is not used in this mode

       set AutoDatEn False

       set AutoRunEn False

       set RunTriggerEn True

       At this point the camera is ready to receive triggers from the timing module
   
	
   