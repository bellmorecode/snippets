winrm quickconfig -quiet

Enable-WSManCredSSP -Role Client -DelegateComputer * -Force