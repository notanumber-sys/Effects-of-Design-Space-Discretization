package main

import java.nio.file.Paths
import java.nio.file.Files
import java.util.stream.Collectors

import forsyde.io.java.core.ForSyDeSystemGraph;
import forsyde.io.java.core.Vertex;
import forsyde.io.java.drivers.ForSyDeModelHandler;
import org.antlr.v4.semantics.RuleCollector
import scala.jdk.CollectionConverters.*;

import breeze.linalg.max
import forsyde.io.java.core.VertexProperty
import scala.annotation.switch
import forsyde.io.java.typed.viewers.decision.results.AnalyzedActor

@main def evaluate(args: String*): Unit = 
  println("BEGIN")

  var data_source = args.length match
    case 0 => Paths.get("data")
    case _ => Paths.get(args(0))
  if !Files.isDirectory(data_source) then 
    println("SELECTED FILE DOES NOT EXIST")
    return

  var handler = ForSyDeModelHandler()
  for p <- Files.list(data_source).collect(Collectors.toList()).asScala do
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
  val jopt = AnalyzedActor.safeCast(a).map(al => {
    al.getThroughputInSecsNumerator().toDouble/al.getThroughputInSecsDenominator().toDouble
  })
  if jopt.isPresent() then Some(jopt.get()) else None

def analyze(graph: ForSyDeSystemGraph): Option[Double] =
  // finds all actors with throughput property
  graph.vertexSet().stream().map(getThroughput(_)).filter(_.isDefined).map(_.get)
      .collect(Collectors.toList()).asScala.reduceLeftOption(_ min _)
