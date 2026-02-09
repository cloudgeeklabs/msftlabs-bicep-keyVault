#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.0.0" }

BeforeAll {
    $script:ModulePath = Split-Path -Parent $PSScriptRoot
    $script:TemplatePath = Join-Path $script:ModulePath "main.bicep"
    $script:ParametersPath = Join-Path $PSScriptRoot "test.parameters.json"
}

Describe "Bicep Module: Key Vault" {
    
    Context "Static Analysis" {
        
        It "Should have valid Bicep syntax" {
            az bicep build --file $script:TemplatePath 2>&1 | Out-Null
            $LASTEXITCODE | Should -Be 0
        }
        
        It "Should generate ARM template" {
            $armTemplatePath = $script:TemplatePath -replace '\.bicep$', '.json'
            Test-Path $armTemplatePath | Should -Be $true
        }
        
        It "Should have security defaults" {
            $content = Get-Content $script:TemplatePath -Raw
            $content | Should -Match "enableRbacAuthorization.*true"
            $content | Should -Match "enablePurgeProtection.*true"
            $content | Should -Match "publicNetworkAccess.*Disabled"
        }
        
        It "Should enforce RBAC authorization" {
            $moduleContent = Get-Content (Join-Path $script:ModulePath "modules/keyVault.bicep") -Raw
            $moduleContent | Should -Match "enableRbacAuthorization"
        }
        
        It "Should have soft delete enabled" {
            $moduleContent = Get-Content (Join-Path $script:ModulePath "modules/keyVault.bicep") -Raw
            $moduleContent | Should -Match "enableSoftDelete.*true"
        }
        
        It "Should have purge protection enabled by default" {
            $moduleContent = Get-Content (Join-Path $script:ModulePath "modules/keyVault.bicep") -Raw
            $moduleContent | Should -Match "enablePurgeProtection"
        }
        
        It "Should have network ACLs configured" {
            $moduleContent = Get-Content (Join-Path $script:ModulePath "modules/keyVault.bicep") -Raw
            $moduleContent | Should -Match "networkAcls"
            $moduleContent | Should -Match "defaultAction.*Deny"
        }

        It "Should have private endpoint module" {
            $pePath = Join-Path $script:ModulePath "modules/privateEndpoint.bicep"
            Test-Path $pePath | Should -Be $true
        }

        It "Should support firewall bypass configuration" {
            $moduleContent = Get-Content (Join-Path $script:ModulePath "modules/keyVault.bicep") -Raw
            $moduleContent | Should -Match "allowTrustedMicrosoftServices"
            $moduleContent | Should -Match "AzureServices"
        }
    }
    
    Context "Template Validation" {
        
        It "Should have valid ARM template schema" {
            $armTemplatePath = $script:TemplatePath -replace '\.bicep$', '.json'
            $template = Get-Content $armTemplatePath | ConvertFrom-Json
            
            $template.'$schema' | Should -Not -BeNullOrEmpty
            $template.resources | Should -Not -BeNullOrEmpty
        }
        
        It "Should define key vault module deployment" {
            $armTemplatePath = $script:TemplatePath -replace '\.bicep$', '.json'
            $template = Get-Content $armTemplatePath | ConvertFrom-Json
            
            $moduleDeployments = $template.resources[0].PSObject.Properties | Where-Object {
                $_.Value.type -eq "Microsoft.Resources/deployments"
            }
            
            $moduleDeployments | Should -Not -BeNullOrEmpty
            $moduleDeployments.Name | Should -Contain 'keyVault'
        }
        
        It "Should have required parameters defined" {
            $armTemplatePath = $script:TemplatePath -replace '\.bicep$', '.json'
            $template = Get-Content $armTemplatePath | ConvertFrom-Json
            
            $template.parameters.workloadName | Should -Not -BeNullOrEmpty
            $template.parameters.tags | Should -Not -BeNullOrEmpty
        }
        
        It "Should have outputs defined" {
            $armTemplatePath = $script:TemplatePath -replace '\.bicep$', '.json'
            $template = Get-Content $armTemplatePath | ConvertFrom-Json
            
            $template.outputs | Should -Not -BeNullOrEmpty
            $template.outputs.resourceId | Should -Not -BeNullOrEmpty
            $template.outputs.vaultUri | Should -Not -BeNullOrEmpty
        }

        It "Should have diagnostic settings module" {
            $diagPath = Join-Path $script:ModulePath "modules/diagnostics.bicep"
            Test-Path $diagPath | Should -Be $true
        }

        It "Should have lock module" {
            $lockPath = Join-Path $script:ModulePath "modules/lock.bicep"
            Test-Path $lockPath | Should -Be $true
        }

        It "Should have RBAC module" {
            $rbacPath = Join-Path $script:ModulePath "modules/rbac.bicep"
            Test-Path $rbacPath | Should -Be $true
        }
    }
}

AfterAll {
    # Cleanup generated ARM template if exists
    $armTemplatePath = $script:TemplatePath -replace '\.bicep$', '.json'
    if (Test-Path $armTemplatePath) {
        # Optionally remove: Remove-Item $armTemplatePath -Force
    }
}
