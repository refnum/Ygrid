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
require 'fileutils';
require 'yaml/store';

require_relative 'job';
require_relative 'node';
require_relative 'utils';
require_relative 'workspace';





#==============================================================================
# Class
#------------------------------------------------------------------------------
class AgentServer





#==============================================================================
#		AgentServer::initialize : Initialiser.
#------------------------------------------------------------------------------
def initialize

	# Create the state
	@state = YAML::Store.new(Workspace.pathJobs("state.yml"), true);

	@state.transaction do
		@state[:jobs] = Array.new();

		if (!@state.root?(:index))
			@state[:index] = 0;
		end
	end

end





#==============================================================================
#		AgentServer::submitJob : Submit a job.
#------------------------------------------------------------------------------
def submitJob(theGrid, theJob)

	# Prepare the job
	theJob.grid      = theGrid;
	theJob.src_host  = Node.local_address;
	theJob.src_index = nextJobIndex();

	jobID = theJob.id;



	# Save the job
	thePath = Workspace.pathQueuedJob(jobID);
	theJob.save(thePath);

	return(jobID);

end





#==============================================================================
#		AgentServer::openJob : Attempt to open a job.
#------------------------------------------------------------------------------
def openJob(jobID)

	# TODO: check for free slots
	pathActive = Workspace.pathActiveJob(jobID);

	FileUtils.mkdir_p(pathActive);

	return(true);

end





#==============================================================================
#		AgentServer::closeJob : Close a job.
#------------------------------------------------------------------------------
def closeJob(jobID)

	# Get the state we need
	pathActive = Workspace.pathActiveJob(jobID);



	# Close the job
	FileUtils.rm_rf(pathActive);
	
	# TODO: increment free slots

end





#==============================================================================
#		AgentServer::executeJob : Execute a job.
#------------------------------------------------------------------------------
def executeJob(jobID)

	# Get the state we need
	pathJob    = Workspace.pathActiveJob(jobID, Agent::JOB_FILE);
	pathStdout = Workspace.pathActiveJob(jobID, Agent::JOB_STDOUT);
	pathStderr = Workspace.pathActiveJob(jobID, Agent::JOB_STDERR);



	# Load the job
	theJob = Job.new(pathJob);



	# Execute the command
	`#{theJob.cmd_task} > "#{pathStdout}" 2> "#{pathStderr}"`;

end





#==============================================================================
#		AgentServer::nextJobIndex : Get the next job index.
#------------------------------------------------------------------------------
def nextJobIndex

	# Get the next index
	nextIndex = nil;

	@state.transaction do
		nextIndex = @state[:index] + 1;
		nextIndex = 1 if (nextIndex > 0xFFFFFFFF);

		@state[:index] = nextIndex;
	end

	return(nextIndex);

end





#==============================================================================
#		AgentServer::setJobProgress : Set the job's progress.
#------------------------------------------------------------------------------
def setJobProgress(jobID, theProgress)

	# Update the progress
	pathProgress = Workspace.pathActiveJob(jobID, Agent::JOB_PROGRESS);



	# Set the progress
	IO.write(pathProgress, theProgress);

end





#==============================================================================
# Class
#------------------------------------------------------------------------------
end


