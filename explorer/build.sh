#!/bin/sh
set -e

EXPLORER_BRANCH=master

echo "Fetching explorer-backend ${EXPLORER_BRANCH} branch"
curl -L https://github.com/ergoplatform/explorer-backend/archive/refs/heads/${EXPLORER_BRANCH}.tar.gz > explorer-backend.tar.gz

echo "Extracting explorer source"
rm -rf explorer-backend-${EXPLORER_BRANCH}
tar -xf explorer-backend.tar.gz
rm explorer-backend.tar.gz

echo "Preparing Dockerfiles"
cp explorer-backend-${EXPLORER_BRANCH}/modules/chain-grabber/Dockerfile explorer-backend-${EXPLORER_BRANCH}/chain-grabber.Dockerfile
cp explorer-backend-${EXPLORER_BRANCH}/modules/explorer-api/Dockerfile explorer-backend-${EXPLORER_BRANCH}/explorer-api.Dockerfile
cp explorer-backend-${EXPLORER_BRANCH}/modules/utx-broadcaster/Dockerfile explorer-backend-${EXPLORER_BRANCH}/utx-broadcaster.Dockerfile
cp explorer-backend-${EXPLORER_BRANCH}/modules/utx-tracker/Dockerfile explorer-backend-${EXPLORER_BRANCH}/utx-tracker.Dockerfile

echo "Fixing deprecated OpenJDK base images"
sed -i.bak 's|FROM openjdk:8-jre-slim|FROM eclipse-temurin:8-jre|g' explorer-backend-${EXPLORER_BRANCH}/*.Dockerfile
rm -f explorer-backend-${EXPLORER_BRANCH}/*.Dockerfile.bak

echo "Fixing broken SNAPSHOT dependencies"
sed -i.bak 's|v3.3.8-aaaab5ef-SNAPSHOT|3.3.7|g' explorer-backend-${EXPLORER_BRANCH}/project/versions.scala
sed -i.bak 's|4.0.6-31-e2e0ffa1-SNAPSHOT|4.0.7|g' explorer-backend-${EXPLORER_BRANCH}/project/dependencies.scala
rm -f explorer-backend-${EXPLORER_BRANCH}/project/*.bak

echo "Fixing incompatible PrettyPrintErgoTree API"
cat > explorer-backend-${EXPLORER_BRANCH}/modules/explorer-api/src/main/scala/org/ergoplatform/explorer/http/api/v1/models/PrettyErgoTree.scala << 'PATCHEOF'
package org.ergoplatform.explorer.http.api.v1.models

import org.ergoplatform.explorer.HexString
import sigmastate.lang.exceptions.SerializerException
import sigmastate.serialization.ErgoTreeSerializer.DefaultSerializer

object PrettyErgoTree {
  def fromString(s: String) : Either[PrettyErgoTreeError, ErgoTreeHuman] = {
    HexString.fromString[Either[Throwable, *]](s) match {
      case Left(_) => Left(PrettyErgoTreeError.BadEncoding)
      case Right(hexString) => fromHexString(hexString)
    }
  }

  def fromHexString(h: HexString): Either[PrettyErgoTreeError, ErgoTreeHuman] = {
    try {
      val ergoTree = DefaultSerializer.deserializeErgoTree(h.bytes)
      ergoTree.root match {
        case Left(_) => Left(PrettyErgoTreeError.UnparsedErgoTree)
        case Right(value) =>
          val script = value.toString
          val constants = ergoTree.constants.zipWithIndex.map { case (c, i) => s"$i: ${c.value}" }.mkString("\n")
          Right(ErgoTreeHuman(constants, script))
      }
    } catch {
      case se: SerializerException => Left(PrettyErgoTreeError.DeserializeException(se.message))
    }
  }
}

sealed trait PrettyErgoTreeError
object PrettyErgoTreeError {
  case object BadEncoding extends PrettyErgoTreeError
  case class DeserializeException(msg: String) extends PrettyErgoTreeError
  case object UnparsedErgoTree extends PrettyErgoTreeError
}
PATCHEOF

echo "Done."
