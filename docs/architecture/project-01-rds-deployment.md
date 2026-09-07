# Project 01 — RDS PostgreSQL deployment

## Scope

This document records the first development database for the Task Manager. It is intentionally small, private and temporary; the application still uses an in-memory store until its database integration phase.

## Implemented components

- DB subnet group: `portfolio-p01-db-subnet-group`, using the two private database subnets in separate Availability Zones.
- RDS identifier: `portfolio-p01-postgres`.
- Engine: PostgreSQL 18.3 on `db.t3.micro`.
- Storage: 20 GiB GP3, encrypted with the AWS-managed RDS key.
- Availability: Single-AZ; Multi-AZ is deliberately out of scope for this development deployment.
- Network: public accessibility is disabled. The database Security Group permits TCP 5432 only from the application Security Group.
- Backups: automated backups retained for one day.
- Instance access: no SSH path exists. The later application instances will use Session Manager and retrieve their password from Parameter Store.

## Secret handling

The master password is generated with a cryptographically secure random generator during provisioning. It is stored as a `SecureString` at:

```text
/portfolio/project-01/database/password
```

It is not printed, committed, placed in a `.env` file or embedded in application code. The EC2 role is limited to `ssm:GetParameter` on that exact parameter only.

## Connection boundary

```text
Internet -> ALB security group -> application security group -> database security group (5432)
```

There is no public route from the Internet to PostgreSQL. At this stage no EC2 application instance has been deployed, so no client is yet connected to the database.

## Operational constraints

- Deletion protection is disabled only because this is a short-lived development resource.
- Stopping RDS does not eliminate storage and backup usage, and AWS automatically restarts a stopped RDS instance after seven days.
- Any deletion, final snapshot decision or extension beyond the initial three-day review window requires explicit approval.
