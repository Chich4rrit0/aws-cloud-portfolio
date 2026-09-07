[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ProfileName,

    [string]$Region = 'us-east-1',

    [switch]$Execute
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$vpcName = 'portfolio-p01-vpc'
$vpcCidr = '10.20.0.0/16'
$commonTags = @(
    @{ Key = 'Project'; Value = 'aws-cloud-portfolio' },
    @{ Key = 'ProjectNumber'; Value = '01' },
    @{ Key = 'Environment'; Value = 'development' },
    @{ Key = 'ManagedBy'; Value = 'aws-cli' }
)
$createdResources = [System.Collections.Generic.List[string]]::new()

function Get-TagSpecification {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResourceType,

        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    $tags = @(@{ Key = 'Name'; Value = $Name }) + $commonTags
    $tagValues = $tags | ForEach-Object { "{Key=$($_.Key),Value=$($_.Value)}" }
    return "ResourceType=$ResourceType,Tags=[$($tagValues -join ',')]"
}

function Invoke-AwsJson {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    $rawOutput = & aws @Arguments '--profile' $ProfileName '--region' $Region '--no-cli-pager' '--output' 'json'

    if ($LASTEXITCODE -ne 0) {
        throw "AWS CLI command failed: aws $($Arguments -join ' ')"
    }

    return $rawOutput | ConvertFrom-Json
}

function Invoke-AwsCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    & aws @Arguments '--profile' $ProfileName '--region' $Region '--no-cli-pager'

    if ($LASTEXITCODE -ne 0) {
        throw "AWS CLI command failed: aws $($Arguments -join ' ')"
    }
}

if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
    throw 'AWS CLI was not found in PATH.'
}

if (-not $Execute) {
    Write-Host 'Dry run only. No AWS resources were created.'
    Write-Host "To create the approved network, rerun with -Execute for profile '$ProfileName' in region '$Region'."
    return
}

$existingVpcIds = & aws ec2 describe-vpcs `
    '--profile' $ProfileName `
    '--region' $Region `
    '--no-cli-pager' `
    '--filters' "Name=tag:Name,Values=$vpcName" "Name=cidr-block,Values=$vpcCidr" `
    '--query' 'Vpcs[].VpcId' `
    '--output' 'text'

if ($LASTEXITCODE -ne 0) {
    throw 'Could not check for an existing Project 01 VPC.'
}

$existingVpcIds = @($existingVpcIds -split '\s+' | Where-Object { $_ -and $_ -ne 'None' })

if ($existingVpcIds.Count -gt 0) {
    throw "A Project 01 VPC already exists: $($existingVpcIds -join ', '). Stopping to prevent duplicate resources."
}

try {
    $vpc = Invoke-AwsJson -Arguments @(
        'ec2', 'create-vpc',
        '--cidr-block', $vpcCidr,
        '--tag-specifications', (Get-TagSpecification -ResourceType 'vpc' -Name $vpcName)
    )
    $vpcId = $vpc.Vpc.VpcId
    $createdResources.Add("VPC $vpcId")

    Invoke-AwsCommand -Arguments @('ec2', 'modify-vpc-attribute', '--vpc-id', $vpcId, '--enable-dns-support', 'Value=true')
    Invoke-AwsCommand -Arguments @('ec2', 'modify-vpc-attribute', '--vpc-id', $vpcId, '--enable-dns-hostnames', 'Value=true')

    $internetGateway = Invoke-AwsJson -Arguments @(
        'ec2', 'create-internet-gateway',
        '--tag-specifications', (Get-TagSpecification -ResourceType 'internet-gateway' -Name 'portfolio-p01-igw')
    )
    $internetGatewayId = $internetGateway.InternetGateway.InternetGatewayId
    $createdResources.Add("Internet Gateway $internetGatewayId")
    Invoke-AwsCommand -Arguments @('ec2', 'attach-internet-gateway', '--internet-gateway-id', $internetGatewayId, '--vpc-id', $vpcId)

    $subnetDefinitions = @(
        @{ Name = 'portfolio-p01-public-edge-a'; Cidr = '10.20.0.0/24'; AvailabilityZone = 'us-east-1a'; Public = $true },
        @{ Name = 'portfolio-p01-public-edge-b'; Cidr = '10.20.1.0/24'; AvailabilityZone = 'us-east-1b'; Public = $true },
        @{ Name = 'portfolio-p01-public-app-a'; Cidr = '10.20.10.0/24'; AvailabilityZone = 'us-east-1a'; Public = $true },
        @{ Name = 'portfolio-p01-public-app-b'; Cidr = '10.20.11.0/24'; AvailabilityZone = 'us-east-1b'; Public = $true },
        @{ Name = 'portfolio-p01-private-db-a'; Cidr = '10.20.20.0/24'; AvailabilityZone = 'us-east-1a'; Public = $false },
        @{ Name = 'portfolio-p01-private-db-b'; Cidr = '10.20.21.0/24'; AvailabilityZone = 'us-east-1b'; Public = $false }
    )
    $subnetIds = @{}

    foreach ($subnetDefinition in $subnetDefinitions) {
        $subnet = Invoke-AwsJson -Arguments @(
            'ec2', 'create-subnet',
            '--vpc-id', $vpcId,
            '--cidr-block', $subnetDefinition.Cidr,
            '--availability-zone', $subnetDefinition.AvailabilityZone,
            '--tag-specifications', (Get-TagSpecification -ResourceType 'subnet' -Name $subnetDefinition.Name)
        )
        $subnetId = $subnet.Subnet.SubnetId
        $subnetIds[$subnetDefinition.Name] = $subnetId
        $createdResources.Add("Subnet $subnetId ($($subnetDefinition.Name))")

        if ($subnetDefinition.Public) {
            Invoke-AwsCommand -Arguments @('ec2', 'modify-subnet-attribute', '--subnet-id', $subnetId, '--map-public-ip-on-launch')
        }
    }

    $routeTableDefinitions = @(
        @{ Name = 'portfolio-p01-rt-public-edge'; Subnets = @('portfolio-p01-public-edge-a', 'portfolio-p01-public-edge-b'); InternetRoute = $true },
        @{ Name = 'portfolio-p01-rt-public-app'; Subnets = @('portfolio-p01-public-app-a', 'portfolio-p01-public-app-b'); InternetRoute = $true },
        @{ Name = 'portfolio-p01-rt-private-db'; Subnets = @('portfolio-p01-private-db-a', 'portfolio-p01-private-db-b'); InternetRoute = $false }
    )
    $routeTableIds = @{}

    foreach ($routeTableDefinition in $routeTableDefinitions) {
        $routeTable = Invoke-AwsJson -Arguments @(
            'ec2', 'create-route-table',
            '--vpc-id', $vpcId,
            '--tag-specifications', (Get-TagSpecification -ResourceType 'route-table' -Name $routeTableDefinition.Name)
        )
        $routeTableId = $routeTable.RouteTable.RouteTableId
        $routeTableIds[$routeTableDefinition.Name] = $routeTableId
        $createdResources.Add("Route table $routeTableId ($($routeTableDefinition.Name))")

        if ($routeTableDefinition.InternetRoute) {
            Invoke-AwsCommand -Arguments @(
                'ec2', 'create-route',
                '--route-table-id', $routeTableId,
                '--destination-cidr-block', '0.0.0.0/0',
                '--gateway-id', $internetGatewayId
            )
        }

        foreach ($subnetName in $routeTableDefinition.Subnets) {
            Invoke-AwsCommand -Arguments @(
                'ec2', 'associate-route-table',
                '--route-table-id', $routeTableId,
                '--subnet-id', $subnetIds[$subnetName]
            )
        }
    }

    [PSCustomObject]@{
        VpcId             = $vpcId
        InternetGatewayId = $internetGatewayId
        SubnetIds         = $subnetIds
        RouteTableIds     = $routeTableIds
    }
}
catch {
    Write-Error $_
    if ($createdResources.Count -gt 0) {
        Write-Warning "Partial creation occurred. No automatic cleanup was attempted. Created resources: $($createdResources -join '; ')"
    }
    throw
}
