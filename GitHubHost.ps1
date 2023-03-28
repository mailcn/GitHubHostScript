# 声明全局变量
# 定义方法开始时输出的前景色
$LogForegroundColorStart = "Green"
# 定义方法结束时输出的前景色
$LogForegroundColorEnd = "Cyan"
# 定义方法输出警告时的前景色
$LogForegroundColorWarning = "Yellow"


$StartFlag = "# Generated by Powershell Start"
$EndFlag = "# Generated by Powershell End"


$HostUrls01 = "https://gitee.com/fliu2476/github-hosts/raw/main/hosts"
$HostUrls02 = "https://raw.hellogithub.com/hosts"


$HostFilePath = "$env:windir\system32\drivers\etc\hosts"

Write-Host "Let's Start!" -Foreground $LogForegroundColorStart

# Requires -RunAsAdministrator
function Test-Admin
{
    $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

if((Test-Admin) -eq $false) 
{
    #提升权限
    Start-Process powershell.exe -Verb RunAs -ArgumentList ('-noprofile -noexit -ExecutionPolicy Bypass -file "{0}"' -f $PSCommandPath)

    Exit
}

Function Edit-Hosts
{
    try
    {
        $urls01 = Invoke-WebRequest $HostUrls01 | Select-Object -Expand Content 
        $urls02 = Invoke-RestMethod  $HostUrls02  
        
        $urls = $StartFlag + $([Environment]::NewLine) + $urls01 + $([Environment]::NewLine)  + $urls02  + $EndFlag

        [System.Collections.ArrayList]$hostFile = Get-Content $HostFilePath 
        $startlineNum= ($hostFile | Select-String $StartFlag).LineNumber 
        $endlineNum= ($hostFile | Select-String $EndFlag).LineNumber 

        #打印对象
        #Write-Host ($hostFile | Format-Table | Out-String) 
        #Write-Host ($urls01 | Format-Table | Out-String) 
        #Write-Host ($urls02 | Format-List | Out-String) 
        Write-Host ($urls | Format-List | Out-String) 

        #Write-Host "hostFile Count:" $hostFile.Count -Foreground $LogForegroundColorWarning
        #Write-Host "startlineNum:" $startlineNum -Foreground $LogForegroundColorWarning
        #Write-Host "endlineNum:" $endlineNum -Foreground $LogForegroundColorWarning

        if ( $startlineNum -GT 0) 
        {
            $hostFile.RemoveRange($startlineNum - 1, $endlineNum - $startlineNum + 1)
        }
     
        #may File Dead Lock
        #$([Environment]::NewLine) + $urls  | Add-Content  $HostFilePath   -Force 

        foreach ($url in $urls)  { $hostFile += $url }

        $hostFile > $HostFilePath
    }
    catch  
    {
        Write-Host "`Edit-Hosts Failed, Exception:" $Error[0] -Foreground $LogForegroundColorWarning
         
		Return $false
    }
    
    Return $true
}

if ((Edit-Hosts) -eq $false)
{
    Write-Host "`nEdit-Hosts Failed" -Foreground $LogForegroundColorWarning
    #Write-Host "`n请联系作者" -Foreground $LogForegroundColorWarning

    "`nAny key to exit." 
    [Console]::Readkey() | Out-Null 
    Exit
}
else
{
    Clear-DnsClientCache

    Start-Process   https://github.com/ping11700/GitHubHostScript
    #Start-Process  https://github.com/ping11700/LOLKit
   
    Write-Host "`nDone." -Foreground $LogForegroundColorEnd

    Exit
}


