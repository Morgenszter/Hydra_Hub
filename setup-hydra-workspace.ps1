[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$RootPath = (Get-Location).Path,

    [Parameter(Mandatory = $false)]
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Utf8NoBomFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Content,

        [Parameter(Mandatory = $false)]
        [switch]$Overwrite
    )

    $parentDirectory = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $parentDirectory -PathType Container)) {
        New-Item -ItemType Directory -Path $parentDirectory -Force | Out-Null
    }

    if ((Test-Path -LiteralPath $Path -PathType Leaf) -and -not $Overwrite) {
        Write-Host ("SKIP  {0}" -f $Path)
        return
    }

    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Content, $encoding)
    Write-Host ("WRITE {0}" -f $Path)
}

try {
    $resolvedRoot = [System.IO.Path]::GetFullPath($RootPath)

    if (-not (Test-Path -LiteralPath $resolvedRoot)) {
        New-Item -ItemType Directory -Path $resolvedRoot -Force | Out-Null
    }

    if (-not (Test-Path -LiteralPath $resolvedRoot -PathType Container)) {
        throw "RootPath does not point to a directory: $resolvedRoot"
    }

    $workspaceRoot = Join-Path $resolvedRoot "HYDRA"

    $directories = @(
        $workspaceRoot
        (Join-Path $workspaceRoot "backlog")
        (Join-Path $workspaceRoot "reports")
        (Join-Path $workspaceRoot "reviews")
        (Join-Path $workspaceRoot "tasks")
        (Join-Path $workspaceRoot "prompts")
        (Join-Path $workspaceRoot "scripts")
    )

    foreach ($directory in $directories) {
        if (-not (Test-Path -LiteralPath $directory -PathType Container)) {
            New-Item -ItemType Directory -Path $directory -Force | Out-Null
            Write-Host ("CREATE {0}" -f $directory)
        }
        else {
            Write-Host ("EXISTS {0}" -f $directory)
        }
    }

    $files = [ordered]@{
        (Join-Path $workspaceRoot "README.md") = @'
# HYDRA Workspace

This workspace contains stabilization planning, reports, reviews, tasks, prompts, and helper scripts for HYDRA AI HOME OS.

## Directories

- backlog — prioritized stabilization backlog
- reports — agent execution reports
- reviews — architecture and implementation reviews
- tasks — actionable work items
- prompts — reusable agent prompts
- scripts — workspace automation scripts
'@
        (Join-Path $workspaceRoot "backlog\STABILIZATION_BACKLOG.md") = @'
# Stabilization Backlog

## Priority Order

1. Parser and class errors
2. Missing resources and scene paths
3. Autoload configuration
4. Runtime composition
5. Final HUD integration
6. Smoke tests
7. Packaging and release

## Backlog Items

| ID | Priority | Area | Description | Owner | Status | Evidence |
|---|---|---|---|---|---|---|
| STAB-001 | Critical | Parser | Record the first root parser error | Unassigned | Open | |
'@
        (Join-Path $workspaceRoot "reports\AGENT_REPORT_TEMPLATE.md") = @'
# Agent Report

## Metadata

- Agent:
- Date:
- Task ID:
- Repository revision:

## Work Completed

Describe the completed work and affected paths.

## Validation

List the commands executed and their actual results.

## Findings

Record errors, risks, blockers, and follow-up items.

## Files Changed

List every created, modified, or deleted file.

## Recommended Commit Message

type(scope): summary
'@
        (Join-Path $workspaceRoot "reviews\ARCHITECT_REVIEW_TEMPLATE.md") = @'
# Architect Review

## Metadata

- Reviewer:
- Date:
- Task ID:
- Revision:

## Scope

Describe the reviewed change and package boundaries.

## Findings

| Severity | Path | Finding | Required Action |
|---|---|---|---|
| | | | |

## Architecture Compliance

- Clean Architecture:
- DDD:
- SOLID:
- EventBus:
- Composition Root:
- Package boundaries:

## Decision

- Status: Pending
- Conditions:
'@
        (Join-Path $workspaceRoot "tasks\TASK_TEMPLATE.md") = @'
# Task

## Metadata

- Task ID:
- Priority:
- Owner:
- Package:
- Status:

## Objective

Describe the single measurable outcome.

## Inputs

List required files, evidence, and dependencies.

## Constraints

List technical and architectural constraints.

## Acceptance Criteria

- [ ] Implementation is complete.
- [ ] Validation commands pass.
- [ ] No unrelated files are changed.
- [ ] A commit message is provided.

## Validation Commands

Document exact commands before execution.

## Deliverables

List expected files and reports.
'@
        (Join-Path $workspaceRoot "prompts\AGENT_PROMPTS.md") = @'
# HYDRA Agent Prompts

## Stabilization Agent

Analyze the assigned issue, identify the first root error, apply the smallest complete fix, and report every changed path. Do not redesign working modules. Validate the result with exact commands and provide a recommended commit message.

## Build Agent

Use existing installers when present. Validate PowerShell syntax, generated paths, manifests, archive contents, checksums, and installation order. Do not claim success without executed validation.

## Review Agent

Review only the supplied change set. Check package boundaries, runtime dependencies, parser safety, resource paths, autoload usage, and reproducibility. Report findings by severity with exact file paths.
'@
        (Join-Path $workspaceRoot "scripts\README.md") = @'
# Scripts

Store deterministic, non-interactive workspace automation scripts in this directory.

## Requirements

- PowerShell 5.1 or later
- Strict mode enabled
- Stop on errors
- UTF-8 without BOM
- No interactive prompts
- No user-specific absolute paths
- Validate every generated file
'@
    }

    foreach ($entry in $files.GetEnumerator()) {
        Write-Utf8NoBomFile -Path $entry.Key -Content $entry.Value -Overwrite:$Force
    }

    foreach ($directory in $directories) {
        if (-not (Test-Path -LiteralPath $directory -PathType Container)) {
            throw "Directory validation failed: $directory"
        }
    }

    foreach ($filePath in $files.Keys) {
        if (-not (Test-Path -LiteralPath $filePath -PathType Leaf)) {
            throw "File validation failed: $filePath"
        }

        $fileInfo = Get-Item -LiteralPath $filePath
        if ($fileInfo.Length -le 0) {
            throw "File is empty: $filePath"
        }

        $bytes = [System.IO.File]::ReadAllBytes($filePath)
        if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
            throw "UTF-8 BOM detected: $filePath"
        }
    }

    Write-Host ("SUCCESS: HYDRA workspace created and validated at {0}" -f $workspaceRoot)
    exit 0
}
catch {
    Write-Error ("ERROR: {0}" -f $_.Exception.Message)
    exit 1
}
