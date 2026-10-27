$ErrorActionPreference = "Stop"

. "$PSScriptRoot\config.ps1"

# Create folders if they do not exist.
New-Item -ItemType Directory -Force -Path $BackupDir, $LogDir |
    Out-Null

function Write-BackupLog {
    param([string]$Message)

    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$Timestamp | $Message" |
        Out-File -FilePath $LogFile -Append -Encoding utf8

    Write-Host "$Timestamp | $Message"
}

$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$DumpFile = Join-Path $BackupDir "${Database}_${Timestamp}.sql"
$ArchiveFile = "$DumpFile.7z"

try {
    Write-BackupLog "Starting backup for database: $Database"

    # Verify required programs.
    if (-not (Test-Path $MySQLDump)) {
        throw "mysqldump.exe not found: $MySQLDump"
    }

    if (-not (Test-Path $SevenZip)) {
        throw "7z.exe not found: $SevenZip"
    }

    # Supply the password through MYSQL_PWD for this process.
    # Prefer a protected MySQL option file for production environments.
    $SecurePassword = Read-Host "Enter MySQL password" -AsSecureString
    $Credential = [System.Net.NetworkCredential]::new("", $SecurePassword)
    $env:MYSQL_PWD = $Credential.Password

    try {
        & $MySQLDump `
            "--host=$DBHost" `
            "--port=$DBPort" `
            "--user=$DBUser" `
            "--single-transaction" `
            "--routines" `
            "--triggers" `
            "--events" `
            "--databases" `
            $Database `
            "--result-file=$DumpFile"

        if ($LASTEXITCODE -ne 0) {
            throw "mysqldump failed with exit code $LASTEXITCODE"
        }
    }
    finally {
        Remove-Item Env:\MYSQL_PWD -ErrorAction SilentlyContinue
    }

    if (-not (Test-Path $DumpFile) -or
        (Get-Item $DumpFile).Length -eq 0) {
        throw "Backup file is missing or empty."
    }

    Write-BackupLog "Database export completed: $DumpFile"

    # Compress the SQL dump.
    & $SevenZip a -t7z $ArchiveFile $DumpFile

    if ($LASTEXITCODE -ne 0) {
        throw "7-Zip compression failed with exit code $LASTEXITCODE"
    }

    if (-not (Test-Path $ArchiveFile) -or
        (Get-Item $ArchiveFile).Length -eq 0) {
        throw "Compressed archive is missing or empty."
    }

    Write-BackupLog "Compression completed: $ArchiveFile"

    # Upload the archive to AWS S3.
    if ($CloudProvider -eq "AWS") {
        $Destination = "s3://$S3Bucket/$S3Prefix/"

        & aws s3 cp $ArchiveFile $Destination

        if ($LASTEXITCODE -ne 0) {
            throw "AWS S3 upload failed with exit code $LASTEXITCODE"
        }

        Write-BackupLog "Cloud upload completed: $Destination"
    }
    else {
        throw "Unsupported cloud provider configured: $CloudProvider"
    }

    # Delete the uncompressed dump after successful upload.
    Remove-Item $DumpFile -Force

    Write-BackupLog "SUCCESS: Backup completed: $ArchiveFile"
}
catch {
    Write-BackupLog "ERROR: $($_.Exception.Message)"
    exit 1
}
finally {
    Remove-Item Env:\MYSQL_PWD -ErrorAction SilentlyContinue
}