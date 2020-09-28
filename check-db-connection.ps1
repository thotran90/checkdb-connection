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
    }
}