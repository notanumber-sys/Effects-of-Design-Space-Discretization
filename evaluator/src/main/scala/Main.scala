import forsyde.io.java.core.ForSyDeSystemGraph;
import forsyde.io.java.drivers.ForSyDeModelHandler;

val data_root = "C:\\Users\\u087044\\Documents\\sf250X-thesis\\evaluator\\data"
val sources: Array[String] = Array(
  "all_and_bus_small_result.fiodl",
  "sobel_and_bus_small_result.fiodl"
)

@main def hello: Unit = 
  println("BEGIN")
  
  var handler = ForSyDeModelHandler()
  for(s <- sources) {
    var path = data_root + "\\" + s
    var graph: ForSyDeSystemGraph = handler.loadModel(path)

    println(s + ": " + analyze(graph))
  }

  println("END")

def analyze(graph: ForSyDeSystemGraph): Double =
  10.1

