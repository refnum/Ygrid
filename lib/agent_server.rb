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

require_relative 'job_status';
require_relative 'job';
require_relative 'node';
require_relative 'utils';
require_relative 'workspace';





#==============================================================================
# Class
#------------------------------------------------------------------------------
class AgentServer

# Config
FILE_STATE   = "state.yml";
MONITOR_POLL = 5;





#==============================================================================
#		AgentServer::initialize : Initialiser.
#------------------------------------------------------------------------------
def initialize

	# Initialise ourselves
	@state = createState();

	startMonitor();

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

	# Get the state we need
	pathActive = Workspace.pathActiveJob(jobID);
	didOpen    = false;



	# Open the job
	#
	# Agents can accept one job per CPU.
	@state.transaction do
		didOpen = (@state[:jobs].size < Node.local_cpus);

		if (didOpen)
			# Save the job
			@state[:jobs] << jobID;


			# Create the state
			FileUtils.mkdir_p(pathActive);
			setJobStatus(jobID, JobStatus::ACTIVE);
		end
	end



	# Update our state
	updateJobStatus();

	return(didOpen);

end





#==============================================================================
#		AgentServer::closeJob : Close a job.
#------------------------------------------------------------------------------
def closeJob(jobID)

	# Get the state we need
	pathActive = Workspace.pathActiveJob(jobID);



	# Close the job
	@state.transaction do
		# Forget the job
		@state[:jobs].delete(jobID);


		# Clean up
		FileUtils.rm_rf(pathActive);
	end



	# Update our state
	updateJobStatus();

	return(true);

end





#==============================================================================
#		AgentServer::executeJob : Execute a job.
#------------------------------------------------------------------------------
def executeJob(jobID)

	# Get the state we need
	pathJob    = Workspace.pathActiveJob(jobID, Agent::JOB_FILE);
	pathStdout = Workspace.pathActiveJob(jobID, Agent::JOB_STDOUT);
	pathStderr = Workspace.pathActiveJob(jobID, Agent::JOB_STDERR);

	theJob = Job.new(pathJob);



	# Execute the job
	Thread.new do
		`#{theJob.cmd_task} > "#{pathStdout}" 2> "#{pathStderr}"`;

		setJobStatus(jobID, JobStatus::DONE);
		updateJobStatus();
	end

	return(true);

end





#==============================================================================
#		AgentServer::createState : Create the state.
#------------------------------------------------------------------------------
def createState

	# Create the state
	theState = YAML::Store.new(Workspace.pathJobs(FILE_STATE), true);

	theState.transaction do
		theState[:jobs] = Array.new();

		if (!theState.root?(:index))
			theState[:index] = 0;
		end
	end
	
	return(theState);

end





#==============================================================================
#		AgentServer::startMonitor : Start the monitor.
#------------------------------------------------------------------------------
def startMonitor

	Thread.new do
		loop do
			updateJobStatus();
			sleep(MONITOR_POLL);
		end
	end

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
#		AgentServer::updateJobStatus : Update our job status.
#------------------------------------------------------------------------------
def updateJobStatus

	# Update the job status
	#
	# The status of jobs can be updated as a result of starting a job, executing
	# a job, or the monitor thread.
	#
	# As these all run on separate threads we use our transaction as a simple
	# lock to ensure only one thread updates the cluster at a time.
	@state.transaction do
		# Collect the status
		theStatuses = [];

		@state[:jobs].each do |jobID|
			theStatuses << getJobStatus(jobID);
		end


		# Update the cluster
		Cluster.updateJobStatus(theStatuses);
	end

end





#==============================================================================
#		AgentServer::getJobStatus : Get a JobStatus.
#------------------------------------------------------------------------------
def getJobStatus(jobID)

	pathStatus = Workspace.pathActiveJob(jobID, Agent::JOB_STATUS);
	theStatus  = Utils.atomicRead(pathStatus);

	return(JobStatus.new(jobID, theStatus, Node.local_address));

end





#==============================================================================
#		AgentServer::setJobStatus : Set a job's status.
#------------------------------------------------------------------------------
def setJobStatus(jobID, theStatus)

	pathStatus = Workspace.pathActiveJob(jobID, Agent::JOB_STATUS);

	IO.write(pathStatus, theStatus);

end





#==============================================================================
# Class
#------------------------------------------------------------------------------
end


