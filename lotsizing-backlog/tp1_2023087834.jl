using JuMP, HiGHS

mutable struct LotsizingData
    n::Int;
    c::Vector{Int} # custos de producao
    d::Vector{Int} # demandas
    p::Vector{Int} # Custos de atrasos
    s::Vector{Int} # Custo de armazenar do tempo i pro tempo i+1
end


function readData(file)
    n = 0
    c = []
    d = []
    p = []
    s = []
    for l in eachline(file)
        q = split(l, "	")
        if q[1] == "n"
            num_vertices = parse(Int64, q[2])
            n=num_vertices
            c = [0 for i = 1:n]
            d = [0 for i = 1:n]
            p = [0 for i = 1:n]
            s = [0 for i = 1:n]

        elseif q[1] == "c"
            id = parse(Int64, q[2])
            val = parse(Int64, q[3])

            c[id] = val
        elseif q[1] == "d"
          id = parse(Int64, q[2])
          val = parse(Int64, q[3])

          d[id] = val

        elseif q[1] == "s"
          id = parse(Int64, q[2])
          val = parse(Int64, q[3])

          s[id] = val
        elseif q[1] == "p"
          id = parse(Int64, q[2])
          val = parse(Int64, q[3])

          p[id] = val
        end
    end

    return LotsizingData(n, c, d, p, s)
end

model = Model(HiGHS.Optimizer)

file = open(ARGS[1], "r")

data = readData(file)

@variable(model, prod[i=1:data.n] >= 0)    # quanto foi produzido
@variable(model, est[i=0:data.n+1] >= 0)   # quanto foi estocado
@variable(model, backlog[i=0:data.n+1] >= 0) # demanda q n foi comprida

for i=1:data.n
  @constraint(model, est[i] - backlog[i] == est[i-1] - backlog[i-1] + prod[i] - data.d[i])
end

@constraint(model, est[0] == 0)     #comecamos zerados
@constraint(model, backlog[0] == 0) #comecamos zerados
@constraint(model, est[data.n] == 0)     #terminamos sem estoque
@constraint(model, backlog[data.n] == 0) #e sem dever nd

@objective(
  model,
  Min,
  sum(
    prod[i]*data.c[i]
    + est[i]*data.s[i]
    + backlog[i]*data.p[i]
    for i=1:data.n
  )
)

optimize!(model)

sol = objective_value(model)

println(sol)

# for i = 1:data.n
#   println("Producao periodo ", i, " = ", value(prod[i]))
# end
