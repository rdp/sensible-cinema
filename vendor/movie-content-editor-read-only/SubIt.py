#Subit
#	* Version 1.2
#	* 2009-01-11
#	* URL: http://www.homeofthehip.com
#	* Description: Subtitle downloader.
#	* Author: Magnus Dunker
#	* Modified by: S. Andrew Ning
#	* Copyright: Copyright (c) 2009 Magnus Dunker. Use it anyway you like
#
#@Parameters
#   -f The name of the avi file or directory. If -f is not specified subit will look in the current directory.
#   -l A comma delimitered string specifying the language of the subtitles in prioritied order.
#
#Usage: SubIt.py -f "M:\MyAvis" -l dan,eng

import time
from array import array
import struct
import os
import urllib
import sys

from zipfile import *
from xmlrpclib import ServerProxy, Error
from urllib2 import Request, urlopen, URLError, HTTPError
from optparse import OptionParser 

server = ServerProxy("http://api.opensubtitles.org/xml-rpc")
token=""
def SubIt():
	filename=""
	lang=""
	movieFound=False
	parser = OptionParser() 
	parser.add_option("-f", help="name of the file or directory to get subtitles for. If omitted SubIt will look for .avi files in the current directory",  dest="filename") 
	parser.add_option("-l", help="comma delimitered string with languages. eg dan,eng. If omitted the default will be english", dest="languages") 

	(options, args) = parser.parse_args() 
	
	if options.filename: 
		filename =  options.filename
	if options.languages:  
		lang=options.languages
	else:
		lang="eng"
		
		
	if filename=="" or os.path.isdir(filename) == True:
		if(os.path.isdir(filename) == True):
			directory = filename
		else:
			directory=os.getcwd()
		for root, dirs, files in os.walk(directory):
			for fname in files:
				extension = os.path.splitext( fname )[1]
				if extension==".avi":
					movieFound=True
					FindSubtitles(root +"\\"+ fname,lang) 
				
	else:
		FindSubtitles(filename,lang)
		movieFound=True
	if not movieFound:
		print "No movies found in '"+os.getcwd()+"'"

	raw_input("Done... press enter ")		
def FindSubtitles(videoname,lang):
	print "Contacting www.opensubtitles.org ("+videoname+")"
	filename = os.path.dirname(videoname) + "\\" +os.path.splitext(os.path.basename(videoname))[0]+ ".srt"
	
	langs=lang.split(",")
	
	data=GetSubtitles(videoname);
	found=False
	if data:
		for l in langs:
			for item in data:
				if item['SubLanguageID']== l and not found:
					print "Found", item['LanguageName'], "subtitle ..."
					zipname=Download(item['ZipDownloadLink'],item['SubFileName'])
					print "Extracting subtitle ",filename
					Unzip(zipname,filename)
					os.remove(zipname)
					found=True
	else:
		print "No Subtitles found"
				
def GetSubtitles(moviepath	):
	#print server.LogIn("","","","SubIt")['status']
	try:
		token=server.LogIn("","","","SubIt")['token']
	except:
		print "opensubtitles.org server is not online at the moment.  please try again later."
		exit(1);
		
	moviebytesize = os.path.getsize(moviepath) 
	hash=Compute(moviepath)
	movieInfo = {'sublanguageid' : 'eng','moviehash' : hash, 'moviebytesize' : moviebytesize}
	movies=[movieInfo]
	data=server.SearchSubtitles(token,movies)['data']
	
	# if the hash fails, try searching by title of movie (assuming file is named after its title)
	if (data == False):
		basename = os.path.basename(moviepath)
		name = os.path.splitext(basename)[0]
		print "Could not find by hash ..." 
		print "Searching by name: \"" + name + "\"" 
		movieInfo = {'sublanguageid' : 'eng','query' : name}
		movies=[movieInfo]
		data=server.SearchSubtitles(token,movies)['data']
		
	server.LogOut()
	
	return data
	
	

def Compute(name): 
	try:
		longlongformat = 'q'  # long long 
		bytesize = struct.calcsize(longlongformat) 
		f = file(name, "rb") 
		filesize = os.path.getsize(name) 
		hash = filesize 
		
		if filesize < 65536 * 2: 
			return "SizeError" 

		for x in range(65536/bytesize): 
			buffer = f.read(bytesize) 
			(l_value,)= struct.unpack(longlongformat, buffer)  
			hash += l_value 
			hash = hash & 0xFFFFFFFFFFFFFFFF #to remain as 64bit number  


		f.seek(max(0,filesize-65536),0) 
		for x in range(65536/bytesize): 
			buffer = f.read(bytesize) 
			(l_value,)= struct.unpack(longlongformat, buffer)  
			hash += l_value 
			hash = hash & 0xFFFFFFFFFFFFFFFF 

		f.close() 
		returnedhash =  "%016x" % hash 
		return returnedhash 

	except(IOError):
		return "IOError"

def Unzip(zipname,unzipname):
	z = ZipFile(zipname)
	for filename in z.namelist():
		if os.path.splitext(os.path.basename(filename))[1] == ".srt":
			outfile = file(unzipname, "w")
			outfile.write(z.read(filename))
			outfile.close()
	
def Download(url,filename):
	req = Request(url)
	f = urlopen(req)
	print "downloading " + url
	# Open our local file for writing
	local_file = open(filename+".zip", "w" + "b")
	#Write to our local file
	local_file.write(f.read())
	local_file.close()
	return filename+".zip"

				
SubIt()

