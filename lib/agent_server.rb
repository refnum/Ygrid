#!/usr/bin/ruby -w
#==============================================================================
#	NAME:
#		agent_server.rb
#
#	DESCRIPTION:
#		ygrid agent server.
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
require_relative 'job';
require_relative 'node';
require_relative 'utils';
require_relative 'workspace';





#==============================================================================
# Class
#------------------------------------------------------------------------------
class AgentServer





#==============================================================================
#		AgentServer::submitJob : Submit a job.
#------------------------------------------------------------------------------
def submitJob(theGrid, theJob)

	# Prepare the job
	theID = Job.encodeID(Node.local_address, nextIndex);

	theJob["grid"] = theGrid if (!theGrid.empty?);
	theJob["id"]   = theID;



	# Save the job
	thePath = Workspace.pathJobs("queued/#{theID}.job");
	Utils.jsonSave(thePath, theJob);

	return(theID);

end





#==============================================================================
#		AgentServer::nextIndex : Allocate the next job index.
#------------------------------------------------------------------------------
def nextIndex

	# Get the last index
	theFile = Workspace.pathJobs("last.idx");

	if (File.exists?(theFile))
		theIndex = IO.read(theFile).to_i;
	else
		theIndex = 0;
	end



	# Get the next index
	theIndex = theIndex + 1;

	if (theIndex >= 0xFFFFFFFF)
		theIndex = 1;
	end

	IO.write(theFile, theIndex);

	return(theIndex);

end





#==============================================================================
# Class
#------------------------------------------------------------------------------
end


