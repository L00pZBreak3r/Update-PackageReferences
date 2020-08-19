param(
  [string]$Path="*",
  [string]$SaveSuffix=""
)
Set-StrictMode -Version Latest

function UpdatePackageReferenceNodes ($aProjectFile)
{
  $ares = $false
  [xml]$aContent = Get-Content -Path $aProjectFile
  $aNodes = $aContent.SelectNodes('//PackageReference')
  foreach ($aNode in $aNodes)
  {
    $aPackages = Find-Package -ProviderName NuGet -AllowPrereleaseVersions -AllVersions -Name $aNode.Include -MinimumVersion $aNode.Version -ErrorAction SilentlyContinue
    if ($aPackages -ne $null)
    {
      $aPackage = $aPackages[0]
      if ($aNode.Version -lt $aPackage.Version)
      {
        if (!$ares)
        {
          Write-Host $aProjectFile.FullName
        }
        Write-Host "$($aNode.Include) : $($aNode.Version) => $($aPackage.Version)"
        $aNode.Version = $aPackage.Version
        $ares = $true
      }
    }
  }
  if ($ares)
  {
    $aSaveFileName = $aProjectFile.BaseName + $SaveSuffix + $aProjectFile.Extension
    $aSaveFullName = Join-Path -Path $aProjectFile.DirectoryName -ChildPath $aSaveFileName
    $aContent.Save($aSaveFullName)
    Write-Host
  }
}

$aIncludedExt = @("*.csproj", "*.vbproj", "*.vcxproj")
$aFiles = Get-ChildItem -Path $Path -File -Recurse -Include $aIncludedExt
foreach ($aFile in $aFiles)
{
  UpdatePackageReferenceNodes $aFile
}
