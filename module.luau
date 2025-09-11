--[[
	- RingBuffer -
	Implements a ring buffer data structure in Luau.
	Provides convenient push/get operators and iterators.

	Copyright (c) 2025 Nowoshire
	
	This software is released under the MIT License.
		https://github.com/Nowoshire/Luau-Ring-Buffer/blob/main/LICENSE
	
	Constructors:
		function new(size: number?): (RingBuffer<any>)
		function fromArray <T>(t: {T}): (RingBuffer<T>)
		
	RingBuffer:
		Methods:
			function Push <T>(self: RingBuffer<T>, value: T): ()
			function GetNewest <T>(self: RingBuffer<T>): (T)
			function GetOldest <T>(self: RingBuffer<T>): (T)
			function IterateNewToOld <T>(r: RingBuffer<T>):
				( (buf: RingBuffer<T>, count: number) -> (number?, T), RingBuffer<T>, number )
			function IterateOldToNew <T>(r: RingBuffer<T>):
				( (buf: RingBuffer<T>, count: number) -> (number?, T), RingBuffer<T>, number )
		Properties:
			index: number
			size: number
			[number]: any
			
	Example:
		```luau
		local RingBuffer = require(path.to.RingBuffer)
		
		local buf = RingBuffer.new(3)
		buf:Push("a")
		buf:Push("b")
		buf:Push("c")
		
		print(buf:GetOldest(), buf:GetNewest()) --> a c
		```
]]--

--!strict

local RingBufferClass = {}

-- internal iteration functions, not intended for external use

local function iterNTO <T>(buf: RingBuffer<T>, count: number): (number?, T)
	local size = buf.size
	if count >= size then
		return nil, nil
	end
	
	return count + 1, buf[(buf.index - count) % size + 1] -- arrays are 1 based, so we need to offset by 1
end

local function iterOTN <T>(buf: RingBuffer<T>, count: number): (number?, T)
	local size = buf.size
	if count >= size then
		return nil, nil
	end

	return count + 1, buf[(buf.index + count) % size + 1] -- same as above, just flipped
end

RingBufferClass.interface = {
	--[[
		Returns a new, empty <code>RingBuffer</code>.
	]]
	new = function(size: number?): RingBuffer<any>
		size = size or 1
		
		local obj = table.create(size) :: {[any]: any} -- more efficient mem alloc avoiding resizing down the line
		obj.index = 0
		obj.size = size
		
		return setmetatable(obj, RingBufferClass.metatable)
	end,
	
	--[[
		Turns the given array <code>t</code> into a <code>RingBuffer</code> object and returns it.
	]]
	fromArray = function <T>(t: {T}): RingBuffer<T>
		-- typecasting any to allow creating properties without type errors
		(t :: any).index = 0
		(t :: any).size = math.min(table.maxn(t), 1)
		
		return setmetatable(t :: {[any]: any}, RingBufferClass.metatable)
	end,
}

RingBufferClass.schema = {
	--[[
		Pushes the given value onto the RingBuffer and updating the index.
	]]
	Push = function <T>(self: RingBuffer<T>, value: T)
		local index = (self.index % self.size) + 1
		self.index = index
		self[index] = value
	end,
	
	--[[
		Returns the newest value in the given RingBuffer.
	]]
	GetNewest = function <T>(self: RingBuffer<T>): T
		return self[self.index]
	end,
	
	--[[
		Returns the oldest value in the given RingBuffer.
	]]
	GetOldest = function <T>(self: RingBuffer<T>): T
		return self[self.index % self.size + 1]
	end,
	
	--[[
		Returns an iterator function and the provided RingBuffer for use in a <code>for</code> loop.
	]]
	IterateNewToOld = function <T>(self: RingBuffer<T>): ((RingBuffer<T>, number) -> (number?, T), RingBuffer<T>, number)
		return iterNTO, self, 0
	end,
	
	--[[
		Returns an iterator function and the provided RingBuffer for use in a <code>for</code> loop.
	]]
	IterateOldToNew = function <T>(self: RingBuffer<T>): ((RingBuffer<T>, number) -> (number?, T), RingBuffer<T>, number)
		return iterOTN, self, 0
	end,
}

RingBufferClass.metatable = {
	__index = RingBufferClass.schema,
}

export type RingBuffer<T> = typeof(RingBufferClass.schema) & {
	index: number,
	size: number,
	[number]: T
}

return RingBufferClass.interface
