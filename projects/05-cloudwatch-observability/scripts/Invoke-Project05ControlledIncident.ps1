[CmdletBinding()]
param(
    [string]$ProfileName = 'portfolio-root-temp',
    [string]$Region = 'us-east-1',
    [string]$AlarmName = 'portfolio-p05-p02-lambda-errors'
)

$ErrorActionPreference = 'Stop'

function Invoke-AwsJson {
    param([string[]]$Arguments)
    $output = & aws @Arguments --region $Region --profile $ProfileName --no-cli-pager --output json 2>&1
    if ($LASTEXITCODE -ne 0) { throw "AWS CLI failed: aws $($Arguments[0..1] -join ' ')" }
    return ($output -join "`n") | ConvertFrom-Json
}

function Set-ControlledAlarmState {
    param([ValidateSet('ALARM', 'OK')][string]$State, [string]$Reason)
    & aws cloudwatch set-alarm-state --alarm-name $AlarmName --state-value $State --state-reason $Reason --region $Region --profile $ProfileName --no-cli-pager
    if ($LASTEXITCODE -ne 0) { throw "AWS CLI failed to set P5 alarm state to $State." }
}

$alarmReset = $false
try {
    $alarm = Invoke-AwsJson @('cloudwatch', 'describe-alarms', '--alarm-names', $AlarmName)
    if (@($alarm.MetricAlarms).Count -ne 1) { throw 'Expected P5 alarm was not found.' }
    if (@($alarm.MetricAlarms[0].AlarmActions).Count -gt 0 -or @($alarm.MetricAlarms[0].OKActions).Count -gt 0 -or @($alarm.MetricAlarms[0].InsufficientDataActions).Count -gt 0) {
        throw 'The selected alarm has automated actions and cannot be used for the controlled incident.'
    }

    Set-ControlledAlarmState -State ALARM -Reason 'Project 5 controlled incident simulation. No source resource was changed.'
    $alarmReset = $true

    $alarmState = Invoke-AwsJson @('cloudwatch', 'describe-alarms', '--alarm-names', $AlarmName)
    if ($alarmState.MetricAlarms[0].StateValue -ne 'ALARM') { throw 'P5 alarm did not enter ALARM as expected.' }
    Write-Host 'Controlled incident: P5 alarm entered ALARM with no automated action.'

    $queryDefinitions = Invoke-AwsJson @('logs', 'describe-query-definitions', '--query-definition-name-prefix', 'portfolio-p05-p02-lambda-errors')
    $query = @($queryDefinitions.queryDefinitions | Where-Object { $_.name -eq 'portfolio-p05-p02-lambda-errors' }) | Select-Object -First 1
    if (-not $query) { throw 'Expected P5 saved Logs Insights query was not found.' }

    $end = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    $start = [DateTimeOffset]::UtcNow.AddDays(-7).ToUnixTimeSeconds()
    $queryRun = Invoke-AwsJson @('logs', 'start-query', '--log-group-name', '/aws/lambda/portfolio-p02-link-shortener', '--start-time', $start, '--end-time', $end, '--query-string', $query.queryString)

    $queryResult = $null
    for ($attempt = 1; $attempt -le 20; $attempt++) {
        Start-Sleep -Seconds 1
        $queryResult = Invoke-AwsJson @('logs', 'get-query-results', '--query-id', $queryRun.queryId)
        if ($queryResult.status -in @('Complete', 'Failed', 'Cancelled', 'Timeout', 'Unknown')) { break }
    }

    if ($queryResult.status -ne 'Complete') { throw "Logs Insights query ended with status $($queryResult.status)." }
    Write-Host "Logs Insights query completed. Result rows: $(@($queryResult.results).Count)."
}
finally {
    if ($alarmReset) {
        Set-ControlledAlarmState -State OK -Reason 'Project 5 controlled incident simulation completed. State restored to OK.'
        $restored = Invoke-AwsJson @('cloudwatch', 'describe-alarms', '--alarm-names', $AlarmName)
        if ($restored.MetricAlarms[0].StateValue -ne 'OK') { throw 'P5 alarm did not return to OK after the controlled incident.' }
        Write-Host 'Controlled incident completed: P5 alarm restored to OK.'
    }
}
