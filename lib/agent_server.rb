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

require_relative 'job';
require_relative 'system';
require_relative 'utils';
require_relative 'workspace';





#==============================================================================
# Class
#------------------------------------------------------------------------------
class AgentServer

# Config
MONITOR_SLEEP = 3.0;





#==============================================================================
#		AgentServer::initialize : Initialiser.
#------------------------------------------------------------------------------
def initialize

	# Initialise our state
	Workspace.stateActiveJobs do |theState|
		theState[:jobs] = Hash.new();
	end



	# Start the monitor
	startMonitor();

end





#==============================================================================
#		AgentServer::startMonitor : Start the monitor thread.
#------------------------------------------------------------------------------
def startMonitor

	Thread.new do
		loop do
			Cluster.updateLoad();
			sleep(MONITOR_SLEEP);
		end
	end

end





#==============================================================================
#		AgentServer::submitJob : Submit a job.
#------------------------------------------------------------------------------
def submitJob(theGrid, theFile)

	# Prepare the job
	theJob           = Job.new(theFile);
	theJob.grid      = theGrid;
	theJob.src_host  = System.address;
	theJob.src_index = nextJobIndex();



	# Enqueue the job
	pathQueued = Workspace.pathQueuedJob(theJob.id);

	theJob.save(pathQueued);

	return(theJob.id);

end





#==============================================================================
#		AgentServer::openJob : Attempt to open a job.
#------------------------------------------------------------------------------
def openJob(jobID, srcAddress)

	# Get the state we need
	pathActive = Workspace.pathActiveJob(jobID);
	pathHost   = Workspace.pathHost(srcAddress);
	didOpen    = false;



	# Open the job
	#
	# Agents can accept one job per CPU.
	Workspace.stateActiveJobs do |theState|
		didOpen = (theState[:jobs].size < System.cpus);

		if (didOpen)
			FileUtils.mkdir_p(pathActive);
			FileUtils.mkdir_p(pathHost);

			theState[:jobs][jobID] = nil;
			Cluster.openedJob();
		end
	end

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
		FileUtils.rm_rf(pathActive);

		theState[:jobs].delete(jobID);
		Cluster.closedJob();
	end

	return(true);

end





#==============================================================================
#		AgentServer::executeJob : Execute a job.
#------------------------------------------------------------------------------
def executeJob(jobID)

	# Get the state we need
	pathJob = Workspace.pathActiveJob(jobID, Agent::JOB_FILE);
	theJob  = Job.new(pathJob);



	# Execute the job
	Thread.new do
		beginJobTask( theJob);
		invokeJobTask(theJob);
		finishJobTask(theJob);

		Agent.callServer(theJob.src_host, "finishedJob", jobID);
	end

	return(true);

end





#==============================================================================
#		AgentServer::finishedJob : A job has finished.
#------------------------------------------------------------------------------
def finishedJob(jobID)

	# Finish the job	
	Thread.new do
		# Get the state we need
		pathOpened = Workspace.pathOpenedJob(jobID, Agent::JOB_FILE);
		theJob     = Job.new(pathOpened);



		# Fetch the results
		Syncer.fetchJob(  theJob.host, jobID);
		Syncer.fetchFiles(theJob.host, theJob.task_outputs) if (!theJob.task_outputs.empty?);



		# Close the job
		FileUtils.rm_rf(pathOpened);

		Agent.callServer(theJob.host, "closeJob", jobID);



		# Execute the done hook
		if (!theJob.cmd_done.empty?)
			invokeJobDone(theJob);
		end

	end

	return(true);

end





#==============================================================================
#		AgentServer::currentStatus : Get the server status.
#------------------------------------------------------------------------------
def currentStatus

	# Get the state we need
	theStatus  = Hash.new();
	activeJobs = Hash.new();



	# Get the active jobs
	Workspace.stateActiveJobs do |theState|
		theState[:jobs].each_pair do |jobID, theInfo|
			if (theInfo != nil)
				theInfo          = theInfo.dup;
				theInfo[:status] = getCmdState(:task, jobID, Agent::JOB_STATUS);

				activeJobs[jobID] = theInfo;
			end
		end
	end



	# Get the status
	theStatus[:active] = activeJobs;

	return(theStatus);

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
#		AgentServer::beginJobTask : Begin a job's task.
#------------------------------------------------------------------------------
def beginJobTask(theJob)

	# Update our state
	Workspace.stateActiveJobs do |theState|
		theInfo              = Hash.new();
		theInfo[:grid]       = theJob.grid;
		theInfo[:time_start] = Time.now();

		theState[:jobs][theJob.id] = theInfo;
	end

end





#==============================================================================
#		AgentServer::invokeJobTask : Invoke a job's task.
#------------------------------------------------------------------------------
def invokeJobTask(theJob)

	# Get the state we need
	theEnvironment = getCmdEnvironment(theJob, Workspace.pathActiveJob(theJob.jobID));
	theOptions     = getCmdOptions(    theEnvironment);



	# Invoke the job
	setCmdState(:task, jobID, Agent::JOB_STATUS, Agent::PROGRESS_ACTIVE)

	thePID = Process.spawn(theEnvironment, theJob.cmd_task, theOptions);
	Process.wait(thePID);

	setCmdState(:task, jobID, Agent::JOB_STATUS, Agent::PROGRESS_DONE)

end





#==============================================================================
#		AgentServer::finishJobTask : Finish a job's task.
#------------------------------------------------------------------------------
def finishJobTask(theJob)

	# Update our state
	Workspace.stateActiveJobs do |theState|
		theInfo            = theState[:jobs][theJob.id];
		theInfo[:time_end] = Time.now();

		theState[:jobs][theJob.id] = theInfo;
	end

end





#==============================================================================
#		AgentServer::invokeJobDone : Invoke a job's done command.
#------------------------------------------------------------------------------
def invokeJobDone(theJob)

	# Get the state we need
	theEnvironment = getCmdEnvironment(theJob, Workspace.pathCompletedJob(theJob.jobID));
	theOptions     = getCmdOptions(    theEnvironment);

	theEnvironment.delete("YGRID_ROOT");
	theEnvironment.delete("YGRID_STDIN");
	theEnvironment.delete("YGRID_STATUS");

	theOptions[:in]  = theEnvironment["YGRID_PATH_STDOUT"];
	theOptions[:out] = "/dev/null";
	theOptions[:err] = "/dev/null";



	# Invoke the command
	thePID = Process.spawn(theEnvironment, theJob.cmd_done, theOptions);
	Process.wait(thePID);

end





#==============================================================================
#		AgentServer::getCmdEnvironment : Get a command's environment.
#------------------------------------------------------------------------------
def getCmdEnvironment(theJob, pathJob)

	# Get the job's environment
	#
	# All environment keys and values must be converted to strings.
	theEnvironment = Hash.new();

	theJob.task_environment.each_pair do |theKey, theValue|
		theEnvironment[theKey.to_s] = theValue.to_s;
	end



	# Add the standard values
	theEnvironment["YGRID_ID"]       = theJob.id;
	theEnvironment["YGRID_GRID"]     = theJob.grid;
	theEnvironment["YGRID_HOST_SRC"] = theJob.src_host.to_s;
	theEnvironment["YGRID_HOST_DST"] = theJob.host.to_s;
	theEnvironment["YGRID_ROOT"]     = Workspace.pathHost(theJob.src_host);
	theEnvironment["YGRID_STDIN"]    = (theJob.task_stdin == nil) ? "/dev/null" : theJob.task_stdin;
	theEnvironment["YGRID_STDOUT"]   = pathJob + "/" + Agent::JOB_STDOUT;
	theEnvironment["YGRID_STDERR"]   = pathJob + "/" + Agent::JOB_STDERR;
	theEnvironment["YGRID_STATUS"]   = pathJob + "/" + Agent::JOB_STATUS;

	return(theEnvironment);

end





#==============================================================================
#		AgentServer::getCmdOptions : Get a command's options.
#------------------------------------------------------------------------------
def getCmdOptions(theEnvironment)

	# Get the options
	theOptions = Hash.new();

	theOptions[:chdir]           = "/tmp";
	theOptions[:unsetenv_others] = true;
	theOptions[:in]              = theEnvironment["YGRID_PATH_STDIN"];
	theOptions[:out]             = theEnvironment["YGRID_PATH_STDOUT"];
	theOptions[:err]             = theEnvironment["YGRID_PATH_STDERR"];

	return(theOptions);

end





#==============================================================================
#		AgentServer::getCmdState : Get a command's state file.
#------------------------------------------------------------------------------
def getCmdState(theCmd, jobID, fileName)

	theFile = (theCmd == :task)	? Workspace.pathActiveJob(   jobID, fileName)
								: Workspace.pathCompletedJob(jobID, fileName);

	return(Utils.atomicRead(theFile));

end





#==============================================================================
#		AgentServer::setJobState : Set a job state value.
#------------------------------------------------------------------------------
def setJobState(theCmd, jobID, fileName, theValue)

	theFile = (theCmd == :task)	? Workspace.pathActiveJob(   jobID, fileName)
								: Workspace.pathCompletedJob(jobID, fileName);

	IO.write(theFile, theValue);

end





#==============================================================================
# Class
#------------------------------------------------------------------------------
end


