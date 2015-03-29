#!/usr/bin/ruby -w
#==============================================================================
#	NAME:
#		job.rb
#
#	DESCRIPTION:
#		Job object.
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
require 'json';

require_relative 'utils';





#==============================================================================
# Class
#------------------------------------------------------------------------------
class Job


# Attributes
attr_accessor :grid
attr_accessor :host
attr_accessor :src_host
attr_accessor :src_index
attr_accessor :cmd_task
attr_accessor :cmd_done
attr_accessor :task_stdin
attr_accessor :task_inputs
attr_accessor :task_outputs
attr_accessor :task_environment
attr_accessor :weights


# Defaults
DEFAULT_GRID			 = "";
DEFAULT_HOST			 = nil;
DEFAULT_SRC_HOST		 = nil;
DEFAULT_SRC_INDEX		 = nil;
DEFAULT_CMD_TASK		 = "";
DEFAULT_CMD_DONE		 = "";
DEFAULT_TASK_STDIN       = nil;
DEFAULT_TASK_INPUTS		 = [];
DEFAULT_TASK_OUTPUTS	 = [];
DEFAULT_TASK_ENVIRONMENT = {};
DEFAULT_WEIGHTS			 = { :local => 10.0, :cpu => 1.0, :memory => 1.0 };





#==============================================================================
#		Job::initialize : Initialiser.
#------------------------------------------------------------------------------
def initialize(thePath)

	# Load the file
	load(thePath);

end





#============================================================================
#		Job::validate : Validate a job.
#----------------------------------------------------------------------------
def validate

	# Validate the job
	theErrors = [];
	
	if (@cmd_task.empty?)
		theErrors << "job does not contain 'cmd_task'";
	end

	return(theErrors);

end





#==============================================================================
#		Job::load : Load a job.
#------------------------------------------------------------------------------
def load(thePath)

	# Load the job
	theInfo = JSON.parse(IO.read(thePath), {:symbolize_names => true});

	@grid				= theInfo.fetch(:grid,				DEFAULT_GRID);
	@host				= theInfo.fetch(:host,				DEFAULT_HOST);
	@src_host			= theInfo.fetch(:src_host,			DEFAULT_SRC_HOST);
	@src_index			= theInfo.fetch(:src_index,			DEFAULT_SRC_INDEX);
	@cmd_task			= theInfo.fetch(:cmd_task,			DEFAULT_CMD_TASK);
	@cmd_done			= theInfo.fetch(:cmd_done,			DEFAULT_CMD_DONE);
	@task_stdin			= theInfo.fetch(:task_stdin,		DEFAULT_TASK_STDIN)
	@task_inputs		= theInfo.fetch(:task_inputs,		DEFAULT_TASK_INPUTS);
	@task_outputs		= theInfo.fetch(:task_outputs,		DEFAULT_TASK_OUTPUTS);
	@task_environment	= theInfo.fetch(:task_environment,	DEFAULT_TASK_ENVIRONMENT);
	@weights			= DEFAULT_WEIGHTS.merge(theInfo.fetch(:weights, {}));



	# Convert the addresses
	@host      = IPAddr.new(@host)     if (@host     != nil);
	@src_host  = IPAddr.new(@src_host) if (@src_host != nil);

end





#============================================================================
#		Job::save : Save a job.
#----------------------------------------------------------------------------
def save(theFile)

	# Save the job
	theInfo = { :weights => {} };

	theInfo[:grid]				= @grid					if (@grid				!= DEFAULT_GRID);
	theInfo[:host]				= @host					if (@host				!= DEFAULT_HOST);
	theInfo[:src_host]			= @src_host				if (@src_host			!= DEFAULT_SRC_HOST);
	theInfo[:src_index]			= @src_index			if (@src_index			!= DEFAULT_SRC_INDEX);
	theInfo[:cmd_task]			= @cmd_task				if (@cmd_task			!= DEFAULT_CMD_TASK);
	theInfo[:cmd_done]			= @cmd_done				if (@cmd_done			!= DEFAULT_CMD_DONE);
	theInfo[:task_stdin]		= @task_stdin			if (@task_stdin			!= DEFAULT_TASK_STDIN);
	theInfo[:task_inputs]		= @task_inputs			if (@task_inputs		!= DEFAULT_TASK_INPUTS);
	theInfo[:task_outputs]		= @task_outputs			if (@task_outputs		!= DEFAULT_TASK_OUTPUTS);
	theInfo[:task_environment]	= @task_environment		if (@task_environment	!= DEFAULT_TASK_ENVIRONMENT);
	theInfo[:weights][:local]	= @weights[:local]		if (@weights[:local]	!= DEFAULT_WEIGHTS[:local]);
	theInfo[:weights][:cpu]		= @weights[:cpu]		if (@weights[:cpu]		!= DEFAULT_WEIGHTS[:cpu]);
	theInfo[:weights][:memory]	= @weights[:memory]		if (@weights[:memory]	!= DEFAULT_WEIGHTS[:memory]);

	Utils.atomicWrite(theFile, JSON.pretty_generate(theInfo) + "\n");

end





#============================================================================
#		Job::id : Get the job ID.
#----------------------------------------------------------------------------
def id

	return(Job.encodeID(@src_index, @src_host));

end





#============================================================================
#		Job.encodeID : Encode an ID.
#----------------------------------------------------------------------------
def self.encodeID(theIndex, theAddress)

	# Encode the ID
	#
	# A job ID is a unique 16-character identifier that contains a
	# node-specific index and the IP address of the source node.
	theID = "%08X%08X" % [theIndex, theAddress.to_i];

	return(theID);

end





#============================================================================
#		Job.decodeID : Decode an ID.
#----------------------------------------------------------------------------
def self.decodeID(jobID)

	# Decode the ID
	theIndex   = jobID.slice( 0, 8).hex;
	theAddress = IPAddr.new(jobID.slice(-8, 8).hex, Socket::AF_INET);
	theInfo    = { :src_index => theIndex, :src_host => theAddress };

	return(theInfo);

end





#==============================================================================
# Class
#------------------------------------------------------------------------------
end
