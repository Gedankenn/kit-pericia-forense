# Perfil EXEMPLO generico para o kit publico.
# Copie e ajuste para o objeto da pericia; nao versione perfis de casos reais.
@{
  Nome = 'exemplo_generico'
  # Regex de fabricantes/produtos de interesse na coleta (Uninstall, pastas, hosts...)
  Fabricantes = 'Autodesk|AutoCAD|Inventor|Revit|3ds ?Max|\bMaya\b|Civil ?3D|Navisworks|Fusion ?360|Corel|PHOTO-PAINT|PaintShop|VideoStudio|Pinnacle Studio|WinZip|Parallels|MindManager|Alludo|Roxio|WinDVD|Adobe|Photoshop|Illustrator'
  IndiciosFortes = '(key[-_ .]?gen|\bkg[-_ ]|crack|x[-_ ]?force|xf-?adsk|\bxf-[a-z]{2,8}|amtlib|amtemu|solidsquad|\bssq\b|ativador|crackead|universal[-_ ]?patch|(adsk|autodesk|autocad|acad).*patch|corel.*(patch|fix|\bkg\b)|kmspico|kmsauto|\bkms\b|kms.?activator|microsoft.?toolkit|re-?loader|aesofthome|midas.?office|office.?kms|adobe.*(crack|keygen|patch|amtlib)|\.torrent$)'
  IndiciosFracos = '(\bpatch(er)?\b|\bloader\b|activator|\bserials?\b|\.nfo$|portable|repack|license[-_ ]?(fix|bypass|gen)|como[-_ ]?ativar|how[-_ ]?to[-_ ]?(activate|crack))'
  ExclusaoIndicios = '^SSH-KEYGEN'
  Extensoes = '.dwg,.dwt,.dxf,.dws,.dwf,.dwfx,.dwl,.dwl2,.sv$,.bak,.rvt,.rfa,.rte,.rft,.ifc,.nwd,.nwc,.nwf,.ipt,.iam,.idw,.ipn,.ide,.max,.3ds,.fbx,.ma,.mb,.f3d,.cdr,.cdt,.cmx,.cpt,.des,.csl,.ai,.eps,.prt,.dcu,.dfm,.dpk'
  PastasPrograma = @('Autodesk','Corel','Alludo','WinZip','Parallels','Adobe')
  RaizesRegistroLicenca = @('Autodesk','Corel','Alludo','Parallels','Nico Mak Computing','WinZip Computing','FLEXlm License Manager','Macrovision','Flexera Software','Adobe')
  PrefetchPrefixes = '^(ACAD|ACCORECONSOLE|ADSK|ADODIS|ADLM|AUTODESK|INVENTOR|REVIT|3DSMAX|MAYA|NAVISWORKS|ROAMER|FUSION360|LMU|LMGRD|ODIS|CORELDRW|CORELPP|CORELPS|CDGS|DESIGNER|PAINTSHOP|WINZIP|PRL_|PARALLELS|MSIEXEC|SETUP|INSTALL|UNINSTALL|UNINS|PHOTOSHOP|ILLUSTRATOR|ACROBAT)'
  LicencaProgramData = @('Autodesk\CLM','Autodesk\AdskLicensingService','Autodesk\AdskLicensing','Autodesk\ODIS','FLEXnet','Macrovision','Corel','Alludo','Adobe')
  CandidatosLicenca = '^(adlmint|adlmutil|adlmact|adlmPIT|adskflex|AdskLicensing[^\\]*|AdskIdentityManager|AdSSO|LMU|acad|accoreconsole|Inventor|Revit|3dsmax|maya|Navisworks|roamer|CorelDRW|CorelPP|CorelPS|Designer|PASMUTILITY|PSIKey[^\\]*|CrlLicense[^\\]*|iPMClient|ClientServices|WINZIP64|WINZIP32|prl_[^\\]*|Photoshop|Illustrator|Acrobat)\.(dll|exe)$'
  DestacarPadrao = @()
}
