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

require_relative 'agent_client';
require_relative 'agent_server';
require_relative 'daemon';





#==============================================================================
# Module
#------------------------------------------------------------------------------
module Agent

# Network
PORT = 7947;


# Jobs
JOB_FILE     = "job.json";
JOB_STDOUT   = "stdout.txt";
JOB_STDERR   = "stderr.txt";
JOB_PROGRESS = "progress.txt";


# Status
STATUS_OPENED   = "opened";
STATUS_ACTIVE   = "active";
STATUS_FINISHED = "finished";





#============================================================================
#		Agent.start : Start the agent.
#----------------------------------------------------------------------------
def Agent.start

	# Get the state we need
	abort("Agent already running!") if (Daemon.running?("agent"));



	# Start the agent
	Daemon.start("agent") do
		startClient();
		startServer();
	end

end





#============================================================================
#		Agent.submitJob : Submit a job.
#----------------------------------------------------------------------------
def Agent.submitJob(theGrid, theJob)

	# Submit the job
	theID = callServer(Node.local_address, "submitJob", theGrid, theJob);

	return(theID);

end





#============================================================================
#		Agent.callServer : Call a server.
#----------------------------------------------------------------------------
def Agent.callServer(theAddress, theCmd, *theArgs)

	# Call a server
	begin
		theServer = XMLRPC::Client.new(theAddress.to_s, nil, Agent::PORT);
		theResult = theServer.call("ygrid." + theCmd, *theArgs);

	rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
		puts "Agent unable to connect to #{theHost} for #{theCmd}";
		theResult = nil;
	end

	return(theResult);

end





#============================================================================
#		Agent.startClient : Start the client.
#----------------------------------------------------------------------------
def Agent.startClient

	# Start the client
	#
	# The client is run in a thread within the daemon.
	Thread.new do
		theClient = AgentClient.new();
		theClient.run();
	end

end





#============================================================================
#		Agent.startServer : Start the server.
#----------------------------------------------------------------------------
def Agent.startServer

	# Start the server
	#
	# The server uses the daemon's main runloop.
	theServer = XMLRPC::Server.new(Agent::PORT, Node.local_address.to_s);
	theServer.add_handler(XMLRPC::iPIMethods("ygrid"), AgentServer.new)

	theServer.serve();

end





#==============================================================================
# Module
#------------------------------------------------------------------------------
end
