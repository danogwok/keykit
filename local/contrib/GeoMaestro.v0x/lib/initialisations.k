################################################################################
#
#    GeoMaestro v1.0
#    Copyright (C) 2000  St�phane Rollandin (hepta@infonie.fr)
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA
#
################################################################################

function Go()			# (appel�e au d�marrage dans le postrc)
{
	print("-G�oMaestro-v1.0")

#	Modir = 1		# console en mode direct (::)

	InitStatique()
	Conph = ''			

	Bavard = 0		# Sc�ne de base (en mode silencieux)	
	if (fileexists(BASE+"init.ev"))
	   LoadEv("init", BASE)
	else
	   InitEv()

	if (fileexists(BASE+"init.df"))
	   ReadDF("init", BASE)
	else
	{
	   InitVolume()
	   InitPan()
	   InitPit()
	   InitPB()
	   InitDur()
	   InitCScore()
	}

	if (fileexists(BASE+"init.geo"))	# �l�ments g�om�triques en m�moire
	   Geo("init", BASE)
		
#	RestoreChantier()
	
	Bavard = 1		# mode Bavard (les Bprint fonctionnent)
       #DebProf = 1		# mode d�buggage (DEBUG � toutes profondeurs)
        DebProf = 5		#		  DEBUG(5,...) et plus seulement 

	Recsched = 1
}

			

#########################################################################################
########								#################
########  Initialisations						#################
########								#################
#########################################################################################



function InitStatique()		# proc�de � toutes les initialisations
{
	InitConstantes()
	InitParameters()			# ... dans lib_dist.k
	if (typeof(InitVAR) == "function")	# cr��e par HardCodeVAR (voir console.k)
	   InitVAR()
}
										
			
function InitConstantes()	# Constantes, variables r�serv�es et options
{
	####################################################################################
	# OPTIONS MODIFIABLES ## CUSTOMIZABLE PART #########################################

	# 1) param�tres GeoMaestro (parameters)
	#--------------------------------------

	# Nombre de clicks par centim�tre, par d�faut
	CPCM = seconds(1)     # ici, une seconde (192 clicks) par centim�tre

	# nombre de canaux g�r�s:
	NbCan = 20	   # 16 midi (� instrument unique)
			   # + 4 fourre-tout G�oMaestro (qui utilisent les
			   #   n derniers canaux midis pour des compositions � n notes)

	# volume minimal pour que persiste une note:
	SILENCE = 10


	# 2) fichiers et chemins (filenames & paths)
	#-------------------------------------------

	# r�pertoires utiles:
	MDOP=	"../MIDI/"		# les fichiers MIDI sont �crits ici par ExMIDI() & Co.
	MAT=    "../contrib/GeoMaestro/"	# r�pertoire racine 
	DATA=	MAT+"data/"		
	COMPOS=	MAT+"userlib/"		# doit se trouver dans le Path de KeyKit
	VRAC =	MDOP+"Vrac/"		
	BASE=	COMPOS+"Courant/"	# compositions courantes (dont les Ev au d�marrage)

	# R�pertoire d'�criture par d�faut  (utilis� par RacineN() et FichierN())
	DEFDIR = DATA


	# 3) Syst�me
	#-----------

	# Langue (Langage)
	#	FrenchBlahBlah()
	EnglishBlahBlah()

	# Notepad(): le fichier "nom" sera ouvert par NOTEPAD1+"nom"+NOTEPAD2
	NOTEPAD1 = "Notepad.exe "	        # (pour Windows)
	NOTEPAD2 = ""				# (pour �ventuelles options)
	TEMPFILE = DATA+"temp.txt"		# nom de fichier par d�faut pour Notepad()


	# 4) CSound
	#----------

	# pr�cision des floats par d�faut:
	CS_DIGITS = 2				# cf. SCpn()

	# FIN OPTIONS ## END CUSTOM ########################################################
	####################################################################################




	Pi = 3.14159265358979	

	# console:
	GEOCOMMENT = "D�fini � la console:"	# pour Sgeo()
	FT = []					# fonctions de T (history)
	FKK = []				# fonctions de X, Y, N, C (history)
	FIF = []				# tests sur X, Y, N, C (history)
	LOG = []				
	SNARF = []
	GVARS = []				# variables globales � retenir		

	# lignes cr��es par l'outil graphique:
	RL = []		

	# pour op�rations sur les r�gions:
	Tout = [0=0]	      # r�gion vide (pas de calcul de r�gion effectu�)
	EnPlusDe = ""	      # op pour ajouter (OU) la r�gion
	EnMoinsDe = "!"	      # op pour ajouter (OU) le n�gatif de la r�gion

	# variables globales r�serv�es pour des calculs temporaires:
	# X_, Y_, C_, Ev, Ln, A_, P_, L_
	# G__, K__
	# N_, T__, S_		
	# G__G, N_N
	# Ma, Mb	points d�finis par la souris dans winterface.k

	# pour utilisation par Excel et par eval():
	Xs = "x"
	Ys = "y"
	Cs = "c"
	Rs = "r"
	Ph = "nodur"
	As = "actif"
	Ss = "s"
	PACs = "PAC"
	Ds = "desc"
	INTERs = "inter"
	RACs = "rac"
	CERs = "cer"
	PAs = "A"
	PBs = "B"
}							


function InitVolume()	# fonction de volume par d�faut, pour chaque canal
{
	Volume = []
	for (c=1; c<= NbCan; c++) Volume[c] = "NoChanges"		# d�faut	
}


function InitPan()	# fonction de st�r�o par d�faut, pour chaque canal
{
	Pan = []
	for (c=1; c<= NbCan; c++) Pan[c] = "BasicPan"		# d�faut

	Pan[3] = "LargePan"
	Pan[4] = "LargePan"
	Pan[14] = "LargePan"
	Pan[15] = "LargePan"
	Pan[16] = "LargePan"
}


function InitPit()	# fonction de pitch par d�faut, pour chaque canal
{
	Pit = []
	for (c=1; c<= NbCan; c++) Pit[c] = "NoChanges"		# d�faut

	Pit[3] = "DopplerLateral"
	Pit[4] = "DopplerLateral"
	Pit[14] = "DopplerLateral"
	Pit[15] = "DopplerLateral"	
	Pit[16] = "DopplerLateral"
}


function InitPB()	# fonction de pitch bend par d�faut, pour chaque canal
{
	PB = []
	for (c=1; c<= NbCan; c++) PB[c] = "NoBend"		# d�faut
}


function InitDur()	# fonction de dur�e par d�faut, pour chaque canal
{
	Dur = []
	for (c=1; c<= NbCan; c++) Dur[c] = "NoChanges"		# d�faut
}


function InitEv()		
{							
	Ev = [0=0]			
	for (nc = 1; nc <= NbCan; nc++) {Ev[nc]=[0=0, "PAC"= '']}			
}


function InitCScore()	# fonction de distortion pour scores CSound 
{
	CScore = []
	for (c=1; c<= NbCan; c++) CScore[c] = "KeepScore"		
}




