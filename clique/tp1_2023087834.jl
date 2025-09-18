using JuMP, HiGHS

mutable struct CliqueData
    n::Int;
    ng::Vector{Vector{Int}} #neighbors
    
    comp_ng::Vector{Vector{Int}} # complementary neighbors
end


function readData(file)
    n = 0
    ng = [[]]
    comp_ng = [[]]
    for l in eachline(file)
        q = split(l, "	")
        if q[1] == "n"
            num_vertices = parse(Int64, q[2])
            n=num_vertices
            ng = [[] for i = 1:n]
            comp_ng = [[] for i=1:n]

        elseif q[1] == "e"
            u = parse(Int64, q[2])
            v = parse(Int64, q[3])

            push!(ng[u], v)
            push!(ng[v], u)
        end
    end

    for i = 1:n
        for j = 1:n
            if i != j && (!(j in ng[i]))
                push!(comp_ng[i], j)
            end
        end
    end

    return CliqueData(n, ng, comp_ng)
end

model = Model(HiGHS.Optimizer)

file = open(ARGS[1], "r")

data = readData(file)

@variable(model, x[1:data.n], Bin)

for u = 1:data.n
    for v in data.comp_ng[u]
        @constraint(model, x[u] + x[v] <= 1)
    end
end

@objective(model, Max, sum(x[i] for i=1:data.n))

optimize!(model)

sol = objective_value(model)

println(sol)
println("Clique vertices: ", [i for i in 1:data.n if value(x[i]) > 0.5])
