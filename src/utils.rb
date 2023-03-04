#!/usr/bin/env ruby

def normalize_bin_arr_len(arr1, arr2)
  longest = [arr1.length, arr2.length].max
  return [0]*(longest - arr1.length) + arr1, 
    [0]*(longest - arr2.length) + arr2
end

def unsign(obj)
  return obj.pack("C*").unpack("C*")
end
