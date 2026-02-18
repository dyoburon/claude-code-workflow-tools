# Claude Code Status Line (Windows / PowerShell)
# Mimics dyoburon's Linux statusline.sh:
#   [Model] <icon> <percent>% (<tokensK/maxK>) | <dir> | <branch or -> | $<cost> | ⏱️ <duration>
# Persists cost/duration across reboots in: %USERPROFILE%\.claude\cost-tally.json

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$inputJson = [Console]::In.ReadToEnd()
if ([string]::IsNullOrWhiteSpace($inputJson)) { exit 0 }

try {
  $d = $inputJson | ConvertFrom-Json
} catch {
  exit 0
}

# --- Basics from JSON ---
$model = $d.model.display_name
if ([string]::IsNullOrWhiteSpace($model)) { $model = "Unknown" }

$contextSize = 200000
if ($null -ne $d.context_window -and $null -ne $d.context_window.context_window_size) {
  $contextSize = [int]$d.context_window.context_window_size
}

# Claude docs commonly expose current dir as .cwd or .workspace.current_dir depending on version.
$cwd = $null
if ($null -ne $d.cwd -and -not [string]::IsNullOrWhiteSpace([string]$d.cwd)) {
  $cwd = [string]$d.cwd
} elseif ($null -ne $d.workspace -and $null -ne $d.workspace.current_dir) {
  $cwd = [string]$d.workspace.current_dir
} else {
  $cwd = (Get-Location).Path
}

$dirName = Split-Path -Leaf $cwd
if ([string]::IsNullOrWhiteSpace($dirName)) { $dirName = $cwd }

# --- Context usage % + token display (current_usage) ---
$percent = 0
$tokenDisplay = "0K"

try {
  $usage = $d.context_window.current_usage
  if ($null -ne $usage) {
    $inputTokens = 0
    $cacheCreate = 0
    $cacheRead   = 0

    if ($null -ne $usage.input_tokens) { $inputTokens = [int]$usage.input_tokens }
    if ($null -ne $usage.cache_creation_input_tokens) { $cacheCreate = [int]$usage.cache_creation_input_tokens }
    if ($null -ne $usage.cache_read_input_tokens) { $cacheRead = [int]$usage.cache_read_input_tokens }

    $currentTokens = $inputTokens + $cacheCreate + $cacheRead

    if ($contextSize -gt 0) {
      $percent = [int](($currentTokens * 100) / $contextSize)
      if ($percent -lt 0) { $percent = 0 }
      if ($percent -gt 100) { $percent = 100 }
    }

    $currentK = [int]($currentTokens / 1000)
    $maxK     = [int]($contextSize / 1000)
    $tokenDisplay = "{0}K/{1}K" -f $currentK, $maxK
  }
} catch {
  # keep defaults
}

# --- Context icon thresholds (matches Linux intent) ---
# Linux script uses different icons at >=60 and >=80; emojis may vary in terminals.
$contextIcon = ""
if ($percent -ge 80) { $contextIcon = "!" }
elseif ($percent -ge 60) { $contextIcon = "~" }
else { $contextIcon = "" }

# --- Git branch (if repo) ---
$gitBranch = ""
try {
  $gitBranch = (& git -C "$cwd" branch --show-current 2>$null).Trim()
} catch {
  $gitBranch = ""
}
$gitDisplay = if ([string]::IsNullOrWhiteSpace($gitBranch)) { "-" } else { $gitBranch }

# --- Cost tracking (persistent, high-water per session) ---
$claudeDir = Join-Path $env:USERPROFILE ".claude"
if (-not (Test-Path $claudeDir)) { New-Item -ItemType Directory -Path $claudeDir | Out-Null }

$trackingFile = Join-Path $claudeDir "cost-tally.json"

$sessionId = "default"
if ($null -ne $d.session_id -and -not [string]::IsNullOrWhiteSpace([string]$d.session_id)) {
  $sessionId = [string]$d.session_id
}

# Totals at context_window level (cumulative for the session)
$totalIn  = 0
$totalOut = 0
if ($null -ne $d.context_window) {
  if ($null -ne $d.context_window.total_input_tokens)  { $totalIn  = [long]$d.context_window.total_input_tokens }
  if ($null -ne $d.context_window.total_output_tokens) { $totalOut = [long]$d.context_window.total_output_tokens }
}

# Pricing per 1M tokens (matches dyoburon comments)
# Opus: $5 in / $25 out, Sonnet: $3 in / $15 out, Haiku: $0.25 in / $1.25 out
$inRate  = 3.0
$outRate = 15.0
if ($model -match "Opus")      { $inRate = 5.0;   $outRate = 25.0 }
elseif ($model -match "Sonnet"){ $inRate = 3.0;   $outRate = 15.0 }
elseif ($model -match "Haiku") { $inRate = 0.25;  $outRate = 1.25 }

# Load existing tracking (if valid)
$startTime = [long]0
$sessions = @{}  # sessionId -> @{ input=..., output=... }

if (Test-Path $trackingFile) {
  try {
    $t = (Get-Content $trackingFile -Raw) | ConvertFrom-Json
    if ($null -ne $t.start_time) { $startTime = [long]$t.start_time }
    if ($null -ne $t.sessions) {
      foreach ($p in $t.sessions.PSObject.Properties) {
        $sid = $p.Name
        $val = $p.Value
        $sessions[$sid] = @{
          input  = [long]($val.input  ?? 0)
          output = [long]($val.output ?? 0)
        }
      }
    }
  } catch {
    # ignore corrupt file; we'll recreate
    $startTime = 0
    $sessions = @{}
  }
}

# Ensure start_time is valid
if ($startTime -le 0) {
  $startTime = [long][DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
}

# Update this session's high-water marks
$prevIn  = 0L
$prevOut = 0L
if ($sessions.ContainsKey($sessionId)) {
  $prevIn  = [long]$sessions[$sessionId].input
  $prevOut = [long]$sessions[$sessionId].output
}

$newIn  = if ($totalIn  -gt $prevIn)  { $totalIn }  else { $prevIn }
$newOut = if ($totalOut -gt $prevOut) { $totalOut } else { $prevOut }

$sessions[$sessionId] = @{ input = $newIn; output = $newOut }

# Sum across all sessions
$sumIn  = 0L
$sumOut = 0L
foreach ($kv in $sessions.GetEnumerator()) {
  $sumIn  += [long]$kv.Value.input
  $sumOut += [long]$kv.Value.output
}

# Write tracking atomically
try {
  $sessionsObj = New-Object psobject
  foreach ($kv in $sessions.GetEnumerator()) {
    $sessionsObj | Add-Member -NotePropertyName $kv.Key -NotePropertyValue (New-Object psobject -Property @{
      input = [long]$kv.Value.input
      output = [long]$kv.Value.output
    })
  }

  $outObj = New-Object psobject -Property @{
    sessions   = $sessionsObj
    start_time = $startTime
  }

  $tmp = Join-Path $claudeDir ("cost-tally.json.tmp")
  $outObj | ConvertTo-Json -Depth 6 | Set-Content -Path $tmp -Encoding utf8
  Move-Item -Force $tmp $trackingFile
} catch {
  # don't break statusline
}

# Cost calc ($xx.xx)
$inputCost  = ($sumIn  * $inRate)  / 1000000.0
$outputCost = ($sumOut * $outRate) / 1000000.0
$totalCost  = $inputCost + $outputCost
$costDisplay = ('$' + ('{0:N2}' -f $totalCost))

# Duration since start_time
$now = [long][DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
$durationSec = [long]($now - $startTime)
if ($durationSec -lt 0) { $durationSec = 0 }

$minutes = [int]($durationSec / 60)
$timeDisplay = ""
if ($minutes -lt 60) {
  $timeDisplay = "`u{23F1}`u{FE0F} {0}m" -f $minutes
} else {
  $hours = [int]($minutes / 60)
  $rem   = [int]($minutes % 60)
  $timeDisplay = "`u{23F1}`u{FE0F} {0}h{1}m" -f $hours, $rem
}

# Final output
$folderIcon = "`u{1F4C1}"
$branchIcon = "`u{1F33F}"
Write-Output ("[{0}] {1} {2}% ({3}) | $folderIcon {4} | $branchIcon {5} | {6} | {7}" -f `
  $model, $contextIcon, $percent, $tokenDisplay, $dirName, $gitDisplay, $costDisplay, $timeDisplay)

