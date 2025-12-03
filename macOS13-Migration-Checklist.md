# macOS-13 to macOS-14/15 Migration Checklist

**Retirement Date:** December 4, 2025  
**Applies To:** Azure DevOps Services - Microsoft-hosted agents only  
**Reference:** [Azure Pipelines Agent Images](https://learn.microsoft.com/en-us/azure/devops/pipelines/agents/hosted)

---

## Pre-Migration Discovery

### Identify Affected Pipelines
- [ ] Run discovery script across all projects
- [ ] Export list of affected pipelines to CSV
- [ ] Identify pipeline owners and notify stakeholders
- [ ] Prioritize pipelines by business criticality

### Document Current State
- [ ] Record current Xcode version requirements per pipeline
- [ ] List all iOS/watchOS/tvOS/visionOS SDK dependencies
- [ ] Document any custom tool installations in pipeline
- [ ] Note any hardcoded paths referencing macOS-13 specifics

---

## Dependency Validation

### Xcode Version Compatibility

| Target Image | Default Xcode | Minimum Supported |
|--------------|---------------|-------------------|
| macOS-14     | Xcode 15.4    | Xcode 14.3        |
| macOS-15     | Xcode 16.0    | Xcode 16.0        |

**Critical Check:** If your pipeline targets iOS/watchOS/tvOS/visionOS versions below Xcode 16.3 compatibility, macOS-15 will break your builds.

- [ ] Review Xcode version in pipeline YAML
- [ ] Verify target iOS SDK version requirements
- [ ] Check if using XcodeSelect task to switch versions
- [ ] Confirm Xcode version exists on target image

### SDK and Framework Dependencies
- [ ] Swift version compatibility verified
- [ ] CocoaPods version compatibility checked
- [ ] Carthage dependencies tested (if applicable)
- [ ] Swift Package Manager resolution tested
- [ ] Fastlane version compatibility confirmed

### Tool Chain Verification
- [ ] Node.js version available on target image
- [ ] Python version compatibility checked
- [ ] Ruby version for CocoaPods/Fastlane confirmed
- [ ] Java/JDK version if Android builds included
- [ ] .NET SDK version for MAUI projects verified

---

## Migration Steps

### Step 1: Update Pipeline YAML

**Before:**
```yaml
pool:
  vmImage: 'macos-13'
```

**After (Option A - Specific Version):**
```yaml
pool:
  vmImage: 'macos-14'
```

**After (Option B - Latest):**
```yaml
pool:
  vmImage: 'macos-latest'
```

> Note: macos-latest currently points to macOS-14

- [ ] Update vmImage reference in pipeline YAML
- [ ] Commit changes to feature branch
- [ ] Create pull request for review

### Step 2: Xcode Version Selection (If Required)

If your pipeline requires a specific Xcode version, add this before build tasks:

```yaml
- task: UseXcode@6
  inputs:
    xcodeVersion: '15.4'
```

Or using bash:

```yaml
- bash: |
    sudo xcode-select -s /Applications/Xcode_15.4.app/Contents/Developer
  displayName: 'Select Xcode 15.4'
```

- [ ] Add Xcode selection task if needed
- [ ] Verify Xcode version exists on target image
- [ ] Test Xcode selection in pipeline run

### Step 3: Path and Environment Updates

Common path changes between macOS versions:

| Component | macOS-13 Path | macOS-14/15 Path |
|-----------|---------------|------------------|
| Homebrew  | /usr/local    | /opt/homebrew (ARM) |
| Python    | /usr/local/bin/python3 | /opt/homebrew/bin/python3 |

- [ ] Review hardcoded paths in scripts
- [ ] Update Homebrew references if using ARM
- [ ] Verify environment variables still resolve

### Step 4: Test Pipeline

- [ ] Run pipeline on feature branch
- [ ] Verify all build steps complete
- [ ] Check test execution passes
- [ ] Validate artifact generation
- [ ] Confirm code signing works (if applicable)

---

## Validation Checklist

### Build Verification
- [ ] Solution/project compiles without errors
- [ ] All targets build successfully
- [ ] No new warnings introduced
- [ ] Build time within acceptable range

### Test Verification
- [ ] Unit tests pass
- [ ] UI tests execute (if applicable)
- [ ] Test results match previous baseline
- [ ] Code coverage reports generate

### Artifact Verification
- [ ] IPA/APP files generated correctly
- [ ] Package signing successful
- [ ] Artifacts upload to expected location
- [ ] Archive size within expected range

### Deployment Verification
- [ ] App Store Connect upload works (if applicable)
- [ ] TestFlight distribution successful
- [ ] Enterprise distribution signing valid

---

## Rollback Plan

If migration fails, revert to macOS-13 temporarily while troubleshooting:

1. Revert pipeline YAML changes
2. Document specific failure points
3. Research compatibility issues
4. Plan remediation before December 4

**Important:** macOS-13 will be unavailable after December 4, 2025. No rollback possible after this date.

---

## Post-Migration

- [ ] Update documentation with new image version
- [ ] Communicate completion to stakeholders
- [ ] Archive discovery report
- [ ] Schedule review for future deprecations
- [ ] Consider macOS-latest for automatic updates

---

## Troubleshooting Common Issues

### Issue: Xcode version not found
**Solution:** Check available Xcode versions on the image. Use XcodeSelect task with a supported version.

### Issue: CocoaPods install fails
**Solution:** Update CocoaPods to latest version or pin to compatible version in Gemfile.

### Issue: Signing certificate not found
**Solution:** Re-import certificates using InstallAppleCertificate task. Keychain paths may differ.

### Issue: Homebrew packages missing
**Solution:** Add explicit brew install steps. Do not rely on pre-installed packages.

### Issue: Swift version mismatch
**Solution:** Verify Swift version bundled with selected Xcode version. Update project settings if needed.

---

## References

- [Microsoft Hosted Agent Software](https://github.com/actions/runner-images/blob/main/images/macos/macos-14-Readme.md)
- [Xcode Version Matrix](https://xcodereleases.com)
- [Azure Pipelines Deprecation Announcement](https://devblogs.microsoft.com/devops/upcoming-updates-for-azure-pipelines-agents-images/)
