using JuMP, Gurobi

mutable struct ColoringData
    n::Int
    ng::Vector{Vector{Int}} #neighbors
end


function readData(file)
    n = 0
    ng = [[]]
    for l in eachline(file)
        q = split(l, "	")
        if q[1] == "n"
            num_vertices = parse(Int64, q[2])
            n = num_vertices
            ng = [[] for i = 1:n]

        elseif q[1] == "e"
            u = parse(Int64, q[2])
            v = parse(Int64, q[3])

            push!(ng[u], v)
            push!(ng[v], u)
        end
    end

    return ColoringData(n, ng)
end

model = Model(Gurobi.Optimizer)

file = open(ARGS[1], "r")

data = readData(file)

@variable(model, y[1:data.n], Bin) # se a cor k foi usada. no maximo k cores parece ok. em que k = |V| = n
@variable(model, x[i=1:data.n, k=1:data.n], Bin) # x[i,k] = 1 sse o vertice I estiver na cor K

for i = 1:data.n
    for k = 1:data.n
        @constraint(model, x[i, k] <= y[k]) # so da pra usar cores que tao ativas
    end
end

for i = 1:data.n
    @constraint(model, sum(x[i, k] for k = 1:data.n) == 1) # tem que ter exatamente uma cor
end


for u = 1:data.n
    for v in data.ng[u]
        # vizinhos devem ter cor diferente
        # ou seja, para cada cor, a aresta so pode ter um vertice daquela cor; no maximo.
        for k in 1:data.n
            @constraint(model, x[u, k] + x[v, k] <= 1)
        end
    end
end

@objective(model, Min, sum(y[k] for k = 1:data.n))

optimize!(model)

sol = objective_value(model)
println("TP1 2023087834 = ", round(sol, digits=2))
