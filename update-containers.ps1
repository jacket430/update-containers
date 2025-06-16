# Updates Docker containers in ./containers directory

# Function to get actual container name from compose service name
function Get-ContainerName {
    param (
        [string]$ServiceName
    )
    
    $containers = docker ps --format "{{.Names}}"
    
    # Try exact match first
    if ($containers -contains $ServiceName) {
        return $ServiceName
    }
    
    # Try common name variations
    $variations = @(
        $ServiceName.Replace("-", ""),  # No hyphens
        $ServiceName.Replace("-", "_"), # Hyphens to underscores
        $ServiceName.ToLower()          # Lowercase
    )
    
    foreach ($variation in $variations) {
        if ($containers -contains $variation) {
            return $variation
        }
    }
    
    # If no match found, return the original service name
    return $ServiceName
}

# Function to check if container needs update
function Test-ContainerUpdate {
    param (
        [string]$ContainerName
    )
    
    try {
        docker compose pull
        
        # Compare current and latest image IDs
        $currentImageId = docker inspect --format='{{.Id}}' $ContainerName
        $latestImageId = docker inspect --format='{{.Id}}' $(docker compose images -q $ContainerName)
        
        return $currentImageId -ne $latestImageId
    }
    catch {
        Write-Host "Error checking updates for $ContainerName : $_"
        return $false
    }
}

# Main script execution
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
            # Return to original directory
            Pop-Location
        }
    }
}
catch {
    Write-Host "Script error: $_"
    exit 1
}

Write-Host "`nContainer update process completed."
