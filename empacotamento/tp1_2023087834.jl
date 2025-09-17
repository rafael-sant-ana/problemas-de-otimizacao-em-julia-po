using JuMP
using HiGHS

mutable struct EmpacotamentoData 
  objetos::Int
  pesos::Array{Int}
  caixa_peso_maximo::Int
end

function readData(file)
  objetos = 0
  pesos = []
  caixa_peso_maximo = 20
  print(file)

  for l in eachline(file)
    q = split(l, " ")
    if q[1] == "n"
      n = parse(Int64, q[2])
      objetos = n
    end
    if q[1] == "o" # descricao de objeto
      id = parse(Int64, q[2])
      preco = parse(Float64, q[3])

      pesos[id] = preco
    end
  end

  return EmpacotamentoData(objetos, pesos, caixa_peso_maximo)
end

model = Model(HiGHS.Optimizer)

file = open(ARGS[1], "r")

data = readData(file)

print(data)
# C = nossa variavel de quantas caixas vamos pegar

@variable(model, c, Int)

@constraint(model, sum(data.pesos[i] for i=1:data.objetos) <= c*data.caixa_peso_maximo)

@objective(model, Min, c)

print(model)

optimize!(model)

sol = objective_value(model)
println("Valor otimo= ", sol)



