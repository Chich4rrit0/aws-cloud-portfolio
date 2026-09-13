[CmdletBinding()]
param(
    [string]$ProfileName = 'portfolio-root-temp',
    [string]$Region = 'us-east-1',
    [string]$GitHubOwner = 'Chich4rrit0',
    [string]$GitHubOwnerId = '66883602',
    [string]$GitHubRepository = 'aws-cloud-portfolio',
    [string]$GitHubRepositoryId = '1360395604',
    [string]$Branch = 'main',
    [string]$RepositoryName = 'portfolio-p04-task-manager'
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

$temporaryDirectory = Join-Path ([System.IO.Path]::GetTempPath()) ("portfolio-p04-oidc-" + [guid]::NewGuid())
New-Item -ItemType Directory -Path $temporaryDirectory | Out-Null

try {
    $identity = Invoke-AwsCli -CliArguments @('sts', 'get-caller-identity') | ConvertFrom-Json
    $accountId = $identity.Account
    $repositoryArn = "arn:aws:ecr:${Region}:$accountId`:repository/$RepositoryName"
    $providerArn = "arn:aws:iam::$accountId`:oidc-provider/token.actions.githubusercontent.com"
    $roleName = 'portfolio-p04-github-actions-ecr-publisher'
    $inlinePolicyName = 'PortfolioP04EcrPublisher'

    $repository = Invoke-AwsCli -CliArguments @(
        'ecr', 'describe-repositories',
        '--region', $Region,
        '--repository-names', $RepositoryName
    ) | ConvertFrom-Json

    if ($repository.repositories[0].repositoryArn -ne $repositoryArn) {
        throw 'The resolved ECR repository ARN did not match the expected Project 4 repository.'
    }

    $existingRoleOutput = & aws iam get-role --role-name $roleName --profile $ProfileName --no-cli-pager --output json 2>&1
    $existingRoleExitCode = $LASTEXITCODE

    if ($existingRoleExitCode -eq 0) {
        throw "IAM role '$roleName' already exists. Stopping without changing its trust or permissions."
    }

    $providers = Invoke-AwsCli -CliArguments @('iam', 'list-open-id-connect-providers') | ConvertFrom-Json
    $providerExists = $providers.OpenIDConnectProviderList | Where-Object { $_.Arn -eq $providerArn }

    if (-not $providerExists) {
        Invoke-AwsCli -CliArguments @(
            'iam', 'create-open-id-connect-provider',
            '--url', 'https://token.actions.githubusercontent.com',
            '--client-id-list', 'sts.amazonaws.com',
            '--tags',
            'Key=Project,Value=aws-cloud-portfolio',
            'Key=ProjectNumber,Value=04',
            'Key=Environment,Value=devops-lab',
            'Key=ManagedBy,Value=aws-cli'
        ) | Out-Null
    }

    $provider = Invoke-AwsCli -CliArguments @(
        'iam', 'get-open-id-connect-provider',
        '--open-id-connect-provider-arn', $providerArn
    ) | ConvertFrom-Json

    if ($provider.Url -ne 'token.actions.githubusercontent.com' -or
        $provider.ClientIDList -notcontains 'sts.amazonaws.com') {
        throw 'The existing GitHub OIDC provider does not have the expected URL and audience. No role was created or changed.'
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
                Sid = 'GetEcrAuthorizationToken'
                Effect = 'Allow'
                Action = 'ecr:GetAuthorizationToken'
                Resource = '*'
            },
            @{
                Sid = 'PushOnlyToProject04Repository'
                Effect = 'Allow'
                Action = @(
                    'ecr:BatchCheckLayerAvailability',
                    'ecr:BatchGetImage',
                    'ecr:CompleteLayerUpload',
                    'ecr:InitiateLayerUpload',
                    'ecr:PutImage',
                    'ecr:UploadLayerPart'
                )
                Resource = $repositoryArn
            }
        )
    }

    $trustPolicyPath = Join-Path $temporaryDirectory 'trust-policy.json'
    $permissionsPolicyPath = Join-Path $temporaryDirectory 'permissions-policy.json'
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($trustPolicyPath, ($trustPolicy | ConvertTo-Json -Depth 10), $utf8NoBom)
    [System.IO.File]::WriteAllText($permissionsPolicyPath, ($permissionsPolicy | ConvertTo-Json -Depth 10), $utf8NoBom)

    Invoke-AwsCli -CliArguments @(
        'iam', 'create-role',
        '--role-name', $roleName,
        '--assume-role-policy-document', "file://$trustPolicyPath",
        '--tags',
        'Key=Project,Value=aws-cloud-portfolio',
        'Key=ProjectNumber,Value=04',
        'Key=Environment,Value=devops-lab',
        'Key=ManagedBy,Value=aws-cli'
    ) | Out-Null

    Invoke-AwsCli -CliArguments @(
        'iam', 'put-role-policy',
        '--role-name', $roleName,
        '--policy-name', $inlinePolicyName,
        '--policy-document', "file://$permissionsPolicyPath"
    ) | Out-Null

    $role = Invoke-AwsCli -CliArguments @('iam', 'get-role', '--role-name', $roleName) | ConvertFrom-Json
    $attachedPolicy = Invoke-AwsCli -CliArguments @(
        'iam', 'get-role-policy',
        '--role-name', $roleName,
        '--policy-name', $inlinePolicyName
    ) | ConvertFrom-Json

    $grantedActions = @($attachedPolicy.PolicyDocument.Statement | ForEach-Object { @($_.Action) })
    $expectedActions = @(
        'ecr:GetAuthorizationToken',
        'ecr:BatchCheckLayerAvailability',
        'ecr:BatchGetImage',
        'ecr:CompleteLayerUpload',
        'ecr:InitiateLayerUpload',
        'ecr:PutImage',
        'ecr:UploadLayerPart'
    )

    if ($role.Role.RoleName -ne $roleName -or
        $attachedPolicy.PolicyName -ne $inlinePolicyName -or
        -not $attachedPolicy.PolicyDocument -or
        (@($grantedActions | Sort-Object -Unique) -join ',') -ne (@($expectedActions | Sort-Object) -join ',')) {
        throw 'Post-creation verification did not return the expected OIDC publisher role and inline policy.'
    }

    Write-Host 'GitHub OIDC provider verified.'
    Write-Host 'Project 4 ECR publisher role created and verified.'
    Write-Host 'No image was built or published by this script.'
}
finally {
    if (Test-Path -LiteralPath $temporaryDirectory) {
        Remove-Item -LiteralPath $temporaryDirectory -Recurse -Force
    }
}
