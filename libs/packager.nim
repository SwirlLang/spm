import std/[os, httpclient, strutils, strformat, osproc, streams]
import jsony

type
    Package* = object of RootObj
        displayName*, name*, description*, author*:string
        upstreamURL*,version*, entryFile*:string
        requirements*:seq[string]
        conflics*:seq[string]

let client = newHttpClient()

proc fetchInstalledPackages*(installationDir:string,pathDelimiter:char, installedPackagesSeq: var seq[Package], installedPackageNamesSeq: var seq[string]) =
    installedPackagesSeq = @[]
    for packageDir in walkDirs(installationDir & "*"):
        let package = readFile(packageDir & pathDelimiter & "package.json").fromJson(Package)
        installedPackagesSeq.add(package)
        installedPackageNamesSeq.add(package.name)

proc fetchOnlinePackageDatabase*():tuple =
    try:
        let request = client.get("https://raw.githubusercontent.com/SwirlLang/spm/packages/packages.files")
        let remotePackageList = request.body()
        return (true, remotePackageList)
    except OSError:
        return (false, "Unable to reach github! Please check your internet connection.")

proc removeLocalPackage*(packageName,installationDir:string, pathDelimiter:char, installedPackagesSeq: var seq[Package], installedPackageNamesSeq: var seq[string]):tuple =
    let packageToRemoveIndex = installedPackageNamesSeq.find(packageName)
    if packageToRemoveIndex == -1:
        return (false, "Unable to find package '" & packageName & "', skipping it")
    
    removeDir(installationDir & pathDelimiter & packageName)
    installedPackageNamesSeq.delete(packageToRemoveIndex)
    installedPackagesSeq.delete(packageToRemoveIndex)
    return (true, "Removed '" & packageName & "'")

proc printPackageInfo*(requestedPackage:Package) =
    let
        packageRequirements = requestedPackage.requirements.join(", ")
        packageConflics = requestedPackage.conflics.join(", ")

    echo &"""
Display Name    : {requestedPackage.displayName}
Name (id)       : {requestedPackage.name}
Description     : {requestedPackage.description}
Author          : {requestedPackage.author}
URL             : {requestedPackage.upstreamURL}
version         : {requestedPackage.version}
Requires        : {packageRequirements}
Conflics with   : {packageConflics}"""

proc fetchLocalPackageDatabase*(installationDir:string, pathDelimiter:char, availablePackagesSeq: var seq[Package], availablePackageNameSeq: var seq[string]) =
    let localDatabaseFile = readFile(installationDir & "packages.files")
    try:
        availablePackagesSeq = localDatabaseFile.fromJson(seq[Package])
        availablePackageNameSeq = @[]
        for availablePackage in availablePackagesSeq:
            availablePackageNameSeq.add(availablePackage.name)
    except JsonError:
        echo "Error processing the local database, it may be corrupted, please redownload it manually"
        quit(2)


proc queryLocalPackageDatabase*(packageQuery:string, availablePackagesSeq: var seq[Package], availablePackageNameSeq: var seq[string]): tuple =
    var found = false
    for availablePackageName in availablePackageNameSeq:
        if packageQuery in availablePackageName:
            found = true
            let packageToFindIndex = availablePackageNameSeq.find(availablePackageName)
            printPackageInfo(availablePackagesSeq[packageToFindIndex])
            return (true, "")
            
    if not found:
        return (false, &"No package containing '{packageQuery}' was found in the localdatabase")

proc installPackageLocally*(packageToInstall:Package,installationDir:string,pathDelimiter:char, installedPackagesSeq: var seq[Package], installedPackageNamesSeq: var seq[string], availablePackagesSeq: var seq[Package], availablePackageNameSeq: var seq[string]):tuple =
    let gitProcess = startProcess("git", installationDir, ["clone", packageToInstall.upstreamURL, "--quiet"], options={poUsePath})
    let gitProcessOutput = gitProcess.errorStream().readAll()
    gitProcess.close()
    if gitProcessOutput != "":
        return (false, gitProcessOutput)
    
    for conflictingPackage in packageToInstall.conflics:
        if conflictingPackage in installedPackageNamesSeq:
            return (false, &"Unable to install package, '{packageToInstall} conflics with '{conflictingPackage}'")

    installedPackagesSeq.add(packageToInstall)
    installedPackageNamesSeq.add(packageToInstall.name)
    for packageDependencie in packageToInstall.requirements:
        if packageDependencie in installedPackageNamesSeq:
            continue
        let packageDependencieIndex = availablePackageNameSeq.find(packageDependencie)
        if packageDependencieIndex == -1:
            return (false, &"Requested dependency {packageDependencie} is not in the database!")

        let installationStatus = installPackageLocally(availablePackagesSeq[packageDependencieIndex], installationDir, pathDelimiter, installedPackagesSeq, installedPackageNamesSeq, availablePackagesSeq, availablePackageNameSeq)
        case installationStatus[0]
        of true: continue
        of false: return installationStatus
        
    return (true, "Installed '" & packageToInstall.name & "'")
