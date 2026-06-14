$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

& "$PSScriptRoot\quality_gate_v16_20.ps1" @args
