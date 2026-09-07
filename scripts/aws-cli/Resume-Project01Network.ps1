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
    param([string]$ResourceType, [string]$Name)

    $tags = @(@{ Key = 'Name'; Value = $Name }) + $commonTags
    $tagValues = $tags | ForEach-Object { "{Key=$($_.Key),Value=$($_.Value)}" }
    return "ResourceType=$ResourceType,Tags=[$($tagValues -join ',')]"
}

function Invoke-AwsJson {
    param([string[]]$Arguments)

    $rawOutput = & aws @Arguments '--profile' $ProfileName '--region' $Region '--no-cli-pager' '--output' 'json'
    if ($LASTEXITCODE -ne 0) {
        throw "AWS CLI command failed: aws $($Arguments -join ' ')"
    }
    return $rawOutput | ConvertFrom-Json
}

function Invoke-AwsCommand {
    param([string[]]$Arguments)

    $null = & aws @Arguments '--profile' $ProfileName '--region' $Region '--no-cli-pager'
    if ($LASTEXITCODE -ne 0) {
        throw "AWS CLI command failed: aws $($Arguments -join ' ')"
    }
}

function Find-Resources {
    param([string[]]$Arguments)

    $resources = @((Invoke-AwsJson -Arguments $Arguments) | Where-Object { $null -ne $_ })
    return ,$resources
}

if (-not $Execute) {
    Write-Host 'Dry run only. No AWS resources were created or changed.'
    return
}

try {
    $vpcs = Find-Resources -Arguments @(
        'ec2', 'describe-vpcs',
        '--filters', "Name=tag:Name,Values=$vpcName", "Name=cidr-block,Values=$vpcCidr",
        '--query', 'Vpcs[]'
    )

    if ($vpcs.Count -ne 1) {
        throw "Expected exactly one existing VPC named '$vpcName' with CIDR '$vpcCidr'; found $($vpcs.Count)."
    }

    $vpcId = $vpcs[0].VpcId
    Write-Host "Reusing VPC $vpcId."
    Invoke-AwsCommand -Arguments @('ec2', 'modify-vpc-attribute', '--vpc-id', $vpcId, '--enable-dns-support', 'Value=true')
    Invoke-AwsCommand -Arguments @('ec2', 'modify-vpc-attribute', '--vpc-id', $vpcId, '--enable-dns-hostnames', 'Value=true')

    $internetGateways = Find-Resources -Arguments @(
        'ec2', 'describe-internet-gateways',
        '--filters', 'Name=tag:Name,Values=portfolio-p01-igw',
        '--query', 'InternetGateways[]'
    )

    if ($internetGateways.Count -gt 1) {
        throw "Expected no more than one Internet Gateway named portfolio-p01-igw; found $($internetGateways.Count)."
    }

    if ($internetGateways.Count -eq 1) {
        $internetGateway = $internetGateways[0]
        $internetGatewayId = $internetGateway.InternetGatewayId
        Write-Host "Reusing Internet Gateway $internetGatewayId."
    }
    else {
        $internetGateway = Invoke-AwsJson -Arguments @(
            'ec2', 'create-internet-gateway',
            '--tag-specifications', (Get-TagSpecification -ResourceType 'internet-gateway' -Name 'portfolio-p01-igw')
        )
        $internetGatewayId = $internetGateway.InternetGateway.InternetGatewayId
        $createdResources.Add("Internet Gateway $internetGatewayId")
        Write-Host "Created Internet Gateway $internetGatewayId."
    }

    $attachedVpcIds = @($internetGateway.Attachments | ForEach-Object { $_.VpcId } | Where-Object { $_ })
    if ($attachedVpcIds.Count -gt 0 -and $attachedVpcIds -notcontains $vpcId) {
        throw "Internet Gateway $internetGatewayId is attached to another VPC."
    }
    if ($attachedVpcIds -notcontains $vpcId) {
        Invoke-AwsCommand -Arguments @('ec2', 'attach-internet-gateway', '--internet-gateway-id', $internetGatewayId, '--vpc-id', $vpcId)
    }

    $subnetDefinitions = @(
        @{ Name = 'portfolio-p01-public-edge-a'; Cidr = '10.20.0.0/24'; AvailabilityZone = 'us-east-1a'; Public = $true },
        @{ Name = 'portfolio-p01-public-edge-b'; Cidr = '10.20.1.0/24'; AvailabilityZone = 'us-east-1b'; Public = $true },
        @{ Name = 'portfolio-p01-public-app-a'; Cidr = '10.20.10.0/24'; AvailabilityZone = 'us-east-1a'; Public = $true },
        @{ Name = 'portfolio-p01-public-app-b'; Cidr = '10.20.11.0/24'; AvailabilityZone = 'us-east-1b'; Public = $true },
        @{ Name = 'portfolio-p01-private-db-a'; Cidr = '10.20.20.0/24'; AvailabilityZone = 'us-east-1a'; Public = $false },
        @{ Name = 'portfolio-p01-private-db-b'; Cidr = '10.20.21.0/24'; AvailabilityZone = 'us-east-1b'; Public = $false }
    )
    $subnetIds = @{}

    foreach ($definition in $subnetDefinitions) {
        $subnets = Find-Resources -Arguments @(
            'ec2', 'describe-subnets',
            '--filters', "Name=vpc-id,Values=$vpcId", "Name=tag:Name,Values=$($definition.Name)", "Name=cidr-block,Values=$($definition.Cidr)",
            '--query', 'Subnets[]'
        )

        if ($subnets.Count -gt 1) {
            throw "More than one subnet matches $($definition.Name)."
        }

        if ($subnets.Count -eq 1) {
            $subnetId = $subnets[0].SubnetId
            $mapPublicIpOnLaunch = $subnets[0].MapPublicIpOnLaunch
            Write-Host "Reusing subnet $subnetId ($($definition.Name))."
        }
        else {
            $subnet = Invoke-AwsJson -Arguments @(
                'ec2', 'create-subnet',
                '--vpc-id', $vpcId,
                '--cidr-block', $definition.Cidr,
                '--availability-zone', $definition.AvailabilityZone,
                '--tag-specifications', (Get-TagSpecification -ResourceType 'subnet' -Name $definition.Name)
            )
            $subnetId = $subnet.Subnet.SubnetId
            $mapPublicIpOnLaunch = $false
            $createdResources.Add("Subnet $subnetId ($($definition.Name))")
            Write-Host "Created subnet $subnetId ($($definition.Name))."
        }

        $subnetIds[$definition.Name] = $subnetId
        if ($definition.Public -and -not $mapPublicIpOnLaunch) {
            Invoke-AwsCommand -Arguments @('ec2', 'modify-subnet-attribute', '--subnet-id', $subnetId, '--map-public-ip-on-launch')
        }
    }

    $routeTableDefinitions = @(
        @{ Name = 'portfolio-p01-rt-public-edge'; Subnets = @('portfolio-p01-public-edge-a', 'portfolio-p01-public-edge-b'); InternetRoute = $true },
        @{ Name = 'portfolio-p01-rt-public-app'; Subnets = @('portfolio-p01-public-app-a', 'portfolio-p01-public-app-b'); InternetRoute = $true },
        @{ Name = 'portfolio-p01-rt-private-db'; Subnets = @('portfolio-p01-private-db-a', 'portfolio-p01-private-db-b'); InternetRoute = $false }
    )
    $routeTableIds = @{}

    foreach ($definition in $routeTableDefinitions) {
        $routeTables = Find-Resources -Arguments @(
            'ec2', 'describe-route-tables',
            '--filters', "Name=vpc-id,Values=$vpcId", "Name=tag:Name,Values=$($definition.Name)",
            '--query', 'RouteTables[]'
        )

        if ($routeTables.Count -gt 1) {
            throw "More than one route table matches $($definition.Name)."
        }

        if ($routeTables.Count -eq 1) {
            $routeTable = $routeTables[0]
            $routeTableId = $routeTable.RouteTableId
            Write-Host "Reusing route table $routeTableId ($($definition.Name))."
        }
        else {
            $routeTable = Invoke-AwsJson -Arguments @(
                'ec2', 'create-route-table',
                '--vpc-id', $vpcId,
                '--tag-specifications', (Get-TagSpecification -ResourceType 'route-table' -Name $definition.Name)
            )
            $routeTableId = $routeTable.RouteTable.RouteTableId
            $createdResources.Add("Route table $routeTableId ($($definition.Name))")
            Write-Host "Created route table $routeTableId ($($definition.Name))."
        }
        $routeTableIds[$definition.Name] = $routeTableId

        if ($definition.InternetRoute) {
            $routeTable = Invoke-AwsJson -Arguments @('ec2', 'describe-route-tables', '--route-table-ids', $routeTableId, '--query', 'RouteTables[0]')
            $defaultRoutes = @($routeTable.Routes | Where-Object { $_.DestinationCidrBlock -eq '0.0.0.0/0' })

            if ($defaultRoutes.Count -eq 0) {
                Invoke-AwsCommand -Arguments @(
                    'ec2', 'create-route',
                    '--route-table-id', $routeTableId,
                    '--destination-cidr-block', '0.0.0.0/0',
                    '--gateway-id', $internetGatewayId
                )
            }
            elseif ($defaultRoutes[0].GatewayId -ne $internetGatewayId) {
                throw "Route table $routeTableId has a different default route."
            }
        }

        foreach ($subnetName in $definition.Subnets) {
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
