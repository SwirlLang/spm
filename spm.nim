import utilities/[macros]
import std/[os, strformat, strutils]
importDir "libs"

var
    installedPackages:seq[Package]
    installedPackageNames:seq[string]   # Use to check if a single package exits given its name (id)
    availablePackages:seq[Package]      # All packages in the local database
    availablePackageNames:seq[string]   # Use to check if a single package is available given its name (id)

proc exit() {.noconv.} =
    quit(0)

proc init() =
    registerHelp(["-h", "--help"], "Show this page and quits")
    registerHelp(["i", "install  [ARGS]"], "Install the following package(s)")
    registerHelp(["U", "update"], "Updates local packages list")
    registerHelp(["r", "remove   [ARGS]"], "Remove the following package(s)")
    registerHelp(["l", "list"], "Lists all installed packages and their versions")
    registerHelp(["info", "--info"], "Lists all informations on an installed package")
    registerHelp(["s", "search    [ARGS]"], "Look through the database for package(s) matching the search query")
    registerHelp(["I", "init"], "Starts the interactive package creation tool")
    fetchInstalledPackages(installPath, pathSeparator, installedPackages, installedPackageNames)
    fetchLocalPackageDatabase(installPath, pathSeparator, availablePackages, availablePackageNames)

proc processCLIArguments() =
    var discardNext = false
    for i in 1..os.paramCount():
        if discardNext:
            discardNext = false
            continue
        
        let arg = os.paramStr(i)
        case arg
        of "-h", "--help", "help":
            echo helpMenu
            quit(0)
        
        of "i", "-i", "install", "--install":

            if findExe("git", true, [""]) == "":
                error "Git was not found in PATH, please make sure you have git installed"

            if paramCount() < i+1:
                error "No package(s) provided"
            
            for i in (i+1)..paramCount():
                let packageToInstall = paramStr(i)
                let packageToInstallIndex = availablePackageNames.find(packageToInstall)

                if packageToInstallIndex == -1:
                    error "Requested package is not in the database!"
                
                if packageToInstall in installedPackageNames:
                    warn "Requested package is already installed!"
                    let doRemove = ask "Would you like to un install it first ? (y/n)"
                    if doRemove.toLowerAscii() == "y" or doRemove.toLowerAscii() ==  "yes":
                        discard removeLocalPackage(packageToInstall, installPath, pathSeparator, installedPackages, installedPackageNames)
                    else:
                        quit(0)

                
                let installationStatus = installPackageLocally(availablePackages[packageToInstallIndex], installPath, pathSeparator, installedPackages, installedPackageNames, availablePackages, availablePackageNames)
                case installationStatus[0]
                of false:
                    error installationStatus[1]
                of true:
                    success installationStatus[1]
                
            
            quit(0)
                
        of "r", "-r", "remove", "--remove":
            if paramCount() < i+1:
                error "No package(s) provided"
            
            for i in (i+1)..paramCount():
                let packageToRemove = paramStr(i)
                let removeStatus = removeLocalPackage(packageToRemove, installPath, pathSeparator, installedPackages, installedPackageNames)

                case removeStatus[0]
                of false:
                    warn removeStatus[1]
                of true:
                    success removeStatus[1]
            
            quit(0)
        
        of "l", "-l", "list", "--list":
            for package in installedPackages:
                info &"{green}{package.name}{dft} version {green}{package.version}{dft} by {red}{package.author}{dft}"
        
        of "info", "--info":
            discardNext = true
            if paramCount() < i+1:
                error "Missing package name"
            
            let wantedPackage = paramStr(i+1)

            let wantedPackageIndex = installedPackageNames.find(wantedPackage)

            if wantedPackageIndex == -1:
                error &"Package {wantedPackage} is not installed !"
            
            let package = installedPackages[wantedPackageIndex]
            printPackageInfo(package)
        
        of "U", "-U", "update", "--update":
            if not os.dirExists(installPath): os.createDir(installPath)
            let onlinePackageDatabase = fetchOnlinePackageDatabase()
            
            let fetchStatus = onlinePackageDatabase[0]

            case fetchStatus
            of true:
                writeFile(installPath & pathSeparator & "packages.files", onlinePackageDatabase[1])
                success "Updated local package database!"
            of false:
                error onlinePackageDatabase[1]
        
        of "s", "-s", "search", "--search":
            discardNext = true
            if paramCount() < i+1:
                    error "No package(s) provided"
            
            for i in (i+1)..paramCount():
                let packageQuery = paramstr(i)
                let queryResults = queryLocalPackageDatabase(packageQuery, availablePackages, availablePackageNames)

                if not queryResults[0]:
                    warn queryResults[1]

                
        
        of "I", "-I", "init", "--init":
            error "Not implemented yet"
        
        else:
            error "Unknow option: " & arg
            
setControlCHook(exit)

when not defined(ssl):
    {.fatal: "SSL is required to compile SPM".}

when defined(windows):
    {.warning: "SPM wasn't tested under a windows environment, please report any issues or consider switching to a better operating system such as GNU/Linux, BSD or MAC_OS".}

when isMainModule:
    init()
    if paramCount() < 1:
        error "No argument provided, please check the help using 'spm --help'" 
    processCLIArguments()