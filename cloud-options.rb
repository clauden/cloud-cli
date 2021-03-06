require 'cloud-constants'

def valid_type?(t)
  VM_TYPES.member? t
end

def valid_zone?(z)
  VM_ZONES.member? z
end

def usage
  msg = []

  msg << "Usage: #{$0} [--type <instance-type>] [--zone <datacenter-zone>] image-id"
  msg << "Launch a VM of type instance-type in datacenter-zone  based on image-id, where:"
  msg << "  instance-type is one of #{VM_TYPES.inspect}"
  msg << "  datacenter-zone is one of #{VM_ZONES.inspect}"
  msg << "  image-id is a valid image name (e.g. as listed by cloud-describe-images)"

  STDERR.puts msg.join("\n")
end

opts = GetoptLong.new(
  [ '--help', '-h', GetoptLong::NO_ARGUMENT ],
  [ '--type', '-t', GetoptLong::REQUIRED_ARGUMENT ],
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
  

