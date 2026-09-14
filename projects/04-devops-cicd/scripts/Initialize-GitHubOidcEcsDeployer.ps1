[CmdletBinding()]
param(
    [string]$ProfileName = 'portfolio-root-temp',
    [string]$Region = 'us-east-1',
    [string]$GitHubOwner = 'Chich4rrit0',
    [string]$GitHubOwnerId = '66883602',
    [string]$GitHubRepository = 'aws-cloud-portfolio',
    [string]$GitHubRepositoryId = '1360395604',
    [string]$Branch = 'main',
    [switch]$UpdateExisting
)

$ErrorActionPreference = 'Stop'

function Invoke-AwsCli {
    param([string[]]$CliArguments)

    $output = & aws @CliArguments --profile $ProfileName --no-cli-pager --output json 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "AWS CLI failed: aws $($CliArguments[0..1] -join ' ')"
    }

    return ($output -join "`n")
}

if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
    throw 'AWS CLI was not found in PATH.'
}

$temporaryDirectory = Join-Path ([System.IO.Path]::GetTempPath()) ("portfolio-p04-ecs-oidc-" + [guid]::NewGuid())
New-Item -ItemType Directory -Path $temporaryDirectory | Out-Null

try {
    $identity = Invoke-AwsCli -CliArguments @('sts', 'get-caller-identity') | ConvertFrom-Json
    $accountId = $identity.Account
    $providerArn = "arn:aws:iam::$accountId`:oidc-provider/token.actions.githubusercontent.com"
    $roleName = 'portfolio-p04-github-actions-ecs-deployer'
    $inlinePolicyName = 'PortfolioP04EcsDeployer'
    $clusterArn = "arn:aws:ecs:${Region}:$accountId`:cluster/portfolio-p04-ecs-lab"
    $serviceArn = "arn:aws:ecs:${Region}:$accountId`:service/portfolio-p04-ecs-lab/portfolio-p04-task-manager"
    $taskDefinitionArn = "arn:aws:ecs:${Region}:$accountId`:task-definition/portfolio-p04-task-manager:*"
    $executionRoleArn = "arn:aws:iam::$accountId`:role/portfolio-p04-ecs-task-execution"
    $repositoryArn = "arn:aws:ecr:${Region}:$accountId`:repository/portfolio-p04-task-manager"

    $provider = Invoke-AwsCli -CliArguments @(
        'iam', 'get-open-id-connect-provider',
        '--open-id-connect-provider-arn', $providerArn
    ) | ConvertFrom-Json

    if ($provider.Url -ne 'token.actions.githubusercontent.com' -or
        $provider.ClientIDList -notcontains 'sts.amazonaws.com') {
        throw 'The GitHub OIDC provider does not have the expected URL and audience. No role was created or changed.'
    }

    $existingRoleOutput = & aws iam get-role --role-name $roleName --profile $ProfileName --no-cli-pager --output json 2>&1
    $roleExists = $LASTEXITCODE -eq 0
    if ($roleExists -and -not $UpdateExisting) {
        throw "IAM role '$roleName' already exists. Re-run with -UpdateExisting only to replace its documented inline policy."
    }
    if (-not $roleExists -and ($existingRoleOutput -join "`n") -notmatch 'NoSuchEntity') {
        throw "Could not determine whether IAM role '$roleName' exists. Stopping without changing IAM."
    }

    $trustPolicy = @{
        Version = '2012-10-17'
        Statement = @(
            @{
                Effect = 'Allow'
                Principal = @{ Federated = $providerArn }
                Action = 'sts:AssumeRoleWithWebIdentity'
                Condition = @{
                    StringEquals = @{
                        'token.actions.githubusercontent.com:aud' = 'sts.amazonaws.com'
                        'token.actions.githubusercontent.com:sub' = "repo:$GitHubOwner@$GitHubOwnerId/$GitHubRepository@$GitHubRepositoryId`:ref:refs/heads/$Branch"
                        'token.actions.githubusercontent.com:repository_owner_id' = $GitHubOwnerId
                        'token.actions.githubusercontent.com:repository_id' = $GitHubRepositoryId
                        'token.actions.githubusercontent.com:ref' = "refs/heads/$Branch"
                    }
                }
            }
        )
    }

    $permissionsPolicy = @{
        Version = '2012-10-17'
        Statement = @(
            @{
                Sid = 'ReadTheSingleProjectImage'
                Effect = 'Allow'
                Action = @('ecr:DescribeImages', 'ecr:DescribeRepositories')
                Resource = $repositoryArn
            },
            @{
                Sid = 'DescribeOnlyTheTemporaryService'
                Effect = 'Allow'
                Action = 'ecs:DescribeServices'
                Resource = $serviceArn
                Condition = @{ StringEquals = @{ 'ecs:cluster' = $clusterArn } }
            },
            @{
                Sid = 'DescribeTaskDefinitionRequiredWildcard'
                Effect = 'Allow'
                Action = 'ecs:DescribeTaskDefinition'
                Resource = '*'
            },
            @{
                Sid = 'RegisterOnlyProject04TaskDefinitions'
                Effect = 'Allow'
                Action = 'ecs:RegisterTaskDefinition'
                Resource = $taskDefinitionArn
            },
            @{
                Sid = 'UpdateOnlyTheTemporaryService'
                Effect = 'Allow'
                Action = 'ecs:UpdateService'
                Resource = $serviceArn
            },
            @{
                Sid = 'PassOnlyTheTemporaryExecutionRole'
                Effect = 'Allow'
                Action = 'iam:PassRole'
                Resource = $executionRoleArn
                Condition = @{ StringEquals = @{ 'iam:PassedToService' = 'ecs-tasks.amazonaws.com' } }
            }
        )
    }

    $trustPolicyPath = Join-Path $temporaryDirectory 'trust-policy.json'
    $permissionsPolicyPath = Join-Path $temporaryDirectory 'permissions-policy.json'
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($trustPolicyPath, ($trustPolicy | ConvertTo-Json -Depth 10), $utf8NoBom)
    [System.IO.File]::WriteAllText($permissionsPolicyPath, ($permissionsPolicy | ConvertTo-Json -Depth 10), $utf8NoBom)

    if (-not $roleExists) {
        Invoke-AwsCli -CliArguments @(
            'iam', 'create-role', '--role-name', $roleName,
            '--assume-role-policy-document', "file://$trustPolicyPath",
            '--tags', 'Key=Project,Value=aws-cloud-portfolio', 'Key=ProjectNumber,Value=04',
            'Key=Environment,Value=devops-lab', 'Key=ManagedBy,Value=aws-cli'
        ) | Out-Null
    }

    Invoke-AwsCli -CliArguments @(
        'iam', 'put-role-policy', '--role-name', $roleName,
        '--policy-name', $inlinePolicyName,
        '--policy-document', "file://$permissionsPolicyPath"
    ) | Out-Null

    $role = Invoke-AwsCli -CliArguments @('iam', 'get-role', '--role-name', $roleName) | ConvertFrom-Json
    $policy = Invoke-AwsCli -CliArguments @('iam', 'get-role-policy', '--role-name', $roleName, '--policy-name', $inlinePolicyName) | ConvertFrom-Json
    if ($role.Role.RoleName -ne $roleName -or $policy.PolicyName -ne $inlinePolicyName) {
        throw 'Post-creation verification did not return the expected ECS deployer role and inline policy.'
    }

    Write-Host 'GitHub OIDC provider verified.'
    Write-Host "Project 4 ECS deployer role $(if ($roleExists) { 'policy updated' } else { 'created' }) and verified."
    Write-Host 'This role can update only the temporary Project 4 ECS service; it cannot create infrastructure.'
}
finally {
    if (Test-Path -LiteralPath $temporaryDirectory) {
        Remove-Item -LiteralPath $temporaryDirectory -Recurse -Force
    }
}
