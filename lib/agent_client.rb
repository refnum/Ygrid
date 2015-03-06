#!/usr/bin/ruby -w
#==============================================================================
#	NAME:
#		agent_client.rb
#
#	DESCRIPTION:
#		ygrid agent client.
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
require_relative 'syncer';
require_relative 'utils';
require_relative 'workspace';





#==============================================================================
# Class
#------------------------------------------------------------------------------
class AgentClient

# Config
QUEUE_POLL = 1.5;





#============================================================================
#		AgentClient::run : Run the client.
#----------------------------------------------------------------------------
def run

	# Run the client
	loop do
		dispatchJobs(waitForJobs());
	end

end





#============================================================================
#		AgentClient::waitForJobs : Wait for some jobs.
#----------------------------------------------------------------------------
def waitForJobs

	# Get the state we need
	thePath = File.dirname(Workspace.pathQueuedJob("x")) + "/*.job";
	theJobs = [];



	# Wait for jobs
	puts "Waiting for jobs...";
	
	loop do
		Dir.glob(thePath).each do |theFile|
			theJobs << Job.new(theFile);
		end

		break if (!theJobs.empty?);
		sleep(QUEUE_POLL);
	end

	return(theJobs);

end





#============================================================================
#		AgentClient::dispatchJobs : Dispatch some jobs.
#----------------------------------------------------------------------------
def dispatchJobs(theJobs)

	# Get the state we need
	numJobs   = Utils.getCount(theJobs, "job");
	fullGrids = [];



	# Process the jobs
	#
	# Jobs that can't be dispatched will defer any other jobs on that grid.
	#
	# This ensures they remain in the queue and will be processed as FIFO
	# when that grid becomes available.
	puts "Dispatching #{numJobs}..."; 

	theJobs.each do |theJob|

		if (fullGrids.include?(theJob.grid))
			puts "Unable to dispatch #{theJob.id} as grid #{theJob.grid} is full";
			continue;
		end
		
		
		if (!dispatchJobToGrid(theJob))
			fullGrids << theJob.grid;
		end	

	end

end





#============================================================================
#		AgentClient::dispatchJobToGrid : Dispatch a job to its grid.
#----------------------------------------------------------------------------
def dispatchJobToGrid(theJob)

	# Get the state we need
	theNodes = Cluster.nodes(theJob.grid);
	didOpen  = false;



	# Dispatch the job
	#
	# Nodes are sorted by priority via Node.score.
	puts "Attempting to dispatch job #{theJob.id} to #{theNodes.size} nodes";

	theNodes.sort.each do |theNode|
		didOpen = dispatchJobToNode(theNode, theJob);
		break if didOpen;
	end

	return(didOpen);

end





#============================================================================
#		AgentClient::dispatchJobToNode : Dispatch a job to a node.
#----------------------------------------------------------------------------
def dispatchJobToNode(theNode, theJob)

	# Open the job
	puts "Attempting to dispatch job #{theJob.id} to #{theNode.address}";
	
	didOpen = Agent.callServer(theNode, "openJob", theJob.id);

	puts "#{theNode.address} #{didOpen ? 'accepted' : 'rejected'} job #{theJob.id}";



	# Execute the job
	if (didOpen)
		executeJob(theNode, theJob);
	end

	return(didOpen);

end





#============================================================================
#		AgentClient::executeJob : Execute the job.
#----------------------------------------------------------------------------
def executeJob(theNode, theJob)

	# Get the state we need
	pathQueued = Workspace.pathQueuedJob(theJob.id);
	pathOpened = Workspace.pathOpenedJob(theJob.id);



	# Send the job
	theJob.host = theNode.address;

	FileUtils.mkdir_p(pathOpened);
	FileUtils.mv(pathQueued, pathOpened + "/" + Agent::JOB_FILE);

	Syncer.sendJob(theNode, theJob.id);



	# Execute the job
	#
	# The remote node will update the status of the job as it executes, which will
	# trigger a cluster update for that node.
	#
	# Once the job is marked as finished by the remote node then finishJob will be
	# invoked by the cluster event handler to fetch the results and close the job.
	Agent.callServer(theNode, "executeJob", theJob.id);

end





#============================================================================
#		AgentClient.finishJob : A job has finished.
#----------------------------------------------------------------------------
def self.finishJob(theNode, jobID)
	
	# Update our state
	#
	# Any cluster update will invoke us for any finished jobs we originated.
	#
	# Since there may be multiple cluster updates before the job has been removed
	# from the remote node we track the known finished jobs in our state and only
	# process them the first time we see them.
	#
	# Since it may take some time between us closing the job on the remote node
	# and the corresponding cluster upate we may continue to see updates for that
	# job even after we've closed it.
	#
	# This is because cluster updates are triggered for any change in a node and
	# so a node that's executing two jobs may receive two updates.
	#
	# We handle this by never purging IDs that we've seen, so that we only close
	# jobs the first time we see them.
	isKnown = false;

	Workspace.stateCompletedJobs do |theState|
		isKnown         = theState.root?(jobID);
		theState[jobID] = true;
	end



	# Finish the job
	if (!isKnown)
		# Get the state we need
		pathOpened = Workspace.pathOpenedJob(jobID);


		# Fetch the output and clean up
		Syncer.fetchJob( theNode,             jobID);
		Agent.callServer(theNode, "closeJob", jobID);

		FileUtils.rm_rf(pathOpened);


		# Execute the done hook
		puts "TODO: invoke cmd_done hook"
	end

end





#==============================================================================
# Class
#------------------------------------------------------------------------------
end
