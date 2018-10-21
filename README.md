# Get-MailboxAuditLoggingReport.ps1

This PowerShell script will generate a report of the mailbox audit log entries
for a specified mailbox.

Results are output to CSV/HTML, and also optionally to email.

## Usage

- **-Mailbox**, The mailbox that you want to query for mailbox audit log entries.
- **-Hours**, How many hours in the past you want to query for. Default is 24 hours.
- **-SendEmail**, Send the HTML report and CSV attachment via email.
- **-MailFrom**, The "From" address for the report email.
- **-MailTo**, The recipient of the report email.
- **-MailServer**, The SMTP server to use to send the report email.

## Examples
```
.\Get-MailboxAuditLoggingReport.ps1 -Mailbox Payroll -Hours 48
```

Checks the Payroll mailbox for mailbox audit log entries from the last 48 hours.

```
.\Get-MailboxAuditLoggingReport.ps1 -Mailbox Payroll -hours 48 -SendEmail -MailFrom exchange@exchangeserverpro.net -MailTo administrator@exchangeserverpro.net -MailServer smtp.exchangeserverpro.net
```

Checks the Payroll mailbox for mailbox audit log entries from the last 48 hours and sends the report email with the CSV file attached.

## Credits
Written by: Paul Cunningham

Find me on:

* My Blog:	http://paulcunningham.me
* Twitter:	https://twitter.com/paulcunningham
* LinkedIn:	http://au.linkedin.com/in/cunninghamp/
* Github:	https://github.com/cunninghamp

Check out my [books](https://paulcunningham.me/books/) and [courses](https://paulcunningham.me/training/) to learn more about Office 365 and Exchange Server.
