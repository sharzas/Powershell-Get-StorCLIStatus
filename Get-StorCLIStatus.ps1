<#
.SYNOPSIS
    Objectify Various information from LSI StorCLI textual output, check/log status,
    log data, generate status and error reports, notify by email if error.
    

.DESCRIPTION
    Objectify various information from LSI StorCLI textual output.
    
    Supports various output variations - depending on the query parameters issued
    to StorCLI.

    The output depends on what is present in the output from StorCLI, and what
    this script supports in its current form.

    Currently this script supports:
    - Parse and objectity LSI StorCLI textual output
    - Log dataset to file
    - Log script and Raid Controller state status to file.
    - Create full status report in text and HTML form.
    - Create error report in text and HTML form.
    - Check Raid Controller State, and optionally notify by e-mail if errors
      are detected.


.PARAMETER CheckStatus
    Check status of the controller, and if specified mail a report to specified
    recipients.

    You may opt to always mail a status report, or only on error. Script supports
    mail in Text or HTML format. In any case Full/Error report in HTML format will
    always be attached to the mail.

.PARAMETER ConvertFromUTCTime
    Convert Controller/System time in StorCLI output from UTC time to Local time. 
    Useful for ESXi server configurations, which are always running in UTC time zone.

.PARAMETER DataLogFile
    If specified, Data will be logged in xml form to this file, using
    Export-CliXML.
    
    The purpose of this, is to have a complete dataset for further investigation
    at a later date, and to be able to establish a technical history, if needed.

    Pruning options are available for this log, to prevent it growing uncontrollably

    NOTE: This is not the same as the -StatusLogFile!

.PARAMETER From
    From mail address used for sending mail notification.
    
    Use hashtable form to supply a display name.

    This parameter must be one of the following:
    
    [string]    "mailaddress@domain.com"
    [hashtable] @{"mailaddress@domain.com" = "Displayname"}

    If you use a hashtable, it must have exactly 1 item.

.PARAMETER LogFullStatusReport
    If specified, the full status report will be included in the status log,
    regardless of the controller being in error state or not.

.PARAMETER LogStatusReportOnError
    If specified, the error status log will be included in the status log,
    if the controller is in error state.

    The error log contains only the elements that are in error state.

.PARAMETER Password
    Password to use for SMTP server authentication. Can be supplied as [string] or [securestring]

.PARAMETER Path
    Path of text file containing output from StorCLI. 
    
    -StorCLIOutput and -Path is mutually exclusive

.PARAMETER PruneDataLog
    If specified, the data log will be pruned according to -PruneDataLogBefore.
    
    All entries dated earlier than the date specified in -PruneDataLogBefore,
    will be removed from the log.
    
.PARAMETER PruneDataLogBefore
    Specifies the cutover date used for pruning the data log. See -PruneDataLog
    for more information.
    
    If this parameter is not specified, the default is 365 days in the past.

.PARAMETER PruneStatusLogDate
    If specified, the status log will be pruned.
    
    All entries dated earlier than this date, will be removed from the log.
        
.PARAMETER Recipient
    Recipient(s) mail address(es) used for sending email notifications.
    
    This parameter can be either a single item, or an array.

    Each item in the array must be one of the following.
    
    [string]    "mailaddress@domain.com"
    [hashtable] @{"mailaddress@domain.com" = "Displayname"}
    [hashtable] @{
                    "mailaddress1@domain.com" = "Displayname"
                    "mailaddress2@otherdomain.com" = "Displayname"
                }

    NOTE: for recipient address, hashtables can contain multiple entries.

.PARAMETER ReportHostname
    This is the hostname attached to the output and the reports.
    
    This parameter is introduced, because the computer where this script is run, isn't
    neccessarily the computer where the raid controller is installed. Using this 
    parameter it is possible to identify the actual host with the raid controller.

.PARAMETER SendMailAsText
    If this parameter is specified, any mails sent will be sent as Text... default
    is to send mails in HTML format.

.PARAMETER SendMailWithReport
    If this parameter is specified, the script will send an email with the full
    status report included.

    This is useful for scheduling e.g. a job to run once a month with this parameter,
    to periodically receive a full report over the Raid Controller status in the system.

    You need to specify SMTP mail server and mail configuration parameters as well,
    if you specify this parameter.
        
.PARAMETER SendMailOnError
    If this parameter is specified, the script will send an email notification if
    the Raid Controller is in error state.

    You need to specify SMTP mail server and mail configuration parameters as well,
    if you specify this parameter.
        
.PARAMETER SMTPHost
    SMTP server to use for sending the mail.

.PARAMETER SMTPPort
    SMTP server TCP Port.

.PARAMETER StatusLogFile
    If specified, status will be logged in text form to this file.
    
    More or less data may be included, based on the other parameters specified.

    See -LogFullStatusReport and -LogStatusReportOnError

    Pruning options are available for this log, to prevent it growing uncontrollably

    NOTE: This is not the same as the -DataLogFile!

.PARAMETER StorCLIOutput
    This is a variable containing output from StorCLI in textual form.
    
    -StorCLIOutput and -Path is mutually exclusive

.PARAMETER Subject
    If specified, this will be the subject of any mails sent - wether being Error
    reports or Status reports.

    Default is to autogenerate subject, based on the hostname specified in
    -ReportHostname, and the status of the Raid Controller (OK/Error)
    
    It is recommended to let the script autogenerate a subject, as it will
    correctly reflect the current state of the Raid Controller.

.PARAMETER TimeStampFormat
    This is the DateTime format used by the logging functions. This must be a .NET
    supported TimeProvider format.
    
    IMPORTANT:
    If you change the format using -TimeStampFormat, and you are using any of the
    log pruning options, be aware that your entire log most likely will be pruned
    at first run, or the script may encounter an error.

    It is advisable to backup any logs in need of preservation first, and delete
    log files when changing this format!

.PARAMETER Username
    Username to use for SMTP server authentication. 
    
    If unspecified, no authentication will be attempted.

.EXAMPLE
    Storcli.txt file contains the output from running ""./storcli /c0 show all" on
    an ESXi system - note below output is truncated as applicable to preserve space.

    --------- [SNIP] --------
    Generating detailed summary of the adapter, it may take a while to complete.

    CLI Version = 007.1211.0000.0000 Nov 07, 2019
    Operating system = VMkernel 6.7.0
    Controller = 0
    Status = Success
    Description = None


    Basics :
    ======
    Controller = 0
    Model = ServeRAID M5015 SAS/SATA Controller
    ....

    Version :
    =======
    Firmware Package Build = 12.15.0-0239
    Firmware Version = 2.130.403-4660
    ....

    Bus :
    ===
    Vendor Id = 0x1000
    Device Id = 0x79
    ....

    Pending Images in Flash :
    =======================
    Image name = No pending images


    Status :
    ======
    Controller Status = Optimal
    Memory Correctable Errors = 0
    ....

    Supported Adapter Operations :
    ============================
    Rebuild Rate = Yes
    CC Rate = Yes
    ....

    Enterprise Key management :
    =========================
    Capability = Supported
    Boot Agent = Not Available
    Configured = No


    Supported PD Operations :
    =======================
    Force Online = Yes
    Force Offline = Yes
    ....

    Supported VD Operations :
    =======================
    Read Policy = Yes
    Write Policy = Yes
    ....

    HwCfg :
    =====
    ChipRevision =  B4
    BatteryFRU = N/A
    ....

    Policies :
    ========

    Policies Table :
    ==============

    ------------------------------------------------
    Policy                          Current Default 
    ------------------------------------------------
    Predictive Fail Poll Interval   300 sec
    Interrupt Throttle Active Count 16
    ....
    ------------------------------------------------

    Flush Time(Default) = 4s
    Drive Coercion Mode = 1GB
    ....

    Boot :
    ====
    BIOS Enumerate VDs = 1
    Stop BIOS on Error = On
    ...

    High Availability :
    =================
    Topology Type = None
    Cluster Permitted = No
    Cluster Active = No


    Defaults :
    ========
    Phy Polarity = 0
    Phy PolaritySplit = 0
    ....

    Capabilities :
    ============
    Supported Drives = SAS, SATA
    RAID Level Supported = RAID0, RAID1(2 or more drives), RAID5, RAID6, RAID00, RAID10(2 or more drives per span), RAID50, RAID60
    ....

    Scheduled Tasks :
    ===============
    Consistency Check Reoccurrence = 168 hrs
    Next Consistency check launch = 01/02/2021, 03:00:00
    ....

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

    VD LIST :
    =======

    -----------------------------------------------------------------------
    DG/VD TYPE  State Access Consist Cache Cac sCC       Size Name         
    -----------------------------------------------------------------------
    0/0   RAID1 Optl  RW     Yes     NRWBD -   ON  371.597 GB DS002_R1_SSD 
    -----------------------------------------------------------------------

    PD LIST :
    =======

    -------------------------------------------------------------------------------------
    EID:Slt DID State DG       Size Intf Med SED PI SeSz Model                   Sp Type 
    -------------------------------------------------------------------------------------
    32:20    36 Onln   0 371.597 GB SATA SSD N   N  512B INTEL SSDSC2BA400G3E    U  -    
    32:21    37 Onln   0 371.597 GB SATA SSD N   N  512B INTEL SSDSC2BA400G3E    U  -    
    -------------------------------------------------------------------------------------

    Enclosure LIST :
    ==============

    -------------------------------------------------------------------------------
    EID State Slots PD PS Fans TSs Alms SIM Port#         ProdID    VendorSpecific 
    -------------------------------------------------------------------------------
     32 OK       24  4  0    0   0    0   0 Port 4 - 7 x4 RES2SV240 x36-254.13.0.0 
    252 OK        8  0  0    0   0    0   1 -             SGPIO                    
    -------------------------------------------------------------------------------



    BBU_Info :
    ========

    -----------------------------------------------------------------------
    Model  State   RetentionTime Temp Mode MfgDate    Next Learn           
    -----------------------------------------------------------------------
    iBBU08 Optimal 48 hours +    27C  4    2011/12/14 2021/01/29  15:47:51 
    -----------------------------------------------------------------------

    Mode 4: 48+ Hrs retention with a non-transparent learn cycle 
            and balanced service life.
    --------- [SNAP] --------



    You run this command: $StorCLI = .\Get-StorCLIStatus.ps1 -StorCLIOutput (Get-Content Storcli.txt)

    $StorCLI will have the following properties:
    

    $_.Basics                     - basic information, including model/system time/etc.
    $_.Boot                       - controller boot info
    $_.Bus                        - bus information (e.g. PCI-E/SAS/SATA)
    $_.Capabilities               - information about controller capabilities
    $_.ControllerStatus           - controller overall status
    $_.Defaults                   - controller defaults
    $_.Enclosures                 - information about controller enclosures
    $_.EnterpriseKeymanagement    - enterprise key management information
    $_.HighAvailability           - HA info.
    $_.HwCfg                      - information about controller hardware config
    $_.PendingFlash               - information about controller pending flash info
    $_.PhysicalDrives             - information about controller physical drives
    $_.Raw                        - Raw sections extracted by this script + the output from
                                    StorCLI in its raw form (basically the file/variable supplied
                                    to the script.)
    $_.ScheduledTasks             - scheduled task information (Patrol read etc)
    $_.Status                     - controller status as determined by this script.
                                    several subproperties may be available here,
                                    including various Areas being checked for status,
                                    and reports.
    $_.Status.Report              - controller status/error reports in text and HTML form.
    $_.SupportedAdapterOperations - supported adapter operations
    $_.SupportedPDOperations      - supported physical drive operations
    $_.SupportedVDOperations      - supported virtual drive operations
    $_.System                     - system info - block at top of output.
    $_.Topology                   - information about controller topology
    $_.Version                    - version info (firmware/webbios/preboot cli/etc.)
    $_.VirtualDrives              - information about controller virtual drives


    NOTE:
    If any of the above properties cannot be populated, because information is missing from
    the supplied StorCLI output, they will be assigned the value $null

.EXAMPLE
    Using the same file, you run this command:

    $StorCLI = .\Get-StorCLIStatus.ps1 -Path Storcli.txt -StatusLogFile "StorCLI_status.log" -PruneStatusLogDate (Get-Date).AddDays(-730) -LogStatusReportOnError

    - Store status in $StorCLI
    - Log status to file "StorCLI_status.log"
    - Log Error report to status file if the controller is in error state
    - Prune status log for any lines older than 730 days.

.EXAMPLE
    .\Get-StorCLIStatus.ps1 -Path Storcli.txt -CheckStatus -ConvertFromUTCTime -SendMailWithReport -SMTPHost "smtp.myhost.com" -SMTPPort 25 -From @{"bofh@mydomain.com" = "BOFH: BestServer01 - Status Notifier"} -Recipient "myemail@mydomain.com" -Username "myemail@mydomain.com" -Password "Passw0rd123" -ReportHostname "BestServer01"

    - Check status of the raid controller, based on contents in Storcli.txt
    - Use the hostname BestServer01 for the report.
    - Time is converted from UTC time to local time
    - Always send a Status report via mail.
      - If there is any errors detected, this mail will convert to an Error report.
      - Mails will be sent as HTML
      - Full Status / Error reports (if error) will be attached as HTML files.
      - Send mail to myemail@mydomain.com
      - Use the SMTP server smtp.myhost.com:25
      - Authenticate as myemail@mydomain.com:Passw0rd

.EXAMPLE
    .\Get-StorCLIStatus.ps1 -Path Storcli.txt -CheckStatus -ConvertFromUTCTime -SendMailOnError -SendMailAsText -SMTPHost "smtp.myhost.com" -SMTPPort 25 -From @{"bofh@mydomain.com" = "BOFH: BestServer01 - Status Notifier"} -Recipient "myemail@mydomain.com" -Username "myemail@mydomain.com" -Password "Passw0rd123" -ReportHostname "BestServer01" -DataLogFile "StorCLI_data.log" -StatusLogFile "StorCLI_status.log" -PruneDataLog -PruneStatusLogDate (Get-Date).AddDays(-730) -LogStatusReportOnError

    - Check status of the raid controller, based on contents in Storcli.txt
    - Use the hostname BestServer01 for the report.
    - Time is converted from UTC time to local time
    - Send error report via mail, if errors are detected.
      - Mail will be sent as text.
      - Full Status / Error reports (if error) will be attached as HTML files.
      - Send mail to myemail@mydomain.com
      - Use the SMTP server smtp.myhost.com:25
      - Authenticate as myemail@mydomain.com:Passw0rd
    - Log status to file "StorCLI_status.log"
    - Log dataset to file "StorCLI_data.log"
    - Log Error report to status file if the controller is in error state
    - Prune status log for any lines older than 730 days.
    - Prune data log for any lines older than 365 days. (default)

.OUTPUTS
    A Powershell custom object, containing all or part of:
    
    - Configuration present in the StorCLI output supplied.
    - Status present in the StorCLI output supplied.
    - Status report in text and HTML form
    - Error report in text and HTML form

    OR

    Textual status indicating the current state of the Raid Controller, and wether
    or not a status/error report was sent by mail, depending on parameters supplied.


.NOTES
    Author.: Kenneth Nielsen (sharzas @ GitHub.com)
    Version: 1.0

.LINK
    https://github.com/sharzas/Powershell-Get-StorCLIStatus
#>

[CmdLetBinding(DefaultParameterSetName = 'File')]

Param (
    [Parameter(ParameterSetName = 'Text', Position = 1)]
    [Parameter(ParameterSetName = 'CheckStatus')]
    $StorCLIOutput,

    [Parameter(ParameterSetName = 'File', Position = 1)]
    [Parameter(ParameterSetName = 'CheckStatus')]
    $Path,
        
    [Parameter(ParameterSetName = 'CheckStatus')]
    [switch]$CheckStatus = $false,

    [Parameter()]
    [switch]$ConvertFromUTCTime = $false,

    [Parameter()]
    $DataLogFile,

    [Parameter(ParameterSetName = 'CheckStatus')]
    [switch]$EnableSSL = $false,

    [Parameter(ParameterSetName = 'CheckStatus')]
    $From,
    
    [Parameter()]
    [switch]$LogFullStatusReport = $false,

    [Parameter()]
    [switch]$LogStatusReportOnError = $false,

    [Parameter(ParameterSetName = 'CheckStatus')]
    $Password = $null,

    [Parameter()]
    [switch]$PruneDataLog = $false,

    [Parameter()]
    [DateTime]$PruneDataLogBefore,

    [Parameter()]
    [DateTime]$PruneStatusLogDate = $null,

    [Parameter(ParameterSetName = 'CheckStatus')]
    $Recipient,

    [Parameter()]
    $ReportHostname,

    [Parameter(ParameterSetName = 'CheckStatus')]
    [switch]$SendMailAsText = $false,

    [Parameter(ParameterSetName = 'CheckStatus')]
    [switch]$SendMailWithReport = $false,

    [Parameter(ParameterSetName = 'CheckStatus')]
    [switch]$SendMailOnError = $false,

    [Parameter(ParameterSetName = 'CheckStatus')]
    [string]$SMTPHost,

    [Parameter(ParameterSetName = 'CheckStatus')]
    [Int32]$SMTPPort = 25,

    [Parameter()]
    $StatusLogFile = $null,

    [Parameter(ParameterSetName = 'CheckStatus')]
    [string]$Subject,

    [Parameter()]
    [string]$TimeStampFormat = "dd-MM-yyyy HH:mm:ss",

    [Parameter(ParameterSetName = 'CheckStatus')]
    [string]$Username = ""

)


function ConvertFrom-StorCLIOutput
{
    <#
    .SYNOPSIS
        Convert textual output from LSI StorCLI to a Powershell custom object

    .DESCRIPTION
        Find all sections in LSI StorCLI textual output, and add the parsed contents of that
        section to a Powershell custom object, as a property.
        
        Raw contents will be added to a .Raw property, and each extracted section in
        raw form, will be added as a subproperty to the .Raw property.

        Additionally Status checks will be done, and added to a .Status property.

        Note:
        For various reasons, the property containing the parsed "Status" section of StorCLI 
        textual output, will be renamed to .ControllerStatus on the output object.

        .Status is reserved for recording the status checks of the Raid Controller, as well
        as the Report / Error report.

    .PARAMETER ConvertFromUTCTime
        Convert Controller/System time in StorCLI output from UTC time to Local time. 
        Useful for ESXi server configurations, which are always running in UTC time zone.

    .PARAMETER Path
        Path of text file containing output from StorCLI. 
        
        -StorCLIOutput and -Path is mutually exclusive

    .PARAMETER ReportHostname
        This is the hostname attached to the output and the reports.
        
        This parameter is introduced, because the computer where this function is run, isn't
        neccessarily the computer where the raid controller is installed. Using this 
        parameter it is possible to identify the actual host where the raid controller is
        installed.

    .PARAMETER StorCLIOutput
        This a variable containing the textual output from LSI StorCLI

        It must be one of the following:
        
        - A string which can be split using "Newline" (Character Code 10)
        - An Array
        - A PSCustomObject (in which case it will be returned unmodified, under the assumption
                            it is StorCLIOutput that has already been converted)

        -StorCLIOutput and -Path is mutually exclusive

    .EXAMPLE
        Storcli.txt file contains the output from running ./storcli /c0 show all" on
        an ESXi system - note below output is truncated as applicable to preserve space.

        --------- [SNIP] --------
        Generating detailed summary of the adapter, it may take a while to complete.

        CLI Version = 007.1211.0000.0000 Nov 07, 2019
        Operating system = VMkernel 6.7.0
        ...

        Basics :
        ======
        Controller = 0
        ....

        Version :
        =======
        Firmware Package Build = 12.15.0-0239
        ....

        Bus :
        ===
        Vendor Id = 0x1000
        ....

        Pending Images in Flash :
        =======================
        Image name = No pending images

        Status :
        ======
        Controller Status = Optimal
        ....

        Supported Adapter Operations :
        ============================
        Rebuild Rate = Yes
        ....

        Enterprise Key management :
        =========================
        Capability = Supported
        ...

        Supported PD Operations :
        =======================
        Force Online = Yes
        ....

        Supported VD Operations :
        =======================
        Read Policy = Yes
        ....

        HwCfg :
        =====
        ChipRevision =  B4
        ....

        Policies Table :
        ==============
        ------------------------------------------------
        Policy                          Current Default 
        ------------------------------------------------
        Predictive Fail Poll Interval   300 sec
        ....
        ------------------------------------------------

        Flush Time(Default) = 4s
        ....

        Boot :
        ====
        BIOS Enumerate VDs = 1
        ...

        High Availability :
        =================
        Topology Type = None
        ...

        Defaults :
        ========
        Phy Polarity = 0
        ....

        Capabilities :
        ============
        Supported Drives = SAS, SATA
        ....

        Scheduled Tasks :
        ===============
        Consistency Check Reoccurrence = 168 hrs
        ....

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

        VD LIST :
        =======
        -----------------------------------------------------------------------
        DG/VD TYPE  State Access Consist Cache Cac sCC       Size Name         
        -----------------------------------------------------------------------
        0/0   RAID1 Optl  RW     Yes     NRWBD -   ON  371.597 GB DS002_R1_SSD 
        -----------------------------------------------------------------------

        PD LIST :
        =======
        -------------------------------------------------------------------------------------
        EID:Slt DID State DG       Size Intf Med SED PI SeSz Model                   Sp Type 
        -------------------------------------------------------------------------------------
        32:20    36 Onln   0 371.597 GB SATA SSD N   N  512B INTEL SSDSC2BA400G3E    U  -    
        32:21    37 Onln   0 371.597 GB SATA SSD N   N  512B INTEL SSDSC2BA400G3E    U  -    
        -------------------------------------------------------------------------------------

        Enclosure LIST :
        ==============
        -------------------------------------------------------------------------------
        EID State Slots PD PS Fans TSs Alms SIM Port#         ProdID    VendorSpecific 
        -------------------------------------------------------------------------------
        32 OK       24  4  0    0   0    0   0 Port 4 - 7 x4 RES2SV240 x36-254.13.0.0 
        252 OK        8  0  0    0   0    0   1 -             SGPIO                    
        -------------------------------------------------------------------------------

        BBU_Info :
        ========
        -----------------------------------------------------------------------
        Model  State   RetentionTime Temp Mode MfgDate    Next Learn           
        -----------------------------------------------------------------------
        iBBU08 Optimal 48 hours +    27C  4    2011/12/14 2021/01/29  15:47:51 
        -----------------------------------------------------------------------

        Mode 4: 48+ Hrs retention with a non-transparent learn cycle 
                and balanced service life.
        --------- [SNAP] --------



        You run this command: $StorCLI = .\Get-StorCLIStatus.ps1 -StorCLIOutput (Get-Content Storcli.txt)

        $StorCLI will have the following properties:
        

        .Basics                     - basic information, including model/system time/etc.
        .Boot                       - controller boot info
        .Bus                        - bus information (e.g. PCI-E/SAS/SATA)
        .Capabilities               - information about controller capabilities
        .ControllerStatus           - controller overall status
        .Defaults                   - controller defaults
        .Enclosures                 - information about controller enclosures
        .EnterpriseKeymanagement    - enterprise key management information
        .HighAvailability           - HA info.
        .HwCfg                      - information about controller hardware config
        .PendingFlash               - information about controller pending flash info
        .PhysicalDrives             - information about controller physical drives
        .Raw                        - Raw sections extracted by this script + the output from
                                      StorCLI in its raw form (basically the file/variable supplied
                                      to the script.)
        .ScheduledTasks             - scheduled task information (Patrol read etc)
        .Status                     - controller status as determined by this script.
                                      several subproperties may be available here,
                                      including various Areas being checked for status,
                                      and reports.
        .Status.Report              - controller status/error reports in text and HTML form.
        .SupportedAdapterOperations - supported adapter operations
        .SupportedPDOperations      - supported physical drive operations
        .SupportedVDOperations      - supported virtual drive operations
        .System                     - system info - block at top of output.
        .Topology                   - information about controller topology
        .Version                    - version info (firmware/webbios/preboot cli/etc.)
        .VirtualDrives              - information about controller virtual drives


        NOTE:
        If any of the above properties cannot be populated, because information is missing from
        the supplied StorCLI output, they will be assigned the value $null


    .OUTPUTS
        Custom object containing a set of properties, matching the sections present in
        -StorCLIOutput, containing the lines of text present in each relevant section, along
        with the parsed output of this text.

    .NOTES
        Spaces are stripped from the raw Section names. Properties will be named the same as the
        sections without spaces.

        Author.: Kenneth Nielsen (sharzas @ GitHub.com)
        Version: 1.0

    .LINK
        https://github.com/sharzas/Powershell-Get-StorCLIStatus
        
    #>
    [CmdLetBinding(DefaultParameterSetName = 'File')]
    Param (
        [Parameter(Mandatory = $true, ParameterSetName = 'Text')]
        $StorCLIOutput,
    
        [Parameter(Mandatory = $true, ParameterSetName = 'File')]
        $Path,
    
        [Parameter()]
        [switch]$ConvertFromUTCTime = $false,

        [Parameter()]
        $ReportHostname = ""
    )





    #region Embedded helper functions

    ##########################################
    ##########################################
    ####                                  ####
    #### BEGIN: Embedded helper functions ####
    ####                                  ####
    ##########################################
    ##########################################

    function Get-StorCLIEnclosureList
    {
        <#
        .SYNOPSIS
            Objectify Controller Enclosure information from the raw text part of the
            parsed StorCLI textual output.

        .DESCRIPTION
            Objectify Controller Enclosure information from the raw text part of the
            parsed StorCLI textual output.

            NOTE:
            This is an internal helper function. It should only be called from
            ConvertFrom-StorCLIOutput

        .PARAMETER StorCLIOutput
            This is the variable containing the raw parts of the parsed StorCLI 
            textual output.

            This would be the .Raw property.

        .OUTPUTS
            A collection of Powershell custom objects, containing the Enclosure information
            present in the StorCLI output supplied.

        .NOTES
            Author.: Kenneth Nielsen (sharzas @ GitHub.com)
            Version: 1.0

            This is an internal helper function. It should only be called from
            ConvertFrom-StorCLIOutput

        .LINK
            https://github.com/sharzas/Powershell-Get-StorCLIStatus        
        #>

        [CmdLetBinding()]

        Param (
            [Parameter(Mandatory)]
            [PSCustomObject]
            $StorCLIOutput
        )

        Write-Verbose 'Get-StorCLIEnclosureList(): Invoked.'
        
        # RegExp Pattern used to match the header of the Enclosure list fixed width
        # table in the StorCLI output.
        #
        # EID State Slots PD PS Fans TSs Alms SIM Port#         ProdID    VendorSpecific 
        # -------------------------------------------------------------------------------
        # 
        $Pattern = "(^.*?EID)\s+(State\s+)(Slots)\s+(PD\s+)(PS\s+)(Fans\s+)(TSs\s+)(Alms\s+)(SIM\s+)(Port#\s+)(ProdID\s+)(VendorSpecific.*)"

        <#
        # Convert StorCLIOutput to object
        $Sections = ConvertFrom-StorCLIOutput -InputObject $StorCLIOutput

        if ($null -eq $Sections) {
            # nothing returned from ConvertFrom-StorCLIOutput, either the data
            # is invalid, or something else is wrong.

            Write-Verbose 'Get-StorCLIEnclosureList(): Nothing returned from ConvertFrom-StorCLIOutput - maybe not output from StorCLI ?'
            return $null
        }
        #>

        if ($null -eq ($StorCLIOutput|Get-Member -Name EnclosureLIST)) {
            # no .EnclosureLIST section found, so that data was most likely not present in the
            # output from StorCLI

            Write-Verbose 'Get-StorCLIEnclosureList(): no .EnclosureLIST section found, so that data was most likely not present in the StorCLI output.'
            return $null
        }

        $Enclosures = ConvertFrom-FixedWidthTable -InputObject $StorCLIOutput.EnclosureLIST -SkipLinesAfterHeader 1 -HeaderPattern $Pattern -EndPattern "^-------"

        if ($null -eq $Enclosures) {
            # could not convert the EnclosureLIST section from a FixedWidthTable to a collection of objects.

            Write-Verbose 'Get-StorCLIEnclosureList(): could not convert the EnclosureLIST section from a FixedWidthTable to a collection of objects.'
            return $null
        }


        $Enclosures|ForEach-Object {
            [PSCustomObject]@{
                EnclosureId             = $_.EID
                State                   = $_.State
                Slots                   = $_.Slots
                PhysicalDrives          = $_.PD
                PowerSupplys            = $_.PS
                Fans                    = $_.Fans
                TemperatureSensors      = $_.TSs
                Alarms                  = $_.Alms
                SIMCount                = $_.SIM
                Port                    = $_.'Port#'
                ProductID               = $_.ProdID
                VendorSpecific          = $_.VendorSpecific
            }
        }
    } # function Get-StorCLIEnclosureList












    function Get-StorCLIPhysicalDriveList
    {
        <#
        .SYNOPSIS
            Objectify Controller Physical Drive information from the raw text part of the
            parsed StorCLI textual output.

        .DESCRIPTION
            Objectify Controller Physical Drive information from the raw text part of the
            parsed StorCLI textual output.

            Supports various output variations - depending on the query parameters issued
            to StorCLI

            NOTE:
            This is an internal helper function. It should only be called from
            ConvertFrom-StorCLIOutput

        .PARAMETER StorCLIOutput
            This is the variable containing the raw parts of the parsed StorCLI 
            textual output.

            This would be the .Raw property.

        .OUTPUTS
            A collection of Powershell custom objects, containing the Physical Drive information
            present in the StorCLI output supplied.

        .NOTES
            Author.: Kenneth Nielsen (sharzas @ GitHub.com)
            Version: 1.0

            This is an internal helper function. It should only be called from
            ConvertFrom-StorCLIOutput

        .LINK
            https://github.com/sharzas/Powershell-Get-StorCLIStatus        
        #>

        [CmdLetBinding()]

        Param (
            [Parameter(Mandatory)]
            [PSCustomObject]
            $StorCLIOutput
        )

        Write-Verbose 'Get-StorCLIPhysicalDriveList(): Invoked.'
        
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


        # depending on the parameters issued to StorCLI, there may be either a .PDLIST or .DGDriveLIST section
        # containing information about physical drives on the controller.
        #
        if ($null -ne ($StorCLIOutput|Get-Member -Name "PDLIST")) {
            Write-Verbose 'Get-StorCLIPhysicalDriveList(): .PDLIST section found in output - using that'

            $Section = $StorCLIOutput.PDLIST
        } elseif ($null -ne ($StorCLIOutput|Get-Member -Name "DGDriveLIST")) {
            Write-Verbose 'Get-StorCLIPhysicalDriveList(): .DGDriveLIST section found in output - using that'

            $Section = $StorCLIOutput.DGDriveLIST
        } else {
            # no .DGDriveLIST / .PDLIST section found, so that data was most likely not present in the
            # output from StorCLI

            Write-Verbose 'Get-StorCLIPhysicalDriveList(): no .DGDriveLIST/.PDLIST section found, so that data was most likely not present in the StorCLI output.'
            return $null
        }


        $Section|ForEach-Object {
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
    } # function Get-StorCLIPhysicalDriveList









    function Get-StorCLIState
    {
        <#
        .SYNOPSIS
            Enumerates controller status from various sections if they are present in
            the StorCLI output object.

        .DESCRIPTION
            Enumerates controller status from various sections if they are present in
            the StorCLI output object.

            Will run through a predefined list of areas in the parsed textual output
            from StorCLI, as presented by ConvertFrom-StorCLIOutput, and evaluate
            the status of that area.

            For each area a status property will be added, containing .Good and .Bad
            entries in that area - e.g. Good can be online physical drives, where bad
            is offline drives.

            A Status/Error report will be build from that information in both text and
            HTML form, and attached as a .Report property.

            NOTE:
            This is an internal helper function. It should only be called from
            ConvertFrom-StorCLIOutput

        .PARAMETER StorCLIOutput
            This is the variable containing the PSCustomObject parsed StorCLI 
            textual output.

            This would be the entire PSCustomObject as made by ConvertFrom-StorCLIOutput.
            

        .OUTPUTS
            A collection of Powershell custom objects, containing the Physical Drive information
            present in the StorCLI output supplied.

        .NOTES
            Author.: Kenneth Nielsen (sharzas @ GitHub.com)
            Version: 1.0

            This is an internal helper function. It should only be called from
            ConvertFrom-StorCLIOutput

        .LINK
            https://github.com/sharzas/Powershell-Get-StorCLIStatus        
        #>

        [CmdLetBinding()]

        Param (
            [Parameter()]
            $StorCLIOutput,

            [Parameter()]
            [switch]$ConvertFromUTCTime = $false,

            [Parameter()]
            $ReportHostname = ""
        )

        Write-Verbose "Get-StorCLIState(): Invoked."

        $StorCLI = ConvertFrom-StorCLIOutput -StorCLIOutput $StorCLIOutput -ConvertFromUTCTime:$ConvertFromUTCTime
        
        if ($null -eq $StorCLI) {
            Write-Warning "Get-StorCLIState(): Could not retrieve the StorCLI object!"
            Write-Warning ""
            return $null
        }

        if ($ReportHostname -eq "") {
            $Origin = ('<span style="color: red;font-weight: bold;">System where the report was run (not neccessarily the system where the controller is installed)</span>')
            $ReportHostname = Get-WmiObject Win32_ComputerSystem|ForEach-Object {"$($_.Domain)\$($_.Name)"}
        } else {
            $Origin = ('<span style="color: green;font-weight: bold;">System Where Controller is installed</span>')
            
        }

        if ($null -ne $StorCLI.Basics.'Current System Date/time') {
            # a time is present in the StorCLI output, we use that to timestamp the current state.
            $StateTime = $StorCLI.Basics.'Current System Date/time'
        } else {
            # no time is present in the StorCLI output, use current time to timestamp the current state.
            $StateTime = Get-Date
        }


        $BadStates = @()

        $GoodStates = @(
            "Dedicated Hot Spare",
            "Global Hot Spare",
            "OK",
            "Online",
            "Optimal",
            "Success",
            "Unconfigured Good"
        )

        <#
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
        #>

        $Areas = @{
            "Enclosures"        = [PSCustomObject]@{
                                    Description = "Enclosures"
                                    Format = "Table"
                                    Property = "State"
                                }
            "PhysicalDrives"    = [PSCustomObject]@{
                                    Description = "Physical Drives"
                                    Format = "Table"
                                    Property = "State"
                                }
            "ControllerStatus"     = [PSCustomObject]@{
                                    Description = "Raid Controller Status"
                                    Format = "List"
                                    Property = "Controller Status"
                                }
            "System"            = [PSCustomObject]@{
                                    Description = "System Information"
                                    Format = "List"
                                    Property = "Status"
                                }
            "Topology"          = [PSCustomObject]@{
                                    Description = "Raid Controller Topology"
                                    Format = "Table"
                                    Property = "State"
                                }
            "VirtualDrives"     = [PSCustomObject]@{
                                    Description = "Virtual Drives"
                                    Format = "Table"
                                    Property = "State"
                                }
        }

        $StatusObject = [PSCustomObject]@{
            Areas = New-Object PSCustomObject
            Report = New-Object PSCustomObject
        }


        $ErrorReport = @()
        $ErrorReportHTML = @(
            ('<html>'),
            ('    <body>'),
            ('        <p>'),
            ('            <h1>Raid Controller reported one or more errors.</h1>'),
            ('            <h2><span style="text-decoration: underline">System Information.</span></h2>'),
            ('            <span style="font-weight: bold;">Date: </span>{0}<br>' -f $StateTime),
            ('            <span style="font-weight: bold;">System Hostname: </span>{0}<br>' -f $ReportHostname),
            ('            <span style="font-weight: bold;">Hostname Origin: </span>{0}' -f $Origin),
            ('        </p>'),
            ('        <p style="font-family:''Lucida Console'',monospace; white-space:pre">')
        )

        $Report = @()
        $ReportHTML = @(
            ('<html>'),
            ('    <body>'),
            ('        <p>'),
            ('            <h1>Raid Controller full status report.</h1>'),
            ('            <h2><span style="text-decoration: underline">System Information.</span></h2>'),
            ('            <span style="font-weight: bold;">Date: </span>{0}<br>' -f $StateTime),
            ('            <span style="font-weight: bold;">System Hostname: </span>{0}<br>' -f $ReportHostname),
            ('            <span style="font-weight: bold;">Hostname Origin: </span>{0}' -f $Origin),
            ('        </p>'),
            ('        <p style="font-family:''Lucida Console'',monospace; white-space:pre">')
        )

        if ($null -ne $StorCLI.System) {
            $ErrorReportHTML += @($StorCLI.System|Format-List *|Out-String -Stream -Width 4096|ForEach-Object {$_.Trim()}|Where-Object {$_})
            $ReportHTML += @($StorCLI.System|Format-List *|Out-String -Stream -Width 4096|ForEach-Object {$_.Trim()}|Where-Object {$_})
        }

        $AreasInErrorState = @()

        foreach ($Area in $Areas.Keys) {
            if ($null -ne $StorCLI."$Area") {
                # Area information present - lets check status
                Write-Verbose ('Get-StorCLIState(): Area present [YES] - [{0}] - recording status: "{1}"."{2}"' -f $Areas[$Area].Format, $Area, "$($Areas[$Area].Property)")

                $StatusObject.Areas|Add-Member -MemberType NoteProperty -Name $Area -Value ([PSCustomObject]@{Good = $null; Bad = $null})

                $StatusObject.Areas."$Area".Good = $StorCLI."$Area"|Where-Object {$GoodStates -contains $_."$($Areas[$Area].Property)"}|Select-Object @{n="Area"; e={$Area}},*
                $StatusObject.Areas."$Area".Bad  = $StorCLI."$Area"|Where-Object {$GoodStates -notcontains $_."$($Areas[$Area].Property)"}|Select-Object @{n="Area"; e={$Area}},*

                # any states not present in $GoodStates, must by definition be bad, so record them.
                $BadStates += @($StatusObject.Areas."$Area".Bad."$($Areas[$Area].Property)"|Where-Object {$_})

                $Report += @(
                    '','',
                    ('Report for Area "{0}"' -f $Areas[$Area].Description),
                    '================================================================='
                )

                $ReportHTML += @(
                    '','',
                    ('<span style="font-weight: bold;">Report for Area "{0}"</span>' -f $Areas[$Area].Description),
                    '<span style="font-weight: bold;">=================================================================</span>'
                )


                switch ($Areas[$Area].Format) {
                    "list" {
                        $Report += @($StorCLI."$Area"|Select-Object @{n="Area"; e={$Areas[$Area].Description}},*|Format-List -Property *|Out-String -Stream -Width 4096|ForEach-Object {$_.Trim()})
                        $ReportHTML += @($StorCLI."$Area"|Select-Object @{n="Area"; e={$Areas[$Area].Description}},*|Format-List -Property *|Out-String -Stream -Width 4096|ForEach-Object {$_.Trim()})
                        break
                    }
                    "table" {
                        $Report += @($StorCLI."$Area"|Select-Object @{n="Area"; e={$Areas[$Area].Description}},*|Format-Table -Property * -AutoSize|Out-String -Stream -Width 4096|ForEach-Object {$_.Trim()})
                        $ReportHTML += @($StorCLI."$Area"|Select-Object @{n="Area"; e={$Areas[$Area].Description}},*|Format-Table -Property * -AutoSize|Out-String -Stream -Width 4096|ForEach-Object {$_.Trim()})
                        break
                    }
                    Default {
                        Write-Warning ('Get-StorCLIState(): Invalid Area Format definition "{0}": "{1}"' -f $Area, "$($Areas[$Area].Format)")
                    }
                }


                if ($null -ne $StatusObject.Areas."$Area".Bad) {
                    # at least one element in non-OK status
                    $ErrorReport += @(
                        '','',
                        ('Error report for Area "{0}"' -f $Areas[$Area].Description),
                        '================================================================='
                    )

                    $ErrorReportHTML += @(
                        '','',
                        ('<span style="font-weight: bold;">Error report for Area "{0}"</span>' -f $Areas[$Area].Description),
                        '<span style="font-weight: bold;">=================================================================</span>'
                    )

                    Write-Verbose ('Get-StorCLIState(): Adding Area "{0}" to ERROR Report using format: "{1}"' -f $Area, "$($Areas[$Area].Format)")

                    switch ($Areas[$Area].Format) {
                        "list" {
                            $ErrorReport += @($StatusObject.Areas."$Area".Bad|Format-List -Property *|Out-String -Stream -Width 4096|ForEach-Object {$_.Trim()})
                            $ErrorReportHTML += @($StatusObject.Areas."$Area".Bad|Format-List -Property *|Out-String -Stream -Width 4096|ForEach-Object {$_.Trim()})
                            break
                        }
                        "table" {
                            $ErrorReport += @($StatusObject.Areas."$Area".Bad|Format-Table -Property * -AutoSize|Out-String -Stream -Width 4096|ForEach-Object {$_.Trim()})
                            $ErrorReportHTML += @($StatusObject.Areas."$Area".Bad|Format-Table -Property * -AutoSize|Out-String -Stream -Width 4096|ForEach-Object {$_.Trim()})
                            break
                        }
                        Default {
                            Write-Warning ('Get-StorCLIState(): Invalid Area Format definition "{0}": "{1}"' -f $Area, "$($Areas[$Area].Format)")
                        }
                    }

                    $AreasInErrorState += $Area
                }
            } else {
                # Area not present.
                Write-Verbose ('Get-StorCLIState(): Area present [NO]  - recording status: "{0}"' -f $Area)
            }
        }


        # all done - time to process the reports.
        #

        # build replace pattern to use for the HTML reports. We will build RegExp patterns, which consist of
        # all Bad/Goodstates concatenated into a search group - e.g. (bad1|bad2|bad3) and (good1|good2|good3)
        # - this way its easy for us to replace in only 1 iteration using Powershells -replace operator.
        $BadStatesPattern = ('({0})' -f ($BadStates -join "|"))
        $GoodStatesPattern = ('({0})' -f ($GoodStates -join "|"))

        Write-Verbose ('Get-StorCLIState(): Bad States RegExp Replace Pattern.: "{0}"' -f $BadStatesPattern)
        Write-Verbose ('Get-StorCLIState(): Good States RegExp Replace Pattern: "{0}"' -f $GoodStatesPattern)


        if ($Report.Count -gt 0) {
            # Some statuses was enumerated, attach report to status object.
            $ReportHTML += @(
                "        </p>",
                "    </body>",
                "</html>"
                )

            # replace all bad/good states text with red/green bolded text, by adding the relevant HTML tags.
            # - this is a bit shotgun, and we may potentially highlight text which doesn't describe a state
            #   by doing a simple replace operation - but it was the easiest way to get the job done.
            if ($BadStates.Count -gt 0) {
                # only attempt the replace operation if there is actually recorded some bad states.
                $ReportHTML = $ReportHTML -replace $BadStatesPattern, '<span style="color: red;font-weight: bold;">$1</span>'
            }

            $ReportHTML = $ReportHTML -replace $GoodStatesPattern, '<span style="color: green;font-weight: bold;">$1</span>'

            $StatusObject.Report|Add-Member -MemberType NoteProperty -Name Full -Value $Report
            $StatusObject.Report|Add-Member -MemberType NoteProperty -Name FullHTML -Value $ReportHTML
        }

        if ($ErrorReport.Count -gt 0) {
            # Errors detected, attach error report to status object.
            $ErrorReportHTML += @(
                "        </p>",
                "    </body>",
                "</html>"
                )

            # replace all bad states text with red bolded text, by adding the relevant HTML tags.
            # - this is a bit shotgun, and we may potentially highlight text which doesn't describe a state
            #   by doing a simple replace operation - but it was the easiest way to get the job done.
            $ErrorReportHTML = $ErrorReportHTML -replace $BadStatesPattern, '<span style="color: red;font-weight: bold;">$1</span>'

            $StatusObject.Report|Add-Member -MemberType NoteProperty -Name Error -Value $ErrorReport
            $StatusObject.Report|Add-Member -MemberType NoteProperty -Name ErrorHTML -Value $ErrorReportHTML
            $StatusObject|Add-Member -MemberType NoteProperty -Name AreasInErrorState -Value $AreasInErrorState
            $StatusObject|Add-Member -MemberType NoteProperty -Name ReportHostname -Value $ReportHostname
            $StatusObject|Add-Member -MemberType NoteProperty -Name State -Value "Error"
            $StatusObject|Add-Member -MemberType NoteProperty -Name StateTime -Value $StateTime
        } else {
            $StatusObject|Add-Member -MemberType NoteProperty -Name ReportHostname -Value $ReportHostname
            $StatusObject|Add-Member -MemberType NoteProperty -Name State -Value "OK"
            $StatusObject|Add-Member -MemberType NoteProperty -Name StateTime -Value $StateTime
        }

        if (($Report.Count -eq 0) -and ($ErrorReport.Count -eq 0)) {
            # Nothing was enumerated, so return null
            Write-Verbose "Get-StorCLIState(): Nothing was enumerated, returning null"

            return $null
        } else {
            # Something was enumerated, so return the status object.
            Write-Verbose "Get-StorCLIState(): Something was enumerated, returning StatusObject"

            return $StatusObject
        }
    } # function Get-StorCLIState




    function Get-StorCLITopology
    {
        <#
        .SYNOPSIS
            Objectify Controller Topology information from the raw text part of the
            parsed StorCLI textual output.

        .DESCRIPTION
            Objectify Controller Topology information from the raw text part of the
            parsed StorCLI textual output.

            NOTE:
            This is an internal helper function. It should only be called from
            ConvertFrom-StorCLIOutput

        .PARAMETER StorCLIOutput
            This is the variable containing the raw parts of the parsed StorCLI 
            textual output.

            This would be the .Raw property.

        .OUTPUTS
            A collection of Powershell custom objects, containing the Controller Topology information
            present in the StorCLI output supplied.

        .NOTES
            Author.: Kenneth Nielsen (sharzas @ GitHub.com)
            Version: 1.0

            This is an internal helper function. It should only be called from
            ConvertFrom-StorCLIOutput

        .LINK
            https://github.com/sharzas/Powershell-Get-StorCLIStatus    
        #>    

        [CmdLetBinding()]

        Param (
            [Parameter(Mandatory)]
            [PSCustomObject]
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

        if ($null -eq ($StorCLIOutput|Get-Member -Name Topology)) {
            # no .Topology section found, so that data was most likely not present in the
            # output from StorCLI

            Write-Verbose 'Get-StorCLITopology(): no .Topology section found, so that data was most likely not present in the StorCLI output.'
            return $null
        }

        $Topology = ConvertFrom-FixedWidthTable -InputObject $StorCLIOutput.Topology -SkipLinesAfterHeader 1 -HeaderPattern "(^.*?DG)\s+(Arr\s+)(Row\s+)(EID:Slot\s+)(DID\s+)(Type\s+)(State\s+)(BT)\s(\s+Size)\s+(PDC\s+)(PI\s+)(SED\s+)(DS3\s+)(FSpace\s+)(TR.*?$)" -EndPattern "^-------"

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
        <#
        .SYNOPSIS
            Objectify Controller Virtual Drive information from the raw text part of the
            parsed StorCLI textual output.

        .DESCRIPTION
            Objectify Controller Virtual Drive information from the raw text part of the
            parsed StorCLI textual output.

            NOTE:
            This is an internal helper function. It should only be called from
            ConvertFrom-StorCLIOutput

        .PARAMETER StorCLIOutput
            This is the variable containing the raw parts of the parsed StorCLI 
            textual output.

            This would be the .Raw property.

        .OUTPUTS
            A collection of Powershell custom objects, containing the Virtual Drive information
            present in the StorCLI output supplied.

        .NOTES
            Author.: Kenneth Nielsen (sharzas @ GitHub.com)
            Version: 1.0

            This is an internal helper function. It should only be called from
            ConvertFrom-StorCLIOutput

        .LINK
            https://github.com/sharzas/Powershell-Get-StorCLIStatus    
        #>

        [CmdLetBinding()]

        Param (
            [Parameter(Mandatory)]
            [PSCustomObject]
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

        if ($null -eq ($StorCLIOutput|Get-Member -Name VDLIST)) {
            # no .Topology section found, so that data was most likely not present in the
            # output from StorCLI

            Write-Verbose 'Get-StorCLIVirtualDriveList(): no .Topology section found, so that data was most likely not present in the StorCLI output.'
            return $null
        }

        $StorCLIOutput.VDLIST|ForEach-Object {
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


    ########################################
    ########################################
    ####                                ####
    #### END: Embedded helper functions ####
    ####                                ####
    ########################################
    ########################################

    #endregion Embedded helper functions



    Write-Verbose ('ConvertFrom-StorCLIOutput(): Invoked.')

    if ($PSBoundParameters.ContainsKey("Path")) {
        # -Path specified - so lets load the data assuming its a text file.

        try {
            Write-Verbose ('ConvertFrom-StorCLIOutput(): Attempting to read file specified in -Path: "{0}"' -f $Path)
            $StorCLIOutput = Get-Content -Path $Path -ErrorAction Stop
        } catch {
            Write-Verbose ('ConvertFrom-StorCLIOutput(): Failed to read file specified in -Path: "{0}"' -f $Path)
            $PSCmdlet.ThrowTerminatingError((New-ErrorRecord -baseObject $_))
        }
    }


    if ($StorCLIOutput -is [PSCustomObject]) {
        # this is already a PSCustomObject, so we assume its a previously
        # converted StorCLIOutput, and will just return it as is.
        Write-Verbose ('ConvertFrom-StorCLIOutput(): StorCLIOutput was already a [PSCustomObject] with {0} properties - will return it as is' -f ($StorCLIObject|Get-Member -MemberType Properties).Count)

        return $StorCLIOutput
    }


    if ($StorCLIOutput -is [string]) {
        # this is a string, but we need an array, so lets attempt to convert it to
        # an array, by splitting the text block by "newline"
        Write-Verbose ('ConvertFrom-StorCLIOutput(): StorCLIOutput is a [string], will convert to [array] by using .Split by newline.')

        $StorCLIOutput = $StorCLIOutput.Split("`n")
    }


    if ($StorCLIOutput -isnot [Array]) {
        # StorCLIOutput is at this stage not an array, but we require an array, so bail.
        Write-Verbose ('ConvertFrom-StorCLIOutput(): StorCLIOutput is NOT an [array], returning null - we need an array.')

        return $null
    }

    $StorCLIOutput = @("System","========") + @($StorCLIOutput)

    # find all section underscores, and grab context with 1 lines to each side.
    $SectionData = $StorCLIOutput|Select-String -Pattern "^==" -Context 1

    # process all found sections, and record line number in the StorCLIOutput array,
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
        Write-Verbose ('ConvertFrom-StorCLIOutput(): No sections found in StorCLIOutput - returning null.')

        return $null
    }


    # loop through sections array, and add end index
    $LastEndIndex = $StorCLIOutput.GetUpperBound(0)

    $Sections = $Sections|Sort-Object -Property StartIndex -Descending|ForEach-Object {
        $_.EndIndex = $LastEndIndex
        $LastEndIndex = $_.StartIndex-3  # -3 because 2 are from the section header, and 1 is to not overlap next section header
        $_
    }|Sort-Object -Property StartIndex

    
    # build return object - .Raw property = full raw content of input object, along with
    # each section in raw format, as extracted by this function. Individual sections in
    # raw format will be attached as subproperties.
    $StorCLIObject = [PSCustomObject]@{
        Basics                      = $null
        Boot                        = $null
        Bus                         = $null
        Capabilities                = $null
        ControllerStatus            = $null
        Defaults                    = $null
        Enclosures                  = $null
        EnterpriseKeymanagement     = $null
        HighAvailability            = $null
        HwCfg                       = $null
        PendingFlash                = $null
        PhysicalDrives              = $null
        ScheduledTasks              = $null
        Status                      = $null
        SupportedAdapterOperations  = $null
        SupportedPDOperations       = $null
        SupportedVDOperations       = $null
        System                      = $null
        Topology                    = $null
        Version                     = $null
        VirtualDrives               = $null
        Raw                         = [PSCustomObject]@{
                                        StorCLIOutput = $StorCLIOutput
                                      }
    }

    # loop through all enumerated sections, and populate an property with their name on the return object.
    # data will be an array with the raw text from that section.
    foreach ($Section in $Sections) {
        $StorCLIObject.Raw|Add-Member -MemberType NoteProperty -Name $Section.Name -Value $StorCLIOutput[$($Section.StartIndex)..$($Section.EndIndex)]
    }


    # populate return object with details about each section. If the sections is not present in the
    # StorCLI output, then the value will be $null
    #
    $StorCLIObject.Basics                       = Get-PropertyValuePairs -InputObject $StorCLIObject.Raw.Basics
    $StorCLIObject.Boot                         = Get-PropertyValuePairs -InputObject $StorCLIObject.Raw.Boot
    $StorCLIObject.Bus                          = Get-PropertyValuePairs -InputObject $StorCLIObject.Raw.Bus
    $StorCLIObject.Capabilities                 = Get-PropertyValuePairs -InputObject $StorCLIObject.Raw.Capabilities
    $StorCLIObject.ControllerStatus             = Get-PropertyValuePairs -InputObject $StorCLIObject.Raw.Status
    $StorCLIObject.Defaults                     = Get-PropertyValuePairs -InputObject $StorCLIObject.Raw.Defaults
    $StorCLIObject.Enclosures                   = Get-StorCLIEnclosureList -StorCLIOutput $StorCLIObject.Raw
    $StorCLIObject.EnterpriseKeymanagement      = Get-PropertyValuePairs -InputObject $StorCLIObject.Raw.EnterpriseKeymanagement
    $StorCLIObject.HighAvailability             = Get-PropertyValuePairs -InputObject $StorCLIObject.Raw.HighAvailability
    $StorCLIObject.HwCfg                        = Get-PropertyValuePairs -InputObject $StorCLIObject.Raw.HwCfg
    $StorCLIObject.PendingFlash                 = Get-PropertyValuePairs -InputObject $StorCLIObject.Raw.PendingImagesinFlash
    $StorCLIObject.PhysicalDrives               = Get-StorCLIPhysicalDriveList -StorCLIOutput $StorCLIObject.Raw
    $StorCLIObject.ScheduledTasks               = Get-PropertyValuePairs -InputObject $StorCLIObject.Raw.ScheduledTasks
    $StorCLIObject.SupportedAdapterOperations   = Get-PropertyValuePairs -InputObject $StorCLIObject.Raw.SupportedAdapterOperations
    $StorCLIObject.SupportedPDOperations        = Get-PropertyValuePairs -InputObject $StorCLIObject.Raw.SupportedPDOperations
    $StorCLIObject.SupportedVDOperations        = Get-PropertyValuePairs -InputObject $StorCLIObject.Raw.SupportedVDOperations
    $StorCLIObject.System                       = Get-PropertyValuePairs -InputObject $StorCLIObject.Raw.System
    $StorCLIObject.Topology                     = Get-StorCLITopology -StorCLIOutput $StorCLIObject.Raw
    $StorCLIObject.Version                      = Get-PropertyValuePairs -InputObject $StorCLIObject.Raw.Version
    $StorCLIObject.VirtualDrives                = Get-StorCLIVirtualDriveList -StorCLIOutput $StorCLIObject.Raw

    # some adjustments
    if ($null -ne $StorCLIObject.Basics) {
        # we want to convert the Controller/System Date/time to a real DateTime value.
        #
        # Note: this value may change, based on culture... I used ParseExact to match
        #       output from ESXi, however your mileage may vary - I've put a Get-Date
        #       in there as well, just in case.
        #
        $TimeFormat = "MM/dd/yyyy, HH:mm:ss"

        Write-Verbose "ConvertFrom-StorCLIOutput(): Local TimeZone information:"
        [System.TimeZoneInfo]::Local|Format-List|Out-String -Stream|ForEach-Object {
            Write-Verbose ('ConvertFrom-StorCLIOutput(): {0}' -f $_)
        }

        if ($null -ne $StorCLIObject.Basics.'Current Controller Date/Time') {
            Write-Verbose "ConvertFrom-StorCLIOutput(): .Basics.'Current Controller Date/Time' found - attempting to convert to [DateTime] data type."
            Write-Verbose ('ConvertFrom-StorCLIOutput(): .Basics.''Current Controller Date/Time'': "{0}"' -f $StorCLIObject.Basics.'Current Controller Date/Time')

            <#
            try {
                $($StorCLIObject.Basics.'Current Controller Date/Time' = Get-Date ($StorCLIObject.Basics.'Current Controller Date/Time') -ErrorAction Stop) *> $null

                Write-Verbose "ConvertFrom-StorCLIOutput(): .Basics.'Current Controller Date/Time' converted to [DateTime] data type using Get-Date."
            } catch {
                Write-Verbose "ConvertFrom-StorCLIOutput(): .Basics.'Current Controller Date/Time' failed conversion using Get-Date, trying [DateTime]::ParseExact"
            #>

            try {
                $($StorCLIObject.Basics.'Current Controller Date/Time' = [Datetime]::ParseExact($StorCLIObject.Basics.'Current Controller Date/Time', $TimeFormat, $null)) *> $null

                Write-Verbose "ConvertFrom-StorCLIOutput(): .Basics.'Current Controller Date/Time' converted to [DateTime] data type using [DateTime]::ParseExact"
            } catch {
                Write-Verbose "ConvertFrom-StorCLIOutput(): .Basics.'Current Controller Date/Time' failed conversion using both Get-Date AND [DateTime]::ParseExact"
                Write-Warning "ConvertFrom-StorCLIOutput(): Unable to convert the .Basics.'Current Controller Date/Time' property to a 'real' [DateTime] data type"
            }
            #}

            if ($StorCLIObject.Basics.'Current Controller Date/Time' -is [DateTime]) {
                Write-Verbose ('ConvertFrom-StorCLIOutput(): .Basics.''Current Controller Date/Time'' after conversion to DATETIME: "{0}"' -f $StorCLIObject.Basics.'Current Controller Date/Time')

                if ($ConvertFromUTCTime) {
                    # Conversion to DateTime went well, and we should convert from UTC time to local time.
                    Write-Verbose "ConvertFrom-StorCLIOutput(): -ConvertFromUTCTime specified, will convert .Basics.'Current Controller Date/Time' to local time from UTC."
    
                    $StorCLIObject.Basics.'Current Controller Date/Time' = [System.TimeZoneInfo]::ConvertTimeFromUtc($StorCLIObject.Basics.'Current Controller Date/Time', [System.TimeZoneInfo]::Local)
                    Write-Verbose ('ConvertFrom-StorCLIOutput(): .Basics.''Current Controller Date/Time'' converted to local time from UTC: "{0}"' -f $StorCLIObject.Basics.'Current Controller Date/Time')
                }
            }

        }
        

        if ($null -ne $StorCLIObject.Basics.'Current System Date/time') {
            Write-Verbose "ConvertFrom-StorCLIOutput(): .Basics.'Current System Date/time' found - attempting to convert to [DateTime] data type."
            Write-Verbose ('ConvertFrom-StorCLIOutput(): .Basics.''Current System Date/time'': "{0}"' -f $StorCLIObject.Basics.'Current System Date/time')

            <#
            try {
                $($StorCLIObject.Basics.'Current System Date/time' = Get-Date ($StorCLIObject.Basics.'Current System Date/time') -ErrorAction Stop) *> $null

                Write-Verbose "ConvertFrom-StorCLIOutput(): .Basics.'Current System Date/time' converted to [DateTime] data type using Get-Date."
            } catch {
                Write-Verbose "ConvertFrom-StorCLIOutput(): .Basics.'Current System Date/time' failed conversion using Get-Date, trying [DateTime]::ParseExact"
            #>
            try {
                $($StorCLIObject.Basics.'Current System Date/time' = [Datetime]::ParseExact($StorCLIObject.Basics.'Current System Date/time', $TimeFormat, $null)) *> $null
                
                Write-Verbose "ConvertFrom-StorCLIOutput(): .Basics.'Current System Date/time' converted to [DateTime] data type using [DateTime]::ParseExact"
            } catch {
                Write-Verbose "ConvertFrom-StorCLIOutput(): .Basics.'Current System Date/time' failed conversion using both Get-Date AND [DateTime]::ParseExact"
                Write-Warning "ConvertFrom-StorCLIOutput(): Unable to convert the .Basics.'Current System Date/time' property to a 'real' [DateTime] data type"
            }
            #}

            if ($StorCLIObject.Basics.'Current System Date/time' -is [DateTime]) {
                Write-Verbose ('ConvertFrom-StorCLIOutput(): .Basics.''Current System Date/time'' after conversion to DATETIME: "{0}"' -f $StorCLIObject.Basics.'Current System Date/time')

                if ($ConvertFromUTCTime) {
                    # Conversion to DateTime went well, and we should convert from UTC time to local time.
                    Write-Verbose "ConvertFrom-StorCLIOutput(): -ConvertFromUTCTime specified, will convert .Basics.'Current System Date/time' to local time from UTC."
    
                    $StorCLIObject.Basics.'Current System Date/time' = [System.TimeZoneInfo]::ConvertTimeFromUtc($StorCLIObject.Basics.'Current System Date/time', [System.TimeZoneInfo]::Local)
                    Write-Verbose ('ConvertFrom-StorCLIOutput(): .Basics.''Current System Date/time'' converted to local time from UTC: "{0}"' -f $StorCLIObject.Basics.'Current System Date/time')
                }
            }

        }
    }

    
    $StorCLIObject.Status = Get-StorCLIState -StorCLIOutput $StorCLIObject -ConvertFromUTCTime:$ConvertFromUTCTime -ReportHostname $ReportHostname

    Write-Verbose ('ConvertFrom-StorCLIOutput(): Done - returning object with {0} properties' -f ($StorCLIObject|Get-Member -MemberType Properties).Count)

    return $StorCLIObject
} # function ConvertFrom-StorCLIOutput







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
        Author.: Kenneth Nielsen (sharzas @ GitHub.com)
        Version: 1.0
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

    Write-Verbose ('ConvertFrom-FixedWidthTable(): Header is "{0}"' -f $Header.Line)
    Write-Verbose ('ConvertFrom-FixedWidthTable(): Header found at line {0}' -f $Header.LineNumber)
    Write-Verbose ('ConvertFrom-FixedWidthTable(): Number of columns derived from Header Pattern {0}' -f ($Header[0].Matches[0].Groups.Count -1))

    $Columns = $Header[0].Matches[0].Groups|Select-Object -Skip 1|Sort-Object -Property Index

    # output verbose listing of enumerated columns
    [int32]$MaxLength = ($Columns|ForEach-Object {$_.Value.ToString().Length}|Sort-Object -Descending)[0]

    foreach ($Column in $Columns) {
        Write-Verbose ('ConvertFrom-FixedWidthTable(): Column.{0} .Index = "{1}", .Length = "{2}"' -f $Column.Value.ToString().Trim().PadRight($MaxLength," "), $Column.Index.ToString().PadLeft(3,"0"), $Column.Length.ToString().PadLeft(3,"0"))
    }


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

    #return $Columns
    foreach ($line in ($InputObject|Select-Object -Skip ($Header.LineNumber + $SkipLinesAfterHeader)|Select-Object -First $Lines)) {
        
        if (-not (($null -ne $SkipPattern) -and ($line -match $SkipPattern))) {
            $Object = New-Object PSCustomObject

            Write-Verbose ('ConvertFrom-FixedWidthTable(): Line.Length({0}) = "{1}"' -f $line.Length.ToString().PadLeft(3,"0"), $line)

            foreach ($Column in $Columns) {

                if ($Column.Index -lt $line.Length) {

                    if (($Column.Index + $Column.Length) -gt $line.Length) {
                        # Combination of Start index + length (width of column) exceeds the available characters in the string.
                        # This usually occurs in the last column, where the Heading of the row is wider than the actual value.
                        #
                        # We will adjust for this.
                        #
                        $Length = $line.Length - $Column.Index
                        Write-Verbose ('ConvertFrom-FixedWidthTable(): Column.{0} .Index + .Length greater than Line.Length: {1} + {2} = {3} > {4} - Adjusted to maximum = {5}' -f `
                                        $Column.Value.ToString().Trim().PadRight($MaxLength," "), 
                                        $Column.Index.ToString().PadLeft(3,"0"), 
                                        $Column.Length.ToString().PadLeft(3,"0"), 
                                        ($Column.Index + $Column.Length).ToString().PadLeft(3,"0"), 
                                        $line.Length.ToString().PadLeft(3,"0"), 
                                        $Length.ToString().PadLeft(3,"0"))
                    } else {
                        # All is good, use length as is.
                        $Length = $Column.Length
                    }

                    if ($DoNotTrimSpaces) {
                        # -DoNotTrimSpaces specified = dont trim trailing/ending spaces of the value in the column
                        $Object|Add-Member -MemberType NoteProperty -Name $Column.Value.ToString().Trim() -Value $line.ToString().Substring($Column.Index, $Length)
                    } else {
                        # -DoNotTrimSpaces NOT specified = trim trailing/ending spaces of the value in the column
                        $Object|Add-Member -MemberType NoteProperty -Name $Column.Value.ToString().Trim() -Value $line.ToString().Substring($Column.Index, $Length).Trim()
                    }
                } else {
                    # start index of column, exceeds length of current line. We cannot extract any data for this column,
                    # from this particular row - so add a $null value (to avoid error, and return the rest of the output)
                    Write-Verbose ('ConvertFrom-FixedWidthTable(): Column.{0} .Index greater than Line.Length: {1} > {2} - Adding null value.' -f `
                                    $Column.Value.ToString().Trim().PadRight($MaxLength," "), 
                                    $Column.Index.ToString().PadLeft(3,"0"), 
                                    $line.Length.ToString().PadLeft(3,"0"))

                    $Object|Add-Member -MemberType NoteProperty -Name $Column.Value.ToString().Trim() -Value $null
                }
            }

            $Object
        }
    }
} # function ConvertFrom-FixedWidthTable








function Get-PropertyValuePairs
{
    <#
    .SYNOPSIS
        Extract property / value pairs from an array of text.

    .DESCRIPTION
        Extract property / value pairs from an array of text, and return the information
        as a single object, containing each property with corresponding value.
        
        Pairs are identified by a delimiter, which by default is "="

    .PARAMETER InputObject
        The text from which to extract the property/value pairs.

    .PARAMETER Delimiter
        Specifies the delimiter to use for identifying property/value pairs.
        
        E.g.:

        Property1 = value
        Property2 = value

        Delimiter is "="


    .EXAMPLE
        $Properties = @'
            IsThisATest = Yes
            YetAnotherProperty = WhoAmI
            Foo = Bar
        '@

        $Properties|Get-PropertyValuePairs|Format-List *

        Will output:

        IsThisATest        : Yes
        YetAnotherProperty : WhoAmI
        Foo                : Bar

    .EXAMPLE
        $Properties = @("IsThisATest = Yes", "YetAnotherProperty = WhoAmI", "Foo = Bar")

        $Properties|Get-PropertyValuePairs|Format-List *

        Will output:

        IsThisATest        : Yes
        YetAnotherProperty : WhoAmI
        Foo                : Bar

    .OUTPUTS
        A single object with all extracted property/value pairs attached as individual
        properties on the object.

        Note: 
        No explicit type conversion is done, so the values will in most cases be strings.

    .NOTES
        Author.: Kenneth Nielsen (sharzas @ GitHub.com)
        Version: 1.0        
    #>

    [CmdLetBinding()]

    Param (
        [Parameter(ValueFromPipeline)]$InputObject,
        $Delimiter = "="
    )

    Begin {
        Write-Verbose 'Get-PropertyValuePairs(): Invoked.'

        # RegExp Pattern used to match the Property/Value pairs.
        #
        # Data is extracted from RegExp groups, and returned as a object with properties
        # matching the properties extract from the property/value pairs
        #
        # E.g.: Property = value, or Property : value
        #
        $Pattern = ('(?m)(^[^{0}].+?){1}(.+)' -f $Delimiter, $Delimiter)

        Write-Verbose ('Get-PropertyValuePairs(): Delimiter.................: "{0}"' -f $Delimiter)
        Write-Verbose ('Get-PropertyValuePairs(): Constructed RegExp pattern: "{0}"' -f $Pattern)

        $Object = New-Object PSCustomObject
    }
    

    Process {
        $InputObject|Select-String -Pattern $Pattern -AllMatches|Where-Object {$_.Matches}|Where-Object {$_.Matches[0].Groups.Count -gt 2}|Select-Object -ExpandProperty Matches|ForEach-Object {
            Write-Verbose ('Get-PropertyValuePairs(): Found Property / Value Pair "{0}" {1} "{2}"' -f $_.Groups[1].ToString().Trim(), $Delimiter, $_.Groups[2].ToString().Trim())

            $Object|Add-Member -MemberType NoteProperty -Name $_.Groups[1].ToString().Trim() -Value $_.Groups[2].ToString().Trim()
        }
    }

    End {
        $PropertyCount = ($Object|Get-Member -MemberType Properties).Count

        if ($PropertyCount -eq 0) {
            Write-Verbose 'Get-PropertyValuePairs(): Done - nothing found - returning null'
            return $null
        } else {
            Write-Verbose ('Get-PropertyValuePairs(): Done - {0} properties found.' -f $PropertyCount)
            return $Object
        }
    }

} # function Get-PropertyValuePairs












function Invoke-Main
{
    # main function
    #
    # no help for this one - it should never be called manually, only as part
    # of script execution.
    #
    [CmdLetBinding(DefaultParameterSetName = 'File')]

    Param (
        [Parameter(ParameterSetName = 'Text')]
        $StorCLIOutput,
    
        [Parameter(ParameterSetName = 'File')]
        $Path,
        
        [Parameter()]
        [switch]$CheckStatus = $false,
    
        [Parameter()]
        [switch]$ConvertFromUTCTime = $false,

        [Parameter()]
        $DataLogFile = $null,

        [Parameter()]
        [switch]$EnableSSL = $false,
        
        [Parameter()]
        $From,
        
        [Parameter()]
        [switch]$LogFullStatusReport = $false,
    
        [Parameter()]
        [switch]$LogStatusReportOnError = $false,
    
        [Parameter()]
        $Password = $null,
    
        [Parameter()]
        [switch]$PruneDataLog = $false,
    
        [Parameter()]
        [DateTime]$PruneDataLogBefore,

        [Parameter()]
        [DateTime]$PruneStatusLogDate = $null,

        [Parameter()]
        $Recipient,

        [Parameter()]
        $ReportHostname,
        
        [Parameter()]
        [switch]$SendMailAsText = $false,
    
        [Parameter()]
        [switch]$SendMailWithReport = $false,
    
        [Parameter()]
        [switch]$SendMailOnError = $false,
    
        [Parameter()]
        [string]$SMTPHost,
    
        [Parameter()]
        [Int32]$SMTPPort = 25,
    
        [Parameter()]
        $StatusLogFile = $null,
    
        [Parameter()]
        [string]$TimeStampFormat = "dd-MM-yyyy HH:mm:ss",
    
        [Parameter()]
        [string]$Username = ""
    )

    Write-Verbose "Invoke-Main(): Invoked."

    $PSBoundParameters.Keys|ForEach-Object {Write-Verbose ('Invoke-Main(): Parameter supplied to function: {0} - Type = "{1}"' -f $_, $_.Gettype().Fullname)}

    # build parameter set to pass on to ConvertFrom-StorCLIOutput function
    $Params = @{}

    @("Path", "StorCLIOutput", "ConvertFromUTCTime", "ReportHostname")|ForEach-Object {
        if ($PSBoundParameters.ContainsKey($_)) {
            Write-Verbose ('Invoke-Main(): Build parameters for ConvertFrom-StorCLIOutput: {0} = {1}' -f $_, $PSBoundParameters[$_])
            $Params[$_] = $PSBoundParameters[$_]
        }
    }
    
    $StorCLI = ConvertFrom-StorCLIOutput @Params

    if ($null -ne $StorCLI) {
        # build parameter set to pass on to Update-DataLog function
        $Params = @{"NewData" = $StorCLI}

        @("DataLogFile", "PruneDataLog", "PruneDataLogBefore")|ForEach-Object {
            if ($PSBoundParameters.ContainsKey($_)) {
                Write-Verbose ('Invoke-Main(): Build parameters for Update-DataLog: {0} = {1}' -f $_, $PSBoundParameters[$_])
                $Params[$_] = $PSBoundParameters[$_]
            }
        }

        # execute Update-DataLog
        try {
            Update-DataLog @Params -ErrorAction Stop
            Write-Verbose ('Invoke-Main(): Update-DataLog finished succesfully.')
        } catch {
            Write-Warning ('Invoke-Main(): Update-DataLog finished with error.')
            Throw
        }
    }


    # Lets generate a status if its needed - part 1 - Populate general data to log.
    if ($null -ne $StatusLogFile) {
        # default log line prefix
        $Prefix = "[OK] "

        if ($null -ne $StorCLI) {
            # We have got status information to log - lets do it.

            $Log = @(('Controller Status: {0}' -f $StorCLI.Status.State))

            if ($LogFullStatusReport) {
                # We should include full status in the log

                $Log += @($StorCLI.Status.Report.Full)
            }

            if ($StorCLI.Status.State -eq "OK") {
                # All good man
            
            } else {
                # Bugger - an error is there

                # change log line prefix to indicate error
                $Prefix = "[ERROR] "

                if ($LogStatusReportOnError) {
                    # We should include error report in the log file.

                    $Log += @($StorCLI.Status.Report.Error)
                }
            }
        } else {
            # could not extract data from the StorCLI output, so log that as an error.

            # change log line prefix to indicate error
            $Prefix = "[ERROR] "

            $Log = @(
                "Could not retrieve the StorCLI object!",
                "",
                "Parameters issued to ConvertFrom-StorCLIOutput:",
                "================================================",
                $($Params.GetEnumerator()|Format-Table -AutoSize|Out-String -Stream),
                ""
            )
        }
    }

    if ($CheckStatus) {
        # We need to run a status check on StorCLI data, and potentially send a notification
        # mail, as well as update the log data to output to Status Log.
        Write-Verbose ('Invoke-Main(): -CheckStatus specified - will run Test-StorCLIStatus')

        $Params = @{"StorCLI" = $StorCLI}

        @("EnableSSL","From","Password","Recipient","SendMailAsText","SendMailWithReport","SendMailOnError","SMTPHost","SMTPPort","Username")|ForEach-Object {
            if ($PSBoundParameters.ContainsKey($_)) {
                Write-Verbose ('Invoke-Main(): Build parameters for Test-StorCLIStatus: {0} = {1}' -f $_, $PSBoundParameters[$_])
                $Params[$_] = $PSBoundParameters[$_]
            }    
        }

        try {            
            $Status = Test-StorCLIStatus @Params -ErrorAction Stop

            Write-Verbose ('Invoke-Main(): Test-StorCLIStatus completed without errors.')
        } catch {
            Write-Warning ('Invoke-Main(): Test-StorCLIStatus failed with an error.')

            # rethrow the statement terminating error.
            $PSCmdlet.ThrowTerminatingError((New-ErrorRecord -baseObject $_))
        }

        $Log += $Status.Log
    }


    # Lets generate a status if its needed - part 2 - finish up and write to log.
    if ($null -ne $StatusLogFile) {
        # build parameter set to pass on to Update-StatusLog function
        $Params = @{"NewData" = $Log; "Prefix" = $Prefix}

        try {
            $Log|Out-Log -Prefix $Prefix -LogFile $StatusLogFile
            Update-Log -LogFile $StatusLogFile -PruneLogDate $PruneStatusLogDate
            Write-Verbose ('Invoke-Main(): StatusLog updated succesfully.')
        } catch {
            Write-Warning ('Invoke-Main(): Error attempting to update StatusLog.')
            Throw
        }        
    }

    if ($null -eq $StorCLI) {
        Write-Warning "Invoke-Main(): Could not retrieve the StorCLI object!"
        Write-Warning ""
        Write-Warning "Parameters issued to ConvertFrom-StorCLIOutput:"
        Write-Warning "================================================"
        $Params.GetEnumerator()|Format-Table -AutoSize|Out-String -Stream|Write-Warning
        Write-Warning ""
        Write-Warning "Aborting!"
        return $null
    }



    if ($CheckStatus) {
        Write-Verbose ('Invoke-Main(): Done. -CheckStatus specified - returning only status output to screen and exit code.')

        if ($Status.Status -ne "OK") {
            Write-Warning ('Performed status check on StorCLI output. State is "{0}"' -f $Status.Status)
            $Status.AdditionalInformation|Foreach-Object {Write-Warning $_}
            Exit 1
        } else {
            Write-Host ('Performed status check on StorCLI output. State is "{0}"' -f $Status.Status)
            $Status.AdditionalInformation|Foreach-Object {Write-Host $_}
            Exit 0
        }
    } else {
        Write-Verbose ('Invoke-Main(): Done - returning object with {0} properties.' -f ($StorCLI|Get-Member -MemberType Properties).Count)
        return $StorCLI
    }
} # function Invoke-Main










function New-ErrorRecord
{
    <#
    .SYNOPSIS
        Build ErrorRecord from scratch, based on Exception, or based on existing ErrorRecord

    .DESCRIPTION
        Build ErrorRecord from scratch, based on Exception, or based on existing ErrorRecord
        
        Especially useful for ErrorRecords used to re-throwing errors in advanced functions
        using $PSCmdlet.ThrowTerminatingError()

        Support for:
        - Build ErrorRecord from scratch, exception or existing ErrorRecord.
        - Inheriting InvocationInfo from existing ErrorRecord
        - Adding Exception from existing ErrorRecord, to InnerException chain
          in of Exception in new ErrorRecord, to preserve full Exception history.
        
    .PARAMETER baseObject
        If supplied, the ErrorRecord will be based on this. It must be either of:

        [System.Exception]
        ==================
        The ErrorRecord will be created based on the other parameters supplied to the function,
        and this Exception is included as is, as the .Exception property.

        [System.Management.Automation.ErrorRecord]
        ==========================================
        The ErrorRecord will be created based on this ErrorRecord. The values of parameters
        that are not supplied to the function, will be derived from this object.

        The exception in this object, will be added to .InnerException chain of the Exception
        created for the new ErrorRecord.

        If specified, InvocationInfo will be inherited from this object, by storing it in
        the FullyQualifiedErrorId property.

    .PARAMETER exceptionType
        If -baseObject has not been supplied, an Exception of this type will be created for
        the ErrorRecord. If this parameter is not supplied, a generic System.Exception will
        be created.

    .PARAMETER exceptionMessage
        Message that is added to the new Exception, attached to the ErrorRecord.
        
        
    .PARAMETER errorId
        This is used to construct the FullyQualifiedErrorId.

        NOTE:
        If -baseObject is an ErrorRecord, and -InheritInvocationInfo is specified as well,
        this parameter will be overridden with the InvocationInfo.PositionMessage property
        of the existing ErrorRecord.
        
    .PARAMETER errorCategory
        Category set in the CategoryInfo of the ErrorRecord. Must be enumerable via the
        [System.Management.Automation.ErrorCategory] enum.

    .PARAMETER targetObject
        Object that was target of the operation. This will be used to display some details
        in the CategoryInfo part of the ErrorRecord - e.g. partial value and Data type of
        the Object (string, int32, etc.).

        Hint: it can be a good idea to include this.

        NOTE: 
        If -baseObject is an ErrorRecord, and this parameter is not supplied, the 
        targetObject of the existing ErrorRecord will be used in the new ErrorRecord as well,
        unless -DontInheritTargetObject is specified.
                
    .PARAMETER DontInheritInvocationInfo
        If this parameter is specified, and -baseObject is an ErrorRecord, the InvocationInfo
        will NOT be inherited in the new ErrorRecord.

        If this parameter isn't specified, and -baseObject is an ErrorRecord, the 
        InvocationInfo.PositionMessage property of the ErrorRecord in baseObject will be 
        appended to the -errorId parameter supplied to the ErrorRecord constructor.

        The benefit from this is, that the resulting ErrorRecord will have correct position
        information displayed in the FullyQualifiedErrorId part of the ErrorRecord, when 
        re-throwing and error in a function, using $PSCmdlet.ThrowTerminatingError()

        If this parameter IS supplied, the ErrorRecord will show the position of the 
        exception as the line where the function was called, as opposed to the line where the
        exception was thrown. Not using this parameter includes both positions, so it will be
        possible to see both where the function was called, and where the Exception was thrown.

    .PARAMETER DontInheritTargetObject
        If specified, and -baseObject is an ErrorRecord, and -targetObject isn't specified
        either, the value of targetObject will be set to $null, to prevent inheritance of
        this value from the existing ErrorRecord.

    .PARAMETER DontUpdateInnerException
        If specified, and -baseObject is an ErrorRecord, the exception created for the new
        ErrorRecord, will not have its .InnerException property chain updated with the
        the Exception from the ErrorRecord in baseObject, and thus the Exception history
        will be reset.

    .EXAMPLE
        You have the following advanced functions:
        
        function Test-LevelTwo
        {
            [CmdletBinding()]
            Param ($TestLevelTwoParameter)

            try {
                Get-Content NonExistingFile.txt -ErrorAction Stop
            } catch {
                $PSCmdlet.ThrowTerminatingError((New-ErrorRecord -baseObject $_))
            }
        } # function Test-LevelTwo

        function Test-LevelOne
        {
            [CmdletBinding()]
            Param ($TestLevelOneParameter)

            try {
                Test-LevelTwo -TestLevelTwoParameter "This is a parameter for Test-LevelTwo"
            } catch {
                $PSCmdlet.ThrowTerminatingError((New-ErrorRecord -baseObject $_ -DontInheritInvocationInfo))
            }
        } # function Test-LevelOne

        And call the function: Test-LevelOne -TestLevelOneParameter "This is a parameter for Test-LevelOne"

        It will display the following error:

        PS C:\Test> .\Test.ps1
        Test-LevelOne : Cannot find path 'C:\Test\NonExistingFile.txt' because it does not exist.
        At C:\Test\Test.ps1:28 char:1
        + Test-LevelOne -TestLevelOneParameter "This is a parameter for Test-Le ...
        + ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            + CategoryInfo          : ObjectNotFound: (C:\Test\NonExistingFile.txt:String) [Test-LevelOne], ItemNotFoundException
            + FullyQualifiedErrorId : errorId not specified,Test-LevelOne

        Note of the error position at line 28, char 1 - this is in fact the line where
        the function Test-LevelOne is called. To get the exact position of the error included 
        in the FullyQualifiedErrorId, do not use the -DontInheritInvocationInfo parameter in
        Test-LevelOne when calling New-ErrorRecord. See next example...
        
    .EXAMPLE
        You have the following advanced function:
        
        function Test-LevelTwo
        {
            [CmdletBinding()]
            Param ($TestLevelTwoParameter)

            try {
                Get-Content NonExistingFile.txt -ErrorAction Stop
            } catch {
                $PSCmdlet.ThrowTerminatingError((New-ErrorRecord -baseObject $_))
            }
        } # function Test-LevelTwo

        function Test-LevelOne
        {
            [CmdletBinding()]
            Param ($TestLevelOneParameter)

            try {
                Test-LevelTwo -TestLevelTwoParameter "This is a parameter for Test-LevelTwo"
            } catch {
                $PSCmdlet.ThrowTerminatingError((New-ErrorRecord -baseObject $_))
            }
        } # function Test-LevelOne

        And call the function: Test-LevelOne -TestLevelOneParameter "This is a parameter for Test-LevelOne"

        It will display the following error:

        PS C:\Test> .\Test.ps1
        Test-LevelOne : Cannot find path 'C:\Test\NonExistingFile.txt' because it does not exist.
        At C:\Test\Test.ps1:28 char:1
        + Test-LevelOne -TestLevelOneParameter "This is a parameter for Test-Le ...
        + ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            + CategoryInfo          : ObjectNotFound: (C:\Test\NonExistingFile.txt:String) [Test-LevelOne], ItemNotFoundException
            + FullyQualifiedErrorId : NotSpecified
        +         Source.CategoryInfo     : "ObjectNotFound: (C:\Test\NonExistingFile.txt:String) [Test-LevelTwo], ItemNotFoundException"
        +         Source.Exception.Message: "Cannot find path 'C:\Test\NonExistingFile.txt' because it does not exist."
        +         Source.Exception.Thrown : At C:\Test\Test.ps1:22 char:9
        +         Test-LevelTwo -TestLevelTwoParameter "This is a parameter for ...
        +         ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        +
        --- Test-LevelTwo : NotSpecified
        +         Source.CategoryInfo     : "ObjectNotFound: (C:\Test\NonExistingFile.txt:String) [Get-Content], ItemNotFoundException"
        +         Source.Exception.Message: "Cannot find path 'C:\Test\NonExistingFile.txt' because it does not exist."
        +         Source.Exception.Thrown : At C:\Test\Test.ps1:10 char:9
        +         Get-Content NonExistingFile.txt -ErrorAction Stop
        +         ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        +
        --- Get-Content : PathNotFound,Microsoft.PowerShell.Commands.GetContentCommand,Test-LevelTwo,Test-LevelOne

        Take good note of the position for all exceptions in the chain, included
        in FullyQualifiedErrorId - this is the result of -DontInheritInvocationInfo not being used.

    .EXAMPLE
        $TestString = "this is a string"
        $ErrorRecord = New-ErrorRecord -exceptionType "System.Exception" -exceptionMessage "This is an Exception" -errorId "This is a test error record" -errorCategory "ReadError" -targetObject $TestString

        throw $ErrorRecord

        Will throw the following error:

        This is an Exception
        At C:\Test\test.ps1:290 char:1
        +     throw $ErrorRecord
        +     ~~~~~~~~~~~~~~~~~~
            + CategoryInfo          : ReadError: (this is a string:String) [], Exception
            + FullyQualifiedErrorId : This is a test error record        

    .EXAMPLE
        You may also @Splay parameters via HashTable for better readability:

        $TestString = "this is a string value"

        $Param = @{
            exceptionType = "System.Exception"
            exceptionMessage = "This is an Exception generated with @Splatted parameters"
            errorId = "This is a test error record"
            errorCategory = "ReadError" 
            targetObject = $TestString
        }

        $ErrorRecord = New-ErrorRecord @Param

        throw $ErrorRecord

        Will throw the following error:

        This is an Exception generated with @Splatted parameters
        At C:\Test\test.ps1:290 char:1
        +     throw $ErrorRecord
        +     ~~~~~~~~~~~~~~~~~~
            + CategoryInfo          : ReadError: (this is a string value:String) [], Exception
            + FullyQualifiedErrorId : This is a test error record


    .OUTPUTS
        An ErrorRecord object.

    .NOTES
        Author.: Kenneth Nielsen (sharzas @ GitHub.com)
        Version: 1.2

    .LINK
        https://github.com/sharzas/Powershell-New-ErrorRecord
    #>

    [CmdletBinding()]

    Param (
        [System.Object]$baseObject,
        [System.String]$exceptionType = "System.Exception",
        [System.string]$exceptionMessage = "exceptionMessage not specified",
        [System.string]$errorId = "errorId not specified",
        [System.Management.Automation.ErrorCategory]$errorCategory = "NotSpecified",
        [System.Object]$targetObject = $null,
        [Switch]$DontInheritInvocationInfo,
        [Switch]$DontInheritTargetObject,
        [Switch]$DontUpdateInnerException
    )

    Write-Verbose ('New-ErrorRecord(): invoked.')



    function Split-WordWrap
    {
        <#
        .SYNOPSIS
            Word wrap a text block at specified width.

        .DESCRIPTION
            Word wrap a text block at specified width.
            
        .PARAMETER Text
            Text block to perform Word Wrap on.

        .PARAMETER Width
            Maximum width of each line. Lines will word wrapped so as to not exceed this line
            length.
            
            If any words in the text block is longer than the maximum width of a line, they
            will be split.

        .PARAMETER SplitLongWordCharacter
            Character that will be inserted at the end of each line, if it becomes neccessary
            to split a very long word.
            
        .PARAMETER NewLineCharacter
            This is the character that will be used for line feeds. Because of various
            possible scenarious this parameter has been included.

            Default is "`n" (LF), but some may prefer "`r`n" (CRLF)

            Just be aware that "`r`n" will make Powershell native code interpret an extra
            empty line, for each line... on the other hand, applications that expect "`r`n"
            will need that.

        .EXAMPLE
            Split-WordWrap -Line "this is a long line that needs some wrapping" -Width 15

            Will output the string value:

            this is a long
            line that needs
            some wrapping
            
        .EXAMPLE
            Split-WordWrap -Line "this long line contains SomeVeryLongWordsThatNeedSplitting and SomeOtherVeryLongWords" -Width 15

            Will output the string value:

            this long line
            contains SomeV-
            eryLongWordsTh-
            atNeedSplitting
            and SomeOtherV-
            eryLongWords

        .OUTPUTS
            String containing the input text block, in word wrapped format, according to
            -Width

        .NOTES
            Author.: Kenneth Nielsen (sharzas @ GitHub.com)
            Version: 1.0
        #>

        [CmdletBinding()]
        Param (
            [String]$Text,
            $Width = $null,
            $SplitLongWordCharacter = "-",
            $NewLineCharacter = "`n"
        )
    
        Write-Verbose ('Split-WordWrap(): invoked')

        if ($null -eq $Width) {
            # if Width not supplied, or is null, then simply return as is.
            # should let it work under ISE as well, if calling using some
            # (Get-Host).UI.RawUI values.
            return $Text
        }

        # replace single newline characters to CRLF
        $Text = $Text.Replace("`r`n","`n")
    
        # split line into separate lines by CRLF if any is present.
        $Lines = $Text.Split("`n")
    
        $NewContent = foreach ($Line in $Lines) {
            $Words = $Line.Split(" ")
    
            # for each line, start with a blank line variable. We'll add to this one until we reach the specified
            # width, at which point we will wrap to next line.
            $NewLine = ""
    
            foreach ($Word in $Words) {
                $Skip = $false
        
                if (($NewLine + ('{0}' -f $Word)).Length -gt $Width) {
                    # Current line + addition of the next word, will exceed the specified width, so we need to wrap here
                    Write-Verbose ('Split-WordWrap(Wrap): ("{0}" + "{1}").Length -gt "{2}" = "{3}"' -f $NewLine, ('{0}' -f $Word), $Width, $(($NewLine + $Word).Length -gt $Width))

                    if ($Word.Length -gt $Width) {
                        # The next word is wider than the specified width, so we need to split that word in order to
                        # be able to wrap it.
                        Write-Verbose ('Word is wider than width, need to split in order to wrap: "{0}"' -f $Word)
    
                        $TooLongWord = $Newline + $Word
    
                        Do {
                            $SplittedWord = ('{0}{1}' -f $TooLongWord.Substring(0,($Width-1)), $SplitLongWordCharacter)
                            $SplittedWord
                            Write-Verbose ('Split-WordWrap(): $SplittedWord is now = "{0}"' -f $SplittedWord)
    
                            $TooLongWord = $TooLongWord.Substring($Width-1)
                            Write-Verbose ('Split-WordWrap(): $TooLongWord.Substring({0}) = "{1}"' -f ($Width-1),$TooLongWord)
                        }
                        Until ($TooLongWord.Length -le $Width)
    
                        $NewLine = ('{0} ' -f $TooLongWord)
    
                        # we need to skip adding this word to the current line, as we've just done that.
                        $Skip = $true
                    } else {
                        # The next word is narrower than specified width, so we can wrap simply by completing current
                        # line, and adding this word as the beginning of a new line.
    
                        # output current line
                        Write-Verbose ('Split-WordWrap(): New Line "{0}"' -f $NewLine.Trim())
                        $NewLine.Trim()
    
                        # reset line, in preparation for adding the next word as a new line.
                        $NewLine = ""    
                    }
                }
    
                if (!$Skip) {
                    # skip has not been specified, so add current word to current line
                    $NewLine += ('{0} ' -f $Word)
                }
                
            }
            Write-Verbose ('Split-WordWrap(): New Line "{0}"' -f $NewLine.Trim())
            $NewLine.Trim()
        }    
    
        Write-Verbose ('Split-WordWrap(): Joining {0} lines to return' -f $NewContent.Count)

        $NewContent = $NewContent -Join $NewLineCharacter
        return $NewContent
    } # function Split-WordWrap



    $Record = $null

    if ($PSBoundParameters.ContainsKey("baseObject")) {
        # base object was supplied - this must be either [System.Exception] or [System.Management.Automation.ErrorRecord]
        if ($baseObject -is [System.Exception]) {
            # exception
            # an existing exception was specified, so use that to create the errorrecord.
            Write-Verbose ('New-ErrorRecord(): -baseObject is [System.Exception]: build ErrorRecord using this Exception.')

            $Record = New-Object System.Management.Automation.ErrorRecord($baseObject, $errorId, $errorCategory, $targetObject)

        } elseif ($baseObject -is [System.Management.Automation.ErrorRecord]) {
            # errorrecord
            # an existing ErrorRecord was specified, so use that to create the new errorrecord.
            Write-Verbose ('New-ErrorRecord(): -baseObject is [System.Management.Automation.ErrorRecord]: build ErrorRecord based on this.')

            if (!$DontInheritInvocationInfo) {
                # -DontInheritInvocationInfo NOT specified: construct information about the original invocation, and store it
                # in errorId of the new record. This is practical if the this errorrecord is made to re-throw via
                # $PSCmdlet.ThrowTerminatingError in a function. If we don't do this, the ErrorRecord will have invocation
                # info, and positional info that points to the line in the script, where the function is called from, 
                # rather than the line where the error occured.
                Write-Verbose ('New-ErrorRecord(): -DontInheritInvocationInfo NOT specified: Including InvocationInfo.PositionMessage as errorId')

                # Set some indentation values
                $Indentation = " "*2
                $DataIndentation = 26

                $PositionMessage = $baseObject.InvocationInfo.PositionMessage.Split("`n") -replace "^\+\s+", ""


                if ($PositionMessage.Count -gt 1) {
                    $PositionMessage[1..$PositionMessage.GetUpperBound(0)]|ForEach-Object {
                        $_ = ('+{0}{0}{1}' -f $Indendation,$_)
                    }
                }

                $PositionMessage = $PositionMessage -join "`n"

                # Base value of errorId
                $errorIdBase = @'
{0}
 
Source.CategoryInfo     : "{2}"
Source.Exception.Message: "{3}"
Source.Exception.Line   : {4}
Source.Exception.Thrown : {5}
 
--- {6} : {7}
'@
                
                if (!$PSBoundParameters.ContainsKey("errorId")) {
                    # -errorId not specified, so simply set value to InvocationInfo.PositionMessage 
                    # of existing ErrorRecord
                    Write-Verbose ('New-ErrorRecord(): -errorId NOT specified: constructing by merging empty string with FullyQualifiedErrorId chain.')

                    $errorId = $errorIdBase -f `
                        "NotSpecified", `
                        $Indentation, `
                        (Split-WordWrap -Text $baseObject.CategoryInfo.ToString() -Width ((Get-Host).UI.RawUI.WindowSize.Width - ($DataIndentation+8))).Replace("`n",("`n{0}" -f (" "*$DataIndentation))), `
                        (Split-WordWrap -Text $baseObject.Exception.Message -Width ((Get-Host).UI.RawUI.WindowSize.Width - ($DataIndentation+8))).Replace("`n",("`n{0}" -f (" "*$DataIndentation))), `
                        (Split-WordWrap -Text $baseObject.InvocationInfo.Line.Trim() -Width ((Get-Host).UI.RawUI.WindowSize.Width - ($DataIndentation+8))).Replace("`n",("`n{0}" -f (" "*$DataIndentation))), `
                        (Split-WordWrap -Text $PositionMessage -Width ((Get-Host).UI.RawUI.WindowSize.Width - ($DataIndentation+8))).Replace("`n",("`n{0}+{1}" -f (" "*$DataIndentation), $Indentation)), `
                        $baseObject.InvocationInfo.InvocationName, `
                        $baseObject.FullyQualifiedErrorId
                } else {
                    # -errorId specified, so merge with existing ErrorRecords InvocationInfo and a NewLine.
                    Write-Verbose ('New-ErrorRecord(): -errorId specified: constructing by merging -errorId with FullyQualifiedErrorId chain.')

                    $errorId = $errorIdBase -f `
                        $errorId, `
                        $Indentation, `
                        (Split-WordWrap -Text $baseObject.CategoryInfo.ToString() -Width ((Get-Host).UI.RawUI.WindowSize.Width - ($DataIndentation+8))).Replace("`n",("`n{0}" -f (" "*$DataIndentation))), `
                        (Split-WordWrap -Text $baseObject.Exception.Message -Width ((Get-Host).UI.RawUI.WindowSize.Width - ($DataIndentation+8))).Replace("`n",("`n{0}" -f (" "*$DataIndentation))), `
                        (Split-WordWrap -Text $baseObject.InvocationInfo.Line.Trim() -Width ((Get-Host).UI.RawUI.WindowSize.Width - ($DataIndentation+8))).Replace("`n",("`n{0}" -f (" "*$DataIndentation))), `
                        (Split-WordWrap -Text $PositionMessage -Width ((Get-Host).UI.RawUI.WindowSize.Width - ($DataIndentation+8))).Replace("`n",("`n{0}+{1}" -f (" "*$DataIndentation), $Indentation)), `
                        $baseObject.InvocationInfo.InvocationName, `
                        $baseObject.FullyQualifiedErrorId
                }

            } else {
                Write-Verbose ('New-ErrorRecord(): -DontInheritInvocationInfo specified: InvocationInfo.PositionMessage not included as errorId')
            }

            if (!$PSBoundParameters.ContainsKey("errorCategory")) {
                # errorCategory wasn't specified, so use the one from the baseObject
                Write-Verbose ('New-ErrorRecord(): -errorCategory NOT specified: using info from -baseObject ErrorRecord')

                $errorCategory = $baseObject.CategoryInfo.Category
            } else {
                Write-Verbose ('New-ErrorRecord(): -errorCategory specified: using info from -errorCategory')
            }

            Write-Verbose ('New-ErrorRecord(): errorCategory: "{0}"' -f $errorCategory)

            if (!$PSBoundParameters.ContainsKey("exceptionMessage")) {
                # exceptionMessage wasn't specified, so use the one from the exception in the baseObject
                Write-Verbose ('New-ErrorRecord(): -exceptionMessage NOT specified: using info from -baseObject ErrorRecord')

                $exceptionMessage = $baseObject.exception.message
            }

            Write-Verbose ('New-ErrorRecord(): exceptionMessage: "{0}"' -f $errorCategory)

            if (!$PSBoundParameters.ContainsKey("targetObject")) {
                # targetObject wasn't specified

                if ($DontInheritTargetObject) {
                    # -DontInheritTargetObject specified, so set to null
                    Write-Verbose ('New-ErrorRecord(): -targetObject NOT specified, but -DontInheritTargetObject was: setting $null value')
                } else {
                    # Use the one from the baseObject
                    $targetObject = $baseObject.TargetObject

                    Write-Verbose ('New-ErrorRecord(): -targetObject NOT specified: using info from -baseObject ErrorRecord')
                }
            } else {
                Write-Verbose ('New-ErrorRecord(): -targetObject specified: added to ErrorRecord')
            }

            if ($DontUpdateInnerException) {
                # Build new exception without adding existing exception from baseObject to InnerException
                Write-Verbose ('New-ErrorRecord(): -DontUpdateInnerException specified: ErrorRecord Exception will not be added to new Exception.InnerException chain.')

                if ($PSBoundParameters.ContainsKey("exceptionType")) {
                    # -exceptionType specified, use that for the new exception
                    Write-Verbose ('New-ErrorRecord(): -exceptionType specified: creating Exception of type "{0}"' -f $exceptionType)
                    
                    $newException = New-Object $exceptionType($exceptionMessage)
                } else {
                    # -exceptionType NOT specified, use baseObject.exception type for the new exception
                    Write-Verbose ('New-ErrorRecord(): -exceptionType NOT specified: creating Exception of type "{0}"' -f $baseObject.exception.Gettype().Fullname)

                    $newException = New-Object ($baseObject.exception.Gettype().Fullname)($exceptionMessage)
                }
            } else {
                # Update InnerException, by adding the exception from the baseObject to the InnerException of the new exception.
                # this preserves the Exception chain.
                Write-Verbose ('New-ErrorRecord(): -DontUpdateInnerException NOT specified: ErrorRecord Exception WILL be added to new Exception.InnerException chain.')

                if ($PSBoundParameters.ContainsKey("exceptionType")) {
                    # -exceptionType specified, use that for the new exception
                    Write-Verbose ('New-ErrorRecord(): -exceptionType specified: creating Exception of type "{0}"' -f $exceptionType)

                    $newException = New-Object $exceptionType($exceptionMessage, $baseObject.exception)
                } else {
                    # -exceptionType NOT specified, use baseObject.exception type for the new exception
                    Write-Verbose ('New-ErrorRecord(): -exceptionType NOT specified: creating Exception of type "{0}"' -f $baseObject.exception.Gettype().Fullname)

                    $newException = New-Object ($baseObject.exception.Gettype().Fullname)($exceptionMessage, $baseObject.exception)
                }
            }            

            # build the ErrorRecord
    
            Write-Verbose ('New-ErrorRecord(): $newException  = {0}' -f $newException.gettype().fullname)
            Write-Verbose ('New-ErrorRecord(): $errorId       = {0}' -f $errorId.gettype().fullname)
            Write-Verbose ('New-ErrorRecord(): $errorCategory = {0}' -f $errorCategory.gettype().fullname)
            Write-Verbose ('New-ErrorRecord(): $targetObject  = {0}' -f $(if ($null -eq $targetObject) {"null"} else {$targetObject.gettype().fullname}))

            $Record = New-Object System.Management.Automation.ErrorRecord($newException, $errorId, $errorCategory, $targetObject)

        } else {
            # unsupported type - prepare to create the exception ourselves.
            Write-Verbose ('New-ErrorRecord(): -baseObject is an invalid type [{0}]: will be ignored. Building ErrorRecord using parameters if possible.' -f $baseObject.GetType().FullName)
        }

    }

    if ($null -eq $Record) {
        # baseObject not specified, or was invalid type, so create ErrorRecord by using parameters
        Write-Verbose ('New-ErrorRecord(): Building ErrorRecord using parameters.')

        # output any unspecified parameters verbosely
        @("exceptionMessage","errorId","errorCategory","targetObject")|ForEach-Object {
            if (!$PSBoundParameters.ContainsKey($_)) {
                # Parameter wasn't specified, use default value.
                Write-Verbose ('New-ErrorRecord(): -{0} NOT specified: using default value' -f $_)
            }
        }

        # create a new exception to embed in the ErrorRecord.
        $newException = New-Object $exceptionType($exceptionMessage)
    
        # Build record

        Write-Verbose ('New-ErrorRecord(): $newException  = {0}' -f $newException.gettype().fullname)
        Write-Verbose ('New-ErrorRecord(): $errorId       = {0}' -f $errorId.gettype().fullname)
        Write-Verbose ('New-ErrorRecord(): $errorCategory = {0}' -f $errorCategory.gettype().fullname)
        Write-Verbose ('New-ErrorRecord(): $targetObject  = {0}' -f $(if ($null -eq $targetObject) {"null"} else {$targetObject.gettype().fullname}))

        $Record = New-Object System.Management.Automation.ErrorRecord($newException, $errorId, $errorCategory, $targetObject)
    }

    # return the constructed ErrorRecord
    $Record

} # function New-ErrorRecord










function Out-Log
{
    <#
    .SYNOPSIS
        Output text to logfile, with timestamp and optionally prefix
        
    .DESCRIPTION
        Output text to logfile, with timestamp and optionally prefix
        
        Option to -PassThru to get a copy of each item being processed via
        the pipeline.

    .PARAMETER Prefix
        If specified, all logged lines will be prefixed with this value. The prefix
        is inserted between the log line and the timestamp - like this:

        <timestamp> <prefix> <logline>

    .PARAMETER Text
        The text to add to the log. This must either be a string, or an array of
        strings.
                
    .PARAMETER PassThru
        If specified, each logline will be passed through to the pipeline as well.
                    
    .PARAMETER LogFile
        If specified, text will be logged in text form to this file.
        
        If not specified, nothing will be logged, however it is still possible to
        get the timestamped/prefixed log lines via -PassThru.

    .PARAMETER TimeStampFormat
        This is the DateTime format used by the logging functions. This must be a .NET
        supported TimeProvider format.
        
    .OUTPUTS
        Success = nothing, or the logged data if -PassThru is specified.
        Failure = Terminating Exception.

    .NOTES
        Author.: Kenneth Nielsen (sharzas @ GitHub.com)
        Version: 1.0

    .LINK
        https://github.com/sharzas/Powershell-Get-StorCLIStatus
    #>

    [CmdletBinding()]

    Param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [AllowNull()]
        [AllowEmptyString()]
        [string[]]$Text,

        [Parameter()]
        [string]$Prefix = "",

        [Parameter()]
        $LogFile = $null,

        [Parameter()]
        [switch]$PassThru = $false,

        [Parameter()]
        [string]$TimeStampFormat = "dd-MM-yyyy HH:mm:ss"
    )

    Begin {
        Write-Verbose ('Out-Log(LogFile={0}): Invoked.' -f $LogFile)

        #$PSBoundParameters.Keys|ForEach-Object {Write-Verbose ('Update-StatusLog(): Parameter supplied to function: {0}' -f $_)}

        $Log = @()
    }


    Process {
        foreach ($item in $Text.Split("`n")) {
            $Log += ('{0} {1}{2}' -f (Get-Date -Format $TimeStampFormat), $Prefix, $item)

            if ($PassThru) {
                # -PassThru specified - pass item down the pipeline as well.
                Write-Output ('{0} {1}{2}' -f (Get-Date -Format $TimeStampFormat), $Prefix, $item)
            }
        }
    }

    End {
        if ($null -ne $LogFile) {
            Write-Verbose ('Out-Log(LogFile={0}): Done processing - logging {1} items to logfile.' -f $LogFile, $Log.Count)

            try {
                # Add data to specified log file
                $Log|Add-Content -Path $LogFile -Encoding UTF8
    
                Write-Verbose ('Out-Log(LogFile={0}): Succesfully written {1} items to logfile.' -f $LogFile, $Log.Count)
            } catch {
                Write-Verbose ('Out-Log(LogFile={0}): FAILED writing items to logfile.' -f $LogFile)

                $PSCmdlet.ThrowTerminatingError((New-ErrorRecord -baseObject $_ `
                    -exceptionMessage ('Error trying to write to LogFile "{0}" - 0x{1:x} - {2}' -f $LogFile, $_.Exception.HResult, $_.Exception.Message) `
                    -errorId "Out-Log" -errorCategory "WriteError" -targetObject $LogFile))
            }
        } else {
            Write-Verbose ('Out-Log(LogFile={0}): Logfile not specified - {1} items is not written to any file.' -f $LogFile, $Log.Count)
        }
    }
} # function Out-Log








function Update-Log
{
    <#
    .SYNOPSIS
        Update text log file per specified parameters.
        
    .DESCRIPTION
        Update text log file per specified parameters.
        
        No update will happen unless parameters specify it.

        The function is intended for log maintenance purposes. Originally intended
        for log pruning.
                
    .PARAMETER PruneLogDate
        If this parameter is specified, the log will be pruned for old entries.

        Specifies the cutover date used for pruning the log.
            
        The content of the LogFile must be lines of String values, and they must include
        a TimeStamp in the beginning of each line, that can be matched to the
        -TimeStampFormat parameter

        Any lines in the log that fails to meet that critera, will be pruned from the
        log.

    .PARAMETER LogFile
        Specifies the LogFile to Update. If this parameter is $null, the function
        exits without doing anything.

        The content of the LogFile must be lines of String values.

    .PARAMETER TimeStampFormat
        This is the DateTime format used by the logging functions. This must be a .NET
        supported TimeProvider format.
        
        IMPORTANT:
        If you change the format using -TimeStampFormat, and you are using any of the
        log pruning options, be aware that your entire log most likely will be pruned
        at first run, or the script may encounter an error.

        It is advisable to backup any logs in need of preservation first, and delete
        log files when changing this format!

    .OUTPUTS
        Success = nothing.
        Failure = Statement Terminating Exception.

    .NOTES
        Author.: Kenneth Nielsen (sharzas @ GitHub.com)
        Version: 1.0
    #>

    [CmdletBinding()]

    Param (
        [Parameter()]
        $LogFile = $null,

        [Parameter()]
        [DateTime]$PruneLogDate = $null,

        [Parameter()]
        [string]$TimeStampFormat = "dd-MM-yyyy HH:mm:ss"
    )

    Write-Verbose ('Update-Log(): Invoked.')

    $PSBoundParameters.Keys|ForEach-Object {Write-Verbose ('Update-Log(): [Parameter] [{0}]{1} = {2}' -f $PSBoundParameters[$_].GetType().FullName, $_, $PSBoundParameters[$_])}

    if ($null -eq $LogFile) {
        Write-Verbose ('Update-Log(): No log file specified - exiting.')
        return
    }

    # declare data storage array
    $Data = @()

    # initial value = we havent modified the data.
    $Modified = $false

    if ((Test-Path -Path $LogFile -PathType Leaf)) {
        Write-Verbose ('Update-Log(): LogFile found: {0}' -f $Logfile)

        if ($PSBoundParameters.ContainsKey("PruneLogDate") -or ($null -ne $PruneLogDate)) {
            #
            # We should prune the log.
            #
            try {
                $Data = @(Get-Content $LogFile)
    
                Write-Verbose ('Update-Log(): Succesfully loaded {0} lines from LogFile {1}' -f $Data.Count, $LogFile)
            } catch {
                Write-Warning ('Update-Log(): Failed to load LogFile {0}' -f $LogFile)
                Write-Warning ('Update-Log(): ')
                Write-Warning ('Update-Log(): Log will not be updated.')
                Write-Warning ('Update-Log(): ')

                $PSCmdlet.ThrowTerminatingError((New-ErrorRecord -baseObject $_ `
                    -exceptionMessage ('Error trying to load LogFile "{0}" - 0x{1:x} - {2}' -f $LogFile, $_.Exception.HResult, $_.Exception.Message) `
                    -errorId "Update-Log" -errorCategory "ReadError" -targetObject $LogFile))
            }

            # we should prune the log, for entries older than the date specified in -PruneLogDate
            Write-Verbose ('Update-Log(): Pruning Log for entries dated earlier than {0}' -f $PruneLogDate)
    
            # Get current entry count.
            $Entries = $Data.Count
            
            # build RegExp pattern to use for splitting the text in the log file, so we can separate
            # the timestamp, in order to correctly prune the log.
            $Pattern = "(^$((($TimeStampFormat -replace 'h|m|s|d|y','0') -replace '(\*|\+|\.|\[|\]|\^|\$|\\)','\$1') -replace '0','\d'))"
            
            # we need a variable of type DateTime to reference for the TryParse function.
            [DateTime]$DateRef = Get-Date

            # remove all lines with a timestamp older than the Prune date.
            $Data = @(($Data|Select-String $Pattern| `
                Where-Object {[DateTime]::TryParse($_.Matches[0].Groups[1].Value, [ref]$DateRef)}| `
                Where-Object {[DateTime]::Parse($_.Matches[0].Groups[1].Value) -gt $PruneLogDate} `
            )|Select-Object -ExpandProperty Line)  # important to grab the line property, or powershell will truncate lines!!!

            Write-Verbose ('Update-Log(): Succesfully pruned {0} entries from LogFile' -f ($Entries - $Data.Count))

            if (($Entries - $Data.Count) -gt 0) {
                # We modified the data, so it should be written back.
                $Modified = $true
            }
        }

        if ($Modified) {
            # data modified - we will attempt to write it back
            Write-Verbose ('Update-Log(): Data was modified = "{0}" - will write data back to log' -f $Modified)

            try {
                $Data|Set-Content -Path $StatusLogFile -Encoding UTF8
    
                Write-Verbose ('Update-Log(): Succesfully written {0} entries to LogFile {1}' -f $Data.Count, $LogFile)
            } catch {
                $PSCmdlet.ThrowTerminatingError((New-ErrorRecord -baseObject $_ `
                    -exceptionMessage ('Error trying to write to LogFile "{0}" - 0x{1:x} - {2}' -f $LogFile, $_.Exception.HResult, $_.Exception.Message) `
                    -errorId "Update-Log" -errorCategory "WriteError" -targetObject $LogFile))
            }
        } else {
            # data not modified, no need to update the file.
            Write-Verbose ('Update-Log(): Data was modified = "{0}" - will not update log file!' -f $Modified)            
        }
    } else {
        # LogFile not found, so we'll do nothing.
        Write-Verbose ('Update-Log(): LogFile NOT found - no action taken: {0}' -f $Logfile)
    }
} # function Update-Log







function Resolve-Error
{
       <#
    .SYNOPSIS
        Resolves an Error records various properties, and outputs it in verbose format.

    .DESCRIPTION
        Resolves an Error records various properties, and outputs it in verbose format.
        
        It will also unwind Exception chain.

        NOTE:
        All output will be piped through Out-String, with a preset width, in order to
        make custom logging easier to implement - default width is 160
        
    .PARAMETER ErrorRecord
        The ErrorRecord to resolve, will use last error by default.

    .PARAMETER Width
        The width of the console/output to which the ErrorRecord will be formatted.

        Default is 160

    .EXAMPLE
        Resolve-Error -ErrorRecord $Error[1]

        Will resolve the 2nd error in the list of errors.

    .EXAMPLE
        try {
            Throw "this is a test error!"
        } catch {
            Resolve-Error -ErrorRecord $_
        }

        Will resolve the error that was thrown.

    .EXAMPLE
        try {
            Throw "this is a test error!"
        } catch {
            Resolve-Error -ErrorRecord $_ -Width 200
        }

        Will resolve the error that was thrown width a custom Width

    .OUTPUTS
        ErrorRecord(s) in string formatted output.

    .NOTES
        Author.: Kenneth Nielsen (sharzas @ GitHub.com)
        Version: 1.0

        Credit goes to MSFT Jeffrey Snower who made the source version I used
        as base for this function!

        Link under links to his original version.

    .LINK
        https://devblogs.microsoft.com/powershell/resolve-error/
    #>
    [CmdletBinding()]
    Param (
        [Parameter(ValueFromPipeline)]
        $ErrorRecord=$Error[0],

        [Parameter()]
        $Width = 140
    )

    $ExceptionChainIndent = 3
    
    $Property = ("*",($ErrorRecord|Get-Member -MemberType Properties -Name "HResult"|Where-Object {$_}|ForEach-Object {@{n="HResult"; e={"0x{0:x}" -f $_.HResult}}})|Where-Object {$_})

    $ErrorRecord|Select-Object -Property $Property -ExcludeProperty HResult |Format-List -Force|Out-String -Stream -Width $Width
    $ErrorRecord.InvocationInfo|Format-List *|Out-String -Stream -Width $Width
    $Exception = $ErrorRecord.Exception

    for ($i = 0; $Exception; $i++, ($Exception = $Exception.InnerException))
    {   
        # Build Exception Separator with respect for Width
        $ExceptionSeparator = " [Exception Chain - Exception #{0}] " -f [string]$i
        $ExceptionSeparator = "{0}{1}{2}" -f ("-"*$ExceptionChainIndent),$ExceptionSeparator,("-"*($Width - ($ExceptionChainIndent + $ExceptionSeparator.Length)))

        $ExceptionSeparator|Out-String -Stream -Width $Width
        $Exception|Select-Object -Property *,@{n="HResult"; e={"0x{0:x}" -f $_.HResult}} -ExcludeProperty HResult|Format-List * -Force|Out-String -Stream -Width $Width
    }
} # function Resolve-Error







function Send-Mail
{
    <#
    .SYNOPSIS
        Send email message.

    .DESCRIPTION
        Send email message. 
        
        Support for:
        - Attachments
        - HTML body
        - Authentication
        - SSL
        
    .PARAMETER SMTPHost
        SMTP server to use for sending the mail.

    .PARAMETER SMTPPort
        SMTP server TCP Port.

    .PARAMETER From
        From mail address.
        
        Use hashtable form to supply a display name.

        This parameter must be one of the following:
        
        [string]    "mailaddress@domain.com"
        [hashtable] @{"mailaddress@domain.com" = "Displayname"}

        If you use a hashtable, it must have exactly 1 item.
        
    .PARAMETER Recipient
        Recipient(s) mail address(es).
        
        This parameter can be either a single item, or an array.

        Each item in the array must be one of the following.
        
        [string]    "mailaddress@domain.com"
        [hashtable] @{"mailaddress@domain.com" = "Displayname"}
        [hashtable] @{
                        "mailaddress1@domain.com" = "Displayname"
                        "mailaddress2@otherdomain.com" = "Displayname"
                    }

        NOTE: for recipient address, hashtables can contain multiple entries.

    .PARAMETER Subject
        Subject of the mail

    .PARAMETER Body
        Body of the mail in text/plain format. Use this parameter if you have formatted
        your mail as text only.
                
    .PARAMETER BodyHTML
        Body of the mail in text/html format. Use this parameter if you have formatted
        your mail as HTML.        

    .PARAMETER AttachmentFile
        One or more files to attach to the mail. This can be either a single string, or
        an array of strings.

    .PARAMETER AttachmentText
        One or more attachments to construct from text. Will be attached as text files.

        This can an array or a single item. Each item must be one of the following:

        [string]    "attachment text"
        [hashtable] @{"filename" = "attachment text"}

        In case of a [string] value, a filename will be constructed using increasing numbers:

        "Attachment_1.txt"
        "Attachment_2.txt"
        ...

    .PARAMETER Username
        Username to use for SMTP server authentication. 
        
        If unspecified, no authentication will be attempted.

    .PARAMETER Password
        Password to use for SMTP server authentication. Can be supplied as [string] or [securestring]
        
    .PARAMETER EnableSSL
        Use SSL when communicating with the SMTP host.

    .EXAMPLE
        Send-Mail -SMTPHost mysmtp.mydomain.com -SMTPPort 25 -From bofh@mydomain.com -Recipient "pooruser@mydomain.com" -Subject "Reboot notification" -Body "The system was rebooted 5 minutes ago fyi"

        Sends normal text mail to pooruser@mydomain.com, using the SMTP mail server at mysmtp.mydomain.com:25.
        Mail addresses are specified using simple strings (no display name included)

    .EXAMPLE
        One of below:
        Send-Mail -SMTPHost mysmtp.mydomain.com -SMTPPort 25 -From @{"bofh@mydomain.com" = "Bastard Operator From Hell"} -Recipient @{"pooruser@mydomain.com" = "Poor user 1"},@{"pooruser2@mydomain.com" = "Poor user 2"} -Subject "Reboot notification" -Body "The system was rebooted 5 minutes ago fyi"

        Send-Mail -SMTPHost mysmtp.mydomain.com -SMTPPort 25 -From @{"bofh@mydomain.com" = "Bastard Operator From Hell"} -Recipient @{"pooruser@mydomain.com" = "Poor user 1"; "pooruser2@mydomain.com" = "Poor user 2"} -Subject "Reboot notification" -Body "The system was rebooted 5 minutes ago fyi"

        Both of the above commands sends normal text mail to pooruser@mydomain.com and pooruser2@mydomain.com, using the SMTP 
        mail server at mysmtp.mydomain.com:25. Mail addresses are specified using hashtables (display name included).

    .EXAMPLE
        $HTML = "<html><body><p>This is a HTML formatted mail - btw the system was rebooted 5 mins ago fyi</p></body></html>"

        Send-Mail -SMTPHost mysmtp.mydomain.com -SMTPPort 25 -From bofh@mydomain.com -Recipient "pooruser@mydomain.com" -Subject "Reboot notification" -BodyHTML $HTML

        Sends HTML formatted mail to pooruser@mydomain.com, using the SMTP mail server at mysmtp.mydomain.com:25. 
        Mail addresses are specified using simple strings (no display name included)

    .EXAMPLE
        $HTML = "<html><body><p>This is a HTML formatted mail - btw the system was rebooted 5 mins ago fyi</p></body></html>"

        Send-Mail -SMTPHost mysmtp.mydomain.com -SMTPPort 25 -From bofh@mydomain.com -Recipient "pooruser@mydomain.com" -Subject "Reboot notification" -BodyHTML $HTML -AttachmentFile "file1.zip","file2.zip"

        Sends HTML formatted mail to pooruser@mydomain.com, using the SMTP mail server at mysmtp.mydomain.com:25. 
        
        Following files are attached to the mail:

        file1.zip
        file2.zip

    .EXAMPLE
        $HTML = "<html><body><p>This is a HTML formatted mail - btw the system was rebooted 5 mins ago fyi</p></body></html>"

        Send-Mail -SMTPHost mysmtp.mydomain.com -SMTPPort 25 -From bofh@mydomain.com -Recipient "pooruser@mydomain.com" -Subject "Reboot notification" -BodyHTML $HTML -AttachmentText "This is a textfile attachment",@{"file.txt" = "This is another text attachment"}

        Sends HTML formatted mail to pooruser@mydomain.com, using the SMTP mail server at mysmtp.mydomain.com:25. 
        
        Following files are attached to the mail:
        
        Attachment_1.txt
        file.txt

        Above is produced from the text in the parameters.

    .OUTPUTS
        Nothing but a status.


    .NOTES
        Author.: Kenneth Nielsen (sharzas @ GitHub.com)
        Version: 1.0

    .LINK
        https://github.com/sharzas/Powershell-Get-StorCLIStatus
    #>
    [CmdletBinding()]

    Param (
        [Parameter(Mandatory = $true)]
        [string]$SMTPHost,

        [Parameter()]
        [Int32]$SMTPPort = 25,

        [Parameter(Mandatory = $true, HelpMessage = 'Format is [HashTable]@{Address = DisplayName} or [String]"Address".' )]
        [ValidateNotNullOrEmpty()]
        $From,

        [Parameter(Mandatory = $true, HelpMessage = 'Format is array of [HashTable]@{Address = DisplayName} or [String]"Address". These can be combined, e.g. @{Address = DisplayName},"Address"' )]
        [ValidateNotNullOrEmpty()]
        $Recipient,

        [Parameter()]
        [string]$Subject = "",

        [Parameter()]
        $Body = "",

        [Parameter()]
        $BodyHTML = "",

        [Parameter()]
        [string[]]$AttachmentFile,

        [Parameter()]
        $AttachmentText,

        [Parameter()]
        [string]$Username = "",

        [Parameter()]
        $Password = $null,

        [Parameter()]
        [switch]$EnableSSL = $false

    )
    Write-Verbose ('Send-Mail(): Invoked')

    $BaseException = @{
        exceptionType = "System.ArgumentException"
        errorId = "Send-Mail.Parameters( -From )"
        errorCategory = "InvalidData"
    }

    # validate from parameter
    if ($From -isnot [Hashtable] -and $From -isnot [string]) {
        $PSCmdlet.ThrowTerminatingError((New-ErrorRecord @BaseException -exceptionMessage '-From is incorrect data type! See help for allowed types!' -targetObject $From))
    }

    if ($From -is [HashTable]) {
        if ($From.Count -ne 1) {
            $PSCmdlet.ThrowTerminatingError((New-ErrorRecord @BaseException -exceptionMessage ('-From = HashTable with {0} entries - count must be exactly 1!' -f $From.Count) -targetObject $From))
        } else {
            Write-Verbose ('Send-Mail(): [Parameter] -From specified as HashTable - {0} items' -f $From.Count)
        }
    } elseif ($From -is [String]) {
        Write-Verbose ('Send-Mail(): [Parameter] -From specified as String')
    }

    # validate recipient parameter
    if ($Recipient -isnot [HashTable] -and $Recipient -isnot [String] -and $Recipient -isnot [String[]] -and $Recipient -isnot [Array]) {
        $BaseException["errorId"] = "Send-Mail.Parameters( -Recipient )"
        $PSCmdlet.ThrowTerminatingError((New-ErrorRecord @BaseException -exceptionMessage '-From is incorrect data type! See help for allowed types!' -targetObject $From))
    }

    $BaseException["errorId"] = "Send-Mail"
    $BaseException.Remove("errorCategory")

    # If the Body parameter is specified, and is an array, join the array to a string value instead
    #
    # This is required in order to use it with the MailMessage class
    #
    If ($Body -ne "" -and $Body -ne $null) {
        If ($Body -is [array]) {
            Write-Verbose ('Send-Mail(): [Parameter] -Body specified as array - converted to String')
            [string]$Body = $Body -join "`n"
        }
    }


    # If the BodyHTML parameter is specified, and is an array, join the array to a string value instead
    #
    # This is required in order to use it with the MailMessage class
    #
    If ($BodyHTML -ne "" -and $BodyHTML -ne $null) {
        If ($BodyHTML -is [array]) {
            Write-Verbose ('Send-Mail(): [Parameter] -BodyHTML specified as array - converted to String')
            [string]$BodyHTML = $BodyHTML -join "`n"
        }
    }



    #
    # Create and set SMTP Client options:
    #
    $SMTPClient = New-Object System.Net.Mail.SmtpClient

    Write-Verbose ('Send-Mail(): [SMTPClient] SMTP Host.........: "{0}"' -f $SMTPHost)
    Write-Verbose ('Send-Mail(): [SMTPClient] SMTP Port.........: "{0}"' -f $SMTPPort)
    Write-Verbose ('Send-Mail(): [SMTPClient] SMTP Enable SSL...: "{0}"' -f $EnableSSL)


    $SMTPClient.Host = $SMTPHost
    $SMTPClient.Port = $SMTPPort
    $SMTPClient.EnableSSL = $EnableSSL


    If ($Username -ne "") {
        #
        # Username specified - so built credentials, and set them on the SMTP client object.
        #
        Write-Verbose ('Send-Mail(): [SMTPClient] Username specified: "{0}"' -f $Username)
        Write-Verbose ('Send-Mail(): [SMTPClient] Password .........: "***"')

        if ($null -ne $Password) {
            if ($Password -isnot [SecureString]) {
                # password specified - but is not SecureString, so convert it.
                $SecPassWd = ConvertTo-SecureString $Password -AsPlainText -Force
            }
        } else {
            # no password specified - so convert empty string to SecureString
            $SecPassWd = ConvertTo-SecureString "" -AsPlainText -Force
        }
        
        $Credentials = New-Object System.Management.Automation.PSCredential ($Username, $SecPassWd)

        $SMTPClient.Credentials = $Credentials.GetNetworkCredential()
    }
    #
    # Done creating SMTP client
    #





    # create new mail message, and set default parameters.
    $Message = New-Object System.Net.Mail.MailMessage

    $Message.BodyTransferEncoding = [System.Net.Mime.TransferEncoding]::Base64
    $Message.BodyEncoding = [System.Text.Encoding]::UTF8
    $Message.HeadersEncoding = [System.Text.Encoding]::UTF8
    $Message.SubjectEncoding = [System.Text.Encoding]::UTF8

    Write-Verbose ('Send-Mail(): [Message] [Subject] ...........: "{0}"' -f $Subject)
    $Message.Subject = $Subject


    if ($From -is [hashtable]) {
        # hashtable - loop through keys (addresses), however ensure only 1 is used.
        foreach ($Address in @($From.Keys)[0]) {
            Write-Verbose ('Send-Mail(): [Message] [Sender]      [HashTable] Adding from: {0} <{1}>' -f $From[$Address], $Address)

            try {
                # set .From / .Sender property 
                $Message.From = (New-Object System.Net.Mail.MailAddress($Address, $From[$Address], [System.Text.Encoding]::UTF8))
                $Message.Sender = (New-Object System.Net.Mail.MailAddress($Address, $From[$Address], [System.Text.Encoding]::UTF8))
            } catch {
                # unable to set sender.
                $PSCmdlet.ThrowTerminatingError((New-ErrorRecord @BaseException `
                    -baseObject $_ `
                    -exceptionMessage ('Error setting .From/.Sender property using the values "{0}", "{1}" - is the format correct? - 0x{2:X} - {3}' -f $Address, $From[$Address], $_.Exception.HResult, $_.Exception.Message) `
                    -errorCategory "InvalidArgument" `
                    -targetObject ('{0} <{1}>' -f $From[$Address], $Address)))
            }
        }

    } elseif ($From -is [string]) {
        # string - use as is.
        Write-Verbose ('Send-Mail(): [Message] [Sender]      [Text]      Adding from: {0} <{1}>' -f $From, $From)

        try {    
            # set .From / .Sender property 
            $Message.From = (New-Object System.Net.Mail.MailAddress($From))
            $Message.Sender = (New-Object System.Net.Mail.MailAddress($From))
        } catch {
            # unable to set sender.
            $PSCmdlet.ThrowTerminatingError((New-ErrorRecord @BaseException `
                -baseObject $_ `
                -exceptionMessage ('Error setting .From/.Sender property using the values "{0}", "{1}" - is the format correct? - 0x{2:X} - {3}' -f $Address, $From[$Address], $_.Exception.HResult, $_.Exception.Message) `
                -errorCategory "InvalidArgument" `
                -targetObject ('{0} <{0}>' -f $From)))
        }
    } else {
        # something else - bail
        Write-Warning ('Send-Mail(): [Message] [Sender]    [ERROR]     Invalid Parameter type specified: {0}' -f $From.Gettype())

        break # bail
    }


    # foreach loop, because there may be more than one Recipient
    #
    foreach ($item in $Recipient) {
        if ($item -is [hashtable]) {
            foreach ($Address in $item.Keys) {
                Write-Verbose ('Send-Mail(): [Message] [Recipient] [HashTable] Adding recipient: {0} <{1}>' -f $item[$Address], $Address)

                try {
                    # attempt to add recipient
                    $Message.To.Add((New-Object System.Net.Mail.MailAddress($Address, $item[$Address], [System.Text.Encoding]::UTF8)))
                } catch {
                    # failed to add recipient
                    $PSCmdlet.ThrowTerminatingError((New-ErrorRecord @BaseException `
                        -baseObject $_ `
                        -exceptionMessage ('Error adding recipient to .To collection using the values "{0}", "{1}" - is the format correct? - 0x{2:X} - {3}' -f $item[$Address], $Address, $_.Exception.HResult, $_.Exception.Message) `
                        -errorCategory "InvalidArgument" `
                        -targetObject ('{0} <{1}>' -f $Address, $item[$Address])))
                }
            }

        } elseif ($item -is [string]) {
            Write-Verbose ('Send-Mail(): [Message] [Recipient] [Text]      Adding recipient: {0} <{1}>' -f $item, $item)

            try {
                # attempt to add recipient
                $Message.To.Add((New-Object System.Net.Mail.MailAddress($item)))
            } catch {
                # failed to add recipient
                Write-Verbose ('Send-Mail(): [Message] [Recipient] [Text]      ERROR: Adding recipient: {0} <{1}>' -f $item, $item)

                $PSCmdlet.ThrowTerminatingError((New-ErrorRecord @BaseException `
                    -baseObject $_ `
                    -exceptionMessage ('Error adding recipient to .To collection using the values "{0}", "{1}" - is the format correct? - 0x{2:X} - {3}' -f $item[$Address], $Address, $_.Exception.HResult, $_.Exception.Message) `
                    -errorCategory "InvalidArgument" `
                    -targetObject ('{0} <{0}>' -f $item)))
            }
        } else {
            Write-Warning ('Send-Mail(): [Message] [Recipient] [ERROR]     Invalid Parameter type specified: {0}' -f $Address.Gettype())
        }
    }



    # If Normal text body is specified, set it.
    #
    If ($Body -ne "" -and $Body -ne $null) {
        Write-Verbose ('Send-Mail(): [Message] Text Body specified.')

        $Message.Body = $Body
    }


    # If HTML body is specified, add it as an alternate view.
    #
    If ($BodyHTML -ne "" -and $BodyHTML -ne $null) {
        Write-Verbose ('Send-Mail(): [Message] HTML Body specified - will add as alternate view')

        # Define mime class to use with the alternate view.
        #
        $mimeHTML = [System.Net.Mime.ContentType][System.Net.Mime.MediaTypeNames+Text]::Html

        $HTMLView = [System.Net.Mail.AlternateView]::CreateAlternateViewFromString($BodyHTML, $mimeHTML)
        
        $Message.AlternateViews.Add($HTMLView)
    }


    If ($PSBoundParameters.Keys.Contains("attachmentfile")) {
        #
        # Some attachment(s) was specified - go grab it/them and attach it to the message
        #
        ForEach ($Item in $AttachmentFile) {
            Write-Verbose ('Send-Mail(): [Attachment] [Filename]  Adding File Attachement - filename: {0}' -f $Item)

            $Att = New-Object System.Net.Mail.Attachment($Item)

            $Message.Attachments.Add($Att)
        }
    }


    If ($PSBoundParameters.Keys.Contains("attachmenttext")) {
        #
        # Some attachment(s) was specified as text - build it/them and attach it to the message
        #
        $i = 0
        ForEach ($Item in $AttachmentText) {

            if ($Item -is [Hashtable]) {
                # this attachment is represented as a HashTable. In that case, it is considered a collection of 1 or more
                # attachments, structed like this:
                #
                # Key   = filename
                # Value = Attachment content in [string] format.
                #
                # @{"filename.txt" = "This is the content of the file."}
                #
                foreach ($Key in $Item.Keys) {
                    Write-Verbose ('Send-Mail(): [Attachment] [HashTable] Adding Text Attachement - filename: {0}' -f $Key)
                    $Att = [System.Net.Mail.Attachment]::CreateAttachmentFromString($Item[$Key], $Key, [System.Text.Encoding]::UTF8, [System.Net.Mime.MediaTypeNames+Text]::Plain)
                }
            } else {
                # this attachment is just a string. In this case a filename is not specified, so we will auto-generate one.
                Write-Verbose ('Send-Mail(): [Attachment] [Text]      Adding Text Attachement - filename: {0}' -f "Attachment_$i.txt")
                $i++
                $Att = [System.Net.Mail.Attachment]::CreateAttachmentFromString($Item, "Attachment_$i.txt", [System.Text.Encoding]::UTF8, [System.Net.Mime.MediaTypeNames+Text]::Plain)
            }

            $Message.Attachments.Add($Att)
        }
    }

    #$Message

    # Send message
    #
    try {
        $SMTPClient.Send($Message)
    } catch {
        $PSCmdlet.ThrowTerminatingError((New-ErrorRecord @BaseException `
            -baseObject $_ `
            -exceptionMessage ('Error calling SMTPClient.Send{0} - 0x{1:X}{0} - {2}' -f "`r`n", $_.Exception.HResult, $_.Exception.Message) `
            -targetObject $Message))
    }
} # function Send-Mail















function Test-StorCLIStatus
{
    [CmdletBinding()]

    Param (
        [Parameter()]
        [switch]$EnableSSL = $false,
        
        [Parameter()]
        $From,
        
        [Parameter()]
        $Password = $null,

        [Parameter()]
        $Recipient,

        [Parameter()]
        [switch]$SendMailAsText = $false,
    
        [Parameter()]
        [switch]$SendMailWithReport = $false,
    
        [Parameter()]
        [switch]$SendMailOnError = $false,
    
        [Parameter()]
        [string]$SMTPHost,
    
        [Parameter()]
        [Int32]$SMTPPort = 25,
        
        [Parameter()]
        $StorCLI,

        [Parameter()]
        [string]$Username = ""
    )

    Write-Verbose ('Test-StorCLIStatus(): Status @ {0} = {1}' -f $StorCLI.Status.StateTime, $StorCLI.Status.State)

    $Status = [PSCustomObject]@{
        AdditionalInformation = @()
        Status = $StorCLI.Status.State
        Log = $null
    }

    # There is a chance we're gonna send a mail, so prepare by constructing
    # parameters for Send-Mail, which we're gonna use to send the mail.
    $MailParams = @{}

    if ($SendMailOnError -or $SendMailWithReport) {        
        @("SMTPHost","SMTPPort","From","Recipient")|ForEach-Object {
            # these are mandatory parameters
            if ($PSBoundParameters.ContainsKey($_)) {
                # parameter specified
                Write-Verbose ('Test-StorCLIStatus(): Adding Mandatory parameter for Send-Mail "{0}" = "{1}"' -f $_, $PSBoundParameters[$_])

                $MailParams[$_] = $PSBoundParameters[$_]
            } else {
                # parameter NOT specified - bail
                Write-Warning ('Test-StorCLIStatus(): [ERROR] You specified -SendMainOnError, but mandatory parameter is missing "{0}"' -f $_)
                Exit 2
            }
        }

        if ($PSBoundParameters.ContainsKey("Subject")) {
            # subject specified on command line - use that
            Write-Verbose ('Test-StorCLIStatus(): Adding optional parameter for Send-Mail "{0}" = "{1}"' -f "Subject", $PSBoundParameters["Subject"])

            $MailParams["Subject"] = $PSBoundParameters["Subject"]
        } else {
            # subject not specified on command line - construct one.

            if ($StorCLI.Status.State -ne "OK") {
                $MailParams["Subject"] = ('{0}: [ERROR] Raid Controller Error' -f $StorCLI.Status.ReportHostname)
            } else {
                $MailParams["Subject"] = ('{0}: [OK] Raid Controller Status Report' -f $StorCLI.Status.ReportHostname)
            }

            Write-Verbose ('Test-StorCLIStatus(): Constructing parameter for Send-Mail "{0}" = "{1}"' -f "Subject", $MailParams["Subject"])

        }

        @("Username","Password","EnableSSL")|ForEach-Object {
            # these are optional parameters
            if ($PSBoundParameters.ContainsKey($_)) {
                # parameter specified
                Write-Verbose ('Test-StorCLIStatus(): Adding optional parameter for Send-Mail1 "{0}" = "{1}"' -f $_, $PSBoundParameters[$_])

                $MailParams[$_] = $PSBoundParameters[$_]
            }
        }

        # Get timestamp that can be included in filename.
        $TimeStamp = (Get-Date($StorCLI.Status.StateTime) -Format $TimeStampFormat).Replace(" ", "__").Replace(":",".").Replace("-",".")

        # build initial attachment - which is the full report. If there is an error, we're gonna add
        # error report later.
        $MailParams["AttachmentText"] = @(@{"FullReport_$($StorCLI.Status.ReportHostname)_$($TimeStamp).html" = ($StorCLI.Status.Report.FullHTML -join "`n")})
    }


    Write-Verbose ('Test-StorCLIStatus(): [{0}] Raid Controller is in state "{0}"' -f $StorCLI.Status.State.ToString().ToUpper())
    $Log = @(('Test-StorCLIStatus(): [{0}] Raid Controller is in state "{0}"' -f $StorCLI.Status.State.ToString().ToUpper()))

    if ($StorCLI.Status.State -eq "OK") {
        # state ok

        # add relevant full report as Mail Body, to be used if we have to send a mail.
        if ($SendMailAsText) {
            $MailParams["Body"] = $StorCLI.Status.Report.Full -join "`r`n"
        } else {
            $MailParams["BodyHTML"] = $StorCLI.Status.Report.FullHTML
        }
    } else {
        # state is not ok, do something!
        Write-Warning ('Test-StorCLIStatus(): Raid Controller is in state "{0}"' -f $StorCLI.Status.State)

        # add relevant error report as Mail Body, to be used if we have to send a mail.
        if ($SendMailAsText) {
            $MailParams["Body"] = $StorCLI.Status.Report.Error -join "`r`n"
        } else {
            $MailParams["BodyHTML"] = $StorCLI.Status.Report.ErrorHTML
        }

        if ($SendMailOnError -or $SendMailWithReport) {
            # we should send a report - add error report as attachment.
            Write-Warning ('Test-StorCLIStatus(): -SendMailOnError or -SendMailWithReport specified - attempting to send mail.')

            $MailParams["AttachmentText"] += @{"ErrorReport_$($StorCLI.Status.ReportHostname)_$($TimeStamp).html" = ($StorCLI.Status.Report.ErrorHTML -join "`n")}
        }
    }

    if ($SendMailWithReport -or ($StorCLI.Status.State -ne "OK" -and $SendMailOnError)) {
        # criteria for sending mail is fullfilled - so go ahead.

        try {
            # attempt to send mail.
            Send-Mail @MailParams

            if ($StorCLI.Status.State -ne "OK") {
                Write-Warning "Test-StorCLIStatus(): Mail succesfully sent."
            } else {
                Write-Verbose "Test-StorCLIStatus(): Mail succesfully sent."
            }

            $Log += ('Test-StorCLIStatus(): [{0}] Mail succesfully sent.' -f $StorCLI.Status.State)
            $Status.AdditionalInformation += ('Test-StorCLIStatus(): [{0}] Mail succesfully sent.' -f $StorCLI.Status.State)

        } catch {
            # error sending mail
            Write-Warning ('Test-StorCLIStatus(): ERROR SENDING MAIL!')
            Write-Warning ('Test-StorCLIStatus(): ')
            Write-Warning ('Test-StorCLIStatus(): Exception.............: "{0}"' -f $_.Exception.Gettype().Name)
            Write-Warning ('Test-StorCLIStatus(): Message...............: "{0}"' -f $_.Exception.Message)
            Write-Warning ('Test-StorCLIStatus(): HResult...............: "0x{0:x}"' -f $_.Exception.HResult)

            $Log += ('Test-StorCLIStatus(): [ERROR] ERROR SENDING MAIL!')
            $Log += ('Test-StorCLIStatus(): [ERROR] ')
            $Log += ('Test-StorCLIStatus(): [ERROR] Exception.............: "{0}"' -f $_.Exception.Gettype().Name)
            $Log += ('Test-StorCLIStatus(): [ERROR] Message...............: "{0}"' -f $_.Exception.Message)
            $Log += ('Test-StorCLIStatus(): [ERROR] HResult...............: "0x{0:x}"' -f $_.Exception.HResult)

            $e = $_.Exception.InnerException

            While ($null -ne $e) {
                # unwind any InnerExceptions as well.
                Write-Warning ('Test-StorCLIStatus(): InnerException.Message: "{0}"' -f $_.Exception.InnerException.Message)
                Write-Warning ('Test-StorCLIStatus(): InnerException.HResult: "0x{0:x}"' -f $_.Exception.InnerException.HResult)
    
                $Log += ('Test-StorCLIStatus(): [ERROR] InnerException.Message: "{0}"' -f $e.Message)
                $Log += ('Test-StorCLIStatus(): [ERROR] InnerException.HResult: "0x{0:x}"' -f $e.HResult)

                $e = $e.InnerException
            }

            Write-Warning ('Test-StorCLIStatus(): ')

            $Log += ('Test-StorCLIStatus(): [ERROR] ')
            
            # re-throw
            $PSCmdlet.ThrowTerminatingError((New-ErrorRecord -baseObject $_ -errorId "Test-StorCLIStatus - send mail."))
        }
    } else {
        if ($StorCLI.Status.State -ne "OK") {
            Write-Warning "Test-StorCLIStatus(): -SendMailOnError or -SendMailWithReport not specified: No mail is sent."
            $Log += "Test-StorCLIStatus(): [ERROR] -SendMailOnError or -SendMailWithReport not specified: No mail is sent."
        } else {
            Write-Verbose "Test-StorCLIStatus(): -SendMailWithReport not specified: No mail is sent."            
            $Log += "Test-StorCLIStatus(): [OK] -SendMailWithReport not specified: No mail is sent."
        }
    }

    $Status.Log = $Log

    return $Status
} # function Test-StorCLIStatus












function Update-DataLog
{
    <#
    .SYNOPSIS
        Update the data log per specified parameters.
        
    .DESCRIPTION
        Update the data log per specified parameters.
        
        No update will happen unless parameters specify it.

        NOTE:
        This is an internal helper function. It should only be called from
        Invoke-Main

    .PARAMETER DataLogFile
        If specified, Data will be logged in xml form to this file, using
        Export-CliXML.
        
        Pruning options are available for this log, to prevent it growing uncontrollably

    .PARAMETER NewData
        The data to add to the log. This must either be a string, or an array of
        strings.
                
    .PARAMETER PruneDataLog
        If specified, the data log will be pruned according to -PruneDataLogBefore.
        
        All entries dated earlier than the date specified in -PruneDataLogBefore,
        will be removed from the log.
        
    .PARAMETER PruneDataLogBefore
        Specifies the cutover date used for pruning the data log. See -PruneDataLog
        for more information.
        
        If this parameter is not specified, the default is 365 days in the past.

    .OUTPUTS
        Success = nothing.
        Failure = Terminating Exception.
        

    .NOTES
        Author.: Kenneth Nielsen (sharzas @ GitHub.com)
        Version: 1.0

        NOTE:
        This is an internal helper function. It should only be called from
        Invoke-Main

    .LINK
        https://github.com/sharzas/Powershell-Get-StorCLIStatus
    #>

    [CmdletBinding()]

    Param (
        [Parameter()]
        $DataLogFile = $null,

        [Parameter()]
        [switch]$PruneDataLog = $false,

        [Parameter()]
        [DateTime]$PruneDataLogBefore = (Get-Date).AddDays(-365),

        [Parameter()]
        $NewData
    )

    Write-Verbose ('Update-DataLog(): Invoked.')

    $PSBoundParameters.Keys|ForEach-Object {Write-Verbose ('Update-DataLog(): Parameter supplied to function: {0}' -f $_)}

    if ($null -ne $DataLogFile) {

        if ((Test-Path -Path $DataLogFile -PathType Leaf)) {
            Write-Verbose ('Update-DataLog(): DataLogFile found - it will be updated: {0}' -f $DataLogfile)            

            try {
                $Data = @(Import-Clixml -Path $DataLogFile)
    
                Write-Verbose ('Update-DataLog(): Succesfully imported {0} entries from DataLogFile {1}' -f $Data.Count, $DataLogFile)
            } catch {
                Write-Warning ('Update-DataLog(): Failed to import DataLogFile {0}' -f $DataLogFile)
                Write-Warning ('Update-DataLog(): ')
                Write-Warning ('Update-DataLog(): The file exists, but the format may be invalid. Cannot handle this file. Please')
                Write-Warning ('Update-DataLog(): specify another file, or delete this file, to create a new clean one.')
                Write-Warning ('Update-DataLog(): ')
                Write-Warning ('Update-DataLog(): Data will not be logged.')
                Write-Warning ('Update-DataLog(): ')
    
                $PSCmdlet.ThrowTerminatingError((New-ErrorRecord -baseObject $_ `
                    -exceptionMessage ('Error trying to import DataLogFile "{0}" - 0x{1:X} - {2}' -f $DataLogFile, $_.Exception.HResult, $_.Exception.Message) `
                    -errorId "Update-DataLog" -errorCategory "ReadError" -targetObject $DataLogFile))
            }    
        } else {
            Write-Verbose ('Update-DataLog(): DataLogFile not found - new will be created: {0}' -f $DataLogfile)

            $Data = @()
        }


        if ($null -ne $NewData) {
            # New data to add to the log file is specified.
            Write-Verbose ('Update-DataLog(): Adding new data set to data log.')

            $Data += $NewData
        }

        # Get current entry count.
        $Entries = $Data.Count

        if ($PruneDataLog) {
            # we should prune the datalog, for entries older than the date specified in -PruneDataLogBefore
            Write-Verbose ('Update-DataLog(): Pruning DataLog for entries dated earlier than {0}' -f $PruneDataLogBefore)

            if ($null -ne $Data.Basics.'Current System Date/time') {
                # we have a date present in the datalog we can use to determine which entries to remove

                $Data = @($Data|Where-Object {$_.Basics.'Current System Date/time' -gt $PruneDataLogBefore})

                Write-Verbose ('Update-DataLog(): Succesfully pruned {0} entries from DataLogFile' -f ($Entries - $Data.Count))
            } else {
                # we dont have a date in the datalog.            
                Write-Warning ('Update-DataLog(): Property .Basics.''Current System Date/time'' not found. Log will not be pruned!')
                Write-Warning ('Update-DataLog(): ')
            }
        }

        if ($null -ne $Data.Basics.'Current System Date/time') {
            # we have a date present in the datalog we can use to sort entries on
            $Data = $Data|Sort-Object -Property {$_.Basics.'Current System Date/time'}
        }

        try {
            $Data|Export-Clixml -Path $DataLogFile -Encoding UTF8

            Write-Verbose ('Update-DataLog(): Succesfully exported {0} entries to DataLogFile {1}' -f $Data.Count, $DataLogFile)
        } catch {
            $PSCmdlet.ThrowTerminatingError((New-ErrorRecord -baseObject $_ `
                -exceptionMessage ('Error trying to write to DataLogFile "{0}" - 0x{1:X} - {2}' -f $DataLogFile, $_.Exception.HResult, $_.Exception.Message) `
                -errorId "Update-DataLog" -errorCategory "WriteError" -targetObject $DataLogFile))
        }
    } else {
        # -DataLog not specified, so we'll do nothing.
        Write-Verbose ('Update-DataLog(): -DataLog not specified, no action taken.')
    }
} # function Update-DataLog







function Update-StatusLog
{
    <#
    .SYNOPSIS
        Update the statuslog per specified parameters.
        
    .DESCRIPTION
        Update the statuslog per specified parameters.
        
        No update will happen unless parameters specify it.

        NOTE:
        This is an internal helper function. It should only be called from
        Invoke-Main

    .PARAMETER Prefix
        If specified, all logged lines will be prefixed with this value. The prefix
        is inserted between the log line and the timestamp - like this:

        <timestamp> <prefix> <logline>

    .PARAMETER NewData
        The data to add to the log. This must either be a string, or an array of
        strings.
                
    .PARAMETER PruneStatusLog
        If specified, the status log will be pruned according to -PruneStatusLogBefore.
        
        All entries dated earlier than the date specified in -PruneStatusLogBefore,
        will be removed from the log.

    .PARAMETER PruneStatusLogBefore
        Specifies the cutover date used for pruning the status log. See -PruneStatusLog
        for more information.
        
        If this parameter is not specified, the default is 365 days in the past.
            
    .PARAMETER StatusLogFile
        If specified, status will be logged in text form to this file.
        
        More or less data may be included, based on the other parameters specified.

        See -LogFullStatusReport and -LogStatusReportOnError

        Pruning options are available for this log, to prevent it growing uncontrollably

        NOTE: This is not the same as the -DataLogFile!

    .PARAMETER TimeStampFormat
        This is the DateTime format used by the logging functions. This must be a .NET
        supported TimeProvider format.
        
        IMPORTANT:
        If you change the format using -TimeStampFormat, and you are using any of the
        log pruning options, be aware that your entire log most likely will be pruned
        at first run, or the script may encounter an error.

        It is advisable to backup any logs in need of preservation first, and delete
        log files when changing this format!

    .OUTPUTS
        Success = nothing.
        Failure = Terminating Exception.

    .NOTES
        Author.: Kenneth Nielsen (sharzas @ GitHub.com)
        Version: 1.0

        NOTE:
        This is an internal helper function. It should only be called from
        Invoke-Main

    .LINK
        https://github.com/sharzas/Powershell-Get-StorCLIStatus
    #>

    [CmdletBinding()]

    Param (
        [Parameter()]
        [string]$Prefix = "",

        [Parameter()]
        [switch]$PruneStatusLog = $false,

        [Parameter()]
        [DateTime]$PruneStatusLogBefore = (Get-Date).AddDays(-365),

        [Parameter()]
        $StatusLogFile = $null,

        [Parameter()]
        [string]$TimeStampFormat = "dd-MM-yyyy HH:mm:ss",

        [Parameter()]
        $NewData
    )

    Write-Verbose ('Update-StatusLog(): Invoked.')

    $PSBoundParameters.Keys|ForEach-Object {Write-Verbose ('Update-StatusLog(): Parameter supplied to function: {0}' -f $_)}

    if ($null -ne $StatusLogFile) {
        # declare data storage array
        $Data = @()

        if ((Test-Path -Path $StatusLogFile -PathType Leaf)) {
            Write-Verbose ('Update-StatusLog(): StatusLogFile found - it will be updated: {0}' -f $StatusLogfile)

            if ($PruneStatusLog) {
                #
                # only load contents of file if Prune is specified - otherwise its a waste of time and resources!
                #
                try {
                    $Data = @(Get-Content $StatusLogFile)
        
                    Write-Verbose ('Update-StatusLog(): Succesfully loaded {0} lines from StatusLogFile {1}' -f $Data.Count, $StatusLogFile)
                } catch {
                    Write-Warning ('Update-StatusLog(): Failed to load existing StatusLogFile {0}' -f $StatusLogFile)
                    Write-Warning ('Update-StatusLog(): ')
                    Write-Warning ('Update-StatusLog(): Status will not be logged.')
                    Write-Warning ('Update-StatusLog(): ')

                    $PSCmdlet.ThrowTerminatingError((New-ErrorRecord -baseObject $_ `
                        -exceptionMessage ('Error trying to load StatusLogFile "{0}" - 0x{1:X} - {2}' -f $StatusLogFile, $_.Exception.HResult, $_.Exception.Message) `
                        -errorId "Update-StatusLog" -errorCategory "ReadError" -targetObject $StatusLogFile))
                }
            }
        } else {
            Write-Verbose ('Update-StatusLog(): StatusLogFile not found - new will be created: {0}' -f $StatusLogfile)
        }



        if ($PruneStatusLog) {
            # we should prune the statuslog, for entries older than the date specified in -PruneStatusLogBefore
            Write-Verbose ('Update-StatusLog(): Pruning StatusLog for entries dated earlier than {0}' -f $PruneStatusLogBefore)
    
            # Get current entry count.
            $Entries = $Data.Count
            
            # build RegExp pattern to use for splitting the text in the log file, so we can separate
            # the timestamp, in order to correctly prune the log.
            #$Pattern = "(^$($TimeStampFormat.ToLower().Replace("d","0").Replace("m","0").Replace("y","0").Replace("h","0").Replace("s","0").Replace("0","\d").Replace(".","\.").Replace("*","\*").Replace("+","\+").Replace('$','\$').Replace("[", "\[").Replace("]","\]").Replace("^","\^")))"
            $Pattern = "(^$((($TimeStampFormat -replace 'h|m|s|d|y','0') -replace '(\*|\+|\.|\[|\]|\^|\$|\\)','\$1') -replace '0','\d'))"
            
            # we need a variable of type DateTime to reference for the TryParse function.
            [DateTime]$DateRef = Get-Date

            # remove all lines with a timestamp older than the Prune date.
            $Data = @(($Data|Select-String $Pattern| `
                Where-Object {[DateTime]::TryParse($_.Matches[0].Groups[1].Value, [ref]$DateRef)}| `
                Where-Object {[DateTime]::Parse($_.Matches[0].Groups[1].Value) -gt $PruneStatusLogBefore} `
            )|Select-Object -ExpandProperty Line)  # important to grab the line property, or powershell will truncate lines!!!

            Write-Verbose ('Update-StatusLog(): Succesfully pruned {0} entries from StatusLogFile' -f ($Entries - $Data.Count))
        }


        if ($null -ne $NewData) {
            # New data to add to the log file is specified.
            Write-Verbose ('Update-StatusLog(): Adding new log data to status log.')

            # add everything to the current dataset, and timestamp it first.
            $NewData|ForEach-Object {
                $Data += ('{0} {1}{2}' -f (Get-Date -Format $TimeStampFormat), $Prefix, $_)
            }
        }


        try {
            if ($PruneStatusLog) {
                # Prune specified, so overwrite file with entire contents of existing file, except
                # the pruned log lines.
                $Data|Set-Content -Path $StatusLogFile -Encoding UTF8
            } else {
                # Prune wasn't specified, so just append the data or create new file.
                $Data|Add-Content -Path $StatusLogFile -Encoding UTF8
            }

            Write-Verbose ('Update-StatusLog(): Succesfully written {0} lines to StatusLogFile {1}' -f $Data.Count, $StatusLogFile)
        } catch {
            $PSCmdlet.ThrowTerminatingError((New-ErrorRecord -baseObject $_ `
                -exceptionMessage ('Error trying to write to StatusLogFile "{0}" - 0x{1:X} - {2}' -f $StatusLogFile, $_.Exception.HResult, $_.Exception.Message) `
                -errorId "Update-StatusLog" -errorCategory "WriteError" -targetObject $StatusLogFile))
        }
    } else {
        # -StatusLog not specified, so we'll do nothing.
        Write-Verbose ('Update-StatusLog(): -StatusLog not specified, no action taken.')
    }

} # function Update-StatusLog








if ($null -ne $StorCLIOutput -or $null -ne $Path) {
    # -StorCLIOutput was specified, so we can get to work

    $PSBoundParameters.Keys|ForEach-Object {Write-Verbose ('Parameter supplied to Script: {0} - Type = "{1}"' -f $_, $_.Gettype().Fullname)}

    try {
        Write-Verbose "Get-StorCLIStatus.ps1: Calling Invoke-Main..."

        Invoke-Main @PSBoundParameters

        Write-Verbose "Get-StorCLIStatus.ps1: Script finished without error"
    } catch {
        Write-Warning "Get-StorCLIStatus.ps1: Script finished with error!"

        $_|Resolve-Error|Out-Log -Prefix "[Get-StorCLIStatus.ps1] " -LogFile $StatusLogFile -Width 300
        $_|Resolve-Error|ForEach-Object {Write-Warning "Get-StorCLIStatus.ps1: $_"}

        # rethrow the statement terminating error, as a script terminating one.
        Throw $_
    }
} else {
    # -StorCLIOutput / -Path NOT specified, so we don't actually do anything, but functions may be 
    # loaded like you would an module.
    Write-Warning "-StorCLIOutput / -Path not specified. Nothing will happen."
    Write-Warning ""
    Write-Warning "You may dot source the functions in this script by running it without parameters. If that"
    Write-Warning "was what you intended, please remember to run the script like this:"
    Write-Warning ""
    Write-Warning ". .\Get-StorCLIStatus.ps1"
}