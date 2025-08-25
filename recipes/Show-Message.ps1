#========================================================================
# Created by:   Shane Cribbs    
#========================================================================

# Load the Windows.Forms assembly for the notification windows
[void][reflection.assembly]::Load("System.Windows.Forms, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")

[void][System.Windows.Forms.MessageBox]::Show("This is a very important message. `nThis is the second line.","Important Title")
