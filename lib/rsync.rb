#!/usr/bin/ruby -w
#==============================================================================
#	NAME:
#		rsync.rb
#
#	DESCRIPTION:
#		Rsync module.
#
#	COPYRIGHT:
#		Copyright (c) 2012, refNum Software
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

require_relative 'utils';





#==============================================================================
# Module
#------------------------------------------------------------------------------
module Rsync

# Paths
PATH_CONF = "/tmp/ygrid_rsyncd.conf";
PATH_LOG  = "/tmp/ygrid_rsyncd.log";
PATH_PID  = "/tmp/ygrid_rsyncd.pid";


# Config
CONFIG_FILE = <<CONFIG_FILE
log file  = TOKEN_PATH_LOG
pid file  = TOKEN_PATH_PID

port       = 42351
use chroot = no
list       = no
read only  = no

[ygrid]
path = TOKEN_PATH_ROOT

CONFIG_FILE





#============================================================================
#		Rsync.running? : Is rsync running?
#----------------------------------------------------------------------------
def Rsync.running?

	return(Utils.cmdRunning?(PATH_PID));

end





#============================================================================
#		Rsync.start : Start rsync.
#----------------------------------------------------------------------------
def Rsync.start(theArgs)

	# Get the state we need
	theConfig = CONFIG_FILE.dup;
	pathRoot  = theArgs["root"];

	theConfig.gsub!("TOKEN_PATH_LOG",  PATH_LOG);
	theConfig.gsub!("TOKEN_PATH_PID",  PATH_PID);
	theConfig.gsub!("TOKEN_PATH_ROOT", pathRoot);

	abort("rsync already running!") if (Rsync.running?);



	# Start the server
	FileUtils.mkpath(pathRoot);
	IO.write(PATH_CONF, theConfig);

	wasOK = system("rsync", "--daemon" , "--config=#{PATH_CONF}");

	return(wasOK);

end





#============================================================================
#		Rsync.stop : Stop rsync.
#----------------------------------------------------------------------------
def Rsync.stop()

	# Stop the server
	if (Rsync.running?)
	
		Process.kill("SIGTERM", IO.read(PATH_PID).to_i);

		FileUtils.rm(PATH_CONF);
		FileUtils.rm(PATH_PID);

	end

end





#==============================================================================
# Module
#------------------------------------------------------------------------------
end
