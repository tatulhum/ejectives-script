# ejectives-script

# New ejectives script
#
# By: Maida Percival with a lot of help from Jessamyn Schertz
# I've taken pieces of and/or inspiration from other scripts for certain parts: 
#		- Alexei Kochetov's spectral measures script
#		- James Kirby's PraatSauce script (https://github.com/kirbyj/praatsauce)
#		- Christian DiCianio's time averaged spectral measurements script (https://www.acsu.buffalo.edu/~cdicanio/scripts.html)
# Thanks for additional input and/or design help from Radu Craioveanu, Emily Clare, and Ted Kye


Input: 
- sound file and TG (need should be the same with the speaker code or initials as a prefix). 
- the textgrid needs to be annotated according to the example file:
	- word tier
	- segment tier: 
			- c for closure (this is optional)
			- p for voiced closure or portion of closure (optional)
			- b for burst (optional)
			- rs for silence, rh for aspiration, rf for frication, rg for glottal stop or other glottalization stuff (all optional and can have multiple in a single word)
			- the label of the preceding and following vowels with their vowel quality. One vowel minimum is necessary to annotate to give the stop tier a host.
	- stop tier:
			- give the label for the stop or affricate as a point
			- the point should be located on the following vowel for word-initial stops, on the preceding vowel for word-medial and word-final stops. Multiple stop labels can cooccur on a vowel. It doesn’t have to be a vowel (could be a syllabic sonorant or other segment if the word has no vowels) but whatever the stop is annotated below will undergo the vowel measurements.
- The script can loop through multiple paired text grids and wav files in the “Sounds” folder, and combined the results into a single spreadsheet. But I would recommend doing one or few at a time (in case of freezing)..

Set up:
- Put the sound file and text grid in the “Sounds” folder.
- Input the F0 range of the speaker in the pitch_params.txt file. Make sure that this file lists the speakers by whatever speaker code or initials you put as the file name prefix.
- fix the file directory of the folder in which the script is located within the script itself.
- open the script in Praat and run it with an empty objects window


This measures: a lot of things... 
 - stop label
 - position of the stop within the word (1 = initial, 2 = medial, 3 = final)
 - burst: annotate the burst with b to get: duration (bDur), mean intensity (bMeanInt), maximum intensity (bMaxInt), minimum intensity (bMinInt), spectral measures (bcog, bsd, bskew, bkur)
 - release:
 		- type of release can be distinguished using the following labels: rh (aspiration), rs (silence), rg (glottalization), rf (frication).
		- The script will give the duration of each release type and of the combined release portions. rDur is the combined post-burst release duration, while posvot is the combined burst + post-burst release duration.
 - for fricatives or affricates, the script gives spectral measurements centered around the frication midpoint (rfcog, rfsd, rfskew, rfkur) and intensity measurements across five points (10%, 30%, 50%, 70%, 90%). You can also get time averaged spectral measurements if you need or want them (following Christian Dicanio's methods/script), but I have commented those out for now. If you want to add them back in (or more generally, if you want to add or remove anything), make sure you do so for all three word position loops.
 - closure duration: annotating the closure with c will give this. If you are interested in voicing into the closure, you can use p (for periodicity) to annotate voiced closures (or portions thereof) and c for voiceless closure. In this case, you'd need to add cDur and pDur to get the total closure duration.
 - following vowel label and several measurements:
		- formant values for F12, F2, F3 at 10%, 50%, 90% points
		- F0 at 10%, 50%, 90% points
		- H1-H2 (raw = h1h2.) at 10%, 50%, 90% points
		- H1-H2 (corrected = h1ch2c.) at 10%, 50%, 90% points
		- jitter at the beginning, middle, and end 30 ms intervals and jitter perturbation (beginning - middle)
		- intensity means of: mean vowel intensity, maximum vowel intensity, minimum vowel intensity, intensity at vowel 10%, 50%, and 90% points
 - following vowel label and several measurements
		- all measurements parallel following vowel measurements except that they are appended with a pv. prefix and pv.jit_pert is end - middle
