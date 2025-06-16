# Updates Docker containers in ./containers directory

# Function to get actual container name from compose service name
function Get-ContainerName {
    param (
        [string]$ServiceName
    )
    
    $containers = docker ps --format "{{.Names}}"
    
    if ($containers -contains $ServiceName) {
        return $ServiceName
    }
    
    $variations = @(
        $ServiceName.Replace("-", ""),
        $ServiceName.Replace("-", "_"),
        $ServiceName.ToLower()
    )
    
    foreach ($variation in $variations) {
        if ($containers -contains $variation) {
            return $variation
        }
    }
    return $ServiceName
}

# Check if container needs update
function Test-ContainerUpdate {
    param (
        [string]$ContainerName
    )
    try {
        $containerImageId = docker inspect --format='{{.Image}}' $ContainerName
        
        $containerImage = docker inspect --format='{{.Config.Image}}' $ContainerName
        
        docker pull $containerImage 2>&1 | Out-Null
        
        $latestImageId = docker image inspect --format='{{.Id}}' $containerImage
        
        if ($containerImageId -and $latestImageId) {
            $containerImageId = $containerImageId -replace '^sha256:', ''
            $latestImageId = $latestImageId -replace '^sha256:', ''
            
            return $containerImageId -ne $latestImageId
        }
        
        $imageUpdated = $LASTEXITCODE -eq 0
        return $imageUpdated
    }
    catch {
        Write-Host "Error checking updates for $ContainerName : $_"
        return $false
    }
}

# Main
try {
    $containerDirs = Get-ChildItem -Path ".\containers" -Directory
    
    foreach ($dir in $containerDirs) {
        Write-Host "`nProcessing container in $($dir.Name)..."
        
        Push-Location $dir.FullName
        
        try {
            $serviceName = $dir.Name
            $containerName = Get-ContainerName -ServiceName $serviceName
            
            Write-Host "Checking updates for $containerName..."
            
            $needsUpdate = Test-ContainerUpdate -ContainerName $containerName
            
            if ($needsUpdate) {
                Write-Host "Update available for $containerName. Updating..."
                docker compose down
                docker compose up -d --force-recreate
                Write-Host "Successfully updated $containerName"
            }
            else {
                Write-Host "No updates available for $containerName"
            }
        }
        catch {
            Write-Host "Error processing $($dir.Name): $_"
        }
        finally {
            Pop-Location
        }
    }
}
catch {
    Write-Host "Script error: $_"
    exit 1
}

Write-Host "`nContainer update process completed."
