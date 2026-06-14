$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

& "$PSScriptRoot\security_audit_v16_21.ps1"
& "$PSScriptRoot\quality_gate_v16_20.ps1" @args
