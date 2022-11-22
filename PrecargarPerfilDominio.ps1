# Script que es capaz de precargar un usuario del dominio, crear el UID y las claves del registro de forma correcta
# Esto puede ser util cuando unimos a un equipo al dominio para configurarle por CLI los accesos a recursos compartidos y/o impresoras
# Entre algunas de las posibilidades

# Pedimos por teclado el nombre de la empresa (dominio) del que vamos a pedir el usuario, si el dominio es abc.local, con abc nos es suficiente
# Pedimos por teclado el nombre del usuario, tiene que ser un nombre de usuario válido 

$Empresa = Read-Host -Prompt 'Nombre de la empresa a configurar'
$Usuario = Read-Host -Prompt 'Nombre del usuario a configurar'

function Add-NativeMethods
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param($typeName = 'NativeMethods')
 
    $nativeMethodsCode = $script:nativeMethods | ForEach-Object { "
        [DllImport(`"$($_.Dll)`")]
        public static extern $($_.Signature);
    " }
 
    Add-Type @"
        using System;
        using System.Text;
        using System.Runtime.InteropServices;
        public static class $typeName {
            $nativeMethodsCode
        }
"@
}

function Register-NativeMethod
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string]$dll,
 
        # Param2 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        [string]
        $methodSignature
    )
 
    $script:nativeMethods += [PSCustomObject]@{ Dll = $dll; Signature = $methodSignature; }
}

Register-NativeMethod "userenv.dll" "int CreateProfile([MarshalAs(UnmanagedType.LPWStr)] string pszUserSid,`
[MarshalAs(UnmanagedType.LPWStr)] string pszUserName,`
[Out][MarshalAs(UnmanagedType.LPWStr)] StringBuilder pszProfilePath, uint cchProfilePath)";

$methodname = 'UserEnvCP2'
Add-NativeMethods -typeName $methodname;

$sb = new-object System.Text.StringBuilder(260);
$pathLen = $sb.Capacity;

$objUser = New-Object System.Security.Principal.NTAccount($Empresa, $Usuario)
$strSID = $objUser.Translate([System.Security.Principal.SecurityIdentifier])
$SID = $strSID.Value

CreateProfile($SID, $Username, $sb, $pathLen)
$result = [UserEnvCP2]::CreateProfile($SID, $Usuario, $sb, $pathLen)
