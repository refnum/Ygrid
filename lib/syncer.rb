#!/usr/bin/ruby -w
#==============================================================================
#	NAME:
#		syncer.rb
#
#	DESCRIPTION:
#		Rsync-based syncer.
#
#	COPYRIGHT:
#		Copyright (c) 2015, refNum Software
#		<http://www.refnum.com/>
#
#		All rights reserved.
#
#		Redistribution and use in source and binary forms, with or without
#		modification, are permitted provided that the following conditions
#		are met:
#
#			o Redistributions of source code must retain the above
#			copyright notice, this list of conditions and the following
#			disclaimer.
#
#			o Redistributions in binary form must reproduce the above
#			copyright notice, this list of conditions and the following
#			disclaimer in the documentation and/or other materials
#			provided with the distribution.
#
#			o Neither the name of refNum Software nor the names of its
#			contributors may be used to endorse or promote products derived
#			from this software without specific prior written permission.
#
#		THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
#		"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
#		LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
#		A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
#		OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
#		SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
#		LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
#		DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
#		THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#		(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
#		OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#==============================================================================
# Imports
#------------------------------------------------------------------------------
require 'tempfile';

require_relative 'daemon';
require_relative 'utils';
require_relative 'workspace';





#==============================================================================
# Module
#------------------------------------------------------------------------------
module Syncer

# Config
SYNCER_VERBOSE = "--verbose";
SYNCER_PORT    = 7948;

CONFIG_FILE = <<CONFIG_FILE
log file  = TOKEN_PATH_LOG
pid file  = TOKEN_PATH_PID

port       = #{SYNCER_PORT}
use chroot = no
list       = no
read only  = no

[ygrid]
path = TOKEN_PATH_WORKSPACE

CONFIG_FILE





#============================================================================
#		Syncer.start : Start the syncer.
#----------------------------------------------------------------------------
def Syncer.start

	# Get the state we need
	pathWorkspace = Workspace.path();
	pathConfig    = Workspace.pathConfig("syncer");
	pathLog       = Workspace.pathLog(   "syncer");
	pathPID       = Workspace.pathPID(   "syncer");

	theConfig = CONFIG_FILE.dup;
	theConfig.gsub!("TOKEN_PATH_LOG",       pathLog);
	theConfig.gsub!("TOKEN_PATH_PID",       pathPID);
	theConfig.gsub!("TOKEN_PATH_WORKSPACE", pathWorkspace);

	abort("Syncer already running!") if (Daemon.running?("syncer"));



	# Start the server
	IO.write(pathConfig, theConfig);

	system("rsync", "--daemon", "--config=#{pathConfig}");

end





#============================================================================
#		Syncer.sendJob : Send a job to a node.
#----------------------------------------------------------------------------
def Syncer.sendJob(theNode, theID)

	# Send the job
	#
	# The job is transferred from the opened folder to the active folder:
	#
	#		ygrid/jobs/opened/0000003E0A000102 => ygrid/jobs/active/0000003E0A000102
	#
	# As our path is just the job ID our source is the parent folder.
	pathOpened = File.dirname(Workspace.pathOpenedJob(theID));
	pathActive = File.dirname(Workspace.pathActiveJob(theID));
	dstURL     = workspaceURL(theNode, pathActive);

	transferFiles(theNode, [theID], pathOpened, dstURL);

end





#============================================================================
#		Syncer.fetchJob : Fetch a job from a node.
#----------------------------------------------------------------------------
def Syncer.fetchJob(theNode, theID)

	# Fetch the job
	#
	# The job is transferred from the active folder to the completed folder:
	#
	#		ygrid/jobs/active/0000003E0A000102 => ygrid/jobs/completed/0000003E0A000102
	#
	# As our path is just the job ID our destination is the parent folder.
	pathActive    = File.dirname(Workspace.pathActiveJob(   theID));
	pathCompleted = File.dirname(Workspace.pathCompletedJob(theID));
	srcURL        = workspaceURL(theNode, pathActive);

	transferFiles(theNode, [theID], srcURL, pathCompleted);

end





#============================================================================
#		Syncer.sendFiles : Send files to a node.
#----------------------------------------------------------------------------
def Syncer.sendFiles(theNode, theFiles)

	# Send the files
	#
	# Transfers a list of absolute paths to the host location for the node:
	#
	#		/path/to/file.txt  =>  ygrid/hosts/10.0.1.2/path/to/file.txt
	#
	# As our paths are absolute paths our source is "/".
	pathHost = Workspace.pathHost(theNode.address);
	dstURL   = workspaceURL(theNode, pathHost);

	transferFiles(theNode, theFiles, "/", dstURL);

end





#============================================================================
#		Syncer.fetchFiles : Fetch files from a node.
#----------------------------------------------------------------------------
def Syncer.fetchFiles(theNode, theFiles)

	# Fetch the files
	#
	# Retrieves a list of absolute paths from the host location for the node:
	#
	#		ygrid/hosts/10.0.1.2/path/to/file.txt  =>  /path/to/file.txt
	#
	# As our paths are absolute paths our destination is "/".
	pathHost = Workspace.pathHost(theNode.address);
	srcURL   = workspaceURL(theNode, pathHost);

	transferFiles(theNode, theFiles, srcURL, "/");

end





#============================================================================
#		Syncer.transferFiles : Transfer files.
#----------------------------------------------------------------------------
def Syncer.transferFiles(theNode, theFiles, theSrc, theDst)

	# Get the state we need
	pathLog = Workspace.pathLog("syncer");
	tmpFile = tmpFileList(theFiles);


	# Transfer the files
	`rsync -az --recursive #{SYNCER_VERBOSE} --files-from="#{tmpFile.path}" #{theSrc} #{theDst} >> "#{pathLog}" 2>&1`;

	tmpFile.unlink();

end





#============================================================================
#		Syncer.tmpFileList : Create a temporary file list.
#----------------------------------------------------------------------------
def Syncer.tmpFileList(thePaths)

	# Create the file
	theFile = Tempfile.new('ygrid')


	# Write the file list
	thePaths.each do |thePath|
		theFile.write(thePath + "\n");
	end

	theFile.close();
	
	return(theFile);

end





#============================================================================
#		Syncer.workspaceURL : Get the URL for a workspace path.
#----------------------------------------------------------------------------
def Syncer.workspaceURL(theNode, thePath)

	# Construct the URL
	#
	# The rsync module maps to the workspace root so removing our local
	# workspace path lets us build a URL for the remote workspace.
	pathWorkspace = Workspace.path();
	
	thePath = thePath[pathWorkspace.size()..-1];
	theURL  = "rsync://#{theNode.address}:#{SYNCER_PORT}/ygrid/#{thePath}";

	return(theURL);

end





#==============================================================================
# Module
#------------------------------------------------------------------------------
end
