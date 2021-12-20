#
#region FILE
#

function Import-PrefFile
{
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        [string]$Path,
        [parameter(Mandatory)]
        [string]$Format
    )

    process
    {
        if (Test-Path $Path)
        {
            switch ($Format)
            {
                'json' { Get-Content -Path $Path | ConvertFrom-Json }
                'clixml' { Import-Clixml -Path $Path }
            }
        }
    }
}

function Export-PrefFile
{
    [cmdletbinding()]
    param(
        [parameter(Mandatory = $true)]
        $Content,
        [parameter(Mandatory = $true)]
        [string]$Path,
        [parameter(Mandatory = $true)]
        [string]$Format
    )

    begin
    {
        Split-Path $Path |
            Where-Object { !(Test-Path $_) } |
            ForEach-Object { New-Item $_ -ItemType Directory -Force }
    }

    process
    {
        switch ($Format)
        {
            'json' { $Content | ConvertTo-Json | Set-Content -Path $Path -Force -Confirm:$false }
            'clixml' { $Content | Export-Clixml -Path $Path -Force -Confirm:$false }
        }
    }
}

#
#endregion
#

#
#region ENV
#

function Test-PrefVar
{
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        [string]$Name
    )

    begin
    {
        $envPath = Join-Path 'ENV:/' $Name
    }

    process
    {
        if (Get-Item $envPath) { return $true }
        else { return $false }
    }
}

function Get-PrefVar
{
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        [string]$Name,
        [string]$Delimiter
    )

    process
    {
        if (Test-PrefVar $Name)
        {
            $value = Get-Content "env:/$Name"
            if ($Delimiter)
            {
                $value = $value -split $Delimiter
            }

            return $value
        }
    }
}

#
#endregion
#

function Get-Pref
{
    [cmdletbinding()]
    param(
        [object]$InputObject,
        [string]$VarName,
        [string]$PrefFilePath,

        [ValidateSet('json', 'clixml')]
        [string]$PrefFileFormat = 'json',
        [string]$Delimiter
    )

    begin
    {
        $output = $null
        $hasInputObject = $hasEnvVar = $hasPrefFile = $false
    }

    process
    {
        if ($InputObject) { $hasInputObject = $true }
        if ($VarName)     { $hasEnvVar = Test-PrefVar $VarName }
        if ($PrefFilePath)
        {
            if (Import-PrefFile -Path $PrefFilePath -Format $PrefFileFormat)
            {
                $hasPrefFile = $true
            }
        }

        if ($hasInputObject)
        {
            $output = $InputObject
            if ($Delimiter) { $output = $output -split $Delimiter | ForEach-Object { $_.Trim() } }
        }
        elseif ($hasEnvVar)
        {
            $output = Get-PrefVar $VarName
            if ($Delimiter) { $output = $output -split $Delimiter | ForEach-Object { $_.Trim() } }
        }
        elseif ($hasPrefFile)
        {
            $output = Import-PrefFile -Path $PrefFilePath -Format $PrefFileFormat
        }
    }

    end
    {
        if ($output)
        {
            return $output
        }
    }
}

function Set-Pref
{
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Content,

        [parameter(Mandatory)]
        [string]$Path,

        [ValidateSet('json', 'clixml')]
        [string]$Format = 'json'
    )

    process
    {
        Export-PrefFile -Content $Content -Path $Path -Format $Format
    }
}
