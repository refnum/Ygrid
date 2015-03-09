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
	theNodes = nodesForJob(theJob)
	didOpen  = false;



	# Dispatch the job
	puts "Attempting to dispatch job #{theJob.id} to #{theNodes.size} nodes";

	theNodes.each do |theNode|
		didOpen = dispatchJobToNode(theJob, theNode);
		break if didOpen;
	end

	return(didOpen);

end





#============================================================================
#		AgentClient::dispatchJobToNode : Dispatch a job to a node.
#----------------------------------------------------------------------------
def dispatchJobToNode(theJob, theNode)

	# Open the job
	puts "Attempting to dispatch job #{theJob.id} to #{theNode.address}";
	
	didOpen = Agent.callServer(theNode.address, "openJob", theJob.id);

	puts "  => #{theNode.address} #{didOpen ? 'accepted' : 'rejected'} job #{theJob.id}";



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
	pathOpened = Workspace.pathOpenedJob(theJob.id, Agent::JOB_FILE);



	# Send the job
	theJob.host = theNode.address;

	FileUtils.mkdir_p(File.dirname(pathOpened));
	FileUtils.rm(pathQueued);
	theJob.save( pathOpened);

	Syncer.sendJob(theJob.host, theJob.id);



	# Execute the job
	#
	# The remote node will exece AgentServer::finishedJob on our local server when
	# it has finished executing the job.
	Agent.callServer(theJob.host, "executeJob", theJob.id);

end





#============================================================================
#		AgentClient::nodesForJob : Get the nodes for a job.
#----------------------------------------------------------------------------
def nodesForJob(theJob)

	# Get the state we need
	theNodes     = Cluster.nodes(theJob.grid);
	localAddress = System.address;

	maxPower  = 0.0;
	maxMemory = 0.0;



	# Determine our upper limits
	theNodes.each do |theNode|
		maxPower  = theNode.power  if (theNode.power  > maxPower);
		maxMemory = theNode.memory if (theNode.memory > maxMemory);
	end



	# Sort the nodes
	#
	# The node's CPU power/memory are normalised to the upper bounds of the
	# available nodes, then weighted by the job's priorities to give a score.
	theNodes.sort! do |nodeA, nodeB|
		scoreA = nodeScoreForJob(theJob, nodeA, localAddress, maxPower, maxMemory);
		scoreB = nodeScoreForJob(theJob, nodeB, localAddress, maxPower, maxMemory);
		scoreA <=> scoreB;
	end

	return(theNodes);

end





#============================================================================
#		AgentClient::nodeScoreForJob : Get a node's score for a job.
#----------------------------------------------------------------------------
def nodeScoreForJob(theJob, theNode, localAddress, maxPower, maxMemory)

	normalLocal  = (theNode.address == localAddress) ? 1 : 0;
	normalPower  = theNode.power  / maxPower;
	normalMemory = theNode.memory / maxMemory;

	scoreLocal  = normalLocal  * theJob.weight_local;
	scorePower  = normalPower  * theJob.weight_cpu;
	scoreMemory = normalMemory * theJob.weight_mem;
	
	return(scoreLocal + scorePower + scoreMemory);

end





#==============================================================================
# Class
#------------------------------------------------------------------------------
end
