<#
Script prepared for dot sourcing.
Import functions by calling . .\get-MUCSupersedence.ps1
#>


function Get-MUCSepersedence 
{
[CmdletBinding()]

    param (
            [parameter(mandatory=$true)]
            [ValidateScript({if ($_ -like "KB*"){$true}else{$false}})]
            [string]
            $KB,
            [string]$SearchString
            
            )

function CreateKBEntry ($Message, $KB, $name, $LastSupersedingKB, $FullSupersedingList, $url, $version, $FullKBList) {

        $properties = @{
        Message = $message
        SupersededKB = $KB
        Name = $name
        LastSupersedingKB = $LastSupersedingKB
        FullSupersedingList = $FullSupersedingList
        URL = if ($url -eq $null) {"N/A"} else {$url}
        Version = if ($version -eq $null) {"N/A"} else {$version}
        FullSupersedance = $FullKBList
        }
        $KBEntry = New-Object psobject -Property $properties;
        return $KBEntry
        }


Write-Verbose "Searching Microsoft Update Catalog for links related to $kb"
if ($SearchString -ne $null) {Write-Verbose "With search string $SearchString"}


$ErrorActionPreference = "silentlyContinue"

$MUC = "https://www.catalog.update.microsoft.com/"
$siteMUC = Invoke-WebRequest ("$MUC" + "Search.aspx?q=$KB")
$SelectKBLinks = $siteMUC.Links | Where {$_.InnerText -Like "*$SearchString*"}
$SelectKBLinks = $SelectKBLinks | Where {$_.Onclick -like "*gotodetails(*"}
Write-Verbose ($SelectKBLinks | Out-String)
if (($SelectKBLinks | Measure-Object).count -gt 0) {Write-Verbose "Supersedance links were found!"}
$Tab = @()


    foreach ($SelectKBLink in $SelectKBLinks) {

    $siteDetails = $null
    $id = $null
    
    $id = ($SelectKBLink.id).Replace("_link",'')
      $url = "$MUC" + "ScopedViewInline.aspx?updateid="
      $siteDetails = ((Invoke-WebRequest $url$id).Links) | where {$_.outerText -like ("*(kb*")}
      $FullKBs = $($t = @("$kb");$Sitedetails| Select outertext | foreach {$t+= $(($_.outertext).split('('))[1].split(")")[0]};$t )
      $LastSuperseded = $siteDetails | Select -Last 1

        if ($siteDetails -eq $null){
        $message = "NotSuperseded"
        $Name = $SelectKBLink.outerText
        $version = try {$Name.Split(' ')[(($Name.Split(' ')) | Select-String -Pattern "version" | select linenumber).linenumber] } catch {}
        $Tab += CreateKBEntry $message $KB $name "N/A" "N/A" "N/A" "$version" "N/A"
        } 
        else {
        $Message = "Superseded"
        $Name = $LastSuperseded.outerText
        $version = try {$Name.Split(' ')[(($Name.Split(' ')) | Select-String -Pattern "version" | select linenumber).linenumber] } catch {}
        $Tab += CreateKBEntry $message $KB $name $(((((($LastSuperseded.outerText).Split("("))[1]).split(" "))[0]).Replace(")","")) "$($($siteDetails | Select InnerText).innerText)" "$URL$($LastSuperseded.href)" "$(if ($version -eq $null) {"N/A"} else {$version})" $FullKBs
        }
    }
return ($Tab | select Message, Version, SupersededKB, LastSupersedingKB, URL, Name, FullSupersedance, FullSupersedingList )


<#
.SYNOPSIS

This function runs a check with Microsoft Update Catalog (https://www.catalog.update.microsoft.com) in order to track supersedence for provided KB.

.DESCRIPTION

It returns table of objects describing Supersedance (Name, number and URL to latest superseding update)
and provides full list of superseding updates in chronological order. 
Function accepts search string which allows for the results to be narrowed. 
Function also does not show which updates provided KB is replacing only which 
updates are replacing  provided value.


.PARAMETER KB
Specifies update number for search in MUC

.PARAMETER SearchString
Specifies the String value that can be used to narrow criteria.

.INPUTS

None. You cannot pipe objects to Get-MUCSupersedence.

.OUTPUTS

Table of custom psobject.

.EXAMPLE

PS>  Get-MUCSepersedence KB4586786 "Windows 10 * x64"

Message             : Superseded
Version             : 1909
SupersededKB        : KB4586786
LastSupersedingKB   : KB5003212
URL                 : https://www.catalog.update.microsoft.com/ScopedViewInline
                      .aspx?updateid=ScopedViewInline.aspx?updateid=e6c950a8-0d
                      7a-4892-bedd-33daa466516c
Name                : 2021-05 Cumulative Update Preview for Windows 10 Version 
                      1909 for x64-based Systems (KB5003212)
FullSupersedance    : {KB4586786, KB4594443, KB4586819, KB4592449...}
FullSupersedingList : 2020-11 Cumulative Update for Windows 10 Version 1909 
                      for x64-based Systems (KB4594443) 2020-11 Cumulative 
                      Update Preview for Windows 10 Version 1909 for x64-based 
                      Systems (KB4586819) 2020-12 Cumulative Update for 
                      Windows 10 Version 1909 for x64-based Systems 
                      (KB4592449) 2021-01 Cumulative Update for Windows 10 
                      Version 1909 for x64-based Systems (KB4598229) 2021-01 
                      Cumulative Update Preview for Windows 10 Version 1909 
                      for x64-based Systems (KB4598298) 2021-02 Cumulative 
                      Update for Windows 10 Version 1909 for x64-based Systems 
                      (KB4601315) 2021-02 Cumulative Update for Windows 10 
                      Version 1909 for x64-based Systems (KB5001028) 2021-02 
                      Cumulative Update Preview for Windows 10 Version 1909 
                      for x64-based Systems (KB4601380) 2021-03 Cumulative 
                      Update for Windows 10 Version 1909 for x64-based Systems 
                      (KB5000808) 2021-03 Cumulative Update for Windows 10 
                      Version 1909 for x64-based Systems (KB5001566) 2021-03 
                      Cumulative Update for Windows 10 Version 1909 for 
                      x64-based Systems (KB5001648) 2021-03 Cumulative Update 
                      Preview for Windows 10 Version 1909 for x64-based 
                      Systems (KB5000850) 2021-04 Cumulative Update for 
                      Windows 10 Version 1909 for x64-based Systems 
                      (KB5001337) 2021-04 Cumulative Update Preview for 
                      Windows 10 Version 1909 for x64-based Systems 
                      (KB5001396) 2021-05 Cumulative Update for Windows 10 
                      Version 1909 for x64-based Systems (KB5003169) 2021-05 
                      Cumulative Update Preview for Windows 10 Version 1909 
                      for x64-based Systems (KB5003212)

Message             : Superseded
Version             : 1903
SupersededKB        : KB4586786
LastSupersedingKB   : KB4592449
URL                 : https://www.catalog.update.microsoft.com/ScopedViewInline
                      .aspx?updateid=ScopedViewInline.aspx?updateid=639cae64-91
                      b2-444e-9810-50ef1637c7e2
Name                : 2020-12 Cumulative Update for Windows 10 Version 1903 
                      for x64-based Systems (KB4592449)
FullSupersedance    : {KB4586786, KB4594443, KB4586819, KB4592449}
FullSupersedingList : 2020-11 Cumulative Update for Windows 10 Version 1903 
                      for x64-based Systems (KB4594443) 2020-11 Cumulative 
                      Update Preview for Windows 10 Version 1903 for x64-based 
                      Systems (KB4586819) 2020-12 Cumulative Update for 
                      Windows 10 Version 1903 for x64-based Systems (KB4592449)


.EXAMPLE

PS>  Get-MUCSepersedence KB4586786 "Cumulative Update for Windows 10 Version 1903 for x64-based"

Message             : Superseded
Version             : 1903
SupersededKB        : KB4586786
LastSupersedingKB   : KB4592449
URL                 : https://www.catalog.update.microsoft.com/ScopedViewInline.aspx?updateid=ScopedViewInl
                      ine.aspx?updateid=639cae64-91b2-444e-9810-50ef1637c7e2
Name                : 2020-12 Cumulative Update for Windows 10 Version 1903 for x64-based Systems 
                      (KB4592449)
FullSupersedance    : {KB4586786, KB4594443, KB4586819, KB4592449}
FullSupersedingList : 2020-11 Cumulative Update for Windows 10 Version 1903 for x64-based Systems 
                      (KB4594443) 2020-11 Cumulative Update Preview for Windows 10 Version 1903 for 
                      x64-based Systems (KB4586819) 2020-12 Cumulative Update for Windows 10 Version 1903 
                      for x64-based Systems (KB4592449)

.EXAMPLE

PS>  Get-MUCSepersedence KB5001918

Message             : NotSuperseded
Version             : 
SupersededKB        : KB5001918
LastSupersedingKB   : N/A
URL                 : N/A
Name                : Security Update for Microsoft Excel 2016 (KB5001918) 32-Bit Edition 
FullSupersedance    : N/A
FullSupersedingList : N/A

Message             : NotSuperseded
Version             : 
SupersededKB        : KB5001918
LastSupersedingKB   : N/A
URL                 : N/A
Name                : Security Update for Microsoft Excel 2016 (KB5001918) 64-Bit Edition 
FullSupersedance    : N/A
FullSupersedingList : N/A


.LINK

https://github.com/BlackwolfComputing/Get-MUC-Supersedence

#>
}
