[CmdletBinding()]
param(
    [string]$ProfileName = 'portfolio-root-temp',
    [string]$Region = 'us-east-1'
)

$ErrorActionPreference = 'Stop'

function Invoke-AwsJson {
    param([string[]]$Arguments)

    $output = & aws @Arguments --region $Region --profile $ProfileName --no-cli-pager --output json 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "AWS CLI failed: aws $($Arguments[0..1] -join ' ')"
    }

    return ($output -join "`n") | ConvertFrom-Json
}

$p2FunctionName = 'portfolio-p02-link-shortener'
$p2TableName = 'portfolio-p02-links'
$p2ApiName = 'portfolio-p02-link-shortener-api'
$p2LogGroupName = '/aws/lambda/portfolio-p02-link-shortener'
$p4ClusterName = 'portfolio-p04-ecs-lab'
$p4ServiceName = 'portfolio-p04-task-manager'
$p4LogGroupName = '/ecs/portfolio-p04-task-manager'

$p2Function = Invoke-AwsJson @('lambda', 'get-function-configuration', '--function-name', $p2FunctionName)
$p2Table = Invoke-AwsJson @('dynamodb', 'describe-table', '--table-name', $p2TableName)
$p2Apis = Invoke-AwsJson @('apigatewayv2', 'get-apis')
$p2Logs = Invoke-AwsJson @('logs', 'describe-log-groups', '--log-group-name-prefix', $p2LogGroupName)
$p4Stack = Invoke-AwsJson @('cloudformation', 'describe-stacks', '--stack-name', 'portfolio-p04-ecs-lab')
$p4Service = Invoke-AwsJson @('ecs', 'describe-services', '--cluster', $p4ClusterName, '--services', $p4ServiceName)
$p4Logs = Invoke-AwsJson @('logs', 'describe-log-groups', '--log-group-name-prefix', $p4LogGroupName)

$result = [ordered]@{
    region = $Region
    project02 = [ordered]@{
        lambda = [ordered]@{ name = $p2Function.FunctionName; state = $p2Function.State; runtime = $p2Function.Runtime }
        dynamodb = [ordered]@{ name = $p2Table.Table.TableName; state = $p2Table.Table.TableStatus; billingMode = $p2Table.Table.BillingModeSummary.BillingMode }
        httpApiFound = @($p2Apis.Items | Where-Object { $_.Name -eq $p2ApiName }).Count -eq 1
        logGroup = [ordered]@{ name = $p2LogGroupName; retentionDays = $p2Logs.logGroups[0].retentionInDays; storedBytes = $p2Logs.logGroups[0].storedBytes }
    }
    project04 = [ordered]@{
        stackStatus = $p4Stack.Stacks[0].StackStatus
        ecs = [ordered]@{ cluster = $p4ClusterName; service = $p4ServiceName; runningCount = $p4Service.services[0].runningCount; desiredCount = $p4Service.services[0].desiredCount; rollout = $p4Service.services[0].deployments[0].rolloutState }
        logGroup = [ordered]@{ name = $p4LogGroupName; retentionDays = $p4Logs.logGroups[0].retentionInDays; storedBytes = $p4Logs.logGroups[0].storedBytes }
    }
}

$result | ConvertTo-Json -Depth 6
Write-Host 'Source inventory completed. This script made read-only AWS API calls and created no resources.'
