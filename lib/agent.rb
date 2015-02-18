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
require "xmlrpc/server";

require_relative 'cluster';
require_relative 'syncer';





#==============================================================================
# Module
#------------------------------------------------------------------------------
module Agent

# Paths
PATH_LOG = Utils.pathData("agent.log");
PATH_PID = Utils.pathData("agent.pid");


# Config
AGENT_PORT = 7947;





#============================================================================
#		Agent.running? : Is the agent running?
#----------------------------------------------------------------------------
def Agent.running?

	return(Utils.cmdRunning?(PATH_PID));

end





#============================================================================
#		Agent.start : Start the agent.
#----------------------------------------------------------------------------
def Agent.start(theArgs)

	# Get the state we need
	abort("Agent already running!") if (Agent.running?);



	# Start the server
	Utils.runDaemon(PATH_LOG, PATH_PID) do
		Agent.serve();
	end


end





#============================================================================
#		Agent.stop : Stop the agent.
#----------------------------------------------------------------------------
def Agent.stop()

	# Stop the server
	if (Agent.running?)
		Process.kill("SIGTERM", IO.read(PATH_PID).to_i);
	end

end





#============================================================================
#		Agent.serve : Run the server.
#----------------------------------------------------------------------------
def Agent.serve()

	# Create the server
	theServer = XMLRPC::Server.new(AGENT_PORT);



	# Run until done
	theServer.serve();

end





#==============================================================================
# Module
#------------------------------------------------------------------------------
end
