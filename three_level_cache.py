import m5

from m5.objects import *
from gem5.runtime import get_runtime_isa

m5.util.addToPath("../../")

# from caches import *
from caches_level import *

from common import SimpleOpts

thispath = os.path.dirname(os.path.realpath(__file__))
default_binary = os.path.join(
    thispath,
    "../../../",
    "tests/test-progs/hello/bin/x86/linux/hello",
)

SimpleOpts.add_option("binary", nargs="?", default=default_binary)

args = SimpleOpts.parse_args()


# binary = 'configs/learning_gem5/part1/benchmarks/BFS'
# binary = 'configs/learning_gem5/part1/benchmarks/queens'
# binary = 'configs/learning_gem5/part1/benchmarks/sha'
# binary = 'configs/learning_gem5/part1/benchmarks/blocked-matmul'

if args.binary:
    binary = args.binary

# Check if there was a binary passed in via the command line and error if
# there are too many arguments
# if len(args) == 1:
#     binary = args[0]
# elif len(args) > 1:
#     SimpleOpts.print_help()
#     m5.fatal("Expected a binary to execute as positional argument")

binary_algo = binary.split('/')[-1]

system = System()

system.clk_domain = SrcClockDomain()
system.clk_domain.clock = "1GHz"
system.clk_domain.voltage_domain = VoltageDomain()

system.mem_mode = "timing"  # Use timing accesses
system.mem_ranges = [AddrRange("512MB")]  # Create an address range

# Create a simple CPU
system.cpu = X86TimingSimpleCPU()

# Create an L1 instruction and data cache
system.cpu.icache = L1ICache(args)
system.cpu.dcache = L1DCache(args)

# Connect the instruction and data caches to the CPU
system.cpu.icache.connectCPU(system.cpu)
system.cpu.dcache.connectCPU(system.cpu)

# Create a memory bus, a coherent crossbar, in this case
system.l2bus = L2XBar()
system.l3bus = L2XBar()

# Hook the CPU ports up to the l2bus
system.cpu.icache.connectBus(system.l2bus)
system.cpu.dcache.connectBus(system.l2bus)

# Create an L2 cache and connect it to the l2bus
system.l2cache = L2Cache(args)
system.l2cache.connectCPUSideBus(system.l2bus)

#Create an L3 cache and connect it to the l2bus
system.l3cache = L3Cache(args)
system.l3cache.connectCPUSideBus(system.l3bus)

# Create a memory bus
system.membus = SystemXBar()

# Connect the L2 cache to the membus
system.l2cache.connectMemSideBus(system.l3bus)
system.l3cache.connectMemSideBus(system.membus)

# create the interrupt controller for the CPU
system.cpu.createInterruptController()
system.cpu.interrupts[0].pio = system.membus.mem_side_ports
system.cpu.interrupts[0].int_requestor = system.membus.cpu_side_ports
system.cpu.interrupts[0].int_responder = system.membus.mem_side_ports

# Connect the system up to the membus
system.system_port = system.membus.cpu_side_ports

# Create a DDR3 memory controller
system.mem_ctrl = MemCtrl()
system.mem_ctrl.dram = DDR3_1600_8x8()
system.mem_ctrl.dram.range = system.mem_ranges[0]
system.mem_ctrl.port = system.membus.mem_side_ports

system.workload = SEWorkload.init_compatible(args.binary)

# Create a process for a simple "Hello World" application
process = Process()
# Set the command
# cmd is a list which begins with the executable (like argv)
# process.cmd = [args.binary]
# process.cmd = [binary, 'configs/learning_gem5/part1/benchmarks/inputs/RL3k.graph']
# process.cmd = [binary, '-c', 10] 
# process.cmd = [binary, 'configs/learning_gem5/part1/benchmarks/inputs/example-sha-input.txt']
process.cmd = [binary]
# Set the cpu to use the process as its workload and create thread contexts
if args.binary:
    if binary_algo == 'queens':
        process.cmd = [binary, '-c', 12]
    if binary_algo == 'sha':
        process.cmd = [binary, 'configs/learning_gem5/part1/benchmarks/inputs/example-sha-input.txt']
    if binary_algo == 'BFS':
        process.cmd = [binary, 'configs/learning_gem5/part1/benchmarks/inputs/RL5k.graph']
    if binary_algo == 'blocked-matmul':
        process.cmd = [binary]

system.cpu.workload = process
system.cpu.createThreads()

# set up the root SimObject and start the simulation
root = Root(full_system=False, system=system)
# instantiate all of the objects we've created above
m5.instantiate()

print("Beginning simulation!")
exit_event = m5.simulate()
print("Exiting @ tick %i because %s" % (m5.curTick(), exit_event.getCause()))
