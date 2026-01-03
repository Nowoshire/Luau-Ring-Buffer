--[[
	- RingBuffer -
	Implements a ring buffer data structure in Luau.
	Provides convenient push/get operators and iterators.

	Licensed under the MIT License:
		https://github.com/Nowoshire/Luau-Float-Precision/blob/main/LICENSE

		MIT License
		
		Copyright (c) 2025-2026 Nowoshire
		
		Permission is hereby granted, free of charge, to any person obtaining a copy
		of this software and associated documentation files (the "Software"), to deal
		in the Software without restriction, including without limitation the rights
		to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
		copies of the Software, and to permit persons to whom the Software is
		furnished to do so, subject to the following conditions:
		
		The above copyright notice and this permission notice shall be included in all
		copies or substantial portions of the Software.
		
		THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
		IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
		FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
		AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
		LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
		OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
		SOFTWARE.
		
	Library:
		Constructors:
			-- Returns a new RingBuffer populated with many instances of the specified value.
			function create <V>(count: number, value: V?): (RingBuffer<V>)
			
			-- Converts the given array <code>t</code> into a <code>RingBuffer</code> object and returns it.
			function fromArray <V>(t: {V}): (RingBuffer<V>)
			
		Operators:
			-- Pushes the given value onto the given RingBuffer and updating the index.
			function push <V>(r: RingBuffer<V>, value: V): ()
			
			-- Returns the newest value in the given RingBuffer.
			function getNewest <V>(r: RingBuffer<V>): (V)
			
			-- Returns the oldest value in the given RingBuffer.
			function getOldest <V>(r: RingBuffer<V>): (V)
			
			-- Returns an iterator function and the provided RingBuffer for use in a for loop.
			-- NOTE: The number returned from the iterator function is the iteration count, not the index of the value in the RingBuffer.
			function iterateNewToOld <V>(r: RingBuffer<V>):
				( (buf: RingBuffer<V>, count: number) -> (number?, V), RingBuffer<V>, number )
				
			-- Returns an iterator function and the provided RingBuffer for use in a for loop.
			-- NOTE: The number returned from the iterator function is the iteration count, not the index of the value in the RingBuffer.
			function iterateOldToNew <V>(r: RingBuffer<V>):
				( (buf: RingBuffer<V>, count: number) -> (number?, V), RingBuffer<V>, number )
				
	RingBuffer:
		Properties:
			index: number		-- The index of the last push operation
			size: number		-- The size of the RingBuffer
			[number]: any		-- The array portion of the RingBuffer
			
	Example:
		```luau
		local RingBuffer = require(path.to.RingBuffer)
		
		local buf = RingBuffer.create(5) :: RingBuffer.RingBuffer<string>
		RingBuffer.push(buf, "a")
		RingBuffer.push(buf, "b")
		RingBuffer.push(buf, "c")
		
		print(RingBuffer.getOldest(buf), RingBuffer.getNewest(buf)) --> a c
		```
]]--

--!strict

local RingBufferLib = {}

export type RingBuffer<V> = {
	[number]: V,
	index: number,
	size: number
}

-- Internal Iteration Functions --
-- not meant for external use!

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

-- Interface Functions --

--[[
	Returns a new <code>RingBuffer</code> populated with many instances of the specified value.
]]
function RingBufferLib.create <V>(count: number, value: V?): RingBuffer<V>
	local obj = table.create(count, value) :: RingBuffer<V>
	obj.index = 0
	obj.size = count

	return obj
end

--[[
	Converts the given array <code>t</code> into a <code>RingBuffer</code> object and returns it.
]]
function RingBufferLib.fromArray <T>(t: {T}): RingBuffer<T>
	-- refine t as a RingBuffer for convenience, compiler will optimize and remove this from bytecode
	t = t :: RingBuffer<T>
	
	t.index = 0
	t.size = math.max(table.maxn(t), 1)
	
	return t
end

-- Operator Functions --

--[[
	Pushes the given value onto the given <code>RingBuffer</code> and updating the index.
]]
function RingBufferLib.push <V>(r: RingBuffer<V>, value: V)
	local index = (r.index % r.size) + 1
	r.index = index
	r[index] = value
end

--[[
	Returns the newest value in the given <code>RingBuffer</code>.
]]
function RingBufferLib.getNewest <V>(r: RingBuffer<V>): V
	return r[r.index]
end

--[[
	Returns the oldest value in the given <code>RingBuffer</code>.
]]
function RingBufferLib.getOldest <V>(r: RingBuffer<V>): V
	return r[r.index % r.size + 1]
end

--[[
	Returns an iterator function and the provided <code>RingBuffer</code> for use in a <code>for</code> loop.
	
	<strong>Note:</strong> The number returned from the iterator function is the iteration count, not the index of the value in the RingBuffer.
]]
function RingBufferLib.iterateNewToOld <V>(r: RingBuffer<V>): ((RingBuffer<V>, number) -> (number?, V), RingBuffer<V>, number)
	return iterNTO, r, 0
end

--[[
	Returns an iterator function and the provided <code>RingBuffer</code> for use in a <code>for</code> loop.
	
	<strong>Note:</strong> The number returned from the iterator function is the iteration count, not the index of the value in the RingBuffer.
]]
function RingBufferLib.iterateOldToNew <V>(r: RingBuffer<V>): ((RingBuffer<V>, number) -> (number?, V), RingBuffer<V>, number)
	return iterNTO, r, 0
end

return RingBufferLib
