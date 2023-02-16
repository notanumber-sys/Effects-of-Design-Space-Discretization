import forsyde.io.java.core.ForSyDeSystemGraph;
import forsyde.io.java.core.Vertex;
import forsyde.io.java.drivers.ForSyDeModelHandler;
import org.antlr.v4.semantics.RuleCollector
import scala.jdk.CollectionConverters.*;
import breeze.linalg.max

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

def getDoubleProp(a: Vertex, name: String) = a.getProperties().get(name).unwrap().asInstanceOf[Long].toDouble

def analyze(graph: ForSyDeSystemGraph): Double =
  var actors: Seq[Vertex] = graph.vertexSet().stream()
      .filter(v => v.getProperties().get("throughputInSecsNumerator") != null)
      .toList().asScala.toList
  actors.map(a => getDoubleProp(a, "throughputInSecsNumerator")/getDoubleProp(a, "throughputInSecsDenominator")).min
