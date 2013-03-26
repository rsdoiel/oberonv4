Installation and Start of Oberon for Windows

1) Installation of Oberon under Windows 95 / Windows NT 3.51 or higher
    Check whether the file sizes are as following. Otherwise you have
    had troubles during downloading the distribution (maybe you did not
    transfer the files in binary mode).
      disk00: 1457152 Bytes 
      disk01: 1457152 Bytes
      disk02:  >500000 Bytes  
    Concatenate the files of the distribution into one big executable.
      copy /b disk00+disk01+disk02 oberon.exe
    Decompress Oberon by executing the program oberon.exe. This will create
      the directory Oberon (with subdirectories) in the current directory.
    You can delete the files "dummy" which reside in some of the directories.
    Create a new link to Oberon.Exe
      either by clicking the right mouse button over the Desktop,
        selecting New -> Link, browsing for Oberon.Exe
      or by dropping Oberon.Exe from the Explorer onto the Desktop
    You can change the working directory by editing the properties of the
      link to Oberon.Exe (e.g. to start in the user directory).
    Now you can start Oberon by clicking on the icon.
    You can delete the installation files again from your harddisk
      or keep it for additional installations.
    The following command line parameters would start Oberon with a heap of
    8 megabytes in a window of 1024x768 pixels:
      oberon -h 8 -width 1024 -height 768
      

2) Overcoming Problems with the Installation

    Read the contents of Oberon.Ini.
 
    You can start Oberon with the option -s to slow down the startup process
    which makes it easier to read the messages.
      Command Line: c:\oberon\oberon.exe -s

    You can start Oberon with the options -l -d (for logging and debugging)
    which enables some debugging output.
    Under Windows 95 and Windows NT a separate console window will be opened
    for the debugging output.
      Command Line: c:\oberon\oberon.exe -l -d

3) Converting Files to Oberon for Windows 95/NT Format

    Old files contained a special header that served to translate long file names
    to 8.3 file names. These headers are no longer necessary under Windows 95
    and Windows NT. Oberon for Windows 95/NT does not support these
    headers. You can convert your old files with the command
    Win31File.SkipHeader. To do so, first install Oberon for Windows 95/NT
    (preferably in a new directory to avoid overwriting of existing files that you
    might want to keep), copy the directories from your old Oberon installation
    to the new Oberon installation, start Oberon, change into the directories
    with your old files, execute the command System.Directory *, write the
    command Win31File.SkipHeader in front of the list of files and execute the
    command.