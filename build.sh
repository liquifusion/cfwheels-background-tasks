#!/bin/bash
BT_VERSION="0.1.0"
BT_ZIP="BackgroundTasks-$BT_VERSION.zip"
zip $BT_ZIP BackgroundTasks.cfc Task.cfc LICENSE README.md controllers/* db/* models/*
