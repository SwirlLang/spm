task build, "Builds a debug binary":
    switch("d","ssl")
    switch("d", "debug")
    setcommand("c")

task release, "Builds an optimized binary":
    switch("d","ssl")
    switch("d", "release")
    switch("d","danger")
    switch("opt", "speed")
    switch("d", "strip")
    setcommand("c")