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

require_relative 'agent_server';
require_relative 'daemon';
require_relative 'utils';
require_relative 'workspace';





#==============================================================================
# Module
#------------------------------------------------------------------------------
module Agent

# Config
AGENT_PORT = 7947;
QUEUE_POLL = 1.5;





#============================================================================
#		Agent.start : Start the agent.
#----------------------------------------------------------------------------
def Agent.start(theArgs)

	# Get the state we need
	abort("Agent already running!") if (Daemon.running?("agent"));



	# Start the server
	Daemon.start("agent") do
		Agent.startScheduler();
		Agent.startServer();
	end

end





#============================================================================
#		Agent.submitJob : Submit a job.
#----------------------------------------------------------------------------
def Agent.submitJob(theGrid, theJob)

	# Submit the job
	theID = callLocal("submitJob", theGrid, theJob);

	return(theID);

end





#============================================================================
#		Agent.startScheduler : Start the scheduler.
#----------------------------------------------------------------------------
def Agent.startScheduler()

	# Start the scheduler
	Thread.new do
		loop do
			pathJob = getNextJob();
			theHost = getBestHost();

			scheduleJob(pathJob, theHost);
		end
	end

end





#============================================================================
#		Agent.startServer : Start the server.
#----------------------------------------------------------------------------
def Agent.startServer()

	# Create the server
	theServer = XMLRPC::Server.new(AGENT_PORT);
	theServer.add_handler(XMLRPC::iPIMethods("ygrid"), AgentServer.new)


	# Run until done
	theServer.serve();

end





#============================================================================
#		Agent.getNextJob : Get the next job.
#----------------------------------------------------------------------------
def Agent.getNextJob

	# Wait for a job
	loop do
		theFiles = Dir.glob(Workspace.pathJobs("queued/*.job"));
		return(theFiles[0]) if (!theFiles.empty?);

		sleep(QUEUE_POLL);
	end

end





#============================================================================
#		Agent.getBestHost : Get the best host.
#----------------------------------------------------------------------------
def Agent.getBestHost
	# todo
	abort("Agent.getBestHost - todo");
end





#============================================================================
#		Agent.scheduleJob : Schedule a job.
#----------------------------------------------------------------------------
def Agent.scheduleJob(pathJob, theHost)
	# todo
	abort("Agent.scheduleJob - todo");
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




#==============================================================================
# Module
#------------------------------------------------------------------------------
end
