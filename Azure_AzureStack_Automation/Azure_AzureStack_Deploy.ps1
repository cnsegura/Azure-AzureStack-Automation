# Run this command to add your Azure/Azure Stack account if you have not already done so
Add-AzureRmAccount

# Gets the subscription ID that we want to use and sets it as the current context.
Get-AzureRmSubscription -SubscriptionName "Visual Studio Enterprise" | Set-AzureRmContext

# Set deployment location and resource group variables
$locName = "West US" # Azure (change to the region of your choice)
# $locName = "local" # Azure Stack
$rgName = "iottest1"
$deployName = "iottestdeploy"
$scriptRoot = "C:\Users\chrisseg\Source\Repos\Azure_AzureStack_Automation\Azure_AzureStack_Automation"
$templatePath = "$scriptRoot\azuredeploy.json"

# Create Resource Group
New-AzureRmResourceGroup -Name $rgName -Location $locName

# Deployment parameters
$deployParam = @{
	"adminUsername" = "localAdmin";
	"adminPassword" = "P@ssw0rd1";
	"deploymentEnv" = "Azure"; # Deploy to Azure
	# "deploymentEnv" = "AzureStack"; # Change for Azure Stack

}

# Deploy Template
New-AzureRmResourceGroupDeployment `
	-Name $deployName `
	-ResourceGroupName $rgName `
	-Mode Complete `
	-Force `
	-TemplateFile $templatePath `
	-TemplateParameterObject $deployParam