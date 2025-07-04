# report_commits.ps1

# Pobierz commity
$commits = git log --pretty=format:'%H|%an|%ad|%s' --date=iso |
    ForEach-Object {
        $fields = $_ -split '\|', 4
        if ($fields.Count -eq 4) {
            [PSCustomObject]@{
                Hash    = $fields[0]
                Author  = $fields[1]
                Date    = [datetime]::Parse($fields[2])
                Message = $fields[3]
                Week    = [System.Globalization.ISOWeek]::GetWeekOfYear([datetime]::Parse($fields[2]))
            }
        }
    }

# Sprawdź czy dane istnieją
if (-not $commits) {
    Write-Error "Brak commitów do zapisania. Upewnij się, że jesteś w katalogu repozytorium Git."
    exit 1
}

# Zapisz do CSV w UTF-8 bez BOM
$commits | Export-Csv -Path ".\commits_report.csv" -NoTypeInformation -Encoding UTF8

Write-Host "✅ Plik commits_report.csv został utworzony pomyślnie."
