#!/usr/bin/ruby -w
#==============================================================================
#	NAME:
#		workspace.rb
#
#	DESCRIPTION:
#		Workspace modeul.
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
require 'fileutils';





#==============================================================================
# Module
#------------------------------------------------------------------------------
module Workspace

# Paths
PATH_DEFAULT = "/tmp/ygrid";
PATH_LINK    = "/tmp/ygrid/root";





#============================================================================
#		Workspace.create : Create the workspace.
#----------------------------------------------------------------------------
def Workspace.create(theRoot)

	# Get the state we need
	if (theRoot.empty?)
		theRoot = PATH_DEFAULT;
	end



	# Create the link
	#
	# We create a link to the root at a fixed path so we can find it later.
	FileUtils.mkdir_p(theRoot);
	FileUtils.mkdir_p(File.dirname(PATH_LINK));
	FileUtils.ln_s(theRoot, PATH_LINK);



	# Create the workspace
	FileUtils.mkdir_p(Workspace.path("jobs/queued"));
	FileUtils.mkdir_p(Workspace.path("jobs/active"));
	FileUtils.mkdir_p(Workspace.path("jobs/completed"));

	FileUtils.mkdir_p(Workspace.path("data"));

	FileUtils.mkdir_p(Workspace.path("run"));

end





#============================================================================
#		Workspace.cleanup : Clean up the workspace
#----------------------------------------------------------------------------
def Workspace.cleanup

	# Clean up our files
	#
	# Logfiles are kept, pidfiles are deleted as daemons are stopped,
	# but the config files from this session can be removed.
	FileUtils.rm_f(Dir.glob(Workspace.path("run") + "/*cfg"));
	FileUtils.rm_f(PATH_LINK);

end





#============================================================================
#		Workspace.path : Get a path.
#----------------------------------------------------------------------------
def Workspace.path(thePath)

	if (File.exists?(PATH_LINK))
		theRoot = File.realpath(PATH_LINK);
	else
		theRoot = PATH_DEFAULT;
	end

	return(theRoot + "/" + thePath);

end





#============================================================================
#		Workspace.pathJobs : Get a path to a job item.
#----------------------------------------------------------------------------
def Workspace.pathJobs(thePath="")

	return(Workspace.path("jobs/#{thePath}"));

end





#============================================================================
#		Workspace.pathConfig : Get a path to a daemon config file.
#----------------------------------------------------------------------------
def Workspace.pathConfig(theCmd)

	return(Workspace.path("run/#{theCmd}.cfg"));

end





#============================================================================
#		Workspace.pathLog : Get a path to a daemon logfile.
#----------------------------------------------------------------------------
def Workspace.pathLog(theCmd)

	return(Workspace.path("run/#{theCmd}.log"));

end





#============================================================================
#		Workspace.pathPID : Get a path to a daemon pidfile.
#----------------------------------------------------------------------------
def Workspace.pathPID(theCmd)

	return(Workspace.path("run/#{theCmd}.pid"));

end





#==============================================================================
# Module
#------------------------------------------------------------------------------
end
