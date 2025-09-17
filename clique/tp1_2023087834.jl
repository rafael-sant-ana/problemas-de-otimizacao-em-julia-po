using JuMP, HiGHS

mutable struct CliqueData
    vertices::Int;
    edges::Vector{Tuple{Int, Int}}

    comp_edges::Vector{Tuple{Int, Int}}
end


function readData(file)
    vertices = 0
    edges = []
    for l in eachline(file)
        q = split(l, " ")
        if q[1] == "n"
            n = parse(Int64, q[2])
            vertices=n

        elseif q[1] == "e"
            push!(edges, (parse(Int64, q[2]), parse(Int64, q[3])))
        end
    end
end

model = Model(HiGHS.Optimizer)

file = open(ARGS[1], "r")

data = readData(file)



optimize!(model)

sol = objective_value(model)

println(sol)
