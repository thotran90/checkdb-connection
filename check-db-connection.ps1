# --------------------------------------------------------
# Author: Tho Tran
# Created Date: 29 Sep 2020
# Desc: Check sql connection and alert
# --------------------------------------------------------

# Send email alert via smtp
function Send-Email($instance, $isNetworkIssue){
    $Subject = "Unable to connect database instance {0}" -f $instance
    $Body = "<strong>Unable to connect database instance "+$instance+"</strong> </br>"

    If($isNetworkIssue -eq $true){
        $Body = $Body + "
        <strong>Issue:</strong>  Network related. Unable to open tcp connection."
    }Else{
        $Body = $Body + "
        <strong>Issue:</strong>  Database engine related. Please contact DBA."
    }

    # Email Sender
    $EmailFrom = "trandev90@gmail.com"
    # Email Receiver
    $EmailTo = "trandev90@gmail.com"
    $EmailPwd = "" 
    # Reference this link to get correct smtp server
    # https://support.microsoft.com/en-us/office/pop-and-imap-email-settings-for-outlook-8361e398-8af4-4e97-b147-6c6c4ac95353?ui=en-us&rs=en-us&ad=us
    $EmailSmtp = "smtp.gmail.com"
    $EmailSmtpPort = 465

    
    $SMTPClient = New-Object Net.Mail.SmtpClient($EmailSmtp, $EmailSmtpPort)   
    $SMTPClient.EnableSsl = $true    
    # Use Get-Credential if you don't want to use current email ( such as domain account )
    $SMTPClient.Credentials = New-Object System.Net.NetworkCredential($EmailFrom, $EmailPwd)    

    $EmailMessage = New-Object System.Net.Mail.MailMessage
    $EmailMessage.Subject = $Subject
    $EmailMessage.Body = $Body
    $EmailMessage.IsBodyHtml = $true
    $EmailMessage.Priority = [System.Net.Mail.MailPriority]::High # For me: Alert should be High priority
    $EmailMessage.From = $EmailFrom
    $EmailMessage.To.Add($EmailTo)

    Try{
        $SMTPClient.Send($EmailMessage)
    }
    Catch{
        Write-Host "Unable to send email"
        Write-Error $Error[0]
    }
}


# Test database instance connectivity
function Test-DBConnectivity($instance, $account, $pwd, $isWindowAuth){
    $connectionString
    If($isWindowAuth -eq $true){
        $connectionString = 'Data Source={0};Initial Catalog=master;Integrated Security=true' -f $instance, $account, $pwd
    }Else{
        $connectionString = 'Data Source={0};Initial Catalog=master;User Id = {1}; Password = {2}' -f $instance, $account, $pwd
    }
    
    $conn = New-Object -TypeName System.Data.SqlClient.SqlConnection -ArgumentList $connectionString;

    Try{
        $conn.Open()
        $conn.Close()
        $conn.Dispose()
        return 1
    }Catch{
        return 0
    }
}


# Main Job
function Main(){
    # List of database instance need to monitor. 
    # Should be stored in a separate database 
    $dtTable = @(
       [pscustomobject]@{[Address]="172.168.1.98";[Port]="9100";[Account]="";[Password]="";IsWindowAuthentication=$true}
       [pscustomobject]@{[Address]="172.168.1.198";[Port]="1433";[Account]="monitor";[Password]="123456";IsWindowAuthentication=$false} )
    $dtTable | ForEach-Object {
        # Perform test net connection
        $testNetConnection = Test-NetConnection -ComputerName $_.Address -Port $_.Port | Select-Object -Property TcpTestSucceeded
        $testNetConnectionResult = $testNetConnection.TcpTestSucceeded
        If($testNetConnectionResult -eq $true){
            # Perform test database engine
            # Should ensure that the sql account and password is correct
            $datasource = "{0},{1}" -f $_.Address, $_.Port
            $testResult = Test-DBConnectivity $_.datasource $_.Account $_.Password $_.IsWindowAuthentication
            If($testResult -eq 0){
                Send-Email $_.Address $false
            }
        }Else{
            Send-Email $_.Address $true
        }
    }   
}