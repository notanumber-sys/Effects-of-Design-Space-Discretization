val scala3Version = "3.2.2"

lazy val forsydeIoVersion  = "0.5.17"
lazy val jgraphtVersion    = "1.5.1"
lazy val scribeVersion     = "3.10.2"
lazy val breezeVersion     = "2.1.0"
lazy val scalaGraphVersion = "1.13.5"

ThisBuild / assembly / assemblyMergeStrategy := {
  case PathList("META_INF", xs @ _*) => MergeStrategy.discard
  case _ => MergeStrategy.first
}

lazy val root = project
  .in(file("."))
  .settings(
    name := "evaluator",
    version := "0.1.0-SNAPSHOT",

    scalaVersion := scala3Version,

    Compile / mainClass := Some("evaluator.Main"),
    assembly / assemblyJarName := "evaluator.jar",

    libraryDependencies ++= Seq(
      ("org.scala-graph" %% "graph-core"   % scalaGraphVersion).cross(CrossVersion.for3Use2_13),
      "org.scalameta" %% "munit" % "0.7.29" % Test,
      "org.jgrapht"       % "jgrapht-core" % jgraphtVersion,
      "org.jgrapht"       % "jgrapht-opt"  % jgraphtVersion,
      "org.scalanlp"     %% "breeze"       % breezeVersion,
      "com.outr"         %% "scribe"       % scribeVersion,
      "io.github.forsyde" % "forsyde-io-java-core" % forsydeIoVersion,
      "io.github.forsyde" % "forsyde-io-java-amalthea" % forsydeIoVersion,
      "io.github.forsyde" % "forsyde-io-java-sdf3"     % forsydeIoVersion,
      "io.github.forsyde" % "forsyde-io-java-graphviz" % forsydeIoVersion,
      "org.jgrapht"       % "jgrapht-core"         % jgraphtVersion,
      "org.jgrapht"       % "jgrapht-opt"          % jgraphtVersion,
      "org.typelevel"    %% "spire"                % "0.18.0"
    )
  )

