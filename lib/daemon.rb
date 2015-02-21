#!/usr/bin/ruby -w
#==============================================================================
#	NAME:
#		daemon.rb
#
#	DESCRIPTION:
#		Daemon module.
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
require_relative 'workspace';





#==============================================================================
# Module
#------------------------------------------------------------------------------
module Daemon





#============================================================================
#		Daemon.running? : Is a daemon running?
#----------------------------------------------------------------------------
def Daemon.running?(theCmd)

	# Get the state we need
	pathPID = Workspace.pathPID(theCmd);



	# Check the state
	if (File.exists?(pathPID))
		thePID    = IO.read(pathPID).to_i;
		isRunning = system("ps -p #{thePID} > /dev/null");
	else
		isRunning = false;
	end

	return(isRunning);

end





#============================================================================
#		Daemon.waitFor : Wait for daemons to exist.
#----------------------------------------------------------------------------
def Daemon.waitFor(theTimeout, theCmds)

	# Get the state we need
	endTime    = Time.now + theTimeout;
	activeCmds = [];



	# Wait for them to exist
	while (Time.now <= endTime)

		activeCmds.clear();

		theCmds.each do |theCmd|
			activeCmds << theCmd if (Daemon.running?(theCmd));
		end

		break      if (activeCmds.size == theCmds.size);
		sleep(0.2) if (theTimeout != 0);

	end

	return(activeCmds);

end





#============================================================================
#		Daemon.start : Start a daemon to run a block.
#----------------------------------------------------------------------------
def Daemon.start(theCmd, &block)

	# Get the state we need
	pathLog = Workspace.pathLog(theCmd);



	# Fork the daemon
	#
	# We return to the parent, exit the intermediate process, and run the supplied
	# block in the daemon process until done.
	#
	# stdout/stderr are redirected to the log file and a pidfile is maintained until
	# the daemon finishes the block or receives an exception.
	#
	# Equivalent to Process.daemon, as per:
	#
	# 	http://www.jstorimer.com/blogs/workingwithcode/7766093-daemon-processes-in-ruby
	#
	return if fork;

	Process.setsid;
    exit() if fork;

    Dir.chdir("/");
    $stdin.reopen("/dev/null");

    $stdout.reopen(pathLog, "a");
    $stderr.reopen(pathLog, "a");
	$stdout.sync = true;
	$stderr.sync = true;

	Daemon.started(theCmd, Process.pid);



	# Execute the daemon
	begin
		block.call();
	ensure
		Daemon.stopped(theCmd);
	end

	exit();

end






#============================================================================
#		Daemon.stop : Stop a daemon.
#----------------------------------------------------------------------------
def Daemon.stop(theCmds)

	# Stop the daemons
	theCmds.each do |theCmd|
		if (Daemon.running?(theCmd))
			pathPID = Workspace.pathPID(theCmd);
			Process.kill("SIGTERM", IO.read(pathPID).to_i);
		end
	end



	# Wait for them to stop
	loop do
		activeCmds = Daemon.waitFor(0, theCmds);
		break if (activeCmds.empty?)
		sleep(0.2);
	end



	# Clean up
	theCmds.each do |theCmd|
		Daemon.stopped(theCmd);
	end

end





#============================================================================
#		Daemon.started : A daemon has started.
#----------------------------------------------------------------------------
def Daemon.started(theCmd, thePID)

	# Create the pidfile
	pathPID = Workspace.pathPID(theCmd);

	IO.write(pathPID, thePID);

end





#============================================================================
#		Daemon.stopped : A daemon has stopped.
#----------------------------------------------------------------------------
def Daemon.stopped(theCmd)

	# Remove the pidfile
	pathPID = Workspace.pathPID(theCmd);

	FileUtils.rm_f(pathPID);

end





#==============================================================================
# Module
#------------------------------------------------------------------------------
end
