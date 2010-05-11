require 'rubygems'
require 'open4'
require 'getoptlong'

require File.join(File.dirname(__FILE__), 'cloud-exceptions')
require File.join(File.dirname(__FILE__), 'cloud-validation')
require File.join(File.dirname(__FILE__), 'cloud-generate-compute-template')

# 
# invoke remote ONE command
#

def usage
  msg = []

  msg << "Usage: #{$0} [--type <instance-type>] [--zone <datacenter-zone>] [--notify <email>] image-id"
  msg << "Launch a VM of type instance-type in datacenter-zone  based on image-id, where:"
  msg << "  instance-type is one of #{VM_TYPES.inspect}"
  msg << "  datacenter-zone is one of #{VM_ZONES.inspect}"
  msg << "  image-id is a valid image name (e.g. as listed by cloud-describe-images)"
  msg << "  email is an address for lifecycle event notifications (NOT IMPLEMENTED)"
  msg << " "
  msg << "For now, instance-type is passed through directly to 'occi-compute create'."

  STDERR.puts msg.join("\n")
end


def parse_opts
  opts = GetoptLong.new(
    [ '--help', '-h', GetoptLong::NO_ARGUMENT ],
    [ '--type', '-t', GetoptLong::REQUIRED_ARGUMENT ],
    [ '--notify', '-n', GetoptLong::REQUIRED_ARGUMENT ],
    [ '--zone', '-z', GetoptLong::REQUIRED_ARGUMENT ]
  )

  begin
    opts.each do |opt, arg|
      case opt
        when '--help'
          puts usage
          exit 0
        when '--type'
          @vmtype = arg.downcase
          raise InvalidVMType if not valid_type? @vmtype
        when '--zone'
          @zone = arg.downcase
          raise InvalidVMZone if not valid_zone? @zone
        when '--notify'
          @notify = arg.downcase
      end
    end
  rescue GetoptLong::InvalidOption 
      usage
      exit 1
  rescue GetoptLong::MissingArgument
      usage
      exit 2
  rescue InvalidVMType
    STDERR.puts "Unknown VM type '#{@vmtype}'"
    usage
    exit 3
  rescue InvalidVMZone
    STDERR.puts "Unknown datacenter zone '#{@zone}'"
    usage
    exit 3
  end
    
  @imageid = ARGV.shift
  if not @imageid
    STDERR.puts "Missing image identifier"
    usage
    exit 4
  end
end

class ExecCmdFailed < RuntimeError
  attr_reader :status, :errs
  def initialize(status, errs)
    @status = status
    @errs = errs
    super
  end
end

# raises if exit code != 0
# returns { :stdout, :stderr }
def exec_cmd(cmd)
  _stdout = _stderr = nil
  _status = Open4::popen4(cmd) do |pid, stdin, stdout, stderr|
    _stdout = stdout.read.strip
    _stderr = stderr.read.strip
  end
  raise ExecCmdFailed.new(_status.exitstatus, _stderr) if _status.exitstatus != 0
  { :stdout => _stdout, :stderr => _stderr }
end


# connect via ssh
# run command
# interpret output

TMPDIR = "/tmp"
remote_host = "garden"

if $0 == __FILE__
  parse_opts

  # compose xml descriptor based on opts
  docid, doc = generate_compute(@vmtype, @imageid)
  fn = "#{TMPDIR}/#{docid}"
  File.open(fn, "w") { |f| f.write(doc) }

  # send it on over to the ONE master
  cmd = "scp #{fn} #{remote_host}:#{fn}"
  puts cmd
  puts "press any key to continue"
  STDIN.getc
  
  rv = {}
  begin
    rv = exec_cmd(cmd)
  rescue ExecCmdFailed => x
    puts "scp returned #{x.status}: #{x.errs}"
    exit 1
  end
  
  cmd = "ssh #{remote_host} occi-compute create #{fn}"
  puts cmd
  puts "press any key to continue"
  STDIN.getc
  
  rv = {}
  begin
    rv = exec_cmd(cmd)
  rescue ExecCmdFailed => x
    puts "ssh returned #{x.status}: #{x.errs}"
    exit 1
  end

  puts rv[:stdout]
  
end
