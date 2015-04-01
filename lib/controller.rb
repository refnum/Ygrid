#!/usr/bin/ruby -w
#==============================================================================
#	NAME:
#		controller.rb
#
#	DESCRIPTION:
#		ygrid controller.
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
require "xmlrpc/server";

require_relative 'agent';
require_relative 'cluster';
require_relative 'daemon';
require_relative 'job';
require_relative 'status';
require_relative 'syncer';
require_relative 'workspace';





#==============================================================================
# Module
#------------------------------------------------------------------------------
module Controller

# Servers
SERVERS = ["agent", "cluster", "syncer"];





#============================================================================
#		Controller.running? : Is the controller running?
#----------------------------------------------------------------------------
def Controller.running?

	return(Daemon.waitFor(0, SERVERS).size == SERVERS.size);

end





#============================================================================
#		Controller.start : Start the controller.
#----------------------------------------------------------------------------
def Controller.start(theRoot, theGrids)

	# Prepare to start
	Controller.stop();

	Workspace.create(theRoot);



	# Start the servers
	Agent.start();
	Syncer.start();
	Cluster.start(theGrids);

	activeCmds = Daemon.waitFor(Daemon::TIMEOUT, SERVERS);



	# Handle failure
	theErrors = "";
	
	SERVERS.each do |theCmd|
		theErrors << "  failed to start #{theCmd} server\n" if (!activeCmds.include?(theCmd));
	end

	if (!theErrors.empty?)
		Controller.stop();
		Utils.fatalError("unable to start servers\n#{theErrors}");
	end

end





#============================================================================
#		Controller.stop : Stop the controller.
#----------------------------------------------------------------------------
def Controller.stop()

	# Stop the servers
	Daemon.stop(SERVERS);

	Workspace.cleanup();

end





#============================================================================
#		Controller.joinGrids : Join some grids.
#----------------------------------------------------------------------------
def Controller.joinGrids(theGrids)

	# Join the grids
	Cluster.joinGrids(theGrids);

end





#============================================================================
#		Controller.leaveGrids : Leve some grids.
#----------------------------------------------------------------------------
def Controller.leaveGrids(theGrids)

	# Leave the grids
	Cluster.leaveGrids(theGrids);

end





#============================================================================
#		Controller.submitJob : Submit a job.
#----------------------------------------------------------------------------
def Controller.submitJob(theGrid, theFile)

	# Submit the job
	#
	# We try and load the job first to validate the file.
	theJob = Job.new(theFile);
	jobID  = Agent.submitJob(theGrid, theFile);

	return(jobID);

end





#============================================================================
#		Controller.showStatus : Show the status.
#----------------------------------------------------------------------------
def Controller.showStatus(theGrids)

	# Get the state we need
	if (theGrids.empty?)
		theGrids = Cluster.grids;
	end



	# Show the grids
	Utils.sleepLoop(2) do

		theGrids.each do |theGrid|
			theNodes = Cluster.nodes(theGrid);
			Status.showStatus(theGrid, theNodes);
		end

	end

end





#==============================================================================
# Module
#------------------------------------------------------------------------------
end
