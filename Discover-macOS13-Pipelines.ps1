<#
.SYNOPSIS
    Discovers all Azure DevOps pipelines using macOS-13 hosted agents before December 4, 2025 retirement.

.DESCRIPTION
    Scans all projects and pipelines in an Azure DevOps organization to identify:
    - YAML pipelines referencing macOS-13, macos-13, or vmImage variations
    - Classic pipelines using the macOS-13 agent pool
    - Outputs a report with pipeline names, paths, and remediation guidance

.PARAMETER Organization
    Your Azure DevOps organization name (e.g., "contoso" from dev.azure.com/contoso)

.PARAMETER PAT
    Personal Access Token with Read permissions on Code and Build

.EXAMPLE
    .\Discover-macOS13-Pipelines.ps1 -Organization "contoso" -PAT "your-pat-here"

.NOTES
    Author: Azure DevOps Migration Assessment
    Retirement Date: December 4, 2025
    Microsoft Docs: https://learn.microsoft.com/en-us/azure/devops/pipelines/agents/hosted
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$Organization,

    [Parameter(Mandatory = $true)]
    [string]$PAT
)

# Setup authentication
$base64Auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$PAT"))
$headers = @{
    Authorization = "Basic $base64Auth"
    "Content-Type" = "application/json"
}

$baseUrl = "https://dev.azure.com/$Organization"
$results = @()

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  macOS-13 Pipeline Discovery Tool" -ForegroundColor Cyan
Write-Host "  Retirement Date: December 4, 2025" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Cyan

# Get all projects
Write-Host "Fetching projects from $Organization..." -ForegroundColor Gray
try {
    $projectsResponse = Invoke-RestMethod -Uri "$baseUrl/_apis/projects?api-version=7.1" -Headers $headers -Method Get
    $projects = $projectsResponse.value
    Write-Host "Found $($projects.Count) projects`n" -ForegroundColor Green
}
catch {
    Write-Host "ERROR: Failed to fetch projects. Check your PAT permissions." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

foreach ($project in $projects) {
    $projectName = $project.name
    Write-Host "Scanning project: $projectName" -ForegroundColor White

    # Get all pipeline definitions
    try {
        $pipelinesUrl = "$baseUrl/$projectName/_apis/pipelines?api-version=7.1"
        $pipelinesResponse = Invoke-RestMethod -Uri $pipelinesUrl -Headers $headers -Method Get
        $pipelines = $pipelinesResponse.value
    }
    catch {
        Write-Host "  Could not fetch pipelines for $projectName" -ForegroundColor Yellow
        continue
    }

    foreach ($pipeline in $pipelines) {
        $pipelineName = $pipeline.name
        $pipelineId = $pipeline.id

        # Get pipeline YAML content if available
        try {
            # Try to get the YAML file path from pipeline configuration
            $pipelineDetailUrl = "$baseUrl/$projectName/_apis/pipelines/$pipelineId`?api-version=7.1"
            $pipelineDetail = Invoke-RestMethod -Uri $pipelineDetailUrl -Headers $headers -Method Get

            if ($pipelineDetail.configuration.type -eq "yaml") {
                $yamlPath = $pipelineDetail.configuration.path
                $repoId = $pipelineDetail.configuration.repository.id

                # Fetch the YAML file content
                $fileUrl = "$baseUrl/$projectName/_apis/git/repositories/$repoId/items?path=$yamlPath&api-version=7.1"
                $yamlContent = Invoke-RestMethod -Uri $fileUrl -Headers $headers -Method Get

                # Check for macOS-13 references
                $macOS13Patterns = @(
                    "vmImage:\s*['""]?macos-13['""]?"
                    "vmImage:\s*['""]?macOS-13['""]?"
                    "pool:\s*['""]?macos-13['""]?"
                    "macos-13"
                )

                $foundMatch = $false
                $matchedPattern = ""

                foreach ($pattern in $macOS13Patterns) {
                    if ($yamlContent -match $pattern) {
                        $foundMatch = $true
                        $matchedPattern = $Matches[0]
                        break
                    }
                }

                if ($foundMatch) {
                    Write-Host "  [FOUND] $pipelineName" -ForegroundColor Red
                    $results += [PSCustomObject]@{
                        Project      = $projectName
                        Pipeline     = $pipelineName
                        PipelineId   = $pipelineId
                        Type         = "YAML"
                        YamlPath     = $yamlPath
                        MatchFound   = $matchedPattern
                        WebUrl       = "$baseUrl/$projectName/_build?definitionId=$pipelineId"
                        Remediation  = "Update vmImage to 'macos-14' or 'macos-15'"
                    }
                }
            }
        }
        catch {
            # Pipeline might be classic or inaccessible
            continue
        }
    }

    # Also check classic build definitions
    try {
        $buildDefsUrl = "$baseUrl/$projectName/_apis/build/definitions?api-version=7.1"
        $buildDefsResponse = Invoke-RestMethod -Uri $buildDefsUrl -Headers $headers -Method Get
        
        foreach ($buildDef in $buildDefsResponse.value) {
            # Get full definition to check agent pool
            $fullDefUrl = "$baseUrl/$projectName/_apis/build/definitions/$($buildDef.id)?api-version=7.1"
            $fullDef = Invoke-RestMethod -Uri $fullDefUrl -Headers $headers -Method Get

            # Check if using Hosted macOS pool with macOS-13
            if ($fullDef.queue.pool.name -match "macOS-13|macos-13") {
                Write-Host "  [FOUND-CLASSIC] $($buildDef.name)" -ForegroundColor Red
                $results += [PSCustomObject]@{
                    Project      = $projectName
                    Pipeline     = $buildDef.name
                    PipelineId   = $buildDef.id
                    Type         = "Classic"
                    YamlPath     = "N/A - Classic Pipeline"
                    MatchFound   = $fullDef.queue.pool.name
                    WebUrl       = "$baseUrl/$projectName/_build?definitionId=$($buildDef.id)"
                    Remediation  = "Update agent pool to use macOS-14 or macOS-15 image"
                }
            }
        }
    }
    catch {
        continue
    }
}

# Output results
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  DISCOVERY RESULTS" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

if ($results.Count -eq 0) {
    Write-Host "No pipelines found using macOS-13. You are ready for the December 4 retirement." -ForegroundColor Green
}
else {
    Write-Host "Found $($results.Count) pipeline(s) requiring migration:`n" -ForegroundColor Yellow

    $results | Format-Table -Property Project, Pipeline, Type, MatchFound -AutoSize

    # Export to CSV
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $csvPath = ".\macOS13-Pipelines-$Organization-$timestamp.csv"
    $results | Export-Csv -Path $csvPath -NoTypeInformation
    Write-Host "`nResults exported to: $csvPath" -ForegroundColor Green

    # Summary by project
    Write-Host "`n--- Summary by Project ---" -ForegroundColor Cyan
    $results | Group-Object Project | ForEach-Object {
        Write-Host "$($_.Name): $($_.Count) pipeline(s)" -ForegroundColor White
    }
}

Write-Host "`n--- Recommended Actions ---" -ForegroundColor Yellow
Write-Host "1. Update vmImage from 'macos-13' to 'macos-14' or 'macos-15'" -ForegroundColor White
Write-Host "2. Verify Xcode version compatibility (macOS-15 requires Xcode 16.3+)" -ForegroundColor White
Write-Host "3. Test pipelines before December 4, 2025 deadline" -ForegroundColor White
Write-Host "4. Review: https://devblogs.microsoft.com/devops/upcoming-updates-for-azure-pipelines-agents-images/`n" -ForegroundColor Gray
