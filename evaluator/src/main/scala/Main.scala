import java.nio.file.Paths
import java.nio.file.Files

import forsyde.io.java.core.ForSyDeSystemGraph;
import forsyde.io.java.core.Vertex;
import forsyde.io.java.drivers.ForSyDeModelHandler;
import org.antlr.v4.semantics.RuleCollector
import scala.jdk.CollectionConverters.*;

import breeze.linalg.max
import forsyde.io.java.core.VertexProperty
import scala.annotation.switch

@main def evaluate(args: String*): Unit = 
  println("BEGIN")

  var data_source = args.length match
    case 0 => Paths.get("data")
    case _ => Paths.get(args(0))
  if !Files.isDirectory(data_source) then 
    println("SELECTED FILE DOES NOT EXIST")
    return

  var handler = ForSyDeModelHandler()
  for p <- Files.list(data_source).toList().asScala do
    val graph: ForSyDeSystemGraph = handler.loadModel(p)
    println(p.getFileName().toString() + ": " + analyze(graph).get)

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
