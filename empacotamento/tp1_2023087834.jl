using JuMP, Gurobi

mutable struct EmpacotamentoData
    objetos::Int64           # n
    pesos::Array{Float64}      # w_i
    caixa_peso_maximo::Int64 # 20kg
end

function readData(file)
    objetos = 0
    pesos = []
    caixa_peso_maximo = 20

    for l in eachline(file)
        q = split(l, "	")
        if q[1] == "n"
            n = parse(Int64, q[2])
            objetos = n
            pesos = [0.00 for i = 1:n]
        elseif q[1] == "o" # descricao de objeto
            id = parse(Int64, q[2])
            peso = parse(Float64, q[3])

            pesos[id+1] = peso
        end
    end

    return EmpacotamentoData(objetos, pesos, caixa_peso_maximo)
end

model = Model(Gurobi.Optimizer)

file = open(ARGS[1], "r")

data = readData(file)

# C = nossa variavel de quantas caixas vamos pegar

@variable(model, c, Int)

@constraint(model, sum(data.pesos[i] for i = 1:data.objetos) <= c * data.caixa_peso_maximo)

@objective(model, Min, c)

optimize!(model)

sol = objective_value(model)
println("TP1 2023087834 = ", sol)
