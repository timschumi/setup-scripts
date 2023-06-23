# Show hidden files and folders
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value 1 -Type Dword

# Show file extensions of known file types
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0 -Type Dword

# Hide the search from the task bar
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -Value 0 -Type Dword

# Store the UTC time in the hardware clock
Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\TimeZoneInformation" -Name "RealTimeIsUniversal" -Value 1 -Type Dword