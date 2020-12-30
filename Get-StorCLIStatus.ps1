function Get-DriveGroupDriveList
{
    Param (
        $StorCLIOutput
    )
    
    # RegExp Pattern used to match the required information in the StorCLI output.
    #
    # Data is extracted from RegExp groups, and returned as individual objects.
    #
    $Pattern = "^([0-9]+:[0-9]+)\s+([0-9]+)\s+(\w+)\s+([0-9]+)\s+([0-9.]+)\s+(\w+)\s+(\w+)\s+(\w+)\s+(\w+)\s+(\w+)\s+([0-9A-Za-z]+)\s+([0-9A-Za-z ]+)\s+([UD])\s{2,}(\w|[-])+"

    $StorCLIOutput|% {
        if ($_ -Match $Pattern) {
            [PSCustomObject]@{
                Position    = $Matches[1]
                DriveID     = $Matches[2]
                State       = $Matches[3]
                DriveGroup  = $Matches[4]
                Size        = $Matches[5]
                Unit        = $Matches[6]
                Interface   = $Matches[7]
                Media       = $Matches[8]
                SED         = $Matches[9]
                PI          = $Matches[10]
                SectorSize  = $Matches[11]
                Model       = $Matches[12]
                Spun        = $Matches[13]
                Type        = $Matches[14]
            }
        }
    }
}


function Get-VirtualDriveList
{
    Param (
        $StorCLIOutput
    )

    # RegExp Pattern used to match the required information in the StorCLI output.
    #
    # Data is extracted from RegExp groups, and returned as individual objects.
    #
    $Pattern = "^([0-9]+)/([0-9]+)\s+([0-9A-Za-z]+)\s+([0-9A-Za-z]+)\s+([0-9A-Za-z]+)\s+([0-9A-Za-z]+)\s+([0-9A-Za-z]+)\s+([0-9A-Za-z-]+)\s+([0-9A-Za-z]+)\s+([0-9.]+)\s+([A-Za-z]+)\s+([^ ]{1}.+)"

    $StorCLIOutput|% {
        if ($_ -Match $Pattern) {
            [PSCustomObject]@{
                DriveGroup                  = $Matches[1]
                VirtualDrive                = $Matches[2]
                Type                        = $Matches[3]
                State                       = $Matches[4]
                Access                      = $Matches[5]
                Consistent                  = $Matches[6]
                Cache                       = $Matches[7]
                WriteCache                  = $(if ($Matches[7].ToString().Contains("AWB")) {"Always Write Back"} elseif ($Matches[7].ToString().Contains("WB")) {"Write Back"} elseif ($Matches[7].ToString().Contains("WT")) {"Write Through"} else {"Unknown"})
                ReadAhead                   = $(if ($Matches[7].ToString().Contains("NR")) {$False} else {$True})
                IO                          = $(if ($Matches[7].ToString().Contains("C")) {"Cached"} else {"Direct"})
                CacheCade                   = $Matches[8]
                ScheduledConsistencyCheck   = $Matches[9]
                Size                        = $Matches[10]
                Unit                        = $Matches[11]
                Name                        = $Matches[12]
            }
        }
    }
}