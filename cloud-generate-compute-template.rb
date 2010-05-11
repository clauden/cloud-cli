require 'rubygems'
require 'uuidtools'
require 'erb'

#
# generate an OCCI compute template based on requirements
#

COMPUTE_TEMPLATE = "compute.erb"

#
# this is reallly simplistic!
#
def generate_compute(compute_instancetype, compute_imageid)
  compute_instancename = UUIDTools::UUID.random_create
  raw_template = ""
  File.open(COMPUTE_TEMPLATE) { |f| raw_template = f.readlines }
  template = ERB.new(raw_template.join("\n"))
  return [compute_instancename, template.result(binding)]
end

# puts generate_compute("centos_large", "14")
