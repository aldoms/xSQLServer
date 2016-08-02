$script:DSCModuleName      = 'xSQLServer'
$script:DSCResourceName    = 'xSQLServerPermission'

#region HEADER

# Unit Test Template Version: 1.1.0
[String] $script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Unit 

#endregion HEADER

# Begin Testing
try
{
    #region Pester Test Initialization

    # Loading mocked classes
    Add-Type -Path (Join-Path -Path $script:moduleRoot -ChildPath 'Tests\Unit\Stubs\SMO.cs')

    $nodeName = 'localhost'
    $instanceName = 'DEFAULT'
    $principal = 'COMPANY\SqlServiceAcct'
    $permission = @( 'AlterAnyAvailabilityGroup','ViewServerState' )

    #endregion Pester Test Initialization

    $testParameters = @{
        InstanceName = $instanceName
        NodeName = $nodeName
        Principal = $principal
        Permission = $permission
    }

    Describe "$($script:DSCResourceName)\Get-TargetResource" {
        Context 'When the system is not in the desired state' {
            BeforeAll {
                Mock -CommandName Get-SQLPSInstance -MockWith { 
                    $mockObjectSmoServer = New-Object Microsoft.SqlServer.Management.Smo.Server -ArgumentList @( $false )
                    $mockObjectSmoServer.Name = "$nodeName\$instanceName"
                    $mockObjectSmoServer.DisplayName = $instanceName
                    $mockObjectSmoServer.InstanceName = $instanceName
                    $mockObjectSmoServer.IsHadrEnabled = $False
                    $mockObjectSmoServer.MockGranteeName = $principal

                    return $mockObjectSmoServer
                } -ModuleName $script:DSCResourceName -Verifiable
            }
    
            $result = Get-TargetResource @testParameters

            It 'Should return the desired state as Absent' {
                $result.Ensure | Should Be 'Absent'
            }

            It 'Should return the node name passed as parameter' {
                $result.NodeName | Should Be $nodeName
            }

            It 'Should return the instance name passed as parameter' {
                $result.InstanceName | Should Be $instanceName
            }

            It 'Should return the principal passed as parameter' {
                $result.Principal | Should Be $principal
            }

            It 'Should not return any permissions' {
                $result.Permission | Should Be $null
            }

            It 'Should call the mock function Get-SQLPSInstance' {
                 Assert-MockCalled Get-SQLPSInstance -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope Context 
            }
        }
    
        Context 'When the system is in the desired state' {
            BeforeAll {
                Mock -CommandName Get-SQLPSInstance -MockWith { 
                    $mockObjectSmoServer = New-Object Microsoft.SqlServer.Management.Smo.Server -ArgumentList @( $true )
                    $mockObjectSmoServer.Name = "$nodeName\$instanceName"
                    $mockObjectSmoServer.DisplayName = $instanceName
                    $mockObjectSmoServer.InstanceName = $instanceName
                    $mockObjectSmoServer.IsHadrEnabled = $False
                    $mockObjectSmoServer.MockGranteeName = $principal

                    return $mockObjectSmoServer
                } -ModuleName $script:DSCResourceName -Verifiable
            }

            $result = Get-TargetResource @testParameters

            It 'Should return the desired state as present' {
                $result.Ensure | Should Be 'Present'
            }

            It 'Should return the node name passed as parameter' {
                $result.NodeName | Should Be $nodeName
            }

            It 'Should return the instance name passed as parameter' {
                $result.InstanceName | Should Be $instanceName
            }

            It 'Should return the principal passed as parameter' {
                $result.Principal | Should Be $principal
            }

            It 'Should return the permissions passed as parameter' {
                foreach ($currentPermission in $permission) {
                    if( $result.Permission -ccontains $currentPermission ) {
                        $permissionState = $true 
                    } else {
                        $permissionState = $false
                        break
                    }
                } 
                
                $permissionState | Should Be $true
            }

            It 'Should call the mock function Get-SQLPSInstance' {
                 Assert-MockCalled Get-SQLPSInstance -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope Context 
            }
        }

        Assert-VerifiableMocks
    }

    # This is added to the hash table after the Get method is tested, because Get method doesn't have Ensure as a parameter. 
    $testParameters += @{
        Ensure = 'Present'
    }

    Describe "$($script:DSCResourceName)\Test-TargetResource" {
        Context 'When the system is not in the desired state' {
            BeforeAll {
                Mock -CommandName Get-SQLPSInstance -MockWith { 
                    $mockObjectSmoServer = New-Object Microsoft.SqlServer.Management.Smo.Server -ArgumentList @( $false )
                    $mockObjectSmoServer.Name = "$nodeName\$instanceName"
                    $mockObjectSmoServer.DisplayName = $instanceName
                    $mockObjectSmoServer.InstanceName = $instanceName
                    $mockObjectSmoServer.IsHadrEnabled = $False
                    $mockObjectSmoServer.MockGranteeName = $principal

                    return $mockObjectSmoServer
                } -ModuleName $script:DSCResourceName -Verifiable
            }

            It 'Should return that desired state is absent' {
                $result = Test-TargetResource @testParameters
                $result | Should Be $false
            }

            It 'Should call the mock function Get-SQLPSInstance' {
                 Assert-MockCalled Get-SQLPSInstance -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope Context 
            }
        }

        Context 'When the system is in the desired state' {
            BeforeAll {
                Mock -CommandName Get-SQLPSInstance -MockWith { 
                    $mockObjectSmoServer = New-Object Microsoft.SqlServer.Management.Smo.Server -ArgumentList @( $true )
                    $mockObjectSmoServer.Name = "$nodeName\$instanceName"
                    $mockObjectSmoServer.DisplayName = $instanceName
                    $mockObjectSmoServer.InstanceName = $instanceName
                    $mockObjectSmoServer.IsHadrEnabled = $False
                    $mockObjectSmoServer.MockGranteeName = $principal

                    return $mockObjectSmoServer
                } -ModuleName $script:DSCResourceName -Verifiable
            }

            It 'Should return that desired state is present' {
                $result = Test-TargetResource @testParameters
                $result | Should Be $true
            }

            It 'Should call the mock function Get-SQLPSInstance' {
                 Assert-MockCalled Get-SQLPSInstance -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope Context 
            }
        }

        Assert-VerifiableMocks
    }

    Describe "$($script:DSCResourceName)\Set-TargetResource" {
        Context 'When the system is not in the desired state' {
            BeforeAll {
                Mock -CommandName Get-SQLPSInstance -MockWith { 
                    $mockObjectSmoServer = New-Object Microsoft.SqlServer.Management.Smo.Server -ArgumentList @( $false )
                    $mockObjectSmoServer.Name = "$nodeName\$instanceName"
                    $mockObjectSmoServer.DisplayName = $instanceName
                    $mockObjectSmoServer.InstanceName = $instanceName
                    $mockObjectSmoServer.IsHadrEnabled = $False
                    $mockObjectSmoServer.MockGranteeName = $principal

                    return $mockObjectSmoServer
                } -ModuleName $script:DSCResourceName -Verifiable
            }

            It 'Should not throw an error' {
                { Set-TargetResource @testParameters } | Should Not Throw
            }

            It 'Should call the mock function Get-SQLPSInstance twice' {
                 Assert-MockCalled Get-SQLPSInstance -Exactly -Times 2 -ModuleName $script:DSCResourceName -Scope Context 
            }
        }

        Context 'When the system is in the desired state' {
            BeforeAll {
                Mock -CommandName Get-SQLPSInstance -MockWith { 
                    $mockObjectSmoServer = New-Object Microsoft.SqlServer.Management.Smo.Server -ArgumentList @( $true )
                    $mockObjectSmoServer.Name = "$nodeName\$instanceName"
                    $mockObjectSmoServer.DisplayName = $instanceName
                    $mockObjectSmoServer.InstanceName = $instanceName
                    $mockObjectSmoServer.IsHadrEnabled = $False
                    $mockObjectSmoServer.MockGranteeName = $principal

                    return $mockObjectSmoServer
                } -ModuleName $script:DSCResourceName -Verifiable
            }

            It 'Should not throw an error' {
                { Set-TargetResource @testParameters } | Should Not Throw
            }

            It 'Should call the mock function Get-SQLPSInstance' {
                 Assert-MockCalled Get-SQLPSInstance -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope Context 
            }
        }

        Assert-VerifiableMocks
    }
}
finally
{
    #region FOOTER

    Restore-TestEnvironment -TestEnvironment $TestEnvironment 

    #endregion

    Remove-module $script:DSCResourceName -Force
}
