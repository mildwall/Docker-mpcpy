#!/bin/bash

echo "Running inside container.."
source ~/miniconda3/bin/activate py27
cd MPCPy/doc/userGuide/tutorial
python introductory.py
echo "Execution finished!"