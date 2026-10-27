# MySQL settings
$MySQLDump = "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysqldump.exe"
$Database  = "load_balancer_demo"
$DBHost    = "127.0.0.1"
$DBPort    = 3306
$DBUser    = "backup_user"

# Install 7-Zip and update this path if necessary.
$SevenZip = "C:\Program Files\7-Zip\7z.exe"

# Backup folders
$ProjectRoot = $PSScriptRoot
$BackupDir   = Join-Path $ProjectRoot "backups"
$LogDir      = Join-Path $ProjectRoot "logs"
$LogFile     = Join-Path $LogDir "backup.log"

# AWS S3 settings
$CloudProvider = "AWS"
$S3Bucket      = "replace-with-your-s3-bucket"
$S3Prefix      = "mysql-backups"

# AWS credentials should be configured securely using AWS CLI.
# Do not place secret access keys in this file.