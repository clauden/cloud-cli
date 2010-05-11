require File.join(File.dirname(__FILE__), 'cloud-constants')

def valid_type?(t)
  VM_TYPES.member? t
end

def valid_zone?(z)
  VM_ZONES.member? z
end


