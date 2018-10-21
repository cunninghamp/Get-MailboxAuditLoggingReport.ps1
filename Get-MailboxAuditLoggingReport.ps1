<#
.SYNOPSIS
Get-MailboxAuditLoggingReport.ps1 - Generate an Exchange Server mailbox audit logging report

.DESCRIPTION 
This PowerShell script will generate a report of the mailbox audit log entries
for a specified mailbox.

.OUTPUTS
Results are output to CSV/HTML, and also optionally to email.

.PARAMETER Mailbox
The mailbox that you want to query for mailbox audit log entries.

.PARAMETER Hours
How many hours in the past you want to query for. Default is 24 hours.

.PARAMETER SendEmail
Send the HTML report and CSV attachment via email.

.PARAMETER MailFrom
The "From" address for the report email.

.PARAMETER MailTo
The recipient of the report email.

.PARAMETER MailServer
The SMTP server to use to send the report email.

.EXAMPLE
.\Get-MailboxAuditLoggingReport.ps1 -Mailbox Payroll -Hours 48
Checks the Payroll mailbox for mailbox audit log entries from the last 48 hours.

.EXAMPLE
.\Get-MailboxAuditLoggingReport.ps1 -Mailbox Payroll -hours 48 -SendEmail -MailFrom exchange@exchangeserverpro.net -MailTo administrator@exchangeserverpro.net -MailServer smtp.exchangeserverpro.net
Checks the Payroll mailbox for mailbox audit log entries from the last 48 hours
and sends the report email with the CSV file attached.

.NOTES
Written by: Paul Cunningham

Find me on:

* My Blog:	https://paulcunningham.me
* Twitter:	https://twitter.com/paulcunningham
* LinkedIn:	https://au.linkedin.com/in/cunninghamp/
* Github:	https://github.com/cunninghamp
#>

#requires -version 2


[CmdletBinding()]
param (
	
	[Parameter( Mandatory=$false)]
	[string]$Mailbox,

	[Parameter( Mandatory=$false)]
	[switch]$SendEmail,

	[Parameter( Mandatory=$false)]
	[string]$MailFrom,

	[Parameter( Mandatory=$false)]
	[string]$MailTo,

	[Parameter( Mandatory=$false)]
	[string]$MailServer,

    [Parameter( Mandatory=$false)]
    [int]$Hours = 24

	)


#...................................
# Variables
#...................................

$now = Get-Date											#Used for timestamps
$date = $now.ToShortDateString()						#Short date format for email message subject

$report = @()
$reportemailsubject = "Mailbox Audit Logs for $mailbox in last $hours hours."

$myDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rawfile = "$myDir\AuditLogEntries.csv"
$htmlfile = "$myDir\AuditLogEntries.html"

#...................................
# Email Settings
#...................................

$smtpsettings = @{
	To =  $MailTo
	From = $MailFrom
    Subject = $reportemailsubject
	SmtpServer = $MailServer
	}

#...................................
# Script
#...................................

#Add Exchange 2010/2013 snapin if not already loaded in the PowerShell session
if (!(Get-PSSnapin | where {$_.Name -eq "Microsoft.Exchange.Management.PowerShell.E2010"}))
{
	try
	{
		Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010 -ErrorAction STOP
	}
	catch
	{
		#Snapin was not loaded
		Write-Warning $_.Exception.Message
		EXIT
	}
	. $env:ExchangeInstallPath\bin\RemoteExchange.ps1
	Connect-ExchangeServer -auto -AllowClobber
}


Write-Host "Searching $mailbox for last $hours hours."

$auditlogentries = @()

$identity = (Get-Mailbox $mailbox).Identity

$auditlogentries = Search-MailboxAuditLog -Identity $identity -LogonTypes Delegate -StartDate (Get-Date).AddHours(-$hours) -ShowDetails

if ($($auditlogentries.Count) -gt 0)
{
    Write-Host "Writing raw data to $rawfile"
    $auditlogentries | Export-CSV $rawfile -NoTypeInformation -Encoding UTF8

    foreach ($entry in $auditlogentries)
    {
        $reportObj = New-Object PSObject
        $reportObj | Add-Member NoteProperty -Name "Mailbox" -Value $entry.MailboxResolvedOwnerName
        $reportObj | Add-Member NoteProperty -Name "Mailbox UPN" -Value $entry.MailboxOwnerUPN
        $reportObj | Add-Member NoteProperty -Name "Timestamp" -Value $entry.LastAccessed
        $reportObj | Add-Member NoteProperty -Name "Accessed By" -Value $entry.LogonUserDisplayName
        $reportObj | Add-Member NoteProperty -Name "Operation" -Value $entry.Operation
        $reportObj | Add-Member NoteProperty -Name "Result" -Value $entry.OperationResult
        $reportObj | Add-Member NoteProperty -Name "Folder" -Value $entry.FolderPathName
        if ($entry.ItemSubject)
        {
            $reportObj | Add-Member NoteProperty -Name "Subject Lines" -Value $entry.ItemSubject
        }
        else
        {
            $reportObj | Add-Member NoteProperty -Name "Subject Lines" -Value $entry.SourceItemSubjectsList
        }

        $report += $reportObj
    }



    $htmlbody = $report | ConvertTo-Html -Fragment

	$htmlhead="<html>
				<style>
				BODY{font-family: Arial; font-size: 8pt;}
				H1{font-size: 22px; font-family: 'Segoe UI Light','Segoe UI','Lucida Grande',Verdana,Arial,Helvetica,sans-serif;}
				H2{font-size: 18px; font-family: 'Segoe UI Light','Segoe UI','Lucida Grande',Verdana,Arial,Helvetica,sans-serif;}
				H3{font-size: 16px; font-family: 'Segoe UI Light','Segoe UI','Lucida Grande',Verdana,Arial,Helvetica,sans-serif;}
				TABLE{border: 1px solid black; border-collapse: collapse; font-size: 8pt;}
				TH{border: 1px solid #969595; background: #dddddd; padding: 5px; color: #000000;}
				TD{border: 1px solid #969595; padding: 5px; }
				td.pass{background: #B7EB83;}
				td.warn{background: #FFF275;}
				td.fail{background: #FF2626; color: #ffffff;}
				td.info{background: #85D4FF;}
				</style>
				<body>
                <p>Report of mailbox audit log entries for $mailbox in the last $hours hours.</p>"
		
	$htmltail = "</body></html>"	

	$htmlreport = $htmlhead + $htmlbody + $htmltail

    Write-Host "Writing report data to $htmlfile"
    $htmlreport | Out-File $htmlfile -Encoding UTF8
    
    if ($SendEmail)
    {
        Write-Host "Sending email"
	    Send-MailMessage @smtpsettings -Body $htmlreport -BodyAsHtml -Encoding ([System.Text.Encoding]::UTF8) -Attachments $rawfile
    }
}
else
{
    Write-Host "No audit log entries found."
}


#...................................
# Finished
#...................................

Write-Host "Finished."
