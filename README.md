# MySQL Cloud Backup Automation

## Objective
Automate MySQL database backups, compress the backup,
upload the archive to cloud storage, and log operations.

## Technologies
- PowerShell
- MySQL mysqldump
- 7-Zip
- AWS CLI
- Windows Task Scheduler

## Features
1. Export MySQL database.
2. Compress SQL dump into a 7z archive.
3. Upload archive to AWS S3.
4. Log backup timestamps and status.
5. Schedule daily execution.

## Execution
Open PowerShell in the project directory:

.\backup.ps1

## Cloud Setup
Configure AWS CLI credentials and create an S3 bucket
before running the backup script.

## Important
This example performs full logical backups.
True incremental backups require MySQL binary-log
capture, retention, and a tested restore procedure.
