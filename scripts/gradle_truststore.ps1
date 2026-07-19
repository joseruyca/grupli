function Initialize-GradleJavaTrustStore {
  param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectRoot,

    [Parameter(Mandatory = $true)]
    [string]$AndroidStudioJbr
  )

  if ($env:OS -ne "Windows_NT") {
    return
  }

  $avastThumbprint = "05E9D9D6BECEAA2974FE634C0BDE58D84AB59BA3"
  $certificate = Get-ChildItem Cert:\CurrentUser\Root |
    Where-Object { $_.Thumbprint -eq $avastThumbprint } |
    Select-Object -First 1

  if (-not $certificate) {
    Write-Host "No encuentro el certificado Avast en Windows; sigo sin truststore extra." -ForegroundColor DarkYellow
    return
  }

  $truststoreDir = Join-Path $env:TEMP "grupli-gradle-truststore"
  New-Item -ItemType Directory -Force -Path $truststoreDir | Out-Null

  $certificatePath = Join-Path $truststoreDir "avast-root.cer"
  $truststorePath = Join-Path $truststoreDir "java-truststore.p12"
  [System.IO.File]::WriteAllBytes(
    $certificatePath,
    $certificate.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert)
  )

  if (Test-Path $truststorePath) {
    Remove-Item $truststorePath -Force
  }

  $Keytool = Join-Path $AndroidStudioJbr "bin\keytool.exe"
  if (-not (Test-Path $Keytool)) {
    throw "No encuentro keytool en $Keytool"
  }

  $keytoolArgs = @(
    "-importcert",
    "-noprompt",
    "-alias", "avast-webmail-shield-root",
    "-file", $certificatePath,
    "-keystore", $truststorePath,
    "-storepass", "changeit",
    "-storetype", "PKCS12"
  )
  $keytoolProcess = Start-Process -FilePath $Keytool -ArgumentList $keytoolArgs -Wait -NoNewWindow -PassThru
  if ($keytoolProcess.ExitCode -ne 0) {
    throw "No se pudo crear el truststore local de Java."
  }

  $env:JAVA_TOOL_OPTIONS = "-Djavax.net.ssl.trustStore=$truststorePath -Djavax.net.ssl.trustStorePassword=changeit -Djavax.net.ssl.trustStoreType=PKCS12"
  Write-Host "Usando truststore local para Java/Gradle." -ForegroundColor Cyan
}
