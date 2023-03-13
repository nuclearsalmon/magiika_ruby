#!/usr/bin/env ruby


module Utils
  BN = 1000000000.0
  
  def round_float(value)
    value = (value*BN).round / BN if value != value.to_i
    return value
  end
  module_function :round_float

  def normalize_bin_arr_len(arr1, arr2)
    longest = [arr1.length, arr2.length].max
    return [0]*(longest - arr1.length) + arr1, 
      [0]*(longest - arr2.length) + arr2
  end
  module_function :normalize_bin_arr_len

  def unsign(obj)
    return obj.pack("C*").unpack("C*")
  end
  module_function :unsign
end
