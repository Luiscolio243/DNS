function Get-FTPList {
    param (
        [string]$ftpServer = "192.168.1.2",
        [string]$ftpUser = "windows",
        [string]$ftpPass = "1234"
    )
    try {
        $ftpPath = "/"
        $credentials = New-Object System.Net.NetworkCredential($ftpUser, $ftpPass)
        $request = [System.Net.FtpWebRequest]::Create("ftp://$ftpServer$ftpPath")
        $request.Credentials = $credentials
        $request.Method = [System.Net.WebRequestMethods+Ftp]::ListDirectory
        $request.UseBinary = $true
        $request.UsePassive = $true
        $response = $request.GetResponse()
        $reader = New-Object System.IO.StreamReader $response.GetResponseStream()
        $fileList = $reader.ReadToEnd() -split "`n"
        $reader.Close()
        $response.Close()
        return $fileList
    } catch {
        Write-Host "Error al conectar con el FTP: $_" -ForegroundColor Red
        return @()
    }
}

function listar_http {
    param (
        [string]$ftpServer,
        [string]$ftpUser,
        [string]$ftpPass,
        [string]$directory
    )
    $baseFtpPath = "ftp://$ftpServer/"
    $ftpPath = "$baseFtpPath$directory"

    $credentials = New-Object System.Net.NetworkCredential($ftpUser, $ftpPass)

    try {
        $request = [System.Net.FtpWebRequest]::Create($ftpPath)
        $request.Credentials = $credentials
        $request.Method = [System.Net.WebRequestMethods+Ftp]::ListDirectory
        $request.UseBinary = $true
        $request.UsePassive = $true
        $response = $request.GetResponse()
        $reader = New-Object System.IO.StreamReader $response.GetResponseStream()
        $fileList = $reader.ReadToEnd() -split "`n"
        $reader.Close()
        $response.Close()
        return $fileList | Where-Object { $_.Trim() -ne "" }
    }
    catch {
        Write-Host "Error al acceder a '$directory': $_" -ForegroundColor Red
        return @()
    }
}
Export-ModuleMember -Function Get-FTPList, listar_http