function ConvertFrom-StorCLIOutput
{
    <#
    .SYNOPSIS
        Convert textual output from LSI StorCLI to a Powershell custom object

    .DESCRIPTION
        Find all sections in LSI StorCLI textual output, and add the contents of that
        section to Powershell custom object, as a property.
        
        Raw contents will be added to a .Raw property.

    .PARAMETER InputObject
        This is the variable containing the textual output from LSI StorCLI

        It must either be a string which can be split using "Newline" (CHR 10), or an Array.

    .EXAMPLE
        $LSIOutput =

        CLI Version = 007.1211.0000.0000 Nov 07, 2019
        Operating system = VMkernel 6.7.0
        Controller = 0
        Status = Success
        Description = Show Drive Group Succeeded

        TOPOLOGY :
        ========

        -----------------------------------------------------------------------------
        DG Arr Row EID:Slot DID Type  State BT       Size PDC  PI SED DS3  FSpace TR 
        -----------------------------------------------------------------------------
        0 -   -   -        -   RAID1 Optl  N  371.597 GB enbl N  N   dflt N      N  
        0 0   -   -        -   RAID1 Optl  N  371.597 GB enbl N  N   dflt N      N  
        0 0   0   32:20    36  DRIVE Onln  N  371.597 GB enbl N  N   dflt -      N  
        0 0   1   32:21    37  DRIVE Onln  N  371.597 GB enbl N  N   dflt -      N  
        -----------------------------------------------------------------------------

        DG=Disk Group Index|Arr=Array Index|Row=Row Index|EID=Enclosure Device ID
        DID=Device ID|Type=Drive Type|Onln=Online|Rbld=Rebuild|Dgrd=Degraded
        Pdgd=Partially degraded|Offln=Offline|BT=Background Task Active
        PDC=PD Cache|PI=Protection Info|SED=Self Encrypting Drive|Frgn=Foreign
        DS3=Dimmer Switch 3|dflt=Default|Msng=Missing|FSpace=Free Space Present
        TR=Transport Ready


        VD LIST :
        =======

        -----------------------------------------------------------------------
        DG/VD TYPE  State Access Consist Cache Cac sCC       Size Name         
        -----------------------------------------------------------------------
        0/0   RAID1 Optl  RW     Yes     NRWBD -   ON  371.597 GB DS002_R1_SSD 
        -----------------------------------------------------------------------

        EID=Enclosure Device ID| VD=Virtual Drive| DG=Drive Group|Rec=Recovery
        Cac=CacheCade|OfLn=OffLine|Pdgd=Partially Degraded|Dgrd=Degraded
        Optl=Optimal|RO=Read Only|RW=Read Write|HD=Hidden|TRANS=TransportReady|B=Blocked|
        Consist=Consistent|R=Read Ahead Always|NR=No Read Ahead|WB=WriteBack|
        AWB=Always WriteBack|WT=WriteThrough|C=Cached IO|D=Direct IO|sCC=Scheduled
        Check Consistency

        Total VD Count = 1

        DG Drive LIST :
        =============

        -------------------------------------------------------------------------------------
        EID:Slt DID State DG       Size Intf Med SED PI SeSz Model                   Sp Type 
        -------------------------------------------------------------------------------------
        32:20    36 Onln   0 371.597 GB SATA SSD N   N  512B INTEL SSDSC2BA400G3E    U  -    
        32:21    37 Onln   0 371.597 GB SATA SSD N   N  512B INTEL SSDSC2BA400G3E    U  -    
        -------------------------------------------------------------------------------------

        EID=Enclosure Device ID|Slt=Slot No.|DID=Device ID|DG=DriveGroup
        DHS=Dedicated Hot Spare|UGood=Unconfigured Good|GHS=Global Hotspare
        UBad=Unconfigured Bad|Onln=Online|Offln=Offline|Intf=Interface
        Med=Media Type|SED=Self Encryptive Drive|PI=Protection Info
        SeSz=Sector Size|Sp=Spun|U=Up|D=Down|T=Transition|F=Foreign
        UGUnsp=UGood Unsupported|UGShld=UnConfigured shielded|HSPShld=Hotspare shielded
        CFShld=Configured shielded|Cpybck=CopyBack|CBShld=Copyback Shielded
        UBUnsp=UBad Unsupported|Rbld=Rebuild

        Total Drive Count = 2


        ConvertFrom-StorCLIOutput -InputObject $LSIOutput

        Will output:

        Object with the following properties:

        .Topology
        .VDLIST
        .DGDriveLIST
        .Raw

        Each property containing an array with the contents of the relevant section, and .Raw
        containing -InputObject in its entirety.

    .OUTPUTS
        Custom object containing a set of properties, matching the sections present in
        -InputObject, containing the lines of text present in each relevant section.

    .NOTES
        Spaces are stripped from the Section names. Properties will be named the same as the
        sections without spaces.

        Author: Kenneth Nielsen (sharzas @ GitHub.com)

    .LINK
        https://github.com/sharzas/Powershell-Get-StorCLIStatus
        
    #>
    [CmdLetBinding()]
    Param (
        [Parameter(Mandatory = $true)]$InputObject
    )

    if ($InputObject -is [string]) {
        $InputObject = $InputObject.Split("`n")
    }

    if ($InputObject -isnot [Array]) {
        return $null
    }

    # find all section underscores, and grab context with 1 lines to each side.
    $SectionData = $InputObject|Select-String -Pattern "^====" -Context 1

    # process all found sections, and record line number in the InputObject array,
    # along with the title of the section.
    #
    # Spaces and trailing colon will be removed from the section title
    #
    $Sections = @($SectionData|ForEach-Object {
        [PSCustomObject]@{
            Name = $_.Context.PreContext[0].ToString().Replace(":","").Replace(" ","").Trim()
            StartIndex = $_.LineNumber
            EndIndex = $null
        }
    })
    
    if ($Sections.Count -lt 1) {
        # no sections found - bail
        return $null
    }


    # loop through sections array, and add end index
    $LastEndIndex = $InputObject.GetUpperBound(0)

    $Sections = $Sections|Sort-Object -Property StartIndex -Descending|ForEach-Object {
        $_.EndIndex = $LastEndIndex
        $LastEndIndex = $_.StartIndex-3  # -3 because 2 are from the section header, and 1 is to not overlap next section header
        $_
    }|Sort-Object -Property StartIndex

    
    # build return object - .Raw property = full raw content of input object.
    $StorCLIObject = [PSCustomObject]@{
        Raw = $InputObject
    }

    # loop through all enumerated sections, and populate an property with their name on the return object.
    # data will be an array with the raw text from that section.
    foreach ($Section in $Sections) {
        $StorCLIObject|Add-Member -MemberType NoteProperty -Name $Section.Name -Value $InputObject[$($Section.StartIndex)..$($Section.EndIndex)]
    }

    return $StorCLIObject
}







function ConvertFrom-FixedWidthTable
{
    <#
    .SYNOPSIS
        Convert a fixed width table, to a collection of PSCustomObjects.

    .DESCRIPTION
        Convert a fixed width table, to a collection of PSCustomObjects.
        
        Each row will have a property + value pair matching the name of the Column Header.

    .PARAMETER InputObject
        This is the variable containing the fixed width table. It must be an array.

    .PARAMETER HeaderPattern
        Specifies the Header RexExp match pattern. This must be a string, containing a RegExp
        patterh.

        The line in -InputObject matching this pattern will be designated the header row.

        The Pattern must be constructed using RegExp groups, that matches the width of the
        column (it will be used to split up the value for this column in each row).

    .PARAMETER EndPattern
        Specifies the Ebd RexExp match pattern. This must be a string, containing a RegExp
        patterh.

        The line in -InputObject matching this pattern will be designated the header row.

        The fixed width table being processed, will be the lines between:
        
        Header Row + the number of lines specified in -SkipLinesAfterHeader

        and

        The line matching -EndPattern

    .PARAMETER SkipLinesAfterHeader
        Skip this number of additional lines after the Header row. This is useful if there
        is a separator line between the header row.

    .PARAMETER SkipPattern
        Any lines matching this pattern in the fixed width table will be skipped.

    .PARAMETER DoNotTrimSpaces
        If specified, values split from each row, will not be trimmed of leading/trailing whitespaces.

    .EXAMPLE
        $Table = @'
        -----------------------------------------------------------------------------
        DG Arr Row EID:Slot DID Type  State BT       Size PDC  PI SED DS3  FSpace TR 
        -----------------------------------------------------------------------------
        0 -   -   -        -   RAID1 Optl  N  371.597 GB enbl N  N   dflt N      N  
        0 0   -   -        -   RAID1 Optl  N  371.597 GB enbl N  N   dflt N      N  
        0 0   0   32:20    36  DRIVE Onln  N  371.597 GB enbl N  N   dflt -      N  
        0 0   1   32:21    37  DRIVE Onln  N  371.597 GB enbl N  N   dflt -      N  
        1 -   -   -        -   RAID1 Optl  N  930.390 GB enbl N  N   dflt N      N  
        1 0   -   -        -   RAID1 Optl  N  930.390 GB enbl N  N   dflt N      N  
        1 0   0   32:22    38  DRIVE Onln  N  930.390 GB enbl N  N   dflt -      N  
        1 0   1   32:23    39  DRIVE Onln  N  930.390 GB enbl N  N   dflt -      N  
        -----------------------------------------------------------------------------
        '@

        ConvertFrom-FixedWidthTable -InputObject $Table -SkipLinesAfterHeader 1 -HeaderPattern "(^.*?DG)\s+(Arr\s+)(Row\s+)(EID:Slot\s+)(DID\s+)(Type\s+)(State\s+)(BT)\s(\s+Size)\s+(PDC\s+)(PI\s+)(SED\s+)(DS3\s+)(FSpace\s+)(TR.*?$)" -EndPattern "^-------"

        Will output:

        DG Arr Row EID:Slot DID Type  State BT Size       PDC  PI SED DS3  FSpace TR
        -- --- --- -------- --- ----  ----- -- ----       ---  -- --- ---  ------ --
        0  -   -   -        -   RAID1 Optl  N  371.597 GB enbl N  N   dflt N      N
        0  0   -   -        -   RAID1 Optl  N  371.597 GB enbl N  N   dflt N      N
        0  0   0   32:20    36  DRIVE Onln  N  371.597 GB enbl N  N   dflt -      N
        0  0   1   32:21    37  DRIVE Onln  N  371.597 GB enbl N  N   dflt -      N
        1  -   -   -        -   RAID1 Optl  N  930.390 GB enbl N  N   dflt N      N
        1  0   -   -        -   RAID1 Optl  N  930.390 GB enbl N  N   dflt N      N
        1  0   0   32:22    38  DRIVE Onln  N  930.390 GB enbl N  N   dflt -      N
        1  0   1   32:23    39  DRIVE Onln  N  930.390 GB enbl N  N   dflt -      N

        Notice how the HeaderPattern is using RegExp groups (things between parantheses)

    .OUTPUTS
        A collection of objects all containing a set of properties, matching the RegExp groups
        extracted using -HeaderPattern, and populated with values split from each row of the
        table, corresponding with the Index and Length matching the Header Row RegExp group
        placement.

        If the table could not be processed, $null is returned. In that case use -Verbose to
        check whats going wrong.


    .NOTES
        Author: Kenneth Nielsen (sharzas @ GitHub.com)

    .LINK
        https://github.com/sharzas/Powershell-Get-StorCLIStatus
        
    #>

    [CmdLetBinding()]

    Param (
        [Parameter(Mandatory = $true)]$InputObject,
        [Parameter(Mandatory = $true)][string]$HeaderPattern,
        [Parameter(Mandatory = $true)][string]$EndPattern,
        $SkipLinesAfterHeader = 0,
        $SkipPattern = $null,
        [switch]$DoNotTrimSpaces = $false
    )

    Write-Verbose ('ConvertFrom-FixedWidthTable(): Invoked')
    Write-Verbose ('ConvertFrom-FixedWidthTable(): -HeaderPattern.......: "{0}"' -f $HeaderPattern)
    Write-Verbose ('ConvertFrom-FixedWidthTable(): -EndPattern..........: "{0}"' -f $EndPattern)
    Write-Verbose ('ConvertFrom-FixedWidthTable(): -SkipPattern.........: "{0}"' -f $SkipPattern)
    Write-Verbose ('ConvertFrom-FixedWidthTable(): -SkipLinesAfterHeader: "{0}"' -f $SkipLinesAfterHeader)
    Write-Verbose ('ConvertFrom-FixedWidthTable(): -DoNotTrimSpaces.....: "{0}"' -f $DoNotTrimSpaces)

    if ($InputObject -isnot [Array]) {
        Write-Verbose ('ConvertFrom-FixedWidthTable(): InputObject is not an [Array]')
        return $null
    }

    $Header = $InputObject|Select-String -Pattern $HeaderPattern

    if ($null -eq $Header) {
        # no pattern matching -HeaderPattern found in the Array
        Write-Verbose ('ConvertFrom-FixedWidthTable(): No lines in -InputObject matching RegExp pattern specified in -HeaderPattern')

        return $null
    }

    Write-Verbose ('ConvertFrom-FixedWidthTable(): Header found at line {0}' -f $Header.LineNumber)
    Write-Verbose ('ConvertFrom-FixedWidthTable(): Number of columns derived from Header Pattern {0}' -f ($Header[0].Matches[0].Groups.Count -1))

    $Columns = $Header[0].Matches[0].Groups|Select-Object -Skip 1|Sort-Object -Property Index

    # look from the header and forward, with respect to the -SkipLinesAfterHeader value, and attempt
    # to match a line to the -EndPattern - this will be end of the table, and everything between the
    # (Header line + -SkipLinesAfterHeader) to -EndPattern line will be the table we're splitting into
    # fixed width columns.
    #
    $End = $InputObject|Select-Object -Skip ($Header.LineNumber + $SkipLinesAfterHeader)|Select-String -Pattern $EndPattern

    if ($null -eq $End) {
        # no pattern matching -EndPattern found in the Array
        Write-Verbose ('ConvertFrom-FixedWidthTable(): No lines in -InputObject, after the Header + skipped lines, matching RegExp pattern specified in -EndPattern!')

        return $null
    }

    # this is the amount of lines we're gonna process
    $Lines = $End.LineNumber -1

    Write-Verbose ('ConvertFrom-FixedWidthTable(): End pattern found at line {0} after the header + skipped lines (-SkipLinesAfterHeader = {1})' -f $End.LineNumber, $SkipLinesAfterHeader)
    Write-Verbose ('ConvertFrom-FixedWidthTable(): Lines to process {0}' -f $Lines)

    if ($Lines -lt 1) {
        # No data... endpattern matches right after where we're going to start, so Lines = 0
        Write-Verbose ('ConvertFrom-FixedWidthTable(): End pattern matches right after start - no data to process.')

        return $null
    }

    foreach ($line in ($InputObject|Select-Object -Skip ($Header.LineNumber + $SkipLinesAfterHeader)|Select-Object -First $Lines)) {
        
        if (-not (($null -ne $SkipPattern) -and ($line -match $SkipPattern))) {
            $Object = New-Object PSCustomObject

            foreach ($Column in $Columns) {
                if ($DoNotTrimSpaces) {
                    # -DoNotTrimSpaces specified = dont trim trailing/ending spaces of the value in the column
                    $Object|Add-Member -MemberType NoteProperty -Name $Column.Value.ToString().Trim() -Value $line.ToString().Substring($Column.Index, $Column.Length)
                } else {
                    # -DoNotTrimSpaces NOT specified = trim trailing/ending spaces of the value in the column
                    $Object|Add-Member -MemberType NoteProperty -Name $Column.Value.ToString().Trim() -Value $line.ToString().Substring($Column.Index, $Column.Length).Trim()
                }
            }

            $Object
        }
    }
} # function ConvertFrom-FixedWidthTable






function Get-StorCLIDriveGroupDriveList
{
    [CmdLetBinding()]
    Param (
        $StorCLIOutput
    )

    Write-Verbose 'Get-StorCLIDriveGroupDriveList(): Invoked.'
    
    # RegExp Pattern used to match the required information in the StorCLI output.
    #
    # Data is extracted from RegExp groups, and returned as individual objects.
    #
    # EID:Slt DID State DG       Size Intf Med SED PI SeSz Model                   Sp Type 
    # -------------------------------------------------------------------------------------
    # 32:20    36 Onln   0 371.597 GB SATA SSD N   N  512B INTEL SSDSC2BA400G3E    U  -    
    # 
    $Pattern = "^([0-9]+:[0-9]+)\s+([0-9]+)\s+(\w+)\s+([0-9]+)\s+([0-9.]+)\s+(\w+)\s+(\w+)\s+(\w+)\s+(\w+)\s+(\w+)\s+([0-9A-Za-z]+)\s+([0-9A-Za-z ]+)\s+([UD])\s{2,}(\w|[-])+"

    # Define abbreviation conversion list - since the StorCLI output is heavily abbreviated.
    #
    $AbbList = @{
        "BT"        = "Background Task Active"
        "CBShld"    = "CopyBack Shielded"
        "CFShld"    = "Configured Shielded"
        "Cpybck"    = "CopyBack"
        "dflt"      = "Default"
        "DHS"       = "Dedicated Hot Spare"
        "dsbl"      = "Disabled"
        "enbl"      = "Enabled"
        "GHS"       = "Global Hot Spare"
        "HSPShld"   = "Hot Spare Shielded"
        "Msng"      = "Missing"
        "Optl"      = "Optimal"
        "Onln"      = "Online"
        "Offln"     = "Offline"
        "Dgrd"      = "Degraded"
        "Pdgd"      = "Partially Degraded"
        "Rbld"      = "Rebuilding"
        "UBad"      = "Unconfigured Bad"
        "UBUnsp"    = "Unconfigured Bad Unsupported"
        "UGood"     = "Unconfigured Good"
        "UGShld"    = "Unconfigured Shielded"
        "UGUnsp"    = "Unconfigured Good Unsupported"
    }

    # Define SPUN States
    #
    $Spun = @{
        "D" = "Down"
        "F" = "Foreign"
        "T" = "Transition"
        "U" = "Up"
    }


    $Sections = ConvertFrom-StorCLIOutput -InputObject $StorCLIOutput

    if ($null -eq $Sections) {
        # nothing returned from ConvertFrom-StorCLIOutput, either the data
        # is invalid, or something else is wrong.

        Write-Verbose 'Get-StorCLIDriveGroupDriveList(): Nothing returned from ConvertFrom-StorCLIOutput - maybe not output from StorCLI ?'
        return $null
    }

    if ($null -eq ($Sections|Get-Member -Name "DGDriveLIST")) {
        # no .DGDriveLIST section found, so that data was most likely not present in the
        # output from StorCLI

        Write-Verbose 'Get-StorCLIDriveGroupDriveList(): no .DGDriveLIST section found, so that data was most likely not present in the StorCLI output.'
        return $null
    }


    $Sections.DGDriveLIST|ForEach-Object {
        if ($_ -Match $Pattern) {
            [PSCustomObject]@{
                Position    = $Matches[1]
                DriveID     = $Matches[2]
                State       = $(
                                if ($AbbList.ContainsKey($Matches[3])) {
                                    $AbbList[$Matches[3]]
                                } else {
                                    $Matches[3]
                                }
                            )
                DriveGroup  = $Matches[4]
                Size        = [Convert]::ToDecimal($Matches[5].ToString().Replace(".",","))
                Unit        = $Matches[6]
                Interface   = $Matches[7]
                Media       = $Matches[8]
                SED         = $(
                                if ($Matches[9] -eq "Y") {
                                    $true
                                } elseif ($Matches[9] -eq "N") {
                                    $false
                                } else {
                                    $Matches[9]
                                }
                            )
                PI          = $(
                                if ($Matches[10] -eq "Y") {
                                    $true
                                } elseif ($Matches[10] -eq "N") {
                                    $false
                                } else {
                                    $Matches[10]
                                }
                            )
                SectorSize  = $Matches[11]
                Model       = $Matches[12]
                Spun        = $(
                                if ($Spun.ContainsKey($Matches[13])) {
                                    $Spun[$Matches[13]]
                                } else {
                                    $Matches[13]
                                }
                            )
                Type        = $Matches[14]
            }
        }
    }
} # function Get-StorCLIDriveGroupDriveList








function Get-StorCLITopology
{
    [CmdLetBinding()]
    Param (
        $StorCLIOutput
    )

    Write-Verbose 'Get-StorCLITopology(): Invoked.'

    # Define abbreviation conversion list - since the StorCLI output is heavily abbreviated.
    #
    $AbbList = @{
        "BT"        = "Background Task Active"
        "CBShld"    = "CopyBack Shielded"
        "CFShld"    = "Configured Shielded"
        "Cpybck"    = "CopyBack"
        "dflt"      = "Default"
        "DHS"       = "Dedicated Hot Spare"
        "dsbl"      = "Disabled"
        "enbl"      = "Enabled"
        "GHS"       = "Global Hot Spare"
        "HSPShld"   = "Hot Spare Shielded"
        "Msng"      = "Missing"
        "Optl"      = "Optimal"
        "Onln"      = "Online"
        "Offln"     = "Offline"
        "Dgrd"      = "Degraded"
        "Pdgd"      = "Partially Degraded"
        "Rbld"      = "Rebuilding"
        "UBad"      = "Unconfigured Bad"
        "UBUnsp"    = "Unconfigured Bad Unsupported"
        "UGood"     = "Unconfigured Good"
        "UGShld"    = "Unconfigured Shielded"
        "UGUnsp"    = "Unconfigured Good Unsupported"
    }

    # Define SPUN States
    #
    $Spun = @{
        "D" = "Down"
        "F" = "Foreign"
        "T" = "Transition"
        "U" = "Up"
    }

    $Sections = ConvertFrom-StorCLIOutput -InputObject $StorCLIOutput

    if ($null -eq $Sections) {
        # nothing returned from ConvertFrom-StorCLIOutput, either the data
        # is invalid, or something else is wrong.

        Write-Verbose 'Get-StorCLITopology(): Nothing returned from ConvertFrom-StorCLIOutput - maybe not output from StorCLI ?'
        return $null
    }

    if ($null -eq ($Sections|Get-Member -Name Topology)) {
        # no .Topology section found, so that data was most likely not present in the
        # output from StorCLI

        Write-Verbose 'Get-StorCLITopology(): no .Topology section found, so that data was most likely not present in the StorCLI output.'
        return $null
    }

    $Topology = ConvertFrom-FixedWidthTable -InputObject $Sections.Topology -SkipLinesAfterHeader 1 -HeaderPattern "(^.*?DG)\s+(Arr\s+)(Row\s+)(EID:Slot\s+)(DID\s+)(Type\s+)(State\s+)(BT)\s(\s+Size)\s+(PDC\s+)(PI\s+)(SED\s+)(DS3\s+)(FSpace\s+)(TR.*?$)" -EndPattern "^-------"

    if ($null -eq $Topology) {
        # could not convert the Topology section from a FixedWidthTable to a collection of objects.

        Write-Verbose 'Get-StorCLITopology(): could not convert the Topology section from a FixedWidthTable to a collection of objects.'
        return $null
    }



    $Topology|ForEach-Object {
        [PSCustomObject]@{
            DriveGroup              = $_.DG
            ArrayIndex              = $_.Arr
            RowIndex                = $_.Row
            Position                = $_.'EID:Slot'
            DriveID                 = $_.DID
            Type                    = $_.Type
            State                   = $(
                                        if ($AbbList.ContainsKey($_.State)) {
                                            $AbbList[$_.State]
                                        } else {
                                            $_.State
                                        }
                                    )
            BackGroundTaskActive    = $(
                                        if ($_.BT -eq "Y") {
                                            $true
                                        } elseif ($_.BT -eq "N") {
                                            $false
                                        } else {
                                            $_.BT
                                        }
                                    )
            Size                    = [Convert]::ToDecimal($_.Size.ToString().Split(" ")[0].Trim().Replace(".",","))
            Unit                    = $_.Size.ToString().Split(" ")[1].Trim()
            PhysicalDriveCache      = $(
                                        if ($AbbList.ContainsKey($_.PDC)) {
                                            $AbbList[$_.PDC]
                                        } else {
                                            $_.PDC
                                        }
                                    )
            SED                     = $(
                                        if ($_.SED -eq "Y") {
                                            $true
                                        } elseif ($_.SED -eq "N") {
                                            $false
                                        } else {
                                            $_.SED
                                        }
                                    )
            PI                      = $(
                                        if ($_.PI -eq "Y") {
                                            $true
                                        } elseif ($_.PI -eq "N") {
                                            $false
                                        } else {
                                            $_.PI
                                        }
                                    )
            DS3                     = $(
                                        if ($AbbList.ContainsKey($_.DS3)) {
                                            $AbbList[$_.DS3]
                                        } else {
                                            $_.DS3
                                        }
                                    )
            FSpace                  = $(
                                        if ($_.FSpace -eq "Y") {
                                            $true
                                        } elseif ($_.FSpace -eq "N") {
                                            $false
                                        } else {
                                            $_.FSpace
                                        }
                                    )
            TransportReady          = $(
                                        if ($_.TR -eq "Y") {
                                            $true
                                        } elseif ($_.TR -eq "N") {
                                            $false
                                        } else {
                                            $_.TR
                                        }
                                    )
        }
    }
} # function Get-StorCLITopology







function Get-StorCLIVirtualDriveList
{
    [CmdLetBinding()]
    Param (
        $StorCLIOutput
    )

    Write-Verbose 'Get-StorCLIVirtualDriveList(): Invoked.'

    # RegExp Pattern used to match the required information in the StorCLI output.
    #
    # Data is extracted from RegExp groups, and returned as individual objects.
    #
    # DG/VD TYPE  State Access Consist Cache Cac sCC       Size Name         
    # -----------------------------------------------------------------------
    # 0/0   RAID1 Optl  RW     Yes     NRWBD -   ON  371.597 GB DS002_R1_SSD 
    #
    #
    $Pattern = "^([0-9]+)/([0-9]+)\s+([0-9A-Za-z]+)\s+([0-9A-Za-z]+)\s+([0-9A-Za-z]+)\s+([0-9A-Za-z]+)\s+([0-9A-Za-z]+)\s+([0-9A-Za-z-]+)\s+([0-9A-Za-z]+)\s+([0-9.]+)\s+([A-Za-z]+)\s+([^ ]{1}.+)"

    # Define abbreviation conversion list - since the StorCLI output is heavily abbreviated.
    #
    $AbbList = @{
        "BT"        = "Background Task Active"
        "CBShld"    = "CopyBack Shielded"
        "CFShld"    = "Configured Shielded"
        "Cpybck"    = "CopyBack"
        "dflt"      = "Default"
        "DHS"       = "Dedicated Hot Spare"
        "dsbl"      = "Disabled"
        "enbl"      = "Enabled"
        "GHS"       = "Global Hot Spare"
        "HSPShld"   = "Hot Spare Shielded"
        "Msng"      = "Missing"
        "Optl"      = "Optimal"
        "Onln"      = "Online"
        "Offln"     = "Offline"
        "Dgrd"      = "Degraded"
        "Pdgd"      = "Partially Degraded"
        "Rbld"      = "Rebuilding"
        "UBad"      = "Unconfigured Bad"
        "UBUnsp"    = "Unconfigured Bad Unsupported"
        "UGood"     = "Unconfigured Good"
        "UGShld"    = "Unconfigured Shielded"
        "UGUnsp"    = "Unconfigured Good Unsupported"
    }

    $Sections = ConvertFrom-StorCLIOutput -InputObject $StorCLIOutput

    if ($null -eq $Sections) {
        # nothing returned from ConvertFrom-StorCLIOutput, either the data
        # is invalid, or something else is wrong.

        Write-Verbose 'Get-StorCLIVirtualDriveList(): Nothing returned from ConvertFrom-StorCLIOutput - maybe not output from StorCLI ?'
        return $null
    }

    if ($null -eq ($Sections|Get-Member -Name VDLIST)) {
        # no .Topology section found, so that data was most likely not present in the
        # output from StorCLI

        Write-Verbose 'Get-StorCLIVirtualDriveList(): no .Topology section found, so that data was most likely not present in the StorCLI output.'
        return $null
    }

    $Sections.VDLIST|ForEach-Object {
        if ($_ -Match $Pattern) {
            [PSCustomObject]@{
                DriveGroup                  = $Matches[1]
                VirtualDrive                = $Matches[2]
                Type                        = $Matches[3]
                State                       = $(
                                                if ($AbbList.ContainsKey($Matches[4])) {
                                                    $AbbList[$Matches[4]]
                                                } else {
                                                    $Matches[4]
                                                }
                                            )
                Access                      = $Matches[5]
                Consistent                  = $Matches[6]
                Cache                       = $Matches[7]
                WriteCache                  = $(
                                                if ($Matches[7].ToString().Contains("AWB")) {
                                                    "Always Write Back"
                                                } elseif ($Matches[7].ToString().Contains("WB")) {
                                                    "Write Back"
                                                } elseif ($Matches[7].ToString().Contains("WT")) {
                                                    "Write Through"
                                                } else {
                                                    "Unknown"
                                                }
                                            )
                ReadAhead                   = $(
                                                if ($Matches[7].ToString().Contains("NR")) {
                                                    $False
                                                } else {
                                                    $True
                                                }
                                            )
                IO                          = $(
                                                if ($Matches[7].ToString().Contains("C")) {
                                                    "Cached"
                                                } else {
                                                    "Direct"
                                                }
                                            )
                CacheCade                   = $Matches[8]
                ScheduledConsistencyCheck   = $Matches[9]
                Size                        = [Convert]::ToDecimal($Matches[10].ToString().Replace(".",","))
                Unit                        = $Matches[11]
                Name                        = $Matches[12]
            }
        }
    }
} # function Get-StorCLIVirtualDriveList