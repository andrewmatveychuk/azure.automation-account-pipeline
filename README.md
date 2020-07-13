# azure.automation-account-pipeline

A sample pipeline for managing PowerShell assets in an [Azure Automation](https://docs.microsoft.com/en-us/azure/automation/) account.

Before starting to work with this sample project, I suggest reading the information in the following blog post:

* [A sample CI/CD pipeline for Azure Automation account](https://andrewmatveychuk.com/a-sample-ci-cd-pipeline-for-azure-automation-account)

Also, you might refer to the following posts regarding the building, publishing and accessing PowerShell modules during deployment:

* [A sample CI/CD pipeline for PowerShell module](https://andrewmatveychuk.com/a-sample-ci-cd-pipeline-for-powershell-module/)
* [How to access private PowerShell repository from Azure pipeline](https://andrewmatveychuk.com/how-to-access-private-powershell-repository-from-azure-pipeline/)

## Build Status

[![Build Status](https://dev.azure.com/matveychuk/azure.automation-account-pipeline/_apis/build/status/andrewmatveychuk.azure.automation-account-pipeline?branchName=master)](https://dev.azure.com/matveychuk/azure.automation-account-pipeline/_build/latest?definitionId=5&branchName=master)

## Introduction

This repository contains the source code for a sample Azure DevOps pipeline that deploys PowerShell assets such as runbooks, modules, and DSC configurations into an [Azure Automation](https://docs.microsoft.com/en-us/azure/automation/) account.

## Getting Started

Clone the repository to your local machine and look for project artifacts in the following locations:

* [dsc-configurations](https://github.com/andrewmatveychuk/azure.automation-account-pipeline/tree/master/dsc-configurations) - source code for a sample PowerShell DSC configuration
* [runbooks](https://github.com/andrewmatveychuk/azure.automation-account-pipeline/tree/master/runbooks) - source code for a sample PowerShell runbook
* *.depend.psd1 files in corresponding folders - managing dependencies with [PSDepend](https://github.com/RamblingCookieMonster/PSDepend)
* *.build.ps1 - build configuration for [InvokeBuild](https://github.com/nightroman/Invoke-Build)
* *.deploy.ps1 - deployment configuration for [PSDeploy](https://github.com/RamblingCookieMonster/PSDeploy)

## Build and Test

This project uses [InvokeBuild](https://github.com/nightroman/Invoke-Build) module to automate build tasks such as running test, performing static code analysis, building the deployment artifact, etc.

* To build the project, run: Invoke-Build
* To see other build options: Invoke-Build ?

For deployment, the project uses [PSDeploy](https://github.com/RamblingCookieMonster/PSDeploy) module to simplify the deployment process and handle the dependency between the deployment artifacts.
To get more information on how it works, please refer to [PSDeploy docs](https://psdeploy.readthedocs.io/).

To deploy from a local source:

1. Create a target Azure Automation account
2. Update the account name and its resource group name in [azure.automation-account-pipeline.deploy.ps1](https://github.com/andrewmatveychuk/azure.automation-account-pipeline/blob/master/azure.automation-account-pipeline.deploy.ps1)
3. In a PowerShell session, connect to your Azure environment (Connect-AzAccount)
4. Run 'Invoke-Build Deploy'

## Suggested tools

* Editing - [Visual Studio Code](https://github.com/Microsoft/vscode)
* Runtime - [PowerShell Core](https://github.com/powershell)
* Build tool - [InvokeBuild](https://github.com/nightroman/Invoke-Build)
* Dependency management - [PSDepend](https://github.com/RamblingCookieMonster/PSDepend)
* Testing - [Pester](https://github.com/Pester/Pester)
* Code coverage - [Pester](https://pester.dev/docs/usage/code-coverage)
* Static code analysis - [PSScriptAnalyzer](https://github.com/PowerShell/PSScriptAnalyzer)
* Deployment tool - [PSDeploy](https://github.com/RamblingCookieMonster/PSDeploy)
