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
- Script does not record, or take into consideration version of StorCLI (output may change with version).

So in its first real workable state, I ended up adding quite a bit of functionality, so
that error checking and email notifications is built in, along with alot of other stuff.

The first lot of code - the part to objectify StorCLI data, went really well, and is
imho real nice code... as the development went along, it started to be troublesome... I
got some errors that where extremely hard to root out - primarily because of Powershells
weird way of handling parameters, and transfering data between functions and the calling
code (how PS seems to wrap everything oddly into objects, that in edge cases doesn't
unwrap too well on their own again). Anyway - long story short, the last 25% of the code
isn't as nice as I would like it to be, but to the best of my knowledge, it works.

Features:
- Takes StorCLI textual output, and:
  - Returns a PSCustomObject with data in objectified form - or
  - Checks status on the data, and can mail a status/error report, log data, etc. 
    depending on the options supplied to the script.

- The PSCustomobject contains:
  - All/most information available in the StorCLI output
  - Full report for status for each area present, in text and HTML format
  - Error report for each area present in error state, in text and HTML format


Script has comment based help, so use Get-Help Get-StorCLIStatus.ps1 for more information.