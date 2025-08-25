@ECHO OFF

Echo "Setting the service account to svc_spworkflow"
sc.exe config "SPUserCodeV4" obj= "FIRM\svc_spworkflow" password="*******"
sc.exe config "SPTimerV4" obj= "FIRM\svc_spworkflow" password="******"

@ECHO ON

