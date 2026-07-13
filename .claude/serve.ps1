$dir = Split-Path -Parent $MyInvocation.MyCommand.Path | Split-Path -Parent
$port = 8765
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")
$listener.Start()
Write-Host "Listening on $port, serving $dir"
while ($listener.IsListening) {
    $context = $listener.GetContext()
    $req = $context.Request
    $res = $context.Response
    $path = [System.Uri]::UnescapeDataString($req.Url.LocalPath.TrimStart('/'))
    if ($path -eq "") { $path = "index.html" }
    $filePath = Join-Path $dir $path
    if (Test-Path $filePath -PathType Leaf) {
        $bytes = [System.IO.File]::ReadAllBytes($filePath)
        $ext = [System.IO.Path]::GetExtension($filePath).ToLower()
        $ct = switch ($ext) {
            ".html" { "text/html; charset=utf-8" }
            ".ttf"  { "font/ttf" }
            ".js"   { "application/javascript" }
            default { "application/octet-stream" }
        }
        $res.ContentType = $ct
        $res.ContentLength64 = $bytes.LongLength
        $chunkSize = 65536
        $offset = 0
        while ($offset -lt $bytes.Length) {
            $len = [Math]::Min($chunkSize, $bytes.Length - $offset)
            $res.OutputStream.Write($bytes, $offset, $len)
            $offset += $len
        }
    } else {
        $res.StatusCode = 404
    }
    $res.OutputStream.Close()
}
