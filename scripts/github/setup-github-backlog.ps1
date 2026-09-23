param([switch]$Apply)

$ErrorActionPreference = "Stop"
$Owner = "karolldahian"
$Repo = "ikd-powerinsight"
$RepoFull = "$Owner/$Repo"
$ProjectNumber = 3
$ProjectId = "PVT_kwHOD4BgZc4BkYXE"
$BacklogPath = Join-Path $PSScriptRoot "ikd-powerinsight-backlog.json"

$Field = @{
 Status="PVTSSF_lAHOD4BgZc4BkYXEzhjJIaw"; Priority="PVTSSF_lAHOD4BgZc4BkYXEzhjJLDU";
 Effort="PVTF_lAHOD4BgZc4BkYXEzhjJLQ8"; Phase="PVTSSF_lAHOD4BgZc4BkYXEzhjJLqo";
 WorkType="PVTSSF_lAHOD4BgZc4BkYXEzhjJMPY"
}
$Opt = @{
 Status=@{Backlog="1cda6717";Ready="76e1aa7d";"In Progress"="47fc9ee4";"In Review"="bc19d27d";Done="98236657"};
 Priority=@{Critical="afb43f48";High="6752f097";Medium="b6f06656";Low="de7fa486"};
 Phase=@{P0="b05e249b";P1="f884b54d";P2="557b2faf";P3="1a4b6f6b";P4="fe08c22a";P5="ea6f00d7";P6="fa1c3061";P7="a6f2986e";P8="03d72de3";P9="55fe9c17";P10="bb527b2a";P11="df106ff7";P12="817b16b8";P13="a4691feb";P14="ca8b4561";P15="325c5541";P16="c5a3ebdb"};
 WorkType=@{Feature="ebe5f01f";Bug="1a6b4e8c";Test="fd1ac12b";Docs="47de19ee";Chore="5022f56e";Research="c59a5902"}
}

if (!(Test-Path $BacklogPath)) { throw "Falta $BacklogPath" }
$Backlog = Get-Content $BacklogPath -Raw -Encoding UTF8 | ConvertFrom-Json
$Existing = gh issue list --repo $RepoFull --state all --limit 500 --json number,title,state,url | ConvertFrom-Json

Write-Host "IKD PowerInsight: $($Backlog.Count) tareas"
if (!$Apply) { Write-Host "DRY RUN: GitHub NO será modificado." }

foreach($Task in $Backlog){
 $Issue=$null
 if($Task.existingIssue){$Issue=$Existing|Where-Object number -eq ([int]$Task.existingIssue)|Select-Object -First 1}
 if(!$Issue){$Issue=$Existing|Where-Object title -eq $Task.title|Select-Object -First 1}
 Write-Host "[$($Task.wbs)] $($Task.title)"
 if(!$Apply){if($Issue){Write-Host "  REUSE #$($Issue.number)"}else{Write-Host "  CREATE"};continue}

 $tmp=[IO.Path]::GetTempFileName()
 try{
   Set-Content $tmp $Task.body -Encoding UTF8
   if($Issue){
     gh issue edit $Issue.number --repo $RepoFull --title $Task.title --body-file $tmp --milestone $Task.milestone | Out-Null
     $url=$Issue.url;$num=$Issue.number
   }else{
     $url=(gh issue create --repo $RepoFull --title $Task.title --body-file $tmp --milestone $Task.milestone --assignee "@me").Trim()
     $num=[int](($url-split "/")[-1])
   }
 }finally{Remove-Item $tmp -Force -ErrorAction SilentlyContinue}

 $pi=gh project item-add $ProjectNumber --owner $Owner --url $url --format json|ConvertFrom-Json
 $id=$pi.id
 gh project item-edit --id $id --project-id $ProjectId --field-id $Field.Status --single-select-option-id $Opt.Status[$Task.status]|Out-Null
 gh project item-edit --id $id --project-id $ProjectId --field-id $Field.Priority --single-select-option-id $Opt.Priority[$Task.priority]|Out-Null
 gh project item-edit --id $id --project-id $ProjectId --field-id $Field.Effort --number $Task.effort|Out-Null
 gh project item-edit --id $id --project-id $ProjectId --field-id $Field.Phase --single-select-option-id $Opt.Phase[$Task.phase]|Out-Null
 gh project item-edit --id $id --project-id $ProjectId --field-id $Field.WorkType --single-select-option-id $Opt.WorkType[$Task.workType]|Out-Null
 if($Task.state -eq "CLOSED"){gh issue close $num --repo $RepoFull|Out-Null}
}
if($Apply){Write-Host "Carga terminada."}else{Write-Host "Dry Run terminado. Para aplicar: .\setup-github-backlog.ps1 -Apply"}
