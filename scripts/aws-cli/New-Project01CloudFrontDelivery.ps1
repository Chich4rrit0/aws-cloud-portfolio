[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ProfileName,

    [string]$Region = 'us-east-1',

    [switch]$Execute
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$frontendSource = Join-Path $PSScriptRoot '..\..\projects\01-web-task-manager\frontend'
$bucketPrefix = 'portfolio-p01-frontend'
$oacName = 'portfolio-p01-frontend-oac'
$distributionComment = 'Project 01 Task Manager frontend and API delivery'
$loadBalancerName = 'portfolio-p01-app-alb'
$originHeaderName = 'X-Portfolio-Origin-Verify'
$originHeaderParameterPath = '/portfolio/project-01/cloudfront/alb-origin-header'
$cachePolicyOptimized = '658327ea-f89d-4fab-a63d-7e88639e58f6'
$cachePolicyDisabled = '4135ea2d-6df8-44a3-9df3-4b5a84be39ad'
$originRequestPolicyAllViewerExceptHost = 'b689b0a8-53d0-40ab-baf2-68738e2966ac'

function Invoke-AwsJson {
    param([string[]]$Arguments)

    $rawOutput = & aws @Arguments '--profile' $ProfileName '--region' $Region '--no-cli-pager' '--output' 'json'
    if ($LASTEXITCODE -ne 0) {
        throw "AWS CLI command failed: aws $($Arguments -join ' ')"
    }
    return $rawOutput | ConvertFrom-Json
}

function Invoke-AwsNoOutput {
    param(
        [string[]]$Arguments,
        [switch]$Sensitive
    )

    $output = & aws @Arguments '--profile' $ProfileName '--region' $Region '--no-cli-pager' 2>&1
    if ($LASTEXITCODE -ne 0) {
        if ($Sensitive) {
            throw 'An AWS CLI command containing sensitive input failed.'
        }
        throw "AWS CLI command failed: aws $($Arguments -join ' ')`n$($output | Out-String)"
    }
}

function Get-ExistingOriginAccessControl {
    $controls = Invoke-AwsJson -Arguments @('cloudfront', 'list-origin-access-controls')
    if ($null -eq $controls -or $null -eq $controls.OriginAccessControlList) {
        return $null
    }
    return @($controls.OriginAccessControlList.Items | Where-Object { $_.Name -eq $oacName } | Select-Object -First 1)[0]
}

function Get-ExistingDistribution {
    $distributions = Invoke-AwsJson -Arguments @('cloudfront', 'list-distributions')
    if ($null -eq $distributions -or $null -eq $distributions.DistributionList) {
        return $null
    }
    return @($distributions.DistributionList.Items | Where-Object { $_.Comment -eq $distributionComment } | Select-Object -First 1)[0]
}

function Get-OriginHeaderValue {
    $output = & aws ssm get-parameter '--name' $originHeaderParameterPath '--with-decryption' '--profile' $ProfileName '--region' $Region '--no-cli-pager' '--output' 'json' 2>&1
    if ($LASTEXITCODE -eq 0) {
        return ($output | ConvertFrom-Json).Parameter.Value
    }
    if (($output | Out-String) -notmatch 'ParameterNotFound') {
        throw 'Could not query the CloudFront origin header parameter.'
    }

    $randomBytes = New-Object byte[] 32
    [System.Security.Cryptography.RandomNumberGenerator]::Fill($randomBytes)
    $value = [Convert]::ToBase64String($randomBytes).TrimEnd('=').Replace('+', '-').Replace('/', '_')
    Invoke-AwsNoOutput -Sensitive -Arguments @(
        'ssm', 'put-parameter',
        '--name', $originHeaderParameterPath,
        '--type', 'SecureString',
        '--value', $value,
        '--tags', 'Key=Project,Value=aws-cloud-portfolio', 'Key=ProjectNumber,Value=01', 'Key=Environment,Value=development', 'Key=ManagedBy,Value=aws-cli'
    )
    return $value
}

function New-FrontendBucket {
    param([string]$BucketName)

    $buckets = Invoke-AwsJson -Arguments @('s3api', 'list-buckets')
    $exists = @($buckets.Buckets | Where-Object { $_.Name -eq $BucketName }).Count -eq 1
    if (-not $exists) {
        Invoke-AwsNoOutput -Arguments @('s3api', 'create-bucket', '--bucket', $BucketName)
        Write-Host 'Created private frontend bucket.'
    }
    else {
        Write-Host 'Reusing private frontend bucket.'
    }

    Invoke-AwsNoOutput -Arguments @('s3api', 'put-public-access-block', '--bucket', $BucketName, '--public-access-block-configuration', 'BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true')
    Invoke-AwsNoOutput -Arguments @('s3api', 'put-bucket-ownership-controls', '--bucket', $BucketName, '--ownership-controls', 'Rules=[{ObjectOwnership=BucketOwnerEnforced}]')
    Invoke-AwsNoOutput -Arguments @('s3api', 'put-bucket-encryption', '--bucket', $BucketName, '--server-side-encryption-configuration', 'Rules=[{ApplyServerSideEncryptionByDefault={SSEAlgorithm=AES256}}]')
    Invoke-AwsNoOutput -Arguments @('s3api', 'put-bucket-tagging', '--bucket', $BucketName, '--tagging', 'TagSet=[{Key=Name,Value=portfolio-p01-frontend},{Key=Project,Value=aws-cloud-portfolio},{Key=ProjectNumber,Value=01},{Key=Environment,Value=development},{Key=ManagedBy,Value=aws-cli}]')
}

if (-not $Execute) {
    [PSCustomObject]@{
        Mode = 'Dry run - no S3 bucket, OAC, CloudFront distribution, secret parameter or uploads will be created'
        FrontendBucket = 'portfolio-p01-frontend-<account-id>-us-east-1 (private, SSE-S3, OAC only)'
        CloudFront = 'Default origin S3; /api/* and /health routed to existing ALB'
        ViewerProtocol = 'Redirect HTTP to HTTPS using the default CloudFront domain'
        OriginGuard = 'A SecureString header is prepared for the following ALB listener-rule step'
        PaidPlan = 'No CloudFront paid flat-rate plan is selected'
    }
    return
}

try {
    if (-not (Test-Path -LiteralPath $frontendSource -PathType Container)) {
        throw 'The frontend source directory does not exist.'
    }

    $accountId = (Invoke-AwsJson -Arguments @('sts', 'get-caller-identity')).Account
    $bucketName = "$bucketPrefix-$accountId-$Region"
    New-FrontendBucket -BucketName $bucketName

    $oac = Get-ExistingOriginAccessControl
    if ($null -eq $oac) {
        $oacConfiguration = @{
            Name = $oacName
            Description = 'OAC for the private Project 01 Task Manager frontend bucket.'
            SigningProtocol = 'sigv4'
            SigningBehavior = 'always'
            OriginAccessControlOriginType = 's3'
        } | ConvertTo-Json -Compress
        $oac = (Invoke-AwsJson -Arguments @('cloudfront', 'create-origin-access-control', '--origin-access-control-config', $oacConfiguration)).OriginAccessControl
        Write-Host 'Created CloudFront Origin Access Control.'
    }
    else {
        Write-Host 'Reusing CloudFront Origin Access Control.'
    }

    $originHeaderValue = Get-OriginHeaderValue
    $loadBalancer = (Invoke-AwsJson -Arguments @('elbv2', 'describe-load-balancers', '--names', $loadBalancerName)).LoadBalancers[0]
    if ($loadBalancer.State.Code -ne 'active') { throw 'The application ALB must be active before CloudFront delivery is created.' }

    $distribution = Get-ExistingDistribution
    if ($null -eq $distribution) {
        $distributionConfig = @{
            CallerReference = [guid]::NewGuid().ToString()
            Comment = $distributionComment
            Enabled = $true
            DefaultRootObject = 'index.html'
            PriceClass = 'PriceClass_100'
            HttpVersion = 'http2and3'
            IsIPV6Enabled = $true
            Origins = @{
                Quantity = 2
                Items = @(
                    @{
                        Id = 's3-frontend'
                        DomainName = "$bucketName.s3.$Region.amazonaws.com"
                        OriginAccessControlId = $oac.Id
                        S3OriginConfig = @{ OriginAccessIdentity = '' }
                    },
                    @{
                        Id = 'alb-api'
                        DomainName = $loadBalancer.DNSName
                        CustomHeaders = @{
                            Quantity = 1
                            Items = @(@{ HeaderName = $originHeaderName; HeaderValue = $originHeaderValue })
                        }
                        CustomOriginConfig = @{
                            HTTPPort = 80
                            HTTPSPort = 443
                            OriginProtocolPolicy = 'http-only'
                            OriginSslProtocols = @{ Quantity = 1; Items = @('TLSv1.2') }
                            OriginReadTimeout = 30
                            OriginKeepaliveTimeout = 5
                        }
                    }
                )
            }
            DefaultCacheBehavior = @{
                TargetOriginId = 's3-frontend'
                ViewerProtocolPolicy = 'redirect-to-https'
                Compress = $true
                AllowedMethods = @{ Quantity = 2; Items = @('GET', 'HEAD'); CachedMethods = @{ Quantity = 2; Items = @('GET', 'HEAD') } }
                CachePolicyId = $cachePolicyOptimized
            }
            CacheBehaviors = @{
                Quantity = 2
                Items = @(
                    @{
                        PathPattern = '/api/*'
                        TargetOriginId = 'alb-api'
                        ViewerProtocolPolicy = 'redirect-to-https'
                        Compress = $true
                        AllowedMethods = @{ Quantity = 7; Items = @('GET', 'HEAD', 'OPTIONS', 'PUT', 'PATCH', 'POST', 'DELETE'); CachedMethods = @{ Quantity = 3; Items = @('GET', 'HEAD', 'OPTIONS') } }
                        CachePolicyId = $cachePolicyDisabled
                        OriginRequestPolicyId = $originRequestPolicyAllViewerExceptHost
                    },
                    @{
                        PathPattern = '/health'
                        TargetOriginId = 'alb-api'
                        ViewerProtocolPolicy = 'redirect-to-https'
                        Compress = $true
                        AllowedMethods = @{ Quantity = 2; Items = @('GET', 'HEAD'); CachedMethods = @{ Quantity = 2; Items = @('GET', 'HEAD') } }
                        CachePolicyId = $cachePolicyDisabled
                        OriginRequestPolicyId = $originRequestPolicyAllViewerExceptHost
                    }
                )
            }
            Restrictions = @{ GeoRestriction = @{ RestrictionType = 'none'; Quantity = 0 } }
            ViewerCertificate = @{ CloudFrontDefaultCertificate = $true; MinimumProtocolVersion = 'TLSv1' }
        }

        $temporaryConfig = New-TemporaryFile
        try {
            $distributionConfig | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $temporaryConfig -Encoding utf8NoBOM
            $distribution = (Invoke-AwsJson -Arguments @('cloudfront', 'create-distribution', '--distribution-config', "file://$temporaryConfig")).Distribution
            Write-Host 'Created CloudFront distribution.'
        }
        finally {
            Remove-Item -LiteralPath $temporaryConfig -Force -ErrorAction SilentlyContinue
        }
    }
    else {
        Write-Host 'Reusing CloudFront distribution.'
    }

    $bucketPolicy = @{
        Version = '2012-10-17'
        Statement = @(
            @{
                Sid = 'AllowCloudFrontServiceReadOnly'
                Effect = 'Allow'
                Principal = @{ Service = 'cloudfront.amazonaws.com' }
                Action = 's3:GetObject'
                Resource = "arn:aws:s3:::$bucketName/*"
                Condition = @{ StringEquals = @{ 'AWS:SourceArn' = $distribution.ARN } }
            }
        )
    }
    $temporaryPolicy = New-TemporaryFile
    try {
        $bucketPolicy | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $temporaryPolicy -Encoding utf8NoBOM
        Invoke-AwsNoOutput -Arguments @('s3api', 'put-bucket-policy', '--bucket', $bucketName, '--policy', "file://$temporaryPolicy")
    }
    finally {
        Remove-Item -LiteralPath $temporaryPolicy -Force -ErrorAction SilentlyContinue
    }

    Invoke-AwsNoOutput -Arguments @('s3', 'sync', $frontendSource, "s3://$bucketName")

    [PSCustomObject]@{
        FrontendBucket = $bucketName
        CloudFrontDistributionId = $distribution.Id
        CloudFrontDomainName = $distribution.DomainName
        DistributionStatus = $distribution.Status
        StaticOrigin = 'Private S3 via OAC'
        ApiOrigin = 'ALB with a protected origin-only header'
        NextStep = 'Wait for distribution deployment, validate CloudFront, then reject direct ALB requests.'
    }
}
catch {
    Write-Error $_
    throw
}
