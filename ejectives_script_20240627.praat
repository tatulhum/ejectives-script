﻿################################### 
# 
# New ejectives script!
#
# By: Maida Percival with a lot of help from Jessamyn Schertz
# I've taken pieces of and/or inspiration from other scripts for certain parts: 
#		- Alexei Kochetov's spectral measures script
#		- James Kirby's PraatSauce script (https://github.com/kirbyj/praatsauce)
#		- Christian DiCianio's time averaged spectral measurements script (https://www.acsu.buffalo.edu/~cdicanio/scripts.html)
# Thanks for additional input and/or design help from Radu Craioveanu, Emily Clare, and Ted Kye
#
# Input: sound file and TG
# This measures: a lot of things... 
# - stop label
# - position of the stop within the word (1 = initial, 2 = medial, 3 = final)
# - burst: annotate the burst with b to get: duration (bDur), mean intensity (bMeanInt), maximum intensity (bMaxInt), minimum intensity (bMinInt), spectral measures (bcog, bsd,bskew,bkur)
# - release:
# 		- type of release can be distinguished using the following labels: rh (aspiration), rs (silence), rg (glottalization), rf (frication).
#		- The script will give the duuration of each release type and of the combined release portions. rDur is the combined post-burst release duration, while posvot is the combined burst + post-burst release duration.
# - for fricatives or affricates, the script gives spectral measurements centered around the frication midpoint (rfcog, rfsd, rfskew, rfkur) and intensity measurements across five points (10%, 30%, 50%, 70%, 90%). You can also get time averaged spectral measurements if you need or want them, but I have commented those out for now.
# - closure duration: annotating the closure with c will give this. If you are interested in voicing into the closure, you can use p (for periodicity) to annotate voiced closures (or portions thereof) and c for voiceless closure. In this case, you'd need to add cDur and pDur to get the total closure duration.
# - following vowel label and several measurements:
#		- formant values for F12, F2, F3 at 10%, 50%, 90% points
#		- F0 at 10%, 50%, 90% points
#		- H1-H2 (raw = h1h2.) at 10%, 50%, 90% points
#		- H1-H2 (corrected = h1ch2c.) at 10%, 50%, 90% points
#		- jitter at the beginning, middle, and end 30 ms intervals and jitter perturbation (beginning - middle)
#		- intensity means of: mean vowel intensity, maximum vowel intensity, minimum vowel intensity, intensity at vowel 10%, 50%, and 90% points
# - following cowel label and several measurements
#		- all measurements parallel following vowel measurements except that they are appended with a pv. prefix and pv.jit_pert is end - middle
##################################


clearinfo

## USER INPUT #########

## dialog box to query user input

beginPause: "User input"
	word: "homedir", "/Users/maida/Dropbox/Maida-dissertation/Praat_scripts/ejective_script/"
	#word: "homedir", "C:\Users\kyete\Documents\Scripts\Praat\Ejective_Script\"
	word: "soundsdir", "sounds/"
	positive: "wordTier", 1
	positive: "segTier", 2
	positive: "stopTier", 3
	word: "output", "ejective_measurements.txt"
	word: "pitchParams", "pitch_params.txt"
	comment: "Leave the below blank to use same formant specs for all data."
	word: "formantParam", ""
	comment: "Recommending ceiling is 4500 for male and 5000 for female."
	comment: "This is ignored if formant_parameters are used above."
	positive: "formantCeiling", 5000
	positive: "numForm", "5"
	#comment: "These settings are for the time averaged spectral moments."
  	##positive "resamplingRate", 44100   	
	#positive: "window_number", 6
   	#positive: "window_size", 0.01
   	#positive: "high_pass_cutoff", 300
endPause: "Continue", 1

## set up output file

@makeHeader

# JS 6/15 open pitch parameters file
pitchInfo = Read Table from tab-separated file: pitchParams$

# JS 7/14
#formantInfo = Read Table from tab-separated file: formantParam$


## READ IN FILES #####################

files = Create Strings as file list: "", soundsdir$+"*.wav"
numFiles = Get number of strings

for file from 1 to numFiles
	select files
	filename$ = Get string: file
	filename$ = filename$-".wav"
	
	sound = Read from file: soundsdir$+filename$+".wav"

	# JS 6/15 create Pitch object with user-specified parameters
	# (I'm not sure how the speaker is coded for all files, so
	# the speaker$ part might need to be modified for others)
	#
	# Using "interpolated" pitch copying VoiceSauceImitator 
	# but I'm not sure what this means. 

	ind = index(filename$, "_")
	speaker$ = left$(filename$, ind-1)
	select pitchInfo
	row = Search column: "sub", speaker$
	floor = Get value: row, "floor"
	ceiling = Get value: row, "ceiling"
	select sound
	pitch = noprogress To Pitch: 0, floor, ceiling
	pitchInterpolated = Interpolate
	if formantParam$ <> ""
		select formantInfo
		row = Search column: "sub", speaker$
		formantCeiling = Get value: row, "ceiling"
		numForm = Get value: row, "numForm"
	endif
	select sound
	sample_rate = Get sampling frequency
	#formant = To Formant (burg): 0, numForm, formantCeiling, 0.025, 50

	tg = Read from file: soundsdir$+filename$+".TextGrid"

	numStopPoints = Get number of points: stopTier
	for point from 1 to numStopPoints

		bDur = 0
		rhDur = 0
		rsDur = 0
		rgDur = 0
		rfDur = 0
		timeavg_rfcog = 0
		timeavg_rfsd = 0
		timeavg_rfskew = 0
		timeavg_rfkur = 0
		rfcog = 0
		rfsd = 0
		rfskew = 0
		rfkur = 0
		rfInt.010 = 0
		rfInt.030 = 0
		rfInt.050 = 0
		rfInt.070 = 0
		rfInt.090 = 0
		rf.010Pt = 0
		rf.030Pt = 0
		rf.050Pt = 0
		rf.070Pt = 0
		rf.090Pt = 0
		rDur = 0
		cDur = 0
		pDur = 0
		v$ = ""
		vDur = 0
		prev$ = ""
		prevDur = 0
		bMeanInt = 0
		bMaxInt = 0
		bMaxIntPt = 0
		bMinInt = 0
		bMinIntPt = 0
		bcog = 0
		bsd = 0
		bskew = 0
		bkur = 0
		f0.010 = 0
		f0.050 = 0
		f0.090 = 0
		pv.f0.010 = 0
		pv.f0.050 = 0
		pv.f0.090 = 0
		h1h2.010 = 0
		h1h2.050 = 0
		h1h2.090 = 0
		h1ch2c.010 = 0
		h1ch2c.050 = 0
		h1ch2c.090 = 0
		pv.h1h2.010 = 0
		pv.h1h2.050 = 0
		pv.h1h2.090 = 0
		pv.h1ch2c.010 = 0
		pv.h1ch2c.050 = 0
		pv.h1ch2c.090 = 0
		jit_beg = 0
		jit_mid = 0
		jit_end = 0
		jit_pert = 0
		pv.jit_beg = 0
		pv.jit_mid = 0
		pv.jit_end = 0
		pv.jit_pert = 0
		f1.010 = 0
		f2.010 = 0
		f3.010 = 0
		f1.050 = 0
		f2.050 = 0
		f3.050 = 0
		f1.090 = 0
		f2.090 = 0
		f3.090 = 0
		vMeanInt = 0
		vMaxInt = 0
		vMaxIntPt = 0
		vMinInt = 0
		vMinIntPt = 0
		vInt.010 = 0
		vInt.050 = 0
		vInt.090 = 0
		v.010Pt = 0
		v.050Pt = 0
		v.090Pt = 0
		pvMeanInt = 0
		pvMaxInt = 0
		pvMaxIntPt = 0
		pvMinInt = 0
		pvMinIntPt = 0
		pvInt.010 = 0
		pv.010Pt = 0
		pvInt.050 = 0
		pv.050Pt = 0
		pvInt.090 = 0
		pv.090Pt = 0

		select tg

		stop$ = Get label of point: stopTier, point

		pos$ = left$(stop$, 1)
		seg$ = mid$(stop$, 2, length(stop$)-1)

		stopTime = Get time of point: stopTier, point
		wordInt = Get interval at time: wordTier, stopTime
		wordLabel$ = Get label of interval: wordTier, wordInt
		repNum$ = right$(wordLabel$, 1)
	
		numSegInts = Get number of intervals: segTier
		vowelInt = Get interval at time: segTier, stopTime
		vowel$ = Get label of interval: segTier, vowelInt

		###word-initial stop measurements

		if pos$ == "1"

			wordBeg = Get start time of interval: wordTier, wordInt
			startInt = Get interval at time: segTier, wordBeg+0.002

			# JS added 20201116	

		#	startInt = vowelInt-3
		#	if point == 1
		#		startInt = vowelInt-2
		#	endif

			for segInt from startInt to vowelInt

				select tg

				segTmp$ = Get label of interval: segTier, segInt
				segStart = Get start time of interval: segTier, segInt
				segEnd = 	Get end time of interval: segTier, segInt
				if segTmp$ == "b"
					bDur = segEnd-segStart

					# the below two commands are the same. 
					#call intensity segStart segEnd
					@intensity: segStart, segEnd

					bMeanInt = meanInt
					bMaxInt = maxInt
					bMaxIntPt = maxPoint
					bMinInt = minInt
					bMinIntPt = minPoint

					@cogcalc: segStart, segEnd
					bcog = cog
					bsd = sd
					bskew = skew
					bkur = kur
				endif

				#if left$(segTmp$, 1) == "r"
				#	rType$ = segTmp$
				#	rDur = segEnd-segStart
				if segTmp$ == "rh"
					rhDur = segEnd-segStart
				endif
				if segTmp$ == "rs"
					rsDur = segEnd-segStart
				endif
				if segTmp$ == "rg"
					rgDur = segEnd-segStart
				endif
				if segTmp$ == "rf"
					rfDur = segEnd-segStart
					#@cogtimeavg: segStart, segEnd
					#timeavg_rfcog = timeavg_cog
					#timeavg_rfsd = timeavg_sd
					#timeavg_rfskew = timeavg_skew
					#timeavg_rfkur = timeavg_kurt
					@cogcalc: segStart+(0.15*rfDur), segEnd-(0.15*rfDur)
					rfcog = cog
					rfsd = sd
					rfskew = skew
					rfkur = kur
					@intensity: segStart, segEnd
					rfInt.010 = int.010
					rf.010Pt = 0.1*rfDur
					rfInt.030 = int.030
					rf.030Pt = 0.3*rfDur
					rfInt.050 = int.050
					rf.050Pt = 0.5*rfDur
					rfInt.070 = int.070
					rf.070Pt = 0.7*rfDur
					rfInt.090 = int.090
					rf.090Pt = 0.9*rfDur
				endif
				rDur = rhDur + rsDur + rgDur + rfDur
				posvot = bDur + rDur 
				if segTmp$ == "c"
					cDur = segEnd-segStart
				endif
				if segTmp$ == "p"
					pDur = segEnd-segStart
				endif
				if segInt = vowelInt
					v$ = segTmp$
					vDur = segEnd-segStart
	
					# JS 6/15 I *think* this is where you want the pitch measured,
					# but if the other vowel is needed as well,
					# that will need to be added.
					# This calls the measurement procedure at a given timepoint.
					@measureF0: segStart+(0.1*vDur), segStart, segEnd, numForm, formantCeiling
					f0.010 = f0.tmp
					f1.010 = f1hzpt
					f2.010 = f2hzpt
					f3.010 = f3hzpt
					h1h2.010 = h1h2.tmp
					h1ch2c.010 = h1ch2c.tmp
					@measureF0: segStart+(0.5*vDur), segStart, segEnd, numForm, formantCeiling
					f0.050 = f0.tmp
					f1.050 = f1hzpt
					f2.050 = f2hzpt
					f3.050 = f3hzpt
					h1h2.050 = h1h2.tmp
					h1ch2c.050 = h1ch2c.tmp
					@measureF0: segStart+(0.9*vDur), segStart, segEnd, numForm, formantCeiling
					f0.090 = f0.tmp
					f1.090 = f1hzpt
					f2.090 = f2hzpt
					f3.090 = f3hzpt
					h1h2.090 = h1h2.tmp
					h1ch2c.090 = h1ch2c.tmp
					@jitter: segStart, segEnd
					jit_beg = jitter_beg
					jit_mid = jitter_mid
					jit_end = jitter_end
					jit_pert = jitter_pert
					@intensity: segStart, segEnd
					vMeanInt = meanInt
					vMaxInt = maxInt
					vMaxIntPt = maxPoint
					vMinInt = minInt
					vMinIntPt = minPoint
					vInt.010 = int.010
					v.010Pt = 0.1*vDur
					vInt.050 = int.050
					v.050Pt = 0.5*vDur
					vInt.090 = int.090
					v.090Pt = 0.9*vDur
				endif
			endfor


		###word-medial stop measurements

		elif pos$ == "2"

		

			wordEnd = Get end time of interval: wordTier, wordInt
			endInt = Get interval at time: segTier, wordEnd-0.02

		###############################
			# JS 20220125
			# this section is a hack to make the script cycle through and not get stuck at the end of the script when looking ahead and certain combinations of labels occur
			almostDone = 0
			done = 0			

			for segInt from vowelInt to endInt
				
				select tg

				segTmp$ = Get label of interval: segTier, segInt

				#JS 20211221 try to get it to stop after finding blank.

				if segTmp$ == ""
					done = 1
				endif

				if almostDone == 1
					done = 1
				endif

				# JS 20220124
				# added another criterion to "done":
				# Checks to see if there's a labeled point on the tier below.
				# If so, this is the second medial stop and it will consider it done (and ignore it).

				segStart = Get start time of interval: segTier, segInt
				segEnd = Get end time of interval: segTier, segInt
				if point < numStopPoints-1
					nextPoint = nocheck Get high index from time: stopTier, segStart

					pointTime = Get time of point: stopTier, nextPoint
					if pointTime < segEnd and segInt <> vowelInt
						almostDone = 1
					endif
				endif
		
				#####################################
				#JS 20211221
				if done <> 1
				segStart = Get start time of interval: segTier, segInt
				segEnd = 	Get end time of interval: segTier, segInt
					if segTmp$ == "b"
						bDur = segEnd-segStart
						@intensity: segStart, segEnd

						bMeanInt = meanInt
						bMaxInt = maxInt
						bMaxIntPt = maxPoint
						bMinInt = minInt
						bMinIntPt = minPoint

						@cogcalc: segStart, segEnd
						bcog = cog
						bsd = sd
						bskew = skew
						bkur = kur
					endif
					if segTmp$ == "rh"
						rhDur = segEnd-segStart
					endif
					if segTmp$ = "rs"
						rsDur = segEnd-segStart
					endif
					if segTmp$ == "rg"
						rgDur = segEnd-segStart
					endif
					if segTmp$ == "rf"
						rfDur = segEnd-segStart
						#@cogtimeavg: segStart, segEnd
						#timeavg_rfcog = timeavg_cog
						#timeavg_rfsd = timeavg_sd
						#timeavg_rfskew = timeavg_skew
						#timeavg_rfkur = timeavg_kurt
						@cogcalc: segStart+(0.15*rfDur), segEnd-(0.15*rfDur)
						rfcog = cog
						rfsd = sd
						rfskew = skew
						rfkur = kur
						@intensity: segStart, segEnd							
						rfInt.010 = int.010
						rf.010Pt = 0.1*rfDur
						rfInt.030 = int.030
						rf.030Pt = 0.3*rfDur
						rfInt.050 = int.050
						rf.050Pt = 0.5*rfDur
						rfInt.070 = int.070
						rf.070Pt = 0.7*rfDur
						rfInt.090 = int.090
						rf.090Pt = 0.9*rfDur
					endif
					rDur = rhDur + rsDur + rgDur + rfDur
					posvot = bDur + rDur
					if segTmp$ == "c"
						cDur = segEnd-segStart
					endif
					if segTmp$ == "p"
						pDur = segEnd-segStart
					endif
					if segInt = vowelInt
						prevDur = segEnd-segStart
						prev$ = segTmp$

						@measureF0: segStart+(0.1*prevDur), segStart, segEnd, numForm, formantCeiling
						pv.f0.010 = f0.tmp
						pv.f1.010 = f1hzpt
						pv.f2.010 = f2hzpt
						pv.f3.010 = f3hzpt
						pv.h1h2.010 = h1h2.tmp
						pv.h1ch2c.010 = h1ch2c.tmp
						@measureF0: segStart+(0.5*prevDur), segStart, segEnd, numForm, formantCeiling
						pv.f0.050 = f0.tmp
						pv.f1.050 = f1hzpt
						pv.f2.050 = f2hzpt
						pv.f3.050 = f3hzpt
						pv.h1h2.050 = h1h2.tmp
						pv.h1ch2c.050 = h1ch2c.tmp
						@measureF0: segStart+(0.9*prevDur), segStart, segEnd, numForm, formantCeiling
						pv.f0.090 = f0.tmp
						pv.f1.090 = f1hzpt
						pv.f2.090 = f2hzpt
						pv.f3.090 = f3hzpt
						pv.h1h2.090 = h1h2.tmp
						pv.h1ch2c.090 = h1ch2c.tmp
						@jitter: segStart, segEnd
						pv.jit_beg = jitter_beg
						pv.jit_mid = jitter_mid
						pv.jit_end = jitter_end
						pv.jit_pert = jitter_pert
						@intensity: segStart, segEnd
						pvMeanInt = meanInt
						pvMaxInt = maxInt
						pvMaxIntPt = maxPoint
						pvMinInt = minInt
						pvMinIntPt = minPoint
						pvInt.010 = int.010
						pv.010Pt = 0.1*prevDur
						pvInt.050 = int.050
						pv.050Pt = 0.5*prevDur
						pvInt.090 = int.090
						pv.090Pt = 0.9*prevDur
					endif
					##make sure that the vowel label for the vowel following the word-medial stop is listed here. Add it if not. The script needs this list for word-medial stops, because the vowelInt variable is already used up by the preceding vowel.
					if (segTmp$ == "a" or segTmp$ == "e" or segTmp$ == "i" or segTmp$ == "u" or segTmp$ == "o" or segTmp$ == "á" or segTmp$ == "óN" or segTmp$ == "ú" or segTmp$ == "é" or segTmp$ == "í" or segTmp$ == "ó" or segTmp$ == "áN" or segTmp$ == "íN" or segTmp$ == "éN" or segTmp$ == "úN" or segTmp$ == "oN" or segTmp$ == "aN" or segTmp$ == "eN" or segTmp$ == "iN" or segTmp$ == "uN" or segTmp$ == "uu" or segTmp$ == "ii" or segTmp$ == "ee" or segTmp$ == "aa" or segTmp$ == "oo" or segTmp$ == "wa" or segTmp$ == "we" or segTmp$ == "wi" or segTmp$ == "wu" or segTmp$ == "wuw" or segTmp$ == "l") and segInt != vowelInt
						vDur = segEnd-segStart
						v$ = segTmp$
						@measureF0: segStart+(0.1*vDur), segStart, segEnd, numForm, formantCeiling
						f0.010 = f0.tmp
						f1.010 = f1hzpt
						f2.010 = f2hzpt
						f3.010 = f3hzpt
						h1h2.010 = h1h2.tmp
						h1ch2c.010 = h1ch2c.tmp
						@measureF0: segStart+(0.5*vDur), segStart, segEnd, numForm, formantCeiling
						f0.050 = f0.tmp
						f1.050 = f1hzpt
						f2.050 = f2hzpt
						f3.050 = f3hzpt
						h1h2.050 = h1h2.tmp
						h1ch2c.050 = h1ch2c.tmp
						@measureF0: segStart+(0.9*vDur), segStart, segEnd, numForm, formantCeiling
						f0.090 = f0.tmp
						f1.090 = f1hzpt
						f2.090 = f2hzpt
						f3.090 = f3hzpt
						h1h2.090 = h1h2.tmp
						h1ch2c.090 = h1ch2c.tmp
						@jitter: segStart, segEnd
						jit_beg = jitter_beg
						jit_mid = jitter_mid
						jit_end = jitter_end
						jit_pert = jitter_pert
						@intensity: segStart, segEnd
						vMeanInt = meanInt
						vMaxInt = maxInt
						vMaxIntPt = maxPoint
						vMinInt = minInt
						vMinIntPt = minPoint
						vInt.010 = int.010
						v.010Pt = 0.1*vDur
						vInt.050 = int.050
						v.050Pt = 0.5*vDur
						vInt.090 = int.090
						v.090Pt = 0.9*vDur
					endif
				endif
			endfor

###word-final stop measurements

		elif pos$ == "3"

			numFilledInt = 1
			if vowelInt+1 <= numSegInts
				segTmp$ = Get label of interval: segTier, vowelInt+1
					if segTmp$ == ""
						numFilledInt = 0
					endif
			endif
			if vowelInt+2 <= numSegInts
				segTmp$ = Get label of interval: segTier, vowelInt+2
					if segTmp$ == ""
						numFilledInt = 1
					endif
			endif
			if vowelInt+3 <= numSegInts
				segTmp$ = Get label of interval: segTier, vowelInt+3
					if segTmp$ == ""
						numFilledInt = 2
					endif
			endif
			if vowelInt+4 <= numSegInts
				segTmp$ = Get label of interval: segTier, vowelInt+4
					if segTmp$ == ""
						numFilledInt = 3
					endif
			endif
			if vowelInt+5 <= numSegInts
				segTmp$ = Get label of interval: segTier, vowelInt+5
					if segTmp$ == ""
						numFilledInt = 4
					endif
			endif
			if vowelInt+6 <= numSegInts
				segTmp$ = Get label of interval: segTier, vowelInt+6
					if segTmp$ == ""
						numFilledInt = 5
					endif
			endif
			endInt = vowelInt+numFilledInt

			done = 0			

			for segInt from vowelInt to endInt
	
				select tg

				segTmp$ = Get label of interval: segTier, segInt


				#JS 20211221 try to get it to stop after finding blank.
				if segTmp$ == ""
					done = 1
				endif
				
				#JS 20211221
				if done <> 1

					segStart = Get start time of interval: segTier, segInt
					segEnd = 	Get end time of interval: segTier, segInt
					if segTmp$ == "b"
						bDur = segEnd-segStart
	
						@intensity: segStart, segEnd
						bMeanInt = meanInt
						bMaxInt = maxInt
						bMaxIntPt = maxPoint
						bMinInt = minInt
						bMinIntPt = minPoint
	
						@cogcalc: segStart, segEnd
						bcog = cog
						bsd = sd
						bskew = skew
						bkur = kur
	
						endif
						if segTmp$ == "rh"
							rhDur = segEnd-segStart
						endif
						if segTmp$ = "rs"
							rsDur = segEnd-segStart
						endif
						if segTmp$ == "rg"
							rgDur = segEnd-segStart
						endif
						if segTmp$ == "rf"
							rfDur = segEnd-segStart
							#@cogtimeavg: segStart, segEnd
							#timeavg_rfcog = timeavg_cog
							#timeavg_rfsd = timeavg_sd
							#timeavg_rfskew = timeavg_skew
							#timeavg_rfkur = timeavg_kurt							
							@cogcalc: segStart+(0.15*rfDur), segEnd-(0.15*rfDur)
							rfcog = cog
							rfsd = sd
							rfskew = skew
							rfkur = kur
							@intensity: segStart, segEnd
							rfInt.010 = int.010
							rf.010Pt = 0.1*rfDur
							rfInt.030 = int.030
							rf.030Pt = 0.3*rfDur
							rfInt.050 = int.050
							rf.050Pt = 0.5*rfDur
							rfInt.070 = int.070
							rf.070Pt = 0.7*rfDur
							rfInt.090 = int.090
							rf.090Pt = 0.9*rfDur
						endif
						rDur = rhDur + rsDur + rgDur + rfDur
						posvot = bDur + rDur
						if segTmp$ == "c"
							cDur = segEnd-segStart
						endif
						if segTmp$ == "p"
							pDur = segEnd-segStart
						endif
						if segInt = vowelInt
							prev$ = segTmp$
							prevDur = segEnd-segStart
							prev$ = segTmp$
							@measureF0: segStart+(0.1*prevDur), segStart, segEnd, numForm, formantCeiling
							pv.f0.010 = f0.tmp
							pv.h1h2.010 = h1h2.tmp
							pv.h1ch2c.010 = h1ch2c.tmp
							@measureF0: segStart+(0.5*prevDur), segStart, segEnd, numForm, formantCeiling
							pv.f0.050 = f0.tmp
							pv.h1h2.050 = h1h2.tmp
							pv.h1ch2c.050 = h1ch2c.tmp
							@measureF0: segStart+(0.9*prevDur), segStart, segEnd, numForm, formantCeiling
							pv.f0.090 = f0.tmp
							pv.h1h2.090 = h1h2.tmp
							pv.h1ch2c.090 = h1ch2c.tmp
							@jitter: segStart, segEnd
							pv.jit_beg = jitter_beg
							pv.jit_mid = jitter_mid
							pv.jit_end = jitter_end
							pv.jit_pert = jitter_pert
							@intensity: segStart, segEnd
							pvMeanInt = meanInt
							pvMaxInt = maxInt
							pvMaxIntPt = maxPoint
							pvMinInt = minInt
							pvMinIntPt = minPoint
							pvInt.010 = int.010
							pv.010Pt = 0.1*prevDur
							pvInt.050 = int.050
							pv.050Pt = 0.5*prevDur
							pvInt.090 = int.090
							pv.090Pt = 0.9*prevDur
						endif

					endif
			endfor
		endif

		@writeToOutput

	endfor

endfor

## CLEAN UP #####################

select sound
plus tg
plus files

# JS 6/15 clean up pitch
plus pitch
plus pitchInterpolated
Remove

## PROCS ##################################

procedure makeHeader
	header$ = "filename	pos	seg	"
	header$ = header$ +	"wordLabel	"
	header$ = header$ +	"repNum	"
	header$ = header$ + "bDur	"
	header$ = header$ + "bMeanInt	"
	header$ = header$ + "bMaxInt	"
	header$ = header$ + "bMaxIntPt	"
	header$ = header$ + "bMinInt	"
	header$ = header$ + "bMinIntPt	"
	header$ = header$ + "bcog	"	
	header$ = header$ + "bsd	"
	header$ = header$ + "bskew	"
	header$ = header$ + "bkur	"
#	header$ = header$ +	"rType	"
	header$ = header$ +	"rhDur	"
	header$ = header$ +	"rsDur	"
	header$ = header$ +	"rgDur	"
	header$ = header$ +	"rfDur	"
#	header$ = header$ + "timeavg_rfcog	"	
#	header$ = header$ + "timeavg_rfsd	"
#	header$ = header$ + "timeavg_rfskew	"
#	header$ = header$ + "timeavg_rfkur	"	
	header$ = header$ + "rfcog	"	
	header$ = header$ + "rfsd	"
	header$ = header$ + "rfskew	"
	header$ = header$ + "rfkur	"
	header$ = header$ +	"rfInt.010	rf.010Pt	rfInt.030	rf.030Pt	rfInt.050	rf.050Pt	rfInt.070	rf.070Pt	rfInt.090	rf.090Pt	"
	header$ = header$ +	"rDur	"
	header$ = header$ +	"posvot	"
	header$ = header$ +	"cDur	"
	header$ = header$ +	"pDur	"
	header$ = header$ +	"Vowel	"
	header$ = header$ +	"vDur	"
	header$ = header$ +	"f1.010	f1.050	f1.090	f2.010	f2.050	f2.090	f3.010	f3.050	f3.090	"
	header$ = header$ +	"f0.010	f0.050	f0.090	"
	header$ = header$ +	"h1h2.010	h1h2.050	h1h2.090	"
	header$ = header$ +	"h1ch2c.010	h1ch2c.050	h1ch2c.090	"
	header$ = header$ +	"jit_beg	jit_mid	jit_end	jit_pert	"
	header$ = header$ +	"vMeanInt	vMaxInt	vMaxIntPt	vMinInt	vMinIntPt	vInt.010	v.010Pt	vInt.050	v.050Pt	vInt.090	v.090Pt	"
	header$ = header$ +	"preVowel	"
	header$ = header$ +	"prevDur	"
	header$ = header$ +	"pv.f0.010	pv.f0.050	pv.f0.090	"
	header$ = header$ +	"pv.h1h2.010	pv.h1h2.050	pv.h1h2.090	"
	header$ = header$ +	"pv.h1ch2c.010	pv.h1ch2c.050	pv.h1ch2c.090	"
	header$ = header$ +	"pv.jit_beg	pv.jit_mid	pv.jit_end	pv.jit_pert	"
	header$ = header$ +	"pvMeanInt	pvMaxInt	pvMaxIntPt	pvMinInt	pvMinIntPt	pvInt.010	pv.010Pt	pvInt.050	pv.050Pt	pvInt.090	pv.090Pt	"
	#header$ = header$ + "rBegInt	"
	#header$ = header$ + "rInt2	"
	#header$ = header$ + "rMidInt	"
	#header$ = header$ + "rInt4		"
	#header$ = header$ + "rEndInt	"
	writeFileLine: output$, header$
endproc

procedure writeToOutput
	info$ = filename$+tab$+pos$+tab$+seg$
	info$ = info$+tab$+wordLabel$+tab$
	info$ = info$+repNum$+tab$
	info$ = info$+"'bDur'"+tab$
	info$ = info$+"'bMeanInt'"+tab$
	info$ = info$+"'bMaxInt'"+tab$
	info$ = info$+"'bMaxIntPt'"+tab$
	info$ = info$+"'bMinInt'"+tab$
	info$ = info$+"'bMinIntPt'"+tab$
	info$ = info$+"'bcog'"+tab$
	info$ = info$+"'bsd'"+tab$
	info$ = info$+"'bskew'"+tab$
	info$ = info$+"'bkur'"+tab$
#	info$ = info$+rType$+tab$
	info$ = info$+"'rhDur'"+tab$
	info$ = info$+"'rsDur'"+tab$
	info$ = info$+"'rgDur'"+tab$
	info$ = info$+"'rfDur'"+tab$
#	info$ = info$+"'timeavg_rfcog'"+tab$
#	info$ = info$+"'timeavg_rfsd'"+tab$
#	info$ = info$+"'timeavg_rfskew'"+tab$
#	info$ = info$+"'timeavg_rfkur'"+tab$	
	info$ = info$+"'rfcog'"+tab$
	info$ = info$+"'rfsd'"+tab$
	info$ = info$+"'rfskew'"+tab$
	info$ = info$+"'rfkur'"+tab$
	info$ = info$+"'rfInt.010'"+tab$+"'rf.010Pt'"+tab$+"'rfInt.030'"+tab$+"'rf.030Pt'"+tab$+"'rfInt.050'"+tab$+"'rf.050Pt'"+tab$+"'rfInt.070'"+tab$+"'rf.070Pt'"+tab$+"'rfInt.090'"+tab$+"'rf.090Pt'"+tab$
	info$ = info$+"'rDur'"+tab$
	info$ = info$+"'posvot'"+tab$
	info$ = info$+"'cDur'"+tab$
	info$ = info$+"'pDur'"+tab$
	info$ = info$+"'v$'"+tab$
	info$ = info$+"'vDur'"+tab$
	info$ = info$+"'f1.010'"+tab$+"'f1.050'"+tab$+"'f1.090'"+tab$+"'f2.010'"+tab$+"'f2.050'"+tab$+"'f2.090'"+tab$+"'f3.010'"+tab$+"'f3.050'"+tab$+"'f3.090'"+tab$
	info$ = info$+"'f0.010'"+tab$+"'f0.050'"+tab$+"'f0.090'"+tab$
	info$ = info$+"'h1h2.010'"+tab$+"'h1h2.050'"+tab$+"'h1h2.090'"+tab$
	info$ = info$+"'h1ch2c.010'"+tab$+"'h1ch2c.050'"+tab$+"'h1ch2c.090'"+tab$
	info$ = info$+"'jit_beg'"+tab$+"'jit_mid'"+tab$+"'jit_end'"+tab$+"'jit_pert'"+tab$
	info$ = info$+"'vMeanInt'"+tab$+"'vMaxInt'"+tab$+"'vMaxIntPt'"+tab$+"'vMinInt'"+tab$+"'vMinIntPt'"+tab$+"'vInt.010'"+tab$+"'v.010Pt'"+tab$+"'vInt.050'"+tab$+"'v.050Pt'"+tab$+"'vInt.090'"+tab$+"'v.090Pt'"+tab$
	info$ = info$+"'prev$'"+tab$
	info$ = info$+"'prevDur'"+tab$
	info$ = info$+"'pv.f0.010'"+tab$+"'pv.f0.050'"+tab$+"'pv.f0.090'"+tab$
	info$ = info$+"'pv.h1h2.010'"+tab$+"'pv.h1h2.050'"+tab$+"'pv.h1h2.090'"+tab$
	info$ = info$+"'pv.h1ch2c.010'"+tab$+"'pv.h1ch2c.050'"+tab$+"'pv.h1ch2c.090'"+tab$
	info$ = info$+"'pv.jit_beg'"+tab$+"'pv.jit_mid'"+tab$+"'pv.jit_end'"+tab$+"'pv.jit_pert'"+tab$
	info$ = info$+"'pvMeanInt'"+tab$+"'pvMaxInt'"+tab$+"'pvMaxIntPt'"+tab$+"'pvMinInt'"+tab$+"'pvMinIntPt'"+tab$+"'pvInt.010'"+tab$+"'pv.010Pt'"+tab$+"'pvInt.050'"+tab$+"'pv.050Pt'"+tab$+"'pvInt.090'"+tab$+"'pv.090Pt'"+tab$
	#info$ = info$+tab$+rInt2$+tab$
	#info$ = info$+tab$+rMidInt$+tab$
	#info$ = info$+tab$+rInt4$+tab$
	#info$ = info$+tab$+rEndInt$
	appendFileLine: output$, info$
	appendInfoLine: info$
endproc

# JS 6/15 f0 measurement procedure
# Note that it's totally unecessary to put this in a procedure 
# since it's really just one line. 
# But since you might be doing spectral measures at the same time
# I thought it might come in handy to have it separated out. 
# But there's no other reason. 

procedure measureF0 .measureTime .beg .end .numForm .formantCeiling

	select pitchInterpolated
	f0.tmp = Get value at time: .measureTime, "Hertz","Linear"
	if f0.tmp <> undefined

		# 1. Make a spectrum of a 25ms slice of sound surrounding the target time. 

		select sound
		sound_part = Extract part: .measureTime-0.0125, .measureTime+0.0125, "rectangular", 1.0, "yes"
		spectrum = To Spectrum (fft)

		# 2. Make the spectrum an LTAS

		ltas = To Ltas (1-to-1)

		# 3. Find the value ranges for harmonics

		# figure out values we want (ish)
		# 10% of f0 for buffer
		
		p10_f0.tmp = f0.tmp / 10
		lowerbh1 = f0.tmp - p10_f0.tmp
		upperbh1 = f0.tmp + p10_f0.tmp
		lowerbh2 = (f0.tmp * 2) - (p10_f0.tmp * 2)
		upperbh2 = (f0.tmp * 2) + (p10_f0.tmp * 2)

		# 4. Find the maximum intensity of the LTAS within each range.  
		
		h1db = Get maximum: lowerbh1, upperbh1, "None"
		h1hz = Get frequency of maximum: lowerbh1, upperbh1, "None"
		h2db = Get maximum: lowerbh2, upperbh2, "None"
		h2hz = Get frequency of maximum: lowerbh2, upperbh2, "None"
		rh1hz = round('h1hz')
		rh2hz = round('h2hz')

		# 5. Calculate h1-h2

		h1h2.tmp = h1db - h2db

		# Old vs. New praat syntax
		#h1db = Get maximum... 'lowerbh1' 'upperbh1' None
		#h1db = Get maximum: lowerbh1, upperbh1, "None"

		# 6. Clean up
		select ltas
		plus spectrum
		plus sound_part
		Remove

		# 6. Get formant measurements
		#select formant
		#f1hzpt = Get value at time: 1, .measureTime, "Hertz","Linear"
		#f2hzpt = Get value at time: 2, .measureTime, "Hertz","Linear"
		#f3hzpt = Get value at time: 3, .measureTime, "Hertz","Linear"
		#f1bw = Get bandwidth at time: 1, .measureTime, "Hertz","Linear"
		#f2bw = Get bandwidth at time: 2, .measureTime, "Hertz","Linear"
		#f3bw = Get bandwidth at time: 3, .measureTime, "Hertz","Linear"

		# JS 7/14 (replace the above)
		select sound
		sound_part = Extract part: .beg-0.1, .end+0.1, "rectangular", 1, "yes"
		formant_part = To Formant (burg): 0, numForm, formantCeiling, 0.025, 50
		f1hzpt = Get value at time: 1, .measureTime, "Hertz","Linear"
		f2hzpt = Get value at time: 2, .measureTime, "Hertz","Linear"
		f3hzpt = Get value at time: 3, .measureTime, "Hertz","Linear"
		f1bw = Get bandwidth at time: 1, .measureTime, "Hertz","Linear"
		f2bw = Get bandwidth at time: 2, .measureTime, "Hertz","Linear"
		f3bw = Get bandwidth at time: 3, .measureTime, "Hertz","Linear"
		select sound_part
		plus formant_part
		Remove

		# 7. Calculate corrected values rel to F1-3
		@correct_iseli (h1db, h1hz, f1hzpt, f1bw, f2hzpt, f2bw, f3hzpt, f3bw, sample_rate)
		h1c = correct_iseli.result
		@correct_iseli (h2db, h2hz, f1hzpt, f1bw, f2hzpt, f2bw, f3hzpt, f3bw, sample_rate)
		h2c = correct_iseli.result
		
		# 8. Calculate h1*-h2*
		h1ch2c.tmp = h1c-h2c 
	endif

endproc
	

procedure correct_iseli (dB, hz, f1hz, f1bw, f2hz, f2bw, f3hz, f3bw, fs)
	dBc = dB
	for corr_i from 1 to 3
		fx = f'corr_i'hz
		bx = f'corr_i'bw
		f = dBc
		if fx <> 0
			r = exp(-pi*bx/fs)
			omega_x = 2*pi*fx/fs
			omega  = 2*pi*f/fs
			a = r ^ 2 + 1 - 2*r*cos(omega_x + omega)
			b = r ^ 2 + 1 - 2*r*cos(omega_x - omega)

			# corr = -10*(log10(a)+log10(b));   # not normalized: H(z=0)~=0
			numerator = r ^ 2 + 1 - 2 * r * cos(omega_x)
			corr = -10*(log10(a)+log10(b)) + 20*log10(numerator)
			dBc = dBc - corr
		endif
	endfor
	.result = dBc
endproc

procedure intensity .beg .end
	select sound
	sound_part = Extract part: .beg-0.2, .end+0.2, "Rectangular", 1.0, 1
	int = To Intensity: 100, 0.0, "yes"

	maxInt = Get maximum: .beg, .end, "Parabolic"
	maxPoint = Get time of maximum: .beg, .end, "Parabolic"
	maxPoint = maxPoint - .beg
	minInt = Get minimum: .beg, .end, "Parabolic"
	minPoint = Get time of minimum: .beg, .end, "Parabolic"
	minPoint = minPoint - .beg
	meanInt = Get mean: .beg, .end, "Energy"
	int.010 = Get value at time: .beg+((.end-.beg)*0.1), "Cubic"
	int.030 = Get value at time: .beg+((.end-.beg)*0.3), "Cubic"
	int.050 = Get value at time: .beg+((.end-.beg)*0.5), "Cubic"
	int.070 = Get value at time: .beg+((.end-.beg)*0.7), "Cubic"
	int.090 = Get value at time: .beg+((.end-.beg)*0.9), "Cubic"
	select sound_part
	plus int
	Remove
endproc

procedure jitter  .beg .end
	select sound
	sound_part = Extract part: .beg-0.2, .end+0.2, "Rectangular", 1.0, 1
	pointprocess_part = To PointProcess (periodic, cc)... floor ceiling
	jitter_beg = 	Get jitter (local)... .beg .beg+0.030 0.0001 0.02 1.3
	jitter_mid = 	Get jitter (local)... .beg+((.end-.beg)*0.5)-0.015 .beg+((.end-.beg)*0.5)+0.015 0.0001 0.02 1.3
	jitter_end = 	Get jitter (local)... .end .end-0.030 0.0001 0.02 1.3
	jitter_pert = jitter_beg - jitter_mid

	select sound_part
	plus pointprocess_part
	Remove
endproc

procedure cogcalc .beg .end
   # Select a window of 40ms at the midpoint of release
#note: name$ = selected$ ("Sound")


	select sound
	#select Sound 'name$'
	  #spectrum_begin = .beg
	  #spectrum_end = .end


   # Extract to new object
	#Extract part... 'spectrum_begin' 'spectrum_end' hamming 1.0 no
	sound_part = Extract part: .beg, .end, "Hamming", 1.0, 0
	#select Sound 'name$'_part
   # analysis
	To Spectrum... yes
	Filter (pass Hann band)... 500 10000 100
	cog = Get centre of gravity... 2
	sd = Get standard deviation... 2.0
	kur = Get kurtosis...  2.0
	skew = Get skewness... 2.0

#uncomment this part if you want to make pictures of the spectrum
   # Draw FFT spectrum
#	Select outer viewport... 0 7.5 0 4
#	  Black
#	  Line width... 1
#	  Draw... 1000 10000 0 0 yes
   # Draw LPC curve
#	LPC smoothing... 3 50
#	  Red
#	  Line width... 2
#	  Draw... 1000 10000 0 0 no
   # Extra garnish
#	Marks bottom... 10 yes yes yes
#	Text top... no '.labelx$'
   # Save image & erase
#	Write to EPS file... '.labelx$'_'.counter'.eps
#	Erase all
   # Cleanup
	  Remove
	select sound_part
	  Remove
endproc

procedure pitch .beg .end
	select Sound 'name$'
	Extract part... .beg-0.2 .end+0.2 Rectangular 1.0 1
	select Sound 'name$'_part
	noprogress To Pitch... 0 60 300
	f0 = Get mean... .beg .end Hertz
	Remove
	select Sound 'name$'_part
	Remove
endproc


procedure cogtimeavg .beg .end

#For each duration in a sound file, extract its duration and then apply a low stop filter
#from 0 to the high pass cutoff frequency set as a variable. Estimate the margin of offset
#then for placing the windows evenly across this duration.

	durval = .end - .beg
	threshold = 0.1*(.end-.beg)
	domain_start = (.beg + threshold)
	domain_end = (.end - threshold)
	select sound
	sound_part = Extract part: domain_start, domain_end, "Rectangular", 1, 0
	intID = sound_part
	#sound_part = Resample... resamplingRate 50
	select intID
	intID2 = Filter (stop Hann band)... 0 high_pass_cutoff 1
	select intID2
	d1 = Get total duration
	d2 = ((d1-window_size)*window_number)/(window_number-1)
	margin = (window_size - (d2/window_number))/2
	end_d2 = (domain_end-margin)
	start_d2 = (domain_start+margin)

#Estimating the size of each window, which varies with the window number and with the size of the margin.
#The margin is the offset between the edge of the overall duration and the estimated start of the window.
#If the overall duration is shorter than the sum duration of all windows, the windows will overlap and
#the margin will be positive. So, this means that the windows at the edge of the overall duration
#are pushed inward so that they do not begin earlier or later than the overall duration. If the overall
#duration is longer than the sum duration of all windows, then the margin will be negative. This means
#that the windows are pushed outward so that they are spaced evenly across the overall duration. Tables
#are created to store the average values of each spectrum, the real values, and the imaginary values.


	chunk_length = d2/window_number
	window_end = (chunk_length)+margin
	window_start = window_end-window_size
	bins = round(((sample_rate/2)*window_size)+1)
	bin_size = (sample_rate/2)/(bins - 1)
	Create TableOfReal... freqs 1 bins
	freqs = selected("TableOfReal")
Create TableOfReal... avs 1 bins
	averages = selected("TableOfReal")
	Create TableOfReal... mag window_number bins
	magnitudes = selected("TableOfReal")
	Create TableOfReal... reals window_number bins
	real_table = selected("TableOfReal")
	Create TableOfReal... imags window_number bins
	imag_table = selected("TableOfReal")
	offset = 0.0001

#For each slice, extract the duration and get the intensity value.
#Then, convert each slice to a spectrum. For each sampling interval of the spectrum,
#extract the real and imaginary values and place them in the appropriate tables.

int_table = Create Table with column names: "table", window_number, "int.val"
	select int_table 

	for j to window_number
		window_end = (chunk_length*j)+margin
		window_start = window_end-(window_size + offset)
		select 'intID2'
		Extract part... window_start window_end Hanning 1 yes
		chunk_part = selected("Sound")

		intensity = Get intensity (dB)
		select 'int_table'
		Set numeric value: j, "int.val", intensity
		select 'chunk_part'

		
		spect = To Spectrum... no
		select spect

			for k to bins
				select 'spect'
				freq = Get frequency from bin number: k
				select 'freqs'
				Set value... 1 k freq
		  	select 'spect'
				real = Get real value in bin... k
				real2 = real^2
				select 'real_table'
				Set value... j k real2
				select 'spect'
				imaginary = Get imaginary value in bin... k
				imaginary2 = imaginary^2
				select 'imag_table'
				Set value... j k imaginary2
				select 'magnitudes'
				Set value... j k real2+imaginary2
			endfor
		dsmfc_table = Create Table with column names: "table", window_number, "dsmfc"
		select dsmfc_table
		Set numeric value: 1, "dsmfc", 92879
		select spect
		plus chunk_part
		plus dsmfc_table
		Remove
	endfor

	select 'int_table'
	Extract rows where column (text): "int.val", "is not equal to", "--undefined--"
	int.rev.table = selected("Table")
	int = Get mean: "int.val"
	select int_table
	Remove

#Getting average values from the real and imaginary numbers in the combined matrix of spectral values.
#Then, placing them into the averaged matrix.

for q to bins
        select 'magnitudes'
	mag_ave = Get column mean (index)... q
	select 'averages'
	Set value... 1 q mag_ave
endfor

#Now, converting the averaged matrix to a spectrum to get the moments. Annoyingly, Praat does
#not allow any simple function to change the sampling interval or xmax in a matrix. So, instead,
#you have to extract the first two moments and then multiply each by the sampling interval size.

	start_bin = ceiling(high_pass_cutoff/bin_size)
	select 'averages'
        Extract column ranges... 'start_bin':'bins'
        new_aves = selected("TableOfReal")
        select 'freqs'
        Extract column ranges... 'start_bin':'bins'
        new_freqs = selected("TableOfReal")
        select 'new_aves'
	To Matrix
        ave_mat = selected("Matrix")
        sum_mat = Get sum

        #We need to divide the matrix values starting from a value above your cut-off frequency by the sum of the matrix values.
        for x to (bins-start_bin+1)
          	select 'ave_mat'
         	val_x = Get value in cell: 1, x
		Set value: 1, x, val_x/sum_mat
        endfor
	
	#function for center of gravity.
        timeavg_cog = 0
        for b to (bins-start_bin+1)
          	select 'new_freqs'
         	 f = Get value: 1, b
          	select 'ave_mat'
          	p = Get value in cell: 1, b
          	timeavg_cog = timeavg_cog+(f*p)
        endfor

	#For the calculation of spectral moments, we start with the function l and then add to it for each moment.
        l2 = 0
        l3 = 0
        l4 = 0
        for c to (bins-start_bin+1)
          	select 'new_freqs'
          	f = Get value: 1, c
          	select 'ave_mat'
          	p = Get value in cell: 1, c
          	l2 = l2+((f-timeavg_cog)^2) * p
          	l3 = l3+((f-timeavg_cog)^3) * p
          	l4 = l4+((f-timeavg_cog)^4) * p
        endfor

	#After calculating the functions above, the summed values are modified slightly following Forrest et al. 1988.
	timeavg_sd = sqrt(l2)
      	timeavg_skew = l3/(l2^(3/2))
      	timeavg_kurt = (l4/(l2^2))-3
select sound_part
plus intID
plus intID2
#plus int_table
#plus spect
plus freqs
plus averages
plus magnitudes
plus real_table
plus imag_table
plus new_freqs
plus new_aves
plus int.rev.table
#plus chunk_part
plus ave_mat
Remove

endproc
















