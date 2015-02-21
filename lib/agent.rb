#!/usr/bin/ruby -w
#==============================================================================
#	NAME:
#		agent.rb
#
#	DESCRIPTION:
#		ygrid agent.
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
require "xmlrpc/client";
require "xmlrpc/server";

require_relative 'cluster';
require_relative 'syncer';
require_relative 'utils';
require_relative 'workspace';





#==============================================================================
# Module
#------------------------------------------------------------------------------
module Agent

# Config
AGENT_PORT = 7947;





#============================================================================
#		AgentServer : Internal server.
#----------------------------------------------------------------------------
class AgentServer

	@@nextID = 1;





	#========================================================================
	#		submitJob : Submit a job.
	#------------------------------------------------------------------------
	def submitJob(theGrid, theFile)

		# Allocate the ID
		theID    = @@nextID;
		@@nextID = @@nextID + 1;



		# Generate the job ID
		theID = ("%08X" % theID) +  Utils.localIP(true);



		# Save the job
		theJob = Utils.jsonLoad(theFile);

		theJob["grid"] = theGrid if (!theGrid.empty?);
		theJob["id"]   = theID;

		return(theID);

	end

end





#============================================================================
#		Agent.running? : Is the agent running?
#----------------------------------------------------------------------------
def Agent.running?

	return(Utils.cmdRunning?(Workspace.pathPID("agent")));

end





#============================================================================
#		Agent.start : Start the agent.
#----------------------------------------------------------------------------
def Agent.start(theArgs)

	# Get the state we need
	pathLog = Workspace.pathLog("agent");
	pathPID = Workspace.pathPID("agent");

	abort("Agent already running!") if (Agent.running?);



	# Start the server
	Utils.runDaemon(pathLog, pathPID) do
		Agent.serve();
	end

end





#============================================================================
#		Agent.stop : Stop the agent.
#----------------------------------------------------------------------------
def Agent.stop()

	# Get the state we need
	pathPID = Workspace.pathPID("agent");



	# Stop the server
	if (Agent.running?)
		Process.kill("SIGTERM", IO.read(pathPID).to_i);
	end

end





#============================================================================
#		Agent.submitJob : Submit a job.
#----------------------------------------------------------------------------
def Agent.submitJob(theGrid, theFile)

	# Submit the job
	theID = callLocal("submitJob", theGrid, theFile);

	return(theID);

end





#============================================================================
#		Agent.callLocal : Call the local server.
#----------------------------------------------------------------------------
def Agent.callLocal(theCmd, *theArgs)

	# Call the server
	callServer(nil, theCmd, *theArgs);

end





#============================================================================
#		Agent.callServer : Call a server.
#----------------------------------------------------------------------------
def Agent.callServer(theHost, theCmd, *theArgs)

	# Call a server
	theResult = nil;

	begin
		theServer = XMLRPC::Client.new(theHost, nil, AGENT_PORT);
		theResult = theServer.call("ygrid." + theCmd, *theArgs);

	rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
		puts "Agent unable to connect to #{theHost} for #{theCmd}";

	end

	return(theResult);

end





#============================================================================
#		Agent.serve : Run the server.
#----------------------------------------------------------------------------
def Agent.serve()

	# Create the server
	theServer = XMLRPC::Server.new(AGENT_PORT);
	theServer.add_handler(XMLRPC::iPIMethods("ygrid"), AgentServer.new)



	# Run until done
	theServer.serve();

end





#==============================================================================
# Module
#------------------------------------------------------------------------------
end
