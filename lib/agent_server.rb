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

require_relative 'job_status';
require_relative 'job';
require_relative 'system';
require_relative 'utils';
require_relative 'workspace';





#==============================================================================
# Class
#------------------------------------------------------------------------------
class AgentServer

# Config
MONITOR_POLL = 5;





#==============================================================================
#		AgentServer::initialize : Initialiser.
#------------------------------------------------------------------------------
def initialize

	# Initialise ourselves
	Workspace.stateActiveJobs do |theState|
		theState[:jobs] = Array.new();
	end


	startMonitor();

end





#==============================================================================
#		AgentServer::submitJob : Submit a job.
#------------------------------------------------------------------------------
def submitJob(theGrid, theJob)

	# Prepare the job
	theJob.grid      = theGrid;
	theJob.src_host  = System.address;
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
	Workspace.stateActiveJobs do |theState|
		didOpen = (theState[:jobs].size < System.cpus);

		if (didOpen)
			# Save the job
			theState[:jobs] << jobID;


			# Create the state
			FileUtils.mkdir_p(pathActive);
			setJobStatus(jobID, JobStatus::ACTIVE);
		end
	end



	# Update our state
	updateJobsStatus();

	return(didOpen);

end





#==============================================================================
#		AgentServer::closeJob : Close a job.
#------------------------------------------------------------------------------
def closeJob(jobID)

	# Get the state we need
	pathActive = Workspace.pathActiveJob(jobID);



	# Close the job
	Workspace.stateActiveJobs do |theState|
		# Forget the job
		theState[:jobs].delete(jobID);


		# Clean up
		FileUtils.rm_rf(pathActive);
	end



	# Update our state
	updateJobsStatus();

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
		updateJobsStatus();
	end

	return(true);

end





#==============================================================================
#		AgentServer::startMonitor : Start the monitor.
#------------------------------------------------------------------------------
def startMonitor

	Thread.new do
		loop do
			updateJobsStatus();
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

	Workspace.stateJobs do |theState|
		nextIndex = theState.fetch(:index, 0) + 1;
		nextIndex = 1 if (nextIndex > 0xFFFFFFFF);

		theState[:index] = nextIndex;
	end

	return(nextIndex);

end





#==============================================================================
#		AgentServer::updateJobsStatus : Update the jobs status.
#------------------------------------------------------------------------------
def updateJobsStatus

	# Update the jobs status
	#
	# The status of jobs can be updated as a result of starting a job, executing
	# a job, or the monitor thread.
	#
	# As these all run on separate threads we use our transaction as a simple
	# lock to ensure only one thread updates the cluster at a time.
	Workspace.stateActiveJobs do |theState|
		# Collect the status
		jobsStatus = [];

		theState[:jobs].each do |jobID|
			jobsStatus << getJobStatus(jobID);
		end


		# Update the cluster
		Cluster.updateJobsStatus(jobsStatus);
	end

end





#==============================================================================
#		AgentServer::getJobStatus : Get a JobStatus.
#------------------------------------------------------------------------------
def getJobStatus(jobID)

	pathStatus = Workspace.pathActiveJob(jobID, Agent::JOB_STATUS);
	theStatus  = Utils.atomicRead(pathStatus);

	return(JobStatus.new(jobID, theStatus, System.address));

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


