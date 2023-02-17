import forsyde.io.java.core.ForSyDeSystemGraph;
import forsyde.io.java.core.Vertex;
import forsyde.io.java.drivers.ForSyDeModelHandler;
import org.antlr.v4.semantics.RuleCollector
import scala.jdk.CollectionConverters.*;

import breeze.linalg.max
import forsyde.io.java.core.VertexProperty

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

def getDoubleProp(a: Vertex, name: String): Option[Double] =
  var prop: Option[VertexProperty] = a.getProperties().get(name) match
    case p: VertexProperty => Some(p)
    case null => None
  try
    prop.map(_.unwrap()).map(_.asInstanceOf[Long].toDouble)
  catch
    case e: ClassCastException => None

def getThroughput(a: Vertex): Option[Double] =
  // if numerator exist, we assume that denominator also exists
  getDoubleProp(a, "throughputInSecsNumerator").map(_/getDoubleProp(a, "throughputInSecsDenominator").get)

def analyze(graph: ForSyDeSystemGraph): Option[Double] =
  // finds all actors with throughput property
  graph.vertexSet().stream().map(getThroughput(_)).filter(_.isDefined).map(_.get)
      .toList().asScala.reduceLeftOption(_ min _)
