@{
    # Errors and warnings fail the CI; information-level hints are only reported
    Severity     = @('Error', 'Warning')

    # PSAvoidUsingWriteHost: Install-StandardApps.ps1 shows colored progress lines
    # to the technician while the same lines go to the log file. They are meant
    # for the screen, not for the pipeline, so Write-Host is the intended behavior.
    ExcludeRules = @('PSAvoidUsingWriteHost')
}
