<#
.SYNOPSIS
  Generuje raport wszystkich commitów: hash, autor, data, tydzień, wiadomość.
.DESCRIPTION
  Skrypt wywołuje `git log`, parsuje wynik i wyświetla tabelę w konsoli oraz zapisuje CSV.
#>

# Pobierz historię commitów
$raw = git log --pretty=format:'%h|%an|%ad|%s' --date=iso

# Funkcja do wyliczenia numeru tygodnia ISO
function Get-IsoWeekNumber([datetime]$dt) {
    $cal = [System.Globalization.CultureInfo]::InvariantCulture.Calendar
    return $cal.GetWeekOfYear($dt, [System.Globalization.CalendarWeekRule]::FirstFourDayWeek, [DayOfWeek]::Monday)
}

# Parsowanie i budowa obiektów
$commits = $raw | ForEach-Object {
    $parts = $_ -split '\|', 4
    [PSCustomObject]@{
        Hash    = $parts[0]
        Author  = $parts[1]
        Date    = [datetime]$parts[2]
        Week    = "{0}-{1:00}" -f ([datetime]$parts[2].Year), (Get-IsoWeekNumber ([datetime]$parts[2]))
        Message = $parts[3]
    }
}

# Posortuj malejąco po dacie
$sorted = $commits | Sort-Object Date -Descending

# Wyświetl w konsoli
$sorted | Format-Table Hash,Author,Date,Week,Message -AutoSize

# Zapisz do CSV
$csvPath = Join-Path (Get-Location) 'commits_report.csv'
$sorted | Export-Csv $csvPath -NoTypeInformation -Encoding UTF8

Write-Host "`nZapisano raport do: $csvPath" -ForegroundColor Green
