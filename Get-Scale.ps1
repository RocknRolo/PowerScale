<#
.SYNOPSIS
  Script that calculates the musical tones of the diatonic modes.

.DESCRIPTION
  This script can be used to calculate the tones of all different keys in the 7 different modes of the major scale, the melodic minor scale and the harmonic minor scale.

.PARAMETER Root
  Takes a string (text) decription of the first tone in the scale. Rare keys such as "E#" or "Abbb" are supported. The first character should be between A and G (incl.) and may also be lowercase. The rest of the chars should either be "b" or "#". 

.PARAMETER Mode
  Takes any [int16] number and translates it to a number between 1 and 7, representing one of the modes of the major scale. 
  1 = Ionian, 2 = Dorian, 3 = Phyrgian, 4 = Lydian, 5 = Mixolydian, 6 = Aeolian, 7 = Locrian

.PARAMETER AsString
  Changes the output type from [PSCustomObject] to a string representation of the scale.

.PARAMETER MelodicMinor
  When this flag is set the script will return modes of the melodic minor scale instead of the major scale.

.PARAMETER HarmonicMinor
  When this flag is set the script will return modes of the harmonic minor scale instead of the major scale.

.NOTES
  Version:        0.2
  Author:         RockNRolo (Roel Kemp)
  Website:        rocknrolo.github.io
  Creation Date:  01-11-2024

.EXAMPLE
  .\Get-Scale.ps1 -Root G# -Mode 6 -AsString
  G# A# B C# D# E F#
#>

[CMDletbinding()]param (
  [string]$Root = "C",
  [int16]$Mode = 1,
  [switch]$MelodicMinor,
  [switch]$HarmonicMinor,
  [switch]$AsString
)

<# 
  Checks if user input is valid. 
  The first character should be between A and G (incl.) and may also be lowercase. 
  The rest of the chars should either be "b" or "#".
#>
function CheckText {
  param(
    [string]$Text
  )
  if ($Text.Length -le 0 -or -not "ABCDEFG".contains($Text.Substring(0, 1).ToUpper())) {
    return $false;
  }
  if ($Text.Length -gt 1 -and ($Text[1] -eq "b" -or $Text[1] -eq "#")) {
    for ($i = 1; $i -lt $Text.Length; $i++) {
      if (-not ($Text[$i] -eq $Text[1])) {
        return $false;
      }
    }
  }  
  return $true;
}

<# 
  Changes the first character to uppercase and stores it in the "Natural" attribute. 
  The rest of the chars are counted and the resulting number is stored in the "FlatSharp" attribute. 
  "FlatSharp" is made negative if $Text[1] equals "b".
#>
function TextToTone {
  param (
    [string]$Text
  )
  $len = $Text.Length - 1;
  $flatSharp = $len; 
  if ($Text.length -gt 1 -and $Text[1] -eq "b") {
    $flatSharp = -$flatSharp;
  }
  return [PSCustomObject]@{Natural = $Text.Substring(0, 1).ToUpper(); FlatSharp = $flatSharp;};
}

<#
  Takes a "Tone" object and returns a string representation of that object.
#>
function ToneToText {
  param (
    [PSCustomObject]$Tone
  )
  $result = $Tone.Natural;
  $n = [Math]::Abs($Tone.FlatSharp)
  if ($Tone.FlatSharp -gt 0) {
    $result += "#" * $n;
  } 
  elseif ($Tone.FlatSharp -lt 0) {
    $result += "b" * $n;
  }
  return $result;
}

<#
  Shifts the order or array $Array by amount $Shift. $Shift may be larger than the size of the array and may be negative.
#>
function ShiftArray {
  param (
    [Int16[]]$Array,
    [Int16]$Shift
  )
  while ($Shift -lt 0) {
    $Shift += $Array.Length;
  }
  $result = @();
  for ($i = 0; $i -lt $Array.Length; $i++) {
    $index = ($i + $Shift) % $Array.Length;
    $result += $Array[$index];
  }
  return $result;
}

# The actual logic of the script starts here.
if (-not (CheckText($Root))) {
  Throw "Invalid input!"
}

[string]$Halves = "C D EF G A B";
[string]$Wholes = "CDEFGAB";

[Int16[]]$Steps = 2, 2, 1, 2, 2, 2, 1;

if ($HarmonicMinor) {
  $Steps = 2, 2, 1, 3, 1, 2, 1;
}
if ($MelodicMinor) {
  $Steps = 2, 2, 2, 2, 1, 2, 1;
}

$Steps = ShiftArray -Array $Steps -Shift $($Mode - 1);

$RootTone = TextToTone($Root);
$Scale = @($RootTone);

for ($i = 1; $i -lt $Steps.Length; $i++) {
  $CurrTone = $Scale[$Scale.Length - 1];
  
  $CurrWholeIndex = $Wholes.IndexOf($CurrTone.Natural);
  $NextWholeIndex = ($CurrWholeIndex + 1) % $Wholes.Length;
  $NextWholeNatural = $Wholes[$NextWholeIndex];
  
  $CurrHalveIndex = $Halves.IndexOf($CurrTone.Natural);
  $NextHalveIndex = $CurrHalveIndex + $Steps[$i-1];
  
  $FlatSharp = $CurrTone.FlatSharp;
  
  if (-not ($Halves[($NextHalveIndex) % $Halves.Length] -eq $NextWholeNatural)) {
    for ($j = 0; $j -lt $Halves.length - 1; $j++) {
      if ($Halves[($NextHalveIndex + $j) % $Halves.Length] -eq $NextWholeNatural) {
        $FlatSharp -= $j;
        break;
      }
      elseif ($Halves[($NextHalveIndex - $j) % $Halves.Length] -eq $NextWholeNatural) {
        $FlatSharp += $j;
        break;
      }
    }
  }
  
  $Scale += [PSCustomObject]@{Natural = $NextWholeNatural; FlatSharp = $FlatSharp;};
}

if ($AsString) {
  $StrScale = "";
  for ($i = 0; $i -lt $Scale.Length; $i++) {
    $StrScale += $(ToneToText($Scale[$i]));
    if ($i -lt $Scale.Count - 1) {
      $StrScale += " ";
    }
  }
  return $StrScale;
}

return $Scale;

<#
Possible upgrades:
- Add support for Pentatonic scales.
- Add visual display
#>