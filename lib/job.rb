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
attr_accessor :index
attr_accessor :source
attr_accessor :worker
attr_accessor :grid
attr_accessor :task
attr_accessor :result
attr_accessor :stdin
attr_accessor :inputs
attr_accessor :outputs
attr_accessor :environment
attr_accessor :weights


# Defaults
DEFAULT_INDEX		= nil;
DEFAULT_SOURCE		= nil;
DEFAULT_WORKER		= nil;
DEFAULT_GRID		= "";
DEFAULT_TASK		= "";
DEFAULT_RESULT		= "";
DEFAULT_STDIN		= nil;
DEFAULT_INPUTS		= [];
DEFAULT_OUTPUTS		= [];
DEFAULT_ENVIRONMENT	= {};
DEFAULT_WEIGHTS		= { :local => 10.0, :cpu => 1.0, :memory => 1.0 };





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
	
	if (@task.empty?)
		theErrors << "job does not contain 'task'";
	end

	return(theErrors);

end





#==============================================================================
#		Job::load : Load a job.
#------------------------------------------------------------------------------
def load(thePath)

	# Load the job
	theInfo = JSON.parse(IO.read(thePath), {:symbolize_names => true});

	@index			= theInfo.fetch(:index,			DEFAULT_INDEX);
	@source			= theInfo.fetch(:source,		DEFAULT_SOURCE);
	@worker			= theInfo.fetch(:worker,		DEFAULT_WORKER);
	@grid			= theInfo.fetch(:grid,			DEFAULT_GRID);
	@task			= theInfo.fetch(:task,			DEFAULT_TASK);
	@result			= theInfo.fetch(:result,		DEFAULT_RESULT);
	@stdin			= theInfo.fetch(:stdin,			DEFAULT_STDIN)
	@inputs			= theInfo.fetch(:inputs,		DEFAULT_INPUTS);
	@outputs		= theInfo.fetch(:outputs,		DEFAULT_OUTPUTS);
	@environment	= theInfo.fetch(:environment,	DEFAULT_ENVIRONMENT);
	@weights		= DEFAULT_WEIGHTS.merge(theInfo.fetch(:weights, {}));



	# Convert the addresses
	@worker      = IPAddr.new(@worker)     if (@worker     != nil);
	@source  = IPAddr.new(@source) if (@source != nil);

end





#============================================================================
#		Job::save : Save a job.
#----------------------------------------------------------------------------
def save(theFile)

	# Save the job
	theInfo = { :weights => {} };

	theInfo[:index]				= @index			if (@index				!= DEFAULT_INDEX);
	theInfo[:source]			= @source			if (@source				!= DEFAULT_SOURCE);
	theInfo[:worker]			= @worker			if (@worker				!= DEFAULT_WORKER);
	theInfo[:grid]				= @grid				if (@grid				!= DEFAULT_GRID);
	theInfo[:task]				= @task				if (@task				!= DEFAULT_TASK);
	theInfo[:result]			= @result			if (@result				!= DEFAULT_RESULT);
	theInfo[:stdin]				= @stdin			if (@stdin				!= DEFAULT_STDIN);
	theInfo[:inputs]			= @inputs			if (@inputs				!= DEFAULT_INPUTS);
	theInfo[:outputs]			= @outputs			if (@outputs			!= DEFAULT_OUTPUTS);
	theInfo[:environment]		= @environment		if (@environment		!= DEFAULT_ENVIRONMENT);
	theInfo[:weights][:local]	= @weights[:local]	if (@weights[:local]	!= DEFAULT_WEIGHTS[:local]);
	theInfo[:weights][:cpu]		= @weights[:cpu]	if (@weights[:cpu]		!= DEFAULT_WEIGHTS[:cpu]);
	theInfo[:weights][:memory]	= @weights[:memory]	if (@weights[:memory]	!= DEFAULT_WEIGHTS[:memory]);

	Utils.atomicWrite(theFile, JSON.pretty_generate(theInfo) + "\n");

end





#============================================================================
#		Job::id : Get the job ID.
#----------------------------------------------------------------------------
def id

	return(Job.encodeID(@index, @source));

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
	theInfo    = { :index => theIndex, :source => theAddress };

	return(theInfo);

end





#==============================================================================
# Class
#------------------------------------------------------------------------------
end
