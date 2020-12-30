### Get-StorCLIStatus ###

Powershell code to get some information in object form from LSI StorCLI Utility Output.

The need for this script arised from LSI controllers being supported by most ESXi versions,
however management tools for those where a pain. LSI StorCLI Utility on the other hand,
installs perfectly as a VIB in ESXi environment, and works, but its textual output is a
different kind of pain.

This code is made to objectify parts of that output (as needed by the author - much more
can undoubtedly be added).

I made the code to support a monitoring solution internal to the ESXi host, since the
LSI software available (LSA) weren't able to consistently detect failures (in fact I
never made it detect one single failure), so in the end I mounted a NFS datastore on the
ESXi, configured a cron job to dump StorCLI status output to a path on this NFS datastore,
and periodically ran the output through this script, and monitored for error states.

Low key and simple... error = mail, no error = log status (not included in script).


Important notes:
- Script does not record, or take into consideration of StorCLI version (output may change with version).