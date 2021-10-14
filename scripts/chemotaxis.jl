@everywhere begin
    using DrWatson
    import JSON
    using Logging
    using HDF5
    using PWS
end

f = ARGS[1]
dict = JSON.parsefile(projectdir("_research", "tmp", f))
@info "Read file" file = projectdir("_research", "tmp", f)

run_name = dict["run_name"]
duration = dict["duration"]
num_responses = dict["num_responses"]

mean_L = dict["mean_L"]
num_receptors = dict["num_receptors"]
Y_tot = dict["Y_tot"]

LR_timescale = dict["LR_timescale"]
Y_timescale = dict["Y_timescale"]

dtimes = collect(0.0:0.04:duration)

system_fn = () -> PWS.chemotaxis_system(
    mean_L = mean_L,
    num_receptors = num_receptors,
    Y_tot = Y_tot,
    LR_timescale = LR_timescale,
    Y_timescale = Y_timescale,
    dtimes = dtimes,
    Y_ratio = 1/6,
    LR_ratio = 0.5
)

algorithm = SMCEstimate(dict["smc_samples"])

mi = PWS.run_parallel(system_fn, algorithm, num_responses)
result = Dict("Samples" => mi, "DiscreteTimes" => dtimes)

function DrWatson._wsave(filename, result::Dict)
    h5open(filename, "w") do file
        PWS.write_hdf5!(file, result)
    end
end

save_dict = Dict("Duration" => duration, "TauLR" => LR_timescale, "TauY" => Y_timescale)

filename = savename(save_dict, "hdf5")
local_path = datadir("chemotaxis", run_name, filename)
tagsave(local_path, merge(dict, result), storepatch=false)
@info "Saved to" filename

# upload to SUN storage

# include("smbclient.jl")
# sun_path = joinpath(sun_home, "data", "chemotaxis", run_name, filename)
# mkpath(dirname(sun_path))
# cp(local_path, sun_path)
