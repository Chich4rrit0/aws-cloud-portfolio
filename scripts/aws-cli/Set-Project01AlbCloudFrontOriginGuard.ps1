[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ProfileName,

    [string]$Region = 'us-east-1',

    [switch]$Execute
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$loadBalancerName = 'portfolio-p01-app-alb'
$targetGroupName = 'portfolio-p01-app-tg'
$originHeaderName = 'X-Portfolio-Origin-Verify'
$originHeaderParameterPath = '/portfolio/project-01/cloudfront/alb-origin-header'

function Invoke-AwsJson {
    param([string[]]$Arguments)

    $rawOutput = & aws @Arguments '--profile' $ProfileName '--region' $Region '--no-cli-pager' '--output' 'json'
    if ($LASTEXITCODE -ne 0) {
        throw "AWS CLI command failed: aws $($Arguments -join ' ')"
    }
    return $rawOutput | ConvertFrom-Json
}

function Invoke-AwsNoOutput {
    param([string[]]$Arguments)

    $output = & aws @Arguments '--profile' $ProfileName '--region' $Region '--no-cli-pager' 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "AWS CLI command failed: aws $($Arguments -join ' ')`n$($output | Out-String)"
    }
}

if (-not $Execute) {
    [PSCustomObject]@{
        Mode = 'Dry run - no ALB listener or rule will be changed'
        GuardHeader = "$originHeaderName retrieved from SecureString at runtime"
        ForwardRule = 'Only requests bearing the CloudFront origin header reach the Target Group'
        DefaultAction = 'Fixed HTTP 403 response for direct ALB requests'
        Prerequisite = 'CloudFront must be deployed and validated first'
    }
    return
}

try {
    $originHeaderValue = (Invoke-AwsJson -Arguments @('ssm', 'get-parameter', '--name', $originHeaderParameterPath, '--with-decryption')).Parameter.Value
    $loadBalancer = (Invoke-AwsJson -Arguments @('elbv2', 'describe-load-balancers', '--names', $loadBalancerName)).LoadBalancers[0]
    $targetGroup = (Invoke-AwsJson -Arguments @('elbv2', 'describe-target-groups', '--names', $targetGroupName)).TargetGroups[0]
    $listeners = Invoke-AwsJson -Arguments @('elbv2', 'describe-listeners', '--load-balancer-arn', $loadBalancer.LoadBalancerArn)
    $matchingListeners = @($listeners.Listeners | Where-Object { $_.Protocol -eq 'HTTP' -and $_.Port -eq 80 })
    $listener = if ($matchingListeners.Count -eq 0) { $null } else { $matchingListeners[0] }
    if ($null -eq $listener) { throw 'Expected the existing HTTP listener on port 80.' }

    $rules = Invoke-AwsJson -Arguments @('elbv2', 'describe-rules', '--listener-arn', $listener.ListenerArn)
    $matchingRules = @($rules.Rules | Where-Object {
        $_.Conditions | Where-Object {
            $_.Field -eq 'http-header' -and $_.HttpHeaderConfig.HttpHeaderName -ieq $originHeaderName
        }
    })
    $guardRule = if ($matchingRules.Count -eq 0) { $null } else { $matchingRules[0] }

    if ($null -eq $guardRule) {
        $conditions = @(
            @{
                Field = 'http-header'
                HttpHeaderConfig = @{
                    HttpHeaderName = $originHeaderName
                    Values = @($originHeaderValue)
                }
            }
        )
        $temporaryConditions = New-TemporaryFile
        try {
            ConvertTo-Json -InputObject $conditions -Depth 8 | Set-Content -LiteralPath $temporaryConditions -Encoding utf8NoBOM
            Invoke-AwsNoOutput -Arguments @(
                'elbv2', 'create-rule',
                '--listener-arn', $listener.ListenerArn,
                '--priority', '10',
                '--conditions', "file://$temporaryConditions",
                '--actions', "Type=forward,TargetGroupArn=$($targetGroup.TargetGroupArn)"
            )
            Write-Host 'Created the CloudFront origin-header forwarding rule.'
        }
        finally {
            Remove-Item -LiteralPath $temporaryConditions -Force -ErrorAction SilentlyContinue
        }
    }
    else {
        Write-Host 'Reusing the existing CloudFront origin-header forwarding rule.'
    }

    $defaultActions = @(
        @{
            Type = 'fixed-response'
            FixedResponseConfig = @{
                StatusCode = '403'
                ContentType = 'text/plain'
                MessageBody = 'Direct ALB access is not permitted.'
            }
        }
    )
    $temporaryActions = New-TemporaryFile
    try {
        ConvertTo-Json -InputObject $defaultActions -Depth 8 | Set-Content -LiteralPath $temporaryActions -Encoding utf8NoBOM
        Invoke-AwsNoOutput -Arguments @('elbv2', 'modify-listener', '--listener-arn', $listener.ListenerArn, '--default-actions', "file://$temporaryActions")
    }
    finally {
        Remove-Item -LiteralPath $temporaryActions -Force -ErrorAction SilentlyContinue
    }

    [PSCustomObject]@{
        Listener = 'HTTP 80'
        CloudFrontRule = 'Configured using an origin-only header value from SecureString'
        DirectAlbDefault = 'HTTP 403'
        TargetGroup = $targetGroupName
    }
}
catch {
    Write-Error $_
    throw
}
