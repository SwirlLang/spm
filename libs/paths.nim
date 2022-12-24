import os

when defined(windows):
    const pathSeparator* = '\\'
    let   installPath*   = os.getEnv("APPDATA") & "\\local\\spm\\packages\\"
    let   basePath*   = os.getEnv("APPDATA") & "\\local\\spm\\"

else:
    const pathSeparator* = '/'
    let   installPath*   = os.getEnv("HOME") & "/.spm/packages/"
    let   basePath*   = os.getEnv("HOME") & "/.spm/"