#!/bin/bash

HELP_LOCALE_ROOT=VisualDifferHelp/Contents/Resources
INDEXER_NAME=VisualDiffer.helpindex

for locale_path in $TARGET_BUILD_DIR/$UNLOCALIZED_RESOURCES_FOLDER_PATH/$HELP_LOCALE_ROOT/*.lproj ;
do
    hiutil -Caf $locale_path/$INDEXER_NAME $locale_path
done
