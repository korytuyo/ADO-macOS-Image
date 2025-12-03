# Azure DevOps macOS-13 Discovery Toolkit

This repo helps Azure DevOps admins find pipelines still pinned to the retiring `macos-13` hosted agent (sunsetting **December 4, 2025**) and guide owners through migration to `macos-14`/`macos-15` images.

## Repository Structure
- `Discover-macOS13-Pipelines.ps1` – PowerShell 5.1+ script that queries Azure DevOps REST APIs (`api-version=7.1`) to enumerate projects, YAML pipelines, and classic definitions, then flags any macOS-13 usage.
- `macOS13-Migration-Checklist.md` – Operational playbook with dependency validation tables (Xcode, SDKs, toolchains) and step-by-step remediation tasks referenced by the discovery output.
- `.github/copilot-instructions.md` – Guidance for AI assistants working in this repo (handy reference for humans too).

## Requirements
- PowerShell 5.1+ (works on Windows PowerShell and Pwsh Core).
- Azure DevOps Personal Access Token with **Build (Read)** and **Code (Read)** scopes.
- Organization slug (e.g., `contoso` from `https://dev.azure.com/contoso`).

## Quick Start
```powershell
# From repo root
.\Discover-macOS13-Pipelines.ps1 -Organization "contoso" -PAT "<your-PAT>"
```

1. Script authenticates via Basic auth header (`:$PAT`).
2. Projects → pipelines → YAML content pulled via `_apis/git/repositories/{id}/items`.
3. Regex list (`$macOS13Patterns`) short-circuits on the first macOS-13 match.
4. Classic definitions are inspected by fetching queues and pool names.

> Tip: When testing changes, scope processing by piping `$projects | Select-Object -First 3` before the main loop and remove the helper before committing.

## Output & Reporting
- Console shows progress plus red `[FOUND]` / `[FOUND-CLASSIC]` rows for quick triage.
- Findings stored as `[PSCustomObject]` entries with `Project`, `Pipeline`, `Type`, `YamlPath`, `MatchFound`, and remediation text.
- Results export to `macOS13-Pipelines-<Org>-<yyyyMMdd-HHmmss>.csv` in repo root and include a per-project summary table.
- Recommended actions (vmImage swap, Xcode validation, testing deadline) print at the end; reuse that format when extending guidance.

## Using the Migration Checklist
1. Open `macOS13-Migration-Checklist.md` and drop in the CSV lines you own.
2. Validate Xcode/SDK/toolchain compatibility with the tables under **Dependency Validation**.
3. Update pipeline YAML per the **Migration Steps** section (vmImage swap, optional `UseXcode@6`, Homebrew path fixes).
4. Track progress via the checkbox sections (Build/Test/Artifact/Deployment verification) and notify stakeholders when complete.

## Customizing Detection
- Extend `$macOS13Patterns` when Microsoft introduces new labels (keep regex syntax so `-match` works).
- Add columns to `$results` only if you also update the checklist so remediation guidance stays in sync.
- Stick with API version `7.1` throughout; mixing versions has caused schema diffs for pipeline metadata.

## Troubleshooting
- **Authentication failures:** confirm PAT scopes and that the org slug is correct.
- **404 on YAML fetch:** pipeline may live in a different repo; ensure the service connection grants Build Read.
- **Classic pipelines missing:** verify the account still uses Classic builds; some orgs disable those endpoints.
- **Xcode mismatch post-migration:** follow the checklist’s `UseXcode@6` or `xcode-select` examples to pin versions.

## Contributing
- Use feature branches; validate the script against a small project set before PRs.
- Keep console messaging consistent (colorized `Write-Host`).
- Update both the script and checklist whenever you change output schema or remediation wording.

## References
- [Azure Pipelines Hosted Agents](https://learn.microsoft.com/azure/devops/pipelines/agents/hosted)
- [Deprecation Announcement](https://devblogs.microsoft.com/devops/upcoming-updates-for-azure-pipelines-agents-images/)
- [Xcode Release Matrix](https://xcodereleases.com/)
