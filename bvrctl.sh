#!/bin/bash

echo "Warning: This scrip is deprectated. Please use beaver.sh instead";

ARGS="";

for var in "$@"
do
	ARGS="$ARGS $var";
done

./beaver.sh $ARGS -B;