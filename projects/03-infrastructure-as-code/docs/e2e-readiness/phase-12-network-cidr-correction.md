# E2E Readiness — Phase 12: network CIDR correction

## Finding

The first Foundation plan correctly exposed a semantic error missed by static
validation: the E2E root supplied VPC `10.30.0.0/16`, while the shared network
module still contained literal `10.20.x.0/24` subnet CIDRs from the lab
reconstruction. Those CIDRs are outside the E2E VPC and an apply would fail.

No resource was created: the command was a Terraform plan only.

## Correction

The network module now derives subnet CIDRs from the required `/16`
`vpc_cidr` input using `cidrsubnet`. The established layout remains exactly
the same by subnet index: Edge 0/1, Application 10/11, and Database 20/21.

This preserves the Project 03 lab representation (`10.20.x.0/24`) while
creating the intended isolated E2E ranges (`10.30.x.0/24`). The module rejects
non-/16 VPC inputs so this contract cannot silently drift.

## Required revalidation

After local Terraform validation, rerun the Foundation plan using the same
transient inputs. The plan must show only `10.30.x.0/24` subnets before any
apply is considered.
