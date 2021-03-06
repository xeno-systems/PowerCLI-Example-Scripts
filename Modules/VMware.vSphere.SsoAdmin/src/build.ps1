# **************************************************************************
#  Copyright 2020 VMware, Inc.
# **************************************************************************

param(
   [ValidateSet("Debug", "Release")]
   [string]
   $Configuration = "Release",

   [string]
   $TestVc,

   [string]
   $TestVcUser,

   [string]
   $TestVcPassword
)

function Test-BuildToolsAreAvailable {
   $dotnetSdk = Get-Command 'dotnet'
   if (-not $dotnetSdk) {
     throw "'dotnet' sdk is not available"
   }
}

function LogInfo($message) {
   $dt = (Get-Date).ToLongTimeString()
   Write-Host "[$dt] INFO: $message" -ForegroundColor Green
}

function Build {
   $srcRoot = Join-Path $PSScriptRoot "VMware.vSphere.SsoAdmin.Client"

   Push-Location $srcRoot

   dotnet build -c $Configuration

   Pop-Location
}

function Publish {
param($OutputFolder)

   if (Test-Path $OutputFolder) {
      $netcoreLsSource = [IO.Path]::Combine(
         $PSScriptRoot,
         "VMware.vSphere.SsoAdmin.Client",
         "VMware.vSphere.LsClient",
         "bin",
         $Configuration,
         "netcoreapp2.0",
         "VMware.vSphere.LsClient.dll")

      $net45LsSource = [IO.Path]::Combine(
         $PSScriptRoot,
         "VMware.vSphere.SsoAdmin.Client",
         "VMware.vSphere.LsClient",
         "bin",
         $Configuration,
         "net45",
         "VMware.vSphere.LsClient.dll")

      $netcoreSsoAdminSource = [IO.Path]::Combine(
         $PSScriptRoot,
         "VMware.vSphere.SsoAdmin.Client",
         "VMware.vSphere.SsoAdminClient",
         "bin",
         $Configuration,
         "netcoreapp2.0",
         "VMware.vSphere.SsoAdminClient.dll")

      $net45SsoAdminSource = [IO.Path]::Combine(
         $PSScriptRoot,
         "VMware.vSphere.SsoAdmin.Client",
         "VMware.vSphere.SsoAdminClient",
         "bin",
         $Configuration,
         "net45",
         "VMware.vSphere.SsoAdminClient.dll")

      $netcoreUtilsSource = [IO.Path]::Combine(
         $PSScriptRoot,
         "VMware.vSphere.SsoAdmin.Client",
         "VMware.vSphere.SsoAdmin.Utils",
         "bin",
         $Configuration,
         "netcoreapp2.0",
         "VMware.vSphere.SsoAdmin.Utils.dll")

      $net45UtilsSource = [IO.Path]::Combine(
         $PSScriptRoot,
         "VMware.vSphere.SsoAdmin.Client",
         "VMware.vSphere.SsoAdmin.Utils",
         "bin",
         $Configuration,
         "net45",
         "VMware.vSphere.SsoAdmin.Utils.dll")


      $netcoreTarget = Join-Path $OutputFolder "netcoreapp2.0"
      $net45Target = Join-Path $OutputFolder "net45"

      Copy-Item -Path $netcoreLsSource -Destination $netcoreTarget -Force
      Copy-Item -Path $net45LsSource -Destination $net45Target -Force
      Copy-Item -Path $netcoreSsoAdminSource -Destination $netcoreTarget -Force
      Copy-Item -Path $net45SsoAdminSource -Destination $net45Target -Force
      Copy-Item -Path $netcoreUtilsSource -Destination $netcoreTarget -Force
      Copy-Item -Path $net45UtilsSource -Destination $net45Target -Force
   }
}

function Test {
   if (-not [string]::IsNullOrEmpty($TestVc) -and `
       -not [string]::IsNullOrEmpty($TestVcUser) -and `
       -not [string]::IsNullOrEmpty($TestVcPassword)) {

      # Run Tests in external process because it will load build output binaries
      LogInfo "Run VC integration tests"
      $usePowerShell = (Get-Process -Id $pid).ProcessName
      $testLauncherScript = Join-Path (Join-Path $PSScriptRoot 'test') 'RunTests.ps1'
      $arguments = "-Command $testLauncherScript -VcAddress $TestVc -User $TestVcUser -Password $TestVcPassword"

      Start-Process `
         -FilePath $usePowerShell `
         -ArgumentList $arguments `
         -PassThru `
         -NoNewWindow | `
         Wait-Process
   }
}

# 1. Test Build Tools
LogInfo "Test build tools are available"
Test-BuildToolsAreAvailable

# 2. Build
LogInfo "Build"
Build

# 3. Publish
$OutputFolder = Split-Path $PSScriptRoot
LogInfo "Publish binaries to '$OutputFolder'"
Publish $OutputFolder

# 4. Test
Test