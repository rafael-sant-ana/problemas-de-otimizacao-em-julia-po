using JuMP, Gurobi

# Estrutura para armazenar o grafo
mutable struct GraphData
    n::Int
    edges::Vector{Tuple{Int,Int}}
    neighbors::Vector{Vector{Int}}
end

# Função para ler o grafo
function readData(file)
    n = 0
    edges = Tuple{Int,Int}[]
    neighbors = Vector{Vector{Int}}()

    for l in eachline(file)
        q = split(l)
        if q[1] == "n"
            n = parse(Int, q[2])
            neighbors = [Int[] for _ in 1:n]

        elseif q[1] == "e"
            u = parse(Int, q[2])
            v = parse(Int, q[3])
            push!(edges, (u, v))
            push!(neighbors[u], v)
            push!(neighbors[v], u)
        end
    end

    return GraphData(n, edges, neighbors)
end

file = open(ARGS[1], "r")

data = readData(file)

n = data.n
model = Model(Gurobi.Optimizer)

@variable(model, x[1:n, 1:n], Bin)

@variable(model, y[1:n], Bin)

@constraint(model, [v = 1:n], sum(x[v, c] for c in 1:n) == 1)

for (u, v) in data.edges
    for c in 1:n
        @constraint(model, x[u, c] + x[v, c] <= 1) # coloração normal: uma aresta deve ter cores diferentes nos extremos
    end
end

@constraint(model, [c = 1:n, v = 1:n], x[v, c] <= y[c]) # coloração normal: só podemos colorir se a cor for selecionada

# Esse z[c,d,v,u] := o vértice v tem cor c e o vértice u tem cor d, com u em N(v)
@variable(model, z[1:n, 1:n, 1:n, 1:n], Bin)

# A coloração
for c in 1:n, d in 1:n
    if c != d
        for v in 1:n, u in data.neighbors[v]
            @constraint(model, z[c, d, v, u] <= x[v, c]) #o vértice v só pode ter cor c se x[v,c] == 1 (se escolhemos a cor c para v)
            @constraint(model, z[c, d, v, u] <= x[u, d]) # o vértice u só pode ter cor d se x[u, d] == 1 (se escolhemos a cor d para u)

            # Nesse estágio, z[c,d,v,u] vai poder ser no máximo 1. e esse upper bound só é permitido se a cor de v é c, e a cor de u é d
            # Agora, precisamos colocar um lower bound para garantir que z[c,d,v,u] seja 1 sse x[v,c] == 1 e x[u,d] == 1
            #
            @constraint(model, z[c, d, v, u] >= x[v, c] + x[u, d] - 1) # agora colocamos um lower bound
            # pra entender essa restrição fica mais facil em casos
            # 1) x[v,c] == 1 e x[u, d] == 1. nesse caso, z[c,d,v,u] tem que ser igual a 1. porque é verdade que v tem cor c e u tem cor d
            # 2) x[v,c] == 1 e x[u,d] == 0 ou vice-versa. nesse caso, z[c,d,v,u] tem que ser 0, porque não é verdade que v tem cor c e u tem cor d
        end
    end
end

# Condição de A-coloração: se cor c usada, ela deve "ver" cada outra cor d
for c in 1:n, d in 1:n
    if c != d
        @constraint(model, y[c] + y[d] - 1 <= sum(z[c, d, v, u] for v in 1:n, u in data.neighbors[v]))
    end
end

# Objetivo: maximizar número de cores
@objective(model, Max, sum(y[c] for c in 1:n))

optimize!(model)

println("TP1 2023087834 = ", objective_value(model))
